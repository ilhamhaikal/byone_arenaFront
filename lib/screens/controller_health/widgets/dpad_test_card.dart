import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_theme.dart';
import '../../../providers/controller_health_provider.dart';
import 'health_card.dart';

class DPadTestCard extends StatelessWidget {
  const DPadTestCard({super.key});

  static const _dirs = ['dpadUp', 'dpadLeft', 'dpadRight', 'dpadDown'];

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ControllerHealthProvider>();
    final allTested = _dirs.every(p.isControlTested);

    return HealthCard(
      title: 'Tes D-Pad',
      icon: Icons.control_camera_rounded,
      accent: kAccentPurple,
      trailing: HealthPill(
        label: allTested ? 'OK' : '${_dirs.where(p.isControlTested).length}/4',
        color: allTested ? kSuccessColor : kTextSecondary,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 116,
            height: 116,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _arrow(p, 'dpadUp', Icons.keyboard_arrow_up_rounded),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _arrow(p, 'dpadLeft', Icons.keyboard_arrow_left_rounded),
                    Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: kCardColor,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: kBorderColor),
                      ),
                    ),
                    _arrow(p, 'dpadRight', Icons.keyboard_arrow_right_rounded),
                  ],
                ),
                _arrow(p, 'dpadDown', Icons.keyboard_arrow_down_rounded),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              allTested
                  ? 'Semua arah D-Pad merespons.'
                  : 'Tekan keempat arah D-Pad pada controller.',
              style: const TextStyle(color: kTextSecondary, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _arrow(ControllerHealthProvider p, String id, IconData icon) {
    final active = p.pressed.contains(id);
    final tested = p.isControlTested(id);
    final color = active
        ? kAccentPurple
        : tested
            ? kSuccessColor
            : kTextSecondary;
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color.withAlpha(active ? 55 : 18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(active ? 200 : 70)),
        boxShadow: active
            ? [BoxShadow(color: color.withAlpha(90), blurRadius: 10)]
            : null,
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}