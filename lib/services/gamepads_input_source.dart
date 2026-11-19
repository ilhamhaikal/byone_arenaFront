import 'dart:async';

import 'package:gamepads/gamepads.dart';

import '../models/controller_event.dart';
import 'controller_input_source.dart';

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
class GamepadsInputSource implements ControllerInputSource {
  final StreamController<ControllerEvent> _controller =
      StreamController<ControllerEvent>.broadcast();

  StreamSubscription<NormalizedGamepadEvent>? _eventSub;
  StreamSubscription<GamepadConnectionEvent>? _connSub;
  StreamSubscription<GamepadConnectionEvent>? _discSub;

  final Map<String, GamepadController> _pads = {};
  final Set<String> _connectedIds = {};
  final Map<String, double> _leftX = {};
  final Map<String, double> _leftY = {};
  final Map<String, double> _rightX = {};
  final Map<String, double> _rightY = {};

  bool _started = false;
  String? _activeId;

  @override
  Stream<ControllerEvent> get events => _controller.stream;

  @override
  bool get isSimulated => false;

  @override
  void start() {
    if (_started) return;
    _started = true;

    _eventSub = Gamepads.normalizedEvents.listen(_onEvent);
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
    }
    if (_connectedIds.isEmpty) _emitDisconnected();
  }

  void _emitDisconnected() {
    _controller.add(const ControllerConnectionEvent(
      connected: false,
      transport: ControllerTransport.unknown,
    ));
  }

  void _onEvent(NormalizedGamepadEvent e) {
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
    if (n.contains('wireless') || n.contains('bluetooth')) {
      return ControllerTransport.bluetooth;
    }
    if (n.contains('usb') || n.contains('wired')) {
      return ControllerTransport.usb;
    }
    return ControllerTransport.unknown;
  }

  @override
  void stop() {
    _started = false;
    _eventSub?.cancel();
    _eventSub = null;
    _connSub?.cancel();
    _connSub = null;
    _discSub?.cancel();
    _discSub = null;

    for (final pad in _pads.values) {
      pad.dispose();
    }
    _pads.clear();
    _connectedIds.clear();
    _activeId = null;
    _leftX.clear();
    _leftY.clear();
    _rightX.clear();
    _rightY.clear();
  }

  @override
  void dispose() {
    stop();
    _controller.close();
  }
}
