import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/controller_event.dart';
import '../../providers/controller_health_provider.dart';
import '../../widgets/premium_background.dart';
import 'widgets/analog_monitor_card.dart';
import 'widgets/battery_card.dart';
import 'widgets/button_test_card.dart';
import 'widgets/connection_status_card.dart';
import 'widgets/controller_visualization.dart';
import 'widgets/dpad_test_card.dart';
import 'widgets/health_banner.dart';
import 'widgets/health_card.dart';
import 'widgets/quick_guide_card.dart';
import 'widgets/test_progress_card.dart';
import 'widgets/trigger_test_card.dart';
import 'widgets/vibration_test_card.dart';

/// Halaman diagnostik controller (DualShock 4 untuk saat ini).
///
/// Halaman dibuka full-screen (tanpa sidebar) dan menyesuaikan diri dari
/// [ControllerProfile] sehingga PS3/PS5 dapat ditambahkan lewat registry.
class ControllerHealthPage extends StatefulWidget {
  /// Halaman hidup di dalam IndexedStack; simulasi hanya berjalan saat aktif.
  final bool isActive;

  /// Aksi tombol "Kembali" (biasanya kembali ke Dashboard).
  final VoidCallback? onBack;

  const ControllerHealthPage({
    super.key,
    this.isActive = true,
    this.onBack,
  });

  @override
  State<ControllerHealthPage> createState() => _ControllerHealthPageState();
}

class _ControllerHealthPageState extends State<ControllerHealthPage> {
  ControllerHealthProvider? _provider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_provider == null) {
      _provider = context.read<ControllerHealthProvider>();
      if (widget.isActive) _provider!.start();
    }
  }

  @override
  void didUpdateWidget(covariant ControllerHealthPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive == widget.isActive) return;
    if (widget.isActive) {
      _provider?.start();
    } else {
      _provider?.stop();
    }
  }

  @override
  void dispose() {
    // Hentikan timer simulasi saat halaman tidak aktif/ditutup.
    _provider?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ControllerHealthProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: kSecondaryColor,
        automaticallyImplyLeading: false,
        title: const Text('Controller'),
        actions: [
          if (p.isSimulated)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: HealthPill(
                  label: 'SIMULASI',
                  color: kWarningColor,
                  icon: Icons.science_rounded,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: PremiumBackground()),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 1000;
              final medium = c.maxWidth >= 720;
              final short = MediaQuery.sizeOf(context).height < 820;

              final header = short ? _buildCompactHeader(p) : _buildHeader(p);
              final controller = ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: wide ? 900 : 640,
                  maxHeight: short ? 360 : 560,
                ),
                child: const ControllerVisualization(),
              );

              final leftColumn = Column(
                children: const [
                  ConnectionStatusCard(),
                  SizedBox(height: 12),
                  AnalogMonitorCard(
                    controlId: 'leftStick',
                    title: 'Analog Kiri',
                    label: 'L Stick',
                    accent: kPrimaryBlue,
                    icon: Icons.gamepad_rounded,
                  ),
                  SizedBox(height: 12),
                  TestProgressCard(),
                ],
              );

              final rightColumn = Column(
                children: const [
                  BatteryCard(),
                  SizedBox(height: 12),
                  AnalogMonitorCard(
                    controlId: 'rightStick',
                    title: 'Analog Kanan',
                    label: 'R Stick',
                    accent: kAccentPurple,
                    icon: Icons.gamepad_rounded,
                  ),
                  SizedBox(height: 12),
                  QuickGuideCard(),
                ],
              );

              final tests = _buildTests(c.maxWidth - 40, wide, medium);
              final banner = HealthBanner(
                onRetest: p.retest,
                onBack: widget.onBack ??
                    () {
                      final nav = Navigator.of(context);
                      if (nav.canPop()) nav.pop();
                    },
              );

              return SingleChildScrollView(
              key: const PageStorageKey('controller-scroll'),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    const SizedBox(height: 14),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: leftColumn),
                          const SizedBox(width: 14),
                          Expanded(flex: 9, child: Center(child: controller)),
                          const SizedBox(width: 14),
                          Expanded(flex: 3, child: rightColumn),
                        ],
                      )
                    else if (medium) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(child: ConnectionStatusCard()),
                          const SizedBox(width: 12),
                          const Expanded(child: BatteryCard()),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Center(child: controller),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Expanded(
                            child: AnalogMonitorCard(
                              controlId: 'leftStick',
                              title: 'Analog Kiri',
                              label: 'L Stick',
                              accent: kPrimaryBlue,
                              icon: Icons.gamepad_rounded,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: AnalogMonitorCard(
                              controlId: 'rightStick',
                              title: 'Analog Kanan',
                              label: 'R Stick',
                              accent: kAccentPurple,
                              icon: Icons.gamepad_rounded,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const ConnectionStatusCard(),
                      const SizedBox(height: 12),
                      const BatteryCard(),
                      const SizedBox(height: 14),
                      Center(child: controller),
                      const SizedBox(height: 14),
                      const AnalogMonitorCard(
                        controlId: 'leftStick',
                        title: 'Analog Kiri',
                        label: 'L Stick',
                        accent: kPrimaryBlue,
                        icon: Icons.gamepad_rounded,
                      ),
                      const SizedBox(height: 12),
                      const AnalogMonitorCard(
                        controlId: 'rightStick',
                        title: 'Analog Kanan',
                        label: 'R Stick',
                        accent: kAccentPurple,
                        icon: Icons.gamepad_rounded,
                      ),
                    ],
                    const SizedBox(height: 16),
                    tests,
                    const SizedBox(height: 14),
                    banner,
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHeader(ControllerHealthProvider p) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            gradient: kGradientBlue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.sports_esports_rounded,
              color: Colors.white, size: 18),
        ),
        const SizedBox(width: 9),
        const Expanded(
          child: Text(
            'Cek Kesehatan Controller',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            p.profile.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(color: kTextSecondary, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ControllerHealthProvider p) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: kGradientBlue,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: kPrimaryBlue.withAlpha(70), blurRadius: 14),
                ],
              ),
              child: const Icon(Icons.sports_esports_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Cek Kesehatan Controller',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(child: Divider(color: kBorderColor, height: 1)),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  p.profile.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: kTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const Expanded(child: Divider(color: kBorderColor, height: 1)),
          ],
        ),
      ],
    );
  }

  Widget _buildTests(double width, bool wide, bool medium) {
    final columns = wide ? 4 : (medium ? 2 : 1);
    const gap = 12.0;
    // -0.5 mencegah pembulatan membuat kartu ke-4 turun baris.
    final itemWidth = ((width - (columns - 1) * gap) / columns) - 0.5;

    final cards = <Widget>[
      const ButtonTestCard(),
      const DPadTestCard(),
      const TriggerTestCard(),
      const VibrationTestCard(),
    ];

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: cards
          .map((c) => SizedBox(width: itemWidth, child: c))
          .toList(),
    );
  }
}