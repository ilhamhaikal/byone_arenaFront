import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../config/app_theme.dart';
import '../../../providers/controller_health_provider.dart';

/// Banner status keseluruhan + tombol Uji Ulang / Kembali.
class HealthBanner extends StatelessWidget {
  final VoidCallback onRetest;
  final VoidCallback onBack;

  const HealthBanner({
    super.key,
    required this.onRetest,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ControllerHealthProvider>();

    final (color, icon, title, subtitle) = switch (p.healthStatus) {
      ControllerHealthStatus.healthy => (
          kSuccessColor,
          Icons.check_circle_rounded,
          'Controller Sehat!',
          'Semua sistem berfungsi normal.',
        ),
      ControllerHealthStatus.needsCheck => (
          kWarningColor,
          Icons.warning_amber_rounded,
          'Perlu Pemeriksaan',
          '${p.testedButtonCount}/${p.profile.requiredButtons.length} tombol teruji • skor ${p.healthScore}%',
        ),
      ControllerHealthStatus.checking => (
          kPrimaryBlue,
          Icons.hourglass_top_rounded,
          'Menunggu Pengujian',
          'Tekan tombol dan gerakkan analog pada controller.',
        ),
      ControllerHealthStatus.disconnected => (
          kErrorColor,
          Icons.link_off_rounded,
          'Controller Terputus',
          'Hubungkan controller lalu uji ulang.',
        ),
    };

    final time = p.lastEventAt == null
        ? '—'
        : DateFormat('HH:mm:ss').format(p.lastEventAt!);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withAlpha(120), width: 1),
        boxShadow: [
          BoxShadow(color: color.withAlpha(28), blurRadius: 22),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final compact = c.maxWidth < 760;

          final content = Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [color, color.withAlpha(160)],
                  ),
                  boxShadow: [
                    BoxShadow(color: color.withAlpha(90), blurRadius: 16),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          color: kTextSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Diagnostik terakhir: $time',
                      style: const TextStyle(
                          color: kTextSecondary, fontSize: 10),
                    ),
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 12),
                _actions(),
              ],
            ],
          );

          if (!compact) return content;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              content,
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: _actions()),
            ],
          );
        },
      ),
    );
  }

  Widget _actions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: onRetest,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Uji Ulang', style: TextStyle(fontSize: 12)),
        ),
        ElevatedButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 16),
          label: const Text('Kembali', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}