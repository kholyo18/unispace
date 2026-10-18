import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:UniSpace/services/video_playback_source.dart';

class _PendingVideo extends VideoPlayerController {
  _PendingVideo() : super.networkUrl(Uri.parse('https://example.invalid/video'));
  final ready = Completer<void>();
  final playing = Completer<void>();
  int playCalls = 0, pauseCalls = 0;
  @override
  Future<void> initialize() => ready.future;
  @override
  Future<void> play() { playCalls++; return playing.future; }
  @override
  Future<void> pause() async { pauseCalls++; }
}

void main() {
  testWidgets('native initialization has a bounded wait', (tester) async {
    final stalled = _PendingVideo();
    final result = expectLater(initializeVideoPlayback(stalled), throwsA(isA<TimeoutException>()));
    await tester.pump(const Duration(seconds: 20));
    await result;
    // A late native completion does not resurrect the failed initialization.
    stalled.ready.complete();
    await tester.pump();
    final healthy = _PendingVideo();
    final next = initializeVideoPlayback(healthy);
    healthy.ready.complete();
    await next;
  });
  test('visibility loss while native play is pending pauses playback', () async {
    final controller = _PendingVideo();
    var visible = true;
    final start = startVisibleVideo(controller, () => visible);
    expect(controller.playCalls, 1);
    visible = false;
    controller.playing.complete();
    await start;
    expect(controller.pauseCalls, 1);
  });
  test('hidden or invalidated videos do not start', () async {
    final controller = _PendingVideo();
    await startVisibleVideo(controller, () => false);
    expect(controller.playCalls, 0);
  });
  test('late playback error is delivered once after healthy updates', () {
    final controller = createVideoPlaybackController('https://example.invalid/video.mp4');
    var errors = 0;
    observeVideoPlaybackError(controller, () => errors++);
    controller.value = const VideoPlayerValue(duration: Duration(seconds: 10), isInitialized: true);
    expect(errors, 0);
    controller.value = const VideoPlayerValue.erroneous('expired signed URL');
    expect(errors, 1);
    controller.value = const VideoPlayerValue.erroneous('another network error');
    expect(errors, 1);
  });
  test('an error already present when attached is delivered once', () {
    final controller = createVideoPlaybackController('https://example.invalid/video.mp4');
    controller.value = const VideoPlayerValue.erroneous('network failure');
    var errors = 0;
    observeVideoPlaybackError(controller, () => errors++);
    expect(errors, 1);
    controller.value = const VideoPlayerValue.erroneous('repeated failure');
    expect(errors, 1);
  });
  test('authorized URL is streamed with signature and generation intact', () {
    const url = 'https://storage.googleapis.com/bucket/video.mp4?generation=42&X-Goog-Signature=test';
    final controller = createVideoPlaybackController(url);
    expect(controller.dataSourceType, DataSourceType.network);
    expect(controller.dataSource, url);
    expect(controller.value.isPlaying, false);
    expect(controller.videoPlayerOptions?.mixWithOthers, true);
  });
  test('local video playback remains file based', () {
    final controller = createVideoPlaybackController('local-video.mp4');
    expect(controller.dataSourceType, DataSourceType.file);
    expect(controller.value.isPlaying, false);
  });
}
