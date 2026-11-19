import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../config/api_config.dart';
import '../utils/device_info.dart';

/// Hasil pemanggilan `POST /devices/announce`.
class PairingInfo {
  /// Kode 6 digit yang ditampilkan di layar TV (null bila perangkat sudah
  /// terhubung).
  final String? pairingCode;

  /// Masa berlaku kode; setelah lewat, kode baru diminta otomatis.
  final DateTime? expiresAt;

  /// True bila perangkat sudah dihubungkan ke sebuah konsol oleh admin.
  final bool bound;

  /// Diisi bila [bound] bernilai true.
  final String? consoleId;
  final String? consoleName;

  const PairingInfo({
    this.pairingCode,
    this.expiresAt,
    this.bound = false,
    this.consoleId,
    this.consoleName,
  });
}

/// Mendaftarkan TV ke server dan mengambil kode pairing 6 digit.
///
/// Identitas perangkat memakai `deviceId` (UUID) yang dibuat sekali dan
/// disimpan di SharedPreferences — bukan IP, supaya TV tetap dikenali walau
/// IP-nya berubah (DHCP).
class PairingService {
  PairingService._();

  static const String _deviceIdKey = 'tv_device_id';
  static const String _appVersion = '1.0.4';

  /// Jeda minimum antar-announce agar server tidak dibanjiri.
  static const Duration _throttle = Duration(seconds: 10);

  static DateTime? _lastAnnounce;
  static String? _cachedDeviceId;

  /// ID tetap perangkat ini (dibuat sekali, lalu dipakai seterusnya).
  static Future<String> deviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_deviceIdKey);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(_deviceIdKey, id);
    }
    _cachedDeviceId = id;
    return id;
  }

  /// Kirim kehadiran ke server dan ambil kode pairing.
  ///
  /// Mengembalikan `null` bila server belum terjangkau (pemanggil sebaiknya
  /// mencoba lagi pada siklus berikutnya).
  static Future<PairingInfo?> announce({bool force = false}) async {
    final now = DateTime.now();
    if (!force &&
        _lastAnnounce != null &&
        now.difference(_lastAnnounce!) < _throttle) {
      return null;
    }
    _lastAnnounce = now;

    final id = await deviceId();
    final ip = await getDeviceIp();

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/devices/announce'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'deviceId': id,
              'name': 'TV Client',
              'model': '',
              'appVersion': _appVersion,
              // Dikirim untuk kompatibilitas; server memakai IP sumber request.
              'ip': ip,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return null;
      final data = body['data'];
      if (data is! Map<String, dynamic>) return null;

      return PairingInfo(
        pairingCode: data['pairingCode'] as String?,
        expiresAt: data['codeExpiresAt'] != null
            ? DateTime.tryParse(data['codeExpiresAt'].toString())
            : null,
        bound: data['bound'] == true,
        consoleId: data['consoleId']?.toString(),
        consoleName: data['consoleName'] as String?,
      );
    } catch (_) {
      // Server belum terjangkau / jaringan bermasalah; ulangi siklus berikut.
      return null;
    }
  }

  /// Paksa minta kode baru (dipakai tombol "Minta Kode Baru" di layar TV).
  /// Paksa minta kode baru (tombol "Minta Kode Baru" di layar TV).
  static Future<PairingInfo?> refreshCode() => announce(force: true);
}
