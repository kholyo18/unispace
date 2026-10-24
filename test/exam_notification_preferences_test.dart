import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:UniSpace/features/exams/notifications/exam_notifications_service.dart';
import 'package:UniSpace/features/exams/data/models/exam_model.dart';
import 'package:UniSpace/ui/settings/app_settings.dart';

class FakeNotifications implements FlutterLocalNotificationsPlugin {
  final scheduled = <int, String?>{};
  final cancelled = <int>[];
  int initializations = 0;
  DidReceiveNotificationResponseCallback? response;
  @override
  Future<bool?> initialize(InitializationSettings settings, {
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback? onDidReceiveBackgroundNotificationResponse,
  }) async { initializations++; response = onDidReceiveNotificationResponse; return true; }
  @override
  Future<void> cancel(int id, {String? tag}) async { cancelled.add(id); scheduled.remove(id); }
  @override
  Future<void> zonedSchedule(int id, String? title, String? body, tz.TZDateTime time, NotificationDetails details, {
    required UILocalNotificationDateInterpretation uiLocalNotificationDateInterpretation,
    required AndroidScheduleMode androidScheduleMode, String? payload, DateTimeComponents? matchDateTimeComponents,
  }) async { scheduled[id] = title; }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  late FakeNotifications plugin;
  late ExamNotificationsService service;
  late SettingsData saved;
  final exam = ExamModel(id: 'future', subject: 'Math', dateTime: DateTime.now().add(const Duration(days: 3)), remindersEnabled: true);
  setUp(() {
    saved = AppSettings.instance.notifier.value;
    AppSettings.instance.notifier.value = SettingsData.initial();
    plugin = FakeNotifications();
    service = ExamNotificationsService(plugin: plugin, loadExams: () async => [exam,
      exam.copyWith(id: 'disabled', remindersEnabled: false),
      exam.copyWith(id: 'past', dateTime: DateTime.now().subtract(const Duration(days: 1)))]);
  });
  tearDown(() { service.stopWatchingSettings(); AppSettings.instance.notifier.value = saved; });
  test('only future enabled reminders scheduled; disabling cancels and re-enabling restores', () async {
    await service.refreshSavedReminders();
    expect(plugin.scheduled, hasLength(3));
    AppSettings.instance.notifier.value = SettingsData.initial().copyWith(examRemindersEnabled: false);
    await service.refreshSavedReminders();
    expect(plugin.scheduled, isEmpty);
    AppSettings.instance.notifier.value = SettingsData.initial();
    await service.refreshSavedReminders();
    expect(plugin.scheduled, hasLength(3));
    AppSettings.instance.notifier.value = SettingsData.initial().copyWith(notificationsEnabled: false);
    await service.refreshSavedReminders();
    expect(plugin.scheduled, isEmpty);
  });
  test('watcher applies changes without opening calendar and retains response callback', () async {
    void response(NotificationResponse _) {}
    service.onNotificationResponse = response;
    service.watchSettings();
    await service.refreshSavedReminders();
    expect(plugin.scheduled, hasLength(3));
    AppSettings.instance.notifier.value = SettingsData.initial().copyWith(examRemindersEnabled: false);
    await Future<void>.delayed(Duration.zero);
    expect(plugin.scheduled, isEmpty);
    await service.initialize();
    expect(plugin.initializations, 1);
    expect(plugin.response, same(response));
  });
  test('storage failure is visible and retry recovers without canceling unrelated alerts', () async {
    bool fail = true;
    service = ExamNotificationsService(plugin: plugin, loadExams: () async {
      if (fail) throw StateError('storage'); return [exam];
    });
    plugin.scheduled[-1] = 'chat';
    await expectLater(service.refreshSavedReminders(), throwsStateError);
    expect(service.error.value, isNotNull);
    expect(plugin.scheduled[-1], 'chat');
    fail = false;
    await service.refreshSavedReminders();
    expect(service.error.value, isNull);
    expect(plugin.scheduled[-1], 'chat');
    expect(plugin.scheduled, hasLength(4));
  });
}
