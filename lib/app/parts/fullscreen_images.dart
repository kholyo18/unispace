part of '../../main.dart';

class FullscreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String? authorName;
  final String? authorPhotoUrl;
  final String? postTitle;
  final String? postBody;
  final Widget? menuButton;
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
  const FullscreenImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
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
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late final PageController _pageController;
  late int currentIndex;
  bool _controlsVisible = true;
  double _dragOffset = 0;
  String _formatVotes(int votes) {
    if (votes >= 1000000) return '${(votes / 1000000).toStringAsFixed(1)}M';
    if (votes >= 1000) return '${(votes / 1000).toStringAsFixed(1)}k';
    return votes.toString();
  }
  final Map<int, TransformationController> _zoomControllers = {};
  final Map<int, double> _currentScale = {};

  Offset? _dragStart;
  bool _isDragGesture = false;
  int _activePointers = 0;
  bool _isPinching = false;
  bool _pointerInBottomPanel = false;
  late int _votes;
  late bool _isLiked;
  late bool _isDisliked;
  late int _commentsCount;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);
    _votes = widget.votes ?? 0;
    _isLiked = widget.isLiked ?? false;      // ← أضف ?? false
    _isDisliked = widget.isDisliked ?? false; // ← أضف ?? false
    _commentsCount = widget.commentsCount ?? 0;
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
  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _zoomControllers.values) {
      c.dispose();
    }
    super.dispose();
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
    if (c != null) {
      c.value = Matrix4.identity();
    }
    setState(() {
      _currentScale[i] = 1.0;
    });
  }

  bool get _isCurrentImageZoomed =>
      ((_currentScale[currentIndex] ?? 1.0) - 1.0).abs() > 0.05;

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
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
    if (_activePointers != 1 || _dragStart == null || _isCurrentImageZoomed) {
      return;
    }

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

  Future<void> _saveImage(String path) async {
    try {
      // منطق الحفظ عندك
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(mainText(context, "تم الحفظ للمعرض"))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(mainText(context, "تعذر حفظ الصورة"))),
      );
    }
  }

  void _shareImage(String path) {
    Share.share(path);
  }

  @override
  Widget build(BuildContext context) {
    final bgOpacity = (1 - (_dragOffset.abs() / 350)).clamp(0.35, 1.0);
    final infoVisible =
        _controlsVisible && !_isPinching && !_isCurrentImageZoomed;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
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
                // ===== الصورة =====
                Transform.translate(
                  offset: Offset(0, _dragOffset),
                  child: Transform.scale(
                    scale: (1 - (_dragOffset.abs() / 2000)).clamp(0.85, 1.0),
                    child: PageView.builder(
                      controller: _pageController,
                      physics: _isDragGesture
                          ? const NeverScrollableScrollPhysics()
                          : const PageScrollPhysics(),
                      itemCount: widget.images.length,
                      onPageChanged: (index) {
                        _resetZoom(currentIndex);
                        setState(() => currentIndex = index);
                      },
                      itemBuilder: (context, index) {
                        final path = widget.images[index];
                        final isNetwork = path.startsWith('http://') ||
                            path.startsWith('https://');

                        final Widget imageWidget = path.startsWith('assets/')
                            ? Image.asset(path, fit: BoxFit.contain)
                            : isNetwork
                            ? ProtectedImage.network(
                          path,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white54,
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) =>
                          const Center(
                            child: Icon(
                              Icons.broken_image_rounded,
                              color: Colors.white38,
                              size: 48,
                            ),
                          ),
                        )
                            : Image.file(File(path), fit: BoxFit.contain);

                        return InteractiveViewer(
                          transformationController: _zoomFor(index),
                          maxScale: 10.0,
                          minScale: 1.0,
                          panEnabled: false,
                          scaleEnabled: true,
                          boundaryMargin:
                          const EdgeInsets.all(double.infinity),
                          onInteractionEnd: (_) {
                            if (_activePointers < 2) {
                              _resetZoom(index);
                            }
                          },
                          child: Center(child: imageWidget),
                        );
                      },
                    ),
                  ),
                ),

                // ===== الشريط العلوي (مثل الفيديو) =====
                // ===== الشريط العلوي =====
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

                              // ===== زر القائمة (يظهر دائمًا إذا تم تمريره) =====
                              if (widget.onMenuBuilder != null) ...[
                                widget.onMenuBuilder!(context),
                                const SizedBox(width: 6),
                              ] else if (widget.menuButton != null) ...[
                                widget.menuButton!,
                                const SizedBox(width: 6),
                              ],

                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),



                // ===== اللوحة السفلية (نفس أسلوب الفيديو) =====
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
                              padding:
                              const EdgeInsets.fromLTRB(14, 28, 14, 10),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // مؤشر الصفحات (Dots) إذا كان هناك أكثر من صورة
                                  if (widget.images.length > 1) ...[
                                    const SizedBox(height: 14),
                                    Center(
                                      child: _DotsIndicator(
                                        count: widget.images.length,
                                        activeIndex: currentIndex,
                                      ),
                                    ),
                                  ],
                                  // نفس الـ Meta المستخدم في الفيديو
                                  _RedditStyleMeta(
                                    authorName: widget.authorName,
                                    authorPhotoUrl: widget.authorPhotoUrl,
                                    postTitle: widget.postTitle,
                                    postBody: widget.postBody,
                                  ),
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

class _ViewerIconButton extends StatelessWidget {
  const _ViewerIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final visibleCount = count > 8 ? 8 : count;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(visibleCount, (i) {
        final isActive = i == (activeIndex.clamp(0, visibleCount - 1));
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          width: isActive ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

