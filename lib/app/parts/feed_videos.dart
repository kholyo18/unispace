part of '../../main.dart';

class _FeedVideoCoordinator {
  _FeedVideoCoordinator._();
  static final instance = _FeedVideoCoordinator._();

  void Function()? _pauseCurrent;

  void claim(void Function() pause) {
    if (_pauseCurrent != null && _pauseCurrent != pause) {
      _pauseCurrent!();
    }
    _pauseCurrent = pause;
  }

  void release(void Function() pause) {
    if (_pauseCurrent == pause) _pauseCurrent = null;
  }
}
class _AutoSizeVideo extends StatefulWidget {
  const _AutoSizeVideo({
    super.key,
    this.postId,
    required this.path,
    this.maxHeight = 480,
    this.authorPhotoUrl,
    this.authorName,
    this.postTitle,
    this.postBody,
    this.menuButton,
    this.votes,
    this.isLiked,
    this.isDisliked,
    this.commentsCount,
    this.tagsCount,
    this.onLike,
    this.onDislike,
    this.onComment,
    this.onTags,
    this.onOpenFullscreen,
  });

  final String path;
  final String? postId;
  final double maxHeight;
  final String? authorName;
  final String? authorPhotoUrl;
  final String? postTitle;
  final String? postBody;
  final Widget? menuButton;

  final int? votes;
  final bool? isLiked;
  final bool? isDisliked;
  final int? commentsCount;
  final int? tagsCount;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final Future<int?> Function()? onComment;
  final VoidCallback? onTags;
  final VoidCallback? onOpenFullscreen;

  @override
  State<_AutoSizeVideo> createState() => _AutoSizeVideoState();
}

