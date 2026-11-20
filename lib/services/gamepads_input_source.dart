import 'dart:async';

import 'package:gamepads/gamepads.dart';

import '../models/controller_event.dart';
import 'controller_input_source.dart';
import 'linux_controller_info_stub.dart'
    if (dart.library.io) 'linux_controller_info_io.dart';

/// Sumber input controller yang terpasang di **perangkat admin**
/// (Linux / Windows / Web) memakai plugin `gamepads`.
///
/// Plugin menormalkan tombol/axis ke layout standar Xbox, sehingga satu
/// pemetaan berlaku untuk semua platform:
///
/// | gamepads            | kontrol UI |
/// |---------------------|------------|
/// | a / b / x / y       | cross / circle / square / triangle |
/// | leftBumper/rightBumper | l1 / r1 |
/// | back / start / home | share / options / ps |
/// | leftStick/rightStick (klik) | l3 / r3 |
/// | dpad*               | dpad* |
/// | touchpad            | touchpad |
/// | leftTrigger/rightTrigger (axis) | l2 / r2 |
/// | leftStickX/Y        | leftStick (Y dibalik untuk UI) |
/// | rightStickX/Y       | rightStick (Y dibalik untuk UI) |
///
/// Catatan web: browser hanya menampilkan gamepad setelah ada interaksi
/// (tekan tombol pada controller). UI menampilkan petunjuk saat belum ada
/// controller.
///
/// Khusus DualShock 4 di Linux, layout `js0` dari driver `hid-playstation`
/// tidak sama dengan mapping bawaan plugin. Karena itu event mentah DS4
/// dipetakan sendiri di [_onRawEvent] (lihat komentar di sana).
class GamepadsInputSource implements ControllerInputSource {
  final StreamController<ControllerEvent> _controller =
      StreamController<ControllerEvent>.broadcast();

  StreamSubscription<GamepadEvent>? _rawSub;
  StreamSubscription<NormalizedGamepadEvent>? _eventSub;
  StreamSubscription<GamepadConnectionEvent>? _connSub;
  StreamSubscription<GamepadConnectionEvent>? _discSub;

  final Map<String, GamepadController> _pads = {};
  final Set<String> _connectedIds = {};
  final Map<String, double> _leftX = {};
  final Map<String, double> _leftY = {};
  final Map<String, double> _rightX = {};
  final Map<String, double> _rightY = {};
  final Set<String> _rawDpadPressed = {};

  bool _started = false;
  String? _activeId;

  Timer? _batteryTimer;
  String? _activeUniq;
  final LinuxTouchpadWatcher _touchpadWatcher = LinuxTouchpadWatcher();

  @override
  Stream<ControllerEvent> get events => _controller.stream;

  @override
  bool get isSimulated => false;

  @override
  void start() {
    if (_started) return;
    _started = true;

    // Event mentah dipakai untuk pemetaan DS4 yang presisi (lihat _onRawEvent).
    // Event ternormalisasi tetap dipakai untuk controller lain.
    _rawSub = Gamepads.events.listen(_onRawEvent);
    _eventSub = Gamepads.normalizedEvents.listen(_onNormalizedEvent);
    _connSub = Gamepads.onConnected.listen(_onConnected);
    _discSub = Gamepads.onDisconnected.listen(_onDisconnected);

    // Controller yang sudah terpasang sebelum stream aktif.
    unawaited(_loadInitial());
  }

  Future<void> _loadInitial() async {
    try {
      final list = await Gamepads.list();
      if (list.isEmpty) {
        _emitDisconnected();
        return;
      }
      for (final pad in list) {
        _pads[pad.id] = pad;
        _connectedIds.add(pad.id);
      }
      final first = list.first;
      _activeId ??= first.id;
      _controller.add(ControllerConnectionEvent(
        connected: true,
        transport: _transportOf(first.name),
        name: first.name,
      ));
      unawaited(_refreshDeviceInfo(first.id));
    } catch (_) {
      _emitDisconnected();
    }
  }

  void _onConnected(GamepadConnectionEvent e) {
    _connectedIds.add(e.gamepadId);
    _activeId ??= e.gamepadId;
    _controller.add(ControllerConnectionEvent(
      connected: true,
      transport: _transportOf(e.name),
      name: e.name,
    ));
    unawaited(_ensurePad(e.gamepadId));
    unawaited(_refreshDeviceInfo(e.gamepadId));
  }

