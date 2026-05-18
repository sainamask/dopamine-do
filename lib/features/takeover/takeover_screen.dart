import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../models/task.dart';
import '../../state/tasks_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';
import '../../widgets/brutal_button.dart';
import '../../widgets/icon_hero.dart';

enum TakeoverChoice { start, snooze }

/// Mustard takeover screen. Calm — fades in, no bouncing.
class TakeoverScreen extends ConsumerStatefulWidget {
  const TakeoverScreen({super.key, required this.task, this.onChoice});

  final Task task;
  final ValueChanged<TakeoverChoice>? onChoice;

  static Future<TakeoverChoice?> show(
    BuildContext context, {
    required Task task,
  }) {
    return Navigator.of(context).push<TakeoverChoice>(
      PageRouteBuilder<TakeoverChoice>(
        opaque: true,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 160),
        pageBuilder:
            (BuildContext _, Animation<double> _, Animation<double> _) =>
                TakeoverScreen(task: task),
        transitionsBuilder:
            (
              BuildContext _,
              Animation<double> anim,
              Animation<double> _,
              Widget child,
            ) {
              return FadeTransition(opacity: anim, child: child);
            },
      ),
    );
  }

  @override
  ConsumerState<TakeoverScreen> createState() => _TakeoverScreenState();
}

class _TakeoverScreenState extends ConsumerState<TakeoverScreen> {
  Timer? _alarm;
  int _alarmRings = 0;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _startAlarm();
  }

  /// Beep on open, then every 1.5s for ~8 rings (~12s of audible nag)
  /// before going quiet on its own. Resolving the takeover cuts it short.
  void _startAlarm() {
    SystemSound.play(SystemSoundType.alert);
    _alarmRings = 1;
    _alarm = Timer.periodic(const Duration(milliseconds: 1500), (Timer t) {
      if (_alarmRings >= 8) {
        t.cancel();
        _alarm = null;
        return;
      }
      SystemSound.play(SystemSoundType.alert);
      _alarmRings++;
    });
  }

  void _stopAlarm() {
    _alarm?.cancel();
    _alarm = null;
  }

  @override
  void dispose() {
    _stopAlarm();
    super.dispose();
  }

  /// Always reads the freshest task from the provider so inline edits made
  /// on this screen reflect immediately. Falls back to the initial task if
  /// it has somehow been removed.
  Task _currentTask() {
    final List<Task> all = ref.read(tasksProvider).value ?? const <Task>[];
    return all.firstWhere(
      (Task t) => t.id == widget.task.id,
      orElse: () => widget.task,
    );
  }

  void _resolve(TakeoverChoice choice) {
    _stopAlarm();
    widget.onChoice?.call(choice);
    Navigator.of(context).maybePop(choice);
  }

  Future<void> _editTitle() async {
    final Task task = _currentTask();
    final String? next = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.ink, width: AppShadows.borderThick),
      ),
      builder: (BuildContext ctx) => _EditTitleSheet(initial: task.title),
    );
    if (next == null) return;
    final String trimmed = next.trim();
    if (trimmed.isEmpty || trimmed == task.title) return;
    await ref.read(tasksProvider.notifier).edit(task.copyWith(title: trimmed));
  }

  Future<void> _editTime() async {
    final Task task = _currentTask();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(task.scheduledAt),
      builder: _brutalDialogTheme,
    );
    if (picked == null) return;
    final DateTime current = task.scheduledAt;
    final DateTime next = DateTime(
      current.year,
      current.month,
      current.day,
      picked.hour,
      picked.minute,
    );
    if (next == current) return;
    await ref
        .read(tasksProvider.notifier)
        .edit(task.copyWith(scheduledAt: next));
  }

  Widget _brutalDialogTheme(BuildContext ctx, Widget? child) {
    return Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: ColorScheme.light(
          primary: AppColors.electricPink,
          onPrimary: AppColors.ink,
          surface: AppColors.paper,
          onSurface: AppColors.ink,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.paper,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: AppColors.ink,
              width: AppShadows.borderThick,
            ),
          ),
        ),
      ),
      child: child!,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch tasks so edits made via the title/time pencils update instantly.
    final List<Task> all = ref.watch(tasksProvider).value ?? const <Task>[];
    final Task task = all.firstWhere(
      (Task t) => t.id == widget.task.id,
      orElse: () => widget.task,
    );
    final TimeOfDay t = TimeOfDay.fromDateTime(task.scheduledAt);
    final String timeLabel = t.format(context);

    return Scaffold(
      backgroundColor: AppColors.safetyOrange,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    PhosphorIconsBold.bellRinging,
                    color: AppColors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TASK INCOMING',
                    style: AppText.hero.copyWith(
                      color: AppColors.white,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Center(child: _BellWithWaves()),
                      const SizedBox(height: 18),
                      Center(
                        child: _TimePill(
                          label: timeLabel,
                          onTap: _editTime,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _EditableTitleCard(
                        title: task.title,
                        onTap: _editTitle,
                      ),
                    ],
                  ),
                ),
              ),
              BrutalButton(
                label: "I'M ON IT",
                color: AppColors.toxicLime,
                padding: const EdgeInsets.symmetric(vertical: 18),
                onPressed: () => _resolve(TakeoverChoice.start),
              ),
              const SizedBox(height: 10),
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

