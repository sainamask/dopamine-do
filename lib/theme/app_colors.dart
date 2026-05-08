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
  static const Color cyan = Color(0xFF22D3EE);

  /// Warm accent — alarms, FAB, "incoming" energy.
  static const Color electricPink = Color(0xFFEC4899);

  /// Soft decorative violet. Tabs, success-sheet bg, idle accents.
  static const Color limeShock = Color(0xFFA78BFA);

  /// "Energy" slot (formerly yellow). Use sparingly for highlights.
  static const Color neonYellow = Color(0xFF84CC16);

  /// Warm orange accent. Stress / heat moments.
  static const Color safetyOrange = Color(0xFFF97316);

  /// "GO / WIN" green. Punchier than neonYellow — used for primary
  /// confirmation buttons (SAVE TASK, I'M ON IT, STACK THE WIN).
  static const Color toxicLime = Color(0xFF4ADE80);

  /// Deep dramatic blue — full-screen surfaces (takeover) where we want
  /// presence. Pair with white text, not ink.
  static const Color vaporBlue = Color(0xFF6366F1);

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
  ];
}
