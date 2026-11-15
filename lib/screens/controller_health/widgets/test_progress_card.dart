import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_theme.dart';
import '../../../providers/controller_health_provider.dart';
import 'health_card.dart';

/// Ringkasan progres pengujian (tombol, trigger, analog).
class TestProgressCard extends StatelessWidget {
  const TestProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ControllerHealthProvider>();
    final btnTotal = p.profile.requiredButtons.length;
    final trgTotal = p.profile.requiredTriggers.length;
    final anaTotal = p.profile.requiredAnalogs.length;

    final btnDone = p.testedButtonCount;
    final trgDone = p.profile.requiredTriggers
        .where((id) => p.isControlTested(id))
        .length;
    final anaDone = p.profile.requiredAnalogs
        .where((id) => p.analogOf(id).distance > 0.5)
        .length;

    return HealthCard(
      title: 'Progres Pengujian',
      icon: Icons.checklist_rounded,
      accent: kAccentPurple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${p.healthScore}%',
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const Spacer(),
              HealthPill(
                label: p.isHealthy ? 'Lengkap' : 'Berjalan',
                color: p.isHealthy ? kSuccessColor : kWarningColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: p.healthScore / 100,
              minHeight: 7,
              backgroundColor: kBorderColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                p.isHealthy ? kSuccessColor : kAccentPurple,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _row('Tombol', btnDone, btnTotal),
          const SizedBox(height: 4),
          _row('Trigger', trgDone, trgTotal),
          const SizedBox(height: 4),
          _row('Analog', anaDone, anaTotal),
        ],
      ),
    );
  }

  Widget _row(String label, int done, int total) {
    final complete = total > 0 && done >= total;
    final color = complete ? kSuccessColor : kTextSecondary;
    return Row(
      children: [
        Icon(
          complete ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label,
              style: const TextStyle(color: kTextSecondary, fontSize: 11)),
        ),
        Text(
          '$done/$total',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}