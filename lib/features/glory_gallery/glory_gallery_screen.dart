import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../models/task.dart';
import '../../state/tasks_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';
import '../../widgets/killed_it_badge.dart';
import '../settings/settings_screen.dart';

// Cool-first rotation: cyan + lavender + magenta lead, yellow last so it's
// rare not dominant.
List<Color> get _kPalette => <Color>[
      AppColors.cyan,
      AppColors.limeShock,
      AppColors.electricPink,
      AppColors.toxicLime,
      AppColors.safetyOrange,
      AppColors.neonYellow,
    ];

class GloryGalleryScreen extends ConsumerWidget {
  const GloryGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Task> done = ref.watch(completedTasksProvider);
    final CompletionStats stats = ref.watch(completionStatsProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
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
                        Text('THE GLORY GALLERY', style: AppText.hero),
                        const SizedBox(height: 3),
                        Text('YOUR HIGH-SCORE LIST.', style: AppText.micro),
                      ],
                    ),
                  ),
                  _SettingsButton(),
                ],
              ),
              const SizedBox(height: 12),
              _ScoreStrip(count: stats.total),
              const SizedBox(height: 10),
              _StreakStrip(stats: stats),
              const SizedBox(height: 12),
              Expanded(
                child: done.isEmpty
                    ? const _EmptyGlory()
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: done.length,
                        separatorBuilder: (BuildContext _, int _) =>
                            const SizedBox(height: 10),
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

class _SettingsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: AppShadows.solid(width: AppShadows.borderRegular),
          boxShadow: AppShadows.hard(offset: 3),
        ),
        child: Icon(
          PhosphorIconsBold.gear,
          color: AppColors.ink,
          size: 18,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.ink,
        border: AppShadows.solid(width: AppShadows.borderThick),
        boxShadow: AppShadows.hard(offset: 5),
      ),
      child: Row(
        children: <Widget>[
          Text('SCORE', style: AppText.micro.copyWith(color: AppColors.white)),
          const Spacer(),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: count.toDouble()),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (BuildContext _, double v, _) {
              return Text(
                v.round().toString().padLeft(4, '0'),
                style: AppText.hero.copyWith(
                  color: AppColors.white,
                  fontSize: 27,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StreakStrip extends StatelessWidget {
  const _StreakStrip({required this.stats});
  final CompletionStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatTile(
            label: 'STREAK',
            value: '${stats.currentStreak}',
            unit: stats.currentStreak == 1 ? 'DAY' : 'DAYS',
            color: AppColors.toxicLime,
            icon: PhosphorIconsBold.flame,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            label: 'BEST',
            value: '${stats.longestStreak}',
            unit: stats.longestStreak == 1 ? 'DAY' : 'DAYS',
            color: AppColors.cyan,
            icon: PhosphorIconsBold.trophy,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            label: '7-DAY',
            value: '${stats.lastSevenDays}',
            unit: stats.lastSevenDays == 1 ? 'WIN' : 'WINS',
            color: AppColors.electricYellow,
            icon: PhosphorIconsBold.lightning,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        border: AppShadows.solid(width: AppShadows.borderThin),
        boxShadow: AppShadows.hard(offset: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: AppColors.ink, size: 12),
              const SizedBox(width: 4),
              Text(label, style: AppText.micro.copyWith(fontSize: 9)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(value, style: AppText.hero.copyWith(fontSize: 18)),
              const SizedBox(width: 3),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(unit, style: AppText.micro.copyWith(fontSize: 8)),
              ),
            ],
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: AppShadows.solid(width: AppShadows.borderThick),
          boxShadow: AppShadows.hard(offset: 5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('NO WINS YET', style: AppText.hero.copyWith(fontSize: 20)),
            const SizedBox(height: 5),
            Text('GO KILL A TASK', style: AppText.micro),
          ],
        ),
      ),
    );
  }
}

class _GloryCard extends StatelessWidget {
  const _GloryCard({
    required this.task,
    required this.color,
    required this.rank,
  });
  final Task task;
  final Color color;
  final int rank;

  String _stamp(DateTime dt) {
    final String d =
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.day.toString().padLeft(2, '0')}';
    final String t =
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
    return '$d · $t';
  }

  String? _delta() {
    final Duration? actual = task.actualDuration;
    if (actual == null) return null;
    final int est = task.duration.inSeconds;
    if (est <= 0) return null;
    final double ratio = actual.inSeconds / est;
    final int pct = ((ratio - 1.0) * 100).round();
    if (pct.abs() <= 5) return 'ON TIME';
    return pct > 0 ? '+$pct% OVER' : '$pct% UNDER';
  }

  @override
  Widget build(BuildContext context) {
    final DateTime when = task.completedAt ?? task.scheduledAt;
    final String? delta = _delta();
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color,
        border: AppShadows.solid(width: AppShadows.borderThin),
        boxShadow: AppShadows.hard(offset: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.ink,
              border: AppShadows.solid(width: AppShadows.borderRegular),
            ),
            child: Text(
              '#${rank.toString().padLeft(2, '0')}',
              style: AppText.title.copyWith(
                color: AppColors.white,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  task.title,
                  style: AppText.hero.copyWith(fontSize: 19),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: <Widget>[
                    Text(_stamp(when), style: AppText.micro),
                    if (delta != null) ...<Widget>[
                      const SizedBox(width: 6),
                      Text('· $delta', style: AppText.micro),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const KilledItBadge(),
        ],
      ),
    );
  }
}
