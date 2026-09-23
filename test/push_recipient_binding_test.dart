import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:UniSpace/ui/settings/app_settings.dart';
import 'support/generated_push_recipient_callbacks.dart' as h;

// Executes extracted, unmodified production callback bodies. The native/Auth/
// navigation boundaries are controlled; this is not an end-to-end device test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SettingsData saved;
  setUp(() {
    saved = AppSettings.instance.notifier.value;
    AppSettings.instance.notifier.value = SettingsData.initial();
    h.resetHarness('recipient-a');
  });
  tearDown(() => AppSettings.instance.notifier.value = saved);
  Map<String, dynamic> data() => {
        'recipientId': 'recipient-a',
        'type': 'follow',
        'notificationId': 'notification-1',
        'actorId': 'actor-b',
        'actorName': 'Synthetic actor',
        'message': 'Synthetic follow',
      };
  RemoteMessage message(Map<String, dynamic> payload) => RemoteMessage(
        data: payload,
        notification:
            const RemoteNotification(title: 'Test', body: 'Test body'),
      );
  Future<void> invoke(String route, Map<String, dynamic> payload) async {
    switch (route) {
      case 'foreground':
        await h.invokeForeground(message(payload));
        break;
      case 'opened':
        h.invokeOpened(message(payload));
        break;
      case 'initial':
        h.deferredInitial(message(payload))();
        break;
      case 'local':
        h.invokeLocal(jsonEncode(payload));
        break;
    }
  }

  void expectNoEffects() {
    expect(h.displayed, isEmpty);
    expect(h.openedNotifications, isEmpty);
  }

  const routes = ['foreground', 'opened', 'initial', 'local'];
  for (final route in routes) {
    for (final absent in ['missing', 'null']) {
      test('RECIPIENT: $route rejects $absent recipient', () async {
        final payload = data();
        if (absent == 'missing') {
          payload.remove('recipientId');
        } else {
          payload['recipientId'] = null;
        }
        await invoke(route, payload);
        expectNoEffects();
      });
    }
    final invalid = <String, dynamic>{
      'empty': '',
      'foreign': 'recipient-b',
      'number': 7,
      'boolean': true,
      'array': ['recipient-a'],
      'map': {'uid': 'recipient-a'},
      'leading space': ' recipient-a',
      'trailing space': 'recipient-a ',
      'case changed': 'RECIPIENT-A',
    };
    for (final entry in invalid.entries) {
      test('$route rejects ${entry.key} recipient', () async {
        await invoke(route, {...data(), 'recipientId': entry.value});
        expectNoEffects();
      });
    }
    test('$route rejects signed-out user', () async {
      h.setHarnessUser(null);
      await invoke(route, data());
      expectNoEffects();
    });
    test('$route accepts exact current recipient without changing payload',
        () async {
      final payload = data();
      final original = Map<String, dynamic>.from(payload);
      await invoke(route, payload);
      expect(payload, equals(original));
      if (route == 'foreground') {
        expect(h.displayed, hasLength(1));
        expect(jsonDecode(h.displayed.single['payload'] as String),
            equals(payload));
        expect(h.displayed.single['title'], 'Test');
        expect(h.displayed.single['body'], 'Test body');
        expect(h.openedNotifications, isEmpty);
      } else {
        expect(h.displayed, isEmpty);
        expect(h.openedNotifications, hasLength(1));
        final item = h.openedNotifications.single;
        expect(item.id, 'notification-1');
        expect(item.actorId, 'actor-b');
        expect(item.type, 'follow');
      }
    });
  }
  test('initial callback rechecks the account when its frame executes', () {
    final callback = h.deferredInitial(message(data()));
    h.setHarnessUser('recipient-b');
    callback();
    expectNoEffects();
  });
  test('initial callback does not open after sign-out', () {
    final callback = h.deferredInitial(message(data()));
    h.setHarnessUser(null);
    callback();
    expectNoEffects();
  });
  test('displayed local payload cannot open under a different account',
      () async {
    await h.invokeForeground(message(data()));
    expect(h.displayed, hasLength(1));
    final payload = h.displayed.single['payload'] as String;
    h.setHarnessUser('recipient-b');
    h.invokeLocal(payload);
    expect(h.openedNotifications, isEmpty);
  });
  test('matching initial callback remains functional after scheduling', () {
    final callback = h.deferredInitial(message(data()));
    expect(h.openedNotifications, isEmpty);
    callback();
    expect(h.openedNotifications, hasLength(1));
  });
  test('missing recipient is not guessed from actor or alternate identity',
      () async {
    final payload = data()..remove('recipientId');
    payload.addAll({
      'actorId': 'recipient-a',
      'userId': 'recipient-a',
      'uid': 'recipient-a'
    });
    await invoke('foreground', payload);
    await invoke('opened', payload);
    expectNoEffects();
  });
  test('correct recipient still respects foreground category preference',
      () async {
    AppSettings.instance.notifier.value =
        SettingsData.initial().copyWith(communityUpdatesEnabled: false);
    await h.invokeForeground(message(data()));
    expectNoEffects();
  });
  test('correct recipient still respects global foreground preference',
      () async {
    AppSettings.instance.notifier.value =
        SettingsData.initial().copyWith(notificationsEnabled: false);
    await h.invokeForeground(message(data()));
    expectNoEffects();
  });
  for (final kind in ['announcement', 'exam_reminder']) {
    test('matching actorless $kind still displays', () async {
      await h
          .invokeForeground(message({...data(), 'type': kind, 'actorId': ''}));
      expect(h.displayed, hasLength(1));
    });
  }
  test('unsupported foreground type remains denied', () async {
    await h.invokeForeground(message({...data(), 'type': 'message'}));
    expectNoEffects();
  });
  test('data-only message does not create a local notification', () async {
    await h.invokeForeground(RemoteMessage(data: data()));
    expectNoEffects();
  });
  test('missing navigator context does not open matching notification', () {
    h.unispaceNavigatorKey.currentContext = null;
    h.invokeOpened(message(data()));
    expectNoEffects();
  });
  for (final value in ['not-json', '[]', 'null', '42']) {
    test('local payload $value is ignored', () {
      h.invokeLocal(value);
      expectNoEffects();
    });
  }
}
