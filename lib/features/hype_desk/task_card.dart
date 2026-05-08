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

  @override
  Widget build(BuildContext context) {
    final Color cardColor = widget.isActive
        ? AppColors.limeShock
        : widget.color;
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
          // Lift slightly while pulsing — reads as "alive".
          final double lift = _down ? 4 : -2 * pulseT;
          final double shadow = (_down ? 2 : 6 + 2 * pulseT).toDouble();
          return Transform.translate(
            offset: Offset(_down ? 4 : 0, lift),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                border: AppShadows.solid(width: AppShadows.borderThick),
                boxShadow: AppShadows.hard(offset: shadow),
              ),
              child: child,
            ),
          );
        },
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.ink,
                border: AppShadows.solid(width: AppShadows.borderRegular),
              ),
              child: Text(
                _timeLabel(),
                style: AppText.title.copyWith(
                  color: AppColors.white,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.task.title,
                    style: AppText.hero.copyWith(fontSize: 22),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.isActive
                        ? 'NOW RUNNING · tap to jump in'
                        : 'Nudge ${widget.task.nudgeLeadTime.inMinutes}m · ${_durationLabel()}',
                    style: AppText.micro,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              widget.isActive
                  ? PhosphorIconsBold.lightning
                  : PhosphorIconsBold.play,
              color: AppColors.ink,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}
