import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../services/timer_music.dart';
import '../../state/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';
import '../../widgets/brutal_button.dart';

/// Below this many seconds remaining, the countdown is voiced ("99, 98…").
/// Above it, each tick is just a soft system click.
const int _kVoiceThresholdSec = 99;

class QuickCountdownScreen extends ConsumerStatefulWidget {
  const QuickCountdownScreen({super.key, required this.duration});

  final Duration duration;

  @override
  ConsumerState<QuickCountdownScreen> createState() =>
      _QuickCountdownScreenState();
}

class _QuickCountdownScreenState extends ConsumerState<QuickCountdownScreen> {
  late int _totalMs;
  late int _remainingMs;
  late DateTime _startedAt;
  Timer? _ticker;
  int _lastSecond = -1;
  bool _done = false;

  late final FlutterTts _tts;
  bool _ttsReady = false;

  @override
  void initState() {
    super.initState();
    _totalMs = widget.duration.inMilliseconds;
    _remainingMs = _totalMs;
    _startedAt = DateTime.now();
    _ticker = Timer.periodic(const Duration(milliseconds: 50), _onTick);

    _tts = FlutterTts();
    _initTts();
    unawaited(TimerMusic.instance.play());
  }

  Future<void> _initTts() async {
    try {
      await _tts.setSpeechRate(0.55);
      await _tts.setPitch(0.9);
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(false);
      _ttsReady = true;
    } catch (_) {
      _ttsReady = false;
    }
  }

  Future<void> _speak(String text) async {
    if (!_ttsReady) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {/* TTS is best-effort */}
  }

  @override
  void dispose() {
    _ticker?.cancel();
    unawaited(_tts.stop());
    unawaited(TimerMusic.instance.stop());
    super.dispose();
  }

  void _onTick(Timer _) {
    final int elapsed = DateTime.now().difference(_startedAt).inMilliseconds;
    final int remaining = (_totalMs - elapsed).clamp(0, _totalMs);
    final int second = (remaining / 1000).ceil();

    if (second != _lastSecond && remaining > 0) {
      _lastSecond = second;
      HapticFeedback.selectionClick();
      final bool voiceOn = ref
              .read(settingsProvider)
              .value
              ?.quickCountdownVoiceEnabled ??
          true;
      if (second <= _kVoiceThresholdSec && voiceOn) {
        unawaited(_speak(second.toString()));
      } else {
        SystemSound.play(SystemSoundType.click);
      }
    }

    if (mounted) setState(() => _remainingMs = remaining);

    if (remaining == 0 && !_done) {
      _done = true;
      _ticker?.cancel();
      HapticFeedback.mediumImpact();
      final bool voiceOn = ref
              .read(settingsProvider)
              .value
              ?.quickCountdownVoiceEnabled ??
          true;
      if (voiceOn) {
        unawaited(_speak('Done'));
      } else {
        SystemSound.play(SystemSoundType.alert);
      }
    }
  }

  void _close() {
    HapticFeedback.lightImpact();
    Navigator.of(context).maybePop();
  }

  String _formatRemaining() {
    final int totalSec = (_remainingMs / 1000).ceil();
    if (totalSec >= 60) {
      final int m = totalSec ~/ 60;
      final int s = totalSec % 60;
      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return totalSec.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    final double ratio = _totalMs == 0 ? 0 : _remainingMs / _totalMs;
    final Color ringColor = _done ? AppColors.toxicLime : AppColors.limeShock;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(PhosphorIconsBold.timer,
                      color: AppColors.ink, size: 16),
                  const SizedBox(width: 5),
                  Text('QUICK NUDGE', style: AppText.micro),
                  const Spacer(),
                  GestureDetector(
                    onTap: _close,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        border: AppShadows.solid(width: AppShadows.borderRegular),
                        boxShadow: AppShadows.hard(offset: 3),
                      ),
                      child: const Icon(PhosphorIconsBold.x,
                          color: AppColors.ink, size: 12),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _DrainRing(
                        ratio: ratio,
                        color: ringColor,
                        label: _done ? 'DONE' : _formatRemaining(),
                      ),
                    ),
                  ),
                ),
              ),
              if (_done)
                BrutalButton(
                  label: 'CLOSE',
                  color: AppColors.toxicLime,
                  onPressed: _close,
                )
              else
                BrutalButton(
                  label: 'BAIL',
                  color: AppColors.white,
                  onPressed: _close,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Brutalist drain ring: thick neon arc that empties counter-clockwise,
/// black inner + outer rims, digits in the center.
class _DrainRing extends StatelessWidget {
  const _DrainRing({
    required this.ratio,
    required this.color,
    required this.label,
  });

  final double ratio;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RingPainter(ratio: ratio.clamp(0, 1), color: color),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: FittedBox(
            child: Text(
              label,
              style: AppText.countdown.copyWith(fontSize: 54),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.ratio, required this.color});

  final double ratio;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double rOuter = math.min(size.width, size.height) / 2;
    const double thickness = 20;
    final double rMid = rOuter - thickness / 2 - 2;
    final double rInner = rOuter - thickness - 4;

    // Hard offset shadow.
    final Paint shadow = Paint()..color = AppColors.ink;
    canvas.drawCircle(c + const Offset(6, 6), rOuter, shadow);

    // Solid base disc (paper).
    canvas.drawCircle(c, rOuter, Paint()..color = AppColors.paper);

    // Drained lane — flat ink shadow inside the ring lane.
    final Paint lane = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: rMid),
      0,
      math.pi * 2,
      false,
      lane,
    );

    // Remaining arc.
    final Paint remaining = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: rMid),
      -math.pi / 2,
      math.pi * 2 * ratio,
      false,
      remaining,
    );

    // Inner + outer rims (thin, hard, brutalist).
    final Paint rim = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(c, rOuter, rim);
    canvas.drawCircle(c, rInner, rim);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.ratio != ratio || old.color != color;
}
