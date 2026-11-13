import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Menemukan server Byone Arena di LAN tanpa mengetik alamat IP.
///
/// Mekanisme: aplikasi mengirim UDP broadcast `BYONE_DISCOVER` ke port tetap,
/// server membalas secara unicast dengan JSON berisi alamat API-nya. Server
/// hanya membalas pengirim, jadi tidak perlu konfigurasi khusus di router
/// selain memastikan AP/client isolation mati.
class DiscoveryService {
  DiscoveryService._();

  static const int port = 47823;
  static const String probe = 'BYONE_DISCOVER';

  static Future<String?> findServer({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    RawDatagramSocket? socket;
    StreamSubscription<RawSocketEvent>? sub;
    Timer? deadline;
    Timer? probeTimer;
    final completer = Completer<String?>();

    void finish(String? url) {
      if (completer.isCompleted) return;
      probeTimer?.cancel();
      deadline?.cancel();
      sub?.cancel();
      try {
        socket?.close();
      } catch (_) {}
      completer.complete(url);
    }

    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      sub = socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        final datagram = socket!.receive();
        if (datagram == null) return;
        try {
          final map =
              jsonDecode(utf8.decode(datagram.data)) as Map<String, dynamic>;
          final api = map['api'];
          if (map['service'] == 'byone-arena' && api is String) {
            finish(api);
          }
        } catch (_) {
          // bukan balasan kita — abaikan
        }
      });

      void sendProbe() {
        try {
          socket?.send(
            utf8.encode(probe),
            InternetAddress('255.255.255.255'),
            port,
          );
        } catch (_) {}
      }

      sendProbe();
      probeTimer = Timer.periodic(const Duration(seconds: 1), (_) => sendProbe());
      deadline = Timer(timeout, () => finish(null));

      return await completer.future;
    } catch (_) {
      finish(null);
      return await completer.future;
    }
  }
}