import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// A neubrutalist bottom sheet: thick top border, neon background, hard edges.
class NeubrutalBottomSheet extends StatelessWidget {
  const NeubrutalBottomSheet({
    super.key,
    required this.child,
    this.color = AppColors.cyan,
    this.topBorderWidth = AppShadows.borderRegular,
  });

  final Widget child;
  final Color color;
  final double topBorderWidth;

  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    Color color = AppColors.cyan,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.ink.withValues(alpha: 0.55),
      builder: (BuildContext ctx) => NeubrutalBottomSheet(
        color: color,
        child: builder(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          border: Border(
            top: BorderSide(color: AppColors.ink, width: topBorderWidth),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: child,
          ),
        ),
      ),
    );
  }
}
