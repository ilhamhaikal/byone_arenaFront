import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/console_overview_model.dart';

enum ClientDisplayState { loading, idle, active, overtime, maintenance, notFound }

class ClientProvider extends ChangeNotifier {
  ConsoleOverviewModel? _console;
  ClientDisplayState _state = ClientDisplayState.loading;
  String? _error;
  Timer? _pollTimer;

  // ── Getters ────────────────────────────────────────────────────────────
  ConsoleOverviewModel? get console => _console;
  ActiveSessionInfo? get activeSession => _console?.activeSession;
  ClientDisplayState get state => _state;
  String? get error => _error;

  bool get isActive => _state == ClientDisplayState.active;
  bool get isOvertime => _state == ClientDisplayState.overtime;
  bool get isIdle => _state == ClientDisplayState.idle;

  // ── Init ───────────────────────────────────────────────────────────────
  void startPolling({int interval = 10}) {
    _poll();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(Duration(seconds: interval), (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
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
    } catch (e) {
      _setError('Gagal terhubung ke server: $e');
    }
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

  void _setError(String msg) {
    _error = msg;
    _state = ClientDisplayState.loading;
    notifyListeners();
  }

  // ── IP Detection ───────────────────────────────────────────────────────
  Future<String?> _getDeviceIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          // Skip link-local dan special addresses
          final ip = addr.address;
          if (ip.startsWith('169.254')) continue; // link-local
          if (ip == '0.0.0.0') continue;
          return ip;
        }
      }
      // Fallback: return first non-loopback
      if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
        return interfaces.first.addresses.first.address;
      }
    } catch (_) {
      // NetworkInterface.list bisa throw di beberapa platform
    }
    return null;
  }
}
