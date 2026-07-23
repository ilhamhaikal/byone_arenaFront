import 'dart:io';

/// Native (Linux/Windows/macOS/Android/iOS) — gunakan dart:io NetworkInterface.
Future<String?> getDeviceIp() async {
  try {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    for (final interface in interfaces) {
      for (final addr in interface.addresses) {
        if (addr.address.isNotEmpty && !addr.address.startsWith('127.')) {
          return addr.address;
        }
      }
    }
  } catch (_) {}
  return null;
}
