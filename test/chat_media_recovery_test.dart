import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:UniSpace/services/chat_local_persistence.dart';
import 'package:UniSpace/features/shell/chat/chat_media_composer.dart';
import 'package:UniSpace/features/shell/chat/chat_media_send_queue.dart';
import 'chat_durable_storage_test.dart' show MemoryPrivateStore;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'composer attachment draft survives restart without sending and excludes once-only',
      () async {
    final store = MemoryPrivateStore(),
        dir = await Directory.systemTemp.createTemp('chat-selection-');
    final file = await File('${dir.path}/original.jpg').writeAsBytes([3, 4]);
    final first = ChatMediaDraftStore(persistence: store, chatId: 'chat');
    await first.ready;
    await first.save([
      ChatMediaDraft(file)..caption = 'unsent caption',
      ChatMediaDraft(file)..viewOnce = true
    ]);
    first.dispose();
    final restored = ChatMediaDraftStore(persistence: store, chatId: 'chat');
    await restored.ready;
    expect(restored.drafts.length, 1);
    expect(restored.drafts.single.caption, 'unsent caption');
    expect(await restored.drafts.single.file.readAsBytes(), [3, 4]);
    await restored.clear();
    expect(store.files, isEmpty);
    restored.dispose();
    await dir.delete(recursive: true);
  });
  test(
      'media reconnection retries transient errors within budget but not privacy failures',
      () async {
    final dir = await Directory.systemTemp.createTemp('chat-retry-');
    final file = await File('${dir.path}/a.jpg').writeAsBytes([1]);
    var calls = 0, code = 'network-request-failed';
    final queue = ChatMediaSendQueue(send: (_, __) async {
      calls++;
      throw FirebaseException(plugin: 'firebase_storage', code: code);
    });
    queue.enqueue([ChatMediaDraft(file)]);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    queue.entries.single.retryAfter =
        DateTime.now().subtract(const Duration(seconds: 1));
    code = 'permission-denied';
    await queue.retryTransient();
    expect(calls, 2);
    queue.entries.single.retryAfter = null;
    await queue.retryTransient();
    expect(calls, 2);
    queue.entries.single.errorCode = 'unavailable';
    queue.entries.single.attempts = 5;
    await queue.retryTransient();
    expect(calls, 2);
    queue.dispose();
    await dir.delete(recursive: true);
  });
  test(
      'adapter hashes stable scope and refuses old account writes; purge may follow signout',
      () async {
    const channel = MethodChannel('test-private-chat');
    final calls = <MethodCall>[];
    var session = 'alice:signedSid:123';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    final store = await ChatLocalPersistence.open(
        sessionKey: session,
        currentSessionKey: () => session,
        channel: channel);
    expect((calls.single.arguments as Map)['scope'],
        matches(RegExp(r'^[a-f0-9]{64}$')));
    await store.write('draft', 'private');
    session = 'bob:newSid:456';
    await expectLater(store.write('draft', 'wrong account'), throwsStateError);
    expect(calls.where((call) => call.method == 'write').length, 1);
    await ChatLocalPersistence.purgeActive();
    expect(calls.last.method, 'purge');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  test('retrying composer handoff after disk failure preserves one queue ID',
      () async {
    final store = MemoryPrivateStore(),
        dir = await Directory.systemTemp.createTemp('chat-handoff-');
    final file = await File('${dir.path}/a.jpg').writeAsBytes([1]);
    final gate = Completer<void>();
    var sends = 0;
    final queue = ChatMediaSendQueue(
        chatId: 'chat',
        persistence: store,
        send: (_, __) async {
          sends++;
          await gate.future;
        });
    await queue.ready;
    store.fail = true;
    final draft = ChatMediaDraft(file);
    queue.enqueue([draft]);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await expectLater(queue.flush(), throwsStateError);
    final id = queue.messageIdFor(draft);
    expect(sends, 0);
    store.fail = false;
    queue.enqueue([draft, draft]);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await queue.flush();
    expect(queue.entries.length, 1);
    expect(queue.messageIdFor(draft), id);
    expect(sends, 1);
    gate.complete();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    queue.dispose();
    await dir.delete(recursive: true);
  });
}
