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
      viewBox: Size(600, 400),
      controls: {
        'triangle': ControlGeometry(
            center: Offset(372, 132), radius: 15, color: kSuccessColor),
        'circle': ControlGeometry(
            center: Offset(412, 165), radius: 15, color: kErrorColor),
        'square': ControlGeometry(
            center: Offset(332, 165), radius: 15, color: kNeonPink),
        'cross': ControlGeometry(
            center: Offset(372, 198), radius: 15, color: kPrimaryBlue),
        'l1': ControlGeometry(
            center: Offset(235, 70), radius: 20, color: kTextSecondary),
        'r1': ControlGeometry(
            center: Offset(365, 70), radius: 20, color: kTextSecondary),
        'l2': ControlGeometry(
            center: Offset(234, 51), radius: 18, color: kPrimaryBlue),
        'r2': ControlGeometry(
            center: Offset(366, 51), radius: 18, color: kPrimaryBlue),
        'share': ControlGeometry(
            center: Offset(252, 84), radius: 10, color: kTextSecondary),
        'options': ControlGeometry(
            center: Offset(348, 84), radius: 10, color: kTextSecondary),
        'ps': ControlGeometry(
            center: Offset(300, 224), radius: 12, color: kPrimaryBlue),
        'touchpad': ControlGeometry(
            center: Offset(300, 132), radius: 34, color: kAccentPurple),
        'l3': ControlGeometry(
            center: Offset(238, 252), radius: 13, color: kPrimaryBlue),
        'r3': ControlGeometry(
            center: Offset(362, 252), radius: 13, color: kPrimaryBlue),
        'dpadUp': ControlGeometry(
            center: Offset(200, 150), radius: 9, color: kPrimaryBlue),
        'dpadDown': ControlGeometry(
            center: Offset(200, 180), radius: 9, color: kPrimaryBlue),
        'dpadLeft': ControlGeometry(
            center: Offset(185, 165), radius: 9, color: kPrimaryBlue),
        'dpadRight': ControlGeometry(
            center: Offset(215, 165), radius: 9, color: kPrimaryBlue),
      },
      leftStick: Offset(238, 252),
      rightStick: Offset(362, 252),
      stickTravel: 19,
      knobRadius: 23,
      l2Area: Rect.fromLTWH(206, 44, 56, 14),
      r2Area: Rect.fromLTWH(338, 44, 56, 14),
      touchpadArea: Rect.fromLTWH(236, 92, 128, 80),
      lightBarArea: Rect.fromLTWH(258, 62, 84, 8),
    ),
  );

  /// Semua profil yang dikenali. Dipakai backend lewat `type` di masa depan.
  static const List<ControllerProfile> all = [ds4];

  static ControllerProfile byId(String id) {
    return all.firstWhere((p) => p.id == id, orElse: () => ds4);
  }
}