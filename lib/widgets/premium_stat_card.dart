import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

/// Premium stat card with neon glow, icon, large number, and mini trend.
class PremiumStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color glowColor;
  final Widget? trend;
  final VoidCallback? onTap;

  const PremiumStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.glowColor,
    this.trend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF13131F),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: glowColor.withAlpha(30),
              width: 0.6,
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor.withAlpha(12),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon row
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: glowColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: glowColor.withAlpha(50),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(icon, color: glowColor, size: 18),
                  ),
                  const Spacer(),
                  if (trend != null) trend!,
                ],
              ),
              const SizedBox(height: 14),
              // Value
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              // Title
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withAlpha(160),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mini trend indicator (up/down percentage).
class MiniTrend extends StatelessWidget {
  final double percent;
  final bool up;

  const MiniTrend({super.key, required this.percent, this.up = true});

  @override
  Widget build(BuildContext context) {
    final color = up ? kSuccessColor : kErrorColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(40), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(up ? Icons.trending_up : Icons.trending_down,
              size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            '${percent.toStringAsFixed(0)}%',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
