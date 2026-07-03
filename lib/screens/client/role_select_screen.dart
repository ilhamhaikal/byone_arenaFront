import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

/// Enum untuk menyimpan role yang dipilih (disimpan di SharedPreferences via key)
enum AppRole { admin, client }

class RoleSelectScreen extends StatefulWidget {
  /// Callback saat user memilih role. Dipanggil oleh _AppRoot untuk navigasi.
  final void Function(AppRole role) onRoleSelected;

  const RoleSelectScreen({super.key, required this.onRoleSelected});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDeepBlack,
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slideUp,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: kGradientBrand,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryBlue.withAlpha(80),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.sports_esports,
                      size: 56, color: Colors.white),
                ),
                const SizedBox(height: 24),
                const Text(
                  'BYONE ARENA',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                    letterSpacing: 5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pilih Mode Aplikasi',
                  style: TextStyle(color: kTextSecondary, fontSize: 14),
                ),
                const SizedBox(height: 48),

                // ── Admin Card ──────────────────────────────────────────
                _RoleCard(
                  icon: Icons.admin_panel_settings_rounded,
                  title: 'Admin',
                  subtitle: 'Dashboard penuh:\nManajemen rental, sesi, konsol, member, & laporan',
                  gradient: kGradientBlue,
                  onTap: () => widget.onRoleSelected(AppRole.admin),
                ),

                const SizedBox(height: 16),

                // ── Client Card ─────────────────────────────────────────
                _RoleCard(
                  icon: Icons.tv_rounded,
                  title: 'Client',
                  subtitle: 'Layar display konsol:\nTimer otomatis berdasarkan IP perangkat',
                  gradient: kGradientPurple,
                  onTap: () => widget.onRoleSelected(AppRole.client),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorderColor),
          boxShadow: [
            BoxShadow(
              color: kDeepBlack.withAlpha(80),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: kTextSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: kTextSecondary, size: 16),
          ],
        ),
      ),
    );
  }
}
