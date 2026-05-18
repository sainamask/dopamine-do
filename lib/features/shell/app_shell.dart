import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../models/task.dart';
import '../../services/notification_service.dart';
import '../../state/tasks_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';
import '../action_chamber/action_chamber_screen.dart';
import '../glory_gallery/glory_gallery_screen.dart';
import '../hype_desk/hype_desk_screen.dart';
import '../takeover/takeover_screen.dart';

/// How often the in-app reminder watcher polls for due tasks.
const Duration _kDueCheckInterval = Duration(seconds: 20);

/// A task is considered "due now" if its scheduledAt is within this window
/// of the current time. Wide enough to catch slips between polls; narrow
/// enough that an old missed task doesn't suddenly fire.
const Duration _kDueWindow = Duration(minutes: 2);

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  Timer? _watcher;
  StreamSubscription<NotifTapEvent>? _notifTapSub;

  /// Task IDs we've already alerted the user about this session. Prevents
  /// re-popping the takeover every 20s for the same task.
  final Set<String> _alerted = <String>{};

  @override
  void initState() {
    super.initState();
    _watcher = Timer.periodic(_kDueCheckInterval, (_) => _checkDueTasks());
    // Run once on first frame too so an already-due task doesn't have to
    // wait a full interval after the app opens.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkDueTasks());

    // When the user taps the system notification (or one of its action
    // buttons), branch on the action so START goes straight to the chamber
    // and SNOOZE silently reschedules.
    _notifTapSub =
        NotificationService.instance.onTap.listen(_handleNotifTap);
  }

  @override
  void dispose() {
    _watcher?.cancel();
    _notifTapSub?.cancel();
    super.dispose();
  }

  Future<void> _handleNotifTap(NotifTapEvent event) async {
    if (!mounted) return;
    final List<Task> tasks =
        ref.read(tasksProvider).value ?? const <Task>[];
    final Task? task = tasks
        .where((Task t) => t.id == event.taskId && !t.completed)
        .firstOrNull;
    if (task == null) return;
    // Suppress the in-app watcher for this task so it doesn't double-fire.
    _alerted.add(task.id);

    switch (event.action) {
      case NotificationService.actionStart:
        // Skip the takeover — the user already chose. Start the session.
        ref.read(activeTaskIdProvider.notifier).set(task.id);
        ref.read(activeRunDurationProvider.notifier).set(task.duration);
        ref.read(shellTabProvider.notifier).set(ShellTab.action);
        return;
      case NotificationService.actionSnooze:
        // Bump the scheduled time by 3 minutes. tasks_provider.edit will
        // cancel the current alarm and re-arm it for the new time.
        final DateTime newWhen =
            DateTime.now().add(const Duration(minutes: 3));
        await ref
            .read(tasksProvider.notifier)
            .edit(task.copyWith(scheduledAt: newWhen));
        // Allow the in-app watcher to fire again at the new time.
        _alerted.remove(task.id);
        return;
      default:
        // Body tap (or unknown action) → open the takeover as before.
        _openTakeover(task);
    }
  }

  void _checkDueTasks() {
    if (!mounted) return;
    final List<Task> tasks =
        ref.read(tasksProvider).value ?? const <Task>[];
    final DateTime now = DateTime.now();
    final String? activeId = ref.read(activeTaskIdProvider);

    for (final Task t in tasks) {
      if (t.completed) continue;
      if (_alerted.contains(t.id)) continue;
      final Duration diff = t.scheduledAt.difference(now);
      // Fire only when the scheduled time has just passed (within the
      // due window). Future tasks and ancient missed tasks both skip.
      if (diff.inSeconds <= 0 && diff >= -_kDueWindow) {
        _alerted.add(t.id);
        if (activeId == null) {
          _openTakeover(t);
        } else {
          _showDueBanner(t);
        }
        return; // one alert at a time
      }
    }
  }

  Future<void> _openTakeover(Task task) async {
    if (!mounted) return;
    final TakeoverChoice? choice =
        await TakeoverScreen.show(context, task: task);
    if (!mounted) return;
    if (choice != TakeoverChoice.start) return;
    // Resolve the latest version (the user may have edited it on the
    // takeover) before starting the active session.
    final List<Task> latest =
        ref.read(tasksProvider).value ?? const <Task>[];
    final Task running = latest.firstWhere(
      (Task t) => t.id == task.id,
      orElse: () => task,
    );
    ref.read(activeTaskIdProvider.notifier).set(running.id);
    ref.read(activeRunDurationProvider.notifier).set(running.duration);
    ref.read(shellTabProvider.notifier).set(ShellTab.action);
  }

  void _showDueBanner(Task task) {
    final ScaffoldMessengerState? messenger =
        ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
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
            color: AppColors.safetyOrange,
            border: AppShadows.solid(width: AppShadows.borderRegular),
            boxShadow: AppShadows.hard(offset: 4),
          ),
          child: Row(
            children: <Widget>[
              Icon(PhosphorIconsBold.bellRinging,
                  color: AppColors.ink, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'DUE: ${task.title.toUpperCase()}',
                  style: AppText.button,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  messenger.hideCurrentSnackBar();
                  _openTakeover(task);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    border: AppShadows.solid(width: AppShadows.borderRegular),
                  ),
                  child: Text(
                    'OPEN',
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

  @override
  Widget build(BuildContext context) {
    final ShellTab tab = ref.watch(shellTabProvider);
    return Scaffold(
      body: IndexedStack(
        index: tab.index,
        children: const <Widget>[
          HypeDeskScreen(),
          ActionChamberScreen(),
          GloryGalleryScreen(),
        ],
      ),
      bottomNavigationBar: const _BrutalNavBar(),
    );
  }
}

class _BrutalNavBar extends ConsumerWidget {
  const _BrutalNavBar();

  static List<_TabSpec> get _tabs => <_TabSpec>[
        _TabSpec(
          ShellTab.hype,
          'HYPE',
          PhosphorIconsBold.fire,
          AppColors.limeShock,
        ),
        _TabSpec(
          ShellTab.action,
          'ACTION',
          PhosphorIconsBold.lightning,
          AppColors.electricPink,
        ),
        _TabSpec(
          ShellTab.glory,
          'GLORY',
          PhosphorIconsBold.trophy,
          AppColors.toxicLime,
        ),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShellTab current = ref.watch(shellTabProvider);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border(
          top: BorderSide(color: AppColors.ink, width: AppShadows.borderThick),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: <Widget>[
              for (final _TabSpec t in _tabs)
                Expanded(
                  child: _NavTab(
                    spec: t,
                    selected: current == t.tab,
                    onTap: () {
                      if (current == t.tab) return;
                      ref.read(shellTabProvider.notifier).set(t.tab);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec(this.tab, this.label, this.icon, this.color);
  final ShellTab tab;
  final String label;
  final IconData icon;
  final Color color;
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final _TabSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? spec.color : AppColors.white,
            border: AppShadows.solid(width: AppShadows.borderRegular),
            boxShadow: selected ? <BoxShadow>[] : AppShadows.hard(offset: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(spec.icon, size: 18, color: AppColors.ink),
              const SizedBox(height: 2),
              Text(spec.label, style: AppText.micro),
            ],
          ),
        ),
      ),
    );
  }
}
