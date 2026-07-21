import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

/// Premium dashboard hero banner — pure Flutter, no external image.
/// Canvas: 3840×1080 ratio (3.55:1)
/// Safe margins: 18% top/bottom, 30% left, 15% top-right
class DashboardBanner extends StatelessWidget {
  const DashboardBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withAlpha(30),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: const Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1: Dark base
            _BannerBackground(),
            // Layer 2: Hexagon grid
            _BannerHexagons(),
            // Layer 3: Glow blobs
            _BannerGlow(),
            // Layer 4: Particles
            _BannerParticles(),
            // Layer 5: Consoles (right side)
            Positioned(
              right: 60, bottom: 10, top: 10,
              child: _ConsoleStack(),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Layer 1: Dark base with gradient
// ═════════════════════════════════════════════════════════════════
class _BannerBackground extends StatelessWidget {
  const _BannerBackground();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0B0F1E),
            Color(0xFF0F172A),
            Color(0xFF1A1040),
            Color(0xFF0F172A),
            Color(0xFF0B0F1E),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Layer 2: Hexagon grid
// ═════════════════════════════════════════════════════════════════
class _BannerHexagons extends StatelessWidget {
  const _BannerHexagons();
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _BannerHexPainter(),
      ),
    );
  }
}

class _BannerHexPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4;

    const hexW = 40.0;
    const hexH = 35.0;
    const spacingX = hexW * 1.5;
    const spacingY = hexH;

    for (double y = -hexH; y < size.height + hexH; y += spacingY) {
      final offset = (y ~/ spacingY).isEven ? 0.0 : spacingX / 2;
      for (double x = -hexW; x < size.width + hexW; x += spacingX) {
        _drawHex(canvas, Offset(x + offset, y), hexW / 2, paint);
      }
    }
  }

  void _drawHex(Canvas c, Offset o, double r, Paint p) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final a = math.pi / 3 * i - math.pi / 6;
      final x = o.dx + r * math.cos(a);
      final y = o.dy + r * math.sin(a);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

// ═════════════════════════════════════════════════════════════════
// Layer 3: Glow blobs (blue + magenta)
// ═════════════════════════════════════════════════════════════════
class _BannerGlow extends StatelessWidget {
  const _BannerGlow();
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          children: [
            // Blue glow top-right
            Positioned(
              top: -40, right: 100,
              child: Container(
                width: 260, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryBlue.withAlpha(18),
                      blurRadius: 80,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
            // Purple glow center
            Positioned(
              top: 20, right: 280,
              child: Container(
                width: 200, height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  boxShadow: [
                    BoxShadow(
                      color: kAccentPurple.withAlpha(15),
                      blurRadius: 90,
                      spreadRadius: 30,
                    ),
                  ],
                ),
              ),
            ),
            // Pink glow bottom-right
            Positioned(
              bottom: -20, right: 160,
              child: Container(
                width: 180, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  boxShadow: [
                    BoxShadow(
                      color: kNeonPink.withAlpha(12),
                      blurRadius: 70,
                      spreadRadius: 30,
                    ),
                  ],
                ),
              ),
            ),
            // Blue glow left edge
            Positioned(
              top: 40, left: -30,
              child: Container(
                width: 100, height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryBlue.withAlpha(10),
                      blurRadius: 60,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Layer 4: Floating particles
// ═════════════════════════════════════════════════════════════════
class _BannerParticles extends StatefulWidget {
  const _BannerParticles();
  @override
  State<_BannerParticles> createState() => _BannerParticlesState();
}

class _BannerParticlesState extends State<_BannerParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
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
          painter: _BannerParticlePainter(_ctrl.value),
        ),
      ),
    );
  }
}

class _BannerParticlePainter extends CustomPainter {
  final double t;
  _BannerParticlePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(7);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 18; i++) {
      final x = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final y = (baseY + t * 25) % size.height;
      final radius = 0.8 + rng.nextDouble() * 1.2;
      final alpha = (0x10 + rng.nextInt(0x20)).toDouble() / 255;

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
  bool shouldRepaint(covariant _BannerParticlePainter o) => t != o.t;
}

// ═════════════════════════════════════════════════════════════════
// Layer 5: Console stack — decorative, right side
// ═════════════════════════════════════════════════════════════════
class _ConsoleStack extends StatelessWidget {
  const _ConsoleStack();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // PS4 Slim
        _ConsoleIcon(
          icon: Icons.sports_esports,
          gradient: const LinearGradient(colors: [kPrimaryBlue, Color(0xFF0D47A1)]),
          glow: kPrimaryBlue,
          label: 'PS4',
          size: 52,
        ),
        const SizedBox(width: 20),
        // PS5 (larger, center)
        _ConsoleIcon(
          icon: Icons.sports_esports,
          gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)]),
          glow: kAccentPurple,
          label: 'PS5',
          size: 60,
        ),
        const SizedBox(width: 20),
        // Nintendo Switch
        _ConsoleIcon(
          icon: Icons.videogame_asset,
          gradient: const LinearGradient(colors: [kNeonPink, Color(0xFF9D174D)]),
          glow: kNeonPink,
          label: 'SWITCH',
          size: 48,
        ),
      ],
    );
  }
}

class _ConsoleIcon extends StatelessWidget {
  final IconData icon;
  final LinearGradient gradient;
  final Color glow;
  final String label;
  final double size;

  const _ConsoleIcon({
    required this.icon,
    required this.gradient,
    required this.glow,
    required this.label,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size * 1.1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                gradient.colors.first.withAlpha(25),
                gradient.colors.last.withAlpha(8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: glow.withAlpha(50),
              width: 0.7,
            ),
            boxShadow: [
              BoxShadow(
                color: glow.withAlpha(25),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(icon, color: glow.withAlpha(180), size: size * 0.45),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: glow.withAlpha(160),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
