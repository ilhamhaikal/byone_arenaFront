import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/console_overview_model.dart';
import '../models/realtime_event.dart';
import '../models/tv_notification_model.dart';
import '../services/realtime_service.dart';
import '../services/notification_policy.dart';
import '../services/device_secret_service.dart';
import '../services/pairing_service.dart';
import '../utils/device_info.dart';

enum ClientDisplayState {
  loading,
  idle,
  active,
  overtime,
  maintenance,
  notFound,

  /// TV dinyalakan manual (wake/live) TANPA sesi rental. Ini kondisi SAH
  /// untuk mematikan konsol/PS: client tidak menampilkan UI "belum ada sesi".
  liveNoSession,

  /// Perangkat belum dihubungkan ke konsol; layar menampilkan kode pairing.
  pairing,
}

class ClientProvider extends ChangeNotifier {
  ConsoleOverviewModel? _console;
  ClientDisplayState _state = ClientDisplayState.loading;
  String? _error;
  Timer? _pollTimer;
  TvNotificationModel? _currentNotification;
  final Set<String> _shownIds = {}; // non-loop: blokir setelah tampil
  // Notifikasi manual: simpan trigger terakhir yang sudah ditampilkan agar
  // tidak muncul berulang tiap polling. Trigger baru dari admin akan
  // menghasilkan waktu yang lebih baru dan ditampilkan sekali lagi.
  final Map<String, DateTime> _seenTriggeredAt = {};
  bool _notificationBaselineReady = false;

  /// Nomor urut tampil notifikasi. UI TV memakai ini untuk me-reset timer
  /// auto-dismiss setiap kali notifikasi BARU ditampilkan (termasuk loop),
  /// sehingga notifikasi baru tidak terpotong timer notifikasi sebelumnya.
  int _notificationSeq = 0;

  // Guard agar polling notifikasi tidak berjalan bersamaan (HTTP poll 10 dtk
  // bisa bertabrakan dengan event WebSocket). Event yang datang saat fetch
  // berjalan diantrikan satu kali agar trigger manual tidak hilang.
  bool _notifPolling = false;
  bool _notifQueued = false;
  bool _notifQueuedRealtime = false;
  String? _notifQueuedPreferredId;
  bool _disposed = false;
  String? _lastActiveSessionId;

  // ── Realtime (WebSocket) — terpisah dari HTTP polling di atas ──────────
  // Hanya dipakai untuk memicu refresh instan; sumber kebenaran data tetap
  // dari HTTP (_poll/_pollNotifications), sesuai pemisahan WS vs HTTP.
  StreamSubscription<RealtimeEvent>? _realtimeSub;

  // ── Overtime sticky window ───────────────────────────────────────────
  // Saat countdown lokal mencapai 0, client tampilkan layar "WAKTU HABIS"
  // dulu SEBELUM kembali ke screensaver. Backend auto-stop sesi dalam siklus
  // 30 detik; kalau poll berikutnya sudah melaporkan sesi berakhir, state
  // jangan langsung lompat ke idle — tahan di overtime selama window ini.
  DateTime? _overtimeSince;
  static const Duration overtimeStickyDuration = Duration(seconds: 10);

  // ID sesi yang saat ini sedang ditampilkan overtime-nya. Dipakai untuk
  // memastikan overtime TIDAK bocor/ter-carry antar sesi: begitu sessionId
  // berubah (sesi baru), semua penanda overtime di-reset.
  String? _overtimeSessionId;

  // ── Pairing (kode 6 digit) ─────────────────────────────────────────────
  String? _pairingCode;
  DateTime? _pairingExpiresAt;
  bool _reauthRequired = false;
  bool _quickRetryScheduled = false;

  // ── Getters ────────────────────────────────────────────────────────────
  ConsoleOverviewModel? get console => _console;
  ActiveSessionInfo? get activeSession => _console?.activeSession;
  ClientDisplayState get state => _state;
  String? get error => _error;
  TvNotificationModel? get currentNotification => _currentNotification;

  /// Bertambah setiap kali notifikasi baru dipasang untuk ditampilkan.
  int get notificationSeq => _notificationSeq;

  /// Kode pairing yang tampil di layar TV (null bila sudah terhubung).
  String? get pairingCode => _pairingCode;

  /// True bila TV sudah terhubung tetapi kredensial perangkat tidak cocok.
  bool get reauthRequired => _reauthRequired;

  /// Kapan kode pairing kedaluwarsa.
  DateTime? get pairingExpiresAt => _pairingExpiresAt;

  /// True saat TV menunggu dihubungkan admin.
  bool get isPairing => _state == ClientDisplayState.pairing;

  bool get isActive => _state == ClientDisplayState.active;
  bool get isOvertime => _state == ClientDisplayState.overtime;
  bool get isIdle => _state == ClientDisplayState.idle;
  bool get isLiveNoSession => _state == ClientDisplayState.liveNoSession;

