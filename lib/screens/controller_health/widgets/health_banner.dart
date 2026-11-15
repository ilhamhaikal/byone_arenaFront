import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../config/app_theme.dart';
import '../../../providers/controller_health_provider.dart';

/// Banner status keseluruhan dengan gaya mockup: frame bersudut (hexagon),
/// glow neon, dekorasi chevron kiri/kanan, ikon besar, dan tombol aksi.
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

    return LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxWidth < 1100;

        final centerGroup = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatusIcon(color: color, icon: icon),
            const SizedBox(width: 16),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: kTextPrimary.withAlpha(195),
                      fontSize: 13,
                    ),
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
            ),
          ],
        );

        final content = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 14),
          child: Stack(
            children: [
              Align(alignment: Alignment.center, child: centerGroup),
              if (!compact)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(child: _actions()),
                ),
            ],
          ),
        );

        return Container(
          constraints: const BoxConstraints(minHeight: 112),
          child: CustomPaint(
            painter: _BannerPainter(color: color),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      content,
                      Padding(
                        padding: const EdgeInsets.fromLTRB(42, 0, 42, 14),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _actions(),
                        ),
                      ),
                    ],
                  )
                : content,
          ),
        );
      },
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
          icon: const Icon(Icons.refresh_rounded, size: 15),
          label: const Text('Uji Ulang', style: TextStyle(fontSize: 11)),
          style: OutlinedButton.styleFrom(
            foregroundColor: kTextPrimary,
            side: BorderSide(color: kTextSecondary.withAlpha(120)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        ElevatedButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 15),
          label: const Text('Kembali', style: TextStyle(fontSize: 11)),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryBlue,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _StatusIcon({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color.withAlpha(255), color.withAlpha(190)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(130),
            blurRadius: 22,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 30),
    );
  }
}

/// Frame bersudut + glow + chevron dekoratif.
class _BannerPainter extends CustomPainter {
  final Color color;

  _BannerPainter({required this.color});

  Path _frame(Size s) {
    final w = s.width;
    final h = s.height;
    const cut = 34.0;
    final path = Path()
      ..moveTo(cut, 1)
      ..lineTo(w - cut * 1.7, 1)
      ..lineTo(w - cut * 0.7, h / 2)
      ..lineTo(w - cut * 1.7, h - 1)
      ..lineTo(cut, h - 1)
      ..lineTo(1, h / 2)
      ..close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _frame(size);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // glow luar
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = color.withAlpha(55)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 12),
    );

    // isi
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [
            color.withAlpha(26),
            const Color(0xFF08120D),
            const Color(0xFF08120D),
            color.withAlpha(26),
          ],
          stops: const [0, 0.25, 0.75, 1],
        ).createShader(rect),
    );

    // border
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withAlpha(220),
    );

    // garis dalam tipis
    canvas.save();
    canvas.translate(4, 4);
    canvas.drawPath(
      _frame(Size(size.width - 8, size.height - 8)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withAlpha(22),
    );
    canvas.restore();

    // chevron dekoratif kiri & kanan
    final chevron = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = color.withAlpha(120);

    for (var i = 0; i < 3; i++) {
      final x = 14.0 + i * 11;
      final p1 = Path()
        ..moveTo(x + 12, size.height * 0.26)
        ..lineTo(x, size.height / 2)
        ..lineTo(x + 12, size.height * 0.74);
      canvas.drawPath(p1, chevron);

      final xr = size.width - 14.0 - i * 11;
      final p2 = Path()
        ..moveTo(xr - 12, size.height * 0.26)
        ..lineTo(xr, size.height / 2)
        ..lineTo(xr - 12, size.height * 0.74);
      canvas.drawPath(p2, chevron);
    }

    // aksen biru tipis di ujung
    final accent = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = kPrimaryBlue.withAlpha(90);
    canvas.drawLine(
        Offset(8, size.height * 0.18), Offset(34, 2), accent);
    canvas.drawLine(Offset(size.width - 8, size.height * 0.18),
        Offset(size.width - 34, 2), accent);
  }

  @override
  bool shouldRepaint(_BannerPainter old) => old.color != color;
}