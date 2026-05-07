import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';
import '../../widgets/brutal_button.dart';
import '../../widgets/lottie_placeholder.dart';

enum TakeoverChoice { start, justFiveMinutes, snooze }

/// Soft "elastic pulse" takeover. Background tweens between two neon colors;
/// the task name bounces in/out on `Curves.elasticOut`. Excited, not angry.
class TakeoverScreen extends StatefulWidget {
  const TakeoverScreen({
    super.key,
    required this.taskTitle,
    required this.scheduledLabel,
    this.onChoice,
  });

  final String taskTitle;
  final String scheduledLabel;
  final ValueChanged<TakeoverChoice>? onChoice;

  static Future<TakeoverChoice?> show(
    BuildContext context, {
    required String taskTitle,
    required String scheduledLabel,
  }) {
    return Navigator.of(context).push<TakeoverChoice>(
      PageRouteBuilder<TakeoverChoice>(
        opaque: true,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (BuildContext _, Animation<double> _, Animation<double> _) =>
            TakeoverScreen(
          taskTitle: taskTitle,
          scheduledLabel: scheduledLabel,
        ),
        transitionsBuilder:
            (BuildContext _, Animation<double> anim, Animation<double> _, Widget child) {
          return FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  State<TakeoverScreen> createState() => _TakeoverScreenState();
}

class _TakeoverScreenState extends State<TakeoverScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _bounceCtrl;
  late final Animation<Color?> _pulseColor;
  late final Animation<double> _bounceY;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseColor = ColorTween(
      begin: AppColors.neonYellow,
      end: AppColors.electricPink,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _bounceY = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.elasticOut),
    );

    HapticFeedback.mediumImpact();
    // TODO(audio): play a soft "boing" loop here via audioplayers.
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _resolve(TakeoverChoice choice) {
    HapticFeedback.lightImpact();
    widget.onChoice?.call(choice);
    Navigator.of(context).maybePop(choice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[_pulseCtrl, _bounceCtrl]),
        builder: (BuildContext context, _) {
          return Container(
            color: _pulseColor.value ?? AppColors.neonYellow,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(widget.scheduledLabel.toUpperCase(),
                        style: AppText.micro),
                    const SizedBox(height: 6),
                    Text('TASK INCOMING', style: AppText.title),
                    const SizedBox(height: 18),
                    const Center(
                      child: LottiePlaceholder(
                        assetPath: 'assets/lottie/bouncing_bell.json',
                        fallbackLabel: 'BOUNCING BELL',
                        height: 140,
                        fallbackColor: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Transform.translate(
                        offset: Offset(0, _bounceY.value),
                        child: _StampedTitle(title: widget.taskTitle),
                      ),
                    ),
                    const Spacer(),
                    BrutalButton(
                      label: "I'M ON IT",
                      color: AppColors.limeShock,
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      onPressed: () => _resolve(TakeoverChoice.start),
                    ),
                    const SizedBox(height: 12),
                    BrutalButton(
                      label: 'JUST 5 MINUTES',
                      color: AppColors.cyan,
                      onPressed: () =>
                          _resolve(TakeoverChoice.justFiveMinutes),
                    ),
                    const SizedBox(height: 12),
                    BrutalButton(
                      label: 'SNOOZE 3 MIN',
                      color: AppColors.white,
                      onPressed: () => _resolve(TakeoverChoice.snooze),
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

class _StampedTitle extends StatelessWidget {
  const _StampedTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: AppShadows.solid(width: AppShadows.borderThick),
        boxShadow: AppShadows.hard(offset: 8),
      ),
      child: Text(
        title.toUpperCase(),
        textAlign: TextAlign.center,
        style: AppText.hero,
      ),
    );
  }
}
