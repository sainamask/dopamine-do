import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';
import '../../widgets/brutal_bottom_sheet.dart';
import '../../widgets/brutal_button.dart';
import '../../widgets/brutal_stepper.dart';
import 'quick_countdown_screen.dart';

class QuickCountdownSheet extends StatefulWidget {
  const QuickCountdownSheet({super.key});

  static Future<void> show(BuildContext context) {
    return NeubrutalBottomSheet.show<void>(
      context,
      color: AppColors.toxicLime,
      builder: (_) => const QuickCountdownSheet(),
    );
  }

  @override
  State<QuickCountdownSheet> createState() => _QuickCountdownSheetState();
}

class _QuickCountdownSheetState extends State<QuickCountdownSheet> {
  static const List<int> _presetSeconds = <int>[60, 120, 300];
  int _seconds = 120;

  bool _custom = false;
  int _customMin = 2;
  int _customSec = 0;

  int get _resolvedSeconds =>
      _custom ? (_customMin * 60 + _customSec).clamp(15, 60 * 60) : _seconds;

  void _go() {
    HapticFeedback.mediumImpact();
    final int secs = _resolvedSeconds;
    Navigator.of(context).pop();
    Future<void>.microtask(() {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              QuickCountdownScreen(duration: Duration(seconds: secs)),
        ),
      );
    });
  }

  String _label(int s) {
    if (s < 60) return '${s}s';
    final int m = s ~/ 60;
    final int rem = s % 60;
    return rem == 0 ? '${m}m' : '${m}m ${rem}s';
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
              width: 40,
              height: 3,
              decoration: BoxDecoration(color: AppColors.ink),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Icon(
                PhosphorIconsBold.timer,
                color: AppColors.ink,
                size: 16,
              ),
              const SizedBox(width: 5),
              Text('QUICK NUDGE', style: AppText.title),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Short burst. We start the second you tap GO.',
            style: AppText.body,
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              for (int i = 0; i < _presetSeconds.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: _Chip(
                    label: _label(_presetSeconds[i]),
                    selected: !_custom && _seconds == _presetSeconds[i],
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _custom = false;
                        _seconds = _presetSeconds[i];
                      });
                    },
                  ),
                ),
              ],
              const SizedBox(width: 6),
              Expanded(
                child: _Chip(
                  label: 'CUSTOM',
                  selected: _custom,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _custom = true);
                  },
                ),
              ),
            ],
          ),
          if (_custom) ...<Widget>[
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: BrutalStepper(
                    label: 'MIN',
                    value: _customMin,
                    min: 0,
                    max: 60,
                    suffix: 'm',
                    onChanged: (int v) => setState(() => _customMin = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: BrutalStepper(
                    label: 'SEC',
                    value: _customSec,
                    min: 0,
                    max: 55,
                    step: 5,
                    suffix: 's',
                    color: AppColors.electricPink,
                    onChanged: (int v) => setState(() => _customSec = v),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          BrutalButton(
            label: 'GO',
            color: AppColors.electricPink,
            textStyle: AppText.button.copyWith(color: AppColors.white),
            padding: const EdgeInsets.symmetric(vertical: 12),
            onPressed: _go,
          ),
        ],
      ),
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
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.white,
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
