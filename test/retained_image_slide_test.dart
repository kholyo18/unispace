import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/services/retained_image_slide.dart';

class _Revision extends ValueNotifier<int> {
  _Revision() : super(0);
  bool get observed => hasListeners;
}

class _SlideProbe extends StatefulWidget {
  const _SlideProbe(this.index, this.created, this.disposed, this.revision);

  final int index;
  final Map<int, int> created;
  final Set<int> disposed;
  final ValueNotifier<int> revision;

  @override
  State<_SlideProbe> createState() => _SlideProbeState();
}

class _SlideProbeState extends State<_SlideProbe> {
  late int _revision;

  @override
  void initState() {
    super.initState();
    widget.created
        .update(widget.index, (count) => count + 1, ifAbsent: () => 1);
    _revision = widget.revision.value;
    widget.revision.addListener(_invalidate);
  }

  void _invalidate() => setState(() => _revision = widget.revision.value);

  @override
  void dispose() {
    widget.revision.removeListener(_invalidate);
    widget.disposed.add(widget.index);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Text('slide ${widget.index}: $_revision');
}

void main() {
  testWidgets('revoking keepAlive evicts an offscreen slide', (tester) async {
    final pages = PageController();
    final revision = _Revision();
    final retained = ValueNotifier<bool>(true);
    final created = <int, int>{};
    final disposed = <int>{};
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: PageView.builder(
        controller: pages,
        itemCount: 4,
        itemBuilder: (_, index) => ValueListenableBuilder<bool>(
          valueListenable: retained,
          builder: (_, keep, __) => RetainedImageSlide(
            key: ValueKey(index),
            keepAlive: keep,
            child: _SlideProbe(index, created, disposed, revision),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    pages.jumpToPage(3);
    await tester.pumpAndSettle();
    expect(disposed.contains(0), isFalse);
    retained.value = false;
    await tester.pumpAndSettle();
    expect(disposed.contains(0), isTrue);
    pages.jumpToPage(0);
    await tester.pumpAndSettle();
    expect(created[0], 2);
    await tester.pumpWidget(const SizedBox.shrink());
    pages.dispose();
    revision.dispose();
    retained.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'visited slide survives paging, observes invalidation and disposes',
      (tester) async {
    final pages = PageController();
    final revision = _Revision();
    final created = <int, int>{};
    final disposed = <int>{};
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: PageView.builder(
        controller: pages,
        itemCount: 4,
        itemBuilder: (_, index) => RetainedImageSlide(
          key: ValueKey(index),
          child: _SlideProbe(index, created, disposed, revision),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('slide 0: 0'), findsOneWidget);
    pages.jumpToPage(3);
    await tester.pumpAndSettle();
    expect(find.text('slide 3: 0'), findsOneWidget);
    expect(disposed.contains(0), isFalse);

    // Revocation listeners must remain live even while a slide is offscreen.
    revision.value = 1;
    await tester.pump();
    pages.jumpToPage(0);
    await tester.pumpAndSettle();
    expect(created[0], 1);
    expect(find.text('slide 0: 1'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(disposed, containsAll(created.keys));
    expect(revision.observed, isFalse);
    pages.dispose();
    revision.dispose();
    expect(tester.takeException(), isNull);
  });
}
