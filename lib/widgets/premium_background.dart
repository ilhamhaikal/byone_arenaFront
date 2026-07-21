import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

/// Premium gaming background with hexagon pattern,
/// soft blue/magenta glow, and floating particles.
class PremiumBackground extends StatelessWidget {
  const PremiumBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base dark
        Container(color: const Color(0xFF09090F)),
        // Soft glow blobs
        const _GlowBlobs(),
        // Hexagon grid
        const _HexagonGrid(),
        // Floating particles
        const _Particles(),
        // Neon controller illustration (bottom-right decorative)
        const Positioned(
          bottom: 20, right: 30,
          child: _NeonController(),
        ),
        // Lightning bolts (top-left decorative)
        const Positioned(
          top: 80, left: -5,
          child: _LightningBolts(),
        ),
        // Subtle top gradient
        Positioned(
          top: 0, left: 0, right: 0, height: 300,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1E88FF).withAlpha(15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Glow blobs (blue + magenta) ──────────────────────────────────────────
class _GlowBlobs extends StatelessWidget {
  const _GlowBlobs();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          children: [
            Positioned(
              top: -100, right: -80,
              child: _GlowCircle(color: Color(0xFF1E88FF), size: 400, opacity: 0.06),
            ),
            Positioned(
              bottom: -120, left: -60,
              child: _GlowCircle(color: Color(0xFFFF2DB7), size: 380, opacity: 0.05),
            ),
            Positioned(
              top: 200, left: -100,
              child: _GlowCircle(color: Color(0xFF7C3AED), size: 280, opacity: 0.04),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;
  const _GlowCircle({required this.color, required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withAlpha((opacity * 255).round()),
            blurRadius: size * 0.5,
            spreadRadius: size * 0.3,
          ),
        ],
      ),
    );
  }
}

// ── Hexagon grid pattern ─────────────────────────────────────────────────
class _HexagonGrid extends StatelessWidget {
  const _HexagonGrid();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _HexagonPainter(),
      ),
    );
  }
}

class _HexagonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const hexW = 60.0;
    const hexH = 52.0;
    const spacingX = hexW * 1.5;
    const spacingY = hexH;

    for (double y = -hexH; y < size.height + hexH; y += spacingY) {
      final offset = (y ~/ spacingY).isEven ? 0.0 : spacingX / 2;
      for (double x = -hexW + offset; x < size.width + hexW; x += spacingX) {
        _drawHexagon(canvas, Offset(x, y), hexW / 2, paint);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = math.pi / 3 * i - math.pi / 6;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Floating particles ───────────────────────────────────────────────────
class _Particles extends StatefulWidget {
  const _Particles();
  @override
  State<_Particles> createState() => _ParticlesState();
}

class _ParticlesState extends State<_Particles>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          size: Size.infinite,
          painter: _ParticlePainter(_ctrl.value),
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double t;
  _ParticlePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 25; i++) {
      final x = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final y = (baseY + t * 30) % size.height;
      final radius = 1.0 + rng.nextDouble() * 1.5;
      final alpha = (0x15 + rng.nextInt(0x30)).toDouble() / 255;

      final colors = [
        const Color(0xFF1E88FF).withAlpha((alpha * 255).round()),
        const Color(0xFFFF2DB7).withAlpha((alpha * 255).round()),
        const Color(0xFF7C3AED).withAlpha((alpha * 255).round()),
      ];
      paint.color = colors[i % 3];

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => t != oldDelegate.t;
}

// ═════════════════════════════════════════════════════════════════
// Neon Controller — decorative outline bottom-right
// ═════════════════════════════════════════════════════════════════
class _NeonController extends StatelessWidget {
  const _NeonController();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 180,
        height: 120,
        child: CustomPaint(
          painter: _ControllerPainter(),
        ),
      ),
    );
  }
}

class _ControllerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Main body
    final bodyPaint = Paint()
      ..color = kAccentPurple.withAlpha(12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final glowPaint = Paint()
      ..color = kAccentPurple.withAlpha(6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Rounded body shape
    final body = RRect.fromLTRBR(20, 30, w - 20, h - 25, const Radius.circular(30));
    canvas.drawRRect(body, glowPaint);
    canvas.drawRRect(body, bodyPaint);

    // Left grip
    final leftGrip = RRect.fromLTRBR(10, 40, 35, h - 30, const Radius.circular(12));
    canvas.drawRRect(leftGrip, glowPaint);
    canvas.drawRRect(leftGrip, bodyPaint);

    // Right grip
    final rightGrip = RRect.fromLTRBR(w - 35, 40, w - 10, h - 30, const Radius.circular(12));
    canvas.drawRRect(rightGrip, glowPaint);
    canvas.drawRRect(rightGrip, bodyPaint);

    // D-pad (left)
    final dpadPaint = Paint()
      ..color = kPrimaryBlue.withAlpha(18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    const dpadSize = 22.0;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(55, h * 0.45), width: dpadSize, height: dpadSize),
      dpadPaint,
    );
    // Cross lines
    canvas.drawLine(
      Offset(55, h * 0.45 - dpadSize / 2),
      Offset(55, h * 0.45 + dpadSize / 2),
      dpadPaint,
    );
    canvas.drawLine(
      Offset(55 - dpadSize / 2, h * 0.45),
      Offset(55 + dpadSize / 2, h * 0.45),
      dpadPaint,
    );

    // Buttons (right)
    final btnPaint = Paint()
      ..color = kNeonPink.withAlpha(22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset(w - 55, h * 0.42), 6, btnPaint);
    canvas.drawCircle(Offset(w - 40, h * 0.47), 6, btnPaint);
    canvas.drawCircle(Offset(w - 52, h * 0.52), 6, btnPaint);
    canvas.drawCircle(Offset(w - 38, h * 0.56), 6, btnPaint);

    // Analog sticks
    final stickPaint = Paint()
      ..color = kPrimaryBlue.withAlpha(15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(Offset(w * 0.38, h * 0.5), 10, stickPaint);
    canvas.drawCircle(Offset(w * 0.38, h * 0.5), 5, stickPaint);
    canvas.drawCircle(Offset(w * 0.6, h * 0.5), 10, stickPaint);
    canvas.drawCircle(Offset(w * 0.6, h * 0.5), 5, stickPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═════════════════════════════════════════════════════════════════
// Lightning Bolts — decorative top-left
// ═════════════════════════════════════════════════════════════════
class _LightningBolts extends StatelessWidget {
  const _LightningBolts();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 100,
        height: 200,
        child: CustomPaint(
          painter: _LightningPainter(),
        ),
      ),
    );
  }
}

class _LightningPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kPrimaryBlue.withAlpha(10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Bolt 1
    final bolt1 = Path()
      ..moveTo(40, 20)
      ..lineTo(25, 65)
      ..lineTo(45, 62)
      ..lineTo(30, 110)
      ..lineTo(55, 55)
      ..lineTo(35, 60);
    canvas.drawPath(bolt1, paint);

    // Bolt 2 (smaller, offset)
    final bolt2 = Path()
      ..moveTo(15, 80)
      ..lineTo(5, 105)
      ..lineTo(20, 102)
      ..lineTo(12, 140);
    canvas.drawPath(bolt2, paint..strokeWidth = 1.0);

    // Magenta glow bolt
    paint.color = kNeonPink.withAlpha(8);
    paint.strokeWidth = 0.8;
    final bolt3 = Path()
      ..moveTo(70, 100)
      ..lineTo(58, 140)
      ..lineTo(75, 138)
      ..lineTo(62, 180);
    canvas.drawPath(bolt3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
