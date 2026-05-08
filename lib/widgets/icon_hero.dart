import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Big chunky icon-in-a-box used as a "hero" illustration. Supports a built-in
/// pulse / wobble animation so it doesn't sit dead on the page.
class IconHero extends StatefulWidget {
  const IconHero({
    super.key,
    required this.icon,
    this.background = AppColors.cyan,
    this.iconColor = AppColors.ink,
    this.size = 120,
    this.padding = 18,
    this.shadowOffset = 8,
    this.borderWidth = AppShadows.borderThick,
    this.animation = HeroAnim.pulse,
  });

  final IconData icon;
  final Color background;
  final Color iconColor;
  final double size;
  final double padding;
  final double shadowOffset;
  final double borderWidth;
  final HeroAnim animation;

  @override
  State<IconHero> createState() => _IconHeroState();
}

enum HeroAnim { pulse, wobble, none }

class _IconHeroState extends State<IconHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animation != HeroAnim.none) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (BuildContext context, _) {
        final double t = Curves.easeInOut.transform(_ctrl.value);
        Widget child = Container(
          width: widget.size,
          height: widget.size,
          padding: EdgeInsets.all(widget.padding),
          decoration: BoxDecoration(
            color: widget.background,
            border: AppShadows.solid(width: widget.borderWidth),
            boxShadow: AppShadows.hard(offset: widget.shadowOffset),
          ),
          child: FittedBox(
            child: Icon(widget.icon, color: widget.iconColor),
          ),
        );

        switch (widget.animation) {
          case HeroAnim.pulse:
            child = Transform.scale(scale: 0.96 + 0.06 * t, child: child);
          case HeroAnim.wobble:
            child = Transform.rotate(angle: -0.06 + 0.12 * t, child: child);
          case HeroAnim.none:
            break;
        }
        return child;
      },
    );
  }
}
