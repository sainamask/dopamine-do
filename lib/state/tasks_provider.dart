import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_text.dart';

const String _kTasksKey = 'dopamine_do.tasks.v1';
const String _kActiveSessionKey = 'dopamine_do.active_session.v1';

/// Snapshot of an active Action Chamber run, persisted so we can resume
/// after an app kill / crash without losing the session.
class ActiveSession {
  const ActiveSession({
    required this.taskId,
    required this.totalMs,
    required this.startedAt,
    required this.elapsedAtPauseMs,
    required this.paused,
  });

  final String taskId;
  final int totalMs;
  final DateTime startedAt;
  final int elapsedAtPauseMs;
  final bool paused;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'taskId': taskId,
        'totalMs': totalMs,
        'startedAt': startedAt.toIso8601String(),
        'elapsedAtPauseMs': elapsedAtPauseMs,
        'paused': paused,
      };

  factory ActiveSession.fromJson(Map<String, dynamic> json) {
    return ActiveSession(
      taskId: json['taskId'] as String,
      totalMs: json['totalMs'] as int,
      startedAt: DateTime.parse(json['startedAt'] as String),
      elapsedAtPauseMs: json['elapsedAtPauseMs'] as int? ?? 0,
      paused: json['paused'] as bool? ?? false,
    );
  }
}

