import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppShadows {
  AppShadows._();

  static const double borderThin = 2.5;
  static const double borderRegular = 3.0;
  static const double borderThick = 5.0;
  static const double borderStress = 6.5;

  static List<BoxShadow> hard({double offset = 5, Color color = AppColors.ink}) {
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
