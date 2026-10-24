import '../../../services/protected_media_service.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../services/chat_audio_coordinator.dart';

class ChatAudioPlayer extends StatefulWidget {
  const ChatAudioPlayer({
    super.key,
    required this.url,
    required this.scope,
    required this.mine,
    required this.totalDuration,
    this.controllerFactory,
    this.foregroundColor,
  });

  final Color? foregroundColor;
  final String url;
  final String scope;
  final bool mine;
  final Duration totalDuration;
  @visibleForTesting
  final VideoPlayerController Function(String)? controllerFactory;

  @override
  State<ChatAudioPlayer> createState() => ChatAudioPlayerState();
}

class ChatAudioPlayerState extends State<ChatAudioPlayer>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => _controller?.value.isPlaying == true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) unawaited(_controller?.pause().catchError((Object _) {}));
  }

  VideoPlayerController? _controller;
  String? _playbackScope;
  bool get _samePlaybackSession => _playbackScope == null ||
      _playbackScope == ProtectedMediaService.instance.scope;
  bool _loading = false;
  bool _foreground = true;
  bool _failed = false;
  double _speed = 1.0;
  static const List<double> _speeds = [1.0, 1.5, 2.0];

  // عدد أعمدة الموجة الصوتية
  static const int _barCount = 32;
  late List<double> _waveform = _generateWaveform(widget.url, _barCount);
  Future<void>? _initializing;
  int _loadGeneration = 0;

  // توليد موجة ثابتة (نفس الشكل دايمًا لنفس الرابط) بدل تحليل الملف فعليًا
  static List<double> _generateWaveform(String seed, int count) {
    final rnd = Random(seed.hashCode);
    return List.generate(count, (i) {
      // نمزج قيمة عشوائية مع منحنى ناعم باش يبان طبيعي وماشي عشوائي بحت
      final base = 0.35 + rnd.nextDouble() * 0.65;
      final envelope = sin((i / count) * pi); // يخلي الأطراف أقصر من الوسط
      return (base * (0.5 + envelope * 0.5)).clamp(0.18, 1.0);
    });
  }

  Future<void> _ensureLoaded() {
    if (_controller != null) return Future<void>.value();
    return _initializing ??= _loadAudio(_loadGeneration);
  }

  Future<void> _loadAudio(int generation) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    VideoPlayerController? pending;
    try {
      final factory = widget.controllerFactory;
      final grant = factory == null
          ? await ProtectedMediaService.instance.resolve(widget.url) : null;
      if (!(mounted && generation == _loadGeneration)) return;
      _playbackScope = grant?.scope;
      pending = factory != null ? factory(widget.url)
          : VideoPlayerController.networkUrl(Uri.parse(grant!.url));
      await pending.initialize().timeout(const Duration(seconds: 20));
      if (grant != null && grant.scope != ProtectedMediaService.instance.scope) {
        throw StateError('Media session changed');
      }
      if (!mounted || generation != _loadGeneration || !_samePlaybackSession) return;
      await pending.setPlaybackSpeed(_speed);
      if (!mounted || generation != _loadGeneration || !_samePlaybackSession) return;
      pending.addListener(_onTick);
      _controller = pending;
      pending = null;
    } catch (error) {
      if (mounted && generation == _loadGeneration)
        setState(() => _failed = true);
    } finally {
      if (pending != null) await pending.dispose();
      if (mounted && generation == _loadGeneration) {
        _initializing = null;
        setState(() => _loading = false);
      }
    }
  }

  @override
  void didUpdateWidget(covariant ChatAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url == widget.url && oldWidget.scope == widget.scope) return;
    chatAudioCoordinator.release(this);
    _loadGeneration++;
    _initializing = null;
    _loading = false;
    _controller?.removeListener(_onTick);
    unawaited(_controller?.dispose());
    _controller = null;
    _waveform = _generateWaveform(widget.url, _barCount);
  }

  void _onTick() {
    if (mounted) {
      updateKeepAlive();
      setState(() {});
    }
  }

  Future<void> _togglePlay() async {
    if (_loading || !_foreground) return;
    final generation = _loadGeneration;
    await _ensureLoaded();
    if (!mounted || generation != _loadGeneration || !_samePlaybackSession) return;
    final c = _controller;
    if (c == null) return;
    try {
      if (c.value.isPlaying) {
        await c.pause();
      } else {
        if (c.value.position >= c.value.duration) {
          await c.seekTo(Duration.zero);
        }
        if (!mounted || generation != _loadGeneration || !_samePlaybackSession) return;
        await chatAudioCoordinator.play(this,
            start: c.play,
            pause: c.pause,
            valid: () =>
                mounted && _foreground && generation == _loadGeneration && _samePlaybackSession);
      }
    } catch (error) {
      if (mounted && generation == _loadGeneration)
        setState(() => _failed = true);
    }
    if (mounted && generation == _loadGeneration) setState(() {});
  }

  Future<void> _seekToRatio(double ratio) async {
    final generation = _loadGeneration;
    await _ensureLoaded();
    if (!mounted || generation != _loadGeneration || !_samePlaybackSession) return;
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final duration = c.value.duration;
    if (duration.inMilliseconds <= 0) return;
    try {
      await c.seekTo(duration * ratio.clamp(0.0, 1.0));
    } catch (error) {
      debugPrint('audio seek failed: $error');
    }
    if (mounted && generation == _loadGeneration) setState(() {});
  }

  Future<void> _cycleSpeed() async {
    final currentIndex = _speeds.indexOf(_speed);
    final next = _speeds[(currentIndex + 1) % _speeds.length];

    final c = _controller;
    if (c != null && c.value.isInitialized) {
      try {
        await c.setPlaybackSpeed(next);
      } catch (error) {
        if (mounted) setState(() => _failed = true);
        return;
      }
    }
    if (mounted) setState(() => _speed = next);
  }

  @override
  void dispose() {
    _loadGeneration++;
    _controller?.removeListener(_onTick);
    chatAudioCoordinator.release(this);
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  String _label(BuildContext c, String ar, String fr, String en) =>
      switch (Localizations.localeOf(c).languageCode) {
        'ar' => ar,
        'fr' => fr,
        _ => en
      };
  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final c = _controller;
    final isPlaying = c?.value.isPlaying ?? false;
    final position = c?.value.position ?? Duration.zero;
    final duration = (c?.value.duration.inMilliseconds ?? 0) > 0
        ? c!.value.duration
        : widget.totalDuration;
    final ratio = duration.inMilliseconds == 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

    // ألوان تتكيف مع فقاعة "أنا" (ملوّنة) أو فقاعة الطرف الآخر
    final Color fg = widget.foregroundColor ??
        (widget.mine ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface);
    final Color playedColor = fg;
    final Color unplayedColor = fg.withValues(alpha: widget.mine ? 0.35 : 0.22);
    final Color buttonBg = widget.mine
        ? fg.withValues(alpha: 0.14)
        : theme.colorScheme.primary.withValues(alpha: 0.12);

    final displayedPosition =
        duration.inMilliseconds > 0 ? position : Duration.zero;
    final timeLabel =
        isPlaying || position.inMilliseconds > 0 ? displayedPosition : duration;

    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      width: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ===== زر التشغيل الدائري =====
          _AccessibleAudioTap(
            label: _label(
                context,
                _failed
                    ? 'إعادة محاولة الصوت'
                    : isPlaying
                        ? 'إيقاف الصوت مؤقتًا'
                        : 'تشغيل الصوت',
                _failed
                    ? 'Réessayer l’audio'
                    : isPlaying
                        ? 'Mettre en pause'
                        : 'Lire l’audio',
                _failed
                    ? 'Retry audio'
                    : isPlaying
                        ? 'Pause audio'
                        : 'Play audio'),
            onTap: _togglePlay,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: buttonBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: _loading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: MediaQuery.disableAnimationsOf(context)
                            ? Icon(Icons.hourglass_empty, color: fg, size: 18)
                            : CircularProgressIndicator(
                                strokeWidth: 2,
                                color: fg,
                              ),
                      )
                    : Icon(
                        _failed
                            ? Icons.refresh_rounded
                            : isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                        color: fg,
                        size: 22,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ===== الموجة الصوتية + الوقت =====
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                    padding: EdgeInsetsGeometry.only(top: 0),
                    child: SizedBox(
                      height: 48,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Semantics(
                              label: _label(context, 'موضع الصوت',
                                  'Position audio', 'Audio position'),
                              slider: true,
                              value: '${_fmt(position)} / ${_fmt(duration)}',
                              increasedValue:
                                  '${_fmt(Duration(milliseconds: (duration.inMilliseconds * (ratio + 0.1).clamp(0.0, 1.0)).round()))} / ${_fmt(duration)}',
                              decreasedValue:
                                  '${_fmt(Duration(milliseconds: (duration.inMilliseconds * (ratio - 0.1).clamp(0.0, 1.0)).round()))} / ${_fmt(duration)}',
                              onIncrease: () => _seekToRatio(ratio + 0.1),
                              onDecrease: () => _seekToRatio(ratio - 0.1),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTapDown: (details) {
                                  final r = (details.localPosition.dx /
                                          constraints.maxWidth)
                                      .clamp(0.0, 1.0);
                                  _seekToRatio(r);
                                },
                                onHorizontalDragUpdate: (details) {
                                  final r = (details.localPosition.dx /
                                          constraints.maxWidth)
                                      .clamp(0.0, 1.0);
                                  _seekToRatio(r);
                                },
                                child: CustomPaint(
                                  size: Size(constraints.maxWidth, 26),
                                  painter: _WaveformPainter(
                                    bars: _waveform,
                                    progress: ratio,
                                    playedColor: playedColor,
                                    unplayedColor: unplayedColor,
                                  ),
                                ),
                              ));
                        },
                      ),
                    )),
                const SizedBox(height: 0),
                Text(
                  _fmt(timeLabel),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: fg.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // ===== زر تغيير السرعة =====
          _AccessibleAudioTap(
            label:
                '${_label(context, "تغيير سرعة التشغيل", "Modifier la vitesse", "Change playback speed")}: ${_speed}x',
            onTap: _cycleSpeed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: buttonBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_speed == _speed.roundToDouble() ? _speed.toInt() : _speed}x',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// رسّام الموجة الصوتية: أعمدة بارتفاعات متفاوتة، تتلون حسب التقدم
class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.bars,
    required this.progress,
    required this.playedColor,
    required this.unplayedColor,
  });

  final List<double> bars;
  final double progress; // 0..1
  final Color playedColor;
  final Color unplayedColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;

    final barCount = bars.length;
    const gapRatio = 0.35; // نسبة الفراغ بين الأعمدة
    final totalWidth = size.width;
    final barWidth = totalWidth / (barCount + (barCount - 1) * gapRatio);
    final gap = barWidth * gapRatio;

    final playedBars = (progress * barCount).floor();
    final partial = (progress * barCount) - playedBars;

    for (var i = 0; i < barCount; i++) {
      final x = i * (barWidth + gap);
      final barHeight = bars[i] * size.height;
      final top = (size.height - barHeight) / 2;

      Color color;
      if (i < playedBars) {
        color = playedColor;
      } else if (i == playedBars && partial > 0) {
        color =
            Color.lerp(unplayedColor, playedColor, partial) ?? unplayedColor;
      } else {
        color = unplayedColor;
      }

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, barHeight),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.playedColor != playedColor ||
        oldDelegate.unplayedColor != unplayedColor;
  }
}

class _AccessibleAudioTap extends StatelessWidget {
  const _AccessibleAudioTap(
      {required this.label, required this.onTap, required this.child});
  final String label;
  final VoidCallback onTap;
  final Widget child;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        onTap: onTap,
        child: ExcludeSemantics(
            child: GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                    child: child))),
      );
}
