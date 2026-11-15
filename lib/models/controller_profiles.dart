import 'dart:ui';

import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import 'controller_event.dart';
import 'controller_layout.dart';
import 'controller_profile.dart';

/// Registry profil controller.
///
/// Menambah PS3/PS5 nanti cukup menambah satu entri di sini + asset SVG +
/// layout. Halaman, provider, dan widget tidak perlu diubah.
class ControllerProfiles {
  ControllerProfiles._();

  static const ControllerProfile ds4 = ControllerProfile(
    id: 'ds4',
    family: 'PlayStation 4',
    displayName: 'DualShock 4',
    asset: 'assets/controller/ds4.svg',
    capabilities: ControllerCapabilities(
      battery: true,
      touchpad: true,
      lightBar: true,
      rumble: true,
      pressureTriggers: true,
      touchpadClick: true,
    ),
    requiredButtons: [
      'cross',
      'circle',
      'square',
      'triangle',
      'l1',
      'r1',
      'share',
      'options',
      'ps',
      'touchpad',
      'l3',
      'r3',
      'dpadUp',
      'dpadDown',
      'dpadLeft',
      'dpadRight',
    ],
    layout: ControllerLayout(
      viewBox: Size(480, 400),
      viewBoxOrigin: Offset(60, 20),
      controls: {
        'triangle': ControlGeometry(
            center: Offset(420, 124), radius: 15, color: kSuccessColor),
        'circle': ControlGeometry(
            center: Offset(456, 160), radius: 15, color: kErrorColor),
        'square': ControlGeometry(
            center: Offset(384, 160), radius: 15, color: kNeonPink),
        'cross': ControlGeometry(
            center: Offset(420, 196), radius: 15, color: kPrimaryBlue),
        'l1': ControlGeometry(
            center: Offset(245, 66), radius: 20, color: kTextSecondary),
        'r1': ControlGeometry(
            center: Offset(355, 66), radius: 20, color: kTextSecondary),
        'l2': ControlGeometry(
            center: Offset(245, 55), radius: 18, color: kPrimaryBlue),
        'r2': ControlGeometry(
            center: Offset(355, 55), radius: 18, color: kPrimaryBlue),
        'share': ControlGeometry(
            center: Offset(255, 90), radius: 10, color: kTextSecondary),
        'options': ControlGeometry(
            center: Offset(345, 90), radius: 10, color: kTextSecondary),
        'ps': ControlGeometry(
            center: Offset(300, 238), radius: 12, color: kPrimaryBlue),
        'touchpad': ControlGeometry(
            center: Offset(300, 135), radius: 34, color: kAccentPurple),
        'l3': ControlGeometry(
            center: Offset(235, 262), radius: 13, color: kPrimaryBlue),
        'r3': ControlGeometry(
            center: Offset(365, 262), radius: 13, color: kPrimaryBlue),
        'dpadUp': ControlGeometry(
            center: Offset(185, 138), radius: 12, color: kPrimaryBlue),
        'dpadDown': ControlGeometry(
            center: Offset(185, 198), radius: 12, color: kPrimaryBlue),
        'dpadLeft': ControlGeometry(
            center: Offset(155, 168), radius: 12, color: kPrimaryBlue),
        'dpadRight': ControlGeometry(
            center: Offset(215, 168), radius: 12, color: kPrimaryBlue),
      },
      leftStick: Offset(235, 262),
      rightStick: Offset(365, 262),
      stickTravel: 19,
      knobRadius: 23,
      l2Area: Rect.fromLTWH(214, 48, 62, 14),
      r2Area: Rect.fromLTWH(324, 48, 62, 14),
      touchpadArea: Rect.fromLTWH(240, 98, 120, 74),
      lightBarArea: Rect.fromLTWH(258, 70, 84, 9),
    ),
  );

  /// Semua profil yang dikenali. Dipakai backend lewat `type` di masa depan.
  static const List<ControllerProfile> all = [ds4];

  static ControllerProfile byId(String id) {
    return all.firstWhere((p) => p.id == id, orElse: () => ds4);
  }
}