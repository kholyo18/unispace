import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/services/chat_conversation_metadata.dart';
import 'package:UniSpace/l10n/chat_ui_strings.dart';

void main() {
  final now = DateTime(2026, 10, 8, 12);
  DateTime? timestamp(Object? value) => value is DateTime ? value : null;
  test('direct conversation receipt remains the peer receipt', () {
    final m = ChatConversationMetadata({
      'memberIds': ['me', 'peer'],
      'lastReadAt': {'peer': now}
    }, 'me');
    expect(m.isGroup, false);
    expect(m.receiptThrough('lastReadAt', timestamp: timestamp), now);
  });
  test('group receipt requires all recipients and uses earliest acknowledgment',
      () {
    final early = now.subtract(const Duration(minutes: 2));
    final data = <String, dynamic>{
      'type': 'group',
      'memberIds': ['me', 'a', 'b'],
      'lastReadAt': {'me': now, 'a': early}
    };
    final m = ChatConversationMetadata(data, 'me');
    expect(m.isGroup, true);
    expect(m.receiptThrough('lastReadAt', timestamp: timestamp), isNull);
    (data['lastReadAt'] as Map)['b'] = now;
    expect(m.receiptThrough('lastReadAt', timestamp: timestamp), early);
  });
  test('creator alone and nonmember receipts never show delivered', () {
    final m = ChatConversationMetadata({
      'memberIds': ['me'],
      'lastDeliveredAt': {'removed': now, 'me': now}
    }, 'me');
    expect(m.receiptThrough('lastDeliveredAt', timestamp: timestamp), isNull);
  });
  test('typing excludes viewer removed members stale and future values', () {
    final data = <String, dynamic>{
      'memberIds': ['me', 'a', 'b'],
      'typing': {
        'me': now,
        'removed': now,
        'a': now.subtract(const Duration(seconds: 5)),
        'b': now.add(const Duration(seconds: 1))
      }
    };
    final m = ChatConversationMetadata(data, 'me');
    expect(m.typingRemaining(timestamp: timestamp, now: now), Duration.zero);
    (data['typing'] as Map)['a'] = now.subtract(const Duration(seconds: 1));
    expect(m.typingRemaining(timestamp: timestamp, now: now),
        const Duration(seconds: 3));
  });
  test('date headers distinguish same day midnight and missing timestamps', () {
    expect(ChatConversationMetadata.startsDay(null, null), false);
    expect(ChatConversationMetadata.startsDay(now.millisecondsSinceEpoch, null),
        true);
    expect(
        ChatConversationMetadata.startsDay(now.millisecondsSinceEpoch,
            now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch),
        false);
    expect(
        ChatConversationMetadata.startsDay(now.millisecondsSinceEpoch,
            now.subtract(const Duration(days: 1)).millisecondsSinceEpoch),
        true);
  });
  test('inbox labels have nonempty Arabic English and French translations', () {
    for (final key in ChatUiStrings.values.keys) {
      for (final language in ['ar', 'en', 'fr']) {
        expect(ChatUiStrings.text(language, key), isNotEmpty);
      }
      expect(ChatUiStrings.text('ar', key), isNot(key));
      expect(ChatUiStrings.text('fr', key), isNot(key));
    }
  });
}
