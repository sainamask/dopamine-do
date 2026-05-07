import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

class BrutalContainer extends StatelessWidget {
  const BrutalContainer({
    super.key,
    required this.child,
    this.color = AppColors.white,
    this.borderColor = AppColors.ink,
    this.borderWidth = AppShadows.borderRegular,
    this.shadowOffset = 6,
    this.padding = const EdgeInsets.all(20),
    this.radius = 0,
  });

  final Widget child;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final double shadowOffset;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        border: AppShadows.solid(width: borderWidth, color: borderColor),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppShadows.hard(offset: shadowOffset, color: borderColor),
      ),
      child: child,
    );
  }
}
