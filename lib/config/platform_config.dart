import 'package:flutter/foundation.dart';
import 'server_config.dart';

/// Deteksi platform & menyediakan baseUrl yang sesuai.
///
/// baseUrl di-load dari SharedPreferences (diset via login screen).
/// Default: http://localhost:8080/api/v1 (dev di PC server).
///
/// Arsitektur: semua device terhubung via LAN ke 1 PC server.
/// Tidak perlu internet — hanya jaringan lokal.
class PlatformConfig {
  PlatformConfig._();

  // ---------------------------------------------------------------------------
  // Base URL
  // ---------------------------------------------------------------------------

  static String _baseUrl = 'http://localhost:8080/api/v1';
  static bool _initialized = false;

  static String get baseUrl => _baseUrl;

  /// Panggil saat startup (sebelum runApp) untuk memuat baseUrl tersimpan.
  static Future<void> init() async {
    if (_initialized) return;
    _baseUrl = await ServerConfig.loadBaseUrl();
    _initialized = true;
  }

  /// Override baseUrl & simpan ke SharedPreferences.
  static Future<void> setBaseUrl(String url) async {
    final clean = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    _baseUrl = clean;
    await ServerConfig.saveBaseUrl(clean);
  }

  // ---------------------------------------------------------------------------
  // Platform Info
  // ---------------------------------------------------------------------------

  static bool get isWeb => kIsWeb;
  static bool get isDesktop =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS);
  static bool get isMobile =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  static bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;
  static bool get isLinux => defaultTargetPlatform == TargetPlatform.linux;

  /// Apakah device ini kemungkinan Android TV client?
  /// True jika Android DAN bukan web.
  static bool get isAndroidTV => isAndroid;
}
