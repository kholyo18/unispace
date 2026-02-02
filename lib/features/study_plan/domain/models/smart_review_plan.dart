enum SmartReviewTaskType {
  focusSession,
  practiceQuiz,
  summaryReview,
  mockTest,
}

class SmartReviewTask {
  const SmartReviewTask({
    required this.type,
    required this.title,
    required this.subjectName,
    required this.durationMinutes,
    this.notes,
  });

  final SmartReviewTaskType type;
  final String title;
  final String subjectName;
  final int durationMinutes;
  final String? notes;

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'title': title,
      'subjectName': subjectName,
      'durationMinutes': durationMinutes,
      'notes': notes,
    };
  }

  factory SmartReviewTask.fromJson(Map<String, dynamic> json) {
    return SmartReviewTask(
      type: SmartReviewTaskType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => SmartReviewTaskType.focusSession,
      ),
      title: json['title'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      notes: json['notes'] as String?,
    );
  }
}

class SmartReviewDay {
  const SmartReviewDay({
    required this.date,
    required this.tasks,
  });

  final DateTime date;
  final List<SmartReviewTask> tasks;

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'tasks': tasks.map((task) => task.toJson()).toList(),
    };
  }

  factory SmartReviewDay.fromJson(Map<String, dynamic> json) {
    return SmartReviewDay(
      date: DateTime.parse(json['date'] as String),
      tasks: (json['tasks'] as List<dynamic>? ?? [])
          .map((task) => SmartReviewTask.fromJson(task as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SmartReviewPlan {
  const SmartReviewPlan({
    required this.createdAt,
    required this.rangeStart,
    required this.rangeEnd,
    required this.days,
  });

  final DateTime createdAt;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final List<SmartReviewDay> days;

  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt.toIso8601String(),
      'rangeStart': rangeStart.toIso8601String(),
      'rangeEnd': rangeEnd.toIso8601String(),
      'days': days.map((day) => day.toJson()).toList(),
    };
  }

  factory SmartReviewPlan.fromJson(Map<String, dynamic> json) {
    return SmartReviewPlan(
      createdAt: DateTime.parse(json['createdAt'] as String),
      rangeStart: DateTime.parse(json['rangeStart'] as String),
      rangeEnd: DateTime.parse(json['rangeEnd'] as String),
      days: (json['days'] as List<dynamic>? ?? [])
          .map((day) => SmartReviewDay.fromJson(day as Map<String, dynamic>))
          .toList(),
    );
  }
}

enum SmartReviewDifficulty {
  easy,
  medium,
  hard,
}

class SmartReviewPreferences {
  const SmartReviewPreferences({
    this.dailyMinutes = 90,
    this.focusSessionsPerDay = 2,
    this.difficultyBySubject = const {},
  });

  final int dailyMinutes;
  final int focusSessionsPerDay;
  final Map<String, SmartReviewDifficulty> difficultyBySubject;
}

extension SmartReviewDifficultyWeight on SmartReviewDifficulty {
  double get weight {
    switch (this) {
      case SmartReviewDifficulty.easy:
        return 0.7;
      case SmartReviewDifficulty.medium:
        return 1.0;
      case SmartReviewDifficulty.hard:
        return 1.4;
    }
  }
}
