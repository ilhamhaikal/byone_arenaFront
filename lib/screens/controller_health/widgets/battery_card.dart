import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_theme.dart';
import '../../../models/controller_event.dart';
import '../../../providers/controller_health_provider.dart';
import 'health_card.dart';

class BatteryCard extends StatelessWidget {
  const BatteryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ControllerHealthProvider>();
    final supported = p.profile.capabilities.battery;
    final level = p.batteryLevel;
    final hasLevel = supported && level != null;

    final color = hasLevel
        ? (level <= 20
            ? kErrorColor
            : level <= 40
                ? kWarningColor
                : kSuccessColor)
        : kTextSecondary;

    return HealthCard(
      title: 'Level Baterai',
      icon: Icons.battery_charging_full_rounded,
      accent: color,
      trailing: p.charging
          ? const Icon(Icons.bolt_rounded, color: kWarningColor, size: 18)
          : null,
      child: hasLevel
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      level >= 90
                          ? Icons.battery_full_rounded
                          : level >= 50
                              ? Icons.battery_5_bar_rounded
                              : Icons.battery_2_bar_rounded,
                      color: color,
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$level%',
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (level / 100).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: kBorderColor,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                const Icon(Icons.power_off_rounded,
                    color: kTextSecondary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p.transport == ControllerTransport.usb
                        ? 'N/A (USB) — level baterai tidak tersedia'
                        : 'Level baterai tidak tersedia',
                    style: const TextStyle(
                        color: kTextSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
    );
  }
}