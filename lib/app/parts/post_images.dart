part of '../../main.dart';

class PostImagesSlider extends StatefulWidget {
  final List<String> images;
  const PostImagesSlider({super.key, required this.images});

  @override
  State<PostImagesSlider> createState() => _PostImagesSliderState();
}

class _PostImagesSliderState extends State<PostImagesSlider> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ✅ يدعم assets وfile paths وnetwork
  Widget _buildImage(String path) {
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover, width: double.infinity);
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return ProtectedImage.network(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[300],
          child: const Center(child: Icon(Icons.broken_image)),
        ),
      );
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover, width: double.infinity);
    }
    return Container(
      color: Colors.grey[300],
      child: const Center(child: Icon(Icons.broken_image)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              final path = widget.images[index];
              return GestureDetector(
                onTap: () {
                  // عارض بسيط مخصص لصور البول (إغلاق + تحميل فقط)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SimpleFullscreenImageViewer(
                        images: widget.images,
                        initialIndex: index,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildImage(path),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        if (widget.images.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.images.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: _currentIndex == index ? 14 : 8,
                height: _currentIndex == index ? 6 : 4,
                decoration: BoxDecoration(
                  color: _currentIndex == index
                      ? AppTeal.main
                      : Colors.grey[400],
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
      ],
    );
  }
}

class _AuthorizedImageView extends StatefulWidget {
  const _AuthorizedImageView(
      {required this.postId, required this.path, super.key, this.commentId, this.preview = false});
  final String? commentId;
  final bool preview;
  final String postId, path;
  @override
  State<_AuthorizedImageView> createState() => _AuthorizedImageViewState();
}

class _AuthorizedImageViewState extends State<_AuthorizedImageView>
    with WidgetsBindingObserver {
  late final String? _viewer;
  StreamSubscription<User?>? _auth;
  bool _foreground = true;
  int _revision = 0;
  @override
  void initState() {
    super.initState();
    _viewer = FirebaseAuth.instance.currentUser?.uid;
    WidgetsBinding.instance.addObserver(this);
    blockedListRevision.addListener(_invalidate);
    moderationRevision.addListener(_invalidate);
    authorProfileRevision.addListener(_invalidate);
    _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user?.uid != _viewer) _invalidate();
    });
  }
  void _invalidate() {
    if (mounted) setState(() => _revision++);
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    setState(() {
      _foreground = state == AppLifecycleState.resumed;
      _revision++;
    });
  }
  @override
  void dispose() {
    _auth?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    blockedListRevision.removeListener(_invalidate);
    moderationRevision.removeListener(_invalidate);
    authorProfileRevision.removeListener(_invalidate);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final sameAccount = _viewer != null && _viewer == FirebaseAuth.instance.currentUser?.uid;
    final image = !sameAccount
        ?  Center(child: Text(mainText(context, "تغيّر الحساب، أغلق العارض وأعد فتحه"),
            style: TextStyle(color: Colors.white)))
        : AuthorizedPostImage(key: ValueKey(_revision), postId: widget.postId,
            commentId: widget.commentId, url: widget.path, active: _foreground,
            fit: widget.preview ? BoxFit.cover : BoxFit.contain);
    if (widget.preview) return SizedBox(height: 220, width: double.infinity, child: image);
    return SimpleFullscreenImageViewer(images: [widget.path], imageBuilder: (_, __) => image);
  }
}

class SimpleFullscreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final Widget Function(String path, int index)? imageBuilder;

  const SimpleFullscreenImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.imageBuilder,
  });

  @override
  State<SimpleFullscreenImageViewer> createState() =>
      _SimpleFullscreenImageViewerState();
}

class _SimpleFullscreenImageViewerState
    extends State<SimpleFullscreenImageViewer> {
  late final PageController _pageController;
  late int currentIndex;
  bool _controlsVisible = true;
  double _dragOffset = 0;

  final Map<int, TransformationController> _zoomControllers = {};
  final Map<int, double> _currentScale = {};

  Offset? _dragStart;
  bool _isDragGesture = false;
  int _activePointers = 0;
  bool _isPinching = false;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);
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
    if (c != null) c.value = Matrix4.identity();
    setState(() => _currentScale[i] = 1.0);
  }

  bool get _isCurrentImageZoomed =>
      ((_currentScale[currentIndex] ?? 1.0) - 1.0).abs() > 0.05;

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
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
      // ضع هنا منطق الحفظ الحقيقي عندك
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

                        final Widget imageWidget = widget.imageBuilder != null
                            ? widget.imageBuilder!(path, index)
                            : path.startsWith('assets/')
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

                // ===== الشريط العلوي (إغلاق + تحميل فقط) =====
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
                              // زر الإغلاق
                              _ViewerIconButton(
                                icon: Icons.close_rounded,
                                onTap: () => Navigator.of(context).pop(),
                              ),
                              const Spacer(),
                              // زر التحميل فقط
                              _ViewerIconButton(
                                icon: Icons.download_rounded,
                                onTap: () =>
                                    _saveImage(widget.images[currentIndex]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ===== مؤشر الصفحات =====
                if (widget.images.length > 1)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 32,
                    child: Center(
                      child: _DotsIndicator(
                        count: widget.images.length,
                        activeIndex: currentIndex,
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
