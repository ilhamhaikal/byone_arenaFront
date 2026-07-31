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
}