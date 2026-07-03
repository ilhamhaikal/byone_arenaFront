import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/console_overview_model.dart';
import '../../providers/client_provider.dart';

class ClientDisplayScreen extends StatefulWidget {
  const ClientDisplayScreen({super.key});

  @override
  State<ClientDisplayScreen> createState() => _ClientDisplayScreenState();
}

class _ClientDisplayScreenState extends State<ClientDisplayScreen>
    with TickerProviderStateMixin {
  Timer? _ticker;
  bool _warningVisible = false;
  bool _showCountdown = false;
  Timer? _warningTimer;
  late AnimationController _pulseCtrl;
  late AnimationController _countdownCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientProvider>().startPolling(interval: 10);
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _onTick();
    });
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _countdownCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _warningTimer?.cancel();
    _pulseCtrl.dispose();
    _countdownCtrl.dispose();
    super.dispose();
  }

  void _onTick() {
    final p = context.read<ClientProvider>();
    if (p.state != ClientDisplayState.active &&
        p.state != ClientDisplayState.overtime) {
      if (_warningVisible || _showCountdown) {
        setState(() {
          _warningVisible = false;
          _showCountdown = false;
        });
        _warningTimer?.cancel();
        _countdownCtrl.reset();
      }
      return;
    }

    final sess = p.activeSession;
    if (sess == null) return;

    final remainingSeconds = sess.remaining?.inSeconds;

    if (p.state == ClientDisplayState.overtime) {
      if (!_showCountdown) {
        _warningTimer?.cancel();
        setState(() {
          _warningVisible = false;
          _showCountdown = true;
        });
      }
      return;
    }

    // 5-second countdown
    if (remainingSeconds != null &&
        remainingSeconds <= 5 &&
        remainingSeconds > 0) {
      if (!_showCountdown) {
        _warningTimer?.cancel();
        setState(() {
          _warningVisible = false;
          _showCountdown = true;
        });
      }
      if (!_countdownCtrl.isAnimating && !_countdownCtrl.isCompleted) {
        _countdownCtrl.forward(from: 0);
      }
      return;
    }

    // 5-minute warning notification
    if (remainingSeconds != null &&
        remainingSeconds <= 300 &&
        remainingSeconds > 5) {
      if (!_warningVisible && !_showCountdown) {
        setState(() => _warningVisible = true);
        _warningTimer?.cancel();
        _warningTimer = Timer(const Duration(seconds: 20), () {
          if (mounted) setState(() => _warningVisible = false);
        });
      }
      return;
    }

    // Normal play — no overlay
    if (_warningVisible || _showCountdown) {
      setState(() {
        _warningVisible = false;
        _showCountdown = false;
      });
      _warningTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ClientProvider>(
      builder: (_, p, __) {
        if (p.state == ClientDisplayState.overtime) return _buildScreenSaver(p);
        if (p.state == ClientDisplayState.maintenance) return _buildMaintenance(p);
        if (p.state == ClientDisplayState.loading ||
            p.state == ClientDisplayState.notFound) {
          return _buildStatus(p);
        }
        if (p.state == ClientDisplayState.idle) return _buildIdle(p);
        return _buildActiveOverlay(p);
      },
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // STATUS (loading / not found)
  // ═════════════════════════════════════════════════════════════════
  Widget _buildStatus(ClientProvider p) {
    return Scaffold(
      backgroundColor: kDeepBlack,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (p.state == ClientDisplayState.loading) ...[
              const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                      color: kPrimaryBlue, strokeWidth: 3)),
              const SizedBox(height: 24),
              const Text('Menghubungkan...',
                  style: TextStyle(color: kTextSecondary, fontSize: 16)),
            ] else ...[
              const Icon(Icons.tv_off_rounded,
                  size: 64, color: kTextSecondary),
              const SizedBox(height: 24),
              const Text('Konsol Tidak Ditemukan',
                  style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
            if (p.error != null) ...[
              const SizedBox(height: 8),
              Text(p.error!,
                  style: const TextStyle(color: kErrorColor, fontSize: 12),
                  textAlign: TextAlign.center),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => p.startPolling(interval: 10),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // IDLE — screen saver
  // ═════════════════════════════════════════════════════════════════
  Widget _buildIdle(ClientProvider p) {
    final c = p.console!;
    return Scaffold(
      backgroundColor: kDeepBlack,
      body: Center(
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (_, child) => Opacity(opacity: _pulse.value, child: child),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: kGradientGreen,
                  boxShadow: [
                    BoxShadow(
                        color: kSuccessColor.withAlpha(60), blurRadius: 40)
                  ],
                ),
                child: const Icon(Icons.sports_esports,
                    size: 64, color: Colors.white),
              ),
              const SizedBox(height: 32),
              Text(c.name,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary)),
              const SizedBox(height: 8),
              const Text('Konsol Tersedia — Hubungi Admin',
                  style: TextStyle(color: kTextSecondary, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // MAINTENANCE
  // ═════════════════════════════════════════════════════════════════
  Widget _buildMaintenance(ClientProvider p) {
    final c = p.console!;
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A00),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction_rounded,
                size: 64, color: kWarningColor),
            const SizedBox(height: 24),
            Text(c.name,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary)),
            const SizedBox(height: 8),
            const Text('DALAM PERBAIKAN',
                style: TextStyle(
                    fontSize: 14,
                    color: kWarningColor,
                    letterSpacing: 4)),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // ACTIVE — overlay minimal
  // ═════════════════════════════════════════════════════════════════
  Widget _buildActiveOverlay(ClientProvider p) {
    final sess = p.activeSession!;
    final remaining = sess.remaining;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Background: fully transparent (game via HDMI)
          const Positioned.fill(child: SizedBox.expand()),

          // 5-minute warning notification (top-right, 20s auto-dismiss)
          if (_warningVisible && !_showCountdown)
            Positioned(
              top: 24,
              right: 24,
              child: _WarningBubble(
                remainingSeconds: remaining?.inSeconds ?? 0,
              ),
            ),

          // 5-second countdown overlay (fullscreen)
          if (_showCountdown)
            Positioned.fill(
              child: _CountdownFullscreen(
                remainingSeconds: remaining?.inSeconds ?? 0,
                controller: _countdownCtrl,
              ),
            ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // SCREEN SAVER — time's up, block HDMI
  // ═════════════════════════════════════════════════════════════════
  Widget _buildScreenSaver(ClientProvider p) {
    return Scaffold(
      backgroundColor: kDeepBlack,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: _pulse.value * 0.8,
                    colors: const [Color(0xFF1A0000), kDeepBlack],
                  ),
                ),
              );
            },
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_off_rounded,
                    size: 96, color: kErrorColor),
                const SizedBox(height: 24),
                const Text('WAKTU HABIS',
                    style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: kErrorColor,
                        letterSpacing: 8)),
                const SizedBox(height: 12),
                if (p.console != null)
                  Text(p.console!.name,
                      style: const TextStyle(
                          fontSize: 18, color: kTextSecondary)),
                const SizedBox(height: 16),
                const Text('Hubungi admin untuk memperpanjang sesi',
                    style:
                        TextStyle(color: kTextSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Warning Bubble — pojok kanan atas
// ══════════════════════════════════════════════════════════════════════
class _WarningBubble extends StatefulWidget {
  final int remainingSeconds;
  const _WarningBubble({required this.remainingSeconds});

  @override
  State<_WarningBubble> createState() => _WarningBubbleState();
}

class _WarningBubbleState extends State<_WarningBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  String _fmtTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: kWarningColor.withAlpha(220),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: kWarningColor.withAlpha(80), blurRadius: 20)
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('WAKTU HAMPIR HABIS',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2)),
                const SizedBox(height: 2),
                Text('Sisa ${_fmtTime(widget.remainingSeconds)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Countdown Fullscreen — hitungan mundur 5...4...3...2...1
// ══════════════════════════════════════════════════════════════════════
class _CountdownFullscreen extends StatelessWidget {
  final int remainingSeconds;
  final AnimationController controller;
  const _CountdownFullscreen(
      {required this.remainingSeconds, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, child) {
        return Container(
          color: kErrorColor.withAlpha((controller.value * 160).round()),
          child: Center(
            child: Transform.scale(
              scale: 1.0 + controller.value * 0.3,
              child: Text(
                remainingSeconds > 0 ? '$remainingSeconds' : '0',
                style: TextStyle(
                  fontSize: 120 + (controller.value * 40),
                  fontWeight: FontWeight.w900,
                  color: Colors.white
                      .withAlpha(200 + (controller.value * 55).round()),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
