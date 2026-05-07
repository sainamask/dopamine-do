import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task.dart';
import '../../state/tasks_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';
import '../takeover/takeover_screen.dart';
import 'add_task_sheet.dart';
import 'task_card.dart';

const List<Color> _cardPalette = <Color>[
  AppColors.neonYellow,
  AppColors.cyan,
  AppColors.electricPink,
  AppColors.limeShock,
  AppColors.safetyOrange,
];

class HypeDeskScreen extends ConsumerWidget {
  const HypeDeskScreen({super.key});

  Future<void> _addTask(BuildContext context, WidgetRef ref) async {
    final Task? task = await AddTaskSheet.show(context);
    if (task == null) return;
    await ref.read(tasksProvider.notifier).add(task);
  }

  Future<void> _startTask(BuildContext context, WidgetRef ref, Task task) async {
    final TimeOfDay t = TimeOfDay.fromDateTime(task.scheduledAt);
    final TakeoverChoice? choice = await TakeoverScreen.show(
      context,
      taskTitle: task.title,
      scheduledLabel: 'SCHEDULED · ${t.format(context)}',
    );
    if (choice == null || choice == TakeoverChoice.snooze) return;

    final Duration runFor = choice == TakeoverChoice.justFiveMinutes
        ? const Duration(minutes: 5)
        : task.duration;

    ref.read(activeTaskIdProvider.notifier).set(task.id);
    ref.read(activeRunDurationProvider.notifier).set(runFor);
    ref.read(shellTabProvider.notifier).set(ShellTab.action);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Task> upcoming = ref.watch(upcomingTasksProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('THE HYPE DESK', style: AppText.hero),
              const SizedBox(height: 4),
              Text('LOAD THE QUEUE. LET\'S GO.', style: AppText.micro),
              const SizedBox(height: 18),
              Expanded(
                child: upcoming.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: upcoming.length,
                        separatorBuilder: (BuildContext _, int _) =>
                            const SizedBox(height: 14),
                        itemBuilder: (BuildContext _, int i) {
                          final Task t = upcoming[i];
                          return TaskCard(
                            task: t,
                            color: _cardPalette[i % _cardPalette.length],
                            onTap: () => _startTask(context, ref, t),
                            onLongPress: () =>
                                ref.read(tasksProvider.notifier).remove(t.id),
                          );
                        },
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: AppShadows.solid(width: AppShadows.borderThick),
          boxShadow: AppShadows.hard(offset: 6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('QUEUE IS EMPTY', style: AppText.hero.copyWith(fontSize: 24)),
            const SizedBox(height: 6),
            Text('TAP + TO LOAD A TASK', style: AppText.micro),
          ],
        ),
      ),
    );
  }
}

class _BrutalFab extends StatelessWidget {
  const _BrutalFab({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          color: AppColors.electricPink,
          border: AppShadows.solid(width: AppShadows.borderThick),
          boxShadow: AppShadows.hard(offset: 6),
        ),
        child: const Icon(Icons.add, size: 36, color: AppColors.ink),
      ),
    );
  }
}
