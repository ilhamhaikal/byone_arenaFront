import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

import '../config/ws_config.dart';
import '../models/realtime_event.dart';

/// Client WebSocket realtime — sepenuhnya terpisah dari `ApiService`/HTTP.
///
/// Tanggung jawab:
/// - Membuka & menjaga koneksi WebSocket ke server (auto-reconnect + backoff)
/// - Mem-parsing pesan mentah menjadi [RealtimeEvent]
/// - Mengekspos [events] sebagai broadcast stream yang bisa didengarkan
///   oleh provider manapun (mis. ClientProvider) tanpa tahu detail transport.
///
/// Catatan arsitektur: service ini TIDAK melakukan request HTTP apa pun.
/// Pengiriman data ke server (mis. heartbeat) tetap lewat HTTP/ApiService;
/// service ini murni untuk menerima broadcast server -> client secara instan.
/// Pemisahan ini sengaja dibuat agar transport WS dan HTTP tidak saling
/// bergantung (clean architecture di sisi frontend).
class RealtimeService {
  RealtimeService._internal();
  static final RealtimeService instance = RealtimeService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _channelSub;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  final StreamController<RealtimeEvent> _eventsController =
      StreamController<RealtimeEvent>.broadcast();

  bool _manuallyDisconnected = false;
  int _reconnectAttempt = 0;

  static const _pingInterval = Duration(seconds: 20);
  static const _maxBackoffSeconds = 30;

  /// Stream event realtime dari server. Bisa didengarkan berkali-kali
  /// (broadcast stream) oleh banyak provider/widget sekaligus.
  Stream<RealtimeEvent> get events => _eventsController.stream;

  bool get isConnected => _channel != null;

  /// Membuka koneksi WebSocket. Aman dipanggil berulang kali (no-op kalau
  /// sudah tersambung).
  void connect() {
    if (_channel != null) return;

    _manuallyDisconnected = false;
    _open();
  }

  void _open() {
    final url = WsConfig.wsUrl;
    try {
      final channel = WebSocketChannel.connect(Uri.parse(url));
      _channel = channel;
      _reconnectAttempt = 0;

      _channelSub = channel.stream.listen(
        _onMessage,
        onError: (_) => _scheduleReconnect(),
        onDone: () => _scheduleReconnect(),
        cancelOnError: true,
      );

      _startPing();

      debugPrint('[RealtimeService] Terhubung ke $url');
    } catch (e) {
      debugPrint('[RealtimeService] Gagal konek: $e');
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final map = jsonDecode(raw as String) as Map<String, dynamic>;
      final event = RealtimeEvent.fromJson(map);
      _eventsController.add(event);
    } catch (e) {
      debugPrint('[RealtimeService] Pesan tidak valid: $e');
    }
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      try {
        _channel?.sink.add(jsonEncode({'type': 'PING'}));
      } catch (_) {
        // Abaikan; onError/onDone dari stream yang akan memicu reconnect.
      }
    });
  }

  void _scheduleReconnect() {
    _cleanupChannel();

    if (_manuallyDisconnected) return;

    _reconnectAttempt++;
    final delaySeconds =
        (2 * _reconnectAttempt).clamp(1, _maxBackoffSeconds);
    final delay = Duration(seconds: delaySeconds);

    debugPrint(
      '[RealtimeService] Reconnect dalam ${delay.inSeconds}s (percobaan ke-$_reconnectAttempt)',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, _open);
  }

  void _cleanupChannel() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _channelSub?.cancel();
    _channelSub = null;
    _channel = null;
  }

  /// Menutup koneksi secara sengaja (mis. saat app dispose). Tidak akan
  /// mencoba reconnect otomatis sampai [connect] dipanggil lagi.
  void disconnect() {
    _manuallyDisconnected = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _channel?.sink.close(ws_status.goingAway);
    _cleanupChannel();
    debugPrint('[RealtimeService] Diputus manual');
  }
}
