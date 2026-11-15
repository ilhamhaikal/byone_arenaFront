import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_theme.dart';
import '../../../models/controller_event.dart';
import '../../../providers/controller_health_provider.dart';
import 'health_card.dart';

class ConnectionStatusCard extends StatelessWidget {
  const ConnectionStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ControllerHealthProvider>();
    final color = p.isConnected ? kSuccessColor : kErrorColor;
    final icon = p.transport == ControllerTransport.usb
        ? Icons.usb_rounded
        : Icons.bluetooth_rounded;

    return HealthCard(
      title: 'Status Koneksi',
      icon: Icons.link_rounded,
      accent: color,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha(18),
              border: Border.all(color: color.withAlpha(90), width: 1.2),
              boxShadow: [
                BoxShadow(color: color.withAlpha(45), blurRadius: 16),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  p.isConnected ? 'Terhubung' : 'Terputus',
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  p.isConnected ? p.transport.label : 'Periksa kabel / Bluetooth',
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}