import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  late final Animation<double> _scale = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.elasticOut,
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
  );

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
    Future<void>.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.electricPink,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (BuildContext context, _) {
            return Opacity(
              opacity: _fade.value,
              child: Transform.scale(
                scale: 0.6 + 0.6 * _scale.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.toxicLime,
                    border: AppShadows.solid(width: AppShadows.borderStress),
                    boxShadow: AppShadows.hard(offset: 12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'DOPAMINE-DO',
                          style: AppText.hero.copyWith(fontSize: 48),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('KILL PROCRASTINATION. LOUD.', style: AppText.micro),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
