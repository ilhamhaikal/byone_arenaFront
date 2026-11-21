import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_ps/services/device_secret_hash.dart';

void main() {
  test('hash device secret memakai SHA-256 hex lowercase', () {
    expect(
      hashDeviceSecret('abc'),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });

  test('secret berbeda menghasilkan hash berbeda', () {
    expect(hashDeviceSecret('secret-a'), isNot(hashDeviceSecret('secret-b')));
  });
}
