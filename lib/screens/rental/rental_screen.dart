import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/session_model.dart';
import '../../providers/session_provider.dart';
import 'start_session_dialog.dart';
import 'end_session_dialog.dart';

class RentalScreen extends StatefulWidget {
  const RentalScreen({super.key});
  @override
  State<RentalScreen> createState() => _RentalScreenState();
}

class _RentalScreenState extends State<RentalScreen> with TickerProviderStateMixin {
  late TabController _tabCtrl;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().loadActive();
      context.read<SessionProvider>().loadAll();
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDeepBlack,
      appBar: _buildAppBar(),
      floatingActionButton: _GradientFab(
        onPressed: () => showDialog(context: context, builder: (_) => const StartSessionDialog()),
        label: 'Mulai Sesi',
        icon: Icons.add_rounded,
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _ActiveTab(),
          _HistoryTab(onRefresh: () => context.read<SessionProvider>().loadAll()),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0A0A0F),
      title: const Text('Rental PS'),
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
                  Icon(Icons.play_circle_outline_rounded, size: 16),
                  SizedBox(width: 6),
                  Text('Aktif'),
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

// ─── Active tab ──────────────────────────────────────────────────────────────
class _ActiveTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, p, _) {
        if (p.isLoading) {
          return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
        }
        if (p.activeSessions.isEmpty) {
          return _EmptySession(onRefresh: p.loadActive);
        }
        return RefreshIndicator(
          color: kPrimaryBlue,
          backgroundColor: kSurface,
          onRefresh: p.loadActive,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: p.activeSessions.length,
            itemBuilder: (ctx, i) => _ActiveSessionCard(session: p.activeSessions[i]),
          ),
        );
      },
    );
  }
}

class _EmptySession extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const _EmptySession({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
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
            child: const Icon(Icons.sports_esports_outlined, size: 40, color: kTextSecondary),
          ),
          const SizedBox(height: 16),
          const Text('Tidak ada sesi aktif',
              style: TextStyle(color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          const Text('Tekan tombol + untuk memulai sesi rental',
              style: TextStyle(color: kTextSecondary, fontSize: 13)),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

// ─── Active session card ─────────────────────────────────────────────────────
class _ActiveSessionCard extends StatefulWidget {
  final SessionModel session;
  const _ActiveSessionCard({required this.session});

  @override
  State<_ActiveSessionCard> createState() => _ActiveSessionCardState();
}

class _ActiveSessionCardState extends State<_ActiveSessionCard> {
  late Timer _timer;
  late Duration _elapsed;

  @override
  void initState() {
    super.initState();
    _elapsed = widget.session.elapsed;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed = widget.session.elapsed);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _fmt(Duration d) =>
      '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  double get _cost => (_elapsed.inSeconds / 3600.0) * widget.session.pricePerHour;

  bool get _isPs5 => widget.session.consoleType.contains('5');
  Color get _typeColor => _isPs5 ? kAccentPurple : kPrimaryBlue;
  LinearGradient get _typeGrad => _isPs5 ? kGradientPurple : kGradientBlue;

  void _end() => showDialog(
        context: context,
        builder: (_) => EndSessionDialog(session: widget.session, elapsed: _elapsed, estimatedCost: _cost),
      );

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Batalkan Sesi'),
        content: Text('Batalkan sesi ${widget.session.consoleName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Tidak')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: kErrorColor),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<SessionProvider>().cancel(widget.session.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('HH:mm');
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderColor, width: 0.5),
        boxShadow: [BoxShadow(color: _typeColor.withAlpha(15), blurRadius: 20)],
      ),
      child: Column(
        children: [
          // ── Header strip ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_typeColor.withAlpha(25), Colors.transparent],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: kBorderColor, width: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: _typeGrad,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: _typeColor.withAlpha(100), blurRadius: 8)],
                  ),
                  child: Text(widget.session.consoleType,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.session.consoleName.isNotEmpty ? widget.session.consoleName : 'Konsol',
                    style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kSuccessColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kSuccessColor.withAlpha(80), width: 0.5),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, size: 6, color: kSuccessColor),
                      SizedBox(width: 4),
                      Text('AKTIF', style: TextStyle(color: kSuccessColor, fontSize: 10, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Timer ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kDeepBlack,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorderColor, width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DURASI BERMAIN',
                          style: TextStyle(color: kTextSecondary, fontSize: 10, letterSpacing: 0.8)),
                      const SizedBox(height: 4),
                      ShaderMask(
                        shaderCallback: (b) => kGradientBlue.createShader(b),
                        child: Text(_fmt(_elapsed),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins', letterSpacing: 2)),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('ESTIMASI BIAYA',
                          style: TextStyle(color: kTextSecondary, fontSize: 10, letterSpacing: 0.8)),
                      const SizedBox(height: 4),
                      ShaderMask(
                        shaderCallback: (b) => kGradientAmber.createShader(b),
                        child: Text(
                          'Rp ${NumberFormat('#,###', 'id').format(_cost.toInt())}',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // ── Info row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 13, color: kTextSecondary),
                const SizedBox(width: 4),
                Text(widget.session.customerName ?? 'Umum (Non-Member)',
                    style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                const Spacer(),
                const Icon(Icons.access_time_rounded, size: 13, color: kTextSecondary),
                const SizedBox(width: 4),
                Text('Mulai ${fmt.format(widget.session.startTime)}',
                    style: const TextStyle(color: kTextSecondary, fontSize: 12)),
              ],
            ),
          ),
          // ── Actions ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _cancel,
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
                  child: _GradientButton(
                    onPressed: _end,
                    label: 'Selesai & Bayar',
                    icon: Icons.stop_circle_rounded,
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

// ─── History tab ─────────────────────────────────────────────────────────────
class _HistoryTab extends StatelessWidget {
  final VoidCallback onRefresh;
  const _HistoryTab({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, p, _) {
        if (p.isLoading) {
          return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
        }
        final history = p.allSessions.where((s) => !s.isActive).toList();
        if (history.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_rounded, size: 64, color: kTextSecondary),
                SizedBox(height: 12),
                Text('Belum ada riwayat sesi', style: TextStyle(color: kTextSecondary, fontSize: 14)),
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

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM · HH:mm', 'id');
    final isCompleted = session.isCompleted;
    final statusColor = isCompleted ? kSuccessColor : kErrorColor;
    final isPs5 = session.consoleType.contains('5');
    final typeColor = isPs5 ? kAccentPurple : kPrimaryBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderColor, width: 0.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: typeColor.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: typeColor.withAlpha(80), width: 0.5),
          ),
          child: Icon(Icons.sports_esports, color: typeColor, size: 22),
        ),
        title: Text(
          session.consoleName.isNotEmpty ? session.consoleName : session.consoleType,
          style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fmt.format(session.startTime),
                style: const TextStyle(color: kTextSecondary, fontSize: 11)),
            if (session.customerName != null)
              Text(session.customerName!,
                  style: const TextStyle(color: kTextSecondary, fontSize: 11)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Rp ${NumberFormat('#,###', 'id').format((session.totalPrice ?? 0).toInt())}',
              style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isCompleted ? 'Selesai' : 'Dibatalkan',
                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

// ─── Shared button widgets ───────────────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  const _GradientButton({required this.onPressed, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            gradient: kGradientBlue,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: kPrimaryBlue.withAlpha(80), blurRadius: 12)],
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientFab extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  const _GradientFab({required this.onPressed, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: kGradientBrand,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: kPrimaryBlue.withAlpha(100), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
