import 'package:UniSpace/features/shell/chat/chat_search_scroll_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:UniSpace/features/shell/chat/chat_message_search.dart';

void main() {
  testWidgets('jump finds offscreen message in reversed variable-height history without filtering', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = ChatSearchScrollController();
    final search = ChatMessageSearch()..update('needle', [
      for (var i=0;i<160;i++) ChatSearchEntry(id: '$i', text: i == 125 ? 'needle' : 'context $i')]);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ListView.builder(
      reverse: true, controller: controller, itemCount: 160,
      itemBuilder: (_, i) => AutoScrollTag(key: ValueKey(i), controller: controller, index: i,
        child: ChatSearchHighlight(selected: search.selectedId == '$i', child: SizedBox(
          height: 60 + (i % 5) * 27, child: Text(i == 125 ? 'needle' : 'context $i')))),
    ))));
    var completed = false;
    final scroll = controller.reveal(125)
      .then((_) => completed = true);
    for(var i=0;i<120 && !completed;i++) { await tester.pump(const Duration(milliseconds: 50)); }
    expect(completed, isTrue);
    await scroll;
    expect(tester.getTopLeft(find.text('needle')).dy, inInclusiveRange(0,640));
    expect(find.text('context 124'), findsOneWidget);
    expect(find.text('context 126'), findsOneWidget);
    expect(tester.widget<ListView>(find.byType(ListView)).childrenDelegate.estimatedChildCount,160);
    expect(tester.takeException(), isNull);
    var stopped = false;
    final cancelled = controller.reveal(0).then((_) => stopped = true);
    await tester.pump(const Duration(milliseconds: 20));
    controller.cancelSearchJump();
    final stoppedAt = controller.offset;
    for(var i=0;i<30;i++) { await tester.pump(const Duration(milliseconds: 30)); }
    expect(stopped, isTrue);
    await cancelled;
    expect(controller.offset, closeTo(stoppedAt, .01));
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
