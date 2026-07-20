import 'dart:async';
import 'dart:math' as math;
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
// Notification Overlay — modern glass card, top-left
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
  late Animation<double> _fadeSlide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeSlide = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Color get _accent {
    switch (widget.notification.priority) {
      case 'high':
        return kNeonPink;
      case 'normal':
        return kPrimaryBlue;
      default:
        return kTextSecondary;
    }
  }

  IconData get _icon {
    switch (widget.notification.priority) {
      case 'high':
        return Icons.campaign_rounded;
      case 'normal':
        return Icons.info_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final isHigh = n.priority == 'high';

    return AnimatedBuilder(
      animation: _fadeSlide,
      builder: (_, child) => Opacity(
        opacity: _fadeSlide.value,
        child: Transform.translate(
          offset: Offset(0, -20 * (1 - _fadeSlide.value)),
          child: child,
        ),
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 32, top: 32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            decoration: BoxDecoration(
              color: const Color(0xDD0A0A14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _accent.withAlpha(isHigh ? 100 : 50),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: _accent.withAlpha(isHigh ? 30 : 12),
                  blurRadius: isHigh ? 20 : 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Accent strip
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_accent, _accent.withAlpha(60)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _NotificationIcon(
                                icon: _icon,
                                color: _accent,
                                pulse: isHigh,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  n.title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isHigh ? 17 : 15,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (n.message.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.only(left: 34),
                              child: Text(
                                n.message,
                                style: TextStyle(
                                  color: Colors.white.withAlpha(190),
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final bool pulse;
  const _NotificationIcon({
    required this.icon,
    required this.color,
    required this.pulse,
  });

  @override
  State<_NotificationIcon> createState() => _NotificationIconState();
}

class _NotificationIconState extends State<_NotificationIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    if (widget.pulse) {
      _pulseCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    if (widget.pulse) _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pulse) {
      return AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, child) {
          final glowAlpha = (20 + 15 * _pulseCtrl.value).toInt();
          return Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withAlpha(glowAlpha),
            ),
            child: Icon(widget.icon, color: widget.color, size: 16),
          );
        },
      );
    }
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.color.withAlpha(25),
      ),
      child: Icon(widget.icon, color: widget.color, size: 16),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Time Warning — modern pill card, top-right
// ═════════════════════════════════════════════════════════════════
class _TimeWarning extends StatefulWidget {
  final String text;
  const _TimeWarning({required this.text});

  @override
  State<_TimeWarning> createState() => _TimeWarningState();
}

class _TimeWarningState extends State<_TimeWarning>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeAnim;
  late AnimationController _pulseAnim;
  late Animation<double> _fadeSlide;

  bool get _isUrgent {
    // Deteksi detik (< 60 detik = urgent)
    final digits = RegExp(r'\d+').allMatches(widget.text).toList();
    if (digits.length >= 2) {
      // Format "Sisa X mnt Y dtk"
      return true; // dalam mode detik = urgent
    }
    if (widget.text.contains('detik')) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    _fadeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeSlide = CurvedAnimation(parent: _fadeAnim, curve: Curves.easeOutCubic);

    if (_isUrgent) {
      _pulseAnim = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _fadeAnim.dispose();
    if (_isUrgent) _pulseAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urgent = _isUrgent;
    final accent = urgent ? kErrorColor : kWarningColor;
    final gradientColors = urgent
        ? [const Color(0xCC1A0000), const Color(0xCC0A0000)]
        : [const Color(0xCC1A1800), const Color(0xCC0A0800)];

    final pulseVal = urgent && _pulseAnim.isAnimating
        ? 1.0 + math.sin(_pulseAnim.value * math.pi * 2) * 0.06
        : 1.0;

    return AnimatedBuilder(
      animation: Listenable.merge(
          [_fadeAnim, if (urgent) _pulseAnim else _fadeAnim]),
      builder: (_, child) => Opacity(
        opacity: _fadeSlide.value,
        child: Transform.translate(
          offset: Offset(0, -20 * (1 - _fadeSlide.value)),
          child: Transform.scale(
            scale: pulseVal,
            child: child,
          ),
        ),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 32, top: 32),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: accent.withAlpha(urgent ? 120 : 70),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withAlpha(urgent ? 50 : 20),
                  blurRadius: urgent ? 24 : 16,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    urgent ? Icons.hourglass_bottom_rounded : Icons.timer_rounded,
                    color: accent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.text.toUpperCase(),
                    style: TextStyle(
                      color: accent,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}