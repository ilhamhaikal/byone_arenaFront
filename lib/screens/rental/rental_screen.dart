import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/console_overview_model.dart';
import '../../models/session_model.dart';
import '../../providers/console_provider.dart';
import '../../providers/session_provider.dart';
import 'start_session_dialog.dart';
import 'end_session_dialog.dart';

class RentalScreen extends StatefulWidget {
  const RentalScreen({super.key});
  @override
  State<RentalScreen> createState() => _RentalScreenState();
}

class _RentalScreenState extends State<RentalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Timer? _ticker; // rebuild setiap detik untuk update timer
  Timer? _autoRefresh; // auto-refresh dari server setiap 30 detik

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _autoRefresh = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _ticker?.cancel();
    _autoRefresh?.cancel();
    super.dispose();
  }

  void _loadData() {
    context.read<ConsoleProvider>().loadOverview();
    context.read<SessionProvider>().loadAll();
  }

  void _openStartSession(ConsoleOverviewModel? console) {
    showDialog(
      context: context,
      builder: (_) => StartSessionDialog(preselectedConsole: console),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDeepBlack,
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _PanelTab(
              onStartSession: _openStartSession, onReload: _loadData),
          _HistoryTab(
              onRefresh: () => context.read<SessionProvider>().loadAll()),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0A0A0F),
      title: const Text('Kontrol Konsol'),
      actions: [
        Consumer<ConsoleProvider>(
          builder: (_, p, __) => IconButton(
            tooltip: 'Refresh',
            icon: p.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: kPrimaryBlue))
                : const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(46),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: kBorderColor, width: 0.5)),
          ),
          child: TabBar(
            controller: _tabCtrl,
            padding: EdgeInsets.zero,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 2,
            tabs: const [
              Tab(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.dashboard_rounded, size: 16),
                  SizedBox(width: 6),
                  Text('Panel'),
                ]),
              ),
              Tab(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.history_rounded, size: 16),
                  SizedBox(width: 6),
                  Text('Riwayat'),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Panel Tab ────────────────────────────────────────────────────────────────
class _PanelTab extends StatelessWidget {
  final void Function(ConsoleOverviewModel?) onStartSession;
  final VoidCallback onReload;
  const _PanelTab({required this.onStartSession, required this.onReload});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConsoleProvider>(
      builder: (context, p, _) {
        if (p.overview.isEmpty && p.isLoading) {
          return const Center(
              child: CircularProgressIndicator(color: kPrimaryBlue));
        }
        if (p.overview.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: kCardColor,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: kBorderColor),
                  ),
                  child: const Icon(Icons.videogame_asset_outlined,
                      size: 40, color: kTextSecondary),
                ),
                const SizedBox(height: 16),
                const Text('Belum ada konsol terdaftar',
                    style: TextStyle(
                        color: kTextPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                const Text('Tambah konsol di menu Konsol',
                    style: TextStyle(color: kTextSecondary, fontSize: 13)),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: p.loadOverview,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        final active = p.overview.where((c) => c.isInUse).length;
        final available = p.overview.where((c) => c.isAvailable).length;
        final maintenance = p.overview.where((c) => c.isMaintenance).length;

        // Urutan: aktif → tersedia → maintenance
        final sorted = [...p.overview]..sort((a, b) {
            const order = {'in_use': 0, 'available': 1, 'maintenance': 2};
            return (order[a.status] ?? 3).compareTo(order[b.status] ?? 3);
          });

        return RefreshIndicator(
          color: kPrimaryBlue,
          backgroundColor: kSurface,
          onRefresh: p.loadOverview,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              _SummaryBar(
                  active: active,
                  available: available,
                  maintenance: maintenance),
              const SizedBox(height: 16),
              ...sorted.map((c) => _ConsoleControlCard(
                    console: c,
                    onStartSession: () => onStartSession(c),
                    onReload: onReload,
                  )),
            ],
          ),
        );
      },
    );
  }
}

