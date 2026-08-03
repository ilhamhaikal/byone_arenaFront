import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../config/platform_config.dart';
import '../models/console_overview_model.dart';
import '../models/realtime_event.dart';
import '../models/tv_notification_model.dart';
import '../services/device_service.dart';
import '../services/realtime_service.dart';
import '../utils/device_info.dart';

enum ClientDisplayState { loading, idle, active, overtime, maintenance, notFound }

class ClientProvider extends ChangeNotifier {
  ConsoleOverviewModel? _console;
  ClientDisplayState _state = ClientDisplayState.loading;
  String? _error;
  Timer? _pollTimer;
  TvNotificationModel? _currentNotification;
  final Set<String> _shownIds = {}; // non-loop: blokir setelah tampil

  // ── Realtime (WebSocket) — terpisah dari HTTP polling di atas ──────────
  // Hanya dipakai untuk memicu refresh instan; sumber kebenaran data tetap
  // dari HTTP (_poll/_pollNotifications), sesuai pemisahan WS vs HTTP.
  StreamSubscription<RealtimeEvent>? _realtimeSub;

  // ── Heartbeat dedup (persisten — bertahan lintas restart/hot-restart) ──
  String? _prevScreenStatus; // status sebelumnya — kirim heartbeat hanya saat berubah
  String? _prevStatusLoadedForConsoleId; // consoleId yang sudah dimuat dari SharedPreferences
  bool _isAuthorized = false; // dari response heartbeat terakhir

  static const String _prefKeyPrefix = 'tv_last_screen_status_';

  // ── Getters ────────────────────────────────────────────────────────────
  ConsoleOverviewModel? get console => _console;
  ActiveSessionInfo? get activeSession => _console?.activeSession;
  ClientDisplayState get state => _state;
  String? get error => _error;
  TvNotificationModel? get currentNotification => _currentNotification;

  bool get isActive => _state == ClientDisplayState.active;
  bool get isOvertime => _state == ClientDisplayState.overtime;
  bool get isIdle => _state == ClientDisplayState.idle;

  // ── Init ───────────────────────────────────────────────────────────────
  void startPolling({int interval = 10}) {
    _poll();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(Duration(seconds: interval), (_) => _poll());

    _startRealtime();
  }

  // ── Realtime (WebSocket) ────────────────────────────────────────────────
  /// Menyambungkan `RealtimeService` (WS) secara terpisah dari HTTP polling.
  /// Event dari server hanya dipakai sebagai sinyal "ada perubahan" untuk
  /// memicu refresh instan lewat HTTP — bukan sumber data langsung — supaya
  /// logic penentuan state (idle/active/overtime/maintenance) tetap satu
  /// tempat saja (_setConsole).
  void _startRealtime() {
    RealtimeService.instance.connect();
    _realtimeSub?.cancel();
    _realtimeSub = RealtimeService.instance.events.listen(_onRealtimeEvent);
  }

  void _onRealtimeEvent(RealtimeEvent event) {
    switch (event.type) {
      case RealtimeEventType.tvNotification:
        _pollNotifications();
        break;
      case RealtimeEventType.sessionEnded:
      case RealtimeEventType.sessionCancelled:
      case RealtimeEventType.tvScreensaver:
        if (_isRelevantToThisConsole(event)) {
          _poll();
          // Sesi berakhir/dibatalkan/waktu habis → app kembali ke depan
          // (doc §10: auto-return), keluar dari Netflix/YouTube/HDMI dll.
          DeviceService.bringToForeground();
        }
        break;
      case RealtimeEventType.sessionStarted:
      case RealtimeEventType.sessionExtended:
      case RealtimeEventType.tvWake:
      case RealtimeEventType.tvSleep:
      case RealtimeEventType.consoleUpdated:
        if (_isRelevantToThisConsole(event)) {
          _poll();
        }
        break;
      default:
        break;
    }
  }

  /// Cek apakah event menyebut consoleId milik konsol ini (kalau event tidak
  /// menyertakan consoleId sama sekali, anggap relevan — lebih aman untuk
  /// selalu refresh daripada melewatkan perubahan).
  bool _isRelevantToThisConsole(RealtimeEvent event) {
    final consoleId = event.payloadMap['consoleId'];
    if (consoleId == null) return true;
    return _console != null && consoleId.toString() == _console!.id;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _realtimeSub?.cancel();
    RealtimeService.instance.disconnect();
    super.dispose();
  }