  /// Cek overtime secara LOKAL (tanpa nunggu poll HTTP berikutnya, yang
  /// interval-nya 10 detik). Untuk sesi pendek, backend bisa saja sudah
  /// auto-stop sesi (siklus 30 detik) SEBELUM poll client berikutnya sempat
  /// menangkap momen overtime — akibatnya state lompat langsung dari
  /// `active` ke `idle` tanpa pernah menampilkan layar "waktu habis".
  /// Dipanggil tiap detik dari ticker UI (client_display_screen.dart).
  void checkLocalOvertime() {
    if (_state == ClientDisplayState.active &&
        _console?.activeSession?.isOvertime == true) {
      markOvertime(_console!.activeSession!.id);
    }
  }

  /// Paksa masuk state overtime (layar "WAKTU HABIS") dan catat waktunya
  /// supaya state ini bertahan beberapa detik walau poll berikutnya sudah
  /// melaporkan sesi berakhir (auto-stop). Dipicu dari countdown lokal
  /// clock-safe di client_display_screen.dart.
  ///
  /// [sessionId] adalah ID sesi yang habis — dipakai agar overtime tidak
  /// tertukar/ter-carry antar sesi.
  void markOvertime(String sessionId) {
    if (_state == ClientDisplayState.overtime &&
        _overtimeSessionId == sessionId) {
      return;
    }
    _state = ClientDisplayState.overtime;
    _overtimeSince = DateTime.now();
    _overtimeSessionId = sessionId;
    notifyListeners();
  }

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
        _pollNotifications(
          realtime: true,
          preferredId: event.payloadMap['id']?.toString(),
        );
        break;
      case RealtimeEventType.sessionEnded:
      case RealtimeEventType.sessionCancelled:
      case RealtimeEventType.tvScreensaver:
        if (_isRelevantToThisConsole(event)) {
          _poll();
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
    final consoleId = event.consoleId ?? event.payloadMap['consoleId'];
    if (consoleId == null) return true;
    return _console != null && consoleId.toString() == _console!.id;
  }

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    _realtimeSub?.cancel();
    RealtimeService.instance.disconnect();
    super.dispose();
  }

  /// Polesan async (HTTP/WS) yang selesai setelah provider di-dispose tidak
  /// boleh memicu notifyListeners.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
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
      final uri =
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.consolesOverview}');
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
        _setError(
            'Akses ditolak. Pastikan endpoint overview bisa diakses tanpa login.');
        return;
      }
      if (response.statusCode != 200) {
        _setError('Server error (${response.statusCode}). Coba lagi nanti.');
        return;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final List data = (body['data'] as List?) ?? [];
      final consoles = data
          .map((e) => ConsoleOverviewModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // Cocokkan console berdasarkan IP
      final match = consoles.cast<ConsoleOverviewModel?>().firstWhere(
            (c) => c?.ipAddress == deviceIp,
            orElse: () => null,
          );

      if (match == null) {
        await _enterPairing();
        return;
      }

      // Terhubung ke konsol — bersihkan status pairing.
      _pairingCode = null;
      _pairingExpiresAt = null;
      _quickRetryScheduled = false;

      _setConsole(match);

      // ── Kirim heartbeat ─────────────────────────────────────────────
      _sendHeartbeat(match.id, match.screenStatus);

      // ── Poll notifications ─────────────────────────────────────────────
      await _pollNotifications();
    } catch (e) {
      _setError('Gagal terhubung ke server: $e');
    }
  }

  /// Perangkat belum terhubung ke konsol: minta kode pairing dan tampilkan
  /// layar "Hubungkan TV" berisi kode 6 digit.
  Future<void> _enterPairing() async {
    final info = await PairingService.announce();

    // Server tidak terjangkau → tampilkan status error seperti sebelumnya.
    if (info == null) {
      if (_reauthRequired) {
        // Pertahankan layar pairing-ulang; announce berikutnya di-throttle.
        _state = ClientDisplayState.pairing;
        notifyListeners();
        return;
      }
      _setConsole(null);
      _state = ClientDisplayState.notFound;
      _error = 'Tidak dapat terhubung ke server. Periksa kabel/WiFi.';
      notifyListeners();
      return;
    }

    // Admin baru saja menghubungkan perangkat ini; overview konsol mungkin
    // belum ter-update, jadi cek ulang sebentar lagi tanpa menunggu 10 detik.
    if (info.bound) {
      _reauthRequired = false;
      _state = ClientDisplayState.loading;
      notifyListeners();
      if (!_quickRetryScheduled) {
        _quickRetryScheduled = true;
        Timer(const Duration(seconds: 2), () {
          _quickRetryScheduled = false;
          _poll();
        });
      }
      return;
    }

    _setConsole(null);
    _pairingCode = info.pairingCode;
    _pairingExpiresAt = info.expiresAt;
    _reauthRequired = info.reauthRequired;
    _state = ClientDisplayState.pairing;
    _error = null;
    notifyListeners();
  }

  /// Dipakai tombol "Minta Kode Baru" pada layar pairing TV.
  Future<void> requestNewPairingCode() async {
    final info = await PairingService.refreshCode();
    if (info == null) return;

    _pairingCode = info.pairingCode;
    _pairingExpiresAt = info.expiresAt;
    _reauthRequired = info.reauthRequired;
    if (info.bound) {
      _reauthRequired = false;
      _state = ClientDisplayState.loading;
    }
    notifyListeners();
  }

  Future<void> _pollNotifications({
    bool realtime = false,
    String? preferredId,
  }) async {
    if (_disposed) return;
    if (_notifPolling) {
      // Sudah ada fetch berjalan. Jadwalkan satu fetch susulan dengan
      // menggabungkan semua sinyal yang masuk, supaya event manual (show)
      // tidak hilang dan event loop tidak menumpuk.
      _notifQueued = true;
      _notifQueuedRealtime = _notifQueuedRealtime || realtime;
      if (preferredId != null) _notifQueuedPreferredId = preferredId;
      return;
    }
    _notifPolling = true;
    try {
      await _fetchNotifications(realtime: realtime, preferredId: preferredId);
    } finally {
      _notifPolling = false;
      if (_notifQueued && !_disposed) {
        _notifQueued = false;
        final queuedRealtime = _notifQueuedRealtime;
        final queuedPreferredId = _notifQueuedPreferredId;
        _notifQueuedRealtime = false;
        _notifQueuedPreferredId = null;
        unawaited(_pollNotifications(
          realtime: queuedRealtime,
          preferredId: queuedPreferredId,
        ));
      }
    }
  }

  Future<void> _fetchNotifications({
    required bool realtime,
    String? preferredId,
  }) async {
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
      if (_disposed) return;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final List data = (body['data'] as List?) ?? [];
      final allNotifications = data
          .map((e) => TvNotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // Baseline pertama: trigger manual yang SUDAH ADA sebelum TV/app
      // dijalankan ditandai sudah dilihat, supaya tidak muncul tiba-tiba
      // saat restart. Trigger baru setelah ini tetap tampil. Berlaku untuk
      // SEMUA notifikasi (bukan hanya manual) agar trigger lama pada
      // notifikasi otomatis juga tidak diputar ulang saat restart.
      if (!_notificationBaselineReady) {
        for (final n in allNotifications) {
          if (n.lastTriggeredAt != null) {
            _seenTriggeredAt[n.id] = n.lastTriggeredAt!;
          }
        }
        _notificationBaselineReady = true;
      }

      // Buang penanda untuk notifikasi yang sudah tidak ada/nonaktif agar
      // memori tidak tumbuh terus selama TV menyala berhari-hari. Notifikasi
      // yang diaktifkan lagi akan diperlakukan sebagai notifikasi baru.
      final activeIds = allNotifications.map((n) => n.id).toSet();
      _shownIds.removeWhere((id) => !activeIds.contains(id));
      _seenTriggeredAt.removeWhere((id, _) => !activeIds.contains(id));

      final notifications = allNotifications
          .where((n) => NotificationPolicy.matchesTarget(
                n,
                consoleId: _console?.id,
                hasActiveSession: _console?.activeSession != null,
              ))
          .where((n) => NotificationPolicy.shouldShow(
                n,
                realtime: realtime,
                shownIds: _shownIds,
                seenTriggeredAt: _seenTriggeredAt,
              ))
          .toList();

      final n = NotificationPolicy.pickForDisplay(
        notifications,
        preferredId: preferredId,
      );
      if (n != null && !_disposed) {
        _currentNotification = n;
        _notificationSeq++;
        if (n.autoShow) _shownIds.add(n.id);
        if (n.lastTriggeredAt != null) {
          _seenTriggeredAt[n.id] = n.lastTriggeredAt!;
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

    // Kredensial perangkat tidak valid: jangan tampilkan state sesi/idle,
    // paksa layar pairing ulang sampai admin melepaskan perangkat.
    if (_reauthRequired) {
      _state = ClientDisplayState.pairing;
      notifyListeners();
      return;
    }

    final newSessionId = c?.activeSession?.id;

    // Sesi baru mulai: jangan bawa notifikasi dari layar idle/sesi sebelumnya.
    // Notifikasi manual yang di-trigger SETELAH sesi berjalan tetap tampil.
    if (newSessionId != null && newSessionId != _lastActiveSessionId) {
      _lastActiveSessionId = newSessionId;
      _currentNotification = null;
    }

    // Sesi berganti ke sesi LAIN (bukan menjadi null karena auto-stop) →
    // reset penanda overtime supaya layar "WAKTU HABIS" sesi lama tidak
    // mengganggu sesi baru. Kalau newSessionId null (backend sudah end sesi),
    // _overtimeSince tetap dipertahankan supaya sticky window masih berlaku.
    if (newSessionId != null && newSessionId != _overtimeSessionId) {
      _overtimeSince = null;
      _overtimeSessionId = null;
    }

    if (c == null) {
      _state = ClientDisplayState.notFound;
    } else if (c.status == 'maintenance') {
      _state = ClientDisplayState.maintenance;
    } else if (c.activeSession != null) {
      final sess = c.activeSession!;

      // Penting: countdown lokal bisa sudah menandai overtime untuk sesi ini,
      // tapi poll berikutnya bisa melaporkan remainingSeconds = 1 (ceil)
      // sehingga sess.isOvertime == false. Jangan turunkan kembali ke active
      // selama sticky window masih berlaku untuk SESI YANG SAMA.
      final overtimeHeldForThisSession =
          _state == ClientDisplayState.overtime &&
              _overtimeSessionId == sess.id &&
              _inOvertimeStickyWindow();

      if (sess.isOvertime) {
        // Sesi masih terlihat oleh backend & sudah overtime → pastikan tampil
        // layar waktu habis (clock-safe via remainingSeconds == 0).
        markOvertime(sess.id);
      } else if (overtimeHeldForThisSession) {
        // Layar "WAKTU HABIS" sudah tampil — tahan sampai sticky window habis.
        _state = ClientDisplayState.overtime;
      } else {
        // Sesi aktif normal (atau sesi BARU) → keluar dari overtime.
        _state = ClientDisplayState.active;
      }
    } else if (_state == ClientDisplayState.overtime &&
        _inOvertimeStickyWindow()) {
      // Backend sudah auto-stop sesi (activeSession null), tapi layar
      // "WAKTU HABIS" baru saja tampil — tahan sebentar sebelum ke idle.
      _state = ClientDisplayState.overtime;
    } else if (c.screenStatus == 'on' && c.manualLive) {
      // TV dinyalakan manual (wake/live) TANPA sesi rental. Ini SAH dipakai
      // admin untuk mematikan konsol/PS, jadi JANGAN tampilkan layar
      // "belum ada sesi" dan jangan masukkan sebagai unauthorized.
      // WAJIB manualLive=true: screenStatus "on" sisa sesi yang baru
      // berakhir TIDAK boleh mempertahankan mode live.
      _state = ClientDisplayState.liveNoSession;
    } else {
      _state = ClientDisplayState.idle;
    }
    notifyListeners();
  }

  bool _inOvertimeStickyWindow() {
    final since = _overtimeSince;
    if (since == null) return false;
    return DateTime.now().difference(since) < overtimeStickyDuration;
  }

  /// Kirim heartbeat liveness + status layar setiap polling.
  /// Server mencatat log hanya saat status berubah, jadi pengiriman periodik
  /// aman dan membuat `last_seen_at` tidak basi.
  Future<void> _sendHeartbeat(String consoleId, String screenStatus) async {
    try {
      final status = screenStatus.isNotEmpty ? screenStatus : 'off';
      final deviceId = await PairingService.deviceId();
      final secret = await DeviceSecretService.getOrCreateSecret();
      final uri = Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.consoles}/$consoleId/heartbeat');
      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Device-Id': deviceId,
          'X-Device-Secret': secret,
        },
        body: jsonEncode({'screenStatus': status}),
      );

      if (response.statusCode == 401) {
        _reauthRequired = true;
        _pairingCode = null;
        _state = ClientDisplayState.pairing;
        notifyListeners();
        return;
      }

      // 200 = heartbeat diterima. Status otorisasi sudah ditangani backend
      // lewat log aktivitas; client tidak perlu menyimpan flag tambahan.
    } catch (_) {
      // silent — heartbeat opsional
    }
  }

  /// Set error dari poll yang gagal. Kalau sudah pernah dapat data console
  /// sebelumnya, JANGAN downgrade state ke `loading` — cukup catat error saja
  /// dan pertahankan tampilan terakhir (idle/active/overtime/dll). Ini penting
  /// supaya hiccup jaringan sesaat tidak membuat layar "waktu habis"/warning
  /// tiba-tiba berganti ke loading lalu balik ke idle.
  void _setError(String msg) {
    _error = msg;
    if (_console == null) {
      _state = ClientDisplayState.loading;
    }
    notifyListeners();
  }

  // ── IP Detection ───────────────────────────────────────────────────────
  /// Gunakan [getDeviceIp] dari device_info.dart (conditional import).
  /// Web → null, Native → IP address.
  Future<String?> _getDeviceIp() => getDeviceIp();
}
