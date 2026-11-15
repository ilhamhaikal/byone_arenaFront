import 'package:flutter/foundation.dart';

/// Feature flag: halaman Controller Health Check hanya tampil di debug atau
/// bila build eksplisit memakai `--dart-define=CONTROLLER_HEALTH=true`.
///
/// Build release biasa (produksi) tidak akan menampilkan menu ini.
const bool kControllerHealthEnabled =
    bool.fromEnvironment('CONTROLLER_HEALTH', defaultValue: kDebugMode);