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
    final Color hotFill =
        Color.lerp(widget.fillColor, AppColors.safetyOrange, s)!;
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

    // Tank body — the empty/back colour reads as "air" above the waterline.
    canvas.drawRect(tank, Paint()..color = back);

    // Liquid: top edge is a sine wave that drops as ratio drops.
    final double waveHeight = 10 + 14 * stress;
    final double waveLen = size.width / (1.5 + 1.5 * stress);
    final double restY = size.height * (1 - ratio);

    double waveYAt(double x) {
      return restY +
          math.sin((x / waveLen) * math.pi * 2 + sloshPhase) * waveHeight +
          math.sin((x / (waveLen * 0.6)) * math.pi * 2 - sloshPhase * 1.4) *
              waveHeight *
              0.4;
    }

    final Path liquid = Path()..moveTo(0, size.height);
    const int steps = 80;
    for (int i = 0; i <= steps; i++) {
      final double x = size.width * (i / steps);
      liquid.lineTo(x, waveYAt(x));
    }
    liquid
      ..lineTo(size.width, size.height)
      ..close();

    // Water with a top-to-bottom depth gradient — top stays the bright
    // fill, bottom mixes toward ink so the tank reads as having volume.
    final Color deep = Color.lerp(fill, AppColors.ink, 0.22)!;
    final Paint waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[fill, deep],
      ).createShader(
        Rect.fromLTWH(0, restY, size.width, size.height - restY),
      );
    canvas.drawPath(liquid, waterPaint);

    // Reflective highlight stroke along the wave crest — gives the
    // surface a clear "this is water" line instead of just a colour edge.
    final Path crest = Path();
    for (int i = 0; i <= steps; i++) {
      final double x = size.width * (i / steps);
      final double y = waveYAt(x);
      if (i == 0) {
        crest.moveTo(x, y);
      } else {
        crest.lineTo(x, y);
      }
    }
    canvas.drawPath(
      crest,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    // Rising bubbles — 3 bubbles on a continuous loop, each drifting up
    // from the tank floor to the waterline and fading as they reach it.
    // sloshPhase is the global clock; bubbles are phase-offset.
    if (ratio > 0.05) {
      final double bubbleClock = sloshPhase / (math.pi * 2);
      for (int i = 0; i < 3; i++) {
        final double seed = (i * 0.37 + 0.13);
        final double t = (bubbleClock * 0.45 + seed) % 1.0;
        final double bubbleX = size.width * (0.18 + 0.64 * (seed * 2.7 % 1.0));
        // Lerp from the floor up to just under the waterline.
        final double bubbleY = size.height - (size.height - restY - 6) * t;
        if (bubbleY < restY + 8) continue;
        final double r = 2.5 + (i % 3) * 1.2;
        // Fade out as the bubble nears the surface.
        final double alpha = (1 - t).clamp(0.0, 1.0) * 0.55;
        canvas.drawCircle(
          Offset(bubbleX, bubbleY),
          r,
          Paint()
            ..color = Colors.white.withValues(alpha: alpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
      }
    }

    // Measurement ticks on the inner walls — three short hashes at
    // 25/50/75% so the eye can read the falling level against a fixed scale.
    final Paint tick = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 2;
    final double tickLen = math.min(12, size.width * 0.05);
    for (final double frac in <double>[0.25, 0.5, 0.75]) {
      final double y = size.height * frac;
      canvas.drawLine(Offset(0, y), Offset(tickLen, y), tick);
      canvas.drawLine(
        Offset(size.width - tickLen, y),
        Offset(size.width, y),
        tick,
      );
    }

    // Drain at the bottom-center — a flat slot with two short stripes
    // beneath, reading as "water exits here". Visible even when the tank
    // is full so the metaphor stays legible.
    final double drainW = math.min(36, size.width * 0.18);
    final double drainH = 6;
    final double cx = size.width / 2;
    final double drainTop = size.height - drainH - 2;
    canvas.drawRect(
      Rect.fromLTWH(cx - drainW / 2, drainTop, drainW, drainH),
      Paint()..color = AppColors.ink,
    );
    // Two short drip stripes just below the drain, hinting at outflow.
    final Paint drip = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      Offset(cx - drainW * 0.25, size.height - 1),
      Offset(cx - drainW * 0.25, size.height + 4),
      drip,
    );
    canvas.drawLine(
      Offset(cx + drainW * 0.25, size.height - 1),
      Offset(cx + drainW * 0.25, size.height + 4),
      drip,
    );

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

    // Label dead-center. Sized to sit comfortably alongside the boat
    // without dominating the tank.
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: 'ArchivoBlack',
          fontFamilyFallback: const <String>['Impact', 'Helvetica', 'Arial'],
          fontWeight: FontWeight.w900,
          fontSize: math.min(size.width, size.height) * 0.22,
          height: 0.95,
          letterSpacing: -1.5,
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
