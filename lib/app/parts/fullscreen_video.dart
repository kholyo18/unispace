part of '../../main.dart';

class FullscreenVideoViewer extends StatefulWidget {
  final VideoPlayerController controller;
  final String? authorName;
  final String? authorPhotoUrl;
  final String? postTitle;
  final String? postBody; // جديد
  final Widget? menuButton; // زر ⋮ جاهز
  final Widget Function(BuildContext context)? onMenuBuilder;
// أضف للمعاملات:
  final int? votes;
  final bool? isLiked;
  final bool? isDisliked;
  final int? commentsCount;
  final int? tagsCount;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final Future<int?> Function()? onComment;
  final VoidCallback? onTags;

  const FullscreenVideoViewer({
    super.key,
    required this.controller,
    this.authorName,
    this.authorPhotoUrl,
    this.postTitle,
    this.postBody,
    this.menuButton,
    this.onMenuBuilder,
    this.votes,
    this.isLiked = false,
    this.isDisliked = false,
    this.commentsCount,
    this.tagsCount,
    this.onLike,
    this.onDislike,
    this.onComment,
    this.onTags,
  });

  @override
  State<FullscreenVideoViewer> createState() => _FullscreenVideoViewerState();
}

class _FullscreenVideoViewerState extends State<FullscreenVideoViewer> {
  bool _controlsVisible = true;
  Timer? _hideTimer;
  double _dragOffset = 0;
  final TransformationController _zoomController = TransformationController();
  String _formatVotes(int votes) {
    if (votes >= 1000000) return '${(votes / 1000000).toStringAsFixed(1)}M';
    if (votes >= 1000) return '${(votes / 1000).toStringAsFixed(1)}k';
    return votes.toString();
  }
  Offset? _dragStart;
  bool _isDragGesture = false;
  int _activePointers = 0;
  bool _isPinching = false; // NE
  double _currentScale = 1.0; // ليس final
  bool _pointerInBottomPanel = false;
  late int _votes;
  late bool _isLiked;
  late bool _isDisliked;
  late int _commentsCount;

  @override
  void initState() {
    super.initState();
    _votes = widget.votes ?? 0;
    _isLiked = widget.isLiked ?? false;      // ← أضف ?? false
    _isDisliked = widget.isDisliked ?? false; // ← أضف ?? false
    _commentsCount = widget.commentsCount ?? 0;
    final c = widget.controller;
    c.setLooping(false);
    c.addListener(_tick);
    _zoomController.addListener(() {
      setState(() => _currentScale = _zoomController.value.getMaxScaleOnAxis());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await c.seekTo(Duration.zero);
      await c.play();
      if (mounted) setState(() {});
      _scheduleAutoHide();
    });
  }

  void _handleLike() {
    setState(() {
      if (_isLiked) {
        _isLiked = false;
        _votes = (_votes - 1).clamp(0, 1 << 30);
      } else {
        if (_isDisliked) {
          _isDisliked = false;
          _votes += 1;
        }
        _isLiked = true;
        _votes += 1;
      }
    });
    widget.onLike?.call(); // يحدث المنشور الأصلي أيضًا
  }

  void _handleDislike() {
    setState(() {
      if (_isDisliked) {
        _isDisliked = false;
        _votes += 1;
      } else {
        if (_isLiked) {
          _isLiked = false;
          _votes -= 1;
        }
        _isDisliked = true;
        _votes -= 1;
      }
    });
    widget.onDislike?.call();
  }

  Future<void> _handleComment() async {
    widget.onComment?.call();
    // إذا كان onComment يفتح CommentsScreen ويرجع،
    // بعد الرجوع نزيد العداد محليًا كتقريب بسيط:
    // (أو اجعل onComment يعيد العدد الجديد إن أمكن)
  }
  void _tick() {
    if (mounted) setState(() {});
  }
  void _resetZoom() {
    _zoomController.value = Matrix4.identity();
    if (mounted) {
      setState(() => _currentScale = 1.0);
    }
  }
  bool get _isZoomed => (_currentScale - 1.0).abs() > 0.05;

  bool get _isEnded {
    final c = widget.controller;
    return c.value.isInitialized &&
        c.value.duration > Duration.zero &&
        c.value.position >= c.value.duration;
  }

