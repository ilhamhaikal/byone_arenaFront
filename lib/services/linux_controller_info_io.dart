import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../models/controller_event.dart';

/// Info controller dari sysfs Linux.
///
/// Plugin `gamepads` hanya memberi nama + VID/PID. Untuk DualShock 4 yang
/// dicolok lewat kabel, Linux tetap menamai perangkat "Wireless Controller",
/// sehingga tanpa sysfs aplikasi salah menyimpulkan transport sebagai
/// Bluetooth. Sysfs juga menyediakan baterai controller
/// (`ps-controller-battery-<MAC>`).
class LinuxControllerBattery {
  final int? level;
  final bool charging;

  const LinuxControllerBattery({this.level, this.charging = false});
}

class LinuxControllerInfo {
  final String jsName;
  final String? name;
  final int vendorId;
  final int productId;
  final ControllerTransport transport;
  final String? uniq;
  final int? batteryLevel;
  final bool charging;

  /// Path `/dev/input/eventX` untuk klik touchpad (jika ada).
  final String? touchpadEventPath;

  const LinuxControllerInfo({
    required this.jsName,
    this.name,
    this.vendorId = 0,
    this.productId = 0,
    this.transport = ControllerTransport.unknown,
    this.uniq,
    this.batteryLevel,
    this.charging = false,
    this.touchpadEventPath,
  });

  /// Baca info dari `/sys/class/input/<js>/device`.
  ///
  /// [gamepadId] dari plugin Linux berbentuk `/dev/input/js0`.
  static Future<LinuxControllerInfo?> forGamepad(String gamepadId) async {
    if (!Platform.isLinux) return null;

    final jsName = gamepadId.split('/').last;
    if (!jsName.startsWith('js')) return null;

    final base = '/sys/class/input/$jsName/device';
    final busType = await _readHex('$base/id/bustype');
    final vendorId = await _readHex('$base/id/vendor');
    final productId = await _readHex('$base/id/product');
    final name = await _readString('$base/name');
    final uniq = await _readString('$base/uniq');

    final battery = await readBatteryForUniq(uniq);
    final touchpadPath = await findTouchpadEvent(uniq);

    return LinuxControllerInfo(
      jsName: jsName,
      name: name,
      vendorId: vendorId,
      productId: productId,
      transport: _transportFromBus(busType),
      uniq: (uniq == null || uniq.isEmpty) ? null : uniq,
      batteryLevel: battery?.level,
      charging: battery?.charging ?? false,
      touchpadEventPath: touchpadPath,
    );
  }

  /// Baca level baterai controller berdasarkan MAC/uniq dari sysfs.
  ///
  /// DualShock 4 (driver hid-playstation) mengekspos:
  /// `/sys/class/power_supply/ps-controller-battery-<MAC>`.
  static Future<LinuxControllerBattery?> readBatteryForUniq(
      String? uniq) async {
    if (!Platform.isLinux || uniq == null || uniq.isEmpty) return null;

    final base = '/sys/class/power_supply/ps-controller-battery-$uniq';
    final capacityRaw = await _readString('$base/capacity');
    if (capacityRaw == null || capacityRaw.isEmpty) return null;

    final level = int.tryParse(capacityRaw);
    if (level == null) return null;

    final status = (await _readString('$base/status')) ?? '';
    return LinuxControllerBattery(
      level: level.clamp(0, 100),
      charging: status.toLowerCase() == 'charging',
    );
  }

  /// Cari event device touchpad DS4 (nama mengandung "Touchpad" dan uniq sama).
  static Future<String?> findTouchpadEvent(String? uniq) async {
    if (!Platform.isLinux || uniq == null || uniq.isEmpty) return null;
    try {
      final entries = await Directory('/sys/class/input').list().toList();
      for (final entry in entries) {
        final name = entry.path.split('/').last;
        if (!name.startsWith('event')) continue;
        final dev = '${entry.path}/device';
        final devName = (await _readString('$dev/name')) ?? '';
        if (!devName.toLowerCase().contains('touchpad')) continue;
        final devUniq = await _readString('$dev/uniq');
        if (devUniq == uniq) return '/dev/input/$name';
      }
    } catch (_) {
      // Sysfs tidak tersedia / akses ditolak.
    }
    return null;
  }

  static ControllerTransport _transportFromBus(int busType) {
    switch (busType) {
      case 0x0003: // BUS_USB
        return ControllerTransport.usb;
      case 0x0005: // BUS_BLUETOOTH
        return ControllerTransport.bluetooth;
      default:
        return ControllerTransport.unknown;
    }
  }

  static Future<String?> _readString(String path) async {
    try {
      final value = await File(path).readAsString();
      return value.trim();
    } catch (_) {
      return null;
    }
  }

  static Future<int> _readHex(String path) async {
    final value = await _readString(path);
    if (value == null || value.isEmpty) return 0;
    return int.tryParse(value, radix: 16) ?? 0;
  }
}

/// Membaca klik touchpad DS4 dari event device evdev.
///
/// Touchpad DS4 bukan bagian dari `js0`; kliknya muncul sebagai tombol kiri
/// mouse (`BTN_LEFT`) pada event device terpisah (mis. `/dev/input/event21`).
class LinuxTouchpadWatcher {
  Process? _process;
  StreamSubscription<List<int>>? _sub;
  final List<int> _buffer = [];
  bool _running = false;

  void start(String eventPath, void Function(bool pressed) onButton) {
    stop();
    _running = true;
    Process.start('cat', [eventPath]).then((proc) {
      if (!_running) {
        proc.kill();
        return;
      }
      _process = proc;
      _sub = proc.stdout.listen((chunk) {
        _buffer.addAll(chunk);
        // struct input_event 64-bit = 24 byte: timeval(16) + type(2) +
        // code(2) + value(4).
        while (_buffer.length >= 24) {
          final bytes = _buffer.sublist(0, 24);
          _buffer.removeRange(0, 24);
          final data = ByteData.sublistView(Uint8List.fromList(bytes));
          final type = data.getUint16(16, Endian.host);
          final code = data.getUint16(18, Endian.host);
          final value = data.getInt32(20, Endian.host);
          if (type == 0x01 && code == 0x110) {
            onButton(value != 0);
          }
        }
      });
    }).catchError((_) {
      // `cat` gagal / perangkat tidak bisa dibuka.
    });
  }

  void stop() {
    _running = false;
    _sub?.cancel();
    _sub = null;
    _process?.kill();
    _process = null;
    _buffer.clear();
  }
}
