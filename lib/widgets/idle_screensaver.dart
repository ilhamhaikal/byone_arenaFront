import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Latar idle ultra-premium — aurora waves, particle streams,
/// glowing orbs, scan lines, & rotating geometric shapes.
///
/// Warna: biru (#2979FF), ungu (#7C3AED), pink (#EC4899)
class IdleScreensaver extends StatefulWidget {
  final Widget child;

  const IdleScreensaver({super.key, required this.child});

  @override
  State<IdleScreensaver> createState() => _IdleScreensaverState();
}

class _IdleScreensaverState extends State<IdleScreensaver>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<_Orb> _orbs = [];
  final List<_StreamParticle> _stream = [];
  final List<_Shape> _shapes = [];
  final _rng = math.Random(42);

  static const _orbColors = [
    Color(0xFF2979FF), Color(0xFF448AFF),
    Color(0xFF7C3AED), Color(0xFFA78BFA),
    Color(0xFFEC4899), Color(0xFFF472B6),
    Color(0xFF6366F1),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 90),
    )..repeat();

    // Glowing orbs — besar & lembut
    for (int i = 0; i < 10; i++) {
      _orbs.add(_Orb(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        radius: 50 + _rng.nextDouble() * 160,
        speedX: (_rng.nextDouble() - 0.5) * 0.025,
        speedY: (_rng.nextDouble() - 0.5) * 0.035,
        opacity: 0.05 + _rng.nextDouble() * 0.10,
        color: _orbColors[_rng.nextInt(_orbColors.length)],
        phase: _rng.nextDouble() * math.pi * 2,
        pulseSpeed: 0.3 + _rng.nextDouble() * 0.7,
        depth: _rng.nextDouble(), // 0=belakang, 1=depan
      ));
    }
    // Sort by depth agar render order benar
    _orbs.sort((a, b) => a.depth.compareTo(b.depth));

    // Particle stream — partikel kecil bergerak diagonal
    for (int i = 0; i < 35; i++) {
      _stream.add(_StreamParticle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: 0.8 + _rng.nextDouble() * 1.8,
        speed: 0.03 + _rng.nextDouble() * 0.06,
        angle: -0.3 + _rng.nextDouble() * 0.6,
        opacity: 0.2 + _rng.nextDouble() * 0.5,
        color: _orbColors[_rng.nextInt(_orbColors.length)],
        trailSegments: 2 + _rng.nextInt(4),
      ));
    }

    // Geometric shapes
    for (int i = 0; i < 6; i++) {
      _shapes.add(_Shape(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: 30 + _rng.nextDouble() * 90,
        type: i % 4, // 0=circle, 1=diamond, 2=triangle, 3=square
        speedX: (_rng.nextDouble() - 0.5) * 0.012,
        speedY: (_rng.nextDouble() - 0.5) * 0.018,
        opacity: 0.03 + _rng.nextDouble() * 0.07,
        color: _orbColors[_rng.nextInt(_orbColors.length)],
        rotation: _rng.nextDouble() * math.pi * 2,
        rotSpeed: (_rng.nextDouble() - 0.5) * 0.2,
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
      fit: StackFit.expand,
      children: [
        Container(color: kDeepBlack),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => CustomPaint(
              painter: _AuroraPainter(
                orbs: _orbs,
                stream: _stream,
                shapes: _shapes,
                progress: _ctrl.value,
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

// ─── Models ─────────────────────────────────────────────────────────────────
class _Orb {
  double x, y;
  final double radius, speedX, speedY, opacity, phase, pulseSpeed, depth;
  final Color color;
  _Orb({required this.x, required this.y, required this.radius,
    required this.speedX, required this.speedY, required this.opacity,
    required this.color, required this.phase, required this.pulseSpeed,
    required this.depth});
}

class _StreamParticle {
  double x, y;
  final double size, speed, angle, opacity;
  final Color color;
  final int trailSegments;
  _StreamParticle({required this.x, required this.y, required this.size,
    required this.speed, required this.angle, required this.opacity,
    required this.color, required this.trailSegments});
}

class _Shape {
  double x, y;
  final double size, speedX, speedY, opacity, rotSpeed;
  final int type;
  final Color color;
  double rotation;
  _Shape({required this.x, required this.y, required this.size,
    required this.type, required this.speedX, required this.speedY,
    required this.opacity, required this.color, required this.rotation,
    required this.rotSpeed});
}

// ─── Painter ────────────────────────────────────────────────────────────────
class _AuroraPainter extends CustomPainter {
  final List<_Orb> orbs;
  final List<_StreamParticle> stream;
  final List<_Shape> shapes;
  final double progress;

  _AuroraPainter({required this.orbs, required this.stream,
    required this.shapes, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── 1. Aurora waves (3 layers) ────────────────────────────────────
    _drawAurora(canvas, w, h);

    // ── 2. Geometric shapes ───────────────────────────────────────────
    for (final s in shapes) {
      final sx = _wrap(s.x + progress * s.speedX);
      final sy = _wrap(s.y + progress * s.speedY);
      canvas.save();
      canvas.translate(sx * w, sy * h);
      canvas.rotate(s.rotation + progress * s.rotSpeed);

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = s.color.withAlpha((s.opacity * 255).round());
      final glow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = s.color.withAlpha((s.opacity * 80).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      final path = _shapePath(s.type, s.size);
      canvas.drawPath(path, glow);
      canvas.drawPath(path, paint);
      canvas.restore();
    }

    // ── 3. Particle streams — diagonal flowing dots ───────────────────
    for (final p in stream) {
      final px = _wrap(p.x + progress * p.speed * math.cos(p.angle));
      final py = _wrap(p.y + progress * p.speed * math.sin(p.angle));
      final alpha = (p.opacity * 180).round();

      // Trail (lebih pendek = lebih smooth)
      for (int t = 1; t <= p.trailSegments; t++) {
        final tx = _wrap(px - t * 0.005 * math.cos(p.angle));
        final ty = _wrap(py - t * 0.005 * math.sin(p.angle));
        final ta = (alpha * (1.0 - t / (p.trailSegments + 1))).round();
        if (ta > 5) {
          canvas.drawCircle(
            Offset(tx * w, ty * h), p.size * 0.4,
            Paint()..color = p.color.withAlpha(ta),
          );
        }
      }

      // Head
      canvas.drawCircle(
        Offset(px * w, py * h), p.size,
        Paint()..color = p.color.withAlpha(alpha),
      );
      // Subtle glow
      canvas.drawCircle(
        Offset(px * w, py * h), p.size * 2.0,
        Paint()
          ..shader = RadialGradient(colors: [
            p.color.withAlpha(alpha), Colors.transparent,
          ]).createShader(Rect.fromCircle(
            center: Offset(px * w, py * h), radius: p.size * 2.0)),
      );
    }

    // ── 4. Glowing orbs ───────────────────────────────────────────────
    for (final orb in orbs) {
      final ox = _wrap(orb.x + progress * orb.speedX);
      final oy = _wrap(orb.y + progress * orb.speedY);
      final pulse = 1.0 + 0.12 * math.sin(progress * math.pi * 2 * orb.pulseSpeed + orb.phase);
      final r = orb.radius * pulse;

      // Outer halo
      canvas.drawCircle(Offset(ox * w, oy * h), r * 1.8,
        Paint()..shader = RadialGradient(colors: [
          orb.color.withAlpha((orb.opacity * 160).round()),
          orb.color.withAlpha((orb.opacity * 40).round()),
          Colors.transparent,
        ], stops: const [0.0, 0.5, 1.0])
        .createShader(Rect.fromCircle(center: Offset(ox * w, oy * h), radius: r * 1.8)));

      // Inner glow
      canvas.drawCircle(Offset(ox * w, oy * h), r * 0.7,
        Paint()..shader = RadialGradient(colors: [
          Colors.white.withAlpha((orb.opacity * 100).round()),
          orb.color.withAlpha((orb.opacity * 100).round()),
          Colors.transparent,
        ], stops: const [0.0, 0.4, 1.0])
        .createShader(Rect.fromCircle(center: Offset(ox * w, oy * h), radius: r * 0.7)));
    }

    // ── 5. Scan line — subtle horizontal line sweeping down ───────────
    final scanY = ((progress * 1.3) % 1.0) * h;
    final scanPaint = Paint()
      ..shader = LinearGradient(colors: [
        Colors.transparent,
        Colors.white.withAlpha(4),
        Colors.white.withAlpha(8),
        Colors.white.withAlpha(4),
        Colors.transparent,
      ]).createShader(Rect.fromLTWH(0, scanY - 40, w, 80));
    canvas.drawRect(Rect.fromLTWH(0, scanY - 40, w, 80), scanPaint);
  }

  void _drawAurora(Canvas canvas, double w, double h) {
    const waveColors = [
      Color(0xFF2979FF), Color(0xFF7C3AED), Color(0xFFEC4899),
    ];
    for (int layer = 0; layer < 3; layer++) {
      final color = waveColors[layer];
      final path = Path();
      final baseY = h * (0.25 + layer * 0.25);
      final amp = 45.0 + layer * 25.0;
      final freq = 0.7 + layer * 0.35;
      final shift = progress * math.pi * (0.5 + layer * 0.45);

      path.moveTo(0, h); path.lineTo(0, baseY);
      for (double x = 0; x <= w; x += 4) {
        final nx = x / w;
        final y = baseY +
            math.sin(nx * freq * math.pi * 3 + shift) * amp +
            math.cos(nx * freq * math.pi * 1.5 + shift * 0.6) * amp * 0.4;
        path.lineTo(x, y);
      }
      path.lineTo(w, h); path.close();

      canvas.drawPath(path, Paint()..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [
          Colors.transparent, color.withAlpha(5),
          color.withAlpha(13), color.withAlpha(5), Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, baseY - amp * 3, w, amp * 6)));
    }
  }

  Path _shapePath(int type, double s) {
    final p = Path();
    switch (type) {
      case 0: p.addOval(Rect.fromCenter(center: Offset.zero, width: s, height: s)); break;
      case 1: p.moveTo(0, -s*0.55); p.lineTo(s*0.4, 0); p.lineTo(0, s*0.55); p.lineTo(-s*0.4, 0); p.close(); break;
      case 2: p.moveTo(0, -s*0.5); p.lineTo(s*0.45, s*0.35); p.lineTo(-s*0.45, s*0.35); p.close(); break;
      case 3: p.addRect(Rect.fromCenter(center: Offset.zero, width: s*0.7, height: s*0.7)); break;
    }
    return p;
  }

  double _wrap(double v) { double w = v % 1.0; return w < 0 ? w + 1.0 : w; }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) => old.progress != progress;
}


