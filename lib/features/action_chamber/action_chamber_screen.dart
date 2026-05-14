import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../models/task.dart';
import '../../services/timer_music.dart';
import '../../state/settings_provider.dart';
import '../../state/tasks_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';
import '../../widgets/brutal_button.dart';
import '../../widgets/icon_hero.dart';
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('THE ACTION CHAMBER', style: AppText.hero),
              const SizedBox(height: 3),
              Text('STAGED FOR DAMAGE.', style: AppText.micro),
              const Spacer(),
              Center(
                child: IconHero(
                  icon: PhosphorIconsBold.gameController,
                  background: AppColors.electricPink,
                  size: 150,
                  animation: HeroAnim.pulse,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: AppShadows.solid(width: AppShadows.borderThick),
                  boxShadow: AppShadows.hard(offset: 5),
                ),
                child: Column(
                  children: <Widget>[
                    Text(
                      'NO ACTIVE TASK',
                      style: AppText.hero.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 5),
                    Text('PICK ONE ON THE HYPE DESK', style: AppText.micro),
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

class _LiveChamberState extends ConsumerState<_LiveChamber>
    with WidgetsBindingObserver {
  late int _totalMs;
  late int _remainingMs;
  late DateTime _startedAt;
  Timer? _ticker;
  int _lastSecondTicked = -1;
  bool _completed = false;
  bool _paused = false;
  int _elapsedAtPauseMs = 0;
  int _persistTickCounter = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

  Future<void> _resetForCurrentTask() async {
    _ticker?.cancel();
    _totalMs = widget.duration.inMilliseconds;
    _remainingMs = _totalMs;
    _startedAt = DateTime.now();
    _elapsedAtPauseMs = 0;
    _lastSecondTicked = -1;
    _completed = false;
    _paused = false;

    // Restore-from-persistence: if a saved session matches this task, reuse
    // its anchor time so the timer continues where it left off rather than
    // restarting from full.
    final ActiveSession? saved = await ActiveSessionStore.instance.load();
    if (mounted &&
        saved != null &&
        saved.taskId == widget.task.id &&
        saved.totalMs == _totalMs) {
      if (saved.paused) {
        _paused = true;
        _elapsedAtPauseMs = saved.elapsedAtPauseMs;
        _remainingMs = (_totalMs - _elapsedAtPauseMs).clamp(0, _totalMs);
        _startedAt = DateTime.now().subtract(
          Duration(milliseconds: _elapsedAtPauseMs),
        );
      } else {
        _startedAt = saved.startedAt;
        final int elapsed = DateTime.now()
            .difference(_startedAt)
            .inMilliseconds;
        _remainingMs = (_totalMs - elapsed).clamp(0, _totalMs);
      }
    } else {
      await _persistSession();
    }

    _ticker = Timer.periodic(const Duration(milliseconds: 50), _onTick);
    if (!_paused) {
      unawaited(TimerMusic.instance.play());
    }
    if (mounted) setState(() {});
  }

  void _togglePause() {
    HapticFeedback.lightImpact();
    if (_paused) {
      _startedAt = DateTime.now().subtract(
        Duration(milliseconds: _elapsedAtPauseMs),
      );
      setState(() => _paused = false);
      unawaited(TimerMusic.instance.play());
    } else {
      _elapsedAtPauseMs = _totalMs - _remainingMs;
      setState(() => _paused = true);
      unawaited(TimerMusic.instance.pause());
    }
    unawaited(_persistSession());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    unawaited(TimerMusic.instance.stop());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Snapshot on every backgrounding so a kill mid-session is recoverable.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      unawaited(_persistSession());
    }
  }

  Future<void> _persistSession() async {
    if (_completed) return;
    final int elapsedMs = _paused
        ? _elapsedAtPauseMs
        : (_totalMs - _remainingMs).clamp(0, _totalMs);
    await ActiveSessionStore.instance.save(
      ActiveSession(
        taskId: widget.task.id,
        totalMs: _totalMs,
        startedAt: _startedAt,
        elapsedAtPauseMs: elapsedMs,
        paused: _paused,
      ),
    );
  }

  void _onTick(Timer _) {
    if (_paused) return;
    final int elapsed = DateTime.now().difference(_startedAt).inMilliseconds;
    final int remaining = (_totalMs - elapsed).clamp(0, _totalMs);
    final int second = (remaining / 1000).ceil();

    if (remaining <= 60000 && remaining > 0 && second != _lastSecondTicked) {
      _lastSecondTicked = second;
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.click);
    }

    if (mounted) setState(() => _remainingMs = remaining);

    // Persist every ~2s while running so the resume snapshot stays fresh.
    _persistTickCounter++;
    if (_persistTickCounter >= 40) {
      _persistTickCounter = 0;
      unawaited(_persistSession());
    }

    if (remaining == 0 && !_completed) {
      _completed = true;
      _ticker?.cancel();
      unawaited(_onComplete());
    }
  }

  Future<void> _onComplete() async {
    HapticFeedback.heavyImpact();
    unawaited(TimerMusic.instance.stop());
    final Duration actual = Duration(milliseconds: _totalMs);
    await ActiveSessionStore.instance.clear();
    // Play the user's custom win sound if they picked one — best-effort.
    final String? hypeSound = ref.read(settingsProvider).value?.hypeSoundPath;
    if (hypeSound != null && hypeSound.isNotEmpty) {
      try {
        await AudioPlayer().play(DeviceFileSource(hypeSound), volume: 0.95);
      } catch (_) {
        /* missing/broken file shouldn't break the flow */
      }
    }
    if (!mounted) return;
    await ref
        .read(tasksProvider.notifier)
        .markCompletedWithUndo(widget.task.id, context, actualDuration: actual);
    if (!mounted) return;
    await _showSuccessSheet();
    if (!mounted) return;
    ref.read(activeTaskIdProvider.notifier).clear();
    ref.read(activeRunDurationProvider.notifier).set(null);
    ref.read(shellTabProvider.notifier).set(ShellTab.glory);
  }

  Future<void> _showSuccessSheet() {
    final AppSettings settings =
        ref.read(settingsProvider).value ?? const AppSettings();
    final List<String> pool = settings.customHypeLines.isNotEmpty
        ? settings.customHypeLines
        : kDefaultHypeLines;
    final String hype = pool[math.Random().nextInt(pool.length)];
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.limeShock,
            border: Border(
              top: BorderSide(
                color: AppColors.ink,
                width: AppShadows.borderThick,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: IconHero(
                      icon: PhosphorIconsBold.confetti,
                      background: AppColors.electricPink,
                      size: 70,
                      animation: HeroAnim.wobble,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(hype, style: AppText.hero, textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text(
                    widget.task.title,
                    style: AppText.title,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  BrutalButton(
                    label: 'STACK THE WIN',
                    color: AppColors.toxicLime,
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
    unawaited(TimerMusic.instance.stop());
    unawaited(ActiveSessionStore.instance.clear());
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  border: AppShadows.solid(width: AppShadows.borderThin),
                  boxShadow: AppShadows.hard(offset: 5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'NOW DOING',
                      style: AppText.micro.copyWith(color: AppColors.white),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.task.title,
                      style: AppText.hero.copyWith(
                        fontSize: 22,
                        color: AppColors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6, bottom: 6),
                  child: AbstractTimerWidget(
                    remainingRatio: ratio,
                    stressLevel: stress,
                    label: _formatTime(_remainingMs),
                    fillColor: AppColors.water,
                    backColor: AppColors.paper,
                  ),
                ),
              ),
              const SizedBox(height: 50),
              Row(
                children: <Widget>[
                  Expanded(
                    child: BrutalButton(
                      label: _paused ? 'RESUME' : 'PAUSE',
                      color: _paused ? AppColors.safetyOrange : AppColors.white,
                      icon: _paused
                          ? PhosphorIconsBold.play
                          : PhosphorIconsBold.pause,
                      onPressed: _togglePause,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BrutalButton(
                      label: 'BAIL',
                      color: AppColors.white,
                      onPressed: _bail,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
