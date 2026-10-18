import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/services/feed_pagination_listener.dart';

Widget nestedFeed({required VoidCallback onLoadMore, int count = 100}) {
  return MaterialApp(
    home: Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => const [
          SliverAppBar(pinned: true, expandedHeight: 96),
        ],
        body: FeedPaginationListener(
          onLoadMore: onLoadMore,
          child: ListView.builder(
            key: const ValueKey('feed'),
            itemExtent: 100,
            itemCount: count,
            itemBuilder: (_, index) => Text('Post $index'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('uses inner feed extent rather than the collapsing header',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(nestedFeed(onLoadMore: () => calls++));
    await tester.pumpAndSettle();
    expect(calls, 0);

    final nested =
        tester.state<NestedScrollViewState>(find.byType(NestedScrollView));
    nested.outerController
        .jumpTo(nested.outerController.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(calls, 0);

    final inner = nested.innerController.position;
    nested.innerController.jumpTo(inner.maxScrollExtent - 999);
    await tester.pumpAndSettle();
    expect(calls, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('initial short feed requests more after layout', (tester) async {
    var calls = 0;
    await tester.pumpWidget(nestedFeed(onLoadMore: () => calls++, count: 1));
    await tester.pumpAndSettle();
    expect(calls, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(calls, 1); // No polling or self-scheduled retry loop.
    expect(tester.takeException(), isNull);
  });

  testWidgets('ignores horizontal page views', (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      home: FeedPaginationListener(
        onLoadMore: () => calls++,
        child: PageView(children: const [Text('One'), Text('Two')]),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(calls, 0);
  });

  testWidgets('coalesces notifications and does not consume them',
      (tester) async {
    var calls = 0;
    var bubbled = 0;
    late BuildContext source;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: NotificationListener<ScrollNotification>(
        onNotification: (_) {
          bubbled++;
          return false;
        },
        child: FeedPaginationListener(
          onLoadMore: () => calls++,
          child: Builder(builder: (context) {
            source = context;
            return const SizedBox();
          }),
        ),
      ),
    ));
    final metrics = FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 2000,
      pixels: 1000,
      viewportDimension: 500,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 1,
    );
    ScrollUpdateNotification(metrics: metrics, context: source)
        .dispatch(source);
    ScrollMetricsNotification(metrics: metrics, context: source)
        .dispatch(source);
    ScrollEndNotification(metrics: metrics, context: source).dispatch(source);
    expect(calls, 0);
    tester.binding.scheduleFrame();
    await tester.pump();
    expect(calls, 1);
    expect(bubbled, 2);
  });
}
