/// Model event realtime yang diterima dari WebSocket server.
///
/// Bentuk JSON persis mengikuti struct `Event` di backend
/// (`internal/delivery/websocket/hub.go`):
/// ```json
/// { "type": "SESSION_STARTED", "payload": { ... }, "timestamp": "..." }
/// ```
class RealtimeEvent {
  final String type;
  final dynamic payload;
  final DateTime timestamp;

  const RealtimeEvent({
    required this.type,
    required this.payload,
    required this.timestamp,
  });

  factory RealtimeEvent.fromJson(Map<String, dynamic> json) {
    return RealtimeEvent(
      type: json['type'] as String? ?? '',
      payload: json['payload'],
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// Payload sebagai Map, atau map kosong kalau bentuknya bukan object.
  Map<String, dynamic> get payloadMap =>
      payload is Map ? Map<String, dynamic>.from(payload as Map) : const {};
}

/// Daftar tipe event yang dikirim server, sinkron dengan `EventType` di backend.
abstract class RealtimeEventType {
  static const sessionStarted = 'SESSION_STARTED';
  static const sessionEnded = 'SESSION_ENDED';
  static const sessionCancelled = 'SESSION_CANCELLED';
  static const sessionExtended = 'SESSION_EXTENDED';
  static const paymentCreated = 'PAYMENT_CREATED';
  static const paymentConfirmed = 'PAYMENT_CONFIRMED';
  static const paymentRefunded = 'PAYMENT_REFUNDED';
  static const consoleUpdated = 'CONSOLE_UPDATED';
  static const ping = 'PING';
  static const tvWake = 'TV_WAKE';
  static const tvSleep = 'TV_SLEEP';
  static const tvScreensaver = 'TV_SCREENSAVER';
  static const tvNotification = 'TV_NOTIFICATION';
}
