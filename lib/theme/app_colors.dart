import 'package:flutter/material.dart';

/// App palette — cool-leaning, refined brutalism. One coherent set; no
/// experimentation cruft. Tuned so ink-colored text reads on every accent.
///
/// Mental model:
///   • Neutrals (ink / paper / white) carry 80% of the surface.
///   • cyan is the calm hero — used by default for primary actions.
///   • neonYellow's *slot* is now lime green: it serves the "energy" role
///     without being yellow. Renaming would touch every file, so we just
///     rebalance the value.
///   • toxicLime is the punchier "GO / win" green for celebratory moments.
///   • electricPink + safetyOrange are warm accents — sparingly.
///   • limeShock is a soft violet — quiet decorative accent.
///   • vaporBlue is the deep dramatic blue (takeover, big surfaces).
class AppColors {
  AppColors._();

  // ---- Neutrals ----
  /// Borders, default text, hard shadows. Near-black, slight cool tint.
  static const Color ink = Color(0xFF171717);

  /// Default scaffold background. Warm-neutral cream, paper-like.
  static const Color paper = Color(0xFFEEEAE0);

  /// Card / chip surface. Pure white so the accents pop.
  static const Color white = Color(0xFFFFFFFF);

  // ---- Accents (all chosen to read with ink-colored text) ----

  /// Calm hero. Default for most BrutalButtons + bottom sheets.
  static const Color cyan = Color(0xFF67C6E3);

  static const Color electricPink = Color(0xFFD9468D);
  static const Color electricYellow = Color(0xFFF2D86B);
  static const Color limeShock = Color(0xFFA78BFA);
  static const Color neonYellow = Color(0xFF2DD4BF);
  static const Color safetyOrange = Color(0xFFE16522);
  static const Color toxicLime = Color(0xFF4ADE80);
  // static const Color water = Color(0xFFBFE9FF);
  // static const Color water = Color(0xFF8FD3FF);
  // static const Color water = Color(0xFFE6F7FF);
  static const Color water = Color(0xFF3FA9D9);

  /// Deep dramatic blue — full-screen surfaces (takeover) where we want
  /// presence. Pair with white text, not ink.
  // static const Color vaporBlue = Color(0xFF6366F1);
  static const Color vaporBlue = Color(0xFF0F766E);

  // ---- Aliases kept for backwards-compat with files that already use
  // the old vapor names. They point at the new neutrals so nothing breaks.
  static const Color windowOutline = ink;
  static const Color backgroundMist = paper;

  /// Card-rotation palette. Cool-first; orange + neonYellow at the tail
  /// so they appear as occasional accents, not as the dominant tone.
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
