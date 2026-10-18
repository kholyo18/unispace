import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:UniSpace/services/feed_item_retention.dart';

class Probe extends StatefulWidget {
  const Probe(this.id, this.created, this.disposed, {super.key});
  final int id;
  final Map<int, int> created;
  final Set<int> disposed;
  @override
  State<Probe> createState() => _ProbeState();
}

class _ProbeState extends State<Probe> {
  @override
  void initState() {
    super.initState();
    widget.created.update(widget.id, (value) => value + 1, ifAbsent: () => 1);
  }

  @override
  void dispose() {
    widget.disposed.add(widget.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 200, child: Text('row ${widget.id}'));
}

void main() {
  setUp(() =>
      VisibilityDetectorController.instance.updateInterval = Duration.zero);
  tearDown(() => VisibilityDetectorController.instance.updateInterval =
      const Duration(milliseconds: 500));

  test('recent visible rows are bounded and revisiting updates eviction order',
      () {
    final retention = FeedItemRetentionController();
    for (var i = 0; i < 6; i++) {
      retention.markVisible('$i');
    }
    retention.markVisible('0');
    retention.markVisible('6');
    expect(retention.contains('0'), isTrue);
    expect(retention.contains('1'), isFalse);
    expect([
      for (var i = 0; i < 7; i++)
        if (retention.contains('$i')) i
    ], hasLength(6));
    retention.clear();
    expect(retention.contains('0'), isFalse);
    retention.dispose();
    expect(() => retention.markVisible('new'), returnsNormally);
    expect(() => retention.clear(), returnsNormally);
  });

  testWidgets(
      'scroll return reuses retained state and eviction releases old rows',
      (tester) async {
    final retention = FeedItemRetentionController(capacity: 2);
    final scroll = ScrollController();
    final created = <int, int>{};
    final disposed = <int>{};
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            height: 180,
            child: ListView.builder(
              controller: scroll,
              cacheExtent: 0,
              itemCount: 12,
              itemExtent: 200,
              itemBuilder: (_, index) => RetainedFeedItem(
                  key: ValueKey(index),
                  id: '$index',
                  controller: retention,
                  child: Probe(index, created, disposed)),
            ),
          )),
    ));
    await tester.pumpAndSettle();
    expect(retention.contains('0'), isTrue);
    scroll.jumpTo(200);
    await tester.pumpAndSettle();
    expect(disposed.contains(0), isFalse);
    scroll.jumpTo(0);
    await tester.pumpAndSettle();
    expect(created[0], 1);
    scroll.jumpTo(400);
    await tester.pumpAndSettle();
    expect(disposed.contains(1), isTrue);
    expect(disposed.contains(0), isFalse);
    scroll.jumpTo(600);
    await tester.pumpAndSettle();
    expect(disposed.contains(0), isTrue);
    scroll.jumpTo(0);
    await tester.pumpAndSettle();
    expect(created[0], 2);
    retention.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    scroll.dispose();
  });
}
