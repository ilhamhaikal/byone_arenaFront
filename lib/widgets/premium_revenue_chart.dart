import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

/// Premium glowing revenue chart with neon blue/pink gradient line.
class PremiumRevenueChart extends StatelessWidget {
  final List<double> data;
  final double maxValue;

  const PremiumRevenueChart({
    super.key,
    required this.data,
    this.maxValue = 0,
  });

  @override
  Widget build(BuildContext context) {
    final max = maxValue > 0 ? maxValue : (data.reduce(math.max));
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
          const SizedBox(height: 20),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _ChartPainter(data: data, maxValue: max),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> data;
  final double maxValue;
  _ChartPainter({required this.data, required this.maxValue});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final chartW = size.width - 40;
    final chartH = size.height - 30;
    final stepX = data.length > 1 ? chartW / (data.length - 1) : chartW;

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withAlpha(8)
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = 10 + chartH * i / 4;
      canvas.drawLine(Offset(20, y), Offset(20 + chartW, y), gridPaint);
    }

    // Points
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = 20 + i * stepX;
      final normalizedY = maxValue > 0 ? data[i] / maxValue : 0;
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
          colors: [
            kPrimaryBlue.withAlpha(40),
            kPrimaryBlue.withAlpha(0),
          ],
        ).createShader(Rect.fromLTWH(0, 10, size.width, chartH));
      canvas.drawPath(fillPath, fillPaint);
    }

    // Line with gradient
    if (points.length >= 2) {
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        final prev = points[i - 1];
        final curr = points[i];
        final cx = (prev.dx + curr.dx) / 2;
        linePath.quadraticBezierTo(prev.dx, prev.dy, cx, (prev.dy + curr.dy) / 2);
      }
      linePath.lineTo(points.last.dx, points.last.dy);

      final linePaint = Paint()
        ..shader = const LinearGradient(
          colors: [kPrimaryBlue, kAccentPurple, kNeonPink],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(linePath, linePaint);
    }

    // Dots
    for (final p in points) {
      // Outer glow
      canvas.drawCircle(p, 6, Paint()..color = kPrimaryBlue.withAlpha(30));
      // Inner dot
      canvas.drawCircle(p, 3.5, Paint()..color = kPrimaryBlue);
      // Center white
      canvas.drawCircle(p, 1.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      data != oldDelegate.data || maxValue != oldDelegate.maxValue;
}
