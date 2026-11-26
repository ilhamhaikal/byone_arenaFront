import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_theme.dart';
import '../../../providers/controller_health_provider.dart';
import 'health_card.dart';

/// Kartu monitoring analog kiri / kanan, termasuk diagnosa stick:
/// jangkauan, drift saat dilepas, dan kerataan lingkaran.
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
    final stats = p.statsOf(controlId);
    final tested = p.isAnalogTested(controlId);
    final condition = p.analogCondition(controlId);
    final normal = condition == 'Normal';
    final waiting = condition == 'Menunggu';

    final color = waiting
        ? kTextSecondary
        : normal
            ? kSuccessColor
            : kWarningColor;

    final hasData = stats != null && stats.hasSamples;
    final rangePct = hasData ? (stats.maxRadius * 100).round() : 0;
    final drift = stats?.restDistance;
    final circularity = hasData && stats.allQuadrants
        ? (stats.circularity * 100).round()
        : null;

    return HealthCard(
      title: title,
      icon: icon,
      accent: accent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StickVisual(offset: v, accent: accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: _axisRow('X', v.dx)),
                    Expanded(child: _axisRow('Y', v.dy)),
                  ],
                ),
                const SizedBox(height: 8),
                if (hasData) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _statChip(
                        'Jangkauan $rangePct%',
                        rangePct >= 85 ? kSuccessColor : kWarningColor,
                      ),
                      _statChip(
                        drift == null
                            ? 'Drift -'
                            : 'Drift ${drift.toStringAsFixed(2)}',
                        drift == null
                            ? kTextSecondary
                            : (drift > 0.12 ? kWarningColor : kSuccessColor),
                      ),
                      if (circularity != null)
                        _statChip(
                          'Lingkaran $circularity%',
                          circularity >= 80 ? kSuccessColor : kWarningColor,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ] else ...[
                  const Text(
                    'Putar stick penuh ke segala arah,\nlalu lepaskan untuk cek drift.',
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: HealthPill(
                    label: condition,
                    color: color,
                    icon: normal
                        ? Icons.check_circle_rounded
                        : tested
                            ? Icons.warning_amber_rounded
                            : Icons.hourglass_empty_rounded,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _axisRow(String axis, double value) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
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
      ),
    );
  }

  Widget _statChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
        ),
      ),
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