class TasksNotifier extends AsyncNotifier<List<Task>> {
  @override
  Future<List<Task>> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> raw = prefs.getStringList(_kTasksKey) ?? <String>[];
    final List<Task> tasks =
        raw
            .map((String s) {
              try {
                return Task.decode(s);
              } catch (_) {
                return null;
              }
            })
            .whereType<Task>()
            .toList()
          ..sort((Task a, Task b) => a.scheduledAt.compareTo(b.scheduledAt));
    return tasks;
  }

  Future<void> _persist(List<Task> tasks) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kTasksKey,
      tasks.map((Task t) => t.encode()).toList(),
    );
  }

  Future<void> add(Task task) async {
    final List<Task> current = state.value ?? <Task>[];
    final List<Task> next = <Task>[...current, task]
      ..sort((Task a, Task b) => a.scheduledAt.compareTo(b.scheduledAt));
    state = AsyncData<List<Task>>(next);
    await _persist(next);
  }

  /// Replace a task by id. Used by the edit/reschedule sheet.
  /// If `scheduledAt` changed to a different day/hour vs the previous, we
  /// bump `rescheduleCount` so the procrastination flag can trigger.
  Future<void> edit(Task updated) async {
    final List<Task> current = state.value ?? <Task>[];
    Task? previous;
    final List<Task> next = current.map((Task t) {
      if (t.id == updated.id) {
        previous = t;
        return updated;
      }
      return t;
    }).toList(growable: false)
      ..sort((Task a, Task b) => a.scheduledAt.compareTo(b.scheduledAt));

    // Auto-increment reschedule count when the user moves the time/date and
    // it's different from before (and the caller didn't explicitly set one).
    final Task? prev = previous;
    Task finalTask = updated;
    if (prev != null &&
        prev.scheduledAt != updated.scheduledAt &&
        updated.rescheduleCount == prev.rescheduleCount) {
      finalTask = updated.copyWith(
        rescheduleCount: prev.rescheduleCount + 1,
      );
      final List<Task> next2 = next
          .map((Task t) => t.id == finalTask.id ? finalTask : t)
          .toList(growable: false);
      state = AsyncData<List<Task>>(next2);
      await _persist(next2);
    } else {
      state = AsyncData<List<Task>>(next);
      await _persist(next);
    }
  }

  Future<void> remove(String id) async {
    final List<Task> current = state.value ?? <Task>[];
    final List<Task> next = current
        .where((Task t) => t.id != id)
        .toList(growable: false);
    state = AsyncData<List<Task>>(next);
    await _persist(next);
  }

  /// Remove with a snackbar that lets the user undo within ~5s.
  Future<void> removeWithUndo(String id, BuildContext context) async {
    final List<Task> current = state.value ?? <Task>[];
    final Task? snapshot = current.where((Task t) => t.id == id).firstOrNull;
    if (snapshot == null) return;
    await remove(id);
    if (!context.mounted) return;
    _showUndoSnack(
      context,
      message: 'TASK NUKED',
      onUndo: () async {
        await add(snapshot);
      },
    );
  }

  /// Mark a task completed. Records the actual time spent. Spawns the next
  /// occurrence if the task is recurring.
  Future<void> markCompleted(
    String id, {
    DateTime? at,
    Duration? actualDuration,
  }) async {
    final List<Task> current = state.value ?? <Task>[];
    final Task? source = current.where((Task t) => t.id == id).firstOrNull;
    if (source == null) return;
    final DateTime completedAt = at ?? DateTime.now();
    final List<Task> next = current
        .map(
          (Task t) => t.id == id
              ? t.copyWith(
                  completed: true,
                  completedAt: completedAt,
                  actualDuration: actualDuration ?? t.actualDuration,
                )
              : t,
        )
        .toList(growable: false);
    state = AsyncData<List<Task>>(next);
    await _persist(next);

    // If recurring, queue the next instance.
    if (source.recurrence != TaskRecurrence.none) {
      final DateTime? when = source.nextOccurrenceFrom(completedAt);
      if (when != null) {
        final Task spawn = Task(
          id: 't_${DateTime.now().microsecondsSinceEpoch}',
          title: source.title,
          scheduledAt: when,
          nudgeLeadTime: source.nudgeLeadTime,
          duration: source.duration,
          recurrence: source.recurrence,
          parentId: source.parentId ?? source.id,
        );
        await add(spawn);
      }
    }
  }

  /// Mark complete with an undo affordance. Restores the prior state if the
  /// user taps undo.
  Future<void> markCompletedWithUndo(
    String id,
    BuildContext context, {
    Duration? actualDuration,
  }) async {
    final List<Task> current = state.value ?? <Task>[];
    final Task? snapshot = current.where((Task t) => t.id == id).firstOrNull;
    if (snapshot == null) return;
    await markCompleted(id, actualDuration: actualDuration);
    if (!context.mounted) return;
    _showUndoSnack(
      context,
      message: 'TASK KILLED',
      onUndo: () async {
        // Revert the just-completed task to its prior state. The recurring
        // spawn (if any) is left in place — it's a future task, no harm done.
        final List<Task> latest = state.value ?? <Task>[];
        final List<Task> reverted = latest
            .map((Task t) => t.id == id ? snapshot : t)
            .toList(growable: false);
        state = AsyncData<List<Task>>(reverted);
        await _persist(reverted);
      },
    );
  }

  void _showUndoSnack(
    BuildContext context,
    {required String message, required Future<void> Function() onUndo}) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.maybeOf(context)
        ?? ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 5),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.electricYellow,
            border: AppShadows.solid(width: AppShadows.borderRegular),
            boxShadow: AppShadows.hard(offset: 4),
          ),
          child: Row(
            children: <Widget>[
              Expanded(child: Text(message, style: AppText.button)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  messenger.hideCurrentSnackBar();
                  await onUndo();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    border: AppShadows.solid(
                      width: AppShadows.borderRegular,
                    ),
                  ),
                  child: Text(
                    'UNDO',
                    style: AppText.button.copyWith(color: AppColors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final AsyncNotifierProvider<TasksNotifier, List<Task>> tasksProvider =
    AsyncNotifierProvider<TasksNotifier, List<Task>>(TasksNotifier.new);

// Slices for screens that don't want both buckets at once.
final Provider<List<Task>> upcomingTasksProvider = Provider<List<Task>>((
  Ref ref,
) {
  final List<Task> tasks = ref.watch(tasksProvider).value ?? const <Task>[];
  return tasks.where((Task t) => !t.completed).toList()
    ..sort((Task a, Task b) => a.scheduledAt.compareTo(b.scheduledAt));
});

final Provider<List<Task>> completedTasksProvider = Provider<List<Task>>((
  Ref ref,
) {
  final List<Task> tasks = ref.watch(tasksProvider).value ?? const <Task>[];
  final List<Task> done = tasks.where((Task t) => t.completed).toList()
    ..sort((Task a, Task b) {
      final DateTime da = a.completedAt ?? a.scheduledAt;
      final DateTime db = b.completedAt ?? b.scheduledAt;
      return db.compareTo(da); // newest first
    });
  return done;
});

/// Stats derived from completed tasks: total count, current streak, longest
/// streak, count for last 7 days. All cheap to recompute on every change.
class CompletionStats {
  const CompletionStats({
    required this.total,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastSevenDays,
    required this.avgOverrun,
  });

  final int total;
  final int currentStreak;
  final int longestStreak;
  final int lastSevenDays;

  /// Average ratio of actual vs scheduled duration across tasks that have it.
  /// 1.0 = on time, 1.2 = 20% over, 0.8 = 20% under. Null if not enough data.
  final double? avgOverrun;
}

final Provider<CompletionStats> completionStatsProvider = Provider<CompletionStats>((
  Ref ref,
) {
  final List<Task> done = ref.watch(completedTasksProvider);
  if (done.isEmpty) {
    return const CompletionStats(
      total: 0,
      currentStreak: 0,
      longestStreak: 0,
      lastSevenDays: 0,
      avgOverrun: null,
    );
  }

  // Map of yyyy-MM-dd → completed that day.
  final Set<String> days = <String>{};
  for (final Task t in done) {
    final DateTime when = t.completedAt ?? t.scheduledAt;
    days.add(
      '${when.year}-${when.month.toString().padLeft(2, '0')}-${when.day.toString().padLeft(2, '0')}',
    );
  }

  String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // Current streak: consecutive days back from today (allow today to be missed
  // — streak counts from yesterday in that case so the user isn't punished
  // for not having completed anything yet today).
  final DateTime today = DateTime.now();
  int current = 0;
  DateTime cursor = DateTime(today.year, today.month, today.day);
  if (!days.contains(dayKey(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
  }
  while (days.contains(dayKey(cursor))) {
    current++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  // Longest streak: walk all days in sorted order.
  final List<DateTime> sorted = days
      .map((String s) => DateTime.parse(s))
      .toList()
    ..sort((DateTime a, DateTime b) => a.compareTo(b));
  int longest = 0;
  int run = 0;
  DateTime? prev;
  for (final DateTime d in sorted) {
    if (prev == null) {
      run = 1;
    } else if (d.difference(prev).inDays == 1) {
      run += 1;
    } else {
      run = 1;
    }
    if (run > longest) longest = run;
    prev = d;
  }

  // Last 7 days.
  final DateTime sevenAgo = today.subtract(const Duration(days: 6));
  final int last7 = done.where((Task t) {
    final DateTime when = t.completedAt ?? t.scheduledAt;
    return !when.isBefore(DateTime(sevenAgo.year, sevenAgo.month, sevenAgo.day));
  }).length;

  // Avg overrun across tasks with actualDuration.
  final List<Task> withActual = done
      .where((Task t) => t.actualDuration != null && t.duration.inSeconds > 0)
      .toList();
  double? avg;
  if (withActual.isNotEmpty) {
    double sum = 0;
    for (final Task t in withActual) {
      sum += t.actualDuration!.inSeconds / t.duration.inSeconds;
    }
    avg = sum / withActual.length;
  }

  return CompletionStats(
    total: done.length,
    currentStreak: current,
    longestStreak: longest,
    lastSevenDays: last7,
    avgOverrun: avg,
  );
});

// Active task: the one currently being run in the Action Chamber.
class ActiveTaskIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) => state = id;
  void clear() => state = null;
}

final NotifierProvider<ActiveTaskIdNotifier, String?> activeTaskIdProvider =
    NotifierProvider<ActiveTaskIdNotifier, String?>(ActiveTaskIdNotifier.new);

final Provider<Task?> activeTaskProvider = Provider<Task?>((Ref ref) {
  final String? id = ref.watch(activeTaskIdProvider);
  if (id == null) return null;
  final List<Task> tasks = ref.watch(tasksProvider).value ?? const <Task>[];
  for (final Task t in tasks) {
    if (t.id == id) return t;
  }
  return null;
});

/// The duration to run the active task for. Distinct from `task.duration`
/// because the user may pick "Just 5 minutes" via the takeover.
class ActiveRunDurationNotifier extends Notifier<Duration?> {
  @override
  Duration? build() => null;

  void set(Duration? d) => state = d;
}

final NotifierProvider<ActiveRunDurationNotifier, Duration?>
activeRunDurationProvider =
    NotifierProvider<ActiveRunDurationNotifier, Duration?>(
      ActiveRunDurationNotifier.new,
    );

/// Persistence for in-flight Action Chamber sessions. Saves a snapshot so the
/// timer can resume after an app kill, crash, or background-evict.
class ActiveSessionStore {
  ActiveSessionStore._();
  static final ActiveSessionStore instance = ActiveSessionStore._();

  Future<void> save(ActiveSession session) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kActiveSessionKey, _encode(session));
  }

  Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kActiveSessionKey);
  }

  Future<ActiveSession?> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_kActiveSessionKey);
    if (raw == null) return null;
    try {
      return ActiveSession.fromJson(_decode(raw));
    } catch (_) {
      return null;
    }
  }

  String _encode(ActiveSession s) {
    final Map<String, dynamic> j = s.toJson();
    return '${j['taskId']}|${j['totalMs']}|${j['startedAt']}|${j['elapsedAtPauseMs']}|${j['paused']}';
  }

  Map<String, dynamic> _decode(String raw) {
    final List<String> parts = raw.split('|');
    return <String, dynamic>{
      'taskId': parts[0],
      'totalMs': int.parse(parts[1]),
      'startedAt': parts[2],
      'elapsedAtPauseMs': int.parse(parts[3]),
      'paused': parts[4] == 'true',
    };
  }
}

/// Bottom-nav tab selection.
enum ShellTab { hype, action, glory }

class ShellTabNotifier extends Notifier<ShellTab> {
  @override
  ShellTab build() => ShellTab.hype;

  void set(ShellTab tab) => state = tab;
}

final NotifierProvider<ShellTabNotifier, ShellTab> shellTabProvider =
    NotifierProvider<ShellTabNotifier, ShellTab>(ShellTabNotifier.new);
