import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

/// Grafik pendapatan dengan TIGA seri dalam satu chart:
/// - Rental & Harian — biru/ungu neon
/// - Member — hijau
/// - Makanan — oranye
class PremiumRevenueChart extends StatelessWidget {
  /// Seri pendapatan rental (sewa konsol + rental harian).
  final List<double> rental;

  /// Seri penjualan membership.
  final List<double> membership;

  /// Seri pendapatan makanan/minuman.
  final List<double> food;

  const PremiumRevenueChart({
    super.key,
    required this.rental,
    this.membership = const [],
    this.food = const [],
  });

  static const Color _foodColor = Color(0xFFF97316);
  static const Color _foodColor2 = Color(0xFFF59E0B);
  static const Color _memberColor = Color(0xFF10B981);
  static const Color _memberColor2 = Color(0xFF059669);

  @override
  Widget build(BuildContext context) {
    // Skala mengikuti nilai maksimum dari KEDUA seri.
    double max = 0;
    for (final v in rental) {
      max = math.max(max, v);
    }
    for (final v in membership) {
      max = math.max(max, v);
    }
    for (final v in food) {
      max = math.max(max, v);
    }
    if (max <= 0) max = 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF13131F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(10), width: 0.6),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withAlpha(8),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kPrimaryBlue, kAccentPurple],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: kPrimaryBlue.withAlpha(50), blurRadius: 8),
                  ],
                ),
                child: const Icon(Icons.trending_up_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GRAFIK PENDAPATAN',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    Text('7 Hari Terakhir',
                        style: TextStyle(
                            color: kTextSecondary, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ── Legenda dua seri ──
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: const [
              _LegendDot(colors: [kPrimaryBlue, kAccentPurple], label: 'Rental & Harian'),
              _LegendDot(colors: [_memberColor, _memberColor2], label: 'Member'),
              _LegendDot(colors: [_foodColor, _foodColor2], label: 'Makanan'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _ChartPainter(
                rental: rental,
                membership: membership,
                food: food,
                maxValue: max),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final List<Color> colors;
  final String label;
  const _LegendDot({required this.colors, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: colors),
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(color: kTextSecondary, fontSize: 11)),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> rental;
  final List<double> membership;
  final List<double> food;
  final double maxValue;
  _ChartPainter({
    required this.rental,
    required this.membership,
    required this.food,
    required this.maxValue,
  });

  static const Color _foodColor = Color(0xFFF97316);
  static const Color _foodColor2 = Color(0xFFF59E0B);
  static const Color _memberColor = Color(0xFF10B981);
  static const Color _memberColor2 = Color(0xFF059669);

  @override
  void paint(Canvas canvas, Size size) {
    final n = math.max(rental.length, math.max(membership.length, food.length));
    if (n == 0) return;

    final chartW = size.width - 40;
    final chartH = size.height - 30;
    final stepX = n > 1 ? chartW / (n - 1) : chartW;

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withAlpha(8)
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = 10 + chartH * i / 4;
      canvas.drawLine(Offset(20, y), Offset(20 + chartW, y), gridPaint);
    }

    // Gambar makanan lebih dulu (latar), lalu rental di atasnya.
    _drawSeries(
      canvas,
      size: size,
      data: food,
      stepX: stepX,
      chartH: chartH,
      lineColors: const [_foodColor, _foodColor2],
      fillColor: _foodColor.withAlpha(28),
      dotColor: _foodColor,
    );
    _drawSeries(
      canvas,
      size: size,
      data: membership,
      stepX: stepX,
      chartH: chartH,
      lineColors: const [_memberColor, _memberColor2],
      fillColor: _memberColor.withAlpha(28),
      dotColor: _memberColor,
    );
    _drawSeries(
      canvas,
      size: size,
      data: rental,
      stepX: stepX,
      chartH: chartH,
      lineColors: const [kPrimaryBlue, kAccentPurple, kNeonPink],
      fillColor: kPrimaryBlue.withAlpha(38),
      dotColor: kPrimaryBlue,
    );
  }

  void _drawSeries(
    Canvas canvas, {
    required Size size,
    required List<double> data,
    required double stepX,
    required double chartH,
    required List<Color> lineColors,
    required Color fillColor,
    required Color dotColor,
  }) {
    if (data.isEmpty) return;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = 20 + i * stepX;
      final normalizedY =
          maxValue > 0 ? (data[i] / maxValue).clamp(0.0, 1.0) : 0.0;
      final y = 10 + chartH - (normalizedY * chartH);
      points.add(Offset(x, y));
    }

    // Gradient fill
    if (points.length >= 2) {
      final fillPath = Path()..moveTo(points.first.dx, 10 + chartH);
      for (final p in points) {
        fillPath.lineTo(p.dx, p.dy);
      }
      fillPath.lineTo(points.last.dx, 10 + chartH);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fillColor, fillColor.withAlpha(0)],
        ).createShader(Rect.fromLTWH(0, 10, size.width, chartH));
      canvas.drawPath(fillPath, fillPaint);
    }

    // Line
    if (points.length >= 2) {
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        final prev = points[i - 1];
        final curr = points[i];
        final cx = (prev.dx + curr.dx) / 2;
        linePath.quadraticBezierTo(
            prev.dx, prev.dy, cx, (prev.dy + curr.dy) / 2);
      }
      linePath.lineTo(points.last.dx, points.last.dy);

      final linePaint = Paint()
        ..shader = LinearGradient(colors: lineColors)
            .createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(linePath, linePaint);
    }

    // Dots
    for (final p in points) {
      canvas.drawCircle(p, 6, Paint()..color = dotColor.withAlpha(30));
      canvas.drawCircle(p, 3.5, Paint()..color = dotColor);
      canvas.drawCircle(p, 1.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      rental != oldDelegate.rental ||
      food != oldDelegate.food ||
      maxValue != oldDelegate.maxValue;
}
