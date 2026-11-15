import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_theme.dart';
import '../../../providers/controller_health_provider.dart';
import 'health_card.dart';

class TriggerTestCard extends StatelessWidget {
  const TriggerTestCard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ControllerHealthProvider>();
    final ok = p.allTriggersTested;

    return HealthCard(
      title: 'Tes Trigger',
      icon: Icons.gamepad_rounded,
      accent: kPrimaryBlue,
      trailing: HealthPill(
        label: ok ? 'OK' : 'Menunggu',
        color: ok ? kSuccessColor : kTextSecondary,
        icon: ok ? Icons.check_rounded : null,
      ),
      child: Column(
        children: [
          _bar('L2', p.triggerOf('l2')),
          const SizedBox(height: 10),
          _bar('R2', p.triggerOf('r2')),
        ],
      ),
    );
  }

  Widget _bar(String label, double value) {
    final reached = value >= 0.9;
    final color = reached ? kSuccessColor : kPrimaryBlue;
    return Row(
      children: [
        SizedBox(
          width: 26,
          child: Text(
            label,
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              children: [
                Container(height: 9, color: kBorderColor),
                FractionallySizedBox(
                  widthFactor: value.clamp(0.0, 1.0),
                  child: Container(
                    height: 9,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withAlpha(180), color],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 42,
          child: Text(
            '${(value * 100).round()}%',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: reached ? kSuccessColor : kTextPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}