  void _scheduleAutoHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && widget.controller.value.isPlaying) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _scheduleAutoHide();
  }

  void _togglePlay() {
    final c = widget.controller;
    if (_isEnded) {
      c.seekTo(Duration.zero);
      c.play();
    } else {
      c.value.isPlaying ? c.pause() : c.play();
    }
    setState(() => _controlsVisible = true);
    _scheduleAutoHide();
  }

  void _seekBy(Duration offset) {
    final c = widget.controller;
    final target = c.value.position + offset;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > c.value.duration ? c.value.duration : target);
    c.seekTo(clamped);
    _scheduleAutoHide();
  }

  

  void _onPointerDown(PointerDownEvent event) {
    if (_pointerInBottomPanel) return; // تجاهل السحب من الشريط السفلي

    _activePointers++;
    if (_activePointers > 1) {
      _dragStart = null;
      setState(() => _isPinching = true); // NEW
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
    if (_pointerInBottomPanel) return;
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
      setState(() => _isPinching = false); // NEW
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
      setState(() => _isPinching = false); // NEW
    }
    _dragStart = null;
    _isDragGesture = false;
    if (_dragOffset != 0) setState(() => _dragOffset = 0);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
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
    // NEW
    final infoVisible = _controlsVisible && !_isPinching && !_isZoomed;

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
                Transform.translate(
                  offset: Offset(0, _dragOffset),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: ratio,
                      child: InteractiveViewer(
                        transformationController: _zoomController,
                        maxScale: 8.0,
                        minScale: 1.0, // FIX: يقدر يصغّر أكثر من الحجم العادي
                        panEnabled: false,
                        scaleEnabled: true,
                        boundaryMargin: const EdgeInsets.all(double.infinity),
                        onInteractionEnd: (_) {
                          // عند رفع الإصبعين بعد التكبير
                          if (_activePointers < 2) {
                            _resetZoom();
                            setState(() {});
                          }
                        },
                        child: VideoPlayer(c),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 90,
                  bottom: 130,
                  left: 0,
                  right: 0,
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onDoubleTap: () => _seekBy(const Duration(seconds: -10)),
                          behavior: HitTestBehavior.translucent,
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onDoubleTap: () => _seekBy(const Duration(seconds: 10)),
                          behavior: HitTestBehavior.translucent,
                        ),
                      ),
                    ],
                  ),
                ),

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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            children: [
                              _ViewerIconButton(
                                icon: Icons.close_rounded,
                                onTap: () => Navigator.of(context).pop(),
                              ),
                              const Spacer(),
                              // ===== زر القائمة هنا =====
                              if (widget.onMenuBuilder != null)
                                widget.onMenuBuilder!(context)
                              else if (widget.menuButton != null)
                                widget.menuButton!,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ===== أسفل الشاشة =====
                AnimatedOpacity(
                  opacity: _controlsVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_controlsVisible,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Listener(
                        onPointerDown: (_) => _pointerInBottomPanel = true,
                        onPointerUp: (_) => _pointerInBottomPanel = false,
                        onPointerCancel: (_) => _pointerInBottomPanel = false,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.92),
                                Colors.black.withValues(alpha: 0.55),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.55, 1.0],
                            ),
                          ),
                          child: SafeArea(
                            top: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 28, 14, 10),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _RedditStyleMeta(
                                    authorName: widget.authorName,
                                    authorPhotoUrl: widget.authorPhotoUrl,
                                    postTitle: widget.postTitle,
                                    postBody: widget.postBody,
                                  ),
                                  const SizedBox(height: 12),
                                  _InlineVideoControls(controller: c),
                                  // بعد _RedditStyleMeta
                                  if (widget.onLike != null) ...[
                                    const SizedBox(height: 12),
                                    _FullscreenActionBar(
                                      likeButtonKey: GlobalKey(),
                                      tagsCount: widget.tagsCount ?? 0,
                                      onTagsTap: widget.onTags ?? () {},
                                      commentLabel: '$_commentsCount',
                                      onCommentTap: () async {
                                        final newCount = await widget.onComment?.call();
                                        if (newCount != null && mounted) {
                                          setState(
                                              () => _commentsCount = newCount);
                                        }
                                      },
                                      likeLabel: _formatVotes(_votes),
                                      isLiked: _isLiked,
                                      isDisliked: _isDisliked,
                                      onLikeTap: _handleLike,
                                      onDislike: _handleDislike,
                                    ),
                                  ],
                                ],
                              ),
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

// ==================== FullscreenPostPager (TikTok-style vertical swipe) ====================

