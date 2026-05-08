import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Abstract "draining tank" timer. The remaining ratio (0..1) controls the
/// liquid level; an internal slosh animation gives it physics. As the timer
/// crosses into the final 60 seconds, [stressLevel] drives thicker borders,
/// faster sloshing, and a hotter color shift.
class AbstractTimerWidget extends StatefulWidget {
  const AbstractTimerWidget({
    super.key,
    required this.remainingRatio,
    required this.label,
    this.stressLevel = 0,
    this.fillColor = AppColors.electricPink,
    this.backColor = AppColors.cyan,
  });

  /// 1.0 = full tank, 0.0 = empty.
  final double remainingRatio;

  /// 0.0 = calm, 1.0 = panic mode (final 60s).
  final double stressLevel;

  final String label;
  final Color fillColor;
  final Color backColor;

  @override
  State<AbstractTimerWidget> createState() => _AbstractTimerWidgetState();
}

class _AbstractTimerWidgetState extends State<AbstractTimerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slosh = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void didUpdateWidget(covariant AbstractTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Slosh accelerates with stress.
    final int ms = (3000 - 2000 * widget.stressLevel.clamp(0, 1)).round();
    if (_slosh.duration?.inMilliseconds != ms) {
      _slosh.duration = Duration(milliseconds: ms);
      _slosh
        ..stop()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _slosh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double s = widget.stressLevel.clamp(0, 1);
    final Color hotFill = Color.lerp(widget.fillColor, AppColors.safetyOrange, s)!;
    final double border = 4 + 6 * s;

    return AnimatedBuilder(
      animation: _slosh,
      builder: (BuildContext context, _) {
        return CustomPaint(
          painter: _TankPainter(
            ratio: widget.remainingRatio.clamp(0, 1),
            sloshPhase: _slosh.value * math.pi * 2,
            stress: s,
            fill: hotFill,
            back: widget.backColor,
            border: border,
            label: widget.label,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _TankPainter extends CustomPainter {
  _TankPainter({
    required this.ratio,
    required this.sloshPhase,
    required this.stress,
    required this.fill,
    required this.back,
    required this.border,
    required this.label,
  });

  final double ratio;
  final double sloshPhase;
  final double stress;
  final Color fill;
  final Color back;
  final double border;
  final String label;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect tank = Offset.zero & size;
    final Paint borderPaint = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = border;

    // Hard offset shadow (no blur — neubrutalism rule).
    final double shadowOffset = 8 + 4 * stress;
    final Paint shadowPaint = Paint()..color = AppColors.ink;
    canvas.drawRect(tank.shift(Offset(shadowOffset, shadowOffset)), shadowPaint);

    // Tank body.
    final Paint backPaint = Paint()..color = back;
    canvas.drawRect(tank, backPaint);

    // Liquid: top edge is a sine wave that drops as ratio drops.
    final double waveHeight = 10 + 14 * stress;
    final double waveLen = size.width / (1.5 + 1.5 * stress);
    final double restY = size.height * (1 - ratio);

    final Path liquid = Path()..moveTo(0, size.height);
    const int steps = 64;
    for (int i = 0; i <= steps; i++) {
      final double x = size.width * (i / steps);
      final double y = restY +
          math.sin((x / waveLen) * math.pi * 2 + sloshPhase) * waveHeight +
          math.sin((x / (waveLen * 0.6)) * math.pi * 2 - sloshPhase * 1.4) *
              waveHeight *
              0.4;
      if (i == 0) {
        liquid.lineTo(x, y);
      } else {
        liquid.lineTo(x, y);
      }
    }
    liquid
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(liquid, Paint()..color = fill);

    // Diagonal "danger" stripes pulse in when stressed.
    if (stress > 0.05) {
      final Paint stripe = Paint()
        ..color = AppColors.ink.withValues(alpha: 0.18 * stress)
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.clipPath(liquid);
      const double sp = 22;
      for (double x = -size.height; x < size.width + size.height; x += sp) {
        final Path p = Path()
          ..moveTo(x, 0)
          ..lineTo(x + 8, 0)
          ..lineTo(x + 8 + size.height, size.height)
          ..lineTo(x + size.height, size.height)
          ..close();
        canvas.drawPath(p, stripe);
      }
      canvas.restore();
    }

    // Border last so it sits on top of the fill.
    canvas.drawRect(tank, borderPaint);

    // Label dead-center, massive.
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: 'ArchivoBlack',
          fontFamilyFallback: const <String>['Impact', 'Helvetica', 'Arial'],
          fontWeight: FontWeight.w900,
          fontSize: math.min(size.width, size.height) * 0.35,
          height: 0.95,
          letterSpacing: -2,
          color: AppColors.ink,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);

    tp.paint(
      canvas,
      Offset(
        (size.width - tp.width) / 2,
        (size.height - tp.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _TankPainter old) {
    return old.ratio != ratio ||
        old.sloshPhase != sloshPhase ||
        old.stress != stress ||
        old.fill != fill ||
        old.back != back ||
        old.border != border ||
        old.label != label;
  }
}
