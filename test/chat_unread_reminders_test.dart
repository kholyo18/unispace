import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:UniSpace/services/chat_unread_reminders.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('reminder survives restart and is scoped to account', () async {
    final first = ChatUnreadReminders();
    await first.set('alice', 'chat', true);
    final restarted = ChatUnreadReminders();
    await restarted.load('alice');
    await restarted.load('bob');
    expect(restarted.contains('alice', 'chat'), isTrue);
    expect(restarted.contains('bob', 'chat'), isFalse);
    await restarted.set('alice', 'chat', false);
    final next = ChatUnreadReminders();
    await next.load('alice');
    expect(next.contains('alice', 'chat'), isFalse);
  });
  test('concurrent edits retain every reminder and clearing is idempotent', () async {
    final store = ChatUnreadReminders();
    await Future.wait([store.set('a', 'one', true), store.set('a', 'two', true)]);
    expect(store.contains('a', 'one'), isTrue);
    expect(store.contains('a', 'two'), isTrue);
    await store.set('a', 'one', false);
    await store.set('a', 'one', false);
    expect(store.contains('a', 'two'), isTrue);
  });
}
