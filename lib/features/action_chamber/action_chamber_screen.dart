import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task.dart';
import '../../state/tasks_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';
import '../../widgets/brutal_button.dart';
import '../../widgets/lottie_placeholder.dart';
import '../timer/abstract_timer_widget.dart';

class ActionChamberScreen extends ConsumerWidget {
  const ActionChamberScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Task? task = ref.watch(activeTaskProvider);
    final Duration? runFor = ref.watch(activeRunDurationProvider);

    if (task == null || runFor == null) {
      return const _IdleChamber();
    }

    return _LiveChamber(task: task, duration: runFor);
  }
}

class _IdleChamber extends StatelessWidget {
  const _IdleChamber();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('THE ACTION CHAMBER', style: AppText.hero),
              const SizedBox(height: 4),
              Text('STAGED FOR DAMAGE.', style: AppText.micro),
              const Spacer(),
              const Center(
                child: LottiePlaceholder(
                  assetPath: 'assets/lottie/loop_shapes.json',
                  fallbackLabel: 'LOOPING SHAPES',
                  height: 200,
                  fallbackColor: AppColors.cyan,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: AppShadows.solid(width: AppShadows.borderThick),
                  boxShadow: AppShadows.hard(offset: 6),
                ),
                child: Column(
                  children: <Widget>[
                    Text('NO ACTIVE TASK', style: AppText.hero.copyWith(fontSize: 24)),
                    const SizedBox(height: 6),
                    Text(
                      'PICK ONE ON THE HYPE DESK',
                      style: AppText.micro,
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveChamber extends ConsumerStatefulWidget {
  const _LiveChamber({required this.task, required this.duration});
  final Task task;
  final Duration duration;

  @override
  ConsumerState<_LiveChamber> createState() => _LiveChamberState();
}

class _LiveChamberState extends ConsumerState<_LiveChamber> {
  late int _totalMs;
  late int _remainingMs;
  late DateTime _startedAt;
  Timer? _ticker;
  int _lastSecondTicked = -1;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _resetForCurrentTask();
  }

  @override
  void didUpdateWidget(covariant _LiveChamber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id ||
        oldWidget.duration != widget.duration) {
      _resetForCurrentTask();
    }
  }

  void _resetForCurrentTask() {
    _ticker?.cancel();
    _totalMs = widget.duration.inMilliseconds;
    _remainingMs = _totalMs;
    _startedAt = DateTime.now();
    _lastSecondTicked = -1;
    _completed = false;
    _ticker = Timer.periodic(const Duration(milliseconds: 50), _onTick);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _onTick(Timer _) {
    final int elapsed = DateTime.now().difference(_startedAt).inMilliseconds;
    final int remaining = (_totalMs - elapsed).clamp(0, _totalMs);
    final int second = (remaining / 1000).ceil();

    // Mechanical "thud" once per second during the final 60.
    if (remaining <= 60000 && remaining > 0 && second != _lastSecondTicked) {
      _lastSecondTicked = second;
      HapticFeedback.heavyImpact();
      // TODO(audio): play a mechanical "thud" tick via audioplayers.
      SystemSound.play(SystemSoundType.click);
    }

    if (mounted) setState(() => _remainingMs = remaining);

    if (remaining == 0 && !_completed) {
      _completed = true;
      _ticker?.cancel();
      unawaited(_onComplete());
    }
  }

  Future<void> _onComplete() async {
    HapticFeedback.heavyImpact();
    await ref
        .read(tasksProvider.notifier)
        .markCompleted(widget.task.id, at: DateTime.now());
    if (!mounted) return;
    await _showSuccessSheet();
    if (!mounted) return;
    ref.read(activeTaskIdProvider.notifier).clear();
    ref.read(activeRunDurationProvider.notifier).set(null);
    ref.read(shellTabProvider.notifier).set(ShellTab.glory);
  }

  Future<void> _showSuccessSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.limeShock,
            border: Border(
              top: BorderSide(color: AppColors.ink, width: AppShadows.borderThick),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Center(
                    child: LottiePlaceholder(
                      assetPath: 'assets/lottie/confetti.json',
                      fallbackLabel: 'CONFETTI',
                      height: 140,
                      fallbackColor: AppColors.neonYellow,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('TASK KILLED', style: AppText.hero, textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text(
                    widget.task.title.toUpperCase(),
                    style: AppText.title,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  BrutalButton(
                    label: 'STACK THE WIN',
                    color: AppColors.neonYellow,
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _bail() {
    _ticker?.cancel();
    ref.read(activeTaskIdProvider.notifier).clear();
    ref.read(activeRunDurationProvider.notifier).set(null);
    ref.read(shellTabProvider.notifier).set(ShellTab.hype);
  }

  String _formatTime(int ms) {
    final int totalSec = (ms / 1000).ceil();
    final int m = totalSec ~/ 60;
    final int s = totalSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final double ratio = _totalMs == 0 ? 0 : _remainingMs / _totalMs;
    final bool finalSixty = _remainingMs <= 60000;
    final double stress = finalSixty
        ? (1 - (_remainingMs / 60000)).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cyan,
                  border: AppShadows.solid(width: AppShadows.borderThick),
                  boxShadow: AppShadows.hard(offset: 6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('NOW DOING', style: AppText.micro),
                    const SizedBox(height: 4),
                    Text(
                      widget.task.title.toUpperCase(),
                      style: AppText.hero.copyWith(fontSize: 26),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 110,
                child: LottiePlaceholder(
                  assetPath: 'assets/lottie/loop_shapes.json',
                  fallbackLabel: 'LOOPING SHAPES',
                  height: 110,
                  fallbackColor: AppColors.electricPink,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                  child: AbstractTimerWidget(
                    remainingRatio: ratio,
                    stressLevel: stress,
                    label: _formatTime(_remainingMs),
                    fillColor: AppColors.electricPink,
                    backColor: AppColors.neonYellow,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: BrutalButton(
                  label: 'BAIL',
                  color: AppColors.white,
                  onPressed: _bail,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
