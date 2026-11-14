import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../utils/device_info.dart';

/// Mendaftarkan TV yang belum terhubung ke konsol agar muncul di daftar
/// "Perangkat menunggu" pada aplikasi admin.
class PairingService {
  PairingService._();

  static DateTime? _lastAnnounce;

  /// Dipanggil berkala; dibatasi 30 detik agar tidak membanjiri server.
  static Future<void> announce({bool force = false}) async {
    final now = DateTime.now();
    if (!force &&
        _lastAnnounce != null &&
        now.difference(_lastAnnounce!).inSeconds < 30) {
      return;
    }
    _lastAnnounce = now;

    final ip = await getDeviceIp();
    if (ip == null) return;

    try {
      await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/devices/announce'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'name': 'TV Client',
              'model': '',
              'appVersion': '1.0.4',
              'ip': ip,
            }),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Server belum terjangkau; percobaan berikutnya akan mengulang.
    }
  }
}