import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:UniSpace/features/shell/chat/chat_media_viewers.dart';

class TestVideo extends VideoPlayerController {
  TestVideo({this.fail = false, this.pending})
      : super.networkUrl(Uri.parse('https://example.invalid/video'));
  final bool fail;
  final Completer<void>? pending;
  int disposals = 0, plays = 0, pauses = 0;
  @override
  Future<void> initialize() async {
    if (pending != null) await pending!.future;
    if (fail) throw StateError('offline');
  }

  @override
  // Native player cleanup is intentionally replaced by the lifecycle spy.
  // ignore: must_call_super
  Future<void> dispose() async {
    disposals++;
  }

  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> play() async {
    plays++;
  }

  @override
  Future<void> pause() async {
    pauses++;
  }
}

void main() {
  testWidgets('video rows never download the video', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body:
                ChatVideoThumbnail(url: 'https://example.invalid/large.mp4'))));
    expect(find.byType(VideoPlayer), findsNothing);
    expect(find.byType(Image), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.play_circle_fill_rounded), findsOneWidget);
  });
  testWidgets('failure releases player and retry makes a new attempt',
      (tester) async {
    final created = <TestVideo>[];
    await tester.pumpWidget(MaterialApp(
        home: ChatVideoViewer(
            url: 'https://example.invalid/video',
            controllerFactory: (_) {
              final c = TestVideo(fail: true);
              created.add(c);
              return c;
            })));
    await tester.pumpAndSettle();
    expect(find.text('Could not load the video'), findsOneWidget);
    expect(created.single.disposals, 1);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(created.length, 2);
    expect(created.last.disposals, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('closing while loading prevents late autoplay', (tester) async {
    final ready = Completer<void>();
    final c = TestVideo(pending: ready);
    await tester.pumpWidget(MaterialApp(
        home: ChatVideoViewer(
            url: 'https://example.invalid/video',
            controllerFactory: (_) => c)));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(c.disposals, 1);
    ready.complete();
    await tester.pump();
    expect(c.plays, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets('stalled loading offers retry after timeout', (tester) async {
    final ready = Completer<void>();
    final c = TestVideo(pending: ready);
    await tester.pumpWidget(MaterialApp(
        home: ChatVideoViewer(
            url: 'https://example.invalid/video',
            controllerFactory: (_) => c)));
    await tester.pump(const Duration(seconds: 21));
    expect(find.text('Retry'), findsOneWidget);
    expect(c.disposals, 1);
    ready.complete();
    await tester.pump();
    expect(c.plays, 0);
  });
  testWidgets('backgrounding during initialization prevents autoplay',
      (tester) async {
    final ready = Completer<void>();
    final c = TestVideo(pending: ready);
    await tester.pumpWidget(MaterialApp(
        home: ChatVideoViewer(
            url: 'https://example.invalid/video',
            controllerFactory: (_) => c)));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    ready.complete();
    await tester.pump();
    expect(c.plays, 0);
    expect(c.pauses, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });
  testWidgets('old source completion cannot replace the newer loading state',
      (tester) async {
    final firstReady = Completer<void>();
    final secondReady = Completer<void>();
    final first = TestVideo(fail: true, pending: firstReady);
    final second = TestVideo(pending: secondReady);
    VideoPlayerController factory(String url) =>
        url.endsWith('first') ? first : second;
    await tester.pumpWidget(MaterialApp(
        home: ChatVideoViewer(
            url: 'https://example.invalid/first', controllerFactory: factory)));
    await tester.pumpWidget(MaterialApp(
        home: ChatVideoViewer(
            url: 'https://example.invalid/second',
            controllerFactory: factory)));
    expect(first.disposals, 1);
    firstReady.complete();
    await tester.pump();
    expect(find.text('Retry'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    secondReady.complete();
    await tester.pump();
    expect(second.plays, 0);
  });
}
