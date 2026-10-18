/// Compact controls intentionally retain their existing minute-wrap format.
String compactVideoDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

double videoProgressRatio(Duration position, Duration duration) {
  if (duration.inMilliseconds == 0) return 0;
  return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
}

bool videoPlaybackEnded(Duration position, Duration duration) =>
    duration > Duration.zero &&
    position >= duration - const Duration(milliseconds: 300);
