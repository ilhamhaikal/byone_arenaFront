import 'dart:math';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Background partikel mengambang dengan glow efek —
/// warna brand: biru, ungu, pink di atas deep black.
class ParticleBackground extends StatefulWidget {
  final Widget child;
  final int particleCount;
  final bool showConnections;

  const ParticleBackground({
    super.key,
    required this.child,
    this.particleCount = 55,
    this.showConnections = false,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<_Particle> _particles = [];
  final _rng = Random();

  // Brand colors untuk partikel
  static const _colors = [
    Color(0xFF2979FF), // biru
    Color(0xFF448AFF), // biru terang
    Color(0xFF7C3AED), // ungu
    Color(0xFF9B59B6), // ungu muda
    Color(0xFFEC4899), // pink
    Color(0xFFF472B6), // pink muda
    Color(0xFF6366F1), // indigo
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    // Generate partikel
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(_Particle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        radius: 1.0 + _rng.nextDouble() * 2.5,
        speed: 0.02 + _rng.nextDouble() * 0.06,
        opacity: 0.15 + _rng.nextDouble() * 0.45,
        color: _colors[_rng.nextInt(_colors.length)],
        wobble: _rng.nextDouble() * pi * 2,
        wobbleSpeed: 0.2 + _rng.nextDouble() * 0.5,
      ));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background solid
        Positioned.fill(child: Container(color: kDeepBlack)),
        // Partikel canvas
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => CustomPaint(
              painter: _ParticlePainter(
                particles: _particles,
                progress: _ctrl.value,
                showConnections: widget.showConnections,
              ),
            ),
          ),
        ),
        // Content di atas
        widget.child,
      ],
    );
  }
}

// ─── Particle model ─────────────────────────────────────────────────────────
class _Particle {
  double x, y;
  final double radius;
  final double speed;
  final double opacity;
  final Color color;
  final double wobble;
  final double wobbleSpeed;

  _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.color,
    required this.wobble,
    required this.wobbleSpeed,
  });
}

// ─── Particle painter ───────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final bool showConnections;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.showConnections,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Update posisi & render setiap partikel
    for (final p in particles) {
      // Gerak ke atas (loop kembali ke bawah)
      p.y -= p.speed * 0.016;
      if (p.y < -0.05) {
        p.y = 1.05;
        p.x = Random().nextDouble();
      }
      // Wobble horizontal
      p.x += sin(progress * pi * 2 * 3 + p.wobble) * 0.0004 * p.wobbleSpeed;
      if (p.x > 1.05) p.x = -0.05;
      if (p.x < -0.05) p.x = 1.05;

      final px = p.x * size.width;
      final py = p.y * size.height;

      // Glow besar (outer)
      final glowPaint = Paint()
        ..color = p.color.withAlpha((p.opacity * 0.08 * 255).toInt())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
      canvas.drawCircle(Offset(px, py), p.radius * 5, glowPaint);

      // Glow sedang
      final midGlow = Paint()
        ..color = p.color.withAlpha((p.opacity * 0.18 * 255).toInt())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(px, py), p.radius * 2.5, midGlow);

      // Inti partikel
      final corePaint = Paint()
        ..color = p.color.withAlpha((p.opacity * 0.9 * 255).toInt())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawCircle(Offset(px, py), p.radius, corePaint);
    }

    // Optional: garis penghubung antar partikel dekat
    if (showConnections && particles.length >= 2) {
      final linePaint = Paint()
        ..color = kPrimaryBlue.withAlpha(12)
        ..strokeWidth = 0.4;
      for (int i = 0; i < particles.length; i++) {
        for (int j = i + 1; j < particles.length; j++) {
          final a = particles[i];
          final b = particles[j];
          final dx = (a.x - b.x) * size.width;
          final dy = (a.y - b.y) * size.height;
          final dist = sqrt(dx * dx + dy * dy);
          if (dist < size.width * 0.13) {
            final alpha = ((1 - dist / (size.width * 0.13)) * 0.12 * 255).toInt();
            linePaint.color = kPrimaryBlue.withAlpha(alpha);
            canvas.drawLine(
              Offset(a.x * size.width, a.y * size.height),
              Offset(b.x * size.width, b.y * size.height),
              linePaint,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}
