import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';
import 'health_card.dart';

/// Panduan singkat pengujian controller.
class QuickGuideCard extends StatelessWidget {
  const QuickGuideCard({super.key});

  static const _tips = [
    'Tekan setiap tombol satu kali.',
    'Gerakkan kedua analog sampai penuh.',
    'Tarik L2/R2 hingga 100%.',
  ];

  @override
  Widget build(BuildContext context) {
    return HealthCard(
      title: 'Panduan Singkat',
      icon: Icons.lightbulb_outline_rounded,
      accent: kPrimaryBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _tips.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: kPrimaryBlue.withAlpha(25),
                    shape: BoxShape.circle,
                    border: Border.all(color: kPrimaryBlue.withAlpha(90)),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: kPrimaryBlue,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _tips[i],
                    style: const TextStyle(
                        color: kTextSecondary, fontSize: 11, height: 1.3),
                  ),
                ),
              ],
            ),
            if (i != _tips.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}