import 'controller_layout.dart';

/// Kemampuan hardware sebuah model. Widget menyesuaikan diri dari sini,
/// sehingga DS3 (tanpa touchpad/light bar) atau DS5 (adaptive trigger) tidak
/// memerlukan perubahan halaman.
class ControllerCapabilities {
  final bool battery;
  final bool touchpad;
  final bool lightBar;
  final bool rumble;
  final bool pressureTriggers;
  final bool touchpadClick;

  const ControllerCapabilities({
    this.battery = true,
    this.touchpad = true,
    this.lightBar = true,
    this.rumble = true,
    this.pressureTriggers = true,
    this.touchpadClick = true,
  });
}

/// Profil satu model controller (mis. DualShock 4).
class ControllerProfile {
  /// ID yang juga dipakai backend: 'ds4', nanti 'ds3' / 'ds5'.
  final String id;
  final String family;
  final String displayName;
  final String asset;
  final ControllerLayout layout;
  final ControllerCapabilities capabilities;

  /// Kontrol yang harus berhasil diuji agar dinyatakan sehat.
  final List<String> requiredButtons;
  final List<String> requiredTriggers;
  final List<String> requiredAnalogs;

  const ControllerProfile({
    required this.id,
    required this.family,
    required this.displayName,
    required this.asset,
    required this.layout,
    required this.capabilities,
    required this.requiredButtons,
    this.requiredTriggers = const ['l2', 'r2'],
    this.requiredAnalogs = const ['leftStick', 'rightStick'],
  });

  String get title => '$family · $displayName';
}