  // ── Poll (HTTP langsung, TANPA auth token) ─────────────────────────────
  Future<void> _poll() async {
    try {
      final deviceIp = await _getDeviceIp();
      if (deviceIp == null) {
        _setError('Tidak dapat mendeteksi IP perangkat');
        return;
      }

      // HTTP call langsung — TIDAK pakai ApiService (yang selalu inject Bearer token)
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.consolesOverview}');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      // Opsional: client token untuk endpoint yang butuh auth
      if (ApiConfig.clientToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${ApiConfig.clientToken}';
      }
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 401 || response.statusCode == 403) {
        _setError('Akses ditolak. Pastikan endpoint overview bisa diakses tanpa login.');
        return;
      }
      if (response.statusCode != 200) {
        _setError('Server error (${response.statusCode}). Coba lagi nanti.');
        return;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final List data = (body['data'] as List?) ?? [];
      final consoles =
          data.map((e) => ConsoleOverviewModel.fromJson(e as Map<String, dynamic>)).toList();

      // Cocokkan console berdasarkan IP
      final match = consoles.cast<ConsoleOverviewModel?>().firstWhere(
            (c) => c?.ipAddress == deviceIp,
            orElse: () => null,
          );

      if (match == null) {
        _setConsole(null);
        _state = ClientDisplayState.notFound;
        _error = 'Konsol dengan IP $deviceIp tidak ditemukan';
        notifyListeners();
        return;
      }

      _setConsole(match);

      // ── Kirim heartbeat ─────────────────────────────────────────────
      _sendHeartbeat(match.id, match.screenStatus);

      // ── Poll notifications ─────────────────────────────────────────────
      await _pollNotifications();
    } catch (e) {
      _setError('Gagal terhubung ke server: $e');
    }
  }

  Future<void> _pollNotifications() async {
    try {
      final uri = Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.notifications}?active=true');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (ApiConfig.clientToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${ApiConfig.clientToken}';
      }
      final response = await http.get(uri, headers: headers);

      // 401/403 = endpoint belum public, skip silently
      if (response.statusCode == 401 || response.statusCode == 403) return;
      if (response.statusCode != 200) return;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final List data = (body['data'] as List?) ?? [];
      final notifications = data
          .map((e) =>
              TvNotificationModel.fromJson(e as Map<String, dynamic>))
          .where((n) =>
              n.targetAll ||
              (_console != null &&
                  n.targetConsoleIds.contains(_console!.id)))
          .where((n) =>
              !n.activeSessionsOnly ||
              (_console?.activeSession != null))
          .where((n) {
            // Non-loop: tampil sekali saja
            if (!n.loopEnabled) return !_shownIds.contains(n.id);
            // Loop: backend yang kontrol timing, selalu tampilkan
            return true;
          })
          .toList();

      if (notifications.isNotEmpty) {
        _currentNotification = notifications.first;
        if (!notifications.first.loopEnabled) {
          _shownIds.add(notifications.first.id);
        }
        notifyListeners();
      }
    } catch (_) {
      // silent fail — notifikasi opsional
    }
  }

  /// Dismiss notifikasi yang sedang tampil
  void dismissNotification() {
    _currentNotification = null;
    notifyListeners();
  }

  void _setConsole(ConsoleOverviewModel? c) {
    _console = c;
    _error = null;

    if (c == null) {
      _state = ClientDisplayState.notFound;
    } else if (c.status == 'maintenance') {
      _state = ClientDisplayState.maintenance;
    } else if (c.activeSession != null) {
      final sess = c.activeSession!;
      if (sess.isOvertime) {
        _state = ClientDisplayState.overtime;
      } else {
        _state = ClientDisplayState.active;
      }
    } else {
      _state = ClientDisplayState.idle;
    }
    notifyListeners();
  }

  /// Kirim heartbeat ke server — lapor status layar TV.
  /// Hanya kirim jika screenStatus berubah (sesuai dokumentasi backend).
  /// Status terakhir disimpan persisten (SharedPreferences) agar restart
  /// aplikasi / hot-restart / reboot TV Box tidak mengirim ulang status yang
  /// sama dan membuat log duplikat di backend.
  Future<void> _sendHeartbeat(String consoleId, String screenStatus) async {
    try {
      final status = screenStatus.isNotEmpty ? screenStatus : 'off';

      // Muat status terakhir yang tersimpan (sekali per consoleId per sesi app)
      if (_prevStatusLoadedForConsoleId != consoleId) {
        final prefs = await SharedPreferences.getInstance();
        _prevScreenStatus = prefs.getString('$_prefKeyPrefix$consoleId');
        _prevStatusLoadedForConsoleId = consoleId;
      }

      // Dedup: jangan kirim jika status sama dengan sebelumnya
      if (status == _prevScreenStatus) return;

      final uri = Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.consoles}/$consoleId/heartbeat');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({'screenStatus': status}),
      );

      // Parse response heartbeat
      if (response.statusCode == 200) {
        _prevScreenStatus = status;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('$_prefKeyPrefix$consoleId', status);

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          _isAuthorized = data['isAuthorized'] == true;
          notifyListeners();
        }
      }
    } catch (_) {
      // silent — heartbeat opsional
    }
  }

  void _setError(String msg) {
    _error = msg;
    _state = ClientDisplayState.loading;
    notifyListeners();
  }

  // ── IP Detection ───────────────────────────────────────────────────────
  /// Gunakan [getDeviceIp] dari device_info.dart (conditional import).
  /// Web → null, Native → IP address.
  Future<String?> _getDeviceIp() => getDeviceIp();
}
