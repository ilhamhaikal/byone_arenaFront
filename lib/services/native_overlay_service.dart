import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridge ke overlay native Android (WindowManager + Foreground Service,
/// lihat `OverlayService.kt`).
///
/// Dipakai HANYA saat state Client == Active (docs/jawaban.md): Client tidak
/// boleh fullscreen/menutupi layar saat console sedang dipakai pemain. Badge
/// kecil ("LIVE" + sisa waktu/warning) digambar native di atas app lain
/// (Game/YouTube/Launcher), sementara `MainActivity` di-background-kan
/// (moveTaskToBack) supaya tampilan yang sedang dipakai pemain kembali
/// terlihat & bisa disentuh/di-remote.
///
/// Semua pemanggilan aman dipanggil dari platform non-Android (mis. saat
/// development di web/desktop) — akan gagal senyap dan caller harus
/// fallback ke tampilan blank biasa berdasarkan nilai return.
class NativeOverlayService {
  NativeOverlayService._();

  static const MethodChannel _channel = MethodChannel('byone/device');

  static bool _permissionChecked = false;
  static bool _hasPermission = false;
  static bool _overlayActive = false;

  static bool get isActive => _overlayActive;

  static Future<bool> isAndroidTV() async {
    try {
      return await _channel.invokeMethod<bool>('isAndroidTV') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Cek (dan kalau perlu minta) izin "draw over other apps". Hasil
  /// di-cache selama proses app masih hidup supaya tidak berulang kali
  /// membuka layar Settings tiap kali state berubah ke active.
  static Future<bool> ensurePermission() async {
    if (_permissionChecked && _hasPermission) return true;
    try {
      _hasPermission =
          await _channel.invokeMethod<bool>('hasOverlayPermission') ?? false;
      if (!_hasPermission) {
        _hasPermission =
            await _channel.invokeMethod<bool>('requestOverlayPermission') ??
                false;
      }
    } catch (e) {
      debugPrint('NativeOverlayService.ensurePermission error: $e');
      _hasPermission = false;
    }
    _permissionChecked = true;
    return _hasPermission;
  }

  /// Mulai overlay native + background-kan Activity Flutter. Return `false`
  /// kalau permission belum diberikan — caller HARUS fallback ke tampilan
  /// blank/biasa (jangan background-kan Activity tanpa overlay, nanti
  /// benar-benar tidak ada apa pun yang tampil).
  static Future<bool> start({
    required String title,
    String subtitle = '',
    String variant = 'live',
  }) async {
    final granted = await ensurePermission();
    if (!granted) {
      _overlayActive = false;
      return false;
    }
    try {
      final ok = await _channel.invokeMethod<bool>('startOverlay', {
            'title': title,
            'subtitle': subtitle,
            'variant': variant,
          }) ??
          false;
      _overlayActive = ok;
      return ok;
    } catch (e) {
      debugPrint('NativeOverlayService.start error: $e');
      _overlayActive = false;
      return false;
    }
  }

  /// Perbarui teks/warna badge overlay yang sedang tampil (dipanggil tiap
  /// detik dari ticker UI selama state == active).
  static Future<void> update({
    required String title,
    String subtitle = '',
    String variant = 'live',
  }) async {
    if (!_overlayActive) return;
    try {
      await _channel.invokeMethod('updateOverlay', {
        'title': title,
        'subtitle': subtitle,
        'variant': variant,
      });
    } catch (e) {
      debugPrint('NativeOverlayService.update error: $e');
    }
  }

  /// Hentikan overlay & foreground service terkait. Dipanggil setiap kali
  /// state keluar dari active (overtime/idle/maintenance).
  static Future<void> stop() async {
    if (!_overlayActive) return;
    _overlayActive = false;
    try {
      await _channel.invokeMethod('stopOverlay');
    } catch (e) {
      debugPrint('NativeOverlayService.stop error: $e');
    }
  }

  /// Bawa kembali MainActivity ke foreground (dipakai bersamaan dengan
  /// [stop] saat state active berakhir, supaya layar fullscreen berikutnya
  /// — overtime/idle/maintenance — bisa langsung tampil).
  static Future<void> bringToFront() async {
    try {
      await _channel.invokeMethod('bringToFront');
    } catch (e) {
      debugPrint('NativeOverlayService.bringToFront error: $e');
    }
  }
}
