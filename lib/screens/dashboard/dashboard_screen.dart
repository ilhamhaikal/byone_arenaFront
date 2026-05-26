import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/session_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../membership/membership_screen.dart';
import '../rental/rental_screen.dart';
import '../discount/discount_screen.dart';
import '../voucher/voucher_screen.dart';
import '../menu/menu_screen.dart';
import '../food_order/food_order_screen.dart';
import '../console/console_screen.dart';

// ─── Dashboard shell ────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
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
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _HomeTab(),
      const RentalScreen(),
      const ConsoleScreen(),
      const MembershipScreen(),
      const DiscountScreen(),
      const VoucherScreen(),
      const MenuScreen(),
      const FoodOrderScreen(),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final selected = currentIndex == i;
              final (outIcon, selIcon, label) = items[i];
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: selected
                      ? BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kPrimaryBlue.withAlpha(40), kAccentPurple.withAlpha(30)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kPrimaryBlue.withAlpha(70), width: 0.5),
                        )
                      : null,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(selected ? selIcon : outIcon,
                          color: selected ? kPrimaryBlue : kTextSecondary, size: 22),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: TextStyle(
                          color: selected ? kPrimaryBlue : kTextSecondary,
                          fontSize: 10,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Home tab ───────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDeepBlack,
      body: Consumer2<AuthProvider, SessionProvider>(
        builder: (context, auth, session, _) {
          return RefreshIndicator(
            color: kPrimaryBlue,
            backgroundColor: kSurface,
            onRefresh: () async {
              await session.loadActive();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── App bar ──
                SliverAppBar(
                  expandedHeight: 130,
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
                      },
                    ),
                    _LogoutButton(),
                    const SizedBox(width: 4),
                  ],
                ),
                // ── Stats ──
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _StatsSection(session: session),
                  ),
                ),
                // ── Active rentals header ──
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
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
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout_rounded, color: kTextSecondary),
      tooltip: 'Logout',
      onPressed: () async {
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
      },
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
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(greeting, style: const TextStyle(color: kTextSecondary, fontSize: 13)),
                const SizedBox(height: 2),
                ShaderMask(
                  shaderCallback: (b) => kGradientBrand.createShader(b),
                  child: Text(user,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimaryBlue.withAlpha(30), kAccentPurple.withAlpha(20)],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kBorderColor),
            ),
            child: Text(
              DateFormat('EEE, d MMM', 'id').format(now),
              style: const TextStyle(color: kTextSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final SessionProvider session;
  const _StatsSection({required this.session});

  @override
  Widget build(BuildContext context) {
    final activeCount = session.activeCount;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        _StatCard(
          label: 'Sesi Aktif',
          value: '$activeCount',
          icon: Icons.play_circle_rounded,
          gradient: kGradientBlue,
          glowColor: kPrimaryBlue,
        ),
        _StatCard(
          label: 'Total Konsol',
          value: '-',
          icon: Icons.sports_esports_rounded,
          gradient: kGradientPurple,
          glowColor: kAccentPurple,
        ),
        _StatCard(
          label: 'Konsol Tersedia',
          value: '-',
          icon: Icons.check_circle_outline_rounded,
          gradient: kGradientGreen,
          glowColor: kSuccessColor,
        ),
        _StatCard(
          label: 'Maintenance',
          value: '-',
          icon: Icons.build_outlined,
          gradient: kGradientAmber,
          glowColor: kWarningColor,
        ),
      ],
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
        color: kCardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderColor, width: 0.5),
        boxShadow: [
          BoxShadow(color: glowColor.withAlpha(20), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: glowColor.withAlpha(80), blurRadius: 8)],
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: kTextPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 11)),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: kCardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kBorderColor),
            ),
            child: Icon(icon, size: 36, color: kTextSecondary),
          ),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(
                  color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
          if (sub != null) ...[
            const SizedBox(height: 6),
            Text(sub!, style: const TextStyle(color: kTextSecondary, fontSize: 13)),
          ],
        ],
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
