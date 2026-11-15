import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_theme.dart';
import '../../../providers/controller_health_provider.dart';
import 'health_card.dart';

class _BtnItem {
  final String id;
  final String glyph;
  final Color color;
  const _BtnItem(this.id, this.glyph, this.color);
}

class ButtonTestCard extends StatelessWidget {
  const ButtonTestCard({super.key});

  static const _items = <_BtnItem>[
    _BtnItem('triangle', '△', kSuccessColor),
    _BtnItem('circle', '○', kErrorColor),
    _BtnItem('square', '□', kNeonPink),
    _BtnItem('cross', '✕', kPrimaryBlue),
    _BtnItem('l1', 'L1', kTextSecondary),
    _BtnItem('r1', 'R1', kTextSecondary),
    _BtnItem('share', 'SHARE', kTextSecondary),
    _BtnItem('options', 'OPT', kTextSecondary),
    _BtnItem('ps', 'PS', kPrimaryBlue),
    _BtnItem('touchpad', 'PAD', kAccentPurple),
    _BtnItem('l3', 'L3', kPrimaryBlue),
    _BtnItem('r3', 'R3', kPrimaryBlue),
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
          final twoCols = c.maxWidth >= 260;
          final width = twoCols ? (c.maxWidth - 10) / 2 : c.maxWidth;
          return Wrap(
            spacing: 10,
            runSpacing: 8,
            children: items.map((i) {
              final tested = p.isControlTested(i.id);
              return SizedBox(
                width: width,
                child: Row(
                  children: [
                    _glyph(i),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        i.id == 'touchpad' ? 'TOUCHPAD' : i.glyph,
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
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: i.color.withAlpha(18),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: i.color.withAlpha(90)),
      ),
      child: Center(
        child: Text(
          i.glyph,
          style: TextStyle(
            color: i.color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}