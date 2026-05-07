import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task.dart';
import '../../state/tasks_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';
import '../../widgets/killed_it_badge.dart';

const List<Color> _kPalette = <Color>[
  AppColors.neonYellow,
  AppColors.cyan,
  AppColors.limeShock,
  AppColors.electricPink,
  AppColors.safetyOrange,
];

class GloryGalleryScreen extends ConsumerWidget {
  const GloryGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Task> done = ref.watch(completedTasksProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('THE GLORY GALLERY', style: AppText.hero),
              const SizedBox(height: 4),
              Text('YOUR HIGH-SCORE LIST.', style: AppText.micro),
              const SizedBox(height: 14),
              _ScoreStrip(count: done.length),
              const SizedBox(height: 14),
              Expanded(
                child: done.isEmpty
                    ? const _EmptyGlory()
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: done.length,
                        separatorBuilder: (BuildContext _, int _) =>
                            const SizedBox(height: 12),
                        itemBuilder: (BuildContext _, int i) {
                          return _GloryCard(
                            task: done[i],
                            color: _kPalette[i % _kPalette.length],
                            rank: i + 1,
                          );
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

class _ScoreStrip extends StatelessWidget {
  const _ScoreStrip({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.ink,
        border: AppShadows.solid(width: AppShadows.borderThick),
        boxShadow: AppShadows.hard(offset: 6),
      ),
      child: Row(
        children: <Widget>[
          Text(
            'SCORE',
            style: AppText.micro.copyWith(color: AppColors.neonYellow),
          ),
          const Spacer(),
          Text(
            count.toString().padLeft(4, '0'),
            style: AppText.hero.copyWith(
              color: AppColors.neonYellow,
              fontSize: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyGlory extends StatelessWidget {
  const _EmptyGlory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: AppShadows.solid(width: AppShadows.borderThick),
          boxShadow: AppShadows.hard(offset: 6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('NO WINS YET', style: AppText.hero.copyWith(fontSize: 24)),
            const SizedBox(height: 6),
            Text('GO KILL A TASK', style: AppText.micro),
          ],
        ),
      ),
    );
  }
}

class _GloryCard extends StatelessWidget {
  const _GloryCard({required this.task, required this.color, required this.rank});
  final Task task;
  final Color color;
  final int rank;

  String _stamp(DateTime dt) {
    final String d = '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.day.toString().padLeft(2, '0')}';
    final String t = '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
    return '$d · $t';
  }

  @override
  Widget build(BuildContext context) {
    final DateTime when = task.completedAt ?? task.scheduledAt;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        border: AppShadows.solid(width: AppShadows.borderThick),
        boxShadow: AppShadows.hard(offset: 6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.ink,
              border: AppShadows.solid(width: AppShadows.borderRegular),
            ),
            child: Text(
              '#${rank.toString().padLeft(2, '0')}',
              style: AppText.title.copyWith(
                color: AppColors.neonYellow,
                fontSize: 16,
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
                Text(_stamp(when), style: AppText.micro),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const KilledItBadge(),
        ],
      ),
    );
  }
}
