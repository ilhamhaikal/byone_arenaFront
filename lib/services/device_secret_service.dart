import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'device_secret_hash.dart';

/// Secret perangkat TV. Disimpan di secure storage/Android Keystore, bukan
/// SharedPreferences. Server hanya menerima hash SHA-256 saat announce.
class DeviceSecretService {
  DeviceSecretService._();

  static const String _key = 'tv_device_secret';
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static String? _cached;

  static Future<String> getOrCreateSecret() async {
    if (_cached != null) return _cached!;
    _cached = await _storage.read(key: _key);
    if (_cached == null || _cached!.isEmpty) {
      final random = Random.secure();
      final bytes = List<int>.generate(32, (_) => random.nextInt(256));
      _cached = base64UrlEncode(bytes).replaceAll('=', '');
      await _storage.write(key: _key, value: _cached);
    }
    return _cached!;
  }

  static Future<String> getSecretHash() async {
    final secret = await getOrCreateSecret();
    return hashDeviceSecret(secret);
  }

  /// Dipakai saat server meminta pairing ulang (secret lama tidak valid).
  static Future<void> reset() async {
    _cached = null;
    await _storage.delete(key: _key);
  }
}
