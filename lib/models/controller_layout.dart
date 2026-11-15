import 'dart:ui';

import 'controller_event.dart';

/// Susunan geometri satu model controller dalam satuan viewBox.
///
/// Semua widget (SVG statis + overlay animasi) memakai koordinat yang sama,
/// sehingga menambah model baru cukup menambah layout + asset.
class ControllerLayout {
  final Size viewBox;

  /// Geometri tombol yang bisa menyala (termasuk D-Pad, L1/R1, L2/R2, dll).
  final Map<String, ControlGeometry> controls;

  /// Posisi pusat analog & jarak gerak knob.
  final Offset leftStick;
  final Offset rightStick;
  final double stickTravel;
  final double knobRadius;

  /// Area tekanan trigger (untuk indikator isi saat ditekan).
  final Rect l2Area;
  final Rect r2Area;

  final Rect touchpadArea;
  final Rect lightBarArea;

  const ControllerLayout({
    required this.viewBox,
    required this.controls,
    required this.leftStick,
    required this.rightStick,
    required this.stickTravel,
    required this.knobRadius,
    required this.l2Area,
    required this.r2Area,
    required this.touchpadArea,
    required this.lightBarArea,
  });

  ControlGeometry? operator [](String id) => controls[id];
}