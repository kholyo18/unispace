import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../ui/settings/app_settings.dart';
import '../data/models/exam_model.dart';
import '../data/storage/exam_storage.dart';

class ExamNotificationsService {
  ExamNotificationsService(
      {FlutterLocalNotificationsPlugin? plugin,
      Future<List<ExamModel>> Function()? loadExams})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _loadExams = loadExams ?? ExamStorage().loadExams;
  static final instance = ExamNotificationsService();
  final FlutterLocalNotificationsPlugin _plugin;
  final Future<List<ExamModel>> Function() _loadExams;
  DidReceiveNotificationResponseCallback? onNotificationResponse;
  final error = ValueNotifier<String?>(null);
  Future<void>? _initializing;
  Future<void> _pending = Future<void>.value();
  bool _watching = false;
  bool get _enabled =>
      AppSettings.instance.notifier.value.notificationsEnabled &&
      AppSettings.instance.notifier.value.examRemindersEnabled;
  bool? _lastEnabled;

  Future<void> initialize() =>
      _initializing ??= _initialize().catchError((Object e) {
        _initializing = null;
        throw e;
      });
  Future<void> _initialize() async {
    await _plugin.initialize(
        const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
            iOS: DarwinInitializationSettings(
                requestAlertPermission: false,
                requestBadgePermission: false,
                requestSoundPermission: false)),
        onDidReceiveNotificationResponse: onNotificationResponse);
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isIOS)
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    if (Platform.isAndroid)
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          false;
    return true;
  }

  Future<void> _serial(Future<void> Function() operation) {
    final next = _pending.then((_) => operation());
    _pending = next.catchError((Object _) {});
    return next;
  }

  /// Observe device preferences even when the exam calendar is not open.
  void watchSettings() {
    if (_watching) return;
    _watching = true;
    AppSettings.instance.notifier.addListener(_settingsChanged);
    _settingsChanged();
  }

  void stopWatchingSettings() {
    if (!_watching) return;
    AppSettings.instance.notifier.removeListener(_settingsChanged);
    _watching = false;
    _lastEnabled = null;
  }

  void _settingsChanged() {
    if (_lastEnabled == _enabled) return;
    _lastEnabled = _enabled;
    unawaited(refreshSavedReminders().catchError((Object _) {}));
  }

  Future<void> refreshSavedReminders() => _serial(() async {
        try {
          final exams = await _loadExams();
          if (exams.isEmpty) {
            error.value = null;
            return;
          }
          await initialize();
          for (final exam in exams) {
            await _cancel(exam);
            if (_enabled && exam.remindersEnabled) {
              await _schedule(exam,
                  requestPermission: false,
                  bodyBuilder: (offset) => _reminderBody(exam.subject, offset));
            }
          }
          error.value = null;
        } catch (_) {
          error.value = 'تعذر تحديث تذكيرات الامتحانات. أعد المحاولة.';
          rethrow;
        }
      });
  String _reminderBody(String subject, int minutes) {
    final language = (Intl.defaultLocale ?? 'ar').split(RegExp('[-_]')).first;
    if (language == 'fr')
      return 'Rappel : $subject dans ${minutes >= 1440 ? '24 heures' : minutes >= 120 ? '2 heures' : '30 minutes'}';
    if (language == 'en')
      return 'Reminder: $subject in ${minutes >= 1440 ? '24 hours' : minutes >= 120 ? '2 hours' : '30 minutes'}';
    return 'تذكير: $subject بعد ${minutes >= 1440 ? '24 ساعة' : minutes >= 120 ? 'ساعتين' : '30 دقيقة'}';
  }

  Future<void> scheduleExamReminders(
    ExamModel exam, {
    required String Function(int minutes) bodyBuilder,
    String channelName = 'Exam reminders',
    String channelDescription = 'Notifications for upcoming exams',
  }) =>
      _serial(() => _schedule(exam,
          bodyBuilder: bodyBuilder,
          channelName: channelName,
          channelDescription: channelDescription));

  Future<void> _schedule(
    ExamModel exam, {
    bool requestPermission = true,
    required String Function(int minutes) bodyBuilder,
    String channelName = 'Exam reminders',
    String channelDescription = 'Notifications for upcoming exams',
  }) async {
    if (!_enabled || !exam.remindersEnabled) return;
    await initialize();
    if (requestPermission && !await _requestPermissions()) return;
    final details = NotificationDetails(
        android: AndroidNotificationDetails('exams_channel', channelName,
            channelDescription: channelDescription,
            importance: Importance.max,
            priority: Priority.high),
        iOS: const DarwinNotificationDetails());
    for (final offset in exam.reminderOffsets) {
      if (!_enabled) return;
      final scheduled = exam.dateTime.subtract(Duration(minutes: offset));
      if (!scheduled.isAfter(DateTime.now())) continue;
      await _plugin.zonedSchedule(
          _notificationId(exam.id, offset),
          exam.subject,
          bodyBuilder(offset),
          tz.TZDateTime.from(scheduled, tz.local),
          details,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  Future<void> cancelExamReminders(ExamModel exam) => _serial(() async {
        await initialize();
        await _cancel(exam);
      });
  Future<void> _cancel(ExamModel exam) async {
    for (final offset in exam.reminderOffsets) {
      await _plugin.cancel(_notificationId(exam.id, offset));
    }
  }

  int _notificationId(String examId, int offset) =>
      (examId.hashCode ^ offset) & 0x7fffffff;
}
