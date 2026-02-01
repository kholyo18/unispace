import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../generated/l10n.dart';
import '../../../../ui/settings/app_settings.dart';
import '../../data/models/exam_model.dart';
import '../../data/storage/exam_storage.dart';
import '../../notifications/exam_notifications_service.dart';
import '../widgets/exam_day_sheet.dart';
import 'exam_form_page.dart';

class ExamsCalendarPage extends StatefulWidget {
  const ExamsCalendarPage({super.key});

  @override
  State<ExamsCalendarPage> createState() => _ExamsCalendarPageState();
}

class _ExamsCalendarPageState extends State<ExamsCalendarPage> {
  final ExamStorage _storage = ExamStorage();
  final ExamNotificationsService _notifications =
      ExamNotificationsService.instance;

  List<ExamModel> _exams = [];
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    final exams = await _storage.loadExams();
    exams.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    if (!mounted) return;
    setState(() {
      _exams = exams;
      _loading = false;
    });
    await _notifications.initialize();
  }

  List<ExamModel> _examsForDay(DateTime day) {
    return _exams
        .where((exam) => DateUtils.isSameDay(exam.dateTime, day))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  bool _hasExamOnDay(DateTime day) {
    return _exams.any((exam) => DateUtils.isSameDay(exam.dateTime, day));
  }

  Future<void> _saveExams() async {
    await _storage.saveExams(_exams);
  }

  Future<void> _openForm({ExamModel? exam}) async {
    final result = await Navigator.of(context).push<ExamModel>(
      MaterialPageRoute(
        builder: (_) => ExamFormPage(exam: exam),
      ),
    );
    if (result == null) return;
    if (exam != null) {
      await _notifications.cancelExamReminders(exam);
      _exams = _exams.map((item) => item.id == exam.id ? result : item).toList();
    } else {
      _exams = [..._exams, result];
    }
    _exams.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    if (mounted) setState(() {});
    await _saveExams();
    await _scheduleNotifications(result);
  }

  Future<void> _scheduleNotifications(ExamModel exam) async {
    final settings = AppSettings.instance.notifier.value;
    if (!settings.notificationsEnabled || !settings.examRemindersEnabled) {
      return;
    }
    if (!exam.remindersEnabled || exam.reminderOffsets.isEmpty) return;
    final s = S.of(context);
    await _notifications.scheduleExamReminders(
      exam,
      bodyBuilder: (minutes) {
        if (minutes >= 1440) {
          return s.examReminder24h(exam.subject);
        }
        if (minutes >= 120) {
          return s.examReminder2h(exam.subject);
        }
        return s.examReminder30m(exam.subject);
      },
    );
  }

  Future<void> _confirmDelete(ExamModel exam) async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.deleteExam),
        content: Text(s.confirmDeleteExam),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.deleteExam),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _notifications.cancelExamReminders(exam);
    _exams = _exams.where((item) => item.id != exam.id).toList();
    if (mounted) setState(() {});
    await _saveExams();
  }

  void _showDaySheet(DateTime day) {
    setState(() => _selectedDate = day);
    final dayExams = _examsForDay(day);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return ExamDaySheet(
          day: day,
          exams: dayExams,
          onAdd: () {
            Navigator.of(context).pop();
            _openForm();
          },
          onEdit: (exam) {
            Navigator.of(context).pop();
            _openForm(exam: exam);
          },
          onDelete: (exam) async {
            Navigator.of(context).pop();
            await _confirmDelete(exam);
          },
        );
      },
    );
  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + offset,
        1,
      );
    });
  }

  List<String> _weekdayLabels(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final baseMonday = DateTime.utc(2024, 1, 1);
    return List.generate(
      7,
      (index) => DateFormat.E(locale).format(baseMonday.add(
        Duration(days: index),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final locale = Localizations.localeOf(context).toString();
    final monthLabel = DateFormat.yMMMM(locale).format(_focusedMonth);
    final daysInMonth =
        DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final leadingEmpty = firstDay.weekday - 1;
    final totalCells =
        ((leadingEmpty + daysInMonth + 6) ~/ 7) * 7;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.examCalendar),
        actions: [
          IconButton(
            tooltip: s.addExam,
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => _changeMonth(-1),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: Text(
                            monthLabel,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _changeMonth(1),
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: _weekdayLabels(context)
                          .map((label) => Expanded(
                                child: Center(
                                  child: Text(
                                    label,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: totalCells,
                      itemBuilder: (context, index) {
                        final dayNumber = index - leadingEmpty + 1;
                        if (dayNumber < 1 || dayNumber > daysInMonth) {
                          return const SizedBox.shrink();
                        }
                        final day = DateTime(
                          _focusedMonth.year,
                          _focusedMonth.month,
                          dayNumber,
                        );
                        final isSelected =
                            DateUtils.isSameDay(day, _selectedDate);
                        final isToday = DateUtils.isSameDay(day, DateTime.now());
                        final hasExam = _hasExamOnDay(day);
                        return InkWell(
                          onTap: () => _showDaySheet(day),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              border: isToday
                                  ? Border.all(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    )
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  dayNumber.toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimary
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (hasExam)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onPrimary
                                          : Theme.of(context)
                                              .colorScheme
                                              .primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
