import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/discovery_service.dart';
import 'server_config.dart';

class PlatformConfig {
  PlatformConfig._();

  static bool _initialized = false;

  static String _baseUrl = '';

  static bool _isAndroidTV = false;

  static String get baseUrl => _baseUrl;

  /// True hanya untuk perangkat Android TV / Google TV (Leanback atau
  /// FEATURE_TELEVISION), dibaca dari MethodChannel native. Jangan memakai
  /// `Platform.isAndroid` — HP/tablet admin memakai APK yang sama.
  static bool get isAndroidTV => _isAndroidTV;

  static Future<void> _detectAndroidTV() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final result = await const MethodChannel('byone/device')
          .invokeMethod<bool>('isAndroidTV');
      _isAndroidTV = result ?? false;
    } catch (_) {
      _isAndroidTV = false;
    }
  }

  static Future<void> init() async {
    if (_initialized) return;

    await _detectAndroidTV();

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

    // Android TV: alamat default (localhost) tidak berguna di TV. Cari server
    // di LAN lewat UDP broadcast sebelum menyerah.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final host = Uri.tryParse(_baseUrl)?.host;
      final isLocalDefault =
          _baseUrl.isEmpty || host == 'localhost' || host == '127.0.0.1';
      if (isLocalDefault) {
        final found = await DiscoveryService.findServer();
        if (found != null && found.isNotEmpty) {
          _baseUrl = found;
          await ServerConfig.saveBaseUrl(found);
          debugPrint('DISCOVERY: server ditemukan -> $_baseUrl');
        } else {
          debugPrint('DISCOVERY: server tidak ditemukan di LAN');
        }
      }
    }

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
}