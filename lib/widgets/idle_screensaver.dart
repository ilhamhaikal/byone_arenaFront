import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Latar idle ultra-premium — starfield, aurora waves, particle streams
/// dengan constellation links, glowing orbs, holographic floor grid,
/// shooting-star comets, scan lines, rotating geometric shapes, ambient
/// center spotlight & cinematic vignette.
///
/// Warna: biru (#2979FF), ungu (#7C3AED), pink (#EC4899) — konsisten
/// dengan palet brand & gaya glow/blur yang sudah dipakai di seluruh app.
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
  final List<_Star> _stars = [];
  final List<_Comet> _comets = [];
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

    // Starfield — titik kecil berkedip lembut, memberi kedalaman malam hari
    for (int i = 0; i < 70; i++) {
      _stars.add(_Star(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        radius: 0.5 + _rng.nextDouble() * 1.3,
        phase: _rng.nextDouble() * math.pi * 2,
        twinkleSpeed: 0.4 + _rng.nextDouble() * 1.2,
        opacity: 0.15 + _rng.nextDouble() * 0.35,
      ));
    }

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

    // Comets — kilatan bintang jatuh sesekali, aksen elegan yang singkat
    for (int i = 0; i < 3; i++) {
      _comets.add(_Comet(
        x0: -0.15 + _rng.nextDouble() * 0.4,
        y0: -0.1 + _rng.nextDouble() * 0.15,
        x1: 0.75 + _rng.nextDouble() * 0.4,
        y1: 1.0 + _rng.nextDouble() * 0.15,
        delay: i / 3.0 + _rng.nextDouble() * 0.05,
        length: 0.16 + _rng.nextDouble() * 0.08,
        color: _orbColors[_rng.nextInt(_orbColors.length)],
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
                stars: _stars,
                comets: _comets,
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

class _Star {
  final double x, y, radius, phase, twinkleSpeed, opacity;
  _Star({required this.x, required this.y, required this.radius,
    required this.phase, required this.twinkleSpeed, required this.opacity});
}

/// Bintang jatuh singkat yang melintas diagonal secara periodik.
/// Posisi start/end di luar tepi layar (koordinat 0..1 dinormalisasi
/// terhadap ukuran layar, boleh <0 atau >1 agar masuk/keluar dari luar).
class _Comet {
  final double x0, y0, x1, y1;
  final double delay; // offset fase dalam siklus lokal (0..1)
  final double length; // panjang trail relatif terhadap sisi terpendek layar
  final Color color;
  _Comet({required this.x0, required this.y0, required this.x1,
    required this.y1, required this.delay, required this.length,
    required this.color});
}

// ─── Painter ────────────────────────────────────────────────────────────────
class _AuroraPainter extends CustomPainter {
  final List<_Orb> orbs;
  final List<_StreamParticle> stream;
  final List<_Shape> shapes;
  final List<_Star> stars;
  final List<_Comet> comets;
  final double progress;

  _AuroraPainter({required this.orbs, required this.stream,
    required this.shapes, required this.stars, required this.comets,
    required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── 1. Starfield — kedalaman malam, berkedip lembut ───────────────
    _drawStarfield(canvas, w, h);

    // ── 2. Aurora waves (3 layers) ─────────────────────────────────────
    _drawAurora(canvas, w, h);

    // ── 3. Holographic floor grid — kesan panggung arena futuristik ───
    _drawGridFloor(canvas, w, h);

    // ── 4. Geometric shapes ────────────────────────────────────────────
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

    // ── 5. Particle streams — diagonal flowing dots + constellation ───
    // Posisi dihitung sekali lalu dipakai ulang untuk garis constellation
    // & partikelnya sendiri (hindari hitung trig dua kali → lebih efisien).
    final streamPos = <Offset>[];
    for (final p in stream) {
      final px = _wrap(p.x + progress * p.speed * math.cos(p.angle));
      final py = _wrap(p.y + progress * p.speed * math.sin(p.angle));
      streamPos.add(Offset(px * w, py * h));
    }
    _drawConstellation(canvas, streamPos);
    for (int i = 0; i < stream.length; i++) {
      final p = stream[i];
      final pos = streamPos[i];
      final alpha = (p.opacity * 180).round();

      // Trail (lebih pendek = lebih smooth)
      for (int t = 1; t <= p.trailSegments; t++) {
        final tx = pos.dx - t * 0.005 * math.cos(p.angle) * w;
        final ty = pos.dy - t * 0.005 * math.sin(p.angle) * h;
        final ta = (alpha * (1.0 - t / (p.trailSegments + 1))).round();
        if (ta > 5) {
          canvas.drawCircle(
            Offset(tx, ty), p.size * 0.4,
            Paint()..color = p.color.withAlpha(ta),
          );
        }
      }

      // Head
      canvas.drawCircle(pos, p.size, Paint()..color = p.color.withAlpha(alpha));
      // Subtle glow
      canvas.drawCircle(
        pos, p.size * 2.0,
        Paint()
          ..shader = RadialGradient(colors: [
            p.color.withAlpha(alpha), Colors.transparent,
          ]).createShader(Rect.fromCircle(center: pos, radius: p.size * 2.0)),
      );
    }

    // ── 6. Glowing orbs ─────────────────────────────────────────────────
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

    // ── 7. Comets — kilatan bintang jatuh, aksen elegan sesaat ─────────
    _drawComets(canvas, w, h);

    // ── 8. Scan line — subtle horizontal line sweeping down ───────────
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

    // ── 9. Ambient center spotlight — beri fokus lembut ke konten ─────
    final cx = w / 2, cy = h * 0.46;
    final spotRadius = math.min(w, h) * 0.55;
    canvas.drawCircle(Offset(cx, cy), spotRadius,
      Paint()..shader = RadialGradient(colors: [
        kPrimaryBlue.withAlpha(14), Colors.transparent,
      ]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: spotRadius)));

    // ── 10. Cinematic vignette — gelapkan tepi agar terasa premium ────
    final vignetteRadius = math.sqrt(w * w + h * h) / 2;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
      Paint()..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Colors.transparent, Colors.transparent, kDeepBlack.withAlpha(150),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(w / 2, h / 2), radius: vignetteRadius)));
  }

  void _drawStarfield(Canvas canvas, double w, double h) {
    for (final star in stars) {
      final twinkle = 0.5 +
          0.5 * math.sin(progress * math.pi * 2 * star.twinkleSpeed + star.phase);
      final alpha = (star.opacity * twinkle * 255).round().clamp(0, 255);
      if (alpha < 4) continue;
      canvas.drawCircle(
        Offset(star.x * w, star.y * h), star.radius,
        Paint()..color = Colors.white.withAlpha(alpha),
      );
    }
  }

  /// Garis tipis penghubung antar partikel yang berdekatan — kesan
  /// jaringan/teknologi yang selaras dengan estetika gaming arena.
  void _drawConstellation(Canvas canvas, List<Offset> positions) {
    const maxDist = 130.0;
    final paint = Paint()..strokeWidth = 0.6;
    for (int i = 0; i < positions.length; i++) {
      for (int j = i + 1; j < positions.length; j++) {
        final dist = (positions[i] - positions[j]).distance;
        if (dist >= maxDist) continue;
        final alpha = ((1 - dist / maxDist) * 30).round();
        if (alpha <= 2) continue;
        canvas.drawLine(positions[i], positions[j],
          paint..color = kPrimaryBlue.withAlpha(alpha));
      }
    }
  }

  /// Lantai grid holografik ala panggung arena — sangat subtle, garis
  /// horizontal & vertikal yang mengerucut menuju titik hilang di horizon.
  void _drawGridFloor(Canvas canvas, double w, double h) {
    final horizonY = h * 0.62;
    const lineCount = 7;
    final scroll = (progress * 0.6) % 1.0;

    for (int i = 0; i < lineCount; i++) {
      final t = ((i + scroll) / lineCount) % 1.0;
      final y = horizonY + (h - horizonY) * (t * t);
      final opacity = (1 - t) * 0.05;
      if (opacity <= 0.002) continue;
      canvas.drawLine(Offset(0, y), Offset(w, y),
        Paint()
          ..color = kPrimaryBlue.withAlpha((opacity * 255).round())
          ..strokeWidth = 0.5 + t * 1.0);
    }

    const vertCount = 5;
    final vanishX = w / 2;
    for (int i = 0; i <= vertCount; i++) {
      final frac = i / vertCount - 0.5;
      final farX = vanishX + frac * w * 0.15;
      final nearX = vanishX + frac * w * 1.3;
      canvas.drawLine(Offset(farX, horizonY), Offset(nearX, h),
        Paint()
          ..color = kPrimaryBlue.withAlpha(10)
          ..strokeWidth = 0.5);
    }
  }

  /// Bintang jatuh singkat yang melintas diagonal secara periodik dengan
  /// trail bercahaya — momen elegan yang muncul sesekali, tidak monoton.
  void _drawComets(Canvas canvas, double w, double h) {
    const localCycles = 5.0;
    const activeFraction = 0.12;
    for (final comet in comets) {
      final t = ((progress * localCycles) + comet.delay) % 1.0;
      if (t >= activeFraction) continue;
      final tt = t / activeFraction;
      final fade = math.sin(tt * math.pi);
      if (fade <= 0.01) continue;

      final headX = (comet.x0 + (comet.x1 - comet.x0) * tt) * w;
      final headY = (comet.y0 + (comet.y1 - comet.y0) * tt) * h;
      final dirX = comet.x1 - comet.x0;
      final dirY = comet.y1 - comet.y0;
      final len = math.sqrt(dirX * dirX + dirY * dirY);
      if (len == 0) continue;
      final normX = dirX / len, normY = dirY / len;
      final tailLen = comet.length * math.min(w, h);
      final tailX = headX - normX * tailLen;
      final tailY = headY - normY * tailLen;

      final alpha = (fade * 200).round().clamp(0, 255);
      canvas.drawLine(
        Offset(tailX, tailY), Offset(headX, headY),
        Paint()
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(colors: [
            Colors.transparent, comet.color.withAlpha(alpha),
          ]).createShader(Rect.fromPoints(
            Offset(tailX, tailY), Offset(headX, headY))),
      );
      canvas.drawCircle(Offset(headX, headY), 3.0,
        Paint()..color = Colors.white.withAlpha(alpha));
      canvas.drawCircle(Offset(headX, headY), 9,
        Paint()..shader = RadialGradient(colors: [
          comet.color.withAlpha(alpha), Colors.transparent,
        ]).createShader(Rect.fromCircle(center: Offset(headX, headY), radius: 9)));
    }
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


