import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../config/app_theme.dart';
import '../../../providers/controller_health_provider.dart';

/// Banner status keseluruhan (gaya mockup): latar bergradien, ikon besar,
/// skor, dekorasi chevron, dan tombol Uji Ulang / Kembali.
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
          Icons.check_rounded,
          'Controller Sehat!',
          'Semua sistem berfungsi normal.',
        ),
      ControllerHealthStatus.needsCheck => (
          kWarningColor,
          Icons.warning_amber_rounded,
          'Perlu Pemeriksaan',
          '${p.testedButtonCount}/${p.profile.requiredButtons.length} tombol teruji',
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [color.withAlpha(55), color.withAlpha(10)],
        ),
        border: Border.all(color: color.withAlpha(150), width: 1.2),
        boxShadow: [
          BoxShadow(color: color.withAlpha(30), blurRadius: 24),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _ChevronPainter(color)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            child: LayoutBuilder(
              builder: (context, c) {
                final compact = c.maxWidth < 860;

                final main = Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [color, color.withAlpha(170)],
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: color.withAlpha(120),
                              blurRadius: 18,
                              spreadRadius: 2),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: kTextPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: const TextStyle(
                                color: kTextSecondary, fontSize: 13),
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
                    const SizedBox(width: 14),
                    _ScoreBadge(score: p.healthScore, color: color),
                    if (!compact) ...[
                      const SizedBox(width: 14),
                      _actions(),
                    ],
                  ],
                );

                if (!compact) return main;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    main,
                    const SizedBox(height: 12),
                    Align(alignment: Alignment.centerRight, child: _actions()),
                  ],
                );
              },
            ),
          ),
        ],
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

class _ScoreBadge extends StatelessWidget {
  final int score;
  final Color color;

  const _ScoreBadge({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(110)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$score%',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const Text(
            'SKOR',
            style: TextStyle(
                color: kTextSecondary,
                fontSize: 8,
                letterSpacing: 1,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Dekorasi chevron kiri/kanan seperti mockup.
class _ChevronPainter extends CustomPainter {
  final Color color;

  _ChevronPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 3; i++) {
      final x = 16.0 + i * 12;
      final p1 = Path()
        ..moveTo(x + 16, size.height * 0.28)
        ..lineTo(x, size.height / 2)
        ..lineTo(x + 16, size.height * 0.72);
      canvas.drawPath(p1, paint);

      final xr = size.width - 16.0 - i * 12;
      final p2 = Path()
        ..moveTo(xr - 16, size.height * 0.28)
        ..lineTo(xr, size.height / 2)
        ..lineTo(xr - 16, size.height * 0.72);
      canvas.drawPath(p2, paint);
    }
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color;
}