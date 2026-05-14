import 'package:flutter/material.dart';

/// App palette — cool-leaning, refined brutalism. One coherent set; no
/// experimentation cruft. Tuned so ink-colored text reads on every accent.
class AppColors {
  AppColors._();

  // ---- Neutrals ----
  static const Color ink = Color(0xFF171717);
  static const Color paper = Color(0xFFEEEAE0);
  static const Color white = Color(0xFFFFFFFF);

  // ---- Accents (all chosen to read with ink-colored text) ----
  static const Color cyan = Color(0xFF67C6E3);
  static const Color electricPink = Color(0xFFD9468D);
  static const Color electricYellow = Color(0xFFF2D86B);
  static const Color limeShock = Color(0xFFA78BFA);
  static const Color neonYellow = Color(0xFF2DD4BF);
  static const Color safetyOrange = Color(0xFFE16522);
  static const Color toxicLime = Color(0xFF4ADE80);
  static const Color water = Color(0xFF3FA9D9);

  /// Deep dramatic blue — full-screen surfaces (takeover) where we want
  /// presence. Pair with white text, not ink.
  static const Color vaporBlue = Color(0xFF0F766E);

  static const Color windowOutline = ink;
  static const Color backgroundMist = paper;

  /// Card-rotation palette.
  static const List<Color> vaporStrobe = <Color>[
    cyan,
    limeShock,
    electricPink,
    toxicLime,
    safetyOrange,
    neonYellow,
    electricYellow,
  ];
}