class _AutoSizeVideoState extends State<_AutoSizeVideo> with WidgetsBindingObserver {
  int _accessGeneration = 0;
  bool _foreground = true, _suspended = false;
  String? _viewer;
  StreamSubscription<User?>? _auth;
  void _invalidateAccess() {
    if (!mounted || widget.postId == null) return;
    _accessGeneration++;
    _disposeTimer?.cancel();
    _pauseSelf();
    _FeedVideoCoordinator.instance.release(_pauseSelf);
    setState(() { _suspended = true; _error = mainText(context, "أعد التحقق لتشغيل الفيديو"); _loading = false; });
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) _invalidateAccess();
  }
  VideoPlayerController? _controller;
  bool _loading = false; // كان true — اتركه false حتى تبدأ التهيئة
  String? _error;
  bool _finished = false;
  bool _muted = true; // يبدأ مكتومًا
  bool _visible = false;
  bool _initialized = false;
  bool _initializing = false;
  late final Key _visibilityKey =
  ValueKey('autosize_video_${widget.path}');
  Timer? _disposeTimer;
  static const double _visibilityThreshold = 0.75;

  @override
  void initState() {
    super.initState();
    _viewer = FirebaseAuth.instance.currentUser?.uid;
    WidgetsBinding.instance.addObserver(this);
    blockedListRevision.addListener(_invalidateAccess);
    moderationRevision.addListener(_invalidateAccess);
    authorProfileRevision.addListener(_invalidateAccess);
    _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (_viewer != user?.uid) { _viewer = user?.uid; _invalidateAccess(); }
    });
  }

  Future<void> _initializeVideo() async {
    if (!mounted || _initializing || (_initialized && !_suspended) ||
        (widget.postId != null && !_foreground)) return;
    _disposeTimer?.cancel();
    final generation = ++_accessGeneration;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    bool current() => mounted && generation == _accessGeneration &&
        (widget.postId == null || (uid != null && uid == FirebaseAuth.instance.currentUser?.uid && _foreground));
    final previous = _controller;
    _controller = null;
    previous?.removeListener(_onControllerUpdate);
    previous?.dispose();
    setState(() { _initializing = true; _initialized = false; _suspended = false; _loading = true; _error = null; });

    final path = widget.path.trim();
    if (path.isEmpty) {
      _initializing = false;
      if (mounted) {
        setState(() {
          _loading = false;
          _error = mainText(context, "رابط الفيديو فارغ");
        });
      }
      return;
    }

    await _VideoInitGate.instance.acquire();
    if (!mounted) {
      _VideoInitGate.instance.release();
      _initializing = false;
      return;
    }

    VideoPlayerController? pending;
    var mediaStage = 'authorization';
    final mediaWatch = Stopwatch()..start();
    PerformanceProbe.elapsed('video_feed_authorization_start', mediaWatch);
    try {
      if (!current()) throw StateError('Video unavailable');
      final source = widget.postId == null ? (path.startsWith('https://') ? (await ProtectedMediaService.instance.resolve(path)).url : path) : await PostMediaLinks.read(widget.postId!, path);
      if (!current()) throw StateError('Video unavailable');
      final controller = createVideoPlaybackController(source);
      pending = controller;
      mediaStage = 'player-initialize';
      PerformanceProbe.elapsed('video_feed_buffer_start', mediaWatch);
      await initializeVideoPlayback(controller);
      mediaStage = 'access-current';
      PerformanceProbe.elapsed('video_feed_buffer_ready', mediaWatch);
      if (!current()) throw StateError('Video unavailable');
      if (widget.postId != null) {
        final fresh = _Post.fromData(widget.postId!, await _readAuthorizedPostData(widget.postId));
        if (!current()) throw StateError('Video unavailable');
        mediaStage = 'access-membership';
        if (!fresh.videoPaths.any((p) => p.trim() == path)) throw StateError('Video removed');
      }
      await controller.setLooping(false);
      await controller.setVolume(0);
      if (!current()) throw StateError('Video unavailable');
      await startVisibleVideo(controller, () => _visible && current());
      if (!current()) throw StateError('Video unavailable');
      controller.addListener(_onControllerUpdate);
      setState(() { _controller = controller; _loading = false; _initialized = true; _error = null; _finished = false; });
      pending = null;
      if (_visible) _FeedVideoCoordinator.instance.claim(_pauseSelf);
      PerformanceProbe.elapsed('video_feed_ready', mediaWatch);
      observeVideoPlaybackError(controller, () {
        if (!mounted || !identical(_controller, controller)) return;
        if (kDebugMode || PerformanceProbe.enabled)
          debugPrint(
              '[VIDEO_FAILURE] surface=feed stage=playback type=VideoPlayerError code=native');
        controller.removeListener(_onControllerUpdate);
        _FeedVideoCoordinator.instance.release(_pauseSelf);
        setState(() {
          _controller = null;
          _initialized = false;
          _suspended = true;
          _loading = false;
          _error = mainText(context, "تعذر تحميل الفيديو");
        });
        controller.dispose();
      });
    } catch (error) {
      if (kDebugMode || PerformanceProbe.enabled) {
        final code = error is FirebaseException
            ? error.code
            : error is PlatformException
                ? error.code
                : 'none';
        debugPrint(
            '[VIDEO_FAILURE] surface=feed stage=$mediaStage type=${error.runtimeType} code=$code');
      }
      if (mounted && generation == _accessGeneration) setState(() {
        _loading = false; _error = mainText(context, "تعذر تحميل الفيديو");
      });
    } finally {
      try { await pending?.dispose(); }
      finally {
        _VideoInitGate.instance.release();
        if (mounted) { setState(() => _initializing = false); } else { _initializing = false; }
      }
    }
  }

  void _onControllerUpdate() {
    final c = _controller;
    if (c == null || !c.value.isInitialized || !mounted || _finished) return;

    final d = c.value.duration;
    final p = c.value.position;
    if (videoPlaybackEnded(p, d)) {
      c.pause();
      setState(() => _finished = true);
    }
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    _visible = info.visibleFraction >= _visibilityThreshold;
    if (_suspended || (widget.postId != null && !_foreground)) return;
    final visible = _visible;
    // Buffer on first entry; playback still requires the visibility threshold.
    if (info.visibleFraction > 0 &&
        !_initialized &&
        !_initializing &&
        _error == null) {
      _disposeTimer?.cancel();
      _initializeVideo();
      return;
    }

    if (visible) {
      _disposeTimer?.cancel(); // ← هنا

      if (!_initialized && !_initializing) {
        _initializeVideo();
        return;
      }

      final c = _controller;
      if (c == null || !c.value.isInitialized) return;

      if (_finished) {
        c.seekTo(Duration.zero);
        setState(() => _finished = false);
      }

      // نفس المرجع دائماً → يوقف الفيديو السابق ثم يسجّل هذا
      _FeedVideoCoordinator.instance.claim(_pauseSelf);

      c.setVolume(_muted ? 0 : 1);
      if (!c.value.isPlaying) c.play();
    } else {
      _pauseSelf();
      _FeedVideoCoordinator.instance.release(_pauseSelf);
      _disposeTimer?.cancel();
      _disposeTimer = Timer(const Duration(seconds: 8), () {
        if (!mounted) return;
        final c = _controller;
        if (c == null) return;
        c.removeListener(_onControllerUpdate);
        c.dispose();
        _controller = null;
        _initialized = false;
        _initializing = false;
        if (mounted) setState(() {});
      });
    }
  }

  void _toggleMute() {
    if (_suspended) return;
    final c = _controller;
    if (c == null) return;

    setState(() {
      _muted = !_muted;
      c.setVolume(_muted ? 0 : 1);
    });
  }

  Future<void> _openFullscreen() async {
    if (_suspended || (widget.postId != null && !_foreground)) return;
    final generation = _accessGeneration;
    final c = _controller;

    if (c == null) return;

    await c.pause();
    await c.setVolume(0);
    if (!mounted) return;
    if (generation != _accessGeneration) return;
    if (widget.postId != null) {
      // The authorized post pager owns a separate controller and rechecks access.
      widget.onOpenFullscreen?.call();
      return;
    }
    if (widget.onOpenFullscreen != null) {
      widget.onOpenFullscreen!();
      // بعد الرجوع من العارض الموحّد
      if (!mounted) return;
      final isCurrentlyMuted = c.value.volume == 0;
      await c.seekTo(Duration.zero);
      await c.pause();
      await c.setVolume(0);
      setState(() {
        _finished = true;
        _muted = isCurrentlyMuted;
      });
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullscreenVideoViewer(
          controller: c,
          authorName: widget.authorName,
          authorPhotoUrl: widget.authorPhotoUrl,
          postTitle: widget.postTitle,
          postBody: widget.postBody,
          menuButton: widget.menuButton,
          votes: widget.votes,
          isLiked: widget.isLiked ?? false,
          isDisliked: widget.isDisliked ?? false,
          commentsCount: widget.commentsCount,
          tagsCount: widget.tagsCount,
          onLike: widget.onLike,
          onDislike: widget.onDislike,
          onComment:widget.onComment,
          onTags: widget.onTags,

        ),
      ),
    );

    if (!mounted) return;

    // مزامنة حالة الكتم بعد الرجوع
    final isCurrentlyMuted = c.value.volume == 0;

    await c.seekTo(Duration.zero);
    await c.pause();
    await c.setVolume(0);

    setState(() {
      _finished = true;
      _muted = isCurrentlyMuted; // ← المهم
    });
  }

  void _pauseSelf() {
    final c = _controller;
    if (c == null) return;
    if (c.value.isPlaying) c.pause();
    c.setVolume(0);
  }

  @override
  void dispose() {
    _accessGeneration++;
    _auth?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    blockedListRevision.removeListener(_invalidateAccess);
    moderationRevision.removeListener(_invalidateAccess);
    authorProfileRevision.removeListener(_invalidateAccess);
    _pauseSelf();
    _disposeTimer?.cancel(); // ← هنا
    _FeedVideoCoordinator.instance.release(_pauseSelf);
    final c = _controller;
    if (c != null) {
      c.removeListener(_onControllerUpdate);
      c.dispose();
    }
    _controller = null;
    super.dispose();
  }

  Widget _placeholderBox({required bool isError}) {
    return Container(
      height: 220,
      color: Colors.black,
      alignment: Alignment.center,
      child: isError
          ? Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.video_library_outlined,
              color: Colors.white70, size: 42),
          const SizedBox(height: 8),
          Text(
            _error ?? mainText(context, "تعذر تحميل الفيديو"),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (widget.postId != null) TextButton(onPressed: _initializeVideo,
              child:  Text(mainText(context, "إعادة المحاولة"))),
        ],
      )
          : const CircularProgressIndicator(color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: VisibilityDetector(
        key: _visibilityKey,
        onVisibilityChanged: _handleVisibilityChanged,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_suspended) return _placeholderBox(isError: true);
    if (_loading || _initializing || (!_initialized && _error == null)) {
      return _placeholderBox(isError: false);
    }
    if (_error != null || _controller == null) {
      return _placeholderBox(isError: true);
    }

    final controller = _controller!;
    final rawRatio = controller.value.aspectRatio;
    final aspectRatio =
    (rawRatio.isFinite && rawRatio > 0) ? rawRatio : 16 / 9;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final naturalHeight = width / aspectRatio;
        final displayHeight =
        naturalHeight > widget.maxHeight ? widget.maxHeight : naturalHeight;
        final needsCover = naturalHeight > widget.maxHeight;

        return SizedBox(
          width: width,
          height: displayHeight,
          child: Container(
            color: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              children: [
                needsCover
                    ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                )
                    : SizedBox.expand(child: VideoPlayer(controller)),

                // الضغط لفتح ملء الشاشة — تحت الأزرار
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _openFullscreen,
                  ),
                ),

                // كتم — فوق طبقة الفتح
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _toggleMute,
                      customBorder: const CircleBorder(),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _muted
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),

                if (_finished)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _openFullscreen,
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.55),
                        alignment: Alignment.center,
                        child: const Icon(Icons.replay_rounded,
                            color: Colors.white, size: 34),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
