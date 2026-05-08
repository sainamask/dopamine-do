import 'package:audioplayers/audioplayers.dart';

/// Background music for the Quick Nudge + Action Chamber timers.
///
/// Streams from a remote URL — set [streamUrl] to any direct audio URL
/// (an .mp3 / .m4a / .ogg endpoint, NOT an HTML page).
///
/// Free lo-fi / focus streams that work as-is can be pasted here, e.g.:
///   https://stream.zeno.fm/0r0xa792kwzuv  (lofi.fm-style 24/7 stream)
///   https://your-cdn.example/focus.mp3
class TimerMusic {
  TimerMusic._();
  static final TimerMusic instance = TimerMusic._();

  /// Edit this to point at your audio. Leave empty to disable music silently.
  static const String streamUrl = '';

  final AudioPlayer _player = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
  bool _started = false;

  Future<void> play() async {
    if (streamUrl.isEmpty) return;
    try {
      if (!_started) {
        await _player.play(UrlSource(streamUrl), volume: 0.6);
        _started = true;
      } else {
        await _player.resume();
      }
    } catch (_) {
      // Best-effort: a busted URL or no network shouldn't crash the timer.
    }
  }

  Future<void> pause() async {
    if (!_started) return;
    try {
      await _player.pause();
    } catch (_) {/* best-effort */}
  }

  Future<void> stop() async {
    if (!_started) return;
    try {
      await _player.stop();
    } catch (_) {/* best-effort */}
    _started = false;
  }
}
