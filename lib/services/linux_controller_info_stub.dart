import '../models/controller_event.dart';

/// Stub untuk platform non-Linux / web.
///
/// Implementasi nyata ada di `linux_controller_info_io.dart` dan hanya
/// dipakai saat `dart.library.io` tersedia.
class LinuxControllerBattery {
  final int? level;
  final bool charging;

  const LinuxControllerBattery({this.level, this.charging = false});
}

class LinuxControllerInfo {
  final String jsName;
  final String? name;
  final int vendorId;
  final int productId;
  final ControllerTransport transport;
  final String? uniq;
  final int? batteryLevel;
  final bool charging;
  final String? touchpadEventPath;

  const LinuxControllerInfo({
    required this.jsName,
    this.name,
    this.vendorId = 0,
    this.productId = 0,
    this.transport = ControllerTransport.unknown,
    this.uniq,
    this.batteryLevel,
    this.charging = false,
    this.touchpadEventPath,
  });

  static Future<LinuxControllerInfo?> forGamepad(String gamepadId) async =>
      null;

  static Future<LinuxControllerBattery?> readBatteryForUniq(
          String? uniq) async =>
      null;

  static Future<String?> findTouchpadEvent(String? uniq) async => null;
}

class LinuxTouchpadWatcher {
  void start(String eventPath, void Function(bool pressed) onButton) {}

  void stop() {}
}
