import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/brand_config.dart';
import '../../models/tv_notification_model.dart';
import '../../providers/client_provider.dart';
import '../../services/native_overlay_service.dart';
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

  // ── Local remaining-time tracker (clock-sync safe) ─────────────────
  // JANGAN hitung sisa waktu dari endScheduledAt.difference(DateTime.now())
  // karena jam device client bisa TIDAK SINKRON dengan server (beda 17 jam!).
  // Sebagai gantinya, pakai remainingMinutes dari backend sebagai seed,
  // lalu hitung mundur secara lokal dengan stopwatch relatif.
  int _localRemainingSeconds = -1;
  DateTime _localRemainingUpdatedAt = DateTime.now();

  // ── Waktu Habis → auto kembali ke Idle Screensaver setelah beberapa saat ──
  // Tidak menunggu backend benar-benar mengakhiri sesi (bisa sampai 30 detik);
  // begitu waktu habis tampil, cukup beberapa detik lalu client kembali idle.
  static const _overtimeDisplayDuration = Duration(seconds: 8);
  Timer? _overtimeAutoIdleTimer;
  bool _forceIdleAfterOvertime = false;

  // ── Overlay native (docs/jawaban.md) ────────────────────────────────
  // Saat state == active, Client TIDAK BOLEH fullscreen. Badge kecil
  // (LIVE/sisa waktu/warning) digambar native (WindowManager overlay) di
  // atas app lain, sementara Activity Flutter di-background-kan supaya
  // Game/YouTube/Launcher yang sedang dipakai pemain kembali terlihat.
  bool _overlayStarted = false;
  // Guard supaya _activateNativeOverlay tidak dipanggil bertumpuk saat
  // di-retry dari _onTick (root cause bug warning "kadang muncul kadang
  // tidak" — lihat komentar di _activateNativeOverlay).
  bool _activatingOverlay = false;

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
    if (_overlayStarted) {
      NativeOverlayService.stop();
    }
    super.dispose();
  }

  /// Trigger crossfade saat state berubah
  void _onStateChanged(ClientDisplayState newState) {
    if (newState == _prevState) return;
    final oldState = _prevState;
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

    // Reset flag overlay setiap kali MASUK state active — supaya overlay
    // di-start ulang untuk setiap sesi baru (mencegah carry-over flag
    // dari sesi sebelumnya yang bisa menyebabkan NativeOverlayService.update
    // di-skip karena _overlayStarted tidak sinkron dengan kondisi native).
    if (newState == ClientDisplayState.active) {
      _overlayStarted = false;
      _activateNativeOverlay();
    } else if (oldState == ClientDisplayState.active) {
      _deactivateNativeOverlay();
    }
  }

  /// Mulai overlay native & background-kan Activity supaya tampilan asli
  /// (game/YouTube/launcher) kembali terlihat. Badge "LIVE" default
  /// tersembunyi (baru dimunculkan lewat [_onTick] saat warning aktif).
  /// Notifikasi promo yang sedang tampil (kalau ada) langsung di-passthrough
  /// juga, karena `_NotificationOverlay` Flutter tidak lagi terlihat selama
  /// Activity di-background. Kalau permission overlay belum diberikan
  /// (atau bukan Android TV), gagal senyap — body 'active' tetap fallback
  /// ke [SizedBox.expand] (blank).
  ///
  /// PENTING (root cause bug "warning kadang muncul kadang tidak"):
  /// `requestOverlayPermission` di sisi native (MainActivity.kt) membuka
  /// layar Settings SECARA ASYNC lalu langsung mengembalikan status
  /// `canDrawOverlays()` saat itu juga — hampir pasti masih `false` karena
  /// user belum sempat menyetujui. Kalau method ini cuma dipanggil SEKALI
  /// (saat transisi ke `active`) dan gagal, overlay TIDAK PERNAH retry lagi
  /// untuk sesi itu → badge/warning tidak pernah tampil sampai sesi
  /// berikutnya. Makanya dipanggil ulang tiap tick dari [_onTick] selama
  /// `_overlayStarted` masih false (self-heal), dilindungi [_activatingOverlay]
  /// supaya tidak menumpuk pemanggilan bersamaan.
  Future<void> _activateNativeOverlay() async {
    if (!mounted || _activatingOverlay) return;
    _activatingOverlay = true;
    try {
      final p = context.read<ClientProvider>();
      final notif = p.currentNotification;
      final started = await NativeOverlayService.start(
        badgeVisible: false,
        notifTitle: notif?.title,
        notifMessage: notif?.message,
      );
      if (mounted) {
        _overlayStarted = started;
        if (started) setState(() {}); // trigger rebuild → _buildActiveFallback → SizedBox.expand
      }
    } finally {
      _activatingOverlay = false;
    }
  }

  /// Hentikan overlay native & bawa Activity kembali ke depan supaya layar
  /// fullscreen berikutnya (overtime/idle/maintenance) bisa langsung tampil.
  Future<void> _deactivateNativeOverlay() async {
    if (!_overlayStarted) return;
    _overlayStarted = false;
    await NativeOverlayService.stop();
    await NativeOverlayService.bringToFront();
  }

  void _onTick() {
    final p = context.read<ClientProvider>();

    // Cek overtime lokal dulu — supaya transisi active → overtime akurat
    // walau siklus poll HTTP (10 detik) belum lewat (lihat komentar di
    // ClientProvider.checkLocalOvertime).
    p.checkLocalOvertime();

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
          _localRemainingSeconds = -1;
        });
        _warningDismissTimer?.cancel();
      }
    }

    // Warning sisa waktu (hanya saat sesi aktif)
    if (p.state == ClientDisplayState.active) {
      final sess = p.activeSession;

      // ── CLOCK-SYNC SAFE dengan presisi detik ──────────────────
      //     Dua sumber: endScheduledAt (presisi detik, butuh jam sync)
      //     dan remainingMinutes (bulat menit, tidak butuh jam sync).
      //     Kalau jam device sync (selisih < 120s), pakai endScheduledAt
      //     untuk presisi penuh. Kalau tidak, fallback ke tracker lokal
      //     yang di-seed dari remainingMinutes backend.
      final serverRemainingMin = sess?.remainingMinutes;
      final int? effectiveRemainingSeconds;
      if (serverRemainingMin != null && serverRemainingMin >= 0) {
        final srvSec = serverRemainingMin * 60;
        final absSec = sess?.remaining?.inSeconds;
        // Deteksi: kalau selisih < 120 detik, clock device sync
        final bool clockOk =
            absSec != null && (absSec - srvSec).abs() < 120;

        if (clockOk) {
          // Jam sync → presisi detik penuh dari endScheduledAt
          effectiveRemainingSeconds = absSec!.clamp(0, 999999);
        } else {
          // Jam ngaco → tracker dari remainingMinutes backend
          if (srvSec != _localRemainingSeconds) {
            final oldSeed = _localRemainingSeconds;
            _localRemainingSeconds = srvSec;
            _localRemainingUpdatedAt = DateTime.now();
            if (oldSeed == -1 || srvSec > oldSeed) {
              _warningDismissed = false;
              _warningText = null;
              _warningDismissTimer?.cancel();
            }
          }
          final elapsed =
              DateTime.now().difference(_localRemainingUpdatedAt).inSeconds;
          effectiveRemainingSeconds =
              (_localRemainingSeconds - elapsed).clamp(0, 999999);
        }
      } else {
        // Fallback ke perhitungan absolut (kalau backend tidak kirim
        // remainingMinutes — seharusnya tidak terjadi).
        effectiveRemainingSeconds = sess?.remaining?.inSeconds;
      }

      if (effectiveRemainingSeconds != null) {
        _updateWarning(effectiveRemainingSeconds);
      }

      // Self-heal: kalau overlay native belum berhasil aktif (mis. saat
      // transisi awal ke active, permission belum sempat di-approve user),
      // coba lagi tiap detik sampai berhasil — supaya badge/warning tidak
      // "hilang permanen" untuk sisa sesi ini.
      // Juga sinkronkan flag: kadang NativeOverlayService._overlayActive
      // bisa true (overlay masih jalan dari sesi sebelumnya) sementara
      // _overlayStarted di widget masih false (baru di-reset di atas).
      if (!_overlayStarted) {
        if (NativeOverlayService.isActive) {
          _overlayStarted = true;
        } else {
          unawaited(_activateNativeOverlay());
        }
      }

      // SELALU update overlay native — tanpa guard _overlayStarted.
      // NativeOverlayService.update sudah punya guard internal
      // (!_overlayActive -> return). Kalau overlay-nya mati, update
      // ini silent no-op; kalau hidup, badge akan tampil.
      // Ini critical fix: sebelumnya update cuma dipanggil kalau
      // _overlayStarted == true, padahal flag itu bisa stale (overlay
      // hidup tapi flag false karena di-reset di _onStateChanged).
      {
        String variant = 'live';
        if (effectiveRemainingSeconds != null && effectiveRemainingSeconds <= 10) {
          variant = 'danger';
        } else if (effectiveRemainingSeconds != null && effectiveRemainingSeconds <= 300) {
          variant = 'warning';
        }
        final notif = p.currentNotification;
        NativeOverlayService.update(
          badgeVisible: _warningText != null,
          badgeTitle: 'LIVE',
          badgeSubtitle: _warningText ?? '',
          badgeVariant: variant,
          notifTitle: notif?.title,
          notifMessage: notif?.message,
        );
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
          // Tidak ada sesi aktif & screenStatus == off → Idle Screensaver
          // (promosi). Kalau screenStatus == on tanpa sesi, lihat cabang
          // 'unauthorized' di bawah — itu BUKAN idle.
          stateKey = 'idle';
          body = _buildIdle(p);
        } else if (p.state == ClientDisplayState.unauthorized) {
          // TV dinyalakan manual (wake/live) TANPA sesi rental aktif.
          stateKey = 'unauthorized';
          body = _buildUnauthorized(p);
        } else if (isOvertime) {
          stateKey = 'overtime';
          body = _buildScreenSaver(p);
        } else {
          stateKey = 'active';
          // ── Fallback: kalau overlay native tidak aktif, Flutter UI
          //     TIDAK di-background-kan (moveTaskToBack tidak dipanggil
          //     karena startOverlay gagal/tidak ada permission). Dalam
          //     kasus ini kita TIDAK bisa cuma tampil SizedBox.expand kosong
          //     — warning harus tetap terlihat lewat widget Flutter.
          //     Sebaliknya, kalau overlay native AKTIF, Flutter UI sudah
          //     di-background dan native badge OverlayService yang menggambar
          //     warning — jadi SizedBox.expand aman (tidak akan terlihat).
          body = _overlayStarted
              ? const SizedBox.expand()
              : _buildActiveFallback(p);
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
  // ACTIVE FALLBACK — ditampilkan HANYA saat overlay native GAGAL aktif.
  // (Kalau overlay native berhasil, Flutter UI sudah di-background-kan
  // via moveTaskToBack dan layar ini TIDAK akan terlihat — digantikan
  // badge kecil native OverlayService di atas Game/YouTube/Launcher.)
  //
  // Root cause fix: sebelumnya active state selalu render SizedBox.expand
  // kosong. Kalau overlay native gagal (no permission / bukan Android),
  // user melihat layar hitam tanpa informasi apa pun — termasuk warning
  // sisa waktu yang seharusnya muncul. Dengan fallback ini, warning TETAP
  // terlihat lewat Flutter UI meskipun overlay native tidak tersedia.
  // ═════════════════════════════════════════════════════════════════
  Widget _buildActiveFallback(ClientProvider p) {
    final console = p.console;
    final session = p.activeSession;
    final remaining = session?.remaining;
    final remainingMin = remaining?.inMinutes;
    final remainingSec = remaining?.inSeconds.remainder(60);

    return Scaffold(
      backgroundColor: kDeepBlack,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Latar belakang transparan — biarkan konten di belakang
          // sedikit terlihat (kalau ada). Kalau Activity belum di-
          // background-kan (karena overlay gagal), ini akan jadi
          // layar hitam penuh — lebih baik daripada kosong total.
          Container(color: kDeepBlack.withValues(alpha: 0.92)),
          // Informasi sesi aktif — tengah layar, besar, jelas terlihat
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Indikator LIVE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 10, color: Color(0xFF22C55E)),
                      SizedBox(width: 10),
                      Text('LIVE', style: TextStyle(
                        color: Color(0xFF22C55E),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (console != null)
                  Text(console.name,
                    style: const TextStyle(
                      fontSize: 18, color: kTextSecondary,
                    ),
                  ),
                if (remainingMin != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${remainingMin}m ${remainingSec.toString().padLeft(2, '0')}s',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      color: kTextPrimary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('sisa waktu',
                    style: TextStyle(fontSize: 12, color: kTextSecondary),
                  ),
                ],
                const SizedBox(height: 28),
                const Text('Sesi sedang berjalan',
                  style: TextStyle(fontSize: 13, color: kTextSecondary),
                ),
              ],
            ),
          ),
          // ── Warning overlay (posisi sama dengan mode normal) ──────
          if (_warningText != null)
            Positioned(
              top: 32,
              right: 32,
              child: _TimeWarning(text: _warningText!),
            ),
          // ── Notifikasi promo ──────────────────────────────────────
          if (p.currentNotification != null)
            _NotificationOverlay(notification: p.currentNotification!),
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
  // UNAUTHORIZED — TV dinyalakan manual (wake/live) TANPA sesi rental.
  // Beda dengan Idle: ini kondisi yang perlu perhatian admin (potensi
  // pemakaian tidak sah), jadi TIDAK boleh tampil seperti screensaver
  // promosi biasa.
  // ═════════════════════════════════════════════════════════════════
  Widget _buildUnauthorized(ClientProvider p) {
    final c = p.console;
    return Scaffold(
      backgroundColor: const Color(0xFF1A1200),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 64, color: kWarningColor),
            const SizedBox(height: 20),
            const Text('BELUM ADA SESI',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: kWarningColor,
                    letterSpacing: 4)),
            const SizedBox(height: 10),
            if (c != null)
              Text(c.name,
                  style: const TextStyle(
                      fontSize: 16, color: kTextSecondary)),
            const SizedBox(height: 12),
            const Text('Silakan hubungi admin untuk memulai sesi rental',
                style: TextStyle(color: kTextSecondary, fontSize: 12)),
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