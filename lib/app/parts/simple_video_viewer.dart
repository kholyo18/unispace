part of '../../main.dart';

class SimpleFullscreenVideoViewer extends StatefulWidget {
  final VideoPlayerController controller;

  const SimpleFullscreenVideoViewer({
    super.key,
    required this.controller,
  });

  @override
  State<SimpleFullscreenVideoViewer> createState() =>
      _SimpleFullscreenVideoViewerState();
}

class _SimpleFullscreenVideoViewerState
    extends State<SimpleFullscreenVideoViewer> {
  bool _controlsVisible = true;
  double _dragOffset = 0;
  final TransformationController _zoomController = TransformationController();
  bool _muted = false;

  Offset? _dragStart;
  bool _isDragGesture = false;
  int _activePointers = 0;
  bool _isPinching = false;
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    final c = widget.controller;
    c.setLooping(false);
    c.addListener(_tick);

    // نحافظ على حالة الصوت الحالية أو نبدأ غير مكتوم
    _muted = c.value.volume == 0;

    _zoomController.addListener(() {
      setState(() => _currentScale = _zoomController.value.getMaxScaleOnAxis());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await c.seekTo(Duration.zero);
      if (!mounted) return;
      await c.play();
      if (mounted) setState(() {});
    });
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  void _resetZoom() {
    _zoomController.value = Matrix4.identity();
    if (mounted) setState(() => _currentScale = 1.0);
  }

  bool get _isZoomed => (_currentScale - 1.0).abs() > 0.05;

  bool get _isEnded {
    final c = widget.controller;
    return c.value.isInitialized &&
        videoPlaybackEnded(c.value.position, c.value.duration);
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
  }

  void _togglePlay() {
    final c = widget.controller;
    if (_isEnded) {
      c.seekTo(Duration.zero);
      c.play();
    } else {
      c.value.isPlaying ? c.pause() : c.play();
    }
    setState(() {});
  }

  void _toggleMute() {
    final c = widget.controller;
    setState(() {
      _muted = !_muted;
      c.setVolume(_muted ? 0 : 1);
    });
  }

  void _onPointerDown(PointerDownEvent event) {
    _activePointers++;
    if (_activePointers > 1) {
      _dragStart = null;
      setState(() => _isPinching = true);
      if (_isDragGesture) {
        _isDragGesture = false;
        setState(() => _dragOffset = 0);
      }
      return;
    }
    _dragStart = event.position;
    _isDragGesture = false;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_activePointers != 1 || _dragStart == null || _isZoomed) return;

    final delta = event.position - _dragStart!;

    if (!_isDragGesture) {
      if (delta.dy.abs() > 8 && delta.dy.abs() > delta.dx.abs() * 1.5) {
        _isDragGesture = true;
      } else if (delta.dx.abs() > 8) {
        _dragStart = null;
        return;
      }
    }

    if (_isDragGesture) {
      setState(() => _dragOffset = delta.dy);
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _activePointers = (_activePointers - 1).clamp(0, 10);

    if (_activePointers < 2 && _isPinching) {
      setState(() => _isPinching = false);
      _resetZoom();
    }

    if (_isDragGesture && _activePointers == 0) {
      if (_dragOffset.abs() > 120) {
        Navigator.of(context).pop();
      } else {
        setState(() => _dragOffset = 0);
      }
      _isDragGesture = false;
    }
    _dragStart = null;
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _activePointers = (_activePointers - 1).clamp(0, 10);
    if (_activePointers < 2 && _isPinching) {
      setState(() => _isPinching = false);
      _resetZoom();
    }
    _dragStart = null;
    _isDragGesture = false;
    if (_dragOffset != 0) setState(() => _dragOffset = 0);
  }

  Future<void> _saveVideo() async {
    try {
      // منطق الحفظ عندك
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(mainText(context, "تم الحفظ للمعرض"))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(mainText(context, "تعذر حفظ الفيديو"))),
      );
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_tick);
    _zoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final ratio = c.value.isInitialized && c.value.aspectRatio > 0
        ? c.value.aspectRatio
        : 16 / 9;
    final bgOpacity = (1 - (_dragOffset.abs() / 350)).clamp(0.35, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Listener(
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: GestureDetector(
          onTap: _toggleControls,
          behavior: HitTestBehavior.translucent,
          child: Container(
            color: Colors.black.withValues(alpha: bgOpacity),
            child: Stack(
              children: [
                // ===== الفيديو =====
                Transform.translate(
                  offset: Offset(0, _dragOffset),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: ratio,
                      child: InteractiveViewer(
                        transformationController: _zoomController,
                        maxScale: 8.0,
                        minScale: 1.0,
                        panEnabled: false,
                        scaleEnabled: true,
                        boundaryMargin: const EdgeInsets.all(double.infinity),
                        onInteractionEnd: (_) {
                          if (_activePointers < 2) {
                            _resetZoom();
                          }
                        },
                        child: VideoPlayer(c),
                      ),
                    ),
                  ),
                ),

                // ===== الشريط العلوي (إغلاق + تحميل) =====
                AnimatedOpacity(
                  opacity: _controlsVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_controlsVisible,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.55),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Row(
                            children: [
                              _ViewerIconButton(
                                icon: Icons.close_rounded,
                                onTap: () => Navigator.of(context).pop(),
                              ),
                              const Spacer(),
                              _ViewerIconButton(
                                icon: Icons.download_rounded,
                                onTap: _saveVideo,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ===== الشريط السفلي =====
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedOpacity(
                    opacity: _controlsVisible ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: !_controlsVisible,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.90),
                              Colors.black.withValues(alpha: 0.45),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.55, 1.0],
                          ),
                        ),
                        child: SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 24, 12, 10),
                            child: _SimpleVideoControls(
                              controller: widget.controller,
                              muted: _muted,
                              onToggleMute: _toggleMute,
                              onTogglePlay: _togglePlay,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
