import 'dart:ui';

/// Jenis transport koneksi controller.
enum ControllerTransport { usb, bluetooth, unknown }

extension ControllerTransportLabel on ControllerTransport {
  String get label {
    switch (this) {
      case ControllerTransport.usb:
        return 'USB';
      case ControllerTransport.bluetooth:
        return 'Bluetooth';
      case ControllerTransport.unknown:
        return 'Tidak diketahui';
    }
  }
}

/// Event mentah dari sumber input (mock sekarang, WebSocket nanti).
sealed class ControllerEvent {
  const ControllerEvent();
}

/// Tombol / D-Pad / L3 / R3 / touchpad ditekan atau dilepas.
class ControllerButtonEvent extends ControllerEvent {
  final String control;
  final bool pressed;

  const ControllerButtonEvent(this.control, {required this.pressed});
}

/// Posisi analog, ternormalisasi -1.0 .. 1.0.
class ControllerAnalogEvent extends ControllerEvent {
  final String control;
  final double x;
  final double y;

  const ControllerAnalogEvent(this.control, this.x, this.y);
}

/// Tekanan trigger, 0.0 .. 1.0.
class ControllerTriggerEvent extends ControllerEvent {
  final String control;
  final double value;

  const ControllerTriggerEvent(this.control, this.value);
}

/// Status koneksi controller.
class ControllerConnectionEvent extends ControllerEvent {
  final bool connected;
  final ControllerTransport transport;

  const ControllerConnectionEvent({
    required this.connected,
    required this.transport,
  });
}

/// Level baterai (null = tidak tersedia, mis. USB tanpa data baterai).
class ControllerBatteryEvent extends ControllerEvent {
  final int? level;
  final bool charging;

  const ControllerBatteryEvent({this.level, this.charging = false});
}

/// Deskripsi singkat bagian controller pada layout (koordinat viewBox).
class ControlGeometry {
  final Offset center;
  final double radius;
  final Color color;

  const ControlGeometry({
    required this.center,
    required this.radius,
    required this.color,
  });
}