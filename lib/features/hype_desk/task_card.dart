import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.color,
    required this.onTap,
    this.onLongPress,
  });

  final Task task;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  String _timeLabel() {
    final TimeOfDay t = TimeOfDay.fromDateTime(task.scheduledAt);
    final String hh = t.hour.toString().padLeft(2, '0');
    final String mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _durationLabel() {
    final int m = task.duration.inMinutes;
    return m < 60 ? '${m}M' : '${(m / 60).toStringAsFixed(m % 60 == 0 ? 0 : 1)}H';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          border: AppShadows.solid(width: AppShadows.borderThick),
          boxShadow: AppShadows.hard(offset: 6),
        ),
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
                  color: AppColors.neonYellow,
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
                    task.title.toUpperCase(),
                    style: AppText.hero.copyWith(fontSize: 22),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NUDGE ${task.nudgeLeadTime.inMinutes}M · ${_durationLabel()}',
                    style: AppText.micro,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.play_arrow_rounded,
                color: AppColors.ink, size: 36),
          ],
        ),
      ),
    );
  }
}
