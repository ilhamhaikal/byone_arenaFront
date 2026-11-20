import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/controller_event.dart';
import '../models/controller_profile.dart';
import '../models/controller_profiles.dart';
import '../services/controller_input_source.dart';
import '../services/gamepads_input_source.dart';
import '../services/ws_controller_source.dart';

enum ControllerHealthStatus { disconnected, checking, needsCheck, healthy }

/// Sumber input dipilih saat build:
/// - default: `gamepads` (controller di perangkat admin: Linux/Windows/Web)
/// - `--dart-define=CONTROLLER_SOURCE=mock` untuk simulasi
/// - `--dart-define=CONTROLLER_SOURCE=ws` untuk WebSocket (masa depan)
const String _controllerSourceMode = String.fromEnvironment(
  'CONTROLLER_SOURCE',
  defaultValue: 'gamepads',
);

/// State & logika halaman Controller Health Check.
class ControllerHealthProvider extends ChangeNotifier {
  ControllerHealthProvider({ControllerProfile? profile})
      : profile = profile ?? ControllerProfiles.ds4;

  final ControllerProfile profile;

  late final ControllerInputSource _source = switch (_controllerSourceMode) {
    'mock' => MockControllerInputSource(),
    'ws' => WsControllerInputSource(),
    _ => GamepadsInputSource(),
  };

  StreamSubscription<ControllerEvent>? _sub;
  Timer? _vibrationTimer;
  bool _started = false;

  bool connected = false;
  ControllerTransport transport = ControllerTransport.unknown;
  int? batteryLevel;
  bool charging = false;
  String? deviceName;

  final Set<String> _pressed = {};
  final Set<String> _checkedButtons = {};
  final Map<String, double> _triggers = {};
  final Map<String, double> _maxTriggers = {};
  final Map<String, Offset> _analogs = {
    'leftStick': Offset.zero,
    'rightStick': Offset.zero,
  };
  final Set<String> _movedAnalogs = {};
  final Map<String, StickStats> _stickStats = {};
  final Map<String, Timer> _restTimers = {};

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

  /// Statistik stick (jangkauan, drift, lingkaran). Null sebelum diuji.
  StickStats? statsOf(String id) => _stickStats[id];

  bool isControlTested(String id) =>
      _checkedButtons.contains(id) || _pressed.contains(id);

  /// True bila trigger pernah mencapai >= 90% (bukan nilai sesaat).
  bool isTriggerReached(String id) => (_maxTriggers[id] ?? 0) >= 0.9;

  /// True bila analog pernah digerakkan melewati ambang.
  bool isAnalogTested(String id) => _movedAnalogs.contains(id);

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

  /// Label kondisi analog berdasarkan pengukuran nyata:
  /// drift saat dilepas, jangkauan maksimum, dan kerataan lingkaran.
  String analogCondition(String id) {
    final s = _stickStats[id];
    if (s == null || !s.hasSamples) return 'Menunggu';

    final rest = s.restDistance;
    if (rest != null && rest > 0.12) {
      return 'Drift (${rest.toStringAsFixed(2)})';
    }
    if (s.maxRadius < 0.85) {
      return 'Jangkauan ${(s.maxRadius * 100).round()}%';
    }
    if (s.allQuadrants && s.circularity < 0.8) {
      return 'Lingkaran ${(s.circularity * 100).round()}%';
    }
    return 'Normal';
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
    unawaited(_source.stopRumble());
    _source.stop();
    connected = false;
    _pressed.clear();
    // Sengaja TIDAK memanggil notifyListeners().
    // stop() dipanggil dari didUpdateWidget/didChangeDependencies saat fase
    // build; memberi notifikasi di sini memicu "setState() called during
    // build". Halaman yang tidak aktif memang tidak perlu rebuild.
  }