// ─── Summary Bar ─────────────────────────────────────────────────────────────
class _SummaryBar extends StatelessWidget {
  final int active, available, maintenance;
  const _SummaryBar(
      {required this.active,
      required this.available,
      required this.maintenance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderColor, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(
              count: active,
              label: 'Aktif',
              color: kSuccessColor,
              icon: Icons.play_circle_outline_rounded),
          _divider(),
          _SummaryItem(
              count: available,
              label: 'Tersedia',
              color: kPrimaryBlue,
              icon: Icons.circle_outlined),
          _divider(),
          _SummaryItem(
              count: maintenance,
              label: 'Maintenance',
              color: kWarningColor,
              icon: Icons.build_outlined),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 0.5, height: 36, color: kBorderColor);
}

class _SummaryItem extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;
  const _SummaryItem(
      {required this.count,
      required this.label,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$count',
                style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.1)),
            Text(label,
                style:
                    const TextStyle(color: kTextSecondary, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

// ─── Console Control Card ────────────────────────────────────────────────────
class _ConsoleControlCard extends StatelessWidget {
  final ConsoleOverviewModel console;
  final VoidCallback onStartSession;
  final VoidCallback onReload;
  const _ConsoleControlCard(
      {required this.console,
      required this.onStartSession,
      required this.onReload});

  Color get _typeColor {
    switch (console.consoleType) {
      case 'PS5':
        return kAccentPurple;
      case 'PS4':
        return kPrimaryBlue;
      case 'PS3':
        return kNeonPink;
      case 'AndroidTV':
        return kSuccessColor;
      default:
        return kPrimaryBlue;
    }
  }

  LinearGradient get _typeGrad {
    switch (console.consoleType) {
      case 'PS5':
        return kGradientPurple;
      case 'PS3':
        return kGradientPink;
      case 'AndroidTV':
        return kGradientGreen;
      default:
        return kGradientBlue;
    }
  }

  String _fmtDur(Duration d) =>
      '${d.inHours.toString().padLeft(2, '0')}:'
      '${(d.inMinutes % 60).toString().padLeft(2, '0')}:'
      '${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (console.isInUse) return _buildActive(context);
    if (console.isMaintenance) return _buildMaintenance(context);
    return _buildIdle(context);
  }

  // ── Tersedia / OFF ────────────────────────────────────────────────────────
  Widget _buildIdle(BuildContext context) {
    final fmt = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderColor, width: 0.5),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: kDeepBlack,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kBorderColor),
                  ),
                  child: Icon(
                    console.isAndroidTV
                        ? Icons.tv_outlined
                        : Icons.sports_esports_outlined,
                    color: kTextSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _typeColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                  color: _typeColor.withAlpha(60)),
                            ),
                            child: Text(console.consoleType,
                                style: TextStyle(
                                    color: _typeColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(console.name,
                                style: const TextStyle(
                                    color: kTextPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${fmt.format(console.pricePerHour)}/jam',
                          style: const TextStyle(
                              color: kTextSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                // OFF badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kDeepBlack,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kBorderColor),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.power_settings_new_rounded,
                          size: 10, color: kTextSecondary),
                      SizedBox(width: 4),
                      Text('OFF',
                          style: TextStyle(
                              color: kTextSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Status kunci TV
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(
              children: [
                const Icon(Icons.lock_outline,
                    size: 12, color: kTextSecondary),
                const SizedBox(width: 4),
                Text(
                  console.isAndroidTV
                      ? 'TV Terkunci · Menampilkan Screen Saver'
                      : 'Siap Disewa',
                  style: const TextStyle(
                      color: kTextSecondary, fontSize: 12),
                ),
                if (console.ipAddress != null &&
                    console.ipAddress!.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.router_outlined,
                      size: 12, color: kTextSecondary),
                  const SizedBox(width: 4),
                  Text(console.ipAddress!,
                      style: const TextStyle(
                          color: kTextSecondary, fontSize: 12)),
                ],
              ],
            ),
          ),
          // Tombol Mulai Sesi
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: SizedBox(
              width: double.infinity,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onStartSession,
                  borderRadius: BorderRadius.circular(10),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: kGradientGreen,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                            color: kSuccessColor.withAlpha(60),
                            blurRadius: 10)
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded,
                            size: 18, color: Colors.white),
                        SizedBox(width: 6),
                        Text('Mulai Sesi',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Aktif / IN USE ────────────────────────────────────────────────────────
  Widget _buildActive(BuildContext context) {
    final sess = console.activeSession!;
    final elapsed = sess.elapsed;
    final remaining = sess.remaining;
    final isOvertime = sess.isOvertime;
    final progress = sess.progress.clamp(0.0, 1.0);
    final cost = elapsed.inSeconds / 3600.0 * console.pricePerHour;
    final fmt =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOvertime
              ? kWarningColor.withAlpha(150)
              : _typeColor.withAlpha(80),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(color: _typeColor.withAlpha(20), blurRadius: 20)
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_typeColor.withAlpha(30), Colors.transparent],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              border: const Border(
                  bottom: BorderSide(color: kBorderColor, width: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: _typeGrad,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                          color: _typeColor.withAlpha(80), blurRadius: 6)
                    ],
                  ),
                  child: Text(console.consoleType,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(console.name,
                      style: const TextStyle(
                          color: kTextPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                      overflow: TextOverflow.ellipsis),
                ),
                // AKTIF badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kSuccessColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: kSuccessColor.withAlpha(80), width: 0.5),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 6, color: kSuccessColor),
                      SizedBox(width: 4),
                      Text('AKTIF',
                          style: TextStyle(
                              color: kSuccessColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Timer section
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kDeepBlack,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorderColor, width: 0.5),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Durasi bermain
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DURASI BERMAIN',
                              style: TextStyle(
                                  color: kTextSecondary,
                                  fontSize: 10,
                                  letterSpacing: 0.8)),
                          const SizedBox(height: 4),
                          ShaderMask(
                            shaderCallback: (b) =>
                                kGradientBlue.createShader(b),
                            child: Text(_fmtDur(elapsed),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                    fontFamily: 'Poppins')),
                          ),
                        ],
                      ),
                      // Sisa waktu / overtime
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isOvertime ? 'OVERTIME' : 'SISA WAKTU',
                            style: TextStyle(
                                color: isOvertime
                                    ? kWarningColor
                                    : kTextSecondary,
                                fontSize: 10,
                                letterSpacing: 0.8),
                          ),
                          const SizedBox(height: 4),
                          if (remaining != null)
                            ShaderMask(
                              shaderCallback: (b) => (isOvertime
                                      ? kGradientAmber
                                      : kGradientGreen)
                                  .createShader(b),
                              child: Text(_fmtDur(remaining),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1)),
                            )
                          else
                            const Text('Open',
                                style: TextStyle(
                                    color: kTextSecondary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  // Progress bar
                  const SizedBox(height: 10),
                  Stack(
                    children: [
                      Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: kBorderColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 5,
                          decoration: BoxDecoration(
                            gradient: isOvertime
                                ? kGradientAmber
                                : kGradientGreen,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${sess.bookedDurationMinutes ~/ 60}h dipesan',
                        style: const TextStyle(
                            color: kTextSecondary, fontSize: 11),
                      ),
                      ShaderMask(
                        shaderCallback: (b) =>
                            kGradientAmber.createShader(b),
                        child: Text(fmt.format(cost.toInt()),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Info pelanggan + waktu mulai
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(
              children: [
                const Icon(Icons.person_outline_rounded,
                    size: 13, color: kTextSecondary),
                const SizedBox(width: 4),
                Text(sess.customerName ?? 'Umum (Non-Member)',
                    style:
                        const TextStyle(color: kTextSecondary, fontSize: 12)),
                const Spacer(),
                const Icon(Icons.access_time_rounded,
                    size: 13, color: kTextSecondary),
                const SizedBox(width: 4),
                Text('Mulai ${DateFormat('HH:mm').format(sess.startTime)}',
                    style:
                        const TextStyle(color: kTextSecondary, fontSize: 12)),
              ],
            ),
          ),
          // Tombol aksi
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _cancel(context),
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(color: kErrorColor.withAlpha(150)),
                        foregroundColor: kErrorColor),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Batalkan'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _end(context, elapsed),
                      borderRadius: BorderRadius.circular(10),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: kGradientBlue,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                                color: kPrimaryBlue.withAlpha(80),
                                blurRadius: 12)
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.stop_circle_rounded,
                                size: 16, color: Colors.white),
                            SizedBox(width: 6),
                            Text('Akhiri Sesi',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Maintenance ───────────────────────────────────────────────────────────
  Widget _buildMaintenance(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kWarningColor.withAlpha(80), width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: kWarningColor.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.build_outlined,
                  color: kWarningColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _typeColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(console.consoleType,
                            style: TextStyle(
                                color: _typeColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(console.name,
                            style: const TextStyle(
                                color: kTextPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Sedang dalam perawatan',
                      style:
                          TextStyle(color: kTextSecondary, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: kWarningColor.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: kWarningColor.withAlpha(80), width: 0.5),
              ),
              child: const Text('MAINTENANCE',
                  style: TextStyle(
                      color: kWarningColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> _cancel(BuildContext context) async {
    final sess = console.activeSession;
    if (sess == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Batalkan Sesi'),
        content: Text(
            'Batalkan sesi ${console.name}?\nTidak ada tagihan yang diproses.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tidak')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: kErrorColor),
            child: const Text('Batalkan Sesi'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<SessionProvider>().cancel(sess.id);
      onReload();
    }
  }

  void _end(BuildContext context, Duration elapsed) {
    final sess = console.activeSession;
    if (sess == null) return;
    showDialog(
      context: context,
      builder: (_) => EndSessionDialog(
        sessionId: sess.id,
        consoleName: console.name,
        consoleType: console.consoleType,
        customerName: sess.customerName,
        elapsed: elapsed,
      ),
    ).then((_) => onReload());
  }
}

// ─── History Tab ─────────────────────────────────────────────────────────────
class _HistoryTab extends StatelessWidget {
  final VoidCallback onRefresh;
  const _HistoryTab({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, p, _) {
        if (p.isLoading && p.allSessions.isEmpty) {
          return const Center(
              child: CircularProgressIndicator(color: kPrimaryBlue));
        }
        final history =
            p.allSessions.where((s) => !s.isActive).toList();
        if (history.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_rounded, size: 64, color: kTextSecondary),
                SizedBox(height: 12),
                Text('Belum ada riwayat sesi',
                    style:
                        TextStyle(color: kTextSecondary, fontSize: 14)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: kPrimaryBlue,
          backgroundColor: kSurface,
          onRefresh: () async => onRefresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: history.length,
            itemBuilder: (ctx, i) => _HistoryCard(session: history[i]),
          ),
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final SessionModel session;
  const _HistoryCard({required this.session});

  Color _typeColor(String type) {
    switch (type) {
      case 'PS5':
        return kAccentPurple;
      case 'PS3':
        return kNeonPink;
      case 'AndroidTV':
        return kSuccessColor;
      default:
        return kPrimaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM · HH:mm', 'id');
    final isCompleted = session.isCompleted;
    final statusColor = isCompleted ? kSuccessColor : kErrorColor;
    final typeColor = _typeColor(session.consoleType);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderColor, width: 0.5),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: typeColor.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: typeColor.withAlpha(80), width: 0.5),
          ),
          child: Icon(
            session.consoleType == 'AndroidTV'
                ? Icons.tv_outlined
                : Icons.sports_esports,
            color: typeColor,
            size: 22,
          ),
        ),
        title: Text(
          session.consoleName.isNotEmpty
              ? session.consoleName
              : session.consoleType,
          style: const TextStyle(
              color: kTextPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fmt.format(session.startTime),
                style:
                    const TextStyle(color: kTextSecondary, fontSize: 11)),
            if (session.customerName != null)
              Text(session.customerName!,
                  style:
                      const TextStyle(color: kTextSecondary, fontSize: 11)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Rp ${NumberFormat('#,###', 'id').format((session.totalPrice ?? 0).toInt())}',
              style: const TextStyle(
                  color: kTextPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isCompleted ? 'Selesai' : 'Dibatalkan',
                style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}


