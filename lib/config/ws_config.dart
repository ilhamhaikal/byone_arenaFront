import 'platform_config.dart';

/// Konfigurasi terpisah untuk koneksi WebSocket realtime.
///
/// URL WebSocket diturunkan dari [PlatformConfig.baseUrl] (yang dipakai untuk HTTP),
/// dengan aturan:
/// - Buang suffix "/api/v1" (endpoint WebSocket ada di root server, bukan di bawah /api/v1)
/// - Ganti skema http -> ws, https -> wss
/// - Tambahkan path "/ws"
///
/// Dipisah dari [PlatformConfig] agar koneksi WebSocket dan HTTP punya
/// tanggung jawab yang jelas (clean architecture: WS != HTTP).
class WsConfig {
  WsConfig._();

  static const String _wsPath = '/ws';
  static const String _apiSuffix = '/api/v1';

  /// URL lengkap untuk koneksi WebSocket, misal: ws://10.0.2.2:8080/ws
  static String get wsUrl {
    var url = PlatformConfig.baseUrl;

    if (url.endsWith(_apiSuffix)) {
      url = url.substring(0, url.length - _apiSuffix.length);
    }

    if (url.startsWith('https://')) {
      url = 'wss://${url.substring('https://'.length)}';
    } else if (url.startsWith('http://')) {
      url = 'ws://${url.substring('http://'.length)}';
    }

    return '$url$_wsPath';
  }
}
