import 'package:shared_preferences/shared_preferences.dart';

/// Menyimpan & memuat konfigurasi server backend dari SharedPreferences.
///
/// Karena semua device terhubung via LAN ke 1 PC server, setiap device
/// perlu tahu IP server. Disimpan lokal — tidak perlu internet.
class ServerConfig {
  ServerConfig._();

  static const _keyBaseUrl = 'server_base_url';
  static const _defaultUrl = 'http://localhost:8080/api/v1';

  // ---------------------------------------------------------------------------
  // Load / Save
  // ---------------------------------------------------------------------------

  /// Panggil saat startup untuk memuat baseUrl dari SharedPreferences.
  /// Jika belum ada, gunakan default (localhost — pas untuk dev di PC server).
  static Future<String> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBaseUrl) ?? _defaultUrl;
  }

  /// Simpan baseUrl ke SharedPreferences (dipanggil dari login screen / settings).
  static Future<void> saveBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    // Bersihkan trailing slash
    final clean = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    await prefs.setString(_keyBaseUrl, clean);
  }

  /// Reset ke default (localhost).
  static Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyBaseUrl);
  }
}