  void retest() {
    _checkedButtons.clear();
    _maxTriggers.clear();
    _movedAnalogs.clear();
    _triggers.clear();
    _analogs['leftStick'] = Offset.zero;
    _analogs['rightStick'] = Offset.zero;
    for (final t in _restTimers.values) {
      t.cancel();
    }
    _restTimers.clear();
    _stickStats.clear();
    vibration = VibrationState.idle;
    lastEventAt = null;
    _source.stop();
    _source.start();
    notifyListeners();
  }

  Future<void> requestVibration() async {
    if (!profile.capabilities.rumble) return;
    vibration = VibrationState.testing;
    notifyListeners();
    _vibrationTimer?.cancel();

    final accepted = await _source.rumble(
      lowFrequency: 0.8,
      highFrequency: 0.95,
      duration: const Duration(milliseconds: 1200),
    );
    if (!accepted) {
      vibration = VibrationState.failed;
      notifyListeners();
      return;
    }

    _vibrationTimer = Timer(const Duration(milliseconds: 1400), () {
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
        final offset = Offset(
          e.x.clamp(-1.0, 1.0),
          e.y.clamp(-1.0, 1.0),
        );
        _analogs[e.control] = offset;
        if (offset.distance >= 0.5) {
          _movedAnalogs.add(e.control);
        }
        _stickStats
            .putIfAbsent(e.control, () => StickStats())
            .add(offset.dx, offset.dy);
        _scheduleRestCheck(e.control);
        break;
      case ControllerTriggerEvent e:
        _triggers[e.control] = e.value.clamp(0.0, 1.0);
        final max = _maxTriggers[e.control] ?? 0;
        if (e.value > max) _maxTriggers[e.control] = e.value;
        break;
      case ControllerConnectionEvent e:
        connected = e.connected;
        transport = e.transport;
        deviceName = e.connected ? (e.name ?? deviceName) : null;
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

  /// Catat posisi "diam" stick setelah 700 ms mendekati pusat. Nilai ini
  /// dipakai untuk mendeteksi drift (stick tidak kembali ke tengah).
  void _scheduleRestCheck(String id) {
    final distance = _analogs[id]?.distance ?? 0;
    _restTimers[id]?.cancel();
    if (distance >= 0.3) return;

    _restTimers[id] = Timer(const Duration(milliseconds: 700), () {
      final current = _analogs[id]?.distance ?? 0;
      if (current >= 0.3) return;
      final stats = _stickStats[id];
      if (stats != null) {
        stats.restDistance = current;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _vibrationTimer?.cancel();
    for (final t in _restTimers.values) {
      t.cancel();
    }
    _restTimers.clear();
    _sub?.cancel();
    _source.dispose();
    super.dispose();
  }
}

enum VibrationState { idle, testing, done, failed }

/// Statistik pengukuran satu stick.
class StickStats {
  double minX = 0, maxX = 0, minY = 0, maxY = 0;
  double maxRadius = 0;

  /// Jarak stick dari pusat setelah dilepas & diam (indikator drift).
  double? restDistance;

  int _samples = 0;
  final List<double> _quadrantMax = [0, 0, 0, 0];

  bool get hasSamples => _samples > 0;
  bool get allQuadrants => _quadrantMax.every((v) => v > 0);

  /// Rasio jangkauan terkecil vs terbesar antar kuadran (0–1).
  double get circularity {
    if (!allQuadrants) return 0;
    final minQ = _quadrantMax.reduce((a, b) => a < b ? a : b);
    final maxQ = _quadrantMax.reduce((a, b) => a > b ? a : b);
    if (maxQ <= 0) return 0;
    return (minQ / maxQ).clamp(0.0, 1.0);
  }

  void add(double x, double y) {
    _samples++;
    if (x < minX) minX = x;
    if (x > maxX) maxX = x;
    if (y < minY) minY = y;
    if (y > maxY) maxY = y;

    final d = math.sqrt(x * x + y * y);
    if (d > maxRadius) maxRadius = d;

    final angle = math.atan2(y, x);
    var q = ((angle + math.pi) / (math.pi / 2)).floor();
    if (q < 0) q = 0;
    if (q > 3) q = 3;
    if (d > _quadrantMax[q]) _quadrantMax[q] = d;
  }
}