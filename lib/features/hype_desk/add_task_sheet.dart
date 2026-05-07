import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';
import '../../widgets/brutal_bottom_sheet.dart';
import '../../widgets/brutal_button.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  static Future<Task?> show(BuildContext context) {
    return NeubrutalBottomSheet.show<Task>(
      context,
      color: AppColors.neonYellow,
      builder: (_) => const AddTaskSheet(),
    );
  }

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final TextEditingController _title = TextEditingController();
  TimeOfDay _start = TimeOfDay.now();
  Duration _lead = const Duration(minutes: 30);
  Duration _duration = const Duration(minutes: 30);

  static const List<Duration> _leadOptions = <Duration>[
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(minutes: 30),
  ];

  static const List<Duration> _durationOptions = <Duration>[
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(hours: 1),
  ];

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _start,
      builder: (BuildContext ctx, Widget? child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.electricPink,
              onPrimary: AppColors.ink,
              surface: AppColors.paper,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _start = picked);
    }
  }

  void _save() {
    final String title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NAME THE TASK FIRST')),
      );
      return;
    }
    final DateTime now = DateTime.now();
    DateTime scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      _start.hour,
      _start.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    final Task task = Task(
      id: 't_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      scheduledAt: scheduled,
      nudgeLeadTime: _lead,
      duration: _duration,
    );
    Navigator.of(context).pop(task);
  }

  String _formatLead(Duration d) =>
      d.inMinutes < 60 ? '${d.inMinutes}m' : '${d.inHours}h';

  @override
  Widget build(BuildContext context) {
    return Column(
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
        _BrutalField(
          controller: _title,
          hint: 'CLEAN ROOM',
          autofocus: true,
        ),
        const SizedBox(height: 18),
        _Label('START TIME'),
        const SizedBox(height: 6),
        _BrutalTapTile(
          label: _start.format(context),
          onTap: _pickTime,
          icon: Icons.access_time,
        ),
        const SizedBox(height: 18),
        _Label('NUDGE LEAD-TIME'),
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
        _BrutalChips<Duration>(
          options: _durationOptions,
          value: _duration,
          labelOf: _formatLead,
          onChanged: (Duration d) => setState(() => _duration = d),
        ),
        const SizedBox(height: 26),
        BrutalButton(
          label: 'SAVE TASK',
          color: AppColors.limeShock,
          padding: const EdgeInsets.symmetric(vertical: 20),
          onPressed: _save,
        ),
      ],
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
        textCapitalization: TextCapitalization.characters,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: AppShadows.solid(width: AppShadows.borderRegular),
          boxShadow: AppShadows.hard(offset: 4),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: AppColors.ink, size: 22),
            const SizedBox(width: 10),
            Text(label, style: AppText.title.copyWith(fontSize: 18)),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: AppColors.ink),
          ],
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
        return GestureDetector(
          onTap: () => onChanged(o),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.electricPink : AppColors.white,
              border: AppShadows.solid(width: AppShadows.borderRegular),
              boxShadow:
                  selected ? <BoxShadow>[] : AppShadows.hard(offset: 4),
            ),
            child: Text(
              labelOf(o),
              style: AppText.button.copyWith(
                color: selected ? AppColors.white : AppColors.ink,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
