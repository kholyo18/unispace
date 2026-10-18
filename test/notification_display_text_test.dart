import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/services/notification_display_text.dart';

void main() {
  test('private chat notifications use generic localized body, not message content', () {
    expect(localizedNotificationBody('en', type: 'message', fallback: 'private message'), 'You have a new message');
    expect(localizedNotificationBody('ar', type: 'message'), 'لديك رسالة جديدة');
    expect(localizedNotificationBody('fr', type: 'message'), 'Vous avez un nouveau message');
  });
  test('device locales normalize to the supported registration contract', () {
    expect(notificationLanguageCode('ar-DZ'), 'ar');
    expect(notificationLanguageCode('fr_FR'), 'fr');
    expect(notificationLanguageCode('EN'), 'en');
    expect(notificationLanguageCode('de'), 'en');
  });
  test('known push templates use the selected language', () {
    expect(localizedNotificationBody('ar', type: 'comment'), 'علّق على منشورك');
    expect(
        localizedNotificationBody('en',
            type: 'comment', fallback: 'علّق على منشورك'),
        'Commented on your post');
    expect(localizedNotificationBody('fr', type: 'follow_request'),
        'A demandé à vous suivre');
    for (final type in [
      'new_post',
      'like',
      'like_comment',
      'comment',
      'reply',
      'repost',
      'follow',
      'follow_request',
      'follow_accepted'
    ]) {
      for (final language in ['en', 'fr']) {
        expect(
            RegExp(r'[\u0600-\u06ff]')
                .hasMatch(localizedNotificationBody(language, type: type)),
            isFalse);
      }
    }
  });

  test('announcement, exam and unknown payload content stays verbatim', () {
    for (final type in ['announcement', 'exam_reminder', 'custom']) {
      expect(
          localizedNotificationBody('fr',
              type: type, fallback: 'موعد الرياضيات 10:30'),
          'موعد الرياضيات 10:30');
    }
    expect(localizedNotificationBody('en', type: 'custom'),
        'You have a new notification');
  });

  test('notification channel labels have each supported locale', () {
    expect(localizedNotificationChannelName('en'), 'UniSpace notifications');
    expect(localizedNotificationChannelName('fr'), 'Notifications UniSpace');
    expect(localizedNotificationChannelDescription('ar'),
        'متابعة، تعليقات، إعجابات');
  });
}
