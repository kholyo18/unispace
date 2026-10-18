import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/services/chat_notification_actions.dart';

void main() {
  final payload = {'type':'message','recipientId':'alice','notificationId':'chat_123','chatId':'conversation','messageId':'message'};
  test('reply sends only the explicit trimmed input and authoritative locator', () async {
    Map<String, dynamic>? sent;
    final client=ChatNotificationActions.forTesting(identity: () async => 'alice:sid',call:(data) async {
      sent=data; return {'action':'reply','messageId':'server-reply'};
    });
    await client.perform(payload,'reply',input:' Thanks ');
    expect(sent,{'notificationId':'chat_123','chatId':'conversation','messageId':'message','action':'reply','text':'Thanks'});
  });
  test('another account, absent session and session replacement never send', () async {
    for(final first in <String?>[null,'bob:sid']) {
      var calls=0;
      final client=ChatNotificationActions.forTesting(identity:() async=>first,call:(_) async {calls++;return {};});
      await expectLater(client.perform(payload,'markRead'),throwsA(isA<FirebaseFunctionsException>()));expect(calls,0);
    }
    var reads=0,calls=0;
    final client=ChatNotificationActions.forTesting(identity:() async=>++reads==1?'alice:first':'alice:replacement',call:(_) async{calls++;return {};});
    await expectLater(client.perform(payload,'reply',input:'Text'),throwsA(isA<FirebaseFunctionsException>()));expect(calls,0);
  });
  test('empty replies and unknown actions do not invoke transport', () async {
    var calls=0;final client=ChatNotificationActions.forTesting(identity:() async=>'alice:sid',call:(_) async{calls++;return {};});
    await expectLater(client.perform(payload,'reply',input:' '),throwsA(isA<FirebaseFunctionsException>()));
    await expectLater(client.perform(payload,'delete'),throwsA(isA<FirebaseFunctionsException>()));expect(calls,0);
  });
  test('mark read requires exact server confirmation and carries no reply text', () async {
    Map<String,dynamic>? sent;
    final client=ChatNotificationActions.forTesting(identity:() async=>'alice:sid',call:(data) async {sent=data;return {'action':'markRead','notificationId':'other'};});
    await expectLater(client.perform(payload,'markRead'),throwsA(isA<FirebaseFunctionsException>().having((e)=>e.code,'code','data-loss')));
    expect(sent!.containsKey('text'),false);
  });
  test('display identity is stable across retries; action labels support three languages', () {
    expect(chatNotificationLocalId('chat_123'),chatNotificationLocalId('chat_123'));
    expect(chatNotificationLocalId('chat_123'),isNot(chatNotificationLocalId('chat_124')));
    for(final key in ['Reply','Mark as read','Write a reply','Reply sent','Marked as read','Retry']) {
      expect(chatNotificationActionText('en',key),key);
      expect(chatNotificationActionText('ar',key),isNot(key));
      expect(chatNotificationActionText('fr-FR',key),isNot(key));
    }
  });
}