  void _onDisconnected(GamepadConnectionEvent e) {
    _connectedIds.remove(e.gamepadId);
    _pads.remove(e.gamepadId)?.dispose();
    _leftX.remove(e.gamepadId);
    _leftY.remove(e.gamepadId);
    _rightX.remove(e.gamepadId);
    _rightY.remove(e.gamepadId);
    if (_activeId == e.gamepadId) {
      _activeId = _connectedIds.isEmpty ? null : _connectedIds.first;
      _activeUniq = null;
      _batteryTimer?.cancel();
      _batteryTimer = null;
      _touchpadWatcher.stop();
      if (_activeId != null) unawaited(_refreshDeviceInfo(_activeId!));
    }
    if (_connectedIds.isEmpty) _emitDisconnected();
  }

  /// Pastikan objek GamepadController tersedia untuk kontrol getar.
  Future<void> _ensurePad(String id) async {
    if (_pads.containsKey(id)) return;
    try {
      final list = await Gamepads.list();
      for (final pad in list) {
        if (pad.id == id) {
          _pads[id] = pad;
        } else {
          await pad.dispose();
        }
      }
    } catch (_) {
      // Getaran tetap akan gagal dengan aman bila controller tidak tersedia.
    }
  }

  /// Ambil info transport & baterai dari sysfs (khusus Linux). Di platform
  /// lain, metode ini tidak melakukan apa-apa.
  Future<void> _refreshDeviceInfo(String id) async {
    if (!_started || _activeId != id) return;

    final info = await LinuxControllerInfo.forGamepad(id);
    if (!_started || _activeId != id || info == null) return;

    _activeUniq = info.uniq;
    if (info.transport != ControllerTransport.unknown) {
      _controller.add(ControllerConnectionEvent(
        connected: true,
        transport: info.transport,
        name: info.name ?? _pads[id]?.name,
      ));
    }

    if (info.batteryLevel != null) {
      _emitBattery(info.batteryLevel, info.charging);
    }

    // Klik touchpad DS4 ada di event device terpisah (mouse BTN_LEFT).
    if (info.touchpadEventPath != null) {
      _touchpadWatcher.start(info.touchpadEventPath!, (pressed) {
        if (!_started) return;
        _controller.add(
            ControllerButtonEvent('touchpad', pressed: pressed));
      });
    } else {
      _touchpadWatcher.stop();
    }

    _startBatteryPolling();
  }

