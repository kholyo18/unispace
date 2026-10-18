import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/shell/chat/chat_message_action_frame.dart';

void main() {
  testWidgets('floating menu stays in viewport when selected bubble is at bottom', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ChatMessageActionFrame(
      anchor: const Rect.fromLTWH(220, 590, 120, 100), isMine: true,
      preview: const Text('Selected message'),
      reactions: const SizedBox(height: 48, child: Text('Reactions')),
      actions: Column(children: List.generate(5, (i) => ListTile(title: Text('Menu $i')))),
    ))));
    expect(tester.takeException(), isNull);
    expect(tester.getTopLeft(find.text('Reactions')).dy, greaterThanOrEqualTo(0));
    expect(tester.getBottomRight(find.text('Menu 4')).dy, lessThanOrEqualTo(640));
    expect(tester.getTopLeft(find.text('Selected message')).dy,
      greaterThan(tester.getTopLeft(find.text('Reactions')).dy));
  });

  for (final height in [380.0, 800.0]) {
    testWidgets('long message actions stay reachable at height $height',
        (tester) async {
      tester.view.physicalSize = Size(360, height);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var deleted = false;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: ChatMessageActionFrame(
        preview: Text(List.filled(200, 'Long message content').join('\n')),
        reactions: Row(
            children: List.generate(
                10,
                (_) => const SizedBox(
                    width: 48, height: 48, child: Icon(Icons.favorite)))),
        actions: Column(children: [
          for (var i = 0; i < 10; i++) ListTile(title: Text('Action $i')),
          TextButton(
              onPressed: () => deleted = true, child: const Text('Last action'))
        ]),
      ))));
      expect(tester.takeException(), isNull);
      expect(tester.getTopLeft(find.byIcon(Icons.favorite).first).dy,
          lessThan(tester.getTopLeft(find.byType(Text).first).dy));
      expect(tester.getTopLeft(find.byType(Text).first).dy,
          lessThan(tester.getTopLeft(find.text('Action 0')).dy));
      await tester.dragUntilVisible(find.text('Last action'),
          find.byType(SingleChildScrollView).last, const Offset(0, -120));
      await tester.tap(find.text('Last action'));
      expect(deleted, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
