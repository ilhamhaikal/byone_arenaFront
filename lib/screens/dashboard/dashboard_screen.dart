import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/brand_config.dart';
import '../../models/session_model.dart';
import '../../models/dashboard_summary_model.dart';
import '../../models/payment_model.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/premium_background.dart';
import '../../widgets/dashboard_stat_card.dart';
import '../../widgets/activity_timeline.dart';
import '../../utils/activity_helper.dart';
import '../../widgets/premium_revenue_chart.dart';
import '../../providers/console_provider.dart';
import '../../providers/dashboard_summary_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/activity_provider.dart';
import '../membership/membership_screen.dart';
import '../rental/rental_screen.dart';
import '../discount/discount_screen.dart';
import '../voucher/voucher_screen.dart';
import '../menu/menu_screen.dart';
import '../food_order/food_order_screen.dart';
import '../console/console_screen.dart';
import '../notification/notification_screen.dart';
import '../report/report_screen.dart';
import '../booking/booking_screen.dart';
import '../daily_rental/daily_rental_screen.dart';
import '../tv_log/tv_log_screen.dart';

// ─── Dashboard shell ────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  final VoidCallback? onSwitchToRoleSelect;
  const DashboardScreen({super.key, this.onSwitchToRoleSelect});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _dashPollTimer;

  void setPage(int index) {
    if (index >= 0 && index < _navItems.length) {
      setState(() => _currentIndex = index);
      _scaffoldKey.currentState?.closeDrawer();
    }
  }

  void _refreshDashboardData() {
    if (!mounted) return;
    context.read<SessionProvider>().loadActive();
    context.read<ConsoleProvider>().loadOverview();
    context.read<DashboardSummaryProvider>().loadSummary();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final session = context.read<SessionProvider>();
      final console = context.read<ConsoleProvider>();
      final dashSummary = context.read<DashboardSummaryProvider>();
      session.loadActive();
      if (console.overview.isEmpty && !console.isLoading) {
        console.loadOverview();
      }
      dashSummary.loadSummary();
      // Mulai polling pembayaran pending untuk banner persistent
      context.read<PaymentProvider>().startPendingPolling(interval: 10);
      // Mulai polling aktivitas terbaru
      context.read<ActivityProvider>().startPolling(interval: 30);
      // Mulai polling data dashboard (sesi aktif, status konsol, ringkasan)
      // supaya tampilan selalu up-to-date tanpa perlu ditarik (pull-to-refresh)
      // atau ditekan tombol refresh manual.
      _dashPollTimer?.cancel();
      _dashPollTimer =
          Timer.periodic(const Duration(seconds: 15), (_) => _refreshDashboardData());
    });
  }

  @override
  void dispose() {
    _dashPollTimer?.cancel();
    super.dispose();
  }

  static const _navItems = [
    (Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
    (Icons.sports_esports_outlined, Icons.sports_esports, 'Rental'),
    (Icons.videogame_asset_outlined, Icons.videogame_asset_rounded, 'Konsol'),
    (Icons.tv_outlined, Icons.tv_rounded, 'Log TV'),
    (Icons.people_outline_rounded, Icons.people_rounded, 'Member'),
    (Icons.local_offer_outlined, Icons.local_offer_rounded, 'Diskon'),
    (Icons.confirmation_number_outlined, Icons.confirmation_number, 'Voucher'),
    (Icons.restaurant_menu_outlined, Icons.restaurant_menu_rounded, 'Menu'),
    (Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Pesanan'),
    (Icons.campaign_outlined, Icons.campaign_rounded, 'Notif'),
    (Icons.assessment_outlined, Icons.assessment_rounded, 'Laporan'),
    (Icons.event_available_outlined, Icons.event_available_rounded, 'Booking'),
    (Icons.home_outlined, Icons.home_rounded, 'Rental Harian'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeTab(onSwitchToRoleSelect: widget.onSwitchToRoleSelect),
      const RentalScreen(),
      const ConsoleScreen(),
      const TvLogScreen(),
      const MembershipScreen(),
      const DiscountScreen(),
      const VoucherScreen(),
      const MenuScreen(),
      const FoodOrderScreen(),
      const NotificationScreen(),
      const ReportScreen(),
      const BookingScreen(),
      const DailyRentalScreen(),
    ];
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: const Color(0xFF0A0A0F),
        width: 240,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _SidebarHeader(),
              const Divider(color: kBorderColor, height: 1),
              // Menu items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    for (var i = 0; i < _navItems.length; i++)
                      _SideNavItem(
                        inactiveIcon: _navItems[i].$1,
                        activeIcon: _navItems[i].$2,
                        label: _navItems[i].$3,
                        isActive: i == _currentIndex,
                        onTap: () {
                          setState(() => _currentIndex = i);
                          Navigator.pop(context); // tutup drawer
                        },
                      ),
                  ],
                ),
              ),
              // ── LEVEL UP promo card ──
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: _SidebarPromoCard(),
              ),
              const Divider(color: kBorderColor, height: 1),
              _LogoutButton(onSwitchToRoleSelect: widget.onSwitchToRoleSelect),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: pages),
          // Hamburger button — only when drawer is closed, di kiri-atas
          Positioned(
            left: 0,
            top: MediaQuery.of(context).padding.top + 4,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                child: Container(
                  width: 36,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xCC0A0A0F),
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                    border: Border.all(color: kBorderColor.withAlpha(80)),
                  ),
                  child: const Icon(Icons.menu_rounded, color: kPrimaryBlue, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sidebar header ──────────────────────────────────────────────────────────
class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(BrandConfig.logoAsset, width: 36, height: 36),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MENU',
                        style: TextStyle(color: kTextSecondary, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700)),
                    Text(BrandConfig.appName,
                        style: TextStyle(color: kPrimaryBlue.withAlpha(180), fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sidebar menu item ───────────────────────────────────────────────────────
class _SideNavItem extends StatelessWidget {
  final IconData inactiveIcon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SideNavItem({
    required this.inactiveIcon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: isActive
                ? BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kPrimaryBlue.withAlpha(50),
                        kAccentPurple.withAlpha(35),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: kPrimaryBlue.withAlpha(130),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryBlue.withAlpha(30),
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color: kAccentPurple.withAlpha(15),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  )
                : null,
            child: Row(
              children: [
                // Left accent bar when active
                if (isActive)
                  Container(
                    width: 3,
                    height: 24,
                    margin: const EdgeInsets.only(right: 11),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kPrimaryBlue, kAccentPurple],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryBlue.withAlpha(100),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                Icon(
                  isActive ? activeIcon : inactiveIcon,
                  color: isActive ? kPrimaryBlue : kTextSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive ? Colors.white : kTextSecondary,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                // Active indicator dot
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kPrimaryBlue,
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryBlue.withAlpha(150),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Sidebar Promo Card — LEVEL UP YOUR GAME
// ═════════════════════════════════════════════════════════════════
class _SidebarPromoCard extends StatelessWidget {
  const _SidebarPromoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kAccentPurple.withAlpha(30),
            kPrimaryBlue.withAlpha(15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kAccentPurple.withAlpha(50), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: kAccentPurple.withAlpha(20),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -10, top: -10,
            child: Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kAccentPurple.withAlpha(30), width: 1),
              ),
            ),
          ),
          Positioned(
            right: 5, top: 5,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kNeonPink.withAlpha(40), width: 1),
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Neon controller icon
              Center(
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [kAccentPurple, kNeonPink],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kAccentPurple.withAlpha(70),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.sports_esports, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'LEVEL UP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [kPrimaryBlue, kAccentPurple, kNeonPink],
                ).createShader(bounds),
                child: const Text(
                  'YOUR GAME',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Play Without Limits',
                style: TextStyle(
                  color: kTextSecondary,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Home tab ───────────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  final VoidCallback? onSwitchToRoleSelect;
  const _HomeTab({this.onSwitchToRoleSelect});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const RepaintBoundary(child: PremiumBackground()),
          Consumer2<AuthProvider, SessionProvider>(
            builder: (context, auth, session, _) {
              final console = context.watch<ConsoleProvider>();
              final dashSummary = context.watch<DashboardSummaryProvider>().summary;
              final paymentProv = context.watch<PaymentProvider>();
              final activityProv = context.watch<ActivityProvider>();
              final fmt = NumberFormat('#,###', 'id');
              final activities = activityProv.activities
                  .map((a) => activityItemToEvent(a))
                  .toList();
              final w = MediaQuery.of(context).size.width;
              final isWide = w >= 1200;
              final isMedium = w >= 800;

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
                    // ── AppBar actions ──
                    SliverAppBar(
                      pinned: true, // pinned — hindari animasi float yang berat saat resize
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: kTextSecondary),
                          onPressed: () {
                            session.loadActive();
                            console.loadOverview();
                            context.read<DashboardSummaryProvider>().loadSummary();
                          },
                        ),
                        _LogoutButton(onSwitchToRoleSelect: widget.onSwitchToRoleSelect),
                        const SizedBox(width: 4),
                      ],
                    ),
                    // ── Hero header ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _DashboardHeader(user: auth.user?.fullName ?? 'Admin'),
                      ),
                    ),
                    // ── Pending banner ──
                    if (paymentProv.hasPendingPayments)
                      SliverToBoxAdapter(
                        child: _PendingPaymentsBanner(
                          count: paymentProv.pendingCount,
                          payments: paymentProv.pendingPayments,
                        ),
                      ),
                    // ── Stats grid ──
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      sliver: SliverToBoxAdapter(
                        child: RepaintBoundary(
                          child: _PremiumStatsGrid(
                            session: session,
                            console: console,
                            summary: dashSummary,
                            fmt: fmt,
                          ),
                        ),
                      ),
                    ),
                    // ── Main content: 3 columns ──
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      sliver: SliverToBoxAdapter(
                        child: isWide
                            ? _buildWideLayout(session, fmt, activities)
                            : isMedium
                                ? _buildMediumLayout(session, fmt, activities)
                                : _buildNarrowLayout(session, fmt, activities),
                      ),
                    ),
                    // ── Quick actions ──
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                      sliver: SliverToBoxAdapter(
                        child: _QuickActions(fmt: fmt),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Wide: 3 columns ───────────────────────────────────────────────────
  Widget _buildWideLayout(SessionProvider session, NumberFormat fmt, List<ActivityEvent> activities) {
    return SizedBox(
      height: 380,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // LEFT: Active sessions
          Expanded(flex: 35, child: _SessionListPanel(session: session)),
          const SizedBox(width: 14),
          // CENTER: Revenue chart
          Expanded(
            flex: 35,
            child: const PremiumRevenueChart(data: [
              450000, 620000, 380000, 780000, 550000, 920000, 680000
            ], maxValue: 1000000),
          ),
          const SizedBox(width: 14),
          // RIGHT: Activity timeline
          Expanded(
            flex: 30,
            child: ActivityTimeline(events: activities),
          ),
        ],
      ),
    );
  }

  // ── Medium: 2 columns ─────────────────────────────────────────────────
  Widget _buildMediumLayout(SessionProvider session, NumberFormat fmt, List<ActivityEvent> activities) {
    return SizedBox(
      height: 340,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _SessionListPanel(session: session)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(children: [
              const SizedBox(
                  height: 190,
                  child: PremiumRevenueChart(data: [
                    450000, 620000, 380000, 780000, 550000, 920000, 680000
                  ], maxValue: 1000000)),
              const SizedBox(height: 14),
              Expanded(
                  child: ActivityTimeline(events: activities)),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Narrow: single column ─────────────────────────────────────────────
  Widget _buildNarrowLayout(SessionProvider session, NumberFormat fmt, List<ActivityEvent> activities) {
    return Column(children: [
      SizedBox(height: 300, child: _SessionListPanel(session: session)),
      const SizedBox(height: 14),
      const SizedBox(
          height: 220,
          child: PremiumRevenueChart(data: [
            450000, 620000, 380000, 780000, 550000, 920000, 680000
          ], maxValue: 1000000)),
      const SizedBox(height: 14),
      SizedBox(height: 340, child: ActivityTimeline(events: activities)),
    ]);
  }


}

// ═════════════════════════════════════════════════════════════════
// Premium Stats Grid — 7 cards dengan glow & ikon
// ═════════════════════════════════════════════════════════════════
class _PremiumStatsGrid extends StatelessWidget {
  final SessionProvider session;
  final ConsoleProvider console;
  final DashboardSummaryModel? summary;
  final NumberFormat fmt;

  const _PremiumStatsGrid({
    required this.session,
    required this.console,
    required this.summary,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final activeCount = session.activeCount;
    final totalConsoles = summary?.totalConsoles ?? console.overview.length;
    final availableConsoles = summary?.availableConsoles ?? console.overview.where((c) => c.isAvailable).length;
    final revenue = (summary?.totalRevenue ?? 0) - (summary?.foodSalesRevenue ?? 0);
    final voucherCount = summary?.voucherUsageCount ?? 0;
    final transactions = summary?.totalTransactions ?? 0;
    final membershipCount = summary?.membershipCount ?? 0;
    final foodRevenue = summary?.foodSalesRevenue ?? 0;
    final foodOrders = summary?.foodOrderCount ?? 0;
    final pendingFood = summary?.pendingFoodOrders ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final gap = w >= 1200 ? 10.0 : 8.0;
        final cardHeight = w >= 1200 ? 112.0 : w >= 500 ? 110.0 : 108.0;

        // Lebar card: desktop lebar → 8 kartu 1 baris; makin kecil → wrap
        // ke 4/3/2 kartu per baris. Wrap widget otomatis mengalirkan ke
        // baris berikutnya.
        final cardWidth = w >= 1600
            ? (w - 16 - (7 * gap)) / 8   // 8 kartu dalam 1 baris
            : w >= 1200
                ? (w - 16 - (7 * gap)) / 8 // 8 kartu, lebih rapat
                : w >= 800
                    ? (w - 16 - (3 * gap)) / 4 // 4 per baris → 2 baris
                    : w >= 500
                        ? (w - 16 - (2 * gap)) / 3 // 3 per baris
                        : (w - 16 - (1 * gap)) / 2; // 2 per baris (mobile)

        final cards = <Widget>[
          DashboardStatCard(title: 'SESI AKTIF', value: '$activeCount', subtitle: 'Realtime', icon: Icons.play_circle_rounded, illustrationIcon: Icons.show_chart_rounded, gradient: const [Color(0xFF00B8FF), Color(0xFF2962FF)], borderColor: const Color(0xFF00B8FF)),
          DashboardStatCard(title: 'PENDAPATAN', value: 'Rp ${fmt.format(revenue.toInt())}', subtitle: 'Hari ini', icon: Icons.payments_rounded, illustrationIcon: Icons.trending_up_rounded, gradient: const [Color(0xFF00E676), Color(0xFF00C853)], borderColor: const Color(0xFF00E676)),
          DashboardStatCard(title: 'TOTAL KONSOL', value: '$totalConsoles', subtitle: 'Semua Unit', icon: Icons.sports_esports_rounded, illustrationIcon: Icons.gamepad_rounded, gradient: const [Color(0xFF2962FF), Color(0xFF1565C0)], borderColor: const Color(0xFF00B8FF)),
          DashboardStatCard(title: 'TERSEDIA', value: '$availableConsoles', subtitle: 'Siap Disewa', icon: Icons.check_circle_outline_rounded, illustrationIcon: Icons.videogame_asset_rounded, gradient: const [Color(0xFF7C4DFF), Color(0xFFE040FB)], borderColor: const Color(0xFFE040FB)),
          DashboardStatCard(title: 'TRANSAKSI', value: '$transactions', subtitle: 'Total Transaksi', icon: Icons.receipt_long_rounded, illustrationIcon: Icons.swap_horiz_rounded, gradient: const [Color(0xFFFF1744), Color(0xFFFF4081)], borderColor: const Color(0xFFFF1744)),
          DashboardStatCard(title: 'VOUCHER', value: '$voucherCount', subtitle: 'Voucher Dipakai', icon: Icons.confirmation_number_rounded, illustrationIcon: Icons.local_activity_rounded, gradient: const [Color(0xFFFF9800), Color(0xFFFFC107)], borderColor: const Color(0xFFFF9800)),
          DashboardStatCard(title: 'MEMBER', value: '$membershipCount', subtitle: 'Total Member', icon: Icons.groups_rounded, illustrationIcon: Icons.people_rounded, gradient: const [Color(0xFFFF2D95), Color(0xFFE040FB)], borderColor: const Color(0xFFFF2D95)),
          DashboardStatCard(title: 'MAKANAN', value: 'Rp ${fmt.format(foodRevenue.toInt())}', subtitle: '$foodOrders Order' + (pendingFood > 0 ? ' • $pendingFood Pending' : ''), icon: Icons.restaurant_rounded, illustrationIcon: Icons.fastfood_rounded, gradient: const [Color(0xFFF97316), Color(0xFFF59E0B)], borderColor: const Color(0xFFF97316)),
        ];

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards.map((c) => SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: c,
          )).toList(),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Session List Panel — daftar sesi aktif dengan scroll
// ═════════════════════════════════════════════════════════════════
class _SessionListPanel extends StatelessWidget {
  final SessionProvider session;
  const _SessionListPanel({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13131F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(10), width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: kGradientBlue,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: kPrimaryBlue.withAlpha(50), blurRadius: 8)],
                ),
                child: const Icon(Icons.play_circle_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('SESI AKTIF', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: kSuccessColor.withAlpha(20), borderRadius: BorderRadius.circular(6), border: Border.all(color: kSuccessColor.withAlpha(40))),
                child: Text('${session.activeSessions.length}', style: const TextStyle(color: kSuccessColor, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (session.isLoading)
            const Center(child: CircularProgressIndicator(color: kPrimaryBlue))
          else if (session.activeSessions.isEmpty)
            const Expanded(child: Center(child: _PremiumEmptyState()))
          else
            Expanded(
              child: ListView.builder(
                itemCount: session.activeSessions.length,
                itemBuilder: (ctx, i) => _DashSessionCard(session: session.activeSessions[i]),
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Premium Empty State — saat tidak ada sesi aktif
// ═════════════════════════════════════════════════════════════════
class _PremiumEmptyState extends StatelessWidget {
  const _PremiumEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Glowing ring + controller icon
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kPrimaryBlue.withAlpha(20), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: kPrimaryBlue.withAlpha(10), blurRadius: 30, spreadRadius: 10),
                  ],
                ),
              ),
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [kPrimaryBlue.withAlpha(30), kAccentPurple.withAlpha(20)],
                  ),
                  border: Border.all(color: kPrimaryBlue.withAlpha(40), width: 1),
                ),
                child: const Icon(Icons.sports_esports_outlined, color: kPrimaryBlue, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [kPrimaryBlue, kAccentPurple],
            ).createShader(bounds),
            child: const Text(
              'READY TO PLAY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Buka tab Rental untuk memulai sesi baru',
            style: TextStyle(color: kTextSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Menu Cepat — responsive wrap, premium glow buttons
// ═════════════════════════════════════════════════════════════════
class _QuickActions extends StatelessWidget {
  final NumberFormat fmt;
  const _QuickActions({required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF13131F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(8), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MENU CEPAT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          // Responsive wrap — 5/4/3/2 tombol per baris tergantung lebar
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final gap = 10.0;
              final btnWidth = w >= 900
                  ? (w - (4 * gap)) / 5   // 5 tombol 1 baris
                  : w >= 650
                      ? (w - (3 * gap)) / 4 // 4 tombol per baris
                      : w >= 420
                          ? (w - (2 * gap)) / 3 // 3 per baris
                          : (w - (1 * gap)) / 2; // 2 per baris (mobile)

              final btns = <_QuickBtn>[
                _QuickBtn(
                  icon: Icons.add_rounded,
                  label: 'Tambah\nRental',
                  gradient: const LinearGradient(colors: [Color(0xFF1E88FF), Color(0xFF0D47A1)]),
                  onTap: () => _navigate(context, 1),
                ),
                _QuickBtn(
                  icon: Icons.receipt_long_rounded,
                  label: 'Transaksi\nBaru',
                  gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF047857)]),
                  onTap: () => _navigate(context, 12),
                ),
                _QuickBtn(
                  icon: Icons.person_add_rounded,
                  label: 'Tambah\nMember',
                  gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)]),
                  onTap: () => _navigate(context, 4),
                ),
                _QuickBtn(
                  icon: Icons.confirmation_number_rounded,
                  label: 'Buat\nVoucher',
                  gradient: const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFF9D174D)]),
                  onTap: () => _navigate(context, 6),
                ),
                _QuickBtn(
                  icon: Icons.assessment_rounded,
                  label: 'Laporan\nHarian',
                  gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFB45309)]),
                  onTap: () => _navigate(context, 10),
                ),
              ];

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: btns.map((b) => SizedBox(
                  width: btnWidth,
                  child: b,
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    final dash = context.findAncestorStateOfType<_DashboardScreenState>();
    dash?.setPage(index);
  }
}

