import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';

/// Kartu dasar untuk halaman Controller Health Check.
/// Meniru bahasa visual panel Dashboard: gelap, border tipis, glow lembut.
class HealthCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const HealthCard({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF171A27), Color(0xFF0E0F18)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withAlpha(70), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: accent.withAlpha(18),
            blurRadius: 20,
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
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withAlpha(28),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: accent.withAlpha(70)),
                ),
                child: Icon(icon, size: 16, color: accent),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Pil status kecil (OK / Menunggu / Normal / Drift).
class HealthPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const HealthPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
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