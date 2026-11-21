import 'package:web_socket_channel/web_socket_channel.dart';

/// Fallback web: browser tidak bisa mengirim header kustom saat upgrade.
/// Kredensial dikirim lewat query parameter. Server tetap memverifikasi hash.
WebSocketChannel createAuthenticatedWsChannel(
  Uri uri, {
  required String deviceId,
  required String secret,
}) {
  final authed = uri.replace(queryParameters: {
    ...uri.queryParameters,
    'deviceId': deviceId,
    'secret': secret,
  });
  return WebSocketChannel.connect(authed);
}