// ── Wide launcher-style button (icon left + text right) ───────────────
class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _QuickBtn({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                gradient.colors.first.withAlpha(35),
                gradient.colors.last.withAlpha(15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: gradient.colors.first.withAlpha(70),
              width: 0.7,
            ),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withAlpha(20),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.colors.first.withAlpha(60),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Existing Logout Button ────────────────────────────────────────────────
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
    final greeting = now.hour < 12 ? 'SELAMAT PAGI' : now.hour < 17 ? 'SELAMAT SIANG' : 'SELAMAT MALAM';
    // Banner gambar diganti dengan latar partikel animasi (_HeaderParticleField)
    // — lebih ringan, konsisten dengan gaya neon/glow di seluruh app, dan
    // tidak ada masalah crop/pillarbox sama sekali karena tidak pakai gambar.
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF13131F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(12), width: 0.6),
        boxShadow: [BoxShadow(color: kPrimaryBlue.withAlpha(25), blurRadius: 30, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // ── Latar partikel animasi (RepaintBoundary agar tidak memicu
            //    layout/paint ulang di widget lain saat window di-resize) ──
            const Positioned.fill(
              child: RepaintBoundary(child: _HeaderParticleField()),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // LEFT
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(greeting, style: TextStyle(color: kPrimaryBlue.withAlpha(230), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2)),
                        const SizedBox(height: 2),
                        const Text('WELCOME BACK,', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: 1)),
                        Text(user, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        const Text('Ready to Play Today?', style: TextStyle(color: Color(0xFF8892B0), fontSize: 11)),
                        const SizedBox(height: 6),
                        Container(width: 80, height: 3,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [kPrimaryBlue, kAccentPurple]),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [BoxShadow(color: kPrimaryBlue.withAlpha(120), blurRadius: 8, spreadRadius: 2)],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // RIGHT
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black.withAlpha(80), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withAlpha(15))),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text(DateFormat('HH:mm:ss').format(now), style: TextStyle(color: kPrimaryBlue.withAlpha(240), fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
                            Text(DateFormat('EEE, d MMM yyyy', 'id').format(now), style: const TextStyle(color: Color(0xFF8892B0), fontSize: 9)),
                          ]),
                        ),
                        const SizedBox(height: 8),
                        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                            Text(user, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                            const Text('Super Admin', style: TextStyle(color: Color(0xFF8892B0), fontSize: 9)),
                          ]),
                          const SizedBox(width: 10),
                          Container(width: 30, height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(colors: [kPrimaryBlue, kAccentPurple]),
                              border: Border.all(color: Colors.white.withAlpha(40), width: 2),
                              boxShadow: [BoxShadow(color: kPrimaryBlue.withAlpha(60), blurRadius: 10)],
                            ),
                            child: const Icon(Icons.person, color: Colors.white, size: 20),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Header static decor — glow blobs + sparkle dots (no animation)
