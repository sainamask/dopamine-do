import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_text.dart';

/// Compact +/- stepper. Designed to fit two side-by-side on a phone screen.
class BrutalStepper extends StatelessWidget {
  const BrutalStepper({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
    this.step = 1,
    this.suffix = '',
    this.color = AppColors.cyan,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final String suffix;
  final Color color;
  final ValueChanged<int> onChanged;

  void _bump(int delta) {
    final int next = (value + delta).clamp(min, max);
    if (next != value) onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(label, style: AppText.micro),
        const SizedBox(height: 5),
        Row(
          children: <Widget>[
            _SquareButton(
              icon: PhosphorIconsBold.minus,
              onTap: () => _bump(-step),
              color: AppColors.white,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Container(
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  border: AppShadows.solid(width: AppShadows.borderRegular),
                  boxShadow: AppShadows.hard(offset: 3),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Text(
                      '${value.toString()}$suffix',
                      style: AppText.hero.copyWith(fontSize: 19),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),
            _SquareButton(
              icon: PhosphorIconsBold.plus,
              onTap: () => _bump(step),
              color: AppColors.white,
            ),
          ],
        ),
      ],
    );
  }
}

class _SquareButton extends StatefulWidget {
  const _SquareButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  State<_SquareButton> createState() => _SquareButtonState();
}

class _SquareButtonState extends State<_SquareButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        width: 38,
        height: 38,
        transform: Matrix4.translationValues(_down ? 3 : 0, _down ? 3 : 0, 0),
        decoration: BoxDecoration(
          color: widget.color,
          border: AppShadows.solid(width: AppShadows.borderRegular),
          boxShadow: _down ? <BoxShadow>[] : AppShadows.hard(offset: 3),
        ),
        child: Icon(widget.icon, color: AppColors.ink, size: 15),
      ),
    );
  }
}
