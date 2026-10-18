import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/shell/chat/chat_media_composer.dart';

void main() {
  late Directory directory;
  late File file;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('composer-save-');
    file = await File('${directory.path}/a.png').writeAsBytes(base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+j8ioAAAAASUVORK5CYII='));
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });
  testWidgets(
      'restored caption persists on back without send or deleting retained file',
      (tester) async {
    final draft = ChatMediaDraft(file)
      ..caption = 'Recovered caption'
      ..generated.add(file);
    List<ChatMediaDraft> saved = [];
    var sent = 0;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () =>
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ChatMediaComposer(
                                files: const [],
                                initialDrafts: [draft],
                                onSend: (_, __) async {
                                  sent++;
                                },
                                onDraftsChanged: (drafts) async {
                                  saved = drafts;
                                }))),
                    child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Recovered caption'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Changed caption');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(ChatMediaComposer), findsNothing);
    expect(saved.single.caption, 'Changed caption');
    expect(sent, 0);
    expect(file.existsSync(), true);
  });
  testWidgets('cleanup failure after enqueue cannot enqueue twice',
      (tester) async {
    var enqueued = 0, cleared = 0;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () =>
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ChatMediaComposer(
                                files: [file],
                                onSend: (_, __) async {},
                                onEnqueue: (_) async {
                                  enqueued++;
                                },
                                onDraftsChanged: (_) async {},
                                onDraftsSent: () async {
                                  if (++cleared == 1) throw StateError('disk');
                                }))),
                    child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('media-send')));
    await tester.pumpAndSettle();
    expect(enqueued, 1);
    await tester.tap(find.byKey(const ValueKey('media-send')));
    await tester.pumpAndSettle();
    expect(enqueued, 1);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(cleared, 2);
    expect(find.byType(ChatMediaComposer), findsNothing);
  });
}
