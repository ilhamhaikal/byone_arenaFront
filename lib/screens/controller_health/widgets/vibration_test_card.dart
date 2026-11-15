import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_theme.dart';
import '../../../providers/controller_health_provider.dart';
import 'health_card.dart';

class VibrationTestCard extends StatelessWidget {
  const VibrationTestCard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ControllerHealthProvider>();
    final supported = p.profile.capabilities.rumble;

    return HealthCard(
      title: 'Tes Getaran',
      icon: Icons.vibration_rounded,
      accent: kAccentPurple,
      child: !supported
          ? const Text(
              'Model controller ini tidak mendukung getaran.',
              style: TextStyle(color: kTextSecondary, fontSize: 12),
            )
          : Column(
              children: [
                _VibrationArt(active: p.vibration == VibrationState.testing),
                const SizedBox(height: 10),
                _action(context, p),
              ],
            ),
    );
  }

  Widget _action(BuildContext context, ControllerHealthProvider p) {
    switch (p.vibration) {
      case VibrationState.testing:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: kAccentPurple),
            ),
            SizedBox(width: 8),
            Text('Menguji...',
                style: TextStyle(color: kAccentPurple, fontSize: 12)),
          ],
        );
      case VibrationState.done:
        return Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded,
                    color: kSuccessColor, size: 14),
                SizedBox(width: 6),
                Text('Getaran terdeteksi',
                    style: TextStyle(color: kSuccessColor, fontSize: 12)),
              ],
            ),
            TextButton(
              onPressed: p.requestVibration,
              child: const Text('Tes Lagi', style: TextStyle(fontSize: 12)),
            ),
          ],
        );
      case VibrationState.idle:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: p.requestVibration,
            icon: const Icon(Icons.vibration_rounded, size: 15),
            label: const Text('Tes Getar', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: kAccentPurple,
              side: BorderSide(color: kAccentPurple.withAlpha(120)),
            ),
          ),
        );
    }
  }
}

class _VibrationArt extends StatelessWidget {
  final bool active;

  const _VibrationArt({required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? kAccentPurple : kTextSecondary;
    return SizedBox(
      height: 44,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _wave(color, active, true),
          const SizedBox(width: 6),
          Icon(Icons.sports_esports_rounded, color: color, size: 34),
          const SizedBox(width: 6),
          _wave(color, active, false),
        ],
      ),
    );
  }

  Widget _wave(Color color, bool active, bool left) {
    return Icon(
      left ? Icons.wifi_rounded : Icons.wifi_rounded,
      color: color.withAlpha(active ? 220 : 90),
      size: 22,
    );
  }
}