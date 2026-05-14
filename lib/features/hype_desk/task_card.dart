import 'package:dopamine_do/services/date_time_ext.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../models/task.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';

class TaskCard extends StatefulWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.color,
    required this.onTap,
    this.onLongPress,
    this.isActive = false,
  });

  final Task task;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isActive;

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _down = false;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant TaskCard old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.isActive && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  String _timeLabel() {
    final TimeOfDay t = TimeOfDay.fromDateTime(widget.task.scheduledAt);
    final String hh = t.hour.toString().padLeft(2, '0');
    final String mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _durationLabel() {
    final int m = widget.task.duration.inMinutes;
    return m < 60
        ? '${m}m'
        : '${(m / 60).toStringAsFixed(m % 60 == 0 ? 0 : 1)}h';
  }

  String _recurrenceLabel() {
    switch (widget.task.recurrence) {
      case TaskRecurrence.daily:
        return '· DAILY';
      case TaskRecurrence.weekdays:
        return '· WEEKDAYS';
      case TaskRecurrence.weekly:
        return '· WEEKLY';
      case TaskRecurrence.none:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color cardColor = widget.isActive
        ? AppColors.limeShock
        : widget.color;
    final bool procrastinated = widget.task.isProcrastinated;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (BuildContext _, Widget? child) {
          final double pulseT = widget.isActive
              ? Curves.easeInOut.transform(_pulse.value)
              : 0.0;
          final double lift = _down ? 3 : -1 * pulseT;
          final double shadow = (_down ? 1 : 3 + 1 * pulseT).toDouble();
          return Transform.translate(
            offset: Offset(_down ? 4 : 0, lift),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardColor,
                border: AppShadows.solid(width: AppShadows.borderThin),
                boxShadow: AppShadows.hard(offset: shadow),
              ),
              child: child,
            ),
          );
        },
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.ink,
                border: AppShadows.solid(width: AppShadows.borderRegular),
              ),
              child: Text(
                _durationLabel(),
                style: AppText.title.copyWith(
                  color: AppColors.white,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.task.title,
                    style: AppText.hero.copyWith(fontSize: 19),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.isActive
                        ? 'NOW RUNNING · tap to jump in'
                        : 'Task · ${widget.task.scheduledAt.dateMonthAbv} · ${_timeLabel()} ${_recurrenceLabel()}',
                    style: AppText.micro,
                  ),
                  if (procrastinated) ...<Widget>[
                    const SizedBox(height: 6),
                    _ProcrastinationChip(count: widget.task.rescheduleCount),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              widget.isActive
                  ? PhosphorIconsBold.lightning
                  : PhosphorIconsBold.play,
              color: AppColors.ink,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcrastinationChip extends StatelessWidget {
  const _ProcrastinationChip({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.safetyOrange,
        border: AppShadows.solid(width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            PhosphorIconsBold.warning,
            color: AppColors.ink,
            size: 12,
          ),
          const SizedBox(width: 5),
          Text(
            'PUSHED $count× · BREAK IT DOWN?',
            style: AppText.micro.copyWith(fontSize: 9),
          ),
        ],
      ),
    );
  }
}
