import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_text.dart';

/// Renders a Lottie animation from assets, with a brutalist fallback box if
/// the asset is missing. Drop the .json files into `assets/lottie/` (already
/// registered in pubspec.yaml) and they'll start playing automatically.
///
/// Suggested files (grab any free Lottie at https://lottiefiles.com/):
///   * loop_shapes.json    — Action Chamber
///   * bouncing_bell.json  — Takeover Nudge
///   * confetti.json       — Success
class LottiePlaceholder extends StatelessWidget {
  const LottiePlaceholder({
    super.key,
    required this.assetPath,
    required this.fallbackLabel,
    this.height,
    this.width,
    this.repeat = true,
    this.fallbackColor = AppColors.cyan,
  });

  final String assetPath;
  final String fallbackLabel;
  final double? height;
  final double? width;
  final bool repeat;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      assetPath,
      height: height,
      width: width,
      repeat: repeat,
      errorBuilder: (BuildContext _, Object __, StackTrace? ___) => _Fallback(
        label: fallbackLabel,
        color: fallbackColor,
        height: height,
        width: width,
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({
    required this.label,
    required this.color,
    this.height,
    this.width,
  });

  final String label;
  final Color color;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 120,
      width: width,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        border: AppShadows.solid(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'LOTTIE · $label',
          textAlign: TextAlign.center,
          style: AppText.micro,
        ),
      ),
    );
  }
}
