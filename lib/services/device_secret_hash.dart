import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Hash SHA-256 (hex lowercase) yang dikirim TV saat announce.
/// Harus sama dengan format yang diharapkan backend (`pkg/deviceauth`).
String hashDeviceSecret(String secret) {
  return sha256.convert(utf8.encode(secret)).toString();
}
