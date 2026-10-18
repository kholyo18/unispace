import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:UniSpace/main.dart' show NotificationItem;

void main() {
  test(
      'in-app message notification is translated and never exposes private text',
      () {
    final original = Intl.defaultLocale;
    addTearDown(() => Intl.defaultLocale = original);
    const item = NotificationItem(
        id: 'chat_test',
        sender: 'A',
        message: 'private text',
        type: 'message',
        chatId: 'group_test');
    for (final row in [
      ('ar', 'لديك رسالة جديدة'),
      ('en', 'You have a new message'),
      ('fr', 'Vous avez un nouveau message'),
    ]) {
      Intl.defaultLocale = row.$1;
      expect(item.displayMessage, row.$2);
    }
  });
}
