import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../models/task.dart';
import '../../state/tasks_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';
import '../../widgets/brutal_button.dart';
import '../quick_countdown/quick_countdown_sheet.dart';
import '../takeover/takeover_screen.dart';
import 'add_task_sheet.dart';
import 'task_card.dart';

// Cool-first rotation. Cyan / lavender / magenta lead the queue;
// yellow is last so it stays an accent.
List<Color> get _cardPalette => <Color>[
  AppColors.toxicLime,
  AppColors.cyan,
  AppColors.electricYellow,
  AppColors.neonYellow,
  AppColors.safetyOrange,
  AppColors.limeShock,
  AppColors.electricPink,
];

Color _cardColorForId(String id) {
  int hash = 0;
  for (final int unit in id.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return _cardPalette[hash % _cardPalette.length];
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class HypeDeskScreen extends ConsumerWidget {
  const HypeDeskScreen({super.key});

  Future<void> _addTask(BuildContext context, WidgetRef ref) async {
    final Task? task = await AddTaskSheet.show(context);
    if (task == null) return;
    await ref.read(tasksProvider.notifier).add(task);
  }

  Future<void> _quickNudge(BuildContext context) async {
    await QuickCountdownSheet.show(context);
  }

  Future<void> _editTask(BuildContext context, WidgetRef ref, Task task) async {
    final EditTaskResult? result = await AddTaskSheet.showEdit(context, task);
    if (result == null) return;
    if (result.delete) {
      await ref.read(tasksProvider.notifier).remove(task.id);
      return;
    }
    if (result.task != null) {
      await ref.read(tasksProvider.notifier).edit(result.task!);
    }
  }

  /// Routes a tap on a TaskCard through the Play / Switch / Conflict logic.
  Future<void> _onTaskTap(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final String? activeId = ref.read(activeTaskIdProvider);

    // Already running THIS task → bypass takeover, jump to action.
    if (activeId == task.id) {
      ref.read(shellTabProvider.notifier).set(ShellTab.action);
      return;
    }

    // A DIFFERENT task is running → conflict.
    if (activeId != null) {
      final _ConflictChoice? c = await _showConflictAlert(context, ref);
      if (c == null || c == _ConflictChoice.cancel) return;
      _bailActive(ref);
      if (!context.mounted) return;
    }

    await _startTaskFlow(context, ref, task);
  }

  Future<void> _startTaskFlow(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final TakeoverChoice? choice = await TakeoverScreen.show(
      context,
      task: task,
    );
    if (choice == null || choice == TakeoverChoice.snooze) return;

    // The user may have edited the task on the takeover screen, so resolve
    // the latest version from the store before starting the session.
    final List<Task> latest = ref.read(tasksProvider).value ?? const <Task>[];
    final Task running = latest.firstWhere(
      (Task t) => t.id == task.id,
      orElse: () => task,
    );
    ref.read(activeTaskIdProvider.notifier).set(running.id);
    ref.read(activeRunDurationProvider.notifier).set(running.duration);
    ref.read(shellTabProvider.notifier).set(ShellTab.action);
  }

  void _bailActive(WidgetRef ref) {
    ref.read(activeTaskIdProvider.notifier).clear();
    ref.read(activeRunDurationProvider.notifier).set(null);
  }

  Widget _buildTaskRow(
    BuildContext context,
    WidgetRef ref,
    Task task,
    String? activeId,
  ) {
    return Dismissible(
      key: ValueKey<String>('task-${task.id}'),
      direction: DismissDirection.endToStart,
      background: const _DeleteSwipeBackground(),
      onDismissed: (_) {
        if (ref.read(activeTaskIdProvider) == task.id) {
          ref.read(activeTaskIdProvider.notifier).clear();
          ref.read(activeRunDurationProvider.notifier).set(null);
        }
        ref.read(tasksProvider.notifier).removeWithUndo(task.id, context);
      },
      child: TaskCard(
        task: task,
        color: _cardColorForId(task.id),
        isActive: activeId == task.id,
        onTap: () => _onTaskTap(context, ref, task),
        onLongPress: () => _editTask(context, ref, task),
      ),
    );
  }

  Future<_ConflictChoice?> _showConflictAlert(
    BuildContext context,
    WidgetRef ref,
  ) {
    return showDialog<_ConflictChoice>(
      context: context,
      barrierColor: AppColors.ink.withValues(alpha: 0.55),
      builder: (BuildContext ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.electricPink,
              border: AppShadows.solid(width: AppShadows.borderThick),
              boxShadow: AppShadows.hard(offset: 6),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      PhosphorIconsBold.warning,
                      color: AppColors.ink,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text('HOLD UP', style: AppText.hero.copyWith(fontSize: 24)),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Finish your current mission first.', style: AppText.body),
                const SizedBox(height: 14),
                BrutalButton(
                  label: 'BAIL CURRENT, START THIS',
                  color: AppColors.toxicLime,
                  onPressed: () =>
                      Navigator.of(ctx).pop(_ConflictChoice.bailCurrent),
                ),
                const SizedBox(height: 8),
                BrutalButton(
                  label: 'NEVER MIND',
                  color: AppColors.white,
                  onPressed: () =>
                      Navigator.of(ctx).pop(_ConflictChoice.cancel),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Task> upcoming = ref.watch(upcomingTasksProvider);
    final String? activeId = ref.watch(activeTaskIdProvider);
    final DateTime now = DateTime.now();
    final List<Task> today = upcoming
        .where((Task task) => _isSameDay(task.scheduledAt, now))
        .toList(growable: false);
    final List<Task> later = upcoming
        .where((Task task) => !_isSameDay(task.scheduledAt, now))
        .toList(growable: false);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('THE HYPE DESK', style: AppText.hero),
              const SizedBox(height: 3),
              Text("LOAD THE QUEUE. LET'S GO.", style: AppText.micro),
              const SizedBox(height: 12),
              _QuickNudgeStrip(onTap: () => _quickNudge(context)),
              const SizedBox(height: 12),
              Expanded(
                child: upcoming.isEmpty
                    ? _EmptyState(onPressed: () => _addTask(context, ref))
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 100),
                        children: <Widget>[
                          if (today.isNotEmpty) ...<Widget>[
                            const _TaskSectionHeader(label: 'TODAY'),
                            const SizedBox(height: 8),
                            for (final Task task in today) ...<Widget>[
                              _buildTaskRow(context, ref, task, activeId),
                              const SizedBox(height: 12),
                            ],
                          ],
                          if (later.isNotEmpty) ...<Widget>[
                            const _TaskSectionHeader(label: 'LATER'),
                            const SizedBox(height: 8),
                            for (final Task task in later) ...<Widget>[
                              _buildTaskRow(context, ref, task, activeId),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _BrutalFab(onPressed: () => _addTask(context, ref)),
    );
  }
}

enum _ConflictChoice { bailCurrent, cancel }

/// Shown behind a TaskCard when the user swipes left to delete it.
class _DeleteSwipeBackground extends StatelessWidget {
  const _DeleteSwipeBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.safetyOrange,
        border: AppShadows.solid(width: AppShadows.borderThick),
        boxShadow: AppShadows.hard(offset: 5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Text('DELETE', style: AppText.button),
          const SizedBox(width: 8),
          Icon(PhosphorIconsBold.trash, color: AppColors.ink, size: 22),
        ],
      ),
    );
  }
}

class _QuickNudgeStrip extends StatelessWidget {
  const _QuickNudgeStrip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.ink,
          border: AppShadows.solid(width: AppShadows.borderThick),
          boxShadow: AppShadows.hard(offset: 5),
        ),
        child: Row(
          children: <Widget>[
            Icon(PhosphorIconsBold.timer, color: AppColors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'QUICK NUDGE',
                    style: AppText.button.copyWith(color: AppColors.limeShock),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Short burst. No commitment.',
                    style: AppText.micro.copyWith(color: AppColors.white),
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorIconsBold.caretRight,
              color: AppColors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskSectionHeader extends StatelessWidget {
  const _TaskSectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(label, style: AppText.micro),
        const SizedBox(width: 8),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(color: AppColors.ink),
            child: const SizedBox(height: 2.5),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: AppShadows.solid(width: AppShadows.borderThick),
          boxShadow: AppShadows.hard(offset: 5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('QUEUE IS EMPTY', style: AppText.hero.copyWith(fontSize: 20)),
            const SizedBox(height: 5),
            Text('TAP + TO LOAD A TASK', style: AppText.micro),
          ],
        ),
      ),
    );
  }
}

class _BrutalFab extends StatefulWidget {
  const _BrutalFab({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_BrutalFab> createState() => _BrutalFabState();
}

class _BrutalFabState extends State<_BrutalFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);
  bool _down = false;

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onPressed();
      },
      child: AnimatedBuilder(
        animation: _idle,
        builder: (BuildContext _, Widget? child) {
          final double t = Curves.easeInOut.transform(_idle.value);
          final double scale = _down ? 0.94 : (1.0 + 0.04 * t);
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            color: AppColors.electricPink,
            border: AppShadows.solid(width: AppShadows.borderThick),
            boxShadow: AppShadows.hard(offset: _down ? 2 : 5),
          ),
          child: Icon(PhosphorIconsBold.plus, size: 26, color: AppColors.ink),
        ),
      ),
    );
  }
}
