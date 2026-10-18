import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/shell/chat/chat_media_composer.dart';

void main() {
  late Directory directory;
  late File file;
  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('media-composer-');
    file = await File('${directory.path}/photo.png').writeAsBytes(base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+j8ioAAAAASUVORK5CYII='));
  });
  tearDownAll(() async {
    await directory.delete(recursive: true);
  });
  testWidgets('Send hands drafts to chat and closes preview before upload', (tester) async {
    List<ChatMediaDraft>? queued;
    var sends = 0;
    var enqueueCalls = 0;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(
      body: TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatMediaComposer(files: [file],
          onSend: (_, __) async { sends++; },
          onEnqueue: (drafts) { enqueueCalls++; queued = drafts; }))), child: const Text('Chat'))))));
    await tester.tap(find.text('Chat')); await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Keep caption');
    final sendButton = tester.widget<IconButton>(find.byKey(const ValueKey('media-send')));
    sendButton.onPressed!();
    sendButton.onPressed!();
    await tester.pumpAndSettle();
    expect(enqueueCalls, 1);
    expect(find.byType(ChatMediaComposer), findsNothing);
    expect(find.text('Chat'), findsOneWidget);
    expect(queued!.single.caption, 'Keep caption');
    expect(sends, 0);
    expect(file.existsSync(), true);
  });
  testWidgets(
      'selection only previews; explicit Send transfers caption on draft',
      (tester) async {
    var calls = 0;
    String? caption;
    await tester.pumpWidget(MaterialApp(
        home: ChatMediaComposer(
            files: [file],
            onSend: (d, p) async {
              calls++;
              caption = d.caption;
            })));
    await tester.pump();
    expect(calls, 0);
    await tester.enterText(find.byType(TextField), 'caption');
    await tester.tap(find.byKey(const ValueKey('media-send')));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(caption, 'caption');
    expect(file.existsSync(), true);
  });
  testWidgets('retry sends only failed item and preserves draft identity',
      (tester) async {
    final calls = <ChatMediaDraft>[];
    var fail = true;
    await tester.pumpWidget(MaterialApp(
        home: ChatMediaComposer(
            files: [file, file],
            onSend: (d, p) async {
              calls.add(d);
              if (calls.length == 2 && fail) {
                fail = false;
                throw StateError('offline');
              }
            })));
    await tester.tap(find.byKey(const ValueKey('media-send')));
    await tester.pumpAndSettle();
    expect(calls.length, 2);
    expect(calls[0].sent, true);
    expect(calls[1].sent, false);
    await tester.tap(find.byKey(const ValueKey('media-send')));
    await tester.pumpAndSettle();
    expect(calls.length, 3);
    expect(identical(calls[1], calls[2]), true);
  });
  testWidgets('changing quality after a failed send invalidates prepared bytes',
      (tester) async {
    var calls = 0;
    ChatMediaDraft? draft;
    await tester.pumpWidget(MaterialApp(
        home: ChatMediaComposer(
      files: [file],
      onSend: (value, progress) async {
        draft = value;
        calls++;
        if (calls == 1) {
          value.prepared = true;
          throw StateError('offline before upload');
        }
        expect(value.prepared, false);
        expect(value.hd, true);
      },
    )));
    await tester.tap(find.byKey(const ValueKey('media-send')));
    await tester.pumpAndSettle();
    expect(draft!.prepared, true);
    await tester.tap(find.text('SD'));
    await tester.pump();
    expect(draft!.prepared, false);
    await tester.tap(find.byKey(const ValueKey('media-send')));
    await tester.pumpAndSettle();
    expect(calls, 2);
  });
}
