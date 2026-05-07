import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppShadows {
  AppShadows._();

  static const double borderThin = 3.0;
  static const double borderRegular = 4.0;
  static const double borderThick = 6.0;
  static const double borderStress = 8.0;

  static List<BoxShadow> hard({double offset = 6, Color color = AppColors.ink}) {
    return <BoxShadow>[
      BoxShadow(
        color: color,
        offset: Offset(offset, offset),
        blurRadius: 0,
        spreadRadius: 0,
      ),
    ];
  }

  static Border solid({double width = borderRegular, Color color = AppColors.ink}) {
    return Border.all(color: color, width: width);
  }
}
