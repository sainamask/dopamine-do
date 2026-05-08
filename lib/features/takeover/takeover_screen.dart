import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';
import '../../widgets/brutal_button.dart';
import '../../widgets/icon_hero.dart';

enum TakeoverChoice { start, snooze }

/// Mustard takeover screen. Calm — fades in, no bouncing.
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
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 160),
        pageBuilder: (BuildContext _, Animation<double> _, Animation<double> _) =>
            TakeoverScreen(
          taskTitle: taskTitle,
          scheduledLabel: scheduledLabel,
        ),
        transitionsBuilder:
            (BuildContext _, Animation<double> anim, Animation<double> _, Widget child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  @override
  State<TakeoverScreen> createState() => _TakeoverScreenState();
}

class _TakeoverScreenState extends State<TakeoverScreen> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
  }

  void _resolve(TakeoverChoice choice) {
    HapticFeedback.lightImpact();
    widget.onChoice?.call(choice);
    Navigator.of(context).maybePop(choice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.vaporBlue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(widget.scheduledLabel.toUpperCase(),
                  style: AppText.micro.copyWith(color: AppColors.white)),
              const SizedBox(height: 6),
              Text('TASK INCOMING',
                  style: AppText.title.copyWith(color: AppColors.white)),
              const SizedBox(height: 18),
              Center(
                child: IconHero(
                  icon: PhosphorIconsBold.bellRinging,
                  background: AppColors.white,
                  size: 140,
                  animation: HeroAnim.wobble,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: _StampedTitle(title: widget.taskTitle),
              ),
              const Spacer(),
              BrutalButton(
                label: "I'M ON IT",
                color: AppColors.toxicLime,
                padding: const EdgeInsets.symmetric(vertical: 22),
                onPressed: () => _resolve(TakeoverChoice.start),
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
        title,
        textAlign: TextAlign.center,
        style: AppText.hero,
      ),
    );
  }
}
