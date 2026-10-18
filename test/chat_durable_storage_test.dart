import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:UniSpace/services/chat_message_service.dart';
import 'package:UniSpace/services/chat_local_persistence.dart';
import 'package:UniSpace/features/shell/chat/chat_media_composer.dart';
import 'package:UniSpace/features/shell/chat/chat_media_send_queue.dart';

class MemoryPrivateStore implements ChatLocalStorage {
  final values = <String, String>{};
  final files = <String, Uint8List>{};
  bool current = true, fail = false;
  @override
  bool get isCurrent => current;
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String? value) async {
    if (fail) throw StateError('disk');
    if (value == null) {
      values.remove(key);
      files.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> keepFile(String key, File file) async {
    files[key] = await file.readAsBytes();
  }

  @override
  Future<File?> restoreFile(String key, String extension) async {
    if (!files.containsKey(key)) return null;
    final dir = await Directory.systemTemp.createTemp('restored-chat-');
    return File('${dir.path}/restored.$extension').writeAsBytes(files[key]!);
  }

  @override
  Future<void> purge() async {
    values.clear();
    files.clear();
  }
}

void main() {
  test('restart retains immutable ID and payload after lost acknowledgement',
      () async {
    final store = MemoryPrivateStore();
    var attempts = 0;
    final committed = <String>{};
    Future<void> send(String c, String id, Map<String, dynamic> message) async {
      committed.add(id);
      expect(message['text'], 'before restart');
      if (++attempts == 1)
        throw FirebaseFunctionsException(
            code: 'unavailable', message: 'lost ack');
    }

    ChatOutbox create() => ChatOutbox(
        currentSessionKey: () => 'alice:sid',
        newMessageId: () => 'stable',
        send: send,
        persistence: store,
        persistenceKey: 'outbox');
    final first = create();
    await first.ready;
    final entry = first.enqueue(
        chatId: 'chat', message: {'type': 'text', 'text': 'before restart'});
    expect(await first.attempt(entry.id), false);
    await first.flush();
    final restored = create();
    await restored.ready;
    expect(restored.entries.single.id, 'stable');
    expect(restored.entries.single.retryable, true);
    expect(await restored.retry('stable'), true);
    await restored.flush();
    expect(committed, {'stable'});
    final empty = create();
    await empty.ready;
    expect(empty.entries, isEmpty);
  });
  test(
      'disk failure prevents network send and once-only payload is never retained',
      () async {
    final store = MemoryPrivateStore();
    var calls = 0;
    final out = ChatOutbox(
        currentSessionKey: () => 'a:s',
        newMessageId: () => 'm',
        send: (_, __, ___) async {
          calls++;
        },
        persistence: store,
        persistenceKey: 'out');
    await out.ready;
    store.fail = true;
    final entry = out.enqueue(chatId: 'c', message: {'text': 'private'});
    expect(await out.attempt(entry.id), false);
    expect(calls, 0);
    store.fail = false;
    out.removeFailed(entry.id);
    await out.flush();
    out.enqueue(
        chatId: 'c',
        message: {'type': 'viewOnce', 'mediaId': 'private-ticket'});
    await out.flush();
    expect(store.values.values.join(), isNot(contains('private-ticket')));
  });
  test('account switch during hydration cannot expose prior messages',
      () async {
    final store = MemoryPrivateStore();
    var session = 'a:s';
    final out = ChatOutbox(
        currentSessionKey: () => session,
        newMessageId: () => 'm',
        send: (_, __, ___) async {},
        persistence: store,
        persistenceKey: 'o');
    await out.ready;
    out.enqueue(chatId: 'c', message: {'text': 'a private'});
    await out.flush();
    store.current = false;
    session = 'b:s';
    expect(out.entries, isEmpty);
    expect(() => out.enqueue(chatId: 'c', message: {'text': 'wrong'}),
        throwsStateError);
  });
  test(
      'permanent failures never retry on connectivity and concurrent retries share send',
      () async {
    final store = MemoryPrivateStore();
    var calls = 0;
    final out = ChatOutbox(
        currentSessionKey: () => 'a:s',
        newMessageId: () => 'm',
        send: (_, __, ___) async {
          calls++;
          throw FirebaseFunctionsException(
              code: 'permission-denied', message: 'denied');
        },
        persistence: store,
        persistenceKey: 'o');
    await out.ready;
    out.enqueue(chatId: 'c', message: {'text': 'x'});
    await Future.wait([out.attempt('m'), out.attempt('m')]);
    await out.retryTransient();
    expect(calls, 1);
    await out.flush();
  });
  test(
      'text draft restores after process cache loss and stays per conversation',
      () async {
    final store = MemoryPrivateStore();
    ChatDraftStore.clear();
    await ChatDraftStore.restore('one', 'a:s', persistence: store);
    ChatDraftStore.put('one', 'a:s', 'draft');
    await ChatDraftStore.flush();
    ChatDraftStore.clear();
    await ChatDraftStore.restore('one', 'a:s', persistence: store);
    expect(ChatDraftStore.get('one', 'a:s'), 'draft');
    expect(ChatDraftStore.get('two', 'a:s'), '');
    ChatDraftStore.clear();
  });
  test(
      'encrypted attachment restart preserves ID, caption and retry file; viewOnce excluded',
      () async {
    final store = MemoryPrivateStore();
    final dir = await Directory.systemTemp.createTemp('chat-durable-');
    final file = await File('${dir.path}/a.jpg').writeAsBytes([1, 2, 3]);
    final draft = ChatMediaDraft(file)..caption = 'caption';
    final queue = ChatMediaSendQueue(
        chatId: 'c',
        persistence: store,
        send: (_, __) async {
          throw StateError('offline');
        });
    await queue.ready;
    queue.enqueue([draft]);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await queue.flush();
    final id = queue.messageIdFor(draft);
    queue.dispose();
    final restored = ChatMediaSendQueue(
        chatId: 'c', persistence: store, send: (_, __) async {});
    await restored.ready;
    expect(restored.entries.single.id, id);
    expect(restored.entries.single.draft.caption, 'caption');
    expect(await restored.entries.single.draft.file.readAsBytes(), [1, 2, 3]);
    restored.retry(restored.entries.single);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await restored.flush();
    expect(restored.entries, isEmpty);
    expect(store.files, isEmpty);
    restored.dispose();
    final once = ChatMediaDraft(file)..viewOnce = true;
    final privateQueue = ChatMediaSendQueue(
        chatId: 'v',
        persistence: store,
        send: (_, __) async {
          throw StateError('offline');
        });
    await privateQueue.ready;
    privateQueue.enqueue([once]);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await privateQueue.flush();
    expect(store.files, isEmpty);
    privateQueue.dispose();
    await dir.delete(recursive: true);
  });
}
