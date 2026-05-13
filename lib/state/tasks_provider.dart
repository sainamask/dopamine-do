import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';

const String _kTasksKey = 'dopamine_do.tasks.v1';

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

  Future<void> remove(String id) async {
    final List<Task> current = state.value ?? <Task>[];
    final List<Task> next = current
        .where((Task t) => t.id != id)
        .toList(growable: false);
    state = AsyncData<List<Task>>(next);
    await _persist(next);
  }

  Future<void> markCompleted(String id, {DateTime? at}) async {
    final List<Task> current = state.value ?? <Task>[];
    final List<Task> next = current
        .map(
          (Task t) => t.id == id
              ? t.copyWith(completed: true, completedAt: at ?? DateTime.now())
              : t,
        )
        .toList(growable: false);
    state = AsyncData<List<Task>>(next);
    await _persist(next);
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

/// Bottom-nav tab selection.
enum ShellTab { hype, action, glory }

class ShellTabNotifier extends Notifier<ShellTab> {
  @override
  ShellTab build() => ShellTab.hype;

  void set(ShellTab tab) => state = tab;
}

final NotifierProvider<ShellTabNotifier, ShellTab> shellTabProvider =
    NotifierProvider<ShellTabNotifier, ShellTab>(ShellTabNotifier.new);
