import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Native (Android TV): kirim kredensial perangkat lewat header saat upgrade.
WebSocketChannel createAuthenticatedWsChannel(
  Uri uri, {
  required String deviceId,
  required String secret,
}) {
  return IOWebSocketChannel.connect(
    uri,
    headers: {
      'X-Device-Id': deviceId,
      'X-Device-Secret': secret,
    },
  );
}
