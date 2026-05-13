import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../models/task.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';
import '../../widgets/brutal_bottom_sheet.dart';
import '../../widgets/brutal_button.dart';
import '../../widgets/brutal_stepper.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  static Future<Task?> show(BuildContext context) {
    return NeubrutalBottomSheet.show<Task>(
      context,
      color: AppColors.cyan,
      builder: (_) => const AddTaskSheet(),
    );
  }

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final TextEditingController _title = TextEditingController();
  TimeOfDay _start = TimeOfDay.now();
  DateTime _date = DateTime.now();
  Duration _lead = const Duration(minutes: 30);

  // Duration: either a preset or custom (h, m).
  Duration _preset = const Duration(minutes: 30);
  bool _customDuration = false;
  int _customHours = 0;
  int _customMinutes = 30;

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

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Duration get _resolvedDuration => _customDuration
      ? Duration(hours: _customHours, minutes: _customMinutes)
      : _preset;

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
    if (picked != null) setState(() => _date = picked);
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

  void _save() {
    HapticFeedback.mediumImpact();
    final String title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name the task first')));
      return;
    }
    final Duration duration = _resolvedDuration;
    if (duration.inMinutes <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pick a duration')));
      return;
    }
    final DateTime scheduled = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _start.hour,
      _start.minute,
    );
    final Task task = Task(
      id: 't_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      scheduledAt: scheduled,
      nudgeLeadTime: _lead,
      duration: duration,
    );
    Navigator.of(context).pop(task);
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Container(
              width: 64,
              height: 6,
              decoration: const BoxDecoration(color: AppColors.ink),
            ),
          ),
          const SizedBox(height: 16),
          Text('NEW TASK', style: AppText.hero),
          const SizedBox(height: 4),
          Text('LOAD THE QUEUE', style: AppText.micro),
          const SizedBox(height: 22),
          _Label('TASK NAME'),
          const SizedBox(height: 6),
          _BrutalField(controller: _title, hint: 'Clean room', autofocus: true),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _Label('DATE'),
                    const SizedBox(height: 6),
                    _BrutalTapTile(
                      label: _formatDate(_date),
                      icon: PhosphorIconsBold.calendarBlank,
                      onTap: _pickDate,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _Label('START'),
                    const SizedBox(height: 6),
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
          const SizedBox(height: 18),
          _Label('REMINDER'),
          const SizedBox(height: 6),
          _BrutalChips<Duration>(
            options: _leadOptions,
            value: _lead,
            labelOf: _formatLead,
            onChanged: (Duration d) => setState(() => _lead = d),
          ),
          const SizedBox(height: 18),
          _Label('DURATION'),
          const SizedBox(height: 6),
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
            const SizedBox(height: 14),
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
                const SizedBox(width: 12),
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
          const SizedBox(height: 24),
          BrutalButton(
            label: 'SAVE TASK',
            color: AppColors.toxicLime,
            padding: const EdgeInsets.symmetric(vertical: 20),
            onPressed: _save,
          ),
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
        boxShadow: AppShadows.hard(offset: 4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        textCapitalization: TextCapitalization.sentences,
        cursorColor: AppColors.ink,
        cursorWidth: 3,
        style: AppText.title.copyWith(fontSize: 18),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: AppText.title.copyWith(
            fontSize: 18,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: AppShadows.solid(width: AppShadows.borderRegular),
          boxShadow: AppShadows.hard(offset: 4),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: AppColors.ink, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppText.title.copyWith(fontSize: 16),
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
      spacing: 10,
      runSpacing: 10,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.electricPink : AppColors.white,
          border: AppShadows.solid(width: AppShadows.borderRegular),
          boxShadow: selected ? <BoxShadow>[] : AppShadows.hard(offset: 4),
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
      spacing: 10,
      runSpacing: 10,
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
