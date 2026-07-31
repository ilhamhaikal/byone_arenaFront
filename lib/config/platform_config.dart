import 'package:flutter/foundation.dart';
import 'server_config.dart';

class PlatformConfig {
  PlatformConfig._();

  static bool _initialized = false;

  static String _baseUrl = '';

  static String get baseUrl => _baseUrl;

  static Future<void> init() async {
    if (_initialized) return;

    // =====================================================
    // DEVELOPMENT
    // =====================================================
    if (kDebugMode && defaultTargetPlatform == TargetPlatform.android) {
      _baseUrl = 'http://10.0.2.2:8080/api/v1';

      debugPrint('====================================');
      debugPrint('DEBUG MODE');
      debugPrint('BaseURL : $_baseUrl');
      debugPrint('====================================');

      _initialized = true;
      return;
    }

    // =====================================================
    // PRODUCTION
    // =====================================================

    _baseUrl = await ServerConfig.loadBaseUrl();

    debugPrint('====================================');
    debugPrint('PRODUCTION MODE');
    debugPrint('BaseURL : $_baseUrl');
    debugPrint('====================================');

    _initialized = true;
  }

  static Future<void> setBaseUrl(String url) async {
    final clean = url.endsWith('/')
        ? url.substring(0, url.length - 1)
        : url;

    _baseUrl = clean;
    await ServerConfig.saveBaseUrl(clean);
  }

  static bool get isWeb => kIsWeb;

  static bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static bool get isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static bool get isAndroid =>
      defaultTargetPlatform == TargetPlatform.android;

  static bool get isLinux =>
      defaultTargetPlatform == TargetPlatform.linux;

  static bool get isAndroidTV => isAndroid;
}