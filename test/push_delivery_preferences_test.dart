import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/ui/settings/app_settings.dart';
import 'package:UniSpace/ui/settings/push_preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SettingsData saved;
  setUp(() {
    saved = AppSettings.instance.notifier.value;
    AppSettings.instance.notifier.value = SettingsData.initial();
  });
  tearDown(() => AppSettings.instance.notifier.value = saved);
  final service = PushPreferencesService.instance;
  const community = [
    'new_post',
    'like',
    'like_comment',
    'reply',
    'comment',
    'repost',
    'follow',
    'follow_request',
    'follow_accepted'
  ];
  for (final type in [...community, 'announcement', 'exam_reminder']) {
    test('recognized $type remains allowed with default preferences', () {
      expect(service.allows(type), isTrue);
      AppSettings.instance.notifier.value =
          SettingsData.initial().copyWith(notificationsEnabled: false);
      expect(service.allows(type), isFalse);
    });
  }
  for (final type in [
    '',
    'chat',
    'message',
    'chat_message',
    'dm_message',
    'unknown',
    'FOLLOW',
    ' follow',
    'follow ',
    '__proto__',
    'constructor',
    'toString'
  ]) {
    test('TYPEGATE: foreground preferences reject unsupported "$type"', () {
      expect(service.allows(type), isFalse);
    });
  }
  test('community switch does not change announcement or exam preferences', () {
    AppSettings.instance.notifier.value =
        SettingsData.initial().copyWith(communityUpdatesEnabled: false);
    for (final type in community) {
      expect(service.allows(type), isFalse);
    }
    expect(service.allows('announcement'), isTrue);
    expect(service.allows('exam_reminder'), isTrue);
  });
  test('announcement and exam switches remain independent', () {
    AppSettings.instance.notifier.value =
        SettingsData.initial().copyWith(announcementsEnabled: false);
    expect(service.allows('announcement'), isFalse);
    expect(service.allows('exam_reminder'), isTrue);
    expect(service.allows('follow'), isTrue);
    AppSettings.instance.notifier.value =
        SettingsData.initial().copyWith(examRemindersEnabled: false);
    expect(service.allows('announcement'), isTrue);
    expect(service.allows('exam_reminder'), isFalse);
  });
}
