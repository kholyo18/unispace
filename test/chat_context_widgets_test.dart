import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:UniSpace/features/shell/chat/chat_context_widgets.dart';
import 'package:UniSpace/features/shell/chat/chat_starred_messages_page.dart';

void main() {
  testWidgets('editing shows original message and cancels without overflow',
      (tester) async {
    bool cancelled = false;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SizedBox(
                width: 280,
                child: ChatEditingBanner(
                    text: 'Original message ' * 40,
                    onCancel: () => cancelled = true)))));
    expect(find.text('Editing message'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    expect(cancelled, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets('request badge shows exact pending count and hides zero',
      (tester) async {
    await tester
        .pumpWidget(const MaterialApp(home: ChatRequestBadge(count: 128)));
    expect(find.text('128'), findsOneWidget);
    await tester
        .pumpWidget(const MaterialApp(home: ChatRequestBadge(count: 0)));
    expect(find.byType(Badge), findsNothing);
  });
  for (final brightness in Brightness.values) {
    testWidgets('photo header has stable surface contrast in $brightness',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: const SizedBox(
              width: 300, height: 100, child: ChatPhotoHeaderBackdrop())));
      final box = tester.widget<ColoredBox>(find.descendant(
          of: find.byType(ChatPhotoHeaderBackdrop),
          matching: find.byType(ColoredBox)));
      expect(box.color.a, greaterThan(.9));
      expect(find.byType(BackdropFilter), findsOneWidget);
    });
  }
  test('stars exclude hidden, cleared, private one-time and another user stars',
      () {
    final date = DateTime(2026, 10, 17);
    final data = <String, dynamic>{
      'starredBy': {'me': true},
      'createdAt': Timestamp.fromDate(date),
      'type': 'text'
    };
    expect(isVisibleStarredMessage(data, 'me', null), isTrue);
    expect(isVisibleStarredMessage(data, 'other', null), isFalse);
    expect(
        isVisibleStarredMessage({
          ...data,
          'hiddenBy': {'me': true}
        }, 'me', null),
        isFalse);
    expect(isVisibleStarredMessage(data, 'me', date), isFalse);
    expect(
        isVisibleStarredMessage(
            data, 'me', date.subtract(const Duration(seconds: 1))),
        isTrue);
    expect(isVisibleStarredMessage({...data, 'type': 'viewOnce'}, 'me', null),
        isFalse);
    expect(isVisibleStarredMessage({...data, 'deleted': true}, 'me', null),
        isFalse);
  });
}
