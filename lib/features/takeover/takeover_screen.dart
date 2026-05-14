import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../models/task.dart';
import '../../state/settings_provider.dart';
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
  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
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
    HapticFeedback.lightImpact();
    widget.onChoice?.call(choice);
    Navigator.of(context).maybePop(choice);
  }

  Future<void> _editTitle() async {
    HapticFeedback.selectionClick();
    final Task task = _currentTask();
    final String? next = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
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
    HapticFeedback.selectionClick();
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
        colorScheme: const ColorScheme.light(
          primary: AppColors.electricPink,
          onPrimary: AppColors.ink,
          surface: AppColors.paper,
          onSurface: AppColors.ink,
        ),
        dialogTheme: const DialogThemeData(
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
    final bool calm = ref.watch(calmModeProvider);
    // Watch tasks so edits made via the title/time pencils update instantly.
    final List<Task> all = ref.watch(tasksProvider).value ?? const <Task>[];
    final Task task = all.firstWhere(
      (Task t) => t.id == widget.task.id,
      orElse: () => widget.task,
    );
    final TimeOfDay t = TimeOfDay.fromDateTime(task.scheduledAt);
    final String timeLabel = t.format(context);

    return Scaffold(
      backgroundColor: AppColors.vaporBlue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'TASK INCOMING',
                          style: AppText.title.copyWith(color: AppColors.white),
                        ),
                        const SizedBox(height: 8),
                        _TimePill(label: timeLabel, onTap: _editTime),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconHero(
                    icon: PhosphorIconsBold.bellRinging,
                    background: AppColors.white,
                    size: 64,
                    animation: calm ? HeroAnim.none : HeroAnim.wobble,
                  ),
                ],
              ),
              const SizedBox(height: 84),
              Expanded(
                child: _EditableTitleCard(title: task.title, onTap: _editTitle),
              ),
              const SizedBox(height: 84),
              const SizedBox(height: 14),
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
            const Icon(PhosphorIconsBold.clock, color: AppColors.ink, size: 12),
            const SizedBox(width: 6),
            Text(label, style: AppText.button),
            const SizedBox(width: 6),
            const Icon(
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: Text(
                    title,
                    style: AppText.hero.copyWith(fontSize: 28, height: 1.1),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                const Icon(
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
              const Icon(
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
