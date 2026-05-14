import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppText {
  AppText._();

  // To use Archivo Black, drop the .ttf into assets/fonts/ and register it
  // in pubspec.yaml under flutter.fonts. We keep a fallback to the system
  // heaviest weight so the app still feels chunky out of the box.
  static const String displayFamily = 'ArchivoBlack';

  static const List<String> _fallback = <String>[
    'Impact',
    'Helvetica',
    'Arial',
  ];

  // Countdown number — the only place we exceed hero size, on purpose.
  static const TextStyle countdown = TextStyle(
    fontFamily: displayFamily,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w800,
    fontSize: 42,
    height: 0.95,
    letterSpacing: -1.5,
    color: AppColors.ink,
  );

  static const TextStyle hero = TextStyle(
    fontFamily: displayFamily,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w800,
    fontSize: 21,
    height: 1.0,
    letterSpacing: -0.3,
    color: AppColors.ink,
  );

  static const TextStyle title = TextStyle(
    fontFamily: displayFamily,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w800,
    fontSize: 14,
    height: 1.05,
    color: AppColors.ink,
  );

  static const TextStyle button = TextStyle(
    fontFamily: displayFamily,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w800,
    fontSize: 11,
    letterSpacing: 1.0,
    color: AppColors.ink,
  );

  static const TextStyle body = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 12,
    height: 1.3,
    color: AppColors.ink,
  );

  static const TextStyle micro = TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 10,
    letterSpacing: 1.0,
    color: AppColors.ink,
  );
}
