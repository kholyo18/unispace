import 'dart:async';
import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/shell/chat/chat_media_composer.dart';
import 'package:UniSpace/features/shell/chat/chat_media_send_queue.dart';
import 'package:UniSpace/features/shell/chat/chat_media_sender.dart';
import 'package:UniSpace/features/shell/chat/chat_transfer_center.dart';
import 'package:UniSpace/services/chat_message_service.dart';

void main() {
  test('cancel during transfer removes entry once transport settles', () async {
    final gate = Completer<void>();
    final queue = ChatMediaSendQueue(send: (_, __) => gate.future);
    queue.enqueue([ChatMediaDraft(File('pending.jpg'))]);
    final entry = queue.entries.single;
    expect(entry.sending, true);
    queue.discard(entry);
    gate.completeError(StateError('Cancelled'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(queue.entries, isEmpty);
    queue.dispose();
  });
  test(
      'detached center retains sending outbox and prunes only after acknowledgement',
      () async {
    final center = ChatTransferCenter(), gate = Completer<void>();
    final outbox = ChatOutbox(
        currentSessionKey: () => 'alice',
        newMessageId: () => 'stable',
        retainUntilObserved: true,
        send: (_, __, ___) => gate.future);
    final queue = center.obtain(
        chatId: 'c',
        title: 'Chat',
        session: 'alice',
        currentSession: () => 'alice',
        outbox: outbox,
        tooLarge: '',
        tooLong: '',
        stillOnly: '');
    await queue.ready;
    final entry =
        outbox.enqueue(chatId: 'c', message: {'type': 'text', 'text': 'hello'});
    final sending = outbox.attempt(entry.id);
    center.detach('c');
    await Future<void>.delayed(Duration.zero);
    expect(center.jobs.length, 1);
    gate.complete();
    expect(await sending, true);
    await Future<void>.delayed(Duration.zero);
    expect(center.jobs, isEmpty);
    center.clear();
    outbox.clear();
  });
  test('old outbox reference refuses new-account enqueue', () {
    var session = 'alice';
    final outbox = ChatOutbox(
        currentSessionKey: () => session,
        newMessageId: () => 'stable',
        send: (_, __, ___) async {});
    session = 'bob';
    expect(
        () => outbox.enqueue(
            chatId: 'old-chat',
            message: {'type': 'text', 'text': 'wrong account'}),
        throwsStateError);
  });

  test('transfer ownership survives route listener removal and reopening',
      () async {
    var session = 'alice';
    final center = ChatTransferCenter();
    final outbox = ChatOutbox(
        currentSessionKey: () => session,
        newMessageId: () => 'id',
        send: (_, __, ___) async {});
    ChatMediaSendQueue obtain() => center.obtain(
        chatId: 'chat',
        title: 'Chat',
        session: session,
        currentSession: () => session,
        outbox: outbox,
        tooLarge: 'large',
        tooLong: 'long',
        stillOnly: 'still');
    final first = obtain();
    await first.ready;
    void listener() {}
    first.addListener(listener);
    final draft = ChatMediaDraft(File('not-uploaded.jpg'));
    await first.replaceDrafts([draft]);
    final id = first.messageIdFor(draft);
    first.removeListener(listener);
    expect(identical(obtain(), first), true);
    expect(first.messageIdFor(draft), id);
    expect(first.entries.single.draft, draft);
    session = 'bob';
    final replacement = obtain();
    await replacement.ready;
    expect(identical(first, replacement), false);
    expect(center.jobs.length, 1);
    expect(() => first.enqueue([draft]), throwsStateError);
    center.clear();
    outbox.clear();
  });
  test(
      'detached UI cannot cancel an ongoing queue transfer or duplicate retry ID',
      () async {
    final gate = Completer<void>();
    var calls = 0;
    var fail = true;
    final queue = ChatMediaSendQueue(send: (draft, progress) async {
      calls++;
      await gate.future;
      if (fail)
        throw FirebaseFunctionsException(code: 'unavailable', message: 'retry');
    });
    var notifications = 0;
    void listener() {
      notifications++;
    }

    queue.addListener(listener);
    final draft = ChatMediaDraft(File('image.jpg'));
    queue.enqueue([draft]);
    final id = queue.messageIdFor(draft);
    queue.removeListener(listener);
    final before = notifications;
    gate.complete();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(notifications, before);
    expect(queue.entries.single.error, isNotNull);
    expect(queue.messageIdFor(draft), id);
    fail = false;
    queue.retry(queue.entries.single);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(calls, 2);
    expect(queue.entries, isEmpty);
    queue.dispose();
  });
  test(
      'outbox change channel survives detached route and suppresses old session completion',
      () async {
    var session = 'alice';
    final gate = Completer<void>();
    var changes = 0, ui = 0;
    final outbox = ChatOutbox(
        currentSessionKey: () => session,
        newMessageId: () => 'stable',
        send: (_, __, ___) => gate.future,
        onChanged: () {
          ui++;
        });
    outbox.changes.addListener(() => changes++);
    final entry =
        outbox.enqueue(chatId: 'c', message: {'type': 'text', 'text': 'hello'});
    outbox.onChanged = null;
    final beforeUi = ui;
    final attempt = outbox.attempt(entry.id);
    expect(changes, greaterThan(1));
    expect(ui, beforeUi);
    session = 'bob';
    gate.complete();
    expect(await attempt, false);
    expect(outbox.entries, isEmpty);
    outbox.clear();
  });
  test('cancelled or closed sender rejects before invoking Firebase', () async {
    final outbox = ChatOutbox(
        currentSessionKey: () => 'alice',
        newMessageId: () => 'id',
        send: (_, __, ___) async {});
    final sender = ChatMediaSender(
        chatId: 'c',
        session: 'alice',
        currentSession: () => 'alice',
        outbox: outbox,
        tooLarge: 'large',
        tooLong: 'long',
        stillOnly: 'still');
    final draft = ChatMediaDraft(File('image.jpg'));
    await sender.cancel(draft);
    await expectLater(sender.send(draft, (_) {}), throwsStateError);
    sender.allowRetry(draft);
    sender.close();
    await expectLater(sender.send(draft, (_) {}), throwsStateError);
    outbox.clear();
  });
}
