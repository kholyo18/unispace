part of '../../main.dart';

class _SimpleVideoControls extends StatelessWidget {
  const _SimpleVideoControls({
    required this.controller,
    required this.muted,
    required this.onToggleMute,
    required this.onTogglePlay,
  });

  final VideoPlayerController controller;
  final bool muted;
  final VoidCallback onToggleMute;
  final VoidCallback onTogglePlay;

  

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final duration = value.duration;
        final position = value.position;
        final ratio = videoProgressRatio(position, duration);

        final isEnded = videoPlaybackEnded(position, duration);

        return Row(
          children: [
            // زر تشغيل / إيقاف
            GestureDetector(
              onTap: onTogglePlay,
              child: Container(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  isEnded
                      ? Icons.replay_rounded
                      : (value.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded),
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),

            const SizedBox(width: 6),

            // الوقت الحالي
            Text(
              compactVideoDuration(position),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(width: 8),

            // شريط التقدم
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  value: ratio,
                  onChanged: (v) {
                    final target = duration * v;
                    controller.seekTo(target);
                  },
                ),
              ),
            ),

            const SizedBox(width: 8),

            // الوقت الكلي
            Text(
              compactVideoDuration(duration),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(width: 4),

            // زر كتم الصوت
            GestureDetector(
              onTap: onToggleMute,
              child: Container(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
//==============================================================
class _InlineVideoControls extends StatefulWidget {
  const _InlineVideoControls({required this.controller});

  final VideoPlayerController controller;

  @override
  State<_InlineVideoControls> createState() => _InlineVideoControlsState();
}

class _InlineVideoControlsState extends State<_InlineVideoControls> {
  bool _muted = false;
  double? _dragValue;

  void _togglePlay() {
    final c = widget.controller;
    setState(() {
      c.value.isPlaying ? c.pause() : c.play();
    });
  }

  void _toggleMute() {
    final c = widget.controller;
    setState(() {
      _muted = !_muted;
      c.setVolume(_muted ? 0 : 1);
    });
  }

  

  void _seekToRatio(double ratio, double width) {
    final c = widget.controller;
    final duration = c.value.duration;
    c.seekTo(duration * ratio.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: c,
      builder: (context, value, _) {
        final duration = value.duration;
        final position = value.position;
        final ratio = videoProgressRatio(position, duration);
        final displayRatio = _dragValue ?? ratio;

        return Container(
          // FIX: كانت 44 — كبرناها باش توفّر حيز كافي للعناصر الجديدة
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          color: Colors.transparent,
          child: Row(
            children: [
              // زر تشغيل/إيقاف — FIX: كبرت الأيقونة والمنطقة القابلة للمس
              InkWell(
                onTap: _togglePlay,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.all(9),
                  child: Icon(
                    value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 30, // كانت 22
                  ),
                ),
              ),
              const SizedBox(width: 2), // كانت 4
              // شريط التقدم
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: (_) => setState(() => _dragValue = displayRatio),
                      onHorizontalDragUpdate: (details) {
                        final box = context.findRenderObject() as RenderBox;
                        final local = box.globalToLocal(details.globalPosition);
                        setState(() => _dragValue = (local.dx / constraints.maxWidth).clamp(0.0, 1.0));
                      },
                      onHorizontalDragEnd: (_) {
                        if (_dragValue != null) _seekToRatio(_dragValue!, constraints.maxWidth);
                        setState(() => _dragValue = null);
                      },
                      onTapUp: (details) {
                        final box = context.findRenderObject() as RenderBox;
                        final local = box.globalToLocal(details.globalPosition);
                        _seekToRatio(
                            (local.dx / constraints.maxWidth).clamp(0.0, 1.0), constraints.maxWidth);
                      },
                      child: SizedBox(
                        // FIX: كبرنا منطقة اللمس والكرة
                        height: 30, // كانت 20
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            Container(
                              height: 5, // كانت 3
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.28),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: displayRatio,
                              child: Container(
                                height: 5, // كانت 3
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                            Positioned(
                              left: (constraints.maxWidth - 18) * displayRatio, // كانت 12
                              child: Container(
                                width: 18, // كانت 12
                                height: 18, // كانت 12
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12), // كانت 8
              // الوقت
              Text(
                compactVideoDuration(position),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16, // كانت 12
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8), // كانت 6
              // زر كتم الصوت
              InkWell(
                onTap: _toggleMute,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.all(9),
                  child: Icon(
                    _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    color: Colors.white,
                    size: 28, // كانت 19
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}









//=================================================================

