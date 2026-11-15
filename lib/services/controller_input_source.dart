import 'dart:async';
import 'dart:math' as math;

import '../models/controller_event.dart';

/// Sumber event input controller.
///
/// Implementasi saat ini: [MockControllerInputSource] (simulasi).
/// Nanti: `WsControllerInputSource` yang membaca event dari service Go.
abstract class ControllerInputSource {
  Stream<ControllerEvent> get events;

  /// True bila data berasal dari simulasi (ditampilkan sebagai badge di UI).
  bool get isSimulated;

  void start();
  void stop();
  void dispose();
}

/// Simulasi DualShock 4: menekan setiap tombol bergiliran, menggerakkan kedua
/// analog, dan menarik trigger 0→100%. Cukup untuk mendemokan seluruh UI
/// sebelum integrasi hardware/backend siap.
class MockControllerInputSource implements ControllerInputSource {
  final StreamController<ControllerEvent> _controller =
      StreamController<ControllerEvent>.broadcast();

  Timer? _timer;
  Stopwatch? _clock;
  final Set<String> _pressed = {};
  double _lastL2 = 0;
  double _lastR2 = 0;

  static const _tick = Duration(milliseconds: 50);

  /// Satu siklus demo (detik).
  static const double _cycleSeconds = 18.0;

  /// Daftar tombol yang ditekan bergiliran, masing-masing 0.6 detik.
  static const List<String> _sequence = [
    'cross',
    'circle',
    'square',
    'triangle',
    'l1',
    'r1',
    'share',
    'options',
    'ps',
    'l3',
    'r3',
    'touchpad',
    'dpadUp',
    'dpadRight',
    'dpadDown',
    'dpadLeft',
  ];

  @override
  Stream<ControllerEvent> get events => _controller.stream;

  @override
  bool get isSimulated => true;

  @override
  void start() {
    if (_timer != null) return;
    _clock = Stopwatch()..start();
    _pressed.clear();
    _lastL2 = 0;
    _lastR2 = 0;

    _controller.add(const ControllerConnectionEvent(
      connected: true,
      transport: ControllerTransport.bluetooth,
    ));
    _controller.add(const ControllerBatteryEvent(level: 78));

    _timer = Timer.periodic(_tick, (_) => _emit());
  }

  void _emit() {
    final t = (_clock?.elapsedMilliseconds ?? 0) / 1000.0;
    final cycle = t % _cycleSeconds;

    // ── Tombol bergiliran (0.0 – 9.6 detik) ──
    final active = <String>{};
    for (var i = 0; i < _sequence.length; i++) {
      final start = i * 0.6;
      if (cycle >= start && cycle < start + 0.45) {
        active.add(_sequence[i]);
      }
    }
    for (final id in active) {
      if (!_pressed.contains(id)) {
        _pressed.add(id);
        _controller.add(ControllerButtonEvent(id, pressed: true));
      }
    }
    for (final id in _pressed.toList()) {
      if (!active.contains(id)) {
        _pressed.remove(id);
        _controller.add(ControllerButtonEvent(id, pressed: false));
      }
    }

    // ── Trigger: L2 10–12s, R2 12–14s (ramp 0→1→0) ──
    double ramp(double from, double to) {
      if (cycle < from || cycle > to) return 0;
      final p = (cycle - from) / (to - from); // 0..1
      return p <= 0.5 ? p * 2 : (1 - p) * 2;
    }

    final l2 = ramp(10.0, 12.0);
    final r2 = ramp(12.0, 14.0);
    if (l2 != _lastL2) {
      _lastL2 = l2;
      _controller.add(ControllerTriggerEvent('l2', l2));
    }
    if (r2 != _lastR2) {
      _lastR2 = r2;
      _controller.add(ControllerTriggerEvent('r2', r2));
    }

    // ── Analog: kiri berputar 0–6s, kanan lissajous 6–14s ──
    double lx = 0, ly = 0, rx = 0, ry = 0;
    if (cycle < 6.0) {
      final a = cycle * 2 * math.pi / 3.0;
      lx = math.cos(a) * 0.85;
      ly = math.sin(a) * 0.85;
    } else if (cycle < 14.0) {
      final a = (cycle - 6.0) * 1.4;
      rx = math.sin(a) * 0.75;
      ry = math.cos(a * 1.7) * 0.75;
    }
    _controller.add(ControllerAnalogEvent('leftStick', lx, ly));
    _controller.add(ControllerAnalogEvent('rightStick', rx, ry));
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
    _clock?.stop();
    _clock = null;
    _pressed.clear();
  }

  @override
  void dispose() {
    stop();
    _controller.close();
  }
}