import '../../exams/data/models/exam_model.dart';
import '../domain/models/smart_review_plan.dart';

class SmartReviewPlanGenerator {
  SmartReviewPlan? generatePlan({
    required List<ExamModel> exams,
    SmartReviewPreferences preferences = const SmartReviewPreferences(),
    DateTime? now,
  }) {
    final startDate = _dateOnly(now ?? DateTime.now());
    final upcoming = filterUpcomingExams(exams, startDate);
    if (upcoming.isEmpty) {
      return null;
    }

    upcoming.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final nearestExamDate = _dateOnly(upcoming.first.dateTime);
    final maxEnd = startDate.add(const Duration(days: 6));
    final endDate = nearestExamDate.isBefore(maxEnd) ? nearestExamDate : maxEnd;
    final dayCount = endDate.difference(startDate).inDays + 1;

    final subjectWeights = _buildSubjectWeights(
      upcoming,
      preferences,
      startDate,
    );
    final weightedSubjects = subjectWeights.keys.toList()
      ..sort((a, b) => subjectWeights[b]!.compareTo(subjectWeights[a]!));

    final days = <SmartReviewDay>[];
    for (var index = 0; index < dayCount; index++) {
      final date = startDate.add(Duration(days: index));
      final dailyMinutes = preferences.dailyMinutes;
      final focusSessions = preferences.focusSessionsPerDay.clamp(1, 3);

      final nextExam = _nextExamForDate(upcoming, date);
      final daysUntilExam =
          _dateOnly(nextExam.dateTime).difference(date).inDays;

      var smallTaskDuration = _clampInt(
        (dailyMinutes * 0.2).round(),
        min: 10,
        max: 20,
      );

      var smallTaskType =
          index.isEven ? SmartReviewTaskType.practiceQuiz : SmartReviewTaskType.summaryReview;

      if (daysUntilExam == 1 && dailyMinutes >= 60) {
        smallTaskType = SmartReviewTaskType.mockTest;
        smallTaskDuration = _clampInt(
          (dailyMinutes * 0.3).round(),
          min: 20,
          max: 45,
        );
      }

      var focusDuration =
          ((dailyMinutes - smallTaskDuration) / focusSessions).floor();
      focusDuration = _clampInt(focusDuration, min: 25, max: 45);

      var totalMinutes = focusDuration * focusSessions + smallTaskDuration;
      if (totalMinutes > dailyMinutes) {
        final available = dailyMinutes - smallTaskDuration;
        focusDuration = (available / focusSessions).floor();
        focusDuration = _clampInt(focusDuration, min: 25, max: 45);
        totalMinutes = focusDuration * focusSessions + smallTaskDuration;
      }

      if (totalMinutes > dailyMinutes && focusDuration == 25) {
        smallTaskDuration = _clampInt(
          dailyMinutes - focusDuration * focusSessions,
          min: 10,
          max: 20,
        );
      }

      final tasks = <SmartReviewTask>[];
      for (var sessionIndex = 0; sessionIndex < focusSessions; sessionIndex++) {
        final subject = weightedSubjects.isEmpty
            ? nextExam.subject
            : weightedSubjects[(index + sessionIndex) % weightedSubjects.length];
        tasks.add(
          SmartReviewTask(
            type: SmartReviewTaskType.focusSession,
            title: subject,
            subjectName: subject,
            durationMinutes: focusDuration,
          ),
        );
      }

      tasks.add(
        SmartReviewTask(
          type: smallTaskType,
          title: nextExam.subject,
          subjectName: nextExam.subject,
          durationMinutes: smallTaskDuration,
        ),
      );

      days.add(SmartReviewDay(date: date, tasks: tasks));
    }

    return SmartReviewPlan(
      createdAt: DateTime.now(),
      rangeStart: startDate,
      rangeEnd: endDate,
      days: days,
    );
  }

  List<ExamModel> filterUpcomingExams(List<ExamModel> exams, DateTime today) {
    return exams
        .where((exam) => !_dateOnly(exam.dateTime).isBefore(today))
        .toList();
  }

  ExamModel _nextExamForDate(List<ExamModel> exams, DateTime date) {
    for (final exam in exams) {
      if (!_dateOnly(exam.dateTime).isBefore(date)) {
        return exam;
      }
    }
    return exams.first;
  }

  Map<String, double> _buildSubjectWeights(
    List<ExamModel> exams,
    SmartReviewPreferences preferences,
    DateTime startDate,
  ) {
    final weights = <String, double>{};
    for (final exam in exams) {
      final daysUntilExam =
          _dateOnly(exam.dateTime).difference(startDate).inDays;
      final proximityWeight = 1 / (daysUntilExam + 1);
      final difficulty =
          preferences.difficultyBySubject[exam.subject.toLowerCase()] ??
              SmartReviewDifficulty.medium;
      final weight = proximityWeight * difficulty.weight;
      weights.update(
        exam.subject,
        (value) => value + weight,
        ifAbsent: () => weight,
      );
    }
    return weights;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  int _clampInt(int value, {required int min, required int max}) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}
