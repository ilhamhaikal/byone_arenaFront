import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../config/app_theme.dart';
import '../../../models/controller_layout.dart';
import '../../../providers/controller_health_provider.dart';

/// Visualisasi DualShock 4: SVG realistis + overlay animasi (tombol, analog,
/// trigger, light bar).
///
/// SVG menjadi dasar bentuk; overlay digambar dengan CustomPaint memakai
/// koordinat viewBox yang sama sehingga tetap sejajar pada semua ukuran.
class ControllerVisualization extends StatefulWidget {
  const ControllerVisualization({super.key});

  @override
  State<ControllerVisualization> createState() =>
      _ControllerVisualizationState();
}

class _ControllerVisualizationState extends State<ControllerVisualization>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  final Map<String, double> _energy = {};

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _updateEnergy(ControllerHealthProvider p) {
    p.profile.layout.controls.forEach((id, _) {
      final target = p.pressed.contains(id) ? 1.0 : 0.0;
      final current = _energy[id] ?? 0.0;
      _energy[id] = current + (target - current) * 0.22;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ControllerHealthProvider>();

    return AspectRatio(
      aspectRatio: p.profile.layout.aspectRatio,
      child: AnimatedBuilder(
        animation: _ticker,
        builder: (context, _) {
          _updateEnergy(p);
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _PlatformGlowPainter(
                  pulse: _ticker.value,
                  connected: p.connected,
                ),
              ),
              SvgPicture.asset(
                p.profile.asset,
                fit: BoxFit.contain,
              ),
              CustomPaint(
                painter: _ControllerOverlayPainter(
                  layout: p.profile.layout,
                  energy: Map<String, double>.from(_energy),
                  analogs: Map<String, Offset>.from(p.analogs),
                  triggers: Map<String, double>.from(p.triggers),
                  connected: p.connected,
                  pulse: _ticker.value,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlatformGlowPainter extends CustomPainter {
  final double pulse;
  final bool connected;

  _PlatformGlowPainter({required this.pulse, required this.connected});

  @override
  void paint(Canvas canvas, Size size) {
    final color = connected ? kPrimaryBlue : kTextSecondary;
    final center = Offset(size.width / 2, size.height * 0.855);
    final w = size.width * 0.66;
    final h = size.height * 0.17;
    final p = 0.5 + 0.5 * math.sin(pulse * 2 * math.pi);

    // bayangan di bawah controller
    canvas.drawOval(
      Rect.fromCenter(center: center, width: w * 0.95, height: h * 0.75),
      Paint()..color = Colors.black.withAlpha(150),
    );

    // glow radial
    canvas.drawOval(
      Rect.fromCenter(center: center, width: w, height: h),
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          w / 2,
          [color.withAlpha((60 + 30 * p).round()), Colors.transparent],
        ),
    );

    // cincin konsentris
    for (final f in [1.0, 0.78, 0.56]) {
      canvas.drawOval(
        Rect.fromCenter(center: center, width: w * f, height: h * f),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = f == 1.0 ? 1.6 : 1.0
          ..color = color.withAlpha(((90 + 70 * p) / (f == 1.0 ? 1 : 1.6)).round()),
      );
    }
    canvas.drawOval(
      Rect.fromCenter(center: center, width: w * 0.34, height: h * 0.34),
      Paint()..color = color.withAlpha((35 + 20 * p).round()),
    );
  }

  @override
  bool shouldRepaint(_PlatformGlowPainter old) =>
      old.pulse != pulse || old.connected != connected;
}

class _ControllerOverlayPainter extends CustomPainter {
  final ControllerLayout layout;
  final Map<String, double> energy;
  final Map<String, Offset> analogs;
  final Map<String, double> triggers;
  final bool connected;
  final double pulse;

  _ControllerOverlayPainter({
    required this.layout,
    required this.energy,
    required this.analogs,
    required this.triggers,
    required this.connected,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / layout.viewBox.width;
    final sy = size.height / layout.viewBox.height;
    final origin = layout.viewBoxOrigin;
    Offset sp(Offset o) =>
        Offset((o.dx - origin.dx) * sx, (o.dy - origin.dy) * sy);

    // ── Trigger pressure ──────────────────────────────────────────────
    _drawTrigger(canvas, layout.l2Area, 'l2', sx, sy);
    _drawTrigger(canvas, layout.r2Area, 'r2', sx, sy);

    // ── Glow tombol ───────────────────────────────────────────────────
    layout.controls.forEach((id, geo) {
      final e = energy[id] ?? 0;
      if (e < 0.02) return;
      final c = sp(geo.center);
      final r = geo.radius * sx;

      if (id == 'touchpad') {
        // touchpad memakai kotak, bukan lingkaran
        final rect = Rect.fromCenter(
          center: c,
          width: layout.touchpadArea.width * sx,
          height: layout.touchpadArea.height * sy,
        );
        final rr = RRect.fromRectAndRadius(rect, Radius.circular(10 * sx));
        canvas.drawRRect(
          rr,
          Paint()..color = kAccentPurple.withAlpha((55 * e).round()),
        );
        canvas.drawRRect(
          rr,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6 * sx
            ..color = kAccentPurple.withAlpha((200 * e).round()),
        );
        return;
      }

      canvas.drawCircle(
        c,
        r * (1 + 0.28 * e),
        Paint()..color = geo.color.withAlpha((75 * e).round()),
      );
      canvas.drawCircle(
        c,
        r + 2.2 * sx,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.7 * sx
          ..color = geo.color.withAlpha((230 * e).round()),
      );
    });

    // ── Knob analog ───────────────────────────────────────────────────
    _drawStick(canvas, layout.leftStick, analogs['leftStick'] ?? Offset.zero,
        kPrimaryBlue, sx, sy);
    _drawStick(canvas, layout.rightStick, analogs['rightStick'] ?? Offset.zero,
        kAccentPurple, sx, sy);

    // ── Light bar berdenyut saat terhubung ────────────────────────────
    if (connected) {
      final p = 0.5 + 0.5 * math.sin(pulse * 2 * math.pi);
      final rect = Rect.fromLTWH(
        (layout.lightBarArea.left - origin.dx) * sx,
        (layout.lightBarArea.top - origin.dy) * sy,
        layout.lightBarArea.width * sx,
        layout.lightBarArea.height * sy,
      );
      final glow = rect.inflate(4 * sx);
      canvas.drawRRect(
        RRect.fromRectAndRadius(glow, Radius.circular(6 * sx)),
        Paint()
          ..color = const Color(0xFF4FC3F7)
              .withAlpha((45 + 45 * p).round()),
      );
    }
  }

  void _drawTrigger(
      Canvas canvas, Rect area, String id, double sx, double sy) {
    final value = (triggers[id] ?? 0).clamp(0.0, 1.0);
    final rect = Rect.fromLTWH(
      (area.left - layout.viewBoxOrigin.dx) * sx,
      (area.top - layout.viewBoxOrigin.dy) * sy,
      area.width * sx,
      area.height * sy,
    );
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(7 * sx));

    canvas.save();
    canvas.clipRRect(rr);
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, rect.width * value, rect.height * 0.85),
      Paint()..color = kPrimaryBlue.withAlpha(150),
    );
    canvas.restore();

    if (value > 0.02) {
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 * sx
          ..color = kPrimaryBlue.withAlpha(220),
      );
    }
  }

  void _drawStick(Canvas canvas, Offset base, Offset dir, Color accent,
      double sx, double sy) {
    final center = Offset(
        (base.dx - layout.viewBoxOrigin.dx) * sx,
        (base.dy - layout.viewBoxOrigin.dy) * sy);
    final offset =
        Offset(dir.dx, dir.dy) * (layout.stickTravel * sx);
    final knob = center + offset;
    final r = layout.knobRadius * sx;

    canvas.drawCircle(
      knob,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          knob,
          r,
          [const Color(0xFF3B4350), const Color(0xFF0B0D12)],
        ),
    );
    canvas.drawCircle(
      knob,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3 * sx
        ..color = accent.withAlpha(190),
    );
    canvas.drawCircle(
      knob,
      r * 0.52,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF20242C),
    );
    canvas.drawCircle(knob, r * 0.24, Paint()..color = accent.withAlpha(210));
    canvas.drawArc(
      Rect.fromCircle(center: knob, radius: r * 0.78),
      math.pi * 1.15,
      math.pi * 0.55,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 * sx
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withAlpha(55),
    );
  }

  @override
  bool shouldRepaint(_ControllerOverlayPainter old) => true;
}