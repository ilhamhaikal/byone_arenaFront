import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success =
        await auth.login(_usernameCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Login gagal'),
          backgroundColor: kErrorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          // ── Background ──────────────────────────────────────
          Container(color: kDeepBlack),

          // ── Ambient glow circles ─────────────────────────────
          Positioned(
            top: -120, left: -120,
            child: _GlowCircle(color: kAccentPurple, size: 360),
          ),
          Positioned(
            bottom: -100, right: -100,
            child: _GlowCircle(color: kNeonPink, size: 300),
          ),
          Positioned(
            top: size.height * 0.45,
            left: size.width * 0.55,
            child: _GlowCircle(color: kPrimaryBlue, size: 220),
          ),

          // ── Main content ─────────────────────────────────────
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/images/logo.png',
                      width: 280,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 6),

                    // Tagline gradient
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [kPrimaryBlue, kAccentPurple, kNeonPink],
                      ).createShader(bounds),
                      child: const Text(
                        'SISTEM MANAJEMEN RENTAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // ── Glassmorphism Card ───────────────────────
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: kAccentPurple.withOpacity(0.45),
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.all(32),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Header accent bar
                                Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [kNeonPink, kAccentPurple],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: kNeonPink.withOpacity(0.6),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'MASUK KE AKUN',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: kSilverWhite,
                                        letterSpacing: 2.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 28),

                                // Username
                                _GameField(
                                  controller: _usernameCtrl,
                                  label: 'USERNAME',
                                  icon: Icons.person_outline_rounded,
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Username wajib diisi'
                                      : null,
                                ),
                                const SizedBox(height: 14),

                                // Password
                                _GameField(
                                  controller: _passwordCtrl,
                                  label: 'PASSWORD',
                                  icon: Icons.lock_outline_rounded,
                                  obscure: _obscurePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: kTextSecondary,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                        () => _obscurePassword = !_obscurePassword),
                                  ),
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Password wajib diisi'
                                      : null,
                                  onFieldSubmitted: (_) => _login(),
                                ),
                                const SizedBox(height: 28),

                                // Gradient button
                                Consumer<AuthProvider>(
                                  builder: (context, auth, _) {
                                    return _GradientButton(
                                      onPressed: auth.status == AuthStatus.loading
                                          ? null
                                          : _login,
                                      isLoading:
                                          auth.status == AuthStatus.loading,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Footer divider
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Colors.transparent,
                                kAccentPurple.withOpacity(0.5),
                              ]),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            '© 2026 BYONE ARENA',
                            style: TextStyle(
                              color: kTextSecondary.withOpacity(0.45),
                              fontSize: 10,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                kNeonPink.withOpacity(0.5),
                                Colors.transparent,
                              ]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ambient glow circle ──────────────────────────────────────
class _GlowCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.06),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.18),
            blurRadius: size * 0.7,
            spreadRadius: size * 0.15,
          ),
        ],
      ),
    );
  }
}

// ── Custom gamer-style text field ────────────────────────────
class _GameField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const _GameField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: kSilverWhite, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: kTextSecondary,
          fontSize: 11,
          letterSpacing: 1.8,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: kAccentPurple, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kAccentPurple.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kAccentPurple.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kNeonPink, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kNintendoRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kNintendoRed, width: 1.5),
        ),
      ),
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
    );
  }
}

// ── Gradient login button ────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  const _GradientButton({required this.onPressed, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final active = onPressed != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: active
            ? const LinearGradient(
                colors: [kPrimaryBlue, kAccentPurple, kNeonPink],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : LinearGradient(
                colors: [Colors.grey.shade800, Colors.grey.shade700]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: active
            ? [
                BoxShadow(
                  color: kNeonPink.withOpacity(0.4),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 6),
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Text(
                'M A S U K',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
