import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/brand_config.dart';
import '../../models/tv_notification_model.dart';
import '../../providers/client_provider.dart';
import '../../widgets/idle_screensaver.dart';

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
  String? _warningText;
  bool _warningDismissed = false;
  int _lastRemainingSeconds = -1;

  // ── Waktu Habis → auto kembali ke Idle Screensaver setelah beberapa saat ──
  // Tidak menunggu backend benar-benar mengakhiri sesi (bisa sampai 30 detik);
  // begitu waktu habis tampil, cukup beberapa detik lalu client kembali idle.
  static const _overtimeDisplayDuration = Duration(seconds: 8);
  Timer? _overtimeAutoIdleTimer;
  bool _forceIdleAfterOvertime = false;

  // ── State transition ──────────────────────────────────────────────────
  ClientDisplayState _prevState = ClientDisplayState.loading;
  late final AnimationController _transCtrl;
  late final Animation<double> _transFade;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientProvider>().startPolling(interval: 10);
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _onTick();
    });

    // Transisi crossfade antar state (800ms)
    _transCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _transFade = CurvedAnimation(parent: _transCtrl, curve: Curves.easeInOut);
    _transCtrl.value = 1.0;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _notifTimer?.cancel();
    _warningDismissTimer?.cancel();
    _overtimeAutoIdleTimer?.cancel();
    _transCtrl.dispose();
    super.dispose();
  }

  /// Trigger crossfade saat state berubah
  void _onStateChanged(ClientDisplayState newState) {
    if (newState == _prevState) return;
    _prevState = newState;
    _transCtrl.forward(from: 0);

    if (newState == ClientDisplayState.overtime) {
      // Baru masuk "waktu habis" — tampilkan sebentar, lalu paksa kembali idle
      // di sisi client tanpa menunggu backend mengakhiri sesi.
      _overtimeAutoIdleTimer?.cancel();
      _forceIdleAfterOvertime = false;
      _overtimeAutoIdleTimer = Timer(_overtimeDisplayDuration, () {
        if (mounted) setState(() => _forceIdleAfterOvertime = true);
      });
    } else {
      _overtimeAutoIdleTimer?.cancel();
      _forceIdleAfterOvertime = false;
    }
  }

  void _onTick() {
    final p = context.read<ClientProvider>();
    final currentState = p.state;

    // Deteksi perubahan state → trigger crossfade
    if (currentState != _prevState) {
      _onStateChanged(currentState);
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
        final isOvertime = p.state == ClientDisplayState.overtime;

        // Build body sesuai state
        final Widget body;
        final String stateKey;

        if (p.state == ClientDisplayState.maintenance) {
          stateKey = 'maintenance';
          body = _buildMaintenance(p);
        } else if (p.state == ClientDisplayState.loading ||
            p.state == ClientDisplayState.notFound) {
          stateKey = 'status';
          body = _buildStatus(p);
        } else if (p.state == ClientDisplayState.idle ||
            (isOvertime && _forceIdleAfterOvertime)) {
          final isTvOn = p.console?.screenStatus == 'on';
          stateKey = isTvOn ? 'live' : 'idle';
          body = isTvOn ? _buildTvLive(p) : _buildIdle(p);
        } else if (isOvertime) {
          stateKey = 'overtime';
          body = _buildScreenSaver(p);
        } else {
          stateKey = 'active';
          body = const SizedBox.expand();
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            // ── Animated body crossfade ──────────────────────────────
            AnimatedBuilder(
              animation: _transFade,
              builder: (_, child) => Opacity(opacity: _transFade.value, child: child),
              child: KeyedSubtree(key: ValueKey(stateKey), child: body),
            ),
            // ── System indicator ─────────────────────────────────────
            const Positioned(
              bottom: 10,
              right: 12,
              child: _SystemIndicator(),
            ),
            // ── Warning overlay ──────────────────────────────────────
            if (_warningText != null)
              Positioned(
                top: 32,
                right: 32,
                child: _TimeWarning(text: _warningText!),
              ),
            // ── Notification overlay ─────────────────────────────────
            if (p.currentNotification != null)
              _NotificationOverlay(notification: p.currentNotification!),
          ],
        );
      },
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // SCREEN SAVER — overtime (WAKTU HABIS)
  // ═════════════════════════════════════════════════════════════════
  Widget _buildScreenSaver(ClientProvider p) {
    return Scaffold(
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
  // TV LIVE — TV menyala, belum ada sesi → transparan + info kecil
  // ═════════════════════════════════════════════════════════════════
  Widget _buildTvLive(ClientProvider p) {
    return const SizedBox.expand(); // TV feed terlihat penuh (transparan)
  }

  // ═════════════════════════════════════════════════════════════════
  // IDLE — Premium Screensaver dengan animasi logo (TV OFF)
  // ═════════════════════════════════════════════════════════════════
  Widget _buildIdle(ClientProvider p) {
    final c = p.console!;
    return IdleScreensaver(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Logo
              const _AnimatedLogo(),
              const SizedBox(height: 28),
              // Brand text with glow
              const _BrandText(),
              const SizedBox(height: 12),
              const Text(
                BrandConfig.shortTagline,
                style: TextStyle(
                  color: kTextSecondary,
                  fontSize: 13,
                  letterSpacing: 3.5,
                ),
              ),
              const SizedBox(height: 36),
              // Console status card
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: kCardColor.withAlpha(180),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: kBorderColor.withAlpha(120),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryBlue.withAlpha(10),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(c.name,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: kTextPrimary)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kSuccessColor,
                            boxShadow: [
                              BoxShadow(
                                  color: kSuccessColor.withAlpha(120),
                                  blurRadius: 8),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Tersedia — Hubungi Admin',
                            style: TextStyle(
                                color: kTextSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
    with TickerProviderStateMixin {
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
    with TickerProviderStateMixin {
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
    with TickerProviderStateMixin {
  late AnimationController _fadeAnim;
  AnimationController? _pulseAnim;
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
    _pulseAnim?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urgent = _isUrgent;
    final accent = urgent ? kErrorColor : kWarningColor;
    final gradientColors = urgent
        ? [const Color(0xCC1A0000), const Color(0xCC0A0000)]
        : [const Color(0xCC1A1800), const Color(0xCC0A0800)];

    final pulseVal = urgent && _pulseAnim != null && _pulseAnim!.isAnimating
        ? 1.0 + math.sin(_pulseAnim!.value * math.pi * 2) * 0.06
        : 1.0;

    final anims = <Animation<double>>[_fadeAnim];
    if (urgent && _pulseAnim != null) anims.add(_pulseAnim!);

    return AnimatedBuilder(
      animation: Listenable.merge(anims),
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

// ═════════════════════════════════════════════════════════════════
// System Indicator — always-on badge pojok kanan bawah
// Memastikan HDMI & sistem berjalan, tidak memblokir tampilan
// ═════════════════════════════════════════════════════════════════
class _SystemIndicator extends StatefulWidget {
  const _SystemIndicator();

  @override
  State<_SystemIndicator> createState() => _SystemIndicatorState();
}

class _SystemIndicatorState extends State<_SystemIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _timeCtrl;
  String _timeStr = '';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _updateTime();
    _timeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _timeCtrl.addListener(_updateTime);
  }

  void _updateTime() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    final newTime = '$h:$m:$s';
    if (newTime != _timeStr && mounted) {
      setState(() => _timeStr = newTime);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _timeCtrl.removeListener(_updateTime);
    _timeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, child) {
        final dotAlpha = (80 + 40 * _pulseCtrl.value).toInt();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0x8005050A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0x20FFFFFF),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing green dot — sistem hidup
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kSuccessColor.withAlpha(dotAlpha),
                  boxShadow: [
                    BoxShadow(
                      color: kSuccessColor.withAlpha(dotAlpha ~/ 2),
                      blurRadius: 3,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              // Brand text
              const Text(
                'BYONE',
                style: TextStyle(
                  color: Color(0xAAFFFFFF),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 6),
              // Separator
              Container(
                width: 1,
                height: 10,
                color: const Color(0x20FFFFFF),
              ),
              const SizedBox(width: 6),
              // Live clock
              Text(
                _timeStr,
                style: const TextStyle(
                  color: Color(0x88FFFFFF),
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// ANIMATED LOGO — rotating gradient ring + pulse + orbit particles
// ═════════════════════════════════════════════════════════════════════
class _AnimatedLogo extends StatefulWidget {
  const _AnimatedLogo();

  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with TickerProviderStateMixin {
  late final AnimationController _rotCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _rotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotCtrl, _pulseCtrl]),
        builder: (_, __) => CustomPaint(
          painter: _LogoRingPainter(
            rotation: _rotCtrl.value * 2 * 3.14159,
            pulse: _pulseCtrl.value,
          ),
          child: Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kDeepBlack,
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryBlue.withAlpha(40),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Image.asset(BrandConfig.logoAsset),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoRingPainter extends CustomPainter {
  final double rotation;
  final double pulse;

  _LogoRingPainter({required this.rotation, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2 - 4;
    final pulseRadius = radius + 2 + pulse * 6;

    // ── Outer pulse ring ───────────────────────────────────────────
    final pulsePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = SweepGradient(
        colors: [
          kPrimaryBlue.withAlpha(80),
          kAccentPurple.withAlpha(80),
          kNeonPink.withAlpha(80),
          kPrimaryBlue.withAlpha(80),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: pulseRadius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(cx, cy), pulseRadius, pulsePaint);

    // ── Main rotating gradient ring ──────────────────────────────────
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..shader = SweepGradient(
        startAngle: rotation,
        colors: const [
          kPrimaryBlue, kAccentPurple, kNeonPink,
          kPrimaryBlue, kAccentPurple, kNeonPink,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));

    // Glow layer
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..shader = SweepGradient(
        startAngle: rotation,
        colors: [
          kPrimaryBlue.withAlpha(40),
          kAccentPurple.withAlpha(40),
          kNeonPink.withAlpha(40),
          kPrimaryBlue.withAlpha(40),
          kAccentPurple.withAlpha(40),
          kNeonPink.withAlpha(40),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawCircle(Offset(cx, cy), radius, glowPaint);
    canvas.drawCircle(Offset(cx, cy), radius, ringPaint);

    // ── Inner ring ───────────────────────────────────────────────────
    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withAlpha(25);
    canvas.drawCircle(Offset(cx, cy), radius - 15, innerPaint);

    // ── Orbit particles (3 titik mengelilingi ring) ──────────────────
    for (int i = 0; i < 3; i++) {
      final angle = rotation + (3.14159 * 2 / 3) * i;
      final dx = cx + radius * 0.75 * math.cos(angle);
      final dy = cy + radius * 0.75 * math.sin(angle);
      final colors = [kPrimaryBlue, kAccentPurple, kNeonPink];

      // Small orbit dot
      canvas.drawCircle(Offset(dx, dy), 3.5,
        Paint()..color = colors[i].withAlpha(200));
      // Glow
      canvas.drawCircle(Offset(dx, dy), 8,
        Paint()
          ..shader = RadialGradient(colors: [
            colors[i].withAlpha(100), Colors.transparent,
          ]).createShader(Rect.fromCircle(
            center: Offset(dx, dy), radius: 8)));
    }
  }

  @override
  bool shouldRepaint(covariant _LogoRingPainter old) =>
      old.rotation != rotation || old.pulse != pulse;
}

// ═════════════════════════════════════════════════════════════════════
// BRAND TEXT — fade in + subtle glow pulse
// ═════════════════════════════════════════════════════════════════════
class _BrandText extends StatefulWidget {
  const _BrandText();

  @override
  State<_BrandText> createState() => _BrandTextState();
}

class _BrandTextState extends State<_BrandText>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _fade = Tween(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [kPrimaryBlue, kAccentPurple, kNeonPink],
        ).createShader(bounds),
        child: const Text(
          BrandConfig.appName,
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 7,
          ),
        ),
      ),
    );
  }
}