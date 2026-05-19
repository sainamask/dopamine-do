import 'dart:async';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/task.dart';

/// System-notification gateway for task reminders. Configured as an
/// "alarm" channel so the notification fires loudly, vibrates, lights the
/// LED, and (on supported Android versions) brings up a full-screen
/// intent over the lock screen.
///
/// Notification IDs are derived from `task.id` (string-hashed to int) so
/// scheduling the same task again replaces the previous schedule cleanly.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const String _channelId = 'dopamine_do_alarms';
  static const String _channelName = 'Task Alarms';
  static const String _channelDesc =
      'Loud, alarm-style nudges when a scheduled task is due.';

  /// Payload prefix so the response handler can recognise our intents.
  static const String _taskPayloadPrefix = 'task:';

  /// Action button IDs on the notification.
  static const String actionStart = 'start';
  static const String actionSnooze = 'snooze';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialised = false;

  /// Listeners get a tap event per notification interaction. `action` is
  /// `null` for a body tap, `actionStart`, or `actionSnooze`.
  final StreamController<NotifTapEvent> _onTap =
      StreamController<NotifTapEvent>.broadcast();
  Stream<NotifTapEvent> get onTap => _onTap.stream;

  Future<void> init() async {
    if (_initialised) return;
    tz_data.initializeTimeZones();
    try {
      final String tzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      // Best-effort: fall back to whatever the package defaulted to.
    }

    // Monochrome bell silhouette; Android tints it white in the status bar.
    // Using the launcher icon directly produces a coloured square that
    // Android either greys out or rejects on API 21+.
    const AndroidInitializationSettings android =
        AndroidInitializationSettings('ic_notification');
    const DarwinInitializationSettings ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const InitializationSettings settings =
        InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundResponseEntrypoint,
    );

    // Pre-create the channel so settings (sound/vibration/importance) are
    // applied even before the first scheduled fire.
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
        ),
      );
    }

    _initialised = true;
  }

  /// Request POST_NOTIFICATIONS (Android 13+) and exact-alarm permission.
  /// Safe to call repeatedly; no-ops if already granted.
  Future<void> requestPermissionsIfNeeded() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }
    final IOSFlutterLocalNotificationsPlugin? iosPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  int _idFor(String taskId) {
    // Map an arbitrary string id into the int range Android demands.
    // hashCode can be negative; mask down to a stable positive 31-bit int.
    return taskId.hashCode & 0x7fffffff;
  }

  Future<void> scheduleForTask(Task task) async {
    if (!_initialised) await init();
    final DateTime when = task.scheduledAt;
    if (when.isBefore(DateTime.now())) {
      // Past-dated tasks: skip rather than firing immediately.
      return;
    }

    final tz.TZDateTime tzWhen = tz.TZDateTime.from(when, tz.local);

    final NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        icon: 'ic_notification',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ongoing: false,
        autoCancel: true,
        ticker: 'Task incoming',
        // Brutalist alarm-orange accent on the notification chrome.
        color: const Color(0xFFE16522),
        colorized: true,
        subText: 'TASK INCOMING',
        // Full title visible even if it wraps multiple lines.
        styleInformation: BigTextStyleInformation(
          task.title,
          contentTitle: 'TASK INCOMING',
          summaryText: 'Tap to take over · Or use the buttons below',
        ),
        actions: const <AndroidNotificationAction>[
          AndroidNotificationAction(
            actionStart,
            "I'M ON IT",
            showsUserInterface: true,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            actionSnooze,
            'SNOOZE 3M',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
        categoryIdentifier: 'taskIncoming',
      ),
    );

    try {
      await _plugin.zonedSchedule(
        _idFor(task.id),
        'TASK INCOMING',
        task.title,
        tzWhen,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: '$_taskPayloadPrefix${task.id}',
      );
    } catch (e) {
      // Common case: SCHEDULE_EXACT_ALARM not granted. Fall back to an
      // inexact schedule so the user still gets *something*.
      if (kDebugMode) {
        debugPrint('Exact schedule failed, falling back to inexact: $e');
      }
      try {
        await _plugin.zonedSchedule(
          _idFor(task.id),
          'TASK INCOMING',
          task.title,
          tzWhen,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: '$_taskPayloadPrefix${task.id}',
        );
      } catch (e2) {
        if (kDebugMode) debugPrint('Inexact schedule also failed: $e2');
      }
    }
  }

  Future<void> cancelForTask(String taskId) async {
    if (!_initialised) return;
    await _plugin.cancel(_idFor(taskId));
  }

  Future<void> cancelAll() async {
    if (!_initialised) return;
    await _plugin.cancelAll();
  }

  void _onResponse(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload == null || !payload.startsWith(_taskPayloadPrefix)) return;
    final String taskId = payload.substring(_taskPayloadPrefix.length);
    _onTap.add(NotifTapEvent(taskId: taskId, action: response.actionId));
  }
}

/// One notification interaction. `action` is `null` for a tap on the body,
/// or one of [NotificationService.actionStart] / [NotificationService.actionSnooze]
/// for a tap on an action button.
class NotifTapEvent {
  const NotifTapEvent({required this.taskId, required this.action});
  final String taskId;
  final String? action;
}

/// Background isolate entrypoint for notification responses. Must be a
/// top-level / static function for the plugin to find it. We don't have
/// access to the running app from here so we just no-op; the app handles
/// the tap on cold-start via `getNotificationAppLaunchDetails()`.
@pragma('vm:entry-point')
void _onBackgroundResponseEntrypoint(NotificationResponse response) {
  // Intentionally empty — see comment above.
}