/// Big bell with three concentric "sound wave" rings pulsing outward.
/// The bell wobbles via [IconHero]; the rings expand + fade on a continuous
/// loop, evenly phase-offset so one's always going.
class _BellWithWaves extends StatefulWidget {
  const _BellWithWaves();

  @override
  State<_BellWithWaves> createState() => _BellWithWavesState();
}

class _BellWithWavesState extends State<_BellWithWaves>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (BuildContext context, _) {
        return SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              for (int i = 0; i < 3; i++)
                _Ring(phase: (_ctrl.value + i * 0.33) % 1.0),
              IconHero(
                icon: PhosphorIconsBold.bellRinging,
                background: AppColors.white,
                size: 130,
                animation: HeroAnim.wobble,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.phase});
  final double phase;

  @override
  Widget build(BuildContext context) {
    final double scale = 0.55 + phase * 1.65;
    final double alpha = (1 - phase).clamp(0.0, 1.0) * 0.55;
    return IgnorePointer(
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.white.withValues(alpha: alpha),
              width: 3,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: AppShadows.solid(width: AppShadows.borderRegular),
          boxShadow: AppShadows.hard(offset: 3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(PhosphorIconsBold.clock, color: AppColors.ink, size: 12),
            const SizedBox(width: 6),
            Text(label, style: AppText.button),
            const SizedBox(width: 6),
            Icon(
              PhosphorIconsBold.pencilSimple,
              color: AppColors.ink,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableTitleCard extends StatelessWidget {
  const _EditableTitleCard({required this.title, required this.onTap});
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: AppShadows.solid(width: AppShadows.borderThick),
          boxShadow: AppShadows.hard(offset: 6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              title,
              style: AppText.hero.copyWith(fontSize: 28, height: 1.1),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Icon(
                  PhosphorIconsBold.pencilSimple,
                  color: AppColors.ink,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text('TAP TO EDIT', style: AppText.micro),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditTitleSheet extends StatefulWidget {
  const _EditTitleSheet({required this.initial});
  final String initial;

  @override
  State<_EditTitleSheet> createState() => _EditTitleSheetState();
}

class _EditTitleSheetState extends State<_EditTitleSheet> {
  late final TextEditingController _controller;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 16, 18, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                PhosphorIconsBold.pencilSimple,
                color: AppColors.ink,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text('EDIT TASK', style: AppText.title),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: AppShadows.solid(width: AppShadows.borderRegular),
              boxShadow: AppShadows.hard(offset: 3),
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              maxLines: null,
              cursorColor: AppColors.ink,
              cursorWidth: 2,
              style: AppText.title.copyWith(fontSize: 16),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          const SizedBox(height: 14),
          BrutalButton(
            label: 'SAVE',
            color: AppColors.toxicLime,
            padding: const EdgeInsets.symmetric(vertical: 14),
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