class _PickedVideoTile extends StatefulWidget {
  const _PickedVideoTile({
    super.key,
    required this.file,
    required this.onDelete,
  });

  final File file;
  final VoidCallback onDelete;

  @override
  State<_PickedVideoTile> createState() => _PickedVideoTileState();
}

class _PickedVideoTileState extends State<_PickedVideoTile> {
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _error;

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final controller = VideoPlayerController.file(widget.file);
      await controller.initialize();
      await controller.setLooping(false);
      await controller.setVolume(0);
      await controller.pause();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      controller.addListener(_onUpdate);

      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Picked video init failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = mainText(context, "تعذر تحميل الفيديو");
      });
    }
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;

    if (c.value.isPlaying) {
      c.pause();
    } else {
      if (c.value.position >=
          c.value.duration - const Duration(milliseconds: 300)) {
        c.seekTo(Duration.zero);
      }
      c.play();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || controller == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white70, size: 36),
            const SizedBox(height: 8),
            Text(
              _error ?? mainText(context, "خطأ"),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final isPlaying = controller.value.isPlaying;

    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),

        // زر التشغيل / الإيقاف
        Center(
          child: GestureDetector(
            onTap: _togglePlay,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
        ),

        // زر الحذف
        Positioned(
          top: 10,
          right: 10,
          child: GestureDetector(
            onTap: widget.onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),

        // شريط التقدم
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Colors.redAccent,
              bufferedColor: Colors.white38,
              backgroundColor: Colors.white24,
            ),
          ),
        ),
      ],
    );
  }
}
// ==================== VideoSlideWidget ====================
class _VideoSlideWidget extends StatefulWidget {
  final String videoPath;
  final String? postId;
  final String? commentId;
  final String? authorName;
  final String? authorPhotoUrl;
  final String? postTitle;
  final String? postBody;
  final Widget? menuButton;

