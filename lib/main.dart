import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/shell/app_shell.dart';
import 'features/splash/splash_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Bring up the alarm channel + timezone data before the tree builds so
  // the first task add() can schedule successfully.
  await NotificationService.instance.init();
  // Fire-and-forget the permission prompt; we don't want to block boot
  // on the user tapping Allow.
  unawaited(NotificationService.instance.requestPermissionsIfNeeded());
  runApp(const ProviderScope(child: DopamineDoApp()));
}

class DopamineDoApp extends StatelessWidget {
  const DopamineDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dopamine-Do',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: const _Root(),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _booted = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _booted
          ? const AppShell(key: ValueKey<String>('shell'))
          : SplashScreen(
              key: const ValueKey<String>('splash'),
              onDone: () => setState(() => _booted = true),
            ),
    );
  }
}
