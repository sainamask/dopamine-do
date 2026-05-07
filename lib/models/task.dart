import 'dart:convert';

class Task {
  Task({
    required this.id,
    required this.title,
    required this.scheduledAt,
    required this.nudgeLeadTime,
    required this.duration,
    this.completed = false,
    this.completedAt,
  });

  final String id;
  final String title;
  final DateTime scheduledAt;
  final Duration nudgeLeadTime;
  final Duration duration;
  final bool completed;
  final DateTime? completedAt;

  Task copyWith({
    bool? completed,
    DateTime? completedAt,
    String? title,
    DateTime? scheduledAt,
    Duration? nudgeLeadTime,
    Duration? duration,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      nudgeLeadTime: nudgeLeadTime ?? this.nudgeLeadTime,
      duration: duration ?? this.duration,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'scheduledAt': scheduledAt.toIso8601String(),
        'nudgeLeadMinutes': nudgeLeadTime.inMinutes,
        'durationSeconds': duration.inSeconds,
        'completed': completed,
        'completedAt': completedAt?.toIso8601String(),
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
    );
  }

  String encode() => jsonEncode(toJson());

  factory Task.decode(String raw) =>
      Task.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
