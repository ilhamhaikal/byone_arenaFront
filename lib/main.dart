import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/app_theme.dart';
import 'config/platform_config.dart';
import 'providers/auth_provider.dart';
import 'providers/client_provider.dart';
import 'providers/console_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/session_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/shift_provider.dart';
import 'providers/dashboard_summary_provider.dart';
import 'providers/discount_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/report_provider.dart';
import 'providers/voucher_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/food_order_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/daily_rental_provider.dart';
import 'providers/membership_settings_provider.dart';
import 'providers/daily_price_settings_provider.dart';
import 'providers/activity_provider.dart';
import 'screens/client/role_select_screen.dart';
import 'screens/client/client_display_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/login/login_screen.dart';
import 'widgets/particle_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);
  // Load baseUrl dari SharedPreferences (default: localhost).
  // User bisa ubah via login screen → disimpan → dipakai di semua platform.
  await PlatformConfig.init();
  runApp(const KioskApp());
}

class KioskApp extends StatelessWidget {
  const KioskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ConsoleProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => ShiftProvider()),
        ChangeNotifierProvider(create: (_) => DiscountProvider()),
        ChangeNotifierProvider(create: (_) => VoucherProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => FoodOrderProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => DailyRentalProvider()),
        ChangeNotifierProvider(create: (_) => MembershipSettingsProvider()),
        ChangeNotifierProvider(create: (_) => DailyPriceSettingsProvider()),
        ChangeNotifierProvider(create: (_) => ClientProvider()),
        ChangeNotifierProvider(create: (_) => DashboardSummaryProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
      ],
      child: MaterialApp(
        title: 'Kiosk PS',
        debugShowCheckedModeBanner: false,
        theme: appTheme(),
        home: const _AppRoot(),
      ),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  static const _roleKey = 'app_role';
  AppRole? _role;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_roleKey);
    if (mounted) {
      setState(() {
        if (stored == 'client') {
          _role = AppRole.client;
        } else if (stored == 'admin') {
          _role = AppRole.admin;
        } else {
          _role = null; // belum memilih
        }
      });
      // Jika admin, lanjutkan auth flow
      if (_role == AppRole.admin) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<AuthProvider>().checkAuth();
        });
      }
    }
  }

  Future<void> _selectRole(AppRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role == AppRole.admin ? 'admin' : 'client');
    setState(() => _role = role);
    if (role == AppRole.admin) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<AuthProvider>().checkAuth();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Belum load role dari storage
    if (_role == null) {
      return RoleSelectScreen(onRoleSelected: _selectRole);
    }

    // Client mode — langsung tampilkan display, tidak perlu auth
    if (_role == AppRole.client) {
      return Stack(
        children: [
          const ClientDisplayScreen(),
          // Tombol kecil di pojok untuk kembali ke role selection
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.settings, color: kTextSecondary, size: 20),
              tooltip: 'Ganti mode',
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove(_roleKey);
                setState(() => _role = null);
              },
            ),
          ),
        ],
      );
    }

    // Admin mode — auth flow seperti biasa
    return ParticleBackground(
      showConnections: true,
      child: Theme(
        data: Theme.of(context).copyWith(
          scaffoldBackgroundColor: Colors.transparent,
        ),
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            switch (auth.status) {
              case AuthStatus.initial:
              case AuthStatus.loading:
                return const _SplashScreen();
              case AuthStatus.authenticated:
                return DashboardScreen(onSwitchToRoleSelect: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove(_roleKey);
                  setState(() => _role = null);
                });
              case AuthStatus.unauthenticated:
                return LoginScreen();
            }
          },
        ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kHighlightColor.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: kHighlightColor, width: 2),
              ),
              child: const Icon(
                Icons.sports_esports,
                size: 60,
                color: kHighlightColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'BYONE ARENA',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: kHighlightColor),
          ],
        ),
      ),
    );
  }
}
