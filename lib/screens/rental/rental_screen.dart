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
  Timer? _ticker;
  Timer? _autoRefresh;
  final Set<String> _autoEnded = {}; // session yang sudah auto-ended (tanpa dialog)
  final Set<String> _dialogShown = {}; // session yang sudah muncul dialog auto-end

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
        _checkAutoEnd();
      }
    });
    _autoRefresh = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadData();
    });
  }

  void _checkAutoEnd() {
    try {
      final overview = context.read<ConsoleProvider>().overview;
      final consoleProv = context.read<ConsoleProvider>();
      for (final c in overview) {
        final sess = c.activeSession;
        if (sess == null) continue;
        if (!c.isInUse) continue;
        if (!sess.isOvertime) continue;

        final sid = sess.id;
        final pendingMins = consoleProv.pendingMinutes[sid] ?? 0;

        // Jika ada pembayaran pending → tampilkan dialog (sekali)
        if (pendingMins > 0 && !_dialogShown.contains(sid)) {
          _dialogShown.add(sid);
          _showAutoEndDialog(c, sess, pendingMins);
          return;
        }

        // Tidak ada pending → auto-end langsung (sekali)
        if (pendingMins == 0 && !_autoEnded.contains(sid)) {
          _autoEnded.add(sid);
          context.read<SessionProvider>().end(sid).then((_) async {
            context.read<ConsoleProvider>().clearActiveSessionFromOverview(sid);
            await _loadData();
          });
        }
      }
    } catch (_) {
      // silent — auto-end is best-effort
    }
  }

  void _showAutoEndDialog(ConsoleOverviewModel console, ActiveSessionInfo sess, int pendingMins) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => EndSessionDialog(
        sessionId: sess.id,
        consoleId: console.id,
        consoleName: console.name,
        consoleType: console.consoleType,
        customerName: sess.customerName,
        elapsed: sess.elapsed,
        pendingMinutes: pendingMins,
        pricePerHour: console.pricePerHour,
      ),
    ).then((_) {
      _dialogShown.remove(sess.id);
      context.read<ConsoleProvider>().setPendingMinutes(sess.id, 0);
      context.read<ConsoleProvider>().clearActiveSessionFromOverview(sess.id);
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

  Future<void> _loadData() async {
    await context.read<ConsoleProvider>().loadOverview();
    await context.read<SessionProvider>().loadAll();
    await context.read<SessionProvider>().loadActive(); // refresh active sessions
    // Bersihkan auto-ended yang sudah tidak aktif (pakai data terbaru)
    if (!mounted) return;
    final overview = context.read<ConsoleProvider>().overview;
    final activeIds = overview
        .where((c) => c.activeSession != null)
        .map((c) => c.activeSession!.id)
        .toSet();
    _autoEnded.removeWhere((id) => !activeIds.contains(id));
    _dialogShown.removeWhere((id) => !activeIds.contains(id));
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
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _PanelTab(
            onStartSession: _openStartSession,
            onReload: _loadData,
            onExtendDone: (sessionId, paid, minutes) {
              context.read<ConsoleProvider>().setPendingMinutes(
                sessionId,
                paid ? 0 : (minutes is int ? minutes : 0),
              );
            },
          ),
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
  final void Function(String sessionId, bool paid, int minutes) onExtendDone;

  const _PanelTab({
    required this.onStartSession,
    required this.onReload,
    required this.onExtendDone,
  });

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
          onRefresh: () async => p.loadOverview(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Grid columns berdasarkan lebar layar
              final crossAxisCount = constraints.maxWidth >= 1200
                  ? 5
                  : constraints.maxWidth >= 900
                      ? 4
                      : constraints.maxWidth >= 600
                          ? 3
                          : 2;

              // Build grid rows manually (karena card height bervariasi)
              final rows = <List<ConsoleOverviewModel>>[];
              for (var i = 0; i < sorted.length; i += crossAxisCount) {
                final end = (i + crossAxisCount > sorted.length)
                    ? sorted.length
                    : i + crossAxisCount;
                rows.add(sorted.sublist(i, end));
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SummaryBar(
                        active: active,
                        available: available,
                        maintenance: maintenance),
                    const SizedBox(height: 12),
                    ...rows.map((row) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final c in row)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: _ConsoleControlCard(
                                    console: c,
                                    onStartSession: () => onStartSession(c),
                                    onReload: onReload,
                                    onExtendDone: onExtendDone,
                                  ),
                                ),
                              ),
                            // Fill remaining slots with invisible placeholders
                            for (int i = row.length; i < crossAxisCount; i++)
                              const Expanded(child: SizedBox.shrink()),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
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
        children: [
          Expanded(
            child: _SummaryItem(
                count: active,
                label: 'Aktif',
                color: kSuccessColor,
                icon: Icons.play_circle_outline_rounded),
          ),
          _divider(),
          Expanded(
            child: _SummaryItem(
                count: available,
                label: 'Tersedia',
                color: kPrimaryBlue,
                icon: Icons.circle_outlined),
          ),
          _divider(),
          Expanded(
            child: _SummaryItem(
                count: maintenance,
                label: 'Maintenance',
                color: kWarningColor,
                icon: Icons.build_outlined),
          ),
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
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('$count',
                    style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.1)),
              ),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: kTextSecondary, fontSize: 10)),
            ],
          ),
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
  final void Function(String sessionId, bool paid, int minutes)? onExtendDone;

  const _ConsoleControlCard({
    required this.console,
    required this.onStartSession,
    required this.onReload,
    this.onExtendDone,
  });

  Color get _typeColor {
    switch (console.consoleType) {
      case 'PS5':
        return kAccentPurple;
      case 'PS4':
        return kPrimaryBlue;
      case 'PS3':
        return kNeonPink;
      case 'Switch':
        return kNintendoRed;
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
      case 'Switch':
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
    if (console.isInUse && console.activeSession != null) {
      return _buildActive(context, console.activeSession!);
    }
    if (console.isMaintenance) return _buildMaintenance(context);
    return _buildIdle(context);
  }

  // ── Tersedia / OFF ────────────────────────────────────────────────────────
  Widget _buildIdle(BuildContext context) {
    final fmt = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorderColor, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: icon + type badge + name + OFF
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 8, 6),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: kDeepBlack,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kBorderColor),
                  ),
                  child: Icon(
                    console.isAndroidTV
                        ? Icons.tv_outlined
                        : Icons.sports_esports_outlined,
                    color: kTextSecondary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: _typeColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: _typeColor.withAlpha(60)),
                            ),
                            child: Text(console.consoleType,
                                style: TextStyle(
                                    color: _typeColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(console.name,
                                style: const TextStyle(
                                    color: kTextPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('${fmt.format(console.pricePerHour)}/jam',
                          style: const TextStyle(
                              color: kTextSecondary, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Status row (compact, IP di baris sendiri)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
            child: Row(
              children: [
                const Icon(Icons.lock_outline,
                    size: 11, color: kTextSecondary),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    console.isAndroidTV
                        ? 'TV Terkunci'
                        : 'Siap Disewa',
                    style: const TextStyle(
                        color: kTextSecondary, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (console.ipAddress != null &&
              console.ipAddress!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
              child: Row(
                children: [
                  const Icon(Icons.router_outlined,
                      size: 11, color: kTextSecondary),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(console.ipAddress!,
                        style: const TextStyle(
                            color: kTextSecondary, fontSize: 10),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          // TV Control + Mulai Sesi
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                // TV Power Switch
                Consumer<ConsoleProvider>(
                  builder: (_, cp, __) {
                    final loading = cp.tvActionTarget == console.id;
                    // Baca screenStatus terbaru dari provider (bukan dari stale console)
                    final latest = cp.overview
                        .where((c) => c.id == console.id)
                        .firstOrNull;
                    final isOn = latest?.screenStatus != 'off';
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (loading)
                          const Padding(
                            padding: EdgeInsets.all(8),
                            child: SizedBox(
                                width: 14, height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: kTextSecondary)),
                          )
                        else ...[
                          const Icon(Icons.tv_rounded, size: 14, color: kTextSecondary),
                          const SizedBox(width: 4),
                          Switch(
                            value: isOn,
                            onChanged: (_) async {
                              final ok = isOn
                                  ? await cp.sleep(console.id)
                                  : await cp.wake(console.id);
                              if (ok) onReload();
                            },
                            activeColor: kSuccessColor,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(width: 6),
                // Mulai Sesi
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onStartSession,
                      borderRadius: BorderRadius.circular(8),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: kGradientGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow_rounded, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Mulai Sesi',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
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

  // ── Aktif / IN USE ────────────────────────────────────────────────────────
  Widget _buildActive(BuildContext context, ActiveSessionInfo sess) {
    final elapsed = sess.elapsed;
    final remaining = sess.remaining;
    final isOvertime = sess.isOvertime;
    final progress = sess.progress.clamp(0.0, 1.0);
    final cost = elapsed.inSeconds / 3600.0 * console.pricePerHour;
    final fmt =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOvertime
              ? kWarningColor.withAlpha(150)
              : _typeColor.withAlpha(80),
          width: 0.8,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header compact
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_typeColor.withAlpha(30), Colors.transparent],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              border: const Border(bottom: BorderSide(color: kBorderColor, width: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: _typeGrad,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(console.consoleType,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(console.name,
                      style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: kSuccessColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kSuccessColor.withAlpha(80), width: 0.5),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 5, color: kSuccessColor),
                      SizedBox(width: 3),
                      Text('AKTIF', style: TextStyle(color: kSuccessColor, fontSize: 9, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Timer + progress
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kDeepBlack,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kBorderColor, width: 0.5),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_fmtDur(elapsed),
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      if (remaining != null)
                        Text(_fmtDur(remaining),
                            style: TextStyle(color: isOvertime ? kWarningColor : kSuccessColor, fontSize: 15, fontWeight: FontWeight.bold))
                      else
                        const Text('Open', style: TextStyle(color: kTextSecondary, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: kBorderColor,
                      valueColor: AlwaysStoppedAnimation(isOvertime ? kWarningColor : kSuccessColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${sess.bookedDurationMinutes ~/ 60}h',
                          style: const TextStyle(color: kTextSecondary, fontSize: 10)),
                      Text(fmt.format(cost.toInt()),
                          style: const TextStyle(color: kTextSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Customer + start time
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 11, color: kTextSecondary),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(sess.customerName ?? 'Umum',
                      style: const TextStyle(color: kTextSecondary, fontSize: 10),
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.access_time_rounded, size: 11, color: kTextSecondary),
                const SizedBox(width: 3),
                Text(DateFormat('HH:mm').format(sess.startTime),
                    style: const TextStyle(color: kTextSecondary, fontSize: 10)),
              ],
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _cancel(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: kErrorColor.withAlpha(120)),
                      foregroundColor: kErrorColor,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    child: const Text('Batal', style: TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _extendSession(context, sess, console.name),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: kAccentPurple.withAlpha(120)),
                      foregroundColor: kAccentPurple,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    child: const Text('Tambah', style: TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 2,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _end(context, elapsed),
                      borderRadius: BorderRadius.circular(8),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: kGradientBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.stop_circle_rounded, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Akhiri', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
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
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kWarningColor.withAlpha(80), width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: kWarningColor.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.build_outlined,
                  color: kWarningColor, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: _typeColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(console.consoleType,
                            style: TextStyle(color: _typeColor, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(console.name,
                            style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text('Dalam perawatan',
                      style: TextStyle(color: kTextSecondary, fontSize: 10)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: kWarningColor.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kWarningColor.withAlpha(80), width: 0.5),
              ),
              child: const Text('MAINT',
                  style: TextStyle(color: kWarningColor, fontSize: 8, fontWeight: FontWeight.w600)),
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
      // Optimistic update: segera hapus sesi aktif dari overview
      context.read<ConsoleProvider>().clearActiveSessionFromOverview(sess.id);
      context.read<ConsoleProvider>().setPendingMinutes(sess.id, 0);
      onReload();
    }
  }

  Future<void> _extendSession(BuildContext context, ActiveSessionInfo sess, String consoleName) async {
    final hoursCtrl = TextEditingController(text: '1');
    final minutesCtrl = TextEditingController(text: '0');
    final cashCtrl = TextEditingController();
    bool isPaid = true; // default: bayar sekarang

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Tambah Waktu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tambah durasi untuk $consoleName',
                  style: const TextStyle(color: kTextSecondary, fontSize: 12)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: hoursCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Jam', hintText: '0'),
                    onChanged: (_) => setSt(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: minutesCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Menit', hintText: '0'),
                    onChanged: (_) => setSt(() {}),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              // ── Bayar / Belum Bayar ──
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setSt(() => isPaid = true),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isPaid ? kSuccessColor.withAlpha(25) : kCardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isPaid ? kSuccessColor : kBorderColor,
                            width: isPaid ? 1.5 : 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payments_outlined,
                                size: 16, color: isPaid ? kSuccessColor : kTextSecondary),
                            const SizedBox(width: 6),
                            Text('Bayar',
                                style: TextStyle(
                                    color: isPaid ? kSuccessColor : kTextSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => setSt(() => isPaid = false),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !isPaid ? kWarningColor.withAlpha(25) : kCardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: !isPaid ? kWarningColor : kBorderColor,
                            width: !isPaid ? 1.5 : 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 16, color: !isPaid ? kWarningColor : kTextSecondary),
                            const SizedBox(width: 6),
                            Text('Belum Bayar',
                                style: TextStyle(
                                    color: !isPaid ? kWarningColor : kTextSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ── Cash field — only if Bayar ──
              if (isPaid)
                TextField(
                  controller: cashCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Uang Diterima (Rp)',
                    prefixIcon: Icon(Icons.payments_outlined, size: 18),
                    hintText: '0',
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kWarningColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kWarningColor.withAlpha(40)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.info_outline, size: 14, color: kWarningColor),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pembayaran akan ditagih setelah sesi selesai. Notifikasi akan muncul di dashboard.',
                        style: TextStyle(color: kWarningColor, fontSize: 11),
                      ),
                    ),
                  ]),
                ),
              const SizedBox(height: 8),
              Text(
                'Minimal tambahan 1 menit.',
                style: TextStyle(color: kTextSecondary, fontSize: 10, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final h = int.tryParse(hoursCtrl.text) ?? 0;
                final m = int.tryParse(minutesCtrl.text) ?? 0;
                final totalMin = h * 60 + m;
                if (totalMin < 1) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('Minimal tambahan 1 menit'),
                    backgroundColor: kErrorColor,
                  ));
                  return;
                }
                if (isPaid) {
                  final cash = double.tryParse(cashCtrl.text) ?? 0;
                  if (cash <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('Masukkan jumlah uang'),
                      backgroundColor: kErrorColor,
                    ));
                    return;
                  }
                  Navigator.pop(ctx, {'minutes': totalMin, 'cash': cash, 'paid': true});
                } else {
                  Navigator.pop(ctx, {'minutes': totalMin, 'cash': 0.0, 'paid': false});
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: kAccentPurple),
              child: const Text('Tambah Waktu'),
            ),
          ],
        ),
      ),
    );

    if (result == null || !context.mounted) return;

    final additionalMin = result['minutes'] as int;
    final cash = result['cash'] as double;
    final paid = result['paid'] as bool;

    final extended = await context.read<SessionProvider>().extend(
      id: sess.id,
      additionalMinutes: additionalMin,
      payNow: paid,
      cashReceived: cash,
    );

    if (context.mounted) {
      if (extended != null) {
        onReload();
        // Track pending payment dengan menit
        onExtendDone?.call(sess.id, paid, additionalMin);
        final msg = paid
            ? 'Waktu ditambah ${additionalMin ~/ 60}j ${additionalMin % 60}m — Dibayar'
            : 'Waktu ditambah ${additionalMin ~/ 60}j ${additionalMin % 60}m — Belum dibayar';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: paid ? kSuccessColor : kWarningColor,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.read<SessionProvider>().error ?? 'Gagal menambah waktu'),
          backgroundColor: kErrorColor,
        ));
      }
    }
  }

  void _end(BuildContext context, Duration elapsed) {
    final sess = console.activeSession;
    if (sess == null) return;
    final pendingMins = context.read<ConsoleProvider>().pendingMinutes[sess.id] ?? 0;
    showDialog(
      context: context,
      builder: (_) => EndSessionDialog(
        sessionId: sess.id,
        consoleId: console.id,
        consoleName: console.name,
        consoleType: console.consoleType,
        customerName: sess.customerName,
        elapsed: elapsed,
        pendingMinutes: pendingMins,
        pricePerHour: console.pricePerHour,
      ),
    ).then((_) {
      // Optimistic update: segera hapus sesi aktif dari overview
      context.read<ConsoleProvider>().clearActiveSessionFromOverview(sess.id);
      context.read<ConsoleProvider>().setPendingMinutes(sess.id, 0);
      onReload();
    });
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


