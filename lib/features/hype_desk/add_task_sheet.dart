import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../models/task.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';
import '../../widgets/brutal_bottom_sheet.dart';
import '../../widgets/brutal_button.dart';
import '../../widgets/brutal_stepper.dart';

/// Result of an edit session. If `delete` is true, the task should be removed.
/// Otherwise `task` is the updated task to persist.
class EditTaskResult {
  const EditTaskResult({this.task, this.delete = false});
  final Task? task;
  final bool delete;
}

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key, this.existing, this.prefillTitle});

  /// When not null, the sheet is in edit mode. Title becomes "EDIT TASK" and
  /// a delete affordance is shown. The result returned is an [EditTaskResult].
  final Task? existing;

  /// Pre-populate the title field (used by share-sheet / voice quick-add).
  final String? prefillTitle;

  static Future<Task?> show(BuildContext context, {String? prefillTitle}) {
    return NeubrutalBottomSheet.show<Task>(
      context,
      color: AppColors.cyan,
      builder: (_) => AddTaskSheet(prefillTitle: prefillTitle),
    );
  }

  static Future<EditTaskResult?> showEdit(BuildContext context, Task task) {
    return NeubrutalBottomSheet.show<EditTaskResult>(
      context,
      color: AppColors.cyan,
      builder: (_) => AddTaskSheet(existing: task),
    );
  }

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final TextEditingController _title = TextEditingController();
  late TimeOfDay _start;
  late DateTime _date;
  Duration _lead = const Duration(minutes: 30);

  Duration _preset = const Duration(minutes: 30);
  bool _customDuration = false;
  int _customHours = 0;
  int _customMinutes = 30;

  TaskRecurrence _recurrence = TaskRecurrence.none;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _listening = false;

  static const List<Duration> _leadOptions = <Duration>[
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(minutes: 30),
  ];

  static const List<Duration> _presetDurations = <Duration>[
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(hours: 1),
  ];

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final Task? existing = widget.existing;
    if (existing != null) {
      _title.text = existing.title;
      _date = existing.scheduledAt;
      _start = TimeOfDay.fromDateTime(existing.scheduledAt);
      _lead = existing.nudgeLeadTime;
      _recurrence = existing.recurrence;
      // Match the saved duration to a preset if possible; otherwise put it
      // into custom h/m so the user sees their value rather than a default.
      final Duration d = existing.duration;
      if (_presetDurations.contains(d)) {
        _preset = d;
      } else {
        _customDuration = true;
        _customHours = d.inHours;
        _customMinutes = d.inMinutes.remainder(60);
      }
    } else {
      final DateTime now = DateTime.now();
      _date = now;
      _start = _timeOfDayFromNow(now);
      if (widget.prefillTitle != null && widget.prefillTitle!.isNotEmpty) {
        _title.text = widget.prefillTitle!;
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    if (_listening) _speech.cancel();
    super.dispose();
  }

  Future<void> _toggleVoice() async {
    HapticFeedback.selectionClick();
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    final PermissionStatus mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (mounted) _showTopMessage('Mic permission needed for voice add');
      return;
    }

    final bool available = await _speech.initialize(
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
      onStatus: (String status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _listening = false);
        }
      },
    );
    if (!available) {
      if (mounted) _showTopMessage('Speech not available on this device');
      return;
    }

    if (!mounted) return;
    setState(() => _listening = true);
    HapticFeedback.mediumImpact();
    await _speech.listen(
      onResult: (result) {
        final String text = result.recognizedWords;
        if (text.isNotEmpty) {
          _title.text = text;
          _title.selection = TextSelection.collapsed(offset: text.length);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  Duration get _resolvedDuration => _customDuration
      ? Duration(hours: _customHours, minutes: _customMinutes)
      : _preset;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime get _scheduledAt =>
      DateTime(_date.year, _date.month, _date.day, _start.hour, _start.minute);

  TimeOfDay _timeOfDayFromNow(DateTime now) {
    final DateTime nextMinute = now.add(const Duration(minutes: 1));
    return TimeOfDay(hour: nextMinute.hour, minute: nextMinute.minute);
  }

  Future<void> _pickTime() async {
    HapticFeedback.selectionClick();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _start,
      builder: _brutalDialogTheme,
    );
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      builder: _brutalDialogTheme,
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        final DateTime now = DateTime.now();
        if (_isSameDay(_date, now) && _scheduledAt.isBefore(now)) {
          _start = _timeOfDayFromNow(now);
        }
      });
    }
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

  void _showTopMessage(String message) {
    showTopSnackBar(
      Overlay.of(context),
      Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.electricYellow,
              border: Border.all(color: AppColors.ink, width: 1),
              boxShadow: AppShadows.hard(),
            ),
            child: Text(message, style: AppText.body),
          ),
        ),
      ),
    );
  }

  void _save() {
    HapticFeedback.mediumImpact();

    final String title = _title.text.trim();

    if (title.isEmpty) {
      _showTopMessage('Name the task first');
      return;
    }

    final Duration duration = _resolvedDuration;

    if (duration.inMinutes <= 0) {
      _showTopMessage('Pick a duration');
      return;
    }

    final DateTime scheduled = _scheduledAt;

    if (!_isEditing && scheduled.isBefore(DateTime.now())) {
      _showTopMessage('Pick a time from now onward');
      return;
    }

    if (_isEditing) {
      final Task next = widget.existing!.copyWith(
        title: title,
        scheduledAt: scheduled,
        nudgeLeadTime: _lead,
        duration: duration,
        recurrence: _recurrence,
      );
      Navigator.of(context).pop(EditTaskResult(task: next));
    } else {
      final Task task = Task(
        id: 't_${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        scheduledAt: scheduled,
        nudgeLeadTime: _lead,
        duration: duration,
        recurrence: _recurrence,
      );
      Navigator.of(context).pop(task);
    }
  }

  void _delete() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(const EditTaskResult(delete: true));
  }

  String _formatLead(Duration d) =>
      d.inMinutes < 60 ? '${d.inMinutes}m' : '${d.inHours}h';

  String _formatDate(DateTime d) {
    const List<String> days = <String>[
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    final String day = days[d.weekday - 1];
    return '$day, ${d.month.toString().padLeft(2, '0')}/'
        '${d.day.toString().padLeft(2, '0')}';
  }

  String _recurrenceLabel(TaskRecurrence r) {
    switch (r) {
      case TaskRecurrence.none:
        return 'ONCE';
      case TaskRecurrence.daily:
        return 'DAILY';
      case TaskRecurrence.weekdays:
        return 'WEEKDAYS';
      case TaskRecurrence.weekly:
        return 'WEEKLY';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Container(
              width: 52,
              height: 5,
              decoration: const BoxDecoration(color: AppColors.ink),
            ),
          ),
          const SizedBox(height: 14),
          Text(_isEditing ? 'EDIT TASK' : 'NEW TASK', style: AppText.hero),
          const SizedBox(height: 3),
          Text(
            _isEditing ? 'TWEAK THE QUEUE' : 'LOAD THE QUEUE',
            style: AppText.micro,
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              _Label('TASK NAME'),
              const Spacer(),
              GestureDetector(
                onTap: _toggleVoice,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _listening
                        ? AppColors.electricPink
                        : AppColors.white,
                    border: AppShadows.solid(width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        _listening
                            ? PhosphorIconsBold.microphoneSlash
                            : PhosphorIconsBold.microphone,
                        color: AppColors.ink,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _listening ? 'LISTENING…' : 'VOICE',
                        style: AppText.micro.copyWith(fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          _BrutalField(
            controller: _title,
            hint: 'Clean room',
            autofocus: !_isEditing,
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _Label('DATE'),
                    const SizedBox(height: 5),
                    _BrutalTapTile(
                      label: _formatDate(_date),
                      icon: PhosphorIconsBold.calendarBlank,
                      onTap: _pickDate,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _Label('START'),
                    const SizedBox(height: 5),
                    _BrutalTapTile(
                      label: _start.format(context),
                      icon: PhosphorIconsBold.clock,
                      onTap: _pickTime,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Label('REMINDER'),
          const SizedBox(height: 5),
          _BrutalChips<Duration>(
            options: _leadOptions,
            value: _lead,
            labelOf: _formatLead,
            onChanged: (Duration d) => setState(() => _lead = d),
          ),
          const SizedBox(height: 14),
          _Label('DURATION'),
          const SizedBox(height: 5),
          _DurationPicker(
            presets: _presetDurations,
            preset: _preset,
            isCustom: _customDuration,
            onPreset: (Duration d) => setState(() {
              _customDuration = false;
              _preset = d;
            }),
            onCustomTap: () => setState(() => _customDuration = true),
            labelOf: _formatLead,
          ),
          if (_customDuration) ...<Widget>[
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: BrutalStepper(
                    label: 'HOURS',
                    value: _customHours,
                    min: 0,
                    max: 12,
                    suffix: 'h',
                    onChanged: (int v) => setState(() => _customHours = v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: BrutalStepper(
                    label: 'MINUTES',
                    value: _customMinutes,
                    min: 0,
                    max: 55,
                    step: 5,
                    suffix: 'm',
                    color: AppColors.electricPink,
                    onChanged: (int v) => setState(() => _customMinutes = v),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          _Label('REPEAT'),
          const SizedBox(height: 5),
          _BrutalChips<TaskRecurrence>(
            options: const <TaskRecurrence>[
              TaskRecurrence.none,
              TaskRecurrence.daily,
              TaskRecurrence.weekdays,
              TaskRecurrence.weekly,
            ],
            value: _recurrence,
            labelOf: _recurrenceLabel,
            onChanged: (TaskRecurrence r) => setState(() => _recurrence = r),
          ),
          const SizedBox(height: 20),
          BrutalButton(
            label: _isEditing ? 'SAVE CHANGES' : 'SAVE TASK',
            color: AppColors.toxicLime,
            padding: const EdgeInsets.symmetric(vertical: 16),
            onPressed: _save,
          ),
          if (_isEditing) ...<Widget>[
            const SizedBox(height: 10),
            BrutalButton(
              label: 'DELETE TASK',
              color: AppColors.safetyOrange,
              padding: const EdgeInsets.symmetric(vertical: 14),
              icon: PhosphorIconsBold.trash,
              onPressed: _delete,
            ),
          ],
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppText.micro);
  }
}

class _BrutalField extends StatelessWidget {
  const _BrutalField({
    required this.controller,
    required this.hint,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hint;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: AppShadows.solid(width: AppShadows.borderRegular),
        boxShadow: AppShadows.hard(offset: 3),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        textCapitalization: TextCapitalization.sentences,
        cursorColor: AppColors.ink,
        cursorWidth: 2,
        style: AppText.title.copyWith(fontSize: 15),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: AppText.title.copyWith(
            fontSize: 15,
            color: AppColors.ink.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

class _BrutalTapTile extends StatelessWidget {
  const _BrutalTapTile({
    required this.label,
    required this.onTap,
    required this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: AppShadows.solid(width: AppShadows.borderRegular),
          boxShadow: AppShadows.hard(offset: 3),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: AppColors.ink, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: AppText.title.copyWith(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationPicker extends StatelessWidget {
  const _DurationPicker({
    required this.presets,
    required this.preset,
    required this.isCustom,
    required this.onPreset,
    required this.onCustomTap,
    required this.labelOf,
  });

  final List<Duration> presets;
  final Duration preset;
  final bool isCustom;
  final ValueChanged<Duration> onPreset;
  final VoidCallback onCustomTap;
  final String Function(Duration) labelOf;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final Duration d in presets)
          _Chip(
            label: labelOf(d),
            selected: !isCustom && d == preset,
            onTap: () {
              HapticFeedback.selectionClick();
              onPreset(d);
            },
          ),
        _Chip(
          label: 'CUSTOM',
          selected: isCustom,
          onTap: () {
            HapticFeedback.selectionClick();
            onCustomTap();
          },
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.electricPink : AppColors.white,
          border: AppShadows.solid(width: AppShadows.borderRegular),
          boxShadow: selected ? <BoxShadow>[] : AppShadows.hard(offset: 3),
        ),
        child: Text(
          label,
          style: AppText.button.copyWith(
            color: selected ? AppColors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _BrutalChips<T> extends StatelessWidget {
  const _BrutalChips({
    required this.options,
    required this.value,
    required this.labelOf,
    required this.onChanged,
  });

  final List<T> options;
  final T value;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((T o) {
        final bool selected = o == value;
        return _Chip(
          label: labelOf(o),
          selected: selected,
          onTap: () => onChanged(o),
        );
      }).toList(),
    );
  }
}
