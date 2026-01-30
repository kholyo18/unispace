import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/models/exam_model.dart';

class ExamNotificationsService {
  ExamNotificationsService._();

  static final ExamNotificationsService instance =
      ExamNotificationsService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _permissionsGranted = true;

  Future<void> initialize() async {
    if (_initialized) return;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(initializationSettings);
    await _requestPermissions();
    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (granted != null) {
        _permissionsGranted = granted;
      }
    }

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      if (granted != null) {
        _permissionsGranted = granted;
      }
    }
  }

  Future<void> scheduleExamReminders(
    ExamModel exam, {
    required String Function(int minutes) bodyBuilder,
  }) async {
    await initialize();
    if (!_permissionsGranted) return;

    const androidDetails = AndroidNotificationDetails(
      'exam_reminders',
      'Exam Reminders',
      channelDescription: 'Notifications for upcoming exams',
      importance: Importance.max,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    for (final offset in exam.reminderOffsets) {
      final scheduledDate = exam.dateTime.subtract(
        Duration(minutes: offset),
      );
      if (scheduledDate.isBefore(DateTime.now())) {
        continue;
      }
      final id = _notificationId(exam.id, offset);
      await _plugin.schedule(
        id,
        exam.subject,
        bodyBuilder(offset),
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelExamReminders(ExamModel exam) async {
    await initialize();
    for (final offset in exam.reminderOffsets) {
      await _plugin.cancel(_notificationId(exam.id, offset));
    }
  }

  int _notificationId(String examId, int offset) {
    return (examId.hashCode ^ offset) & 0x7fffffff;
  }
}
