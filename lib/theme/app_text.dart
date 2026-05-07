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
    fontWeight: FontWeight.w900,
    fontSize: 72,
    height: 0.95,
    letterSpacing: -2,
    color: AppColors.ink,
  );

  // Hero — capped at 36px per Phase 2 spec.
  static const TextStyle hero = TextStyle(
    fontFamily: displayFamily,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w900,
    fontSize: 36,
    height: 1.0,
    letterSpacing: -0.5,
    color: AppColors.ink,
  );

  static const TextStyle title = TextStyle(
    fontFamily: displayFamily,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w900,
    fontSize: 20,
    height: 1.05,
    color: AppColors.ink,
  );

  static const TextStyle button = TextStyle(
    fontFamily: displayFamily,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w900,
    fontSize: 16,
    letterSpacing: 1.2,
    color: AppColors.ink,
  );

  static const TextStyle body = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 16,
    height: 1.3,
    color: AppColors.ink,
  );

  static const TextStyle micro = TextStyle(
    fontWeight: FontWeight.w900,
    fontSize: 12,
    letterSpacing: 1.4,
    color: AppColors.ink,
  );
}
