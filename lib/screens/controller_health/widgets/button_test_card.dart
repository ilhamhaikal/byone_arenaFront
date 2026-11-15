import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_theme.dart';
import '../../../providers/controller_health_provider.dart';
import 'health_card.dart';

class _BtnItem {
  final String id;
  final String badge;
  final String label;
  final Color color;

  const _BtnItem(this.id, this.badge, this.label, this.color);
}

class ButtonTestCard extends StatelessWidget {
  const ButtonTestCard({super.key});

  static const _items = <_BtnItem>[
    _BtnItem('triangle', '△', 'Triangle', kSuccessColor),
    _BtnItem('circle', '○', 'Circle', kErrorColor),
    _BtnItem('square', '□', 'Square', kNeonPink),
    _BtnItem('cross', '✕', 'Cross', kPrimaryBlue),
    _BtnItem('l1', 'L1', 'L1', kTextSecondary),
    _BtnItem('r1', 'R1', 'R1', kTextSecondary),
    _BtnItem('share', 'SH', 'Share', kTextSecondary),
    _BtnItem('options', 'OP', 'Options', kTextSecondary),
    _BtnItem('ps', 'PS', 'PS', kPrimaryBlue),
    _BtnItem('touchpad', 'PD', 'Touchpad', kAccentPurple),
    _BtnItem('l3', 'L3', 'L3', kPrimaryBlue),
    _BtnItem('r3', 'R3', 'R3', kPrimaryBlue),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ControllerHealthProvider>();
    final items = _items
        .where((i) => i.id != 'touchpad' || p.profile.capabilities.touchpad)
        .toList();

    return HealthCard(
      title: 'Tes Tombol',
      icon: Icons.sports_esports_rounded,
      accent: kPrimaryBlue,
      child: LayoutBuilder(
        builder: (context, c) {
          final columns = c.maxWidth >= 330 ? 3 : (c.maxWidth >= 200 ? 2 : 1);
          final width =
              (c.maxWidth - (columns - 1) * 10) / columns - 0.5;
          return Wrap(
            spacing: 10,
            runSpacing: 7,
            children: items.map((i) {
              final tested = p.isControlTested(i.id);
              return SizedBox(
                width: width,
                child: Row(
                  children: [
                    _glyph(i),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        i.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: kTextSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    HealthPill(
                      label: tested ? 'OK' : '—',
                      color: tested ? kSuccessColor : kTextSecondary,
                      icon: tested ? Icons.check_rounded : null,
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _glyph(_BtnItem i) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: i.color.withAlpha(18),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: i.color.withAlpha(90)),
      ),
      child: Center(
        child: Text(
          i.badge,
          style: TextStyle(
            color: i.color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}