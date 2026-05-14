import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kCalmKey = 'dopamine_do.settings.calm_mode';
const String _kHypeLinesKey = 'dopamine_do.settings.hype_lines';
const String _kHideNotifContentKey = 'dopamine_do.settings.hide_notif_content';
const String _kMorningSummaryKey = 'dopamine_do.settings.morning_summary';
const String _kMorningSummaryTimeKey =
    'dopamine_do.settings.morning_summary_minute';
const String _kHypeSoundPathKey = 'dopamine_do.settings.hype_sound_path';
const String _kHypeSoundNameKey = 'dopamine_do.settings.hype_sound_name';
const String _kQuickVoiceKey = 'dopamine_do.settings.quick_voice';

/// User settings. Kept dead simple: a flat key/value bag persisted in
/// SharedPreferences so we can read/write it sync after first load.
class AppSettings {
  const AppSettings({
    this.calmMode = false,
    this.customHypeLines = const <String>[],
    this.hideNotificationContent = false,
    this.morningSummaryEnabled = false,
    this.morningSummaryMinuteOfDay = 8 * 60,
    this.hypeSoundPath,
    this.hypeSoundName,
    this.quickCountdownVoiceEnabled = true,
  });

  /// Tones down animations + intensity for users who like the concept but
  /// not the full-volume visuals.
  final bool calmMode;

  /// Replaces the default 'TASK KILLED' success line with one of these,
  /// chosen at random. Empty → use defaults.
  final List<String> customHypeLines;

  /// Hide task name in system notifications (privacy).
  final bool hideNotificationContent;

  /// Send a "here's your day" notification each morning.
  final bool morningSummaryEnabled;

  /// Minute-of-day for the morning summary (0..1439).
  final int morningSummaryMinuteOfDay;

  /// Local file path of a user-picked audio file to play on task completion.
  /// Null = no custom sound (default haptic-only).
  final String? hypeSoundPath;

  /// User-facing display name for the custom sound (filename without path).
  final String? hypeSoundName;

  /// Speak the final-99-seconds countdown aloud during Quick Nudge.
  /// When false, every tick is just a system click — no voice.
  final bool quickCountdownVoiceEnabled;

  AppSettings copyWith({
    bool? calmMode,
    List<String>? customHypeLines,
    bool? hideNotificationContent,
    bool? morningSummaryEnabled,
    int? morningSummaryMinuteOfDay,
    String? hypeSoundPath,
    String? hypeSoundName,
    bool? quickCountdownVoiceEnabled,
    bool clearHypeSound = false,
  }) {
    return AppSettings(
      calmMode: calmMode ?? this.calmMode,
      customHypeLines: customHypeLines ?? this.customHypeLines,
      hideNotificationContent:
          hideNotificationContent ?? this.hideNotificationContent,
      morningSummaryEnabled:
          morningSummaryEnabled ?? this.morningSummaryEnabled,
      morningSummaryMinuteOfDay:
          morningSummaryMinuteOfDay ?? this.morningSummaryMinuteOfDay,
      hypeSoundPath: clearHypeSound
          ? null
          : (hypeSoundPath ?? this.hypeSoundPath),
      hypeSoundName: clearHypeSound
          ? null
          : (hypeSoundName ?? this.hypeSoundName),
      quickCountdownVoiceEnabled:
          quickCountdownVoiceEnabled ?? this.quickCountdownVoiceEnabled,
    );
  }
}

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return AppSettings(
      calmMode: prefs.getBool(_kCalmKey) ?? false,
      customHypeLines: prefs.getStringList(_kHypeLinesKey) ?? const <String>[],
      hideNotificationContent: prefs.getBool(_kHideNotifContentKey) ?? false,
      morningSummaryEnabled: prefs.getBool(_kMorningSummaryKey) ?? false,
      morningSummaryMinuteOfDay:
          prefs.getInt(_kMorningSummaryTimeKey) ?? 8 * 60,
      hypeSoundPath: prefs.getString(_kHypeSoundPathKey),
      hypeSoundName: prefs.getString(_kHypeSoundNameKey),
      quickCountdownVoiceEnabled: prefs.getBool(_kQuickVoiceKey) ?? true,
    );
  }

  Future<void> setHypeSound({required String path, required String name}) async {
    final AppSettings current = state.value ?? const AppSettings();
    final AppSettings next =
        current.copyWith(hypeSoundPath: path, hypeSoundName: name);
    state = AsyncData<AppSettings>(next);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kHypeSoundPathKey, path);
    await prefs.setString(_kHypeSoundNameKey, name);
  }

  Future<void> clearHypeSound() async {
    final AppSettings current = state.value ?? const AppSettings();
    state = AsyncData<AppSettings>(current.copyWith(clearHypeSound: true));
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHypeSoundPathKey);
    await prefs.remove(_kHypeSoundNameKey);
  }

  Future<void> setQuickCountdownVoice(bool value) async {
    final AppSettings current = state.value ?? const AppSettings();
    final AppSettings next =
        current.copyWith(quickCountdownVoiceEnabled: value);
    state = AsyncData<AppSettings>(next);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kQuickVoiceKey, value);
  }

  Future<void> setCalmMode(bool value) async {
    final AppSettings current = state.value ?? const AppSettings();
    final AppSettings next = current.copyWith(calmMode: value);
    state = AsyncData<AppSettings>(next);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCalmKey, value);
  }

  Future<void> setHideNotificationContent(bool value) async {
    final AppSettings current = state.value ?? const AppSettings();
    final AppSettings next = current.copyWith(hideNotificationContent: value);
    state = AsyncData<AppSettings>(next);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHideNotifContentKey, value);
  }

  Future<void> setMorningSummary({required bool enabled, int? minuteOfDay}) async {
    final AppSettings current = state.value ?? const AppSettings();
    final AppSettings next = current.copyWith(
      morningSummaryEnabled: enabled,
      morningSummaryMinuteOfDay: minuteOfDay,
    );
    state = AsyncData<AppSettings>(next);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kMorningSummaryKey, enabled);
    if (minuteOfDay != null) {
      await prefs.setInt(_kMorningSummaryTimeKey, minuteOfDay);
    }
  }

  Future<void> addHypeLine(String line) async {
    final String trimmed = line.trim();
    if (trimmed.isEmpty) return;
    final AppSettings current = state.value ?? const AppSettings();
    if (current.customHypeLines.contains(trimmed)) return;
    final List<String> next = <String>[...current.customHypeLines, trimmed];
    state = AsyncData<AppSettings>(current.copyWith(customHypeLines: next));
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kHypeLinesKey, next);
  }

  Future<void> removeHypeLine(String line) async {
    final AppSettings current = state.value ?? const AppSettings();
    final List<String> next = current.customHypeLines
        .where((String s) => s != line)
        .toList(growable: false);
    state = AsyncData<AppSettings>(current.copyWith(customHypeLines: next));
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kHypeLinesKey, next);
  }
}

final AsyncNotifierProvider<SettingsNotifier, AppSettings> settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

/// Convenience: sync read of calmMode, defaults to false until loaded.
final Provider<bool> calmModeProvider = Provider<bool>((Ref ref) {
  return ref.watch(settingsProvider).value?.calmMode ?? false;
});

/// Default lines used when the user hasn't added any custom ones.
const List<String> kDefaultHypeLines = <String>[
  'TASK KILLED',
  'CRUSHED IT',
  'TOTAL DOMINATION',
  'CLEAN HIT',
  'NO SURVIVORS',
  'CHEF KISS',
];
