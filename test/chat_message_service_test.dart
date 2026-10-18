import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/services/chat_message_service.dart';

void main() {
  test('optimistic entries remain until observed and acknowledgement cannot resend', () async {
    var sends=0;final gate=Completer<void>();
    final box=ChatOutbox(currentSessionKey:()=> 'a:s',newMessageId:()=> 'm',retainUntilObserved:true,send:(c,id,m) async {sends++;await gate.future;});
    final entry=box.enqueue(chatId:'c',message:{'type':'text','text':'hello'});
    final attempt=box.attempt(entry.id);
    expect(box.entries.single.state,ChatOutboxState.sending);
    gate.complete();expect(await attempt,isTrue);
    expect(box.entries.single.state,ChatOutboxState.acknowledged);
    expect(await box.retry(entry.id),isTrue);expect(sends,1);
    box.observe(['m']);expect(box.entries,isEmpty);
  });
  test('snapshot before acknowledgement does not resurrect an optimistic entry', () async {
    final gate=Completer<void>();
    final box=ChatOutbox(currentSessionKey:()=> 'a:s',newMessageId:()=> 'm',retainUntilObserved:true,send:(c,id,m)=>gate.future);
    final entry=box.enqueue(chatId:'c',message:{'text':'hello'});final attempt=box.attempt(entry.id);
    box.observe(['m']);expect(box.entries,isEmpty);
    gate.complete();expect(await attempt,isTrue);expect(box.entries,isEmpty);
  });
  test('a second message can enqueue while the first confirmation is pending', () async {
    var id=0;final gate=Completer<void>();
    final box=ChatOutbox(currentSessionKey:()=> 'a:s',newMessageId:()=> '${++id}',retainUntilObserved:true,send:(c,id,m)=>gate.future);
    final first=box.enqueue(chatId:'c',message:{'text':'first'});final one=box.attempt(first.id);
    final second=box.enqueue(chatId:'c',message:{'text':'second'});final two=box.attempt(second.id);
    expect(box.entries.length,2);expect(first.id,isNot(second.id));gate.complete();await Future.wait([one,two]);
    box.observe([first.id,second.id]);expect(box.entries,isEmpty);
  });

  tearDown(ChatDraftStore.clear);
  test('draft survives navigation only within same signed session', () {
    ChatDraftStore.put('c', 'alice:old', 'not yet sent');
    expect(ChatDraftStore.get('other', 'alice:old'), '');
    expect(ChatDraftStore.get('c', 'alice:old'), 'not yet sent');
    expect(ChatDraftStore.get('c', 'alice:new'), '');
    ChatDraftStore.put('c', 'alice:new', 'private');
    expect(ChatDraftStore.get('c', ''), '');
    expect(ChatDraftStore.get('c', 'bob:session'), '');
  });
  test('empty drafts are removed and capacity never drops existing text', () {
    for (var i = 0; i < 128; i++) {
      ChatDraftStore.put('$i', 'a:s', 'draft $i');
    }
    expect(
        () => ChatDraftStore.put('overflow', 'a:s', 'keep'), throwsStateError);
    expect(ChatDraftStore.get('0', 'a:s'), 'draft 0');
    ChatDraftStore.put('0', 'a:s', 'edited');
    expect(ChatDraftStore.get('0', 'a:s'), 'edited');
    ChatDraftStore.put('0', 'a:s', '');
    ChatDraftStore.put('overflow', 'a:s', 'now fits');
    expect(ChatDraftStore.get('overflow', 'a:s'), 'now fits');
    ChatDraftStore.clear();
    expect(ChatDraftStore.get('overflow', 'a:s'), '');
    expect(() => ChatDraftStore.put('c', '', 'private'), throwsStateError);
  });
  tearDown(ChatOutboxStore.clear);

  test('store restores failed sends on navigation and wipes on new session',
      () async {
    var session = 'alice:old';
    ChatOutbox acquire() => ChatOutboxStore.forSession(
          chatId: 'c',
          currentSessionKey: () => session,
          sender: (_, __, ___) async => throw StateError('offline'),
          newMessageId: () => 'm',
        );
    final first = acquire();
    final entry = first.enqueue(chatId: 'c', message: {'text': 'private'});
    await first.attempt(entry.id);
    first.onChanged = null;
    final reopened = acquire();
    expect(identical(first, reopened), true);
    expect(reopened.entries.single.message['text'], 'private');
    session = 'alice:new';
    expect(acquire().entries, isEmpty);
    expect(first.entries, isEmpty);
    session = '';
    expect(acquire, throwsStateError);
  });

  test('full store refuses new outbox without losing failed messages',
      () async {
    for (var i = 0; i < 32; i++) {
      final outbox = ChatOutboxStore.forSession(
        chatId: '$i',
        currentSessionKey: () => 'a:s',
        sender: (_, __, ___) async => throw StateError('offline'),
        newMessageId: () => 'm',
      );
      final entry = outbox.enqueue(chatId: '$i', message: {'text': 'keep'});
      await outbox.attempt(entry.id);
    }
    expect(
        () => ChatOutboxStore.forSession(
            chatId: 'overflow',
            currentSessionKey: () => 'a:s',
            sender: (_, __, ___) async {},
            newMessageId: () => 'm'),
        throwsStateError);
    final first = ChatOutboxStore.forSession(
        chatId: '0',
        currentSessionKey: () => 'a:s',
        sender: (_, __, ___) async {},
        newMessageId: () => 'm');
    expect(first.entries.single.message['text'], 'keep');
  });
  test('lost acknowledgement retries same immutable payload and ID', () async {
    var calls = 0;
    final sent = <String, Map<String, dynamic>>{};
    final outbox = ChatOutbox(
      currentSessionKey: () => 'alice:sid',
      newMessageId: () => 'm1',
      send: (chat, id, message) async {
        sent.putIfAbsent(id, () => message);
        if (++calls == 1) throw StateError('response lost');
      },
    );
    final original = {'type': 'text', 'text': 'hello'};
    final entry = outbox.enqueue(chatId: 'a_b', message: original);
    original['text'] = 'changed';
    expect(await outbox.attempt(entry.id), false);
    expect(entry.state, ChatOutboxState.failed);
    expect(entry.message['text'], 'hello');
    expect(outbox.entries, [entry]);
    expect(await outbox.retry(entry.id), true);
    expect(sent.length, 1);
    expect(sent['m1']!['text'], 'hello');
    expect(outbox.entries, isEmpty);
  });

  test('concurrent retry sends once and cannot remove an in-flight message',
      () async {
    final network = Completer<void>();
    var calls = 0;
    final outbox = ChatOutbox(
      currentSessionKey: () => 'a:s',
      newMessageId: () => 'm',
      send: (_, __, ___) {
        calls++;
        return network.future;
      },
    );
    final entry = outbox.enqueue(chatId: 'c', message: {'text': 'hi'});
    final first = outbox.attempt(entry.id);
    final second = outbox.retry(entry.id);
    outbox.removeFailed(entry.id);
    expect(outbox.entries.length, 1);
    expect(identical(first, second), true);
    expect(calls, 1);
    network.complete();
    expect(await first, true);
  });

  test('account or signed session changes discard drafts and stale completion',
      () async {
    for (final replacement in ['bob:new', 'alice:new', '']) {
      var session = 'alice:old';
      final network = Completer<void>();
      final outbox = ChatOutbox(
        currentSessionKey: () => session,
        newMessageId: () => 'm',
        send: (_, __, ___) => network.future,
      );
      final entry = outbox.enqueue(chatId: 'c', message: {'text': 'private'});
      final result = outbox.attempt(entry.id);
      session = replacement;
      expect(outbox.entries, isEmpty);
      network.complete();
      expect(await result, false);
      expect(outbox.entries, isEmpty);
    }
  });

  test('clearing during send cannot resurrect failure in a new session',
      () async {
    final network = Completer<void>();
    final outbox = ChatOutbox(
      currentSessionKey: () => 'a:s',
      newMessageId: () => 'm',
      send: (_, __, ___) => network.future,
    );
    final entry = outbox.enqueue(chatId: 'c', message: {'text': 'private'});
    final attempt = outbox.attempt(entry.id);
    outbox.clear();
    network.completeError(StateError('offline'));
    expect(await attempt, false);
    expect(outbox.entries, isEmpty);
  });

  test('failed message can be removed; signed-out enqueue is refused',
      () async {
    var session = 'a:s';
    final outbox = ChatOutbox(
      currentSessionKey: () => session,
      newMessageId: () => 'm',
      send: (_, __, ___) async => throw StateError('offline'),
    );
    final entry = outbox.enqueue(chatId: 'c', message: {'text': 'private'});
    await outbox.attempt(entry.id);
    outbox.removeFailed(entry.id);
    expect(outbox.entries, isEmpty);
    session = '';
    expect(() => outbox.enqueue(chatId: 'c', message: {'text': 'x'}),
        throwsStateError);
  });

  test('callable adapter forwards stable message id and checks confirmation',
      () async {
    final service = ChatMessageService.forTesting(
      currentUserId: () => 'alice',
      call: (name, data) async {
        expect(name, 'sendChatMessage');
        expect(data, {
          'chatId': 'c',
          'messageId': 'm',
          'message': {'text': 'hello'}
        });
        return {'messageId': 'm'};
      },
    );
    expect(
        await service.sendChatMessage(
            chatId: 'c', messageId: 'm', message: {'text': 'hello'}),
        'm');
  });

  test('callable rejects success from prior account and signed-out requests',
      () async {
    String? uid = 'alice';
    var calls = 0;
    final service = ChatMessageService.forTesting(
      currentUserId: () => uid,
      call: (_, __) async {
        calls++;
        uid = 'bob';
        return {'messageId': 'm'};
      },
    );
    await expectLater(
        service.sendChatMessage(
            chatId: 'c', messageId: 'm', message: {'text': 'x'}),
        throwsA(isA<FirebaseFunctionsException>()));
    uid = null;
    await expectLater(
        service.openChat('bob'), throwsA(isA<FirebaseFunctionsException>()));
    expect(calls, 1);
  });

  test('open, respond, and edit use callable contract', () async {
    final calls = <String>[];
    final service = ChatMessageService.forTesting(
      currentUserId: () => 'alice',
      call: (name, data) async {
        calls.add(name);
        if (name == 'openChat') expect(data, {'peerId': 'bob'});
        if (name == 'respondChatRequest') {
          expect(data, {'requestId': 'r', 'action': 'accept'});
        }
        if (name == 'mutateChatMessage') {
          expect(data, {
            'chatId': 'c',
            'messageId': 'm',
            'action': 'edit',
            'text': 'new'
          });
        }
        return {'chatId': 'c', 'status': 'open'};
      },
    );
    expect((await service.openChat('bob')).status, 'open');
    expect(
        (await service.respondChatRequest(requestId: 'r', action: 'accept'))
            .chatId,
        'c');
    await service.mutateChatMessage(
        chatId: 'c', messageId: 'm', action: 'edit', text: 'new');
    expect(calls, ['openChat', 'respondChatRequest', 'mutateChatMessage']);
  });
}