  void _startBatteryPolling() {
    _batteryTimer?.cancel();
    if (_activeUniq == null) return;
    _batteryTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      unawaited(_pollBattery());
    });
  }

  Future<void> _pollBattery() async {
    final uniq = _activeUniq;
    if (!_started || uniq == null) return;
    final battery = await LinuxControllerInfo.readBatteryForUniq(uniq);
    if (!_started || battery == null) return;
    _emitBattery(battery.level, battery.charging);
  }

  void _emitBattery(int? level, bool charging) {
    _controller.add(ControllerBatteryEvent(level: level, charging: charging));
  }

  @override
  Future<bool> rumble({
    double lowFrequency = 0.8,
    double highFrequency = 0.9,
    Duration duration = const Duration(milliseconds: 1200),
  }) async {
    final id = _activeId;
    if (id == null) return false;
    try {
      await _ensurePad(id);
      final pad = _pads[id];
      if (pad == null) return false;
      if (!await pad.hasRumble()) return false;
      return await pad.rumble(
        lowFrequency: lowFrequency,
        highFrequency: highFrequency,
        duration: duration,
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> stopRumble() async {
    final id = _activeId;
    final pad = id == null ? null : _pads[id];
    if (pad == null) return;
    try {
      await pad.stopRumble();
    } catch (_) {
      // Abaikan; controller mungkin sudah terlepas.
    }
  }

  void _emitDisconnected() {
    _controller.add(const ControllerConnectionEvent(
      connected: false,
      transport: ControllerTransport.unknown,
    ));
  }

  /// DS4 v1/v2 memakai layout js0 yang berbeda dari entri GameControllerDB
  /// bawaan plugin. Contoh nyata pada CUH-ZCT2x (054c:09cc):
  ///   js button 0=cross, 1=circle, 2=triangle, 3=square,
  ///             4=l1, 5=r1, 6=l2, 7=r2, 8=share, 9=options,
  ///             10=ps, 11=l3, 12=r3
  ///   js axis   0=leftX, 1=leftY, 2=l2, 3=rightX,
  ///             4=rightY, 5=r2, 6=dpadX, 7=dpadY
  bool _isPlayStationRaw(GamepadEvent e) {
    if (e.vendorId != 0x054c) return false;
    // DualShock 4 v1 (CUH-ZCT1) dan v2 (CUH-ZCT2).
    return e.productId == 0x05c4 || e.productId == 0x09cc;
  }

  void _onRawEvent(GamepadEvent e) {
    if (!_isPlayStationRaw(e)) return;
    if (_activeId != null && e.gamepadId != _activeId) return;
    _activeId ??= e.gamepadId;

    if (e.type == KeyType.button) {
      _handleDs4Button(e.key, e.value);
    } else {
      _handleDs4Axis(e.key, e.value);
    }
  }

  void _handleDs4Button(String key, double value) {
    switch (key) {
      case '0':
        _emitButton('cross', value);
        break;
      case '1':
        _emitButton('circle', value);
        break;
      case '2':
        _emitButton('triangle', value);
        break;
      case '3':
        _emitButton('square', value);
        break;
      case '4':
        _emitButton('l1', value);
        break;
      case '5':
        _emitButton('r1', value);
        break;
      case '6':
        // Tombol digital L2; nilai analog tetap datang dari axis 4.
        _controller.add(
            ControllerTriggerEvent('l2', value > 0.5 ? 1.0 : 0.0));
        break;
      case '7':
        _controller.add(
            ControllerTriggerEvent('r2', value > 0.5 ? 1.0 : 0.0));
        break;
      case '8':
        _emitButton('share', value);
        break;
      case '9':
        _emitButton('options', value);
        break;
      case '10':
        _emitButton('ps', value);
        break;
      case '11':
        _emitButton('l3', value);
        break;
      case '12':
        _emitButton('r3', value);
        break;
    }
  }

  void _handleDs4Axis(String key, double value) {
    final id = _activeId;
    if (id == null) return;

    switch (key) {
      case '0': // leftX
        _leftX[id] = _normalizeStick(value);
        _emitStick('leftStick', _leftX[id] ?? 0, _leftY[id] ?? 0);
        break;
      case '1': // leftY (js: up = negatif, plugin: up = positif)
        _leftY[id] = -_normalizeStick(value);
        _emitStick('leftStick', _leftX[id] ?? 0, _leftY[id] ?? 0);
        break;
      case '2': // L2 analog (ABS_Z)
        _controller.add(
            ControllerTriggerEvent('l2', _normalizeTrigger(value)));
        break;
      case '3': // rightX (ABS_RX)
        _rightX[id] = _normalizeStick(value);
        _emitStick('rightStick', _rightX[id] ?? 0, _rightY[id] ?? 0);
        break;
      case '4': // rightY (ABS_RY)
        _rightY[id] = -_normalizeStick(value);
        _emitStick('rightStick', _rightX[id] ?? 0, _rightY[id] ?? 0);
        break;
      case '5': // R2 analog (ABS_RZ)
        _controller.add(
            ControllerTriggerEvent('r2', _normalizeTrigger(value)));
        break;
      case '6': // D-Pad X
        _setDpad('dpadLeft', value < -0.5);
        _setDpad('dpadRight', value > 0.5);
        break;
      case '7': // D-Pad Y (up = negatif)
        _setDpad('dpadUp', value < -0.5);
        _setDpad('dpadDown', value > 0.5);
        break;
    }
  }

  void _emitButton(String control, double value) {
    _controller.add(
        ControllerButtonEvent(control, pressed: value > 0.5));
  }

  void _setDpad(String control, bool pressed) {
    final wasPressed = _rawDpadPressed.contains(control);
    if (pressed == wasPressed) return;
    if (pressed) {
      _rawDpadPressed.add(control);
    } else {
      _rawDpadPressed.remove(control);
    }
    _controller.add(ControllerButtonEvent(control, pressed: pressed));
  }

  double _normalizeStick(double value) =>
      (value / 32767.0).clamp(-1.0, 1.0);

  double _normalizeTrigger(double value) =>
      ((value + 32768.0) / 65535.0).clamp(0.0, 1.0);

  void _onNormalizedEvent(NormalizedGamepadEvent e) {
    // DS4 sudah ditangani lewat event mentah (_onRawEvent) karena layout
    // js0-nya berbeda dari mapping bawaan plugin.
    if (_isPlayStationRaw(e.rawEvent)) return;

    // Hanya pakai satu controller (yang pertama terhubung) agar input tidak
    // tercampur bila ada dua controller terpasang.
    if (_activeId != null && e.gamepadId != _activeId) return;
    final id = e.gamepadId;
    final value = e.value;

    if (e.button != null) {
      final control = _buttonControl(e.button!);
      if (control == null) return;

      // Trigger bisa datang sebagai tombol digital atau axis analog.
      if (control == 'l2' || control == 'r2') {
        _controller.add(
            ControllerTriggerEvent(control, value.clamp(0.0, 1.0)));
        return;
      }
      _controller.add(
          ControllerButtonEvent(control, pressed: value > 0.5));
      return;
    }

    final axis = e.axis;
    if (axis == null) return;

    switch (axis) {
      case GamepadAxis.leftStickX:
        _leftX[id] = value;
        _emitStick('leftStick', _leftX[id] ?? 0, _leftY[id] ?? 0);
        break;
      case GamepadAxis.leftStickY:
        _leftY[id] = value;
        _emitStick('leftStick', _leftX[id] ?? 0, _leftY[id] ?? 0);
        break;
      case GamepadAxis.rightStickX:
        _rightX[id] = value;
        _emitStick('rightStick', _rightX[id] ?? 0, _rightY[id] ?? 0);
        break;
      case GamepadAxis.rightStickY:
        _rightY[id] = value;
        _emitStick('rightStick', _rightX[id] ?? 0, _rightY[id] ?? 0);
        break;
      case GamepadAxis.leftTrigger:
        _controller.add(
            ControllerTriggerEvent('l2', value.clamp(0.0, 1.0)));
        break;
      case GamepadAxis.rightTrigger:
        _controller.add(
            ControllerTriggerEvent('r2', value.clamp(0.0, 1.0)));
        break;
    }
  }

  void _emitStick(String control, double x, double y) {
    // Plugin: Up = +1. UI Flutter: Y ke bawah = positif → dibalik.
    _controller.add(ControllerAnalogEvent(
      control,
      x.clamp(-1.0, 1.0),
      (-y).clamp(-1.0, 1.0),
    ));
  }

  String? _buttonControl(GamepadButton b) {
    switch (b) {
      case GamepadButton.a:
        return 'cross';
      case GamepadButton.b:
        return 'circle';
      case GamepadButton.x:
        return 'square';
      case GamepadButton.y:
        return 'triangle';
      case GamepadButton.leftBumper:
        return 'l1';
      case GamepadButton.rightBumper:
        return 'r1';
      case GamepadButton.back:
        return 'share';
      case GamepadButton.start:
        return 'options';
      case GamepadButton.home:
        return 'ps';
      case GamepadButton.leftStick:
        return 'l3';
      case GamepadButton.rightStick:
        return 'r3';
      case GamepadButton.dpadUp:
        return 'dpadUp';
      case GamepadButton.dpadDown:
        return 'dpadDown';
      case GamepadButton.dpadLeft:
        return 'dpadLeft';
      case GamepadButton.dpadRight:
        return 'dpadRight';
      case GamepadButton.touchpad:
        return 'touchpad';
      case GamepadButton.leftTrigger:
        return 'l2';
      case GamepadButton.rightTrigger:
        return 'r2';
    }
  }

  ControllerTransport _transportOf(String name) {
    final n = name.toLowerCase();
    // Catatan: DualShock 4 tetap bernama "Wireless Controller" walau dicolok
    // USB. Karena itu "wireless" saja TIDAK boleh dianggap Bluetooth; info
    // transport yang akurat diambil dari sysfs Linux (_refreshDeviceInfo).
    if (n.contains('bluetooth')) return ControllerTransport.bluetooth;
    if (n.contains('usb') || n.contains('wired')) {
      return ControllerTransport.usb;
    }
    return ControllerTransport.unknown;
  }

  @override
  void stop() {
    _started = false;
    _rawSub?.cancel();
    _rawSub = null;
    _eventSub?.cancel();
    _eventSub = null;
    _connSub?.cancel();
    _connSub = null;
    _discSub?.cancel();
    _discSub = null;

    _batteryTimer?.cancel();
    _batteryTimer = null;
    _touchpadWatcher.stop();
    unawaited(stopRumble());

    for (final pad in _pads.values) {
      pad.dispose();
    }
    _pads.clear();
    _connectedIds.clear();
    _activeId = null;
    _activeUniq = null;
    _leftX.clear();
    _leftY.clear();
    _rightX.clear();
    _rightY.clear();
    _rawDpadPressed.clear();
  }

  @override
  void dispose() {
    stop();
    _controller.close();
  }
}
