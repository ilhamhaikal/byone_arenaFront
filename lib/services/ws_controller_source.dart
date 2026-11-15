import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/ws_config.dart';
import '../models/controller_event.dart';
import 'controller_input_source.dart';

/// Sumber input dari service Go melalui WebSocket.
///
/// Belum dipakai di tahap ini (masih mock), tetapi kontraknya sudah disiapkan
/// agar integrasi hardware nanti tidak mengubah halaman/ provider.
///
/// Format pesan yang diharapkan:
/// ```json
/// {"type":"button","control":"cross","pressed":true}
/// {"type":"analog","control":"leftStick","x":0.12,"y":-0.4}
/// {"type":"trigger","control":"l2","value":0.72}
/// {"type":"connection","connected":true,"transport":"bluetooth"}
/// {"type":"battery","level":78,"charging":false}
/// ```
class WsControllerInputSource implements ControllerInputSource {
  final String? endpoint;
  final StreamController<ControllerEvent> _controller =
      StreamController<ControllerEvent>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  WsControllerInputSource({this.endpoint});

  @override
  Stream<ControllerEvent> get events => _controller.stream;

  @override
  bool get isSimulated => false;

  String get _url => endpoint ?? '${WsConfig.wsUrl}/controllers';

  @override
  void start() {
    if (_channel != null) return;
    try {
      final channel = WebSocketChannel.connect(Uri.parse(_url));
      _channel = channel;
      _sub = channel.stream.listen(
        _onMessage,
        onError: (_) => _emitDisconnected(),
        onDone: _emitDisconnected,
      );
    } catch (_) {
      _emitDisconnected();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final map = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = map['type'] as String?;
      switch (type) {
        case 'button':
          _controller.add(ControllerButtonEvent(
            map['control'] as String,
            pressed: map['pressed'] == true,
          ));
          break;
        case 'analog':
          _controller.add(ControllerAnalogEvent(
            map['control'] as String,
            (map['x'] as num?)?.toDouble() ?? 0,
            (map['y'] as num?)?.toDouble() ?? 0,
          ));
          break;
        case 'trigger':
          _controller.add(ControllerTriggerEvent(
            map['control'] as String,
            (map['value'] as num?)?.toDouble() ?? 0,
          ));
          break;
        case 'connection':
          _controller.add(ControllerConnectionEvent(
            connected: map['connected'] == true,
            transport: _parseTransport(map['transport'] as String?),
          ));
          break;
        case 'battery':
          _controller.add(ControllerBatteryEvent(
            level: (map['level'] as num?)?.toInt(),
            charging: map['charging'] == true,
          ));
          break;
      }
    } catch (_) {
      // Pesan tidak dikenal diabaikan.
    }
  }

  ControllerTransport _parseTransport(String? value) {
    switch (value) {
      case 'usb':
        return ControllerTransport.usb;
      case 'bluetooth':
        return ControllerTransport.bluetooth;
      default:
        return ControllerTransport.unknown;
    }
  }

  void _emitDisconnected() {
    _controller.add(const ControllerConnectionEvent(
      connected: false,
      transport: ControllerTransport.unknown,
    ));
  }

  @override
  void stop() {
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
  }

  @override
  void dispose() {
    stop();
    _controller.close();
  }
}