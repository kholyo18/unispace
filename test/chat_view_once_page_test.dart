import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/shell/chat/chat_view_once_page.dart';

Widget harness(Future<Uint8List> Function() load,
        Future<void> Function(bool) protect) =>
    MaterialApp(
        home: Builder(
            builder: (c) => Scaffold(
                body: TextButton(
                    onPressed: () => Navigator.of(c).push(MaterialPageRoute(
                        builder: (_) => ChatViewOncePage(
                            chatId: 'chat',
                            messageId: 'message',
                            load: load,
                            protect: protect))),
                    child: const Text('open')))));
void main() {
  testWidgets('secure window precedes one read; closing clears protection',
      (tester) async {
    final events = <String>[];
    await tester.pumpWidget(harness(() async {
      events.add('load');
      return base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+j8ioAAAAASUVORK5CYII=');
    }, (v) async {
      events.add('secure:$v');
    }));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 400));
    expect(events.take(2), ['secure:true', 'load']);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(events.where((e) => e == 'load').length, 1);
    expect(events.last, 'secure:false');
  });
  testWidgets('protection failure does not consume the photo', (tester) async {
    var reads = 0;
    await tester.pumpWidget(harness(() async {
      reads++;
      return Uint8List(0);
    }, (v) async {
      throw StateError('unsupported');
    }));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(reads, 0);
    expect(find.byType(RawImage), findsNothing);
  });
  testWidgets('background closes private viewer with no retry', (tester) async {
    var reads = 0;
    final protected = <bool>[];
    await tester.pumpWidget(harness(() async {
      reads++;
      throw StateError('lost stream');
    }, (v) async {
      protected.add(v);
    }));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(reads, 1);
    expect(protected, [true, false]);
    expect(find.byType(ChatViewOncePage), findsNothing);
  });
}
