import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/shell/chat/chat_media_composer.dart';
import 'package:UniSpace/features/shell/chat/chat_media_send_queue.dart';
void main() {
  test('queue returns immediately, sends sequentially and retains failed upload identity', () async {
    final gate = Completer<void>();
    final first = ChatMediaDraft(File('first.jpg'));
    final second = ChatMediaDraft(File('second.jpg'));
    final calls = <ChatMediaDraft>[];
    var fail = true;
    final queue = ChatMediaSendQueue(send: (draft, progress) async {
      calls.add(draft);
      if (identical(draft, first)) await gate.future;
      progress(.5);
      if (identical(draft, second) && fail) {
        draft.uploadUrl = 'already-uploaded';
        throw StateError('network');
      }
    });
    queue.enqueue([first, second]);
    expect(queue.entries.length, 2);
    expect(calls, [first]);
    gate.complete();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(calls, [first, second]);
    expect(queue.entries.single.error, isNotNull);
    fail = false;
    queue.retry(queue.entries.single);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(calls, [first, second, second]);
    expect(second.uploadUrl, 'already-uploaded');
    expect(queue.entries, isEmpty);
    queue.dispose();
  });
  test('closing queue waits for active send before deleting generated file', () async {
    final directory = await Directory.systemTemp.createTemp('chat-queue-');
    final original = await File('${directory.path}/original').writeAsBytes([1]);
    final generated = await File('${directory.path}/edited').writeAsBytes([2]);
    final draft = ChatMediaDraft(original)..generated.add(generated);
    final gate = Completer<void>();
    final queue = ChatMediaSendQueue(send: (_, __) => gate.future);
    queue.enqueue([draft]);
    queue.dispose();
    expect(await generated.exists(), isTrue);
    gate.complete();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(await generated.exists(), isFalse);
    expect(await original.exists(), isTrue);
    await directory.delete(recursive: true);
  });
}
