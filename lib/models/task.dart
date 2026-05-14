import 'dart:convert';

enum TaskRecurrence { none, daily, weekdays, weekly }

TaskRecurrence _recurrenceFromName(String? name) {
  switch (name) {
    case 'daily':
      return TaskRecurrence.daily;
    case 'weekdays':
      return TaskRecurrence.weekdays;
    case 'weekly':
      return TaskRecurrence.weekly;
    default:
      return TaskRecurrence.none;
  }
}

String _recurrenceToName(TaskRecurrence r) {
  switch (r) {
    case TaskRecurrence.daily:
      return 'daily';
    case TaskRecurrence.weekdays:
      return 'weekdays';
    case TaskRecurrence.weekly:
      return 'weekly';
    case TaskRecurrence.none:
      return 'none';
  }
}

class Task {
  Task({
    required this.id,
    required this.title,
    required this.scheduledAt,
    required this.nudgeLeadTime,
    required this.duration,
    this.completed = false,
    this.completedAt,
    this.recurrence = TaskRecurrence.none,
    this.rescheduleCount = 0,
    this.actualDuration,
    this.parentId,
  });

  final String id;
  final String title;
  final DateTime scheduledAt;
  final Duration nudgeLeadTime;
  final Duration duration;
  final bool completed;
  final DateTime? completedAt;
  final TaskRecurrence recurrence;
  final int rescheduleCount;

  /// How long the user actually spent on the task before completion.
  /// Filled in on completion; null until then.
  final Duration? actualDuration;

  /// If this is a recurring instance, the id of the original/template task.
  /// Lets us group recurring instances in stats.
  final String? parentId;

  Task copyWith({
    bool? completed,
    DateTime? completedAt,
    String? title,
    DateTime? scheduledAt,
    Duration? nudgeLeadTime,
    Duration? duration,
    TaskRecurrence? recurrence,
    int? rescheduleCount,
    Duration? actualDuration,
    String? parentId,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      nudgeLeadTime: nudgeLeadTime ?? this.nudgeLeadTime,
      duration: duration ?? this.duration,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      recurrence: recurrence ?? this.recurrence,
      rescheduleCount: rescheduleCount ?? this.rescheduleCount,
      actualDuration: actualDuration ?? this.actualDuration,
      parentId: parentId ?? this.parentId,
    );
  }

  /// True if the user has rescheduled this task >= 3 times.
  bool get isProcrastinated => rescheduleCount >= 3;

  /// Compute the next scheduled date for the next instance of a recurring
  /// task, based on this one's scheduledAt. Returns null if not recurring.
  DateTime? nextOccurrenceFrom(DateTime base) {
    switch (recurrence) {
      case TaskRecurrence.none:
        return null;
      case TaskRecurrence.daily:
        return DateTime(
          base.year,
          base.month,
          base.day + 1,
          scheduledAt.hour,
          scheduledAt.minute,
        );
      case TaskRecurrence.weekdays:
        DateTime next = DateTime(
          base.year,
          base.month,
          base.day + 1,
          scheduledAt.hour,
          scheduledAt.minute,
        );
        while (next.weekday == DateTime.saturday ||
            next.weekday == DateTime.sunday) {
          next = next.add(const Duration(days: 1));
        }
        return next;
      case TaskRecurrence.weekly:
        return DateTime(
          base.year,
          base.month,
          base.day + 7,
          scheduledAt.hour,
          scheduledAt.minute,
        );
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'scheduledAt': scheduledAt.toIso8601String(),
        'nudgeLeadMinutes': nudgeLeadTime.inMinutes,
        'durationSeconds': duration.inSeconds,
        'completed': completed,
        'completedAt': completedAt?.toIso8601String(),
        'recurrence': _recurrenceToName(recurrence),
        'rescheduleCount': rescheduleCount,
        'actualSeconds': actualDuration?.inSeconds,
        'parentId': parentId,
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      nudgeLeadTime: Duration(minutes: json['nudgeLeadMinutes'] as int),
      duration: Duration(seconds: json['durationSeconds'] as int),
      completed: json['completed'] as bool? ?? false,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      recurrence: _recurrenceFromName(json['recurrence'] as String?),
      rescheduleCount: (json['rescheduleCount'] as int?) ?? 0,
      actualDuration: json['actualSeconds'] == null
          ? null
          : Duration(seconds: json['actualSeconds'] as int),
      parentId: json['parentId'] as String?,
    );
  }

  String encode() => jsonEncode(toJson());

  factory Task.decode(String raw) =>
      Task.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