  const _VideoSlideWidget({
    super.key,
    this.postId,
    this.commentId,
    required this.videoPath,
    this.authorName,
    this.authorPhotoUrl,
    this.postTitle,
    this.postBody,
    this.menuButton,
  });

  @override
  State<_VideoSlideWidget> createState() => _VideoSlideWidgetState();
}

class _VideoSlideWidgetState extends State<_VideoSlideWidget> with WidgetsBindingObserver {
  int _accessGeneration = 0;
  bool _foreground = true, _suspended = false, _openingFullscreen = false;
  String? _viewer;
  StreamSubscription<User?>? _auth;
  TransitionRoute<void>? _fullscreenRoute;
  void _invalidateVideo() {
    if (!mounted || widget.postId == null) return;
    _accessGeneration++;
    _controller?.pause();
    _controller?.setVolume(0);
    setState(() { _suspended = true; _loading = false; _error = mainText(context, "تغيّر الوصول، أعد التحقق لتشغيل الفيديو"); });
    final route = _fullscreenRoute;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = route?.navigator;
      if (route != null && nav != null && nav.mounted && route.isActive) nav.removeRoute(route);
    });
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) _invalidateVideo();
  }
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _error;
  bool _finished = false;
  bool _visible = false;
  bool _hasStartedLoading = false;
  bool _muted = true; // يبدأ مكتومًا

  late final Key _visibilityKey =
  ValueKey('feed_video_${widget.videoPath}');

  static const double _visibilityThreshold = 0.5;

  @override
  void initState() {
    super.initState();
    _viewer = FirebaseAuth.instance.currentUser?.uid;
    WidgetsBinding.instance.addObserver(this);
    blockedListRevision.addListener(_invalidateVideo);
    moderationRevision.addListener(_invalidateVideo);
    authorProfileRevision.addListener(_invalidateVideo);
    _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (_viewer != user?.uid) { _viewer = user?.uid; _invalidateVideo(); }
    });
  }

  Future<void> _verifyCommentVideoAccess() async {
    final postId = widget.postId, commentId = widget.commentId, source = widget.videoPath.trim();
    final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('verifyCommentMediaAccess')
        .call({
          'postId': postId, 'commentId': commentId, 'url': source,
        });
    final data = Map<String, dynamic>.from(result.data as Map);
    if (data['authorized'] != true || data['mediaType'] != 'video' ||
        data['postId'] != postId || data['commentId'] != commentId || data['source'] != source) {
      throw StateError('Invalid comment video access');
    }
  }

  Future<String> _readCommentVideoLink() async {
    final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('readCommentMediaDownload')
        .call({
          'postId': widget.postId, 'commentId': widget.commentId, 'url': widget.videoPath.trim(),
      'delivery': 'playback',
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    final url = data['url'], expiry = data['expiresAt'];
    if (data['mediaType'] != 'video' || url is! String || Uri.tryParse(url)?.scheme != 'https' ||
        expiry is! num || expiry <= DateTime.now().millisecondsSinceEpoch) {
      throw StateError('Invalid comment video authorization');
    }
    return url;
  }

  Future<void> _initializeVideo() async {
    if (!mounted || _hasStartedLoading || _openingFullscreen || (widget.postId != null && !_foreground)) return;
    final generation = ++_accessGeneration;
    _suspended = false;
    final previous = _controller;
    _controller = null;
    previous?.removeListener(_onControllerUpdate);
    previous?.dispose();
    _hasStartedLoading = true;
    setState(() { _loading = true; _error = null; });
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final postId = widget.postId;
    final blockVersion = blockedListRevision.value;
    final profileVersion = authorProfileRevision.value;
    final moderationVersion = moderationRevision.value;
    bool current() => mounted && generation == _accessGeneration && !_suspended && (postId == null ||
        (uid != null && uid == FirebaseAuth.instance.currentUser?.uid &&
         postId == widget.postId && blockVersion == blockedListRevision.value &&
         profileVersion == authorProfileRevision.value && moderationVersion == moderationRevision.value));

    final path = widget.videoPath.trim();
    if (path.isEmpty) {
      setState(() {
        _loading = false;
        _error = mainText(context, "رابط الفيديو فارغ");
      });
      return;
    }

    await _VideoInitGate.instance.acquire();
    if (!mounted) {
      _VideoInitGate.instance.release();
      return;
    }

    VideoPlayerController? pending;
    var mediaStage = 'authorization';
    final mediaWatch = Stopwatch()..start();
    PerformanceProbe.elapsed('video_slide_authorization_start', mediaWatch);
    try {
      if (!current()) throw StateError('Video unavailable');
      final source = widget.commentId != null ? await _readCommentVideoLink()
          : postId == null ? (path.startsWith('https://') ? (await ProtectedMediaService.instance.resolve(path)).url : path) : await PostMediaLinks.read(postId, path);
      if (!current()) throw StateError('Video unavailable');
      final controller = createVideoPlaybackController(source);
      pending = controller;
      mediaStage = 'player-initialize';
      PerformanceProbe.elapsed('video_slide_buffer_start', mediaWatch);
      await initializeVideoPlayback(controller);
      mediaStage = 'access-current';
      PerformanceProbe.elapsed('video_slide_buffer_ready', mediaWatch);
      if (!current()) throw StateError('Video unavailable');
      if (widget.commentId != null) {
        // Recheck the exact comment and its ancestors after network initialization.
        await _verifyCommentVideoAccess();
        if (!current()) throw StateError('Video unavailable');
      } else if (postId != null) {
        final fresh = _Post.fromData(postId, await _readAuthorizedPostData(postId));
        if (!current()) throw StateError('Video unavailable');
        final belongs = fresh.videoPaths.any((p) => p.trim() == path) ||
            fresh.pollSlides.any((slide) => slide['type'] == 'video' &&
                (slide['url'] ?? slide['mediaPath'] ?? slide['path'] ?? '')
                        .toString()
                        .trim() == path);
        if (!belongs) throw StateError('Video removed');
      }
      await controller.setLooping(false);
      await controller.setVolume(0);
      if (!current()) throw StateError('Video unavailable');
      await startVisibleVideo(
          controller, () => _visible && current() && !_openingFullscreen);
      if (!current()) throw StateError('Video unavailable');
      controller.addListener(_onControllerUpdate);
      setState(() { _controller = controller; _loading = false; _error = null; });
      pending = null;
      PerformanceProbe.elapsed('video_slide_ready', mediaWatch);
      observeVideoPlaybackError(controller, () {
        if (!mounted || !identical(_controller, controller)) return;
        if (kDebugMode || PerformanceProbe.enabled)
          debugPrint(
              '[VIDEO_FAILURE] surface=slide stage=playback type=VideoPlayerError code=native');
        controller.removeListener(_onControllerUpdate);
        setState(() {
          _controller = null;
          _suspended = true;
          _loading = false;
          _error = mainText(context, "تعذر تحميل الفيديو");
        });
        controller.dispose();
      });
    } catch (error) {
      if (kDebugMode || PerformanceProbe.enabled) {
        final code = error is FirebaseException
            ? error.code
            : error is PlatformException
                ? error.code
                : 'none';
        debugPrint(
            '[VIDEO_FAILURE] surface=slide stage=$mediaStage type=${error.runtimeType} code=$code');
      }
      if (mounted && generation == _accessGeneration) setState(() { _loading = false; _error = mainText(context, "تعذر تحميل الفيديو"); });
    } finally {
      try { await pending?.dispose(); }
      finally { _VideoInitGate.instance.release(); }
    }
  }

  void _onControllerUpdate() {
    final c = _controller;
    if (c == null || !c.value.isInitialized || !mounted || _finished) return;

    final d = c.value.duration;
    final p = c.value.position;
    if (videoPlaybackEnded(p, d)) {
      c.pause();
      setState(() => _finished = true);
    }
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    _visible = info.visibleFraction >= _visibilityThreshold;
    if (_suspended || (widget.postId != null && !_foreground) || _openingFullscreen) return;
    final visible = _visible;
    if (info.visibleFraction > 0 && !_hasStartedLoading) {
      _initializeVideo();
      return; // الكونترولر مازال مكاينش، غادي نستنى الفريم الجاي
    }
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;



    if (visible) {
      // عند الظهور مرة أخرى → نعيد الحالة الطبيعية
      if (_finished) {
        c.seekTo(Duration.zero);
        setState(() => _finished = false);
      }
      if (!c.value.isPlaying) {
        c.play();
      }
    } else {
      // عند الاختفاء → نوقف الفيديو
      if (c.value.isPlaying) {
        c.pause();
      }
    }
  }

  void _toggleMute() {
    if (_suspended) return;
    final c = _controller;
    if (c == null) return;

    setState(() {
      _muted = !_muted;
      c.setVolume(_muted ? 0 : 1);
    });
  }

  Future<void> _openFullscreen() async {
    final c = _controller;
    if (c == null || _suspended || _openingFullscreen) return;
    _openingFullscreen = true;
    final generation = _accessGeneration;
    bool current() => mounted && generation == _accessGeneration && !_suspended && identical(c, _controller);
    try {
      await c.pause();
      await c.setVolume(0);
      if (!current()) return;
      if (widget.commentId != null) {
        await _verifyCommentVideoAccess();
        if (!current()) return;
      } else if (widget.postId != null) {
        final fresh = _Post.fromData(widget.postId!, await _readAuthorizedPostData(widget.postId));
        if (!current()) return;
        final path = widget.videoPath.trim();
        if (!fresh.videoPaths.any((p) => p.trim() == path) &&
            !fresh.pollSlides.any((slide) => slide['type'] == 'video' &&
                (slide['url'] ?? slide['mediaPath'] ?? slide['path'] ?? '')
                        .toString()
                        .trim() == path)) {
          throw StateError('Video removed');
        }
      }
      final route = MaterialPageRoute<void>(builder: (_) => SimpleFullscreenVideoViewer(controller: c));
      _fullscreenRoute = route;
      await Navigator.of(context).push(route);
      await route.completed;
      if (!current()) return;
      final isCurrentlyMuted = c.value.volume == 0;
      await c.seekTo(Duration.zero);
      if (!current()) return;
      await c.pause();
      await c.setVolume(0);
      if (current()) setState(() { _finished = true; _muted = isCurrentlyMuted; });
    } catch (_) {
      if (current() && widget.postId != null) _invalidateVideo();
    } finally {
      _fullscreenRoute = null;
      _openingFullscreen = false;
    }
  }
  @override
  void dispose() {
    _accessGeneration++;
    _auth?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    blockedListRevision.removeListener(_invalidateVideo);
    moderationRevision.removeListener(_invalidateVideo);
    authorProfileRevision.removeListener(_invalidateVideo);
    final route = _fullscreenRoute;
    final nav = route?.navigator;
    if (route != null && nav != null && nav.mounted && route.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (nav.mounted && route.isActive) nav.removeRoute(route);
      });
    }
    _controller?.removeListener(_onControllerUpdate);
    final controller = _controller;
    if (route != null) {
      controller?.pause();
      route.completed.then((_) => controller?.dispose());
    } else {
      controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FIX: VisibilityDetector دابا كيلف حتى حالة "قبل التحميل" (_loading==true بلا _hasStartedLoading)
    // باش يقدر يكتشف الظهور ويبدا التحميل بمجرد ما يوصل للشاشة
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: VisibilityDetector(
        key: _visibilityKey,
        onVisibilityChanged: _handleVisibilityChanged,
        child: Container(
          color: Colors.black,
          width: double.infinity,
          height: 250,
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _error != null || _controller == null
              ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.video_library_outlined, color: Colors.white70, size: 42),
                const SizedBox(height: 8),
                Text(_error ?? mainText(context, "تعذر تحميل الفيديو"),
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                if (widget.postId != null) TextButton(onPressed: () {
                  _hasStartedLoading = false;
                  _initializeVideo();
                }, child:  Text(mainText(context, "إعادة المحاولة"))),
              ],
            ),
          )
              : Stack(
            fit: StackFit.expand,
            children: [
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              ),
              Positioned.fill(
                child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _openFullscreen),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: _toggleMute,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), shape: BoxShape.circle),
                    child: Icon(_muted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
              if (_finished)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _openFullscreen,
                    child: Container(
                      color: Colors.black45,
                      alignment: Alignment.center,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: const Icon(Icons.replay_rounded, color: Colors.white, size: 32),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

