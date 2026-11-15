import 'dart:async';

import 'package:flutter/material.dart';

import '../models/controller_event.dart';
import '../models/controller_profile.dart';
import '../models/controller_profiles.dart';
import '../services/controller_input_source.dart';
import '../services/ws_controller_source.dart';

enum ControllerHealthStatus { disconnected, checking, needsCheck, healthy }

/// Sumber input dipilih saat build:
/// `--dart-define=CONTROLLER_SOURCE=ws` untuk memakai WebSocket.
const String _controllerSourceMode =
    String.fromEnvironment('CONTROLLER_SOURCE', defaultValue: 'mock');

/// State & logika halaman Controller Health Check.
class ControllerHealthProvider extends ChangeNotifier {
  ControllerHealthProvider({ControllerProfile? profile})
      : profile = profile ?? ControllerProfiles.ds4;

  final ControllerProfile profile;

  late final ControllerInputSource _source = _controllerSourceMode == 'ws'
      ? WsControllerInputSource()
      : MockControllerInputSource();

  StreamSubscription<ControllerEvent>? _sub;
  Timer? _vibrationTimer;
  bool _started = false;

  bool connected = false;
  ControllerTransport transport = ControllerTransport.unknown;
  int? batteryLevel;
  bool charging = false;

  final Set<String> _pressed = {};
  final Set<String> _checkedButtons = {};
  final Map<String, double> _triggers = {};
  final Map<String, double> _maxTriggers = {};
  final Map<String, Offset> _analogs = {
    'leftStick': Offset.zero,
    'rightStick': Offset.zero,
  };
  final Set<String> _movedAnalogs = {};

  DateTime? lastEventAt;

  VibrationState vibration = VibrationState.idle;

  // ── Getter untuk UI ────────────────────────────────────────────────────
  bool get isSimulated => _source.isSimulated;
  bool get isConnected => connected;
  Set<String> get pressed => _pressed;
  Set<String> get checkedButtons => _checkedButtons;
  Map<String, double> get triggers => _triggers;
  Map<String, Offset> get analogs => _analogs;

  Offset analogOf(String id) => _analogs[id] ?? Offset.zero;
  double triggerOf(String id) => _triggers[id] ?? 0;

  bool isControlTested(String id) =>
      _checkedButtons.contains(id) || _pressed.contains(id);

  bool get allButtonsTested =>
      profile.requiredButtons.every(_checkedButtons.contains);

  bool get allTriggersTested =>
      profile.requiredTriggers.every((id) => (_maxTriggers[id] ?? 0) >= 0.9);

  bool get allAnalogsTested =>
      profile.requiredAnalogs.every(_movedAnalogs.contains);

  int get testedButtonCount => profile.requiredButtons
      .where(_checkedButtons.contains)
      .length;

  /// 0–100. Koneksi 20, tombol 40, trigger 20, analog 20.
  int get healthScore {
    if (!connected) return 0;
    final btn = profile.requiredButtons.isEmpty
        ? 1.0
        : testedButtonCount / profile.requiredButtons.length;
    final trg = profile.requiredTriggers.isEmpty
        ? 1.0
        : profile.requiredTriggers
                .where((id) => (_maxTriggers[id] ?? 0) >= 0.9)
                .length /
            profile.requiredTriggers.length;
    final ana = profile.requiredAnalogs.isEmpty
        ? 1.0
        : _movedAnalogs.length / profile.requiredAnalogs.length;
    return (20 + 40 * btn + 20 * trg + 20 * ana).round().clamp(0, 100);
  }

  ControllerHealthStatus get healthStatus {
    if (!connected) return ControllerHealthStatus.disconnected;
    if (allButtonsTested && allTriggersTested && allAnalogsTested) {
      return ControllerHealthStatus.healthy;
    }
    if (testedButtonCount == 0 && _movedAnalogs.isEmpty) {
      return ControllerHealthStatus.checking;
    }
    return ControllerHealthStatus.needsCheck;
  }

  bool get isHealthy => healthStatus == ControllerHealthStatus.healthy;

  /// Label kondisi analog (Normal bila mendekati pusat saat dilepas).
  String analogCondition(String id) {
    final v = analogOf(id);
    if (!_movedAnalogs.contains(id)) return 'Menunggu';
    if (v.distance < 0.15) return 'Normal';
    return 'Drift (${v.distance.toStringAsFixed(2)})';
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────
  void start() {
    if (_started) return;
    _started = true;
    _sub = _source.events.listen(_onEvent);
    _source.start();
  }

  void stop() {
    _started = false;
    _sub?.cancel();
    _sub = null;
    _source.stop();
    connected = false;
    _pressed.clear();
    notifyListeners();
  }

  void retest() {
    _checkedButtons.clear();
    _maxTriggers.clear();
    _movedAnalogs.clear();
    _triggers.clear();
    _analogs['leftStick'] = Offset.zero;
    _analogs['rightStick'] = Offset.zero;
    vibration = VibrationState.idle;
    lastEventAt = null;
    _source.stop();
    _source.start();
    notifyListeners();
  }

  void requestVibration() {
    if (!profile.capabilities.rumble) return;
    vibration = VibrationState.testing;
    notifyListeners();
    _vibrationTimer?.cancel();
    _vibrationTimer = Timer(const Duration(milliseconds: 1600), () {
      vibration = VibrationState.done;
      notifyListeners();
    });
  }

  void _onEvent(ControllerEvent event) {
    lastEventAt = DateTime.now();

    switch (event) {
      case ControllerButtonEvent e:
        if (e.pressed) {
          _pressed.add(e.control);
          _checkedButtons.add(e.control);
        } else {
          _pressed.remove(e.control);
        }
        break;
      case ControllerAnalogEvent e:
        _analogs[e.control] = Offset(
          e.x.clamp(-1.0, 1.0),
          e.y.clamp(-1.0, 1.0),
        );
        if (_analogs[e.control]!.distance >= 0.5) {
          _movedAnalogs.add(e.control);
        }
        break;
      case ControllerTriggerEvent e:
        _triggers[e.control] = e.value.clamp(0.0, 1.0);
        final max = _maxTriggers[e.control] ?? 0;
        if (e.value > max) _maxTriggers[e.control] = e.value;
        break;
      case ControllerConnectionEvent e:
        connected = e.connected;
        transport = e.transport;
        if (!e.connected) {
          _pressed.clear();
          _triggers.clear();
        }
        break;
      case ControllerBatteryEvent e:
        batteryLevel = e.level;
        charging = e.charging;
        break;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _vibrationTimer?.cancel();
    _sub?.cancel();
    _source.dispose();
    super.dispose();
  }
}

enum VibrationState { idle, testing, done }