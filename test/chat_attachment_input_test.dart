import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/services/chat_attachment_input.dart';
import 'package:UniSpace/services/chat_message_service.dart';
import 'package:UniSpace/features/shell/chat/chat_link_dialog.dart';

void main() {
  test('oversize document rejected before reading its source', () async {
    var read = false;
    Stream<List<int>> source() async* {
      read = true;
      yield [1];
    }

    await expectLater(
        readChatDocument(PlatformFile(
            name: 'large.pdf',
            size: chatDocumentMaxBytes + 1,
            readStream: source())),
        throwsFormatException);
    expect(read, false);
    await expectLater(
        readChatDocument(
            PlatformFile(name: 'empty', size: 0, bytes: Uint8List(0))),
        throwsFormatException);
  });
  test('actual stream length is bounded and truncated downloads rejected',
      () async {
    await expectLater(
        readBoundedChatAttachment(
            Stream.fromIterable([
              [1, 2],
              [3, 4]
            ]),
            maxBytes: 3),
        throwsFormatException);
    await expectLater(
        readBoundedChatAttachment(Stream.value([1, 2]),
            maxBytes: 4, expectedBytes: 3),
        throwsFormatException);
    expect(
        await readBoundedChatAttachment(
            Stream.fromIterable([
              [1],
              [2]
            ]),
            maxBytes: 2,
            expectedBytes: 2),
        [1, 2]);
  });
  test('native picker path works without loading bytes in picker', () async {
    final directory =
        await Directory.systemTemp.createTemp('unispace-document-test-');
    try {
      final file =
          await File('${directory.path}/sample.pdf').writeAsBytes([1, 2, 3]);
      expect(
          await readChatDocument(
              PlatformFile(name: 'sample.pdf', size: 3, path: file.path)),
          [1, 2, 3]);
      await expectLater(
          readChatDocument(
              PlatformFile(name: 'changed.pdf', size: 4, path: file.path)),
          throwsFormatException);
    } finally {
      await directory.delete(recursive: true);
    }
  });
  test(
      'portable filename keeps Arabic and removes traversal/control characters',
      () {
    expect(chatDocumentName('ملخص الدرس.pdf'), 'ملخص الدرس.pdf');
    expect(chatDocumentName('../test.pdf'), 'test.pdf');
    expect(chatDocumentName(r'C:\folder\test.pdf'), 'test.pdf');
    expect(chatDocumentName('CON.txt'), '_CON.txt');
    expect(chatDocumentName('bad\u0000:name?.pdf'), 'bad__name_.pdf');
    expect(chatDocumentName('...'), 'document');
  });
  test('links allow web destinations and reject unsafe schemes/credentials',
      () {
    expect(normalizeChatLink(' example.com/path '), 'https://example.com/path');
    expect(normalizeChatLink('https://example.com?q=hello'),
        'https://example.com?q=hello');
    for (final link in [
      '',
      'javascript:alert(1)',
      'file:///a',
      'intent://example',
      'https://user:secret@example.com',
      'https://',
      'https://example.com/with space'
    ]) {
      expect(normalizeChatLink(link), isNull, reason: link);
    }
  });
  testWidgets(
      'link dialog validates before confirmation and preserves normalized result',
      (tester) async {
    String? result;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      result = await showChatLinkDialog(context);
                    },
                    child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'javascript:alert(1)');
    await tester.tap(find.byKey(const ValueKey('sendLink')));
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(find.text('Enter a valid HTTP or HTTPS link.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'example.com');
    await tester.tap(find.byKey(const ValueKey('sendLink')));
    await tester.pumpAndSettle();
    expect(result, 'https://example.com');
  });
  test('vote and attendance use callable path and active session checks',
      () async {
    String? uid = 'member';
    final calls = <String>[];
    final service = ChatMessageService.forTesting(
        currentUserId: () => uid,
        call: (name, data) async {
          calls.add(name);
          expect(data['chatId'], 'chat');
          expect(data['messageId'], 'message');
          return {'messageId': 'message'};
        });
    await service.voteChatPoll(
        chatId: 'chat', messageId: 'message', optionIndex: 1);
    await service.respondChatEvent(
        chatId: 'chat', messageId: 'message', attending: true);
    expect(calls, ['voteChatPoll', 'respondChatEvent']);
    uid = null;
    await expectLater(
        service.voteChatPoll(
            chatId: 'chat', messageId: 'message', optionIndex: 1),
        throwsA(anything));
    expect(calls.length, 2);
  });
}
