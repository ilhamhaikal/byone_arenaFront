import 'dart:io';

import 'package:flutter/services.dart';

class DeviceService {
  static const MethodChannel _channel =
      MethodChannel('byone/device');

  static Future<bool> isAndroidTV() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final bool? result =
          await _channel.invokeMethod<bool>('isAndroidTV');

      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Kirim app ke background TANPA menutupnya (dipakai tombol "LIVE"),
  /// supaya Android TV Launcher/HDMI/Netflix/dll bisa dipakai user sambil
  /// sesi rental tetap berjalan.
  static Future<void> moveToBackground() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('moveToBackground');
    } catch (_) {
      // Abaikan — best-effort.
    }
  }

  /// Paksa app kembali ke depan (dipakai saat sesi berakhir/di-stop admin).
  /// Best-effort: sejak Android 10 ada pembatasan start-activity-from-background.
  static Future<void> bringToForeground() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('bringToForeground');
    } catch (_) {
      // Abaikan — best-effort.
    }
  }
}