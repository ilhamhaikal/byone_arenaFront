/// Conditional export:
/// - Web → device_info_stub.dart (tidak pakai dart:io)
/// - Native → device_info_real.dart (pakai dart:io NetworkInterface)
export 'device_info_stub.dart' if (dart.library.io) 'device_info_real.dart';
