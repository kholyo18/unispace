import 'dart:io';
import 'package:video_player/video_player.dart';

/// Bound native buffering so a stalled source cannot occupy the feed init gate
/// indefinitely. The owner still disposes the controller on failure.
Future<void> initializeVideoPlayback(VideoPlayerController controller) =>
    controller.initialize().timeout(const Duration(seconds: 20));

/// Visibility or access may change while the native play command is pending.
Future<void> startVisibleVideo(
    VideoPlayerController controller, bool Function() canPlay) async {
  if (!canPlay()) return;
  await controller.play();
  if (!canPlay()) await controller.pause();
}

/// Callers authorize remote sources before creation and recheck before playback.
/// Network playback buffers the media instead of waiting for a full download.
VideoPlayerController createVideoPlaybackController(String source) {
  final uri = Uri.tryParse(source);
  final options = VideoPlayerOptions(mixWithOthers: true);
  if (uri?.scheme == 'https' || uri?.scheme == 'http') {
    return VideoPlayerController.networkUrl(uri!, videoPlayerOptions: options);
  }
  return VideoPlayerController.file(File(source), videoPlayerOptions: options);
}

/// Report a late stream failure once; the owner exposes its authorized retry.
/// Disposing the controller also clears this listener.
void observeVideoPlaybackError(
    VideoPlayerController controller, void Function() onError) {
  var delivered = false;
  void listener() {
    if (delivered || !controller.value.hasError) return;
    delivered = true;
    controller.removeListener(listener);
    onError();
  }
  controller.addListener(listener);
  listener();
}
