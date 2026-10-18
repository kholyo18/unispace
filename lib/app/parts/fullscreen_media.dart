part of '../../main.dart';

enum _MediaKind { image, video }

class _PostMediaItem {
  final _MediaKind kind;
  final String path;
  const _PostMediaItem.image(this.path) : kind = _MediaKind.image;
  const _PostMediaItem.video(this.path) : kind = _MediaKind.video;
}

class FullscreenMediaViewer extends StatefulWidget {
  final List<_PostMediaItem> items;
  final int initialIndex;
  final String? authorName;
  final String? authorPhotoUrl;
  final String? postTitle;
  final String? postBody;
  final Widget? menuButton;
  final int? votes;
  final bool isLiked;
  final bool isDisliked;
  final int? commentsCount;
  final int? tagsCount;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final Future<int?> Function()? onComment;
  final VoidCallback? onTags;

  const FullscreenMediaViewer({
    super.key,
    required this.items,
    this.initialIndex = 0,
    this.authorName,
    this.authorPhotoUrl,
    this.postTitle,
    this.postBody,
    this.menuButton,
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
  State<FullscreenMediaViewer> createState() => _FullscreenMediaViewerState();
}

class _FullscreenMediaViewerState extends State<FullscreenMediaViewer> {
  late final PageController _pageController;
  late int currentIndex;
  bool _controlsVisible = true;
  double _dragOffset = 0;

  final Map<int, TransformationController> _zoomControllers = {};
  final Map<int, double> _currentScale = {};
  final Map<int, VideoPlayerController> _videoControllers = {};

  Offset? _dragStart;
  bool _isDragGesture = false;
  int _activePointers = 0;
  bool _isPinching = false;
  bool _pointerInBottomPanel = false;

  late int _votes;
  late bool _isLiked;
  late bool _isDisliked;
  late int _commentsCount;

  String _formatVotes(int votes) {
    if (votes >= 1000000) return '${(votes / 1000000).toStringAsFixed(1)}M';
    if (votes >= 1000) return '${(votes / 1000).toStringAsFixed(1)}k';
    return votes.toString();
  }

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex.clamp(0, widget.items.length - 1);
    _pageController = PageController(initialPage: currentIndex);
    _votes = widget.votes ?? 0;
    _isLiked = widget.isLiked;
    _isDisliked = widget.isDisliked;
    _commentsCount = widget.commentsCount ?? 0;
    _initVideoAt(currentIndex);
  }

  Future<void> _initVideoAt(int index) async {
    if (index < 0 || index >= widget.items.length) return;
    final item = widget.items[index];
    if (item.kind != _MediaKind.video) return;
    if (_videoControllers.containsKey(index)) return;

    final path = item.path.trim();
    if (path.isEmpty) return;

    final isNetwork =
        path.startsWith('http://') || path.startsWith('https://');

    VideoPlayerController c;

    try {
      if (isNetwork) {
        // تنزيل/قراءة من الكاش ثم تشغيل محلي
        final file = await DefaultCacheManager().getSingleFile(path);
        if (!mounted) return;
        c = VideoPlayerController.file(
          file,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      } else {
        c = VideoPlayerController.file(
          File(path),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      }

      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(1);

      if (!mounted) {
        await c.dispose();
        return;
      }

      _videoControllers[index] = c;


      if (index == currentIndex) {
        await c.play();
      }

      if (mounted) setState(() {});
    } catch (e, st) {
      debugPrint('Fullscreen media video init failed: $e');
      debugPrintStack(stackTrace: st);
      // إن فشل الكاش، محاولة أخيرة من الشبكة
      if (isNetwork) {
        try {
          final fallback = VideoPlayerController.networkUrl(
            Uri.parse(path),
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          );
          await fallback.initialize();
          await fallback.setLooping(true);
          if (!mounted) {
            await fallback.dispose();
            return;
          }
          _videoControllers[index] = fallback;
          if (index == currentIndex) await fallback.play();
          if (mounted) setState(() {});
        } catch (e2) {
          debugPrint('Fullscreen fallback also failed: $e2');
        }
      }
    }
  }

  void _pauseAllVideosExcept(int keep) {
    _videoControllers.forEach((i, c) {
      if (i != keep && c.value.isPlaying) c.pause();
    });
  }

  TransformationController _zoomFor(int index) {
    return _zoomControllers.putIfAbsent(index, () {
      final c = TransformationController();
      c.addListener(() {
        if (!mounted) return;
        setState(() {
          _currentScale[index] = c.value.getMaxScaleOnAxis();
        });
      });
      return c;
    });
  }

  void _resetZoom([int? index]) {
    final i = index ?? currentIndex;
    final c = _zoomControllers[i];
    if (c != null) c.value = Matrix4.identity();
    setState(() => _currentScale[i] = 1.0);
  }

  bool get _isCurrentZoomed =>
      ((_currentScale[currentIndex] ?? 1.0) - 1.0).abs() > 0.05;

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
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
    widget.onLike?.call();
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

  void _onPointerDown(PointerDownEvent event) {
    if (_pointerInBottomPanel) return;
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
    if (_pointerInBottomPanel) return;
    if (_activePointers != 1 || _dragStart == null || _isCurrentZoomed) return;

    final delta = event.position - _dragStart!;
    if (!_isDragGesture) {
      if (delta.dy.abs() > 8 && delta.dy.abs() > delta.dx.abs() * 1.5) {
        _isDragGesture = true;
      } else if (delta.dx.abs() > 8) {
        _dragStart = null;
        return;
      }
    }
    if (_isDragGesture) setState(() => _dragOffset = delta.dy);
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

  Widget _buildImagePage(int index, String path) {
    final isNetwork =
        path.startsWith('http://') || path.startsWith('https://');
    final imageWidget = path.startsWith('assets/')
        ? Image.asset(path, fit: BoxFit.contain)
        : isNetwork
        ? Image.network(
      path,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.broken_image_rounded,
        color: Colors.white38,
        size: 48,
      ),
    )
        : Image.file(File(path), fit: BoxFit.contain);

    return InteractiveViewer(
      transformationController: _zoomFor(index),
      maxScale: 10,
      minScale: 1,
      panEnabled: false,
      scaleEnabled: true,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      onInteractionEnd: (_) {
        if (_activePointers < 2) _resetZoom(index);
      },
      child: Center(child: imageWidget),
    );
  }

  Widget _buildVideoPage(int index) {
    final c = _videoControllers[index];
    if (c == null || !c.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white54),
      );
    }

    final ratio = c.value.aspectRatio > 0 ? c.value.aspectRatio : 16 / 9;

    return Center(
      child: AspectRatio(
        aspectRatio: ratio,
        child: InteractiveViewer(
          transformationController: _zoomFor(index),
          maxScale: 8.0,
          minScale: 1.0,
          panEnabled: false,
          scaleEnabled: true,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          onInteractionEnd: (_) {
            if (_activePointers < 2) _resetZoom(index);
          },
          child: VideoPlayer(c),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _zoomControllers.values) {
      c.dispose();
    }
    for (final c in _videoControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                Transform.translate(
                  offset: Offset(0, _dragOffset),
                  child: PageView.builder(
                    controller: _pageController,
                    physics: _isDragGesture
                        ? const NeverScrollableScrollPhysics()
                        : const PageScrollPhysics(),
                    itemCount: widget.items.length,
                    onPageChanged: (index) {          // ← هنا
                      _resetZoom(currentIndex);
                      _pauseAllVideosExcept(index);
                      setState(() => currentIndex = index);
                      _initVideoAt(index).then((_) {
                        final c = _videoControllers[index];
                        if (c != null && c.value.isInitialized) {
                          c.seekTo(Duration.zero);
                          c.play();
                        }
                      });
                    },
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      if (item.kind == _MediaKind.image) {
                        return _buildImagePage(index, item.path);
                      }
                      return _buildVideoPage(index);
                    },
                  ),
                ),

                // شريط علوي
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
                              if (widget.menuButton != null) widget.menuButton!,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // شريط سفلي
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
                        onPointerCancel: (_) =>
                        _pointerInBottomPanel = false,
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
                              padding:
                              const EdgeInsets.fromLTRB(14, 28, 14, 10),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.items.length > 1) ...[
                                    Center(
                                      child: _DotsIndicator(
                                        count: widget.items.length,
                                        activeIndex: currentIndex,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                  _RedditStyleMeta(
                                    authorName: widget.authorName,
                                    authorPhotoUrl: widget.authorPhotoUrl,
                                    postTitle: widget.postTitle,
                                    postBody: widget.postBody,
                                  ),
                                  if (widget.items[currentIndex].kind == _MediaKind.video) ...[
                                    const SizedBox(height: 12),
                                    if (_videoControllers[currentIndex] != null &&
                                        _videoControllers[currentIndex]!
                                            .value.isInitialized)
                                      _InlineVideoControls(
                                        controller: _videoControllers[currentIndex]!,
                                      ),
                                  ],
                                  if (widget.onLike != null) ...[
                                    const SizedBox(height: 12),
                                    _FullscreenActionBar(
                                      likeButtonKey: GlobalKey(),
                                      tagsCount: widget.tagsCount ?? 0,
                                      onTagsTap: widget.onTags ?? () {},
                                      commentLabel: '$_commentsCount',
                                      onCommentTap: () async {
                                        final n =
                                        await widget.onComment?.call();
                                        if (n != null && mounted) {
                                          setState(() => _commentsCount = n);
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

