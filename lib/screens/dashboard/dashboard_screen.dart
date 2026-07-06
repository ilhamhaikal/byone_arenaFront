import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/session_model.dart';
import '../../models/dashboard_summary_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/console_provider.dart';
import '../../providers/dashboard_summary_provider.dart';
import '../../providers/session_provider.dart';
import '../membership/membership_screen.dart';
import '../rental/rental_screen.dart';
import '../discount/discount_screen.dart';
import '../voucher/voucher_screen.dart';
import '../menu/menu_screen.dart';
import '../food_order/food_order_screen.dart';
import '../console/console_screen.dart';
import '../notification/notification_screen.dart';
import '../report/report_screen.dart';

// ─── Dashboard shell ────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  final VoidCallback? onSwitchToRoleSelect;
  const DashboardScreen({super.key, this.onSwitchToRoleSelect});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().loadActive();
    });
  }

  static const _navItems = [
    (Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
    (Icons.sports_esports_outlined, Icons.sports_esports, 'Rental'),
    (Icons.videogame_asset_outlined, Icons.videogame_asset_rounded, 'Konsol'),
    (Icons.people_outline_rounded, Icons.people_rounded, 'Member'),
    (Icons.local_offer_outlined, Icons.local_offer_rounded, 'Diskon'),
    (Icons.confirmation_number_outlined, Icons.confirmation_number, 'Voucher'),
    (Icons.restaurant_menu_outlined, Icons.restaurant_menu_rounded, 'Menu'),
    (Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Pesanan'),
    (Icons.campaign_outlined, Icons.campaign_rounded, 'Notif'),
    (Icons.assessment_outlined, Icons.assessment_rounded, 'Laporan'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeTab(onSwitchToRoleSelect: widget.onSwitchToRoleSelect),
      const RentalScreen(),
      const ConsoleScreen(),
      const MembershipScreen(),
      const DiscountScreen(),
      const VoucherScreen(),
      const MenuScreen(),
      const FoodOrderScreen(),
      const NotificationScreen(),
      const ReportScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final List<(IconData, IconData, String)> items;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0F),
        border: Border(top: BorderSide(color: kBorderColor, width: 0.5)),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive sizing: total lebar dibagi 8 item
            final isNarrow = constraints.maxWidth < 600;
            final hPad = isNarrow ? 4.0 : 10.0;
            final iconSize = isNarrow ? 18.0 : 22.0;
            final fontSize = isNarrow ? 8.0 : 10.0;
            final vPad = isNarrow ? 4.0 : 7.0;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad > 6 ? 4.0 : 2.0, vertical: 4),
              child: Row(
                children: List.generate(items.length, (i) {
                  final selected = currentIndex == i;
                  final (outIcon, selIcon, label) = items[i];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(i),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
                        margin: EdgeInsets.symmetric(horizontal: isNarrow ? 1.0 : 2.0),
                        decoration: selected
                            ? BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [kPrimaryBlue.withAlpha(40), kAccentPurple.withAlpha(30)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: kPrimaryBlue.withAlpha(70), width: 0.5),
                              )
                            : null,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(selected ? selIcon : outIcon,
                                color: selected ? kPrimaryBlue : kTextSecondary, size: iconSize),
                            SizedBox(height: isNarrow ? 1 : 2),
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: selected ? kPrimaryBlue : kTextSecondary,
                                fontSize: fontSize,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Home tab ───────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final VoidCallback? onSwitchToRoleSelect;
  const _HomeTab({this.onSwitchToRoleSelect});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDeepBlack,
      body: Consumer2<AuthProvider, SessionProvider>(
        builder: (context, auth, session, _) {
          final console = context.watch<ConsoleProvider>();
          final dashSummary = context.watch<DashboardSummaryProvider>().summary;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (console.overview.isEmpty && !console.isLoading) {
              console.loadOverview();
            }
            context.read<DashboardSummaryProvider>().loadSummary();
          });

          return RefreshIndicator(
            color: kPrimaryBlue,
            backgroundColor: kSurface,
            onRefresh: () async {
              await Future.wait([
                session.loadActive(),
                console.loadOverview(),
                context.read<DashboardSummaryProvider>().loadSummary(),
              ]);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── App bar ──
                SliverAppBar(
                  expandedHeight: 100,
                  pinned: true,
                  backgroundColor: const Color(0xFF0A0A0F),
                  flexibleSpace: FlexibleSpaceBar(
                    background: _DashboardHeader(user: auth.user?.fullName ?? 'Admin'),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: kTextSecondary),
                      onPressed: () {
                        session.loadActive();
                        console.loadOverview();
                        context.read<DashboardSummaryProvider>().loadSummary();
                      },
                    ),
                    _LogoutButton(onSwitchToRoleSelect: onSwitchToRoleSelect),
                    const SizedBox(width: 4),
                  ],
                ),
                // ── Stats ──
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _StatsSection(session: session, console: console, summary: dashSummary),
                  ),
                ),
                // ── Active rentals header ──
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: 'Sesi Aktif',
                      count: session.activeSessions.length,
                    ),
                  ),
                ),
                // ── Rental list ──
                session.isLoading
                    ? const SliverFillRemaining(
                        child: Center(
                            child: CircularProgressIndicator(color: kPrimaryBlue)),
                      )
                    : session.activeSessions.isEmpty
                        ? SliverFillRemaining(child: _EmptyState(
                            icon: Icons.sports_esports_outlined,
                            message: 'Tidak ada sesi aktif',
                            sub: 'Buka tab Rental untuk memulai sesi baru',
                          ))
                        : SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) => _DashSessionCard(session: session.activeSessions[i]),
                                childCount: session.activeSessions.length,
                              ),
                            ),
                          ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback? onSwitchToRoleSelect;
  const _LogoutButton({this.onSwitchToRoleSelect});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: kTextSecondary),
      color: kCardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (val) async {
        if (val == 'logout') {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Konfirmasi Logout'),
              content: const Text('Yakin ingin keluar dari aplikasi?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batal')),
                ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(backgroundColor: kErrorColor),
                    child: const Text('Logout')),
              ],
            ),
          );
          if (confirm == true && context.mounted) {
            await context.read<AuthProvider>().logout();
          }
        } else if (val == 'switch') {
          onSwitchToRoleSelect?.call();
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'switch',
          child: Row(
            children: [
              Icon(Icons.swap_horiz_rounded, color: kTextSecondary, size: 18),
              SizedBox(width: 8),
              Text('Ganti Mode (Client)'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, color: kErrorColor, size: 18),
              SizedBox(width: 8),
              Text('Logout', style: TextStyle(color: kErrorColor)),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String user;
  const _DashboardHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'Selamat Pagi' : now.hour < 17 ? 'Selamat Siang' : 'Selamat Malam';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A0A1F), Color(0xFF0A0A0F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(bottom: BorderSide(color: kBorderColor, width: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 36, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$greeting, ',
                    style: const TextStyle(color: kTextSecondary, fontSize: 12),
                  ),
                  TextSpan(
                    text: user,
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimaryBlue.withAlpha(30), kAccentPurple.withAlpha(20)],
              ),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: kBorderColor),
            ),
            child: Text(
              DateFormat('EEE, d MMM', 'id').format(now),
              style: const TextStyle(color: kTextSecondary, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final SessionProvider session;
  final ConsoleProvider console;
  final DashboardSummaryModel? summary;
  const _StatsSection(
      {required this.session, required this.console, this.summary});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'id');

    // Value helpers — pakai summary jika sudah tersedia, fallback ke provider
    final activeCount = summary?.activeSessions ?? session.activeCount;
    final totalConsoles = summary?.totalConsoles ?? console.overview.length;
    final availableConsoles =
        summary?.availableConsoles ?? console.overview.where((c) => c.isAvailable).length;
    final revenue = summary?.totalRevenue ?? 0;
    final voucherCount = summary?.voucherUsageCount ?? 0;
    final transactions = summary?.totalTransactions ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1200
            ? 6
            : constraints.maxWidth >= 900
                ? 4
                : constraints.maxWidth >= 600
                    ? 3
                    : 2;
        final childAspect = constraints.maxWidth >= 600 ? 1.8 : 1.9;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: childAspect,
          children: [
            _StatCard(
              label: 'Sesi Aktif',
              value: '$activeCount',
              icon: Icons.play_circle_rounded,
              gradient: kGradientBlue,
              glowColor: kPrimaryBlue,
            ),
            _StatCard(
              label: 'Pendapatan',
              value: 'Rp ${fmt.format(revenue.toInt())}',
              icon: Icons.monetization_on_rounded,
              gradient: kGradientGreen,
              glowColor: kSuccessColor,
            ),
            _StatCard(
              label: 'Total Konsol',
              value: '$totalConsoles',
              icon: Icons.sports_esports_rounded,
              gradient: kGradientPurple,
              glowColor: kAccentPurple,
            ),
            _StatCard(
              label: 'Tersedia',
              value: '$availableConsoles',
              icon: Icons.check_circle_outline_rounded,
              gradient: kGradientGreen,
              glowColor: kSuccessColor,
            ),
            _StatCard(
              label: 'Voucher Dipakai',
              value: '$voucherCount',
              icon: Icons.confirmation_number_rounded,
              gradient: kGradientPink,
              glowColor: kNeonPink,
            ),
            _StatCard(
              label: 'Transaksi',
              value: '$transactions',
              icon: Icons.receipt_long_rounded,
              gradient: kGradientAmber,
              glowColor: kWarningColor,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final LinearGradient gradient;
  final Color glowColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Shared widgets ─────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(
                color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            gradient: kGradientBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count',
              style: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? sub;
  const _EmptyState({required this.icon, required this.message, this.sub});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorderColor),
              ),
              child: Icon(icon, size: 24, color: kTextSecondary),
            ),
            const SizedBox(height: 10),
            Text(message,
                style: const TextStyle(
                    color: kTextPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
            if (sub != null) ...[
              const SizedBox(height: 4),
              Text(sub!, style: const TextStyle(color: kTextSecondary, fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Dashboard session card (compact) ─────────────────────────────────────
class _DashSessionCard extends StatelessWidget {
  final SessionModel session;
  const _DashSessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final elapsed = session.elapsed;
    final h = elapsed.inHours.toString().padLeft(2, '0');
    final m = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final isPs5 = session.consoleType.contains('5');
    final typeColor = isPs5 ? kAccentPurple : kPrimaryBlue;
    final typeGrad = isPs5 ? kGradientPurple : kGradientBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderColor, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Console type badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: typeGrad,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: typeColor.withAlpha(80), blurRadius: 8)],
              ),
              child: Center(
                child: Icon(
                  Icons.sports_esports,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.consoleName.isEmpty ? session.consoleType : session.consoleName,
                      style: TextStyle(
                          color: typeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    session.customerName ?? 'Umum (Tamu)',
                    style: const TextStyle(color: kTextSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Timer
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: kSuccessColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$h:$m',
                      style: const TextStyle(
                          color: kSuccessColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Poppins'),
                    ),
                  ],
                ),
                const Text('bermain', style: TextStyle(color: kTextSecondary, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
