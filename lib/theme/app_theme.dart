import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text.dart';

class AppTheme {
  AppTheme._();

  static ThemeData build() {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.paper,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.electricPink,
        secondary: AppColors.cyan,
        surface: AppColors.paper,
        onPrimary: AppColors.ink,
        onSecondary: AppColors.ink,
        onSurface: AppColors.ink,
      ),
      textTheme: TextTheme(
        displayLarge: AppText.countdown,
        headlineLarge: AppText.hero,
        titleLarge: AppText.title,
        labelLarge: AppText.button,
        bodyLarge: AppText.body,
        labelSmall: AppText.micro,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      useMaterial3: true,
    );
  }
}
