import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_theme.dart';
import '../../../providers/controller_health_provider.dart';
import 'health_card.dart';

/// Kartu monitoring analog kiri / kanan.
class AnalogMonitorCard extends StatelessWidget {
  final String controlId;
  final String title;
  final String label;
  final Color accent;
  final IconData icon;

  const AnalogMonitorCard({
    super.key,
    required this.controlId,
    required this.title,
    required this.label,
    required this.accent,
    this.icon = Icons.radio_button_checked_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ControllerHealthProvider>();
    final v = p.analogOf(controlId);
    final moved = p.checkedButtons.isNotEmpty || p.analogs.values.any((o) => o.distance > 0.01);
    final condition = p.analogCondition(controlId);
    final normal = condition == 'Normal';
    final color = !moved
        ? kTextSecondary
        : normal
            ? kSuccessColor
            : kWarningColor;

    return HealthCard(
      title: title,
      icon: icon,
      accent: accent,
      child: Row(
        children: [
          _StickVisual(offset: v, accent: accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _axisRow('X', v.dx),
                const SizedBox(height: 6),
                _axisRow('Y', v.dy),
                const SizedBox(height: 10),
                HealthPill(
                  label: condition,
                  color: color,
                  icon: normal
                      ? Icons.check_circle_rounded
                      : moved
                          ? Icons.warning_amber_rounded
                          : Icons.hourglass_empty_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _axisRow(String axis, double value) {
    return Row(
      children: [
        Text(
          '$axis : ',
          style: const TextStyle(color: kTextSecondary, fontSize: 12),
        ),
        Text(
          value.toStringAsFixed(2),
          style: const TextStyle(
            color: kTextPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _StickVisual extends StatelessWidget {
  final Offset offset;
  final Color accent;

  const _StickVisual({required this.offset, required this.accent});

  @override
  Widget build(BuildContext context) {
    const size = 70.0;
    const travel = 18.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF0A0B10),
        border: Border.all(color: accent.withAlpha(90), width: 1.4),
        boxShadow: [
          BoxShadow(color: accent.withAlpha(30), blurRadius: 12),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: kBorderColor, width: 1),
            ),
          ),
          Transform.translate(
            offset: Offset(offset.dx * travel, offset.dy * travel),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFF4A5464), Color(0xFF14161C)],
                ),
                border: Border.all(color: accent.withAlpha(160), width: 1.2),
                boxShadow: [
                  BoxShadow(color: accent.withAlpha(120), blurRadius: 8),
                ],
              ),
              child: Center(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}