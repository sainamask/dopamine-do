import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_text.dart';

class BrutalButton extends StatefulWidget {
  const BrutalButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.neonYellow,
    this.borderColor = AppColors.ink,
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
    this.shadowOffset = 6,
    this.borderWidth = AppShadows.borderThick,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final Color color;
  final Color borderColor;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry padding;
  final double shadowOffset;
  final double borderWidth;
  final IconData? icon;

  @override
  State<BrutalButton> createState() => _BrutalButtonState();
}

class _BrutalButtonState extends State<BrutalButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
    reverseDuration: const Duration(milliseconds: 380),
  );

  late final Animation<double> _scale = Tween<double>(begin: 1, end: 0.9)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut, reverseCurve: Curves.elasticOut));

  late final Animation<double> _shadow = Tween<double>(begin: 1, end: 0)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut, reverseCurve: Curves.elasticOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _down() {
    HapticFeedback.lightImpact();
    _controller.forward();
  }

  void _up() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _down(),
      onTapCancel: _up,
      onTapUp: (_) {
        _up();
        widget.onPressed();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          final double offset = widget.shadowOffset * _shadow.value;
          return Transform.translate(
            offset: Offset(
              widget.shadowOffset - offset,
              widget.shadowOffset - offset,
            ),
            child: Transform.scale(
              scale: _scale.value,
              alignment: Alignment.center,
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                  color: widget.color,
                  border: AppShadows.solid(
                    width: widget.borderWidth,
                    color: widget.borderColor,
                  ),
                  boxShadow: AppShadows.hard(
                    offset: offset,
                    color: widget.borderColor,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (widget.icon != null) ...<Widget>[
                      Icon(widget.icon, color: widget.borderColor, size: 24),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      widget.label.toUpperCase(),
                      style: widget.textStyle ?? AppText.button,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
