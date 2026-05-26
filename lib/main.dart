import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/console_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/session_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/shift_provider.dart';
import 'providers/discount_provider.dart';
import 'providers/voucher_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/food_order_provider.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/login/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        switch (auth.status) {
          case AuthStatus.initial:
          case AuthStatus.loading:
            return const _SplashScreen();
          case AuthStatus.authenticated:
            return const DashboardScreen();
          case AuthStatus.unauthenticated:
            return const LoginScreen();
        }
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
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