// ═════════════════════════════════════════════════════════════════
class _HeaderParticleField extends StatelessWidget {
  const _HeaderParticleField();

  @override
  Widget build(BuildContext context) {
    // Sepenuhnya statis — tidak ada timer/animasi agar tidak membebani
    // GTK compositor saat window di-resize (OpenGL frame timeout).
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _HeaderStaticPainter(),
      ),
    );
  }
}

/// Static header decor — glow blobs + sparse sparkle dots.
/// NO animation/timers: avoids GTK OpenGL frame timeout during window resize.
class _HeaderStaticPainter extends CustomPainter {
  static final _rng = math.Random(7);
  static final _dots = List.generate(15, (i) {
    final colors = [kPrimaryBlue, kAccentPurple, kNeonPink, kSuccessColor, const Color(0xFF00E5FF)];
    return (
      x: _rng.nextDouble(),
      y: _rng.nextDouble(),
      r: 0.6 + _rng.nextDouble() * 1.6,
      alpha: 0.12 + _rng.nextDouble() * 0.18,
      color: colors[_rng.nextInt(colors.length)],
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Ambient glow blobs (statis)
    final blob1 = Paint()
      ..color = kPrimaryBlue.withAlpha(24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 42);
    canvas.drawCircle(Offset(size.width * 0.12, size.height * 0.35), 50, blob1);

    final blob2 = Paint()
      ..color = kNeonPink.withAlpha(20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48);
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.65), 56, blob2);

    final blob3 = Paint()
      ..color = kAccentPurple.withAlpha(18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 46);
    canvas.drawCircle(Offset(size.width * 0.55, size.height * 0.1), 52, blob3);

    // Titik dekoratif (sparkle dots)
    for (final d in _dots) {
      final paint = Paint()..color = d.color.withAlpha((d.alpha * 255).round());
      canvas.drawCircle(Offset(d.x * size.width, d.y * size.height), d.r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeaderStaticPainter oldDelegate) => false;
}

// ── Old StatsSection (kept for backward compat) ────────────────────────
class _StatsSection extends StatelessWidget {
  final SessionProvider session;
  final ConsoleProvider console;
  final DashboardSummaryModel? summary;
  const _StatsSection(
      {required this.session, required this.console, this.summary});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'id');

    // Value helpers — Sesi Aktif selalu dari SessionProvider (real-time),
    // stat lainnya pakai summary jika tersedia, fallback ke provider
    final activeCount = session.activeCount;
    final totalConsoles = summary?.totalConsoles ?? console.overview.length;
    final availableConsoles =
        summary?.availableConsoles ?? console.overview.where((c) => c.isAvailable).length;
    final revenue = summary?.totalRevenue ?? 0;
    final voucherCount = summary?.voucherUsageCount ?? 0;
    final transactions = summary?.totalTransactions ?? 0;
    final dailyRentalRevenue = summary?.dailyRentalRevenue ?? 0;
    final dailyRentalCount = summary?.dailyRentalCount ?? 0;
    final membershipRevenue = summary?.membershipRevenue ?? 0;
    final membershipCount = summary?.membershipCount ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final crossAxisCount = w >= 1400
            ? 6
            : w >= 1000
                ? 4
                : w >= 600
                    ? 3
                    : 2;
        // Responsive aspect: mobile → card lebih lebar/pendek, desktop → lebih tinggi
        final childAspect = w >= 1000 ? 1.5 : w >= 600 ? 1.6 : 1.8;

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
            _StatCard(
              label: 'Rental Harian',
              value: dailyRentalCount > 0
                  ? '${dailyRentalCount} • Rp ${fmt.format(dailyRentalRevenue.toInt())}'
                  : '0',
              icon: Icons.home_rounded,
              gradient: kGradientBlue,
              glowColor: kPrimaryBlue,
            ),
            _StatCard(
              label: 'Membership',
              value: membershipCount > 0
                  ? '${membershipCount} • Rp ${fmt.format(membershipRevenue.toInt())}'
                  : '0',
              icon: Icons.card_membership_rounded,
              gradient: kGradientPurple,
              glowColor: kAccentPurple,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF13131F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glowColor.withAlpha(25), width: 0.6),
        boxShadow: [
          BoxShadow(
            color: glowColor.withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon with glow
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withAlpha(60),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          // Value + label
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: kTextSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
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

// ─── Dashboard session card (compact, stateless) ──────────────────────────
// Tidak pakai Timer — elapsed time di-refresh oleh dashboard poll 15 detik,
// cukup untuk overview. Menghindari setState/detik yang membebani resize.
class _DashSessionCard extends StatelessWidget {
  final SessionModel session;
  const _DashSessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final elapsed = session.elapsed;
    final h = elapsed.inHours.toString().padLeft(2, '0');
    final m = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final isPs5 = session.consoleType.contains('5');
    final typeColor = isPs5 ? kAccentPurple : kPrimaryBlue;
    final typeGrad = isPs5 ? kGradientPurple : kGradientBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF13131F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: typeColor.withAlpha(30), width: 0.6),
        boxShadow: [
          BoxShadow(
            color: typeColor.withAlpha(12),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
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
                      '$h:$m:$s',
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

// ═════════════════════════════════════════════════════════════════
// Pending Payments Banner — persistent alert di dashboard
// ═════════════════════════════════════════════════════════════════
class _PendingPaymentsBanner extends StatelessWidget {
  final int count;
  final List<PaymentModel> payments;
  const _PendingPaymentsBanner({required this.count, required this.payments});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'id');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPendingList(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xCC3D1800), Color(0xCC1A0800)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kWarningColor.withAlpha(90), width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: kWarningColor.withAlpha(25),
                  blurRadius: 16,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kWarningColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: kWarningColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ Ada $count pembayaran extend yang belum dikonfirmasi',
                        style: const TextStyle(
                          color: kWarningColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ketuk untuk lihat & konfirmasi',
                        style: TextStyle(
                          color: kWarningColor.withAlpha(160),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: kWarningColor.withAlpha(140),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPendingList(BuildContext context) {
    final fmt = NumberFormat('#,###', 'id');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: kWarningColor, size: 22),
            const SizedBox(width: 8),
            Text('$count Pembayaran Tertunda',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView(
              shrinkWrap: true,
              children: payments.map((p) => _PendingPaymentTile(
                    payment: p,
                    fmt: fmt,
                    onConfirm: () => _confirmPayment(ctx, p),
                  )).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPayment(BuildContext dialogCtx, PaymentModel payment) async {
    final prov = dialogCtx.read<PaymentProvider>();
    final confirmed = await prov.confirmPayment(paymentId: payment.id);

    if (confirmed != null) {
      // Optimistic: hapus langsung dari list tanpa tunggu polling
      prov.removePendingOptimistic(payment.id);
      Navigator.pop(dialogCtx); // tutup dialog list
      ScaffoldMessenger.of(dialogCtx).showSnackBar(
        const SnackBar(
          content: Text('Pembayaran berhasil dikonfirmasi'),
          backgroundColor: kSuccessColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(dialogCtx).showSnackBar(SnackBar(
        content: Text(prov.error ?? 'Gagal konfirmasi'),
        backgroundColor: kErrorColor,
      ));
    }
  }
}

class _PendingPaymentTile extends StatelessWidget {
  final PaymentModel payment;
  final NumberFormat fmt;
  final VoidCallback onConfirm;

  const _PendingPaymentTile({
    required this.payment,
    required this.fmt,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final consoleName = payment.session?.consoleName ?? 'Konsol';
    final sessionNote = payment.notes ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorderColor, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(consoleName,
                    style: const TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  'Rp ${fmt.format(payment.amount.toInt())}',
                  style: const TextStyle(
                    color: kWarningColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (sessionNote.isNotEmpty)
                  Text(sessionNote,
                      style: const TextStyle(
                          color: kTextSecondary, fontSize: 11)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: onConfirm,
            icon: const Icon(Icons.payment_rounded, size: 16),
            label: const Text('Bayar', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}
