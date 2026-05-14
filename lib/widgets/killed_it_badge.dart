import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_text.dart';

class KilledItBadge extends StatelessWidget {
  const KilledItBadge({super.key, this.angle = -0.08});

  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.ink,
          border: AppShadows.solid(width: AppShadows.borderRegular),
        ),
        child: Text(
          'KILLED IT',
          style: AppText.button.copyWith(
            color: AppColors.limeShock,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
