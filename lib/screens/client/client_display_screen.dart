import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/tv_notification_model.dart';
import '../../providers/client_provider.dart';

class ClientDisplayScreen extends StatefulWidget {
  const ClientDisplayScreen({super.key});

  @override
  State<ClientDisplayScreen> createState() => _ClientDisplayScreenState();
}

class _ClientDisplayScreenState extends State<ClientDisplayScreen>
    with TickerProviderStateMixin {
  Timer? _ticker;
  Timer? _notifTimer;
  Timer? _warningDismissTimer;
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;
  bool _wasOvertime = false;
  String? _warningText; // teks warning sisa waktu
  bool _warningDismissed = false; // hanya muncul sekali per sesi (kecuali 10 detik)
  int _lastRemainingSeconds = -1; // track perubahan detik

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientProvider>().startPolling(interval: 10);
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _onTick();
    });
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _notifTimer?.cancel();
    _warningDismissTimer?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _onTick() {
    final p = context.read<ClientProvider>();
    final isOvertime = p.state == ClientDisplayState.overtime;

    // Screen saver transition
    if (isOvertime && !_wasOvertime) {
      _wasOvertime = true;
      _fadeCtrl.forward();
    } else if (!isOvertime) {
      _wasOvertime = false;
      _fadeCtrl.reset();
    }

    // Reset warning saat tidak aktif
    if (p.state != ClientDisplayState.active) {
      if (_warningText != null || _warningDismissed) {
        setState(() {
          _warningText = null;
          _warningDismissed = false;
          _lastRemainingSeconds = -1;
        });
        _warningDismissTimer?.cancel();
      }
    }

    // Warning sisa waktu (hanya saat sesi aktif)
    if (p.state == ClientDisplayState.active) {
      final sess = p.activeSession;
      final remainingSeconds = sess?.remaining?.inSeconds;
      if (remainingSeconds != null) {
        _updateWarning(remainingSeconds);
      }
    }

    // Auto-dismiss promo notification
    if (p.currentNotification != null && _notifTimer == null) {
      _notifTimer = Timer(const Duration(seconds: 8), () {
        if (mounted) {
          context.read<ClientProvider>().dismissNotification();
          _notifTimer = null;
        }
      });
    } else if (p.currentNotification == null) {
      _notifTimer?.cancel();
      _notifTimer = null;
    }

    if (mounted) setState(() {});
  }

  void _updateWarning(int remainingSeconds) {
    // 10 detik — warning selalu muncul
    if (remainingSeconds <= 10 && remainingSeconds > 0) {
      final min = remainingSeconds ~/ 60;
      final sec = remainingSeconds % 60;
      final text = min > 0 ? 'Sisa $min mnt $sec dtk' : 'Sisa $sec detik';
      if (_warningText != text) {
        _warningDismissTimer?.cancel();
        setState(() => _warningText = text);
      }
      return;
    }

    // 5 menit — muncul sekali 10 detik
    if (remainingSeconds <= 300 && remainingSeconds > 10 && !_warningDismissed) {
      final min = remainingSeconds ~/ 60;
      if (_warningText == null) {
        setState(() => _warningText = 'Sisa $min menit');
        _warningDismissTimer?.cancel();
        _warningDismissTimer = Timer(const Duration(seconds: 10), () {
          if (mounted) {
            setState(() {
              _warningText = null;
              _warningDismissed = true;
            });
          }
        });
      }
      return;
    }

    // Normal — clear warning
    if (_warningText != null && remainingSeconds > 300) {
      _warningDismissTimer?.cancel();
      setState(() => _warningText = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ClientProvider>(
      builder: (_, p, __) {
        // Screen saver = fullscreen, tidak perlu notif overlay
        if (p.state == ClientDisplayState.overtime) {
          return _buildScreenSaver(p);
        }

        // Build body sesuai state
        final Widget body;
        if (p.state == ClientDisplayState.maintenance) {
          body = _buildMaintenance(p);
        } else if (p.state == ClientDisplayState.loading ||
            p.state == ClientDisplayState.notFound) {
          body = _buildStatus(p);
        } else if (p.state == ClientDisplayState.idle) {
          body = _buildIdle(p);
        } else {
          // Active: transparan
          body = const SizedBox.expand();
        }

        // Notifikasi + warning overlay di SEMUA state (kecuali screen saver)
        if (p.currentNotification == null && _warningText == null) return body;
        return Stack(
          children: [
            Positioned.fill(child: body),
            if (_warningText != null)
              Positioned(
                top: 32,
                right: 32,
                child: _TimeWarning(text: _warningText!),
              ),
            if (p.currentNotification != null)
              _NotificationOverlay(notification: p.currentNotification!),
          ],
        );
      },
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // SCREEN SAVER — smooth fade in
  // ═════════════════════════════════════════════════════════════════
  Widget _buildScreenSaver(ClientProvider p) {
    return FadeTransition(
      opacity: _fade,
      child: Scaffold(
        backgroundColor: kDeepBlack,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  colors: [Color(0xFF1A0000), kDeepBlack],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_off_rounded,
                      size: 80, color: kErrorColor),
                  const SizedBox(height: 20),
                  const Text('WAKTU HABIS',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: kErrorColor,
                          letterSpacing: 6)),
                  const SizedBox(height: 10),
                  if (p.console != null)
                    Text(p.console!.name,
                        style: const TextStyle(
                            fontSize: 16, color: kTextSecondary)),
                  const SizedBox(height: 12),
                  const Text('Hubungi admin untuk memperpanjang sesi',
                      style: TextStyle(
                          color: kTextSecondary, fontSize: 12)),
                ],
              ),
            ),
          ],
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
                size: 56, color: kWarningColor),
            const SizedBox(height: 20),
            Text(c.name,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary)),
            const SizedBox(height: 6),
            const Text('DALAM PERBAIKAN',
                style: TextStyle(
                    fontSize: 13,
                    color: kWarningColor,
                    letterSpacing: 3)),
          ],
        ),
      ),
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
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                      color: kPrimaryBlue, strokeWidth: 3)),
              const SizedBox(height: 20),
              const Text('Menghubungkan...',
                  style: TextStyle(
                      color: kTextSecondary, fontSize: 14)),
            ] else ...[
              const Icon(Icons.tv_off_rounded,
                  size: 56, color: kTextSecondary),
              const SizedBox(height: 20),
              const Text('Konsol Tidak Ditemukan',
                  style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
            if (p.error != null) ...[
              const SizedBox(height: 8),
              Text(p.error!,
                  style: const TextStyle(
                      color: kErrorColor, fontSize: 11),
                  textAlign: TextAlign.center),
            ],
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => p.startPolling(interval: 10),
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // IDLE
  // ═════════════════════════════════════════════════════════════════
  Widget _buildIdle(ClientProvider p) {
    final c = p.console!;
    return Scaffold(
      backgroundColor: kDeepBlack,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: kGradientGreen,
                boxShadow: [
                  BoxShadow(
                      color: kSuccessColor.withAlpha(60),
                      blurRadius: 40)
                ],
              ),
              child: const Icon(Icons.sports_esports,
                  size: 56, color: Colors.white),
            ),
            const SizedBox(height: 28),
            Text(c.name,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary)),
            const SizedBox(height: 6),
            const Text('Konsol Tersedia — Hubungi Admin',
                style: TextStyle(
                    color: kTextSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Notification Overlay — tampil di tengah, auto-dismiss 8 detik
// ═════════════════════════════════════════════════════════════════
class _NotificationOverlay extends StatefulWidget {
  final TvNotificationModel notification;
  const _NotificationOverlay({required this.notification});

  @override
  State<_NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<_NotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    return FadeTransition(
      opacity: _fadeIn,
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 32, top: 32),
          child: Opacity(
            opacity: 0.65,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.title,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 8),
                        ])),
                if (n.message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(n.message,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 6),
                          ])),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Time Warning — pojok kanan bawah, text only
// ═════════════════════════════════════════════════════════════════
class _TimeWarning extends StatefulWidget {
  final String text;
  const _TimeWarning({required this.text});

  @override
  State<_TimeWarning> createState() => _TimeWarningState();
}

class _TimeWarningState extends State<_TimeWarning>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _anim, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: Opacity(
        opacity: 0.6,
        child: Text(
          widget.text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(color: Colors.black54, blurRadius: 8),
            ],
          ),
        ),
      ),
    );
  }
}