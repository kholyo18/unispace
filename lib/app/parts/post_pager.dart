part of '../../main.dart';

class FullscreenPostPager extends StatefulWidget {
  const FullscreenPostPager({
    super.key,
    required this.posts,
    required this.initialIndex,
    this.initialMediaIndex = 0,
    this.onChanged,
    this.menuButton,
    this.onNearEnd,
  this.onAuthorBlocked,
  });

  final List<_Post> posts;
  final int initialIndex;
  final int initialMediaIndex;
  final VoidCallback? onChanged;
  final Widget? menuButton;
  final void Function(String authorId)? onAuthorBlocked;

  /// يُستدعى قرب نهاية القائمة، ويعيد كل المنشورات بعد التحميل
  final Future<List<_Post>> Function()? onNearEnd;

  @override
  State<FullscreenPostPager> createState() => _FullscreenPostPagerState();
}

class _FullscreenPostPagerState extends State<FullscreenPostPager>
    with WidgetsBindingObserver {
  final Map<String?, int> _mediaIndices = {};
  late PageController _verticalController;
  late int _currentIndex;
  late List<_Post> _posts;
  bool _lockVertical = false;
  bool _loadingMore = false;
  bool _foreground = WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    _posts = List<_Post>.from(widget.posts);
    WidgetsBinding.instance.addObserver(this);
    current = this;
    _currentIndex =
        widget.initialIndex.clamp(0, (_posts.length - 1).clamp(0, 1 << 30));
    _verticalController = PageController(initialPage: _currentIndex);
  }
  static _FullscreenPostPagerState? current;

  _Post get currentPost =>
      _posts[_currentIndex.clamp(0, _posts.length - 1)];

  void hidePost(String postId) {
    if (postId.isEmpty) return;
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx < 0) return;

    final next = List<_Post>.from(_posts)..removeAt(idx);
    if (next.isEmpty) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
      return;
    }

    var i = _currentIndex;
    if (idx < i) i -= 1;
    if (i >= next.length) i = next.length - 1;

    setState(() {
      _posts = next;
      _currentIndex = i;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_verticalController.hasClients) {
        _verticalController.jumpToPage(i);
      }
    });
  }

  void _onAuthorBlocked(String authorId) {
    final next = _posts
        .where((p) => !isBlockedPost(p, {authorId})).toList();

    if (next.isEmpty) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
      return;
    }

    var i = _currentIndex;
    if (i >= next.length) i = next.length - 1;

    setState(() {
      _posts = next;
      _currentIndex = i;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_verticalController.hasClients) {
        _verticalController.jumpToPage(i);
      }
    });
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _verticalController.dispose();
    if (current == this) current = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (mounted)
      setState(() => _foreground = state == AppLifecycleState.resumed);
  }

  List<_Post> _filterSwipeable(List<_Post> source) {
    return source.where((p) {
      final hasMedia = p.imagePaths.any((s) => s.trim().isNotEmpty) ||
          p.videoPaths.any((s) => s.trim().isNotEmpty);
      if (p.pollDataList.isNotEmpty && !hasMedia) return false;
      return hasMedia;
    }).toList();
  }

  Future<void> _maybeLoadMore(int i) async {
    if (widget.onNearEnd == null) return;
    if (_loadingMore) return;
    if (_posts.isEmpty) return;
    if (i < _posts.length - 3) return;

    _loadingMore = true;
    try {
      final updated = await widget.onNearEnd!();
      if (!mounted) return;
      final filtered = _filterSwipeable(updated);
      if (filtered.length <= _posts.length) return;
      setState(() => _posts = filtered);
    } catch (e) {
      debugPrint('Pager loadMore failed: $e');
    } finally {
      _loadingMore = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _verticalController,
        allowImplicitScrolling: true,
        scrollDirection: Axis.vertical,
        physics: _lockVertical
            ? const NeverScrollableScrollPhysics()
            : const PageScrollPhysics(),
        itemCount: _posts.length, // ← القائمة الداخلية
        findChildIndexCallback: (key) {
          final index = _posts.indexWhere((post) => ValueKey(post.id) == key);
          return index < 0 ? null : index;
        },
        onPageChanged: (i) {
          setState(() { _currentIndex = i; _lockVertical = false; });
          _maybeLoadMore(i);
        },
        itemBuilder: (context, index) {
          final post = _posts[index];
          final paths = [...post.imagePaths, ...post.videoPaths]
              .where((p) => p.trim().isNotEmpty)
              .toList();
          final mediaIndex = _mediaIndices[post.id] ??
              (index == widget.initialIndex ? widget.initialMediaIndex : 0);
          final sources = <String>{
            for (final i in [mediaIndex, mediaIndex + 1, mediaIndex - 1])
              if (i >= 0 &&
                  i < paths.length &&
                  Uri.tryParse(paths[i].trim())?.host ==
                      'firebasestorage.googleapis.com')
                paths[i].trim()
          }.toList();
          return _AuthorizedPagerMedia(
            key: ValueKey(post.id),
            postId: post.id,
            active: index == _currentIndex,
            prepare: _foreground && (index - _currentIndex).abs() <= 1,
            mediaSources: sources,
            onChecking: () {
              if (mounted && index == _currentIndex && _lockVertical) setState(() => _lockVertical = false);
            },
            onAuthorized: (fresh) {
              if (!mounted || index >= _posts.length || _posts[index].id != fresh.id) return;
              _posts[index] = fresh;
            },
            builder: (fresh, allowedActive, policyRevision, grant) => _PostPagerPage(
            key: ValueKey(
              post.id ??
                  '${post.author}_${post.createdAt.millisecondsSinceEpoch}',
            ),
            post: fresh,
            isActive: allowedActive,
              prepare: _foreground && (index - _currentIndex).abs() <= 1,
              policyRevision: policyRevision,
              mediaGrant: grant,
              onMediaIndexChanged: (i) => _mediaIndices[post.id] = i,
              initialMediaIndex: mediaIndex,
              onChanged: widget.onChanged,
              menuButton: widget.menuButton,
              onAuthorBlocked: _onAuthorBlocked,
              onPostHidden: hidePost,
              onLockScroll: (lock) {
                if (index == _currentIndex && _lockVertical != lock) {
                setState(() => _lockVertical = lock);
              }
            },
            ),
          );
        },
      ),
    );
  }
}

// ==================== صفحة منشور واحد داخل الـ Pager ====================

/// Exercises the real pager authorization/lifetime gate without Firebase I/O.
@visibleForTesting
Widget authorizedPagerMediaForTesting({
  required String postId,
  required bool active,
  required bool prepare,
  required Future<void> Function(String?) authorize,
  required String? Function() viewer,
  required Stream<String?> viewerChanges,
  required List<Listenable> policyChanges,
  required Widget Function(bool allowedActive, int policyRevision) builder,
  Future<PostMediaGrant> Function()? readBundle,
  ValueChanged<PostMediaGrant?>? observeGrant,
}) =>
    _AuthorizedPagerMedia(
      postId: postId,
      active: active,
      prepare: prepare,
      viewer: viewer,
      viewerChanges: viewerChanges,
      policyChanges: policyChanges,
      bundleLoader: readBundle,
      mediaSources: readBundle == null ? const [] : const ['source'],
      parsePost: (id, data) => _Post(
          id: id,
          author: '',
          title: '',
          body: '',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
          imagePaths: List<String>.from(data['imageUrls'] as List)),
      loadPost: (id) async {
        await authorize(id);
        return _Post(
            id: id,
            author: '',
            title: '',
            body: '',
            createdAt: DateTime.fromMillisecondsSinceEpoch(0),
            imagePaths: const ['test-image']);
      },
      onAuthorized: (_) {},
      onChecking: () {},
      builder: (_, allowedActive, revision, grant) {
        observeGrant?.call(grant);
        return builder(allowedActive, revision);
      },
    );

class _AuthorizedPagerMedia extends StatefulWidget {
  const _AuthorizedPagerMedia(
      {super.key, required this.postId, required this.active,
    required this.prepare, required this.builder, required this.onAuthorized,
      required this.onChecking,
      this.viewer,
      this.viewerChanges,
      this.policyChanges,
      this.loadPost,
      this.bundleLoader,
      this.parsePost,
      this.mediaSources = const []});
  final String? postId;
  final bool active, prepare;
  final Widget Function(_Post, bool, int, PostMediaGrant?) builder;
  final List<String> mediaSources;
  final Future<PostMediaGrant> Function()? bundleLoader;
  final _Post Function(String, Map<String, dynamic>)? parsePost;
  final ValueChanged<_Post> onAuthorized;
  final VoidCallback onChecking;
  final String? Function()? viewer;
  final Stream<String?>? viewerChanges;
  final List<Listenable>? policyChanges;
  final Future<_Post> Function(String?)? loadPost;
  @override
  State<_AuthorizedPagerMedia> createState() => _AuthorizedPagerMediaState();
}

class _AuthorizedPagerMediaState extends State<_AuthorizedPagerMedia> with WidgetsBindingObserver,
        AutomaticKeepAliveClientMixin<_AuthorizedPagerMedia> {
  _Post? _post;
  PostMediaGrant? _mediaGrant;
  String? _error, _viewer;
  bool _loading = false;
  int _generation = 0;
  int _policyRevision = 0;
  int _childGeneration = 0;
  bool _foreground = WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  StreamSubscription<String?>? _auth;
  late final List<Listenable> _policies;
  String? get _currentViewer => widget.viewer != null
      ? widget.viewer!()
      : FirebaseAuth.instance.currentUser?.uid;
  @override
  bool get wantKeepAlive => widget.prepare && _foreground;

  @override
  void initState() {
    super.initState();
    _viewer = _currentViewer;
    WidgetsBinding.instance.addObserver(this);
    _policies = widget.policyChanges ??
        [
          blockedListRevision,
          followRevision,
          moderationRevision,
          authorProfileRevision
        ];
    for (final policy in _policies) {
      policy.addListener(_invalidate);
    }
    _auth = (widget.viewerChanges ??
            FirebaseAuth.instance.authStateChanges().map((user) => user?.uid))
        .listen((uid) {
      if (mounted && uid != _viewer) _invalidate();
    });
    if (widget.prepare) _reload();
  }
  @override
  void didUpdateWidget(covariant _AuthorizedPagerMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateKeepAlive();
    if (oldWidget.postId != widget.postId || !widget.prepare) {
      _invalidate();
    } else if (oldWidget.active != widget.active || oldWidget.prepare != widget.prepare) {
      _reload();
    }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    updateKeepAlive();
    _invalidate();
  }

  void _invalidate() {
    if (!mounted) return;
    _mediaGrant?.seal();
    _mediaGrant = null;
    setState(() {
      _post = null;
      _error = null;
      _childGeneration++;
      _policyRevision++;
    });
    _reload();
  }
  Future<void> _reload() async {
    if (!mounted) return;
    final generation = ++_generation;
    _mediaGrant?.seal();
    _mediaGrant = null;
    final id = widget.postId;
    setState(() {
      _error = null;
      _loading =
          widget.prepare && _foreground && (widget.active || _post == null);
    });
    if (!widget.prepare || !_foreground || (!widget.active && _post != null))
      return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && generation == _generation) widget.onChecking();
    });
    if (_viewer == null || _viewer != _currentViewer) {
      setState(() { _loading = false; _error = "تغيّر الحساب، أعد فتح العارض"; });
      return;
    }
    bool current() => mounted && generation == _generation && widget.prepare &&
        _foreground &&
        id == widget.postId && _viewer == _currentViewer;
    try {
      PostMediaGrant? grant;
      if ((widget.loadPost == null || widget.bundleLoader != null) &&
          id != null &&
          widget.mediaSources.isNotEmpty) {
        try {
          grant = widget.bundleLoader != null
              ? await widget.bundleLoader!()
              : await PostMediaLinks.readBundle(id, widget.mediaSources);
        } on FirebaseFunctionsException catch (error) {
          // Stale media or an older backend recovers via a fresh projection.
          if (!['invalid-argument', 'permission-denied', 'not-found']
              .contains(error.code)) rethrow;
        }
      }
      final fresh = grant != null
          ? (widget.parsePost?.call(id!, grant.data) ??
              _Post.fromData(id!, grant.data))
          : widget.loadPost != null
              ? await widget.loadPost!(id)
              : _Post.fromData(id!, await _readAuthorizedPostData(id));
      if (!current()) return;
      if (fresh.imagePaths.isEmpty && fresh.videoPaths.isEmpty) {
        setState(() {
          _post = null;
          _loading = false; _error = mainText(context, "لم تعد هناك وسائط في هذا المنشور"); });
        return;
      }
      widget.onAuthorized(fresh);
      setState(() { _post = fresh; _loading = false;
        _mediaGrant = grant; });
    } on FirebaseFunctionsException catch (error) {
      if (!current()) return;
      setState(() {
        _post = null;
        _loading = false; _error = error.code == 'not-found'
          ? mainText(context, "المنشور لم يعد متاحاً") : mainText(context, "تعذر التحقق من عرض المنشور"); });
    } catch (_) {
      if (!current()) return;
      setState(() {
        _post = null;
        _loading = false; _error = mainText(context, "تعذر التحقق من عرض المنشور"); });
    }
  }
  @override
  void dispose() {
    _generation++;
    _mediaGrant?.seal();
    _auth?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    for (final policy in _policies) {
      policy.removeListener(_invalidate);
    }
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final allowed = widget.active &&
        widget.prepare &&
        _foreground &&
        !_loading &&
        _error == null &&
        _viewer != null &&
        _viewer == _currentViewer;
    // Seal after the frame that actually builds the recipients, not the frame
    // in which an asynchronous response happened to arrive.
    final grant = _mediaGrant;
    if (grant != null)
      WidgetsBinding.instance.addPostFrameCallback((_) => grant.seal());
    return Stack(fit: StackFit.expand, children: [
      const ColoredBox(color: Colors.black),
      if (_post != null)
        Offstage(
            offstage: !allowed,
            child: KeyedSubtree(
                key: ValueKey(_childGeneration),
                child: widget.builder(_post!, allowed, _policyRevision, _mediaGrant))),
      if (widget.active && !allowed)
        ColoredBox(color: Colors.black, child: SafeArea(child: Stack(children: [
      Center(child: _loading ? const CircularProgressIndicator() : Column(
        mainAxisSize: MainAxisSize.min, children: [
          Text(mainText(context, _error ?? "اسحب للانتقال إلى منشور آخر"), style: const TextStyle(color: Colors.white)),
          TextButton(onPressed: _reload, child:  Text(mainText(context, "إعادة المحاولة"))),
        ],
      )),
      Align(alignment: AlignmentDirectional.topStart, child: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.close, color: Colors.white), tooltip: mainText(context, "إغلاق"),
      )),
            ]))),
    ]);
  }
}

class _PostPagerPage extends StatefulWidget {
  const _PostPagerPage({
    super.key,
    required this.post,
    required this.isActive,
    required this.prepare,
    required this.policyRevision,
    this.mediaGrant,
    this.onMediaIndexChanged,
    this.initialMediaIndex = 0,
    this.onChanged,
    this.onLockScroll, // ← جديد
    this.menuButton,
    this.onAuthorBlocked,
    this.onPostHidden,
  });

  final _Post post;
  final bool isActive;
  final bool prepare;
  final int policyRevision;
  final PostMediaGrant? mediaGrant;
  final ValueChanged<int>? onMediaIndexChanged;
  final int initialMediaIndex;
  final VoidCallback? onChanged;
  final Widget? menuButton;
  final ValueChanged<bool>? onLockScroll;
  final void Function(String authorId)? onAuthorBlocked;
  final void Function(String postId)? onPostHidden;
  @override
  State<_PostPagerPage> createState() => _PostPagerPageState();
}

class _PostPagerPageState extends State<_PostPagerPage>
    with WidgetsBindingObserver {
  late final PageController _mediaController;
  late int _mediaIndex;

  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, VideoPlayerController> _preparingVideoControllers = {};
  final Map<int, Object> _signedVideoLoading = {};
  final Set<int> _signedVideoErrors = {};
  final Set<int> _videoAllowed = {};
  final Map<int, String> _videoSourceKeys = {};
  final Map<int, DateTime> _videoAuthorizedAt = {};
  int _accessAttempt = 0;
  final String? _viewer = FirebaseAuth.instance.currentUser?.uid;
  bool _foreground = WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  bool _isNavigatingComments = false;
  bool _controlsVisible = true;
  List<_PostMediaItem> _mediaItemsForPost(_Post post) {
    final items = <_PostMediaItem>[];
    for (final p in post.imagePaths) {
      if (p.trim().isNotEmpty) items.add(_PostMediaItem.image(p.trim()));
    }
    for (final p in post.videoPaths) {
      if (p.trim().isNotEmpty) items.add(_PostMediaItem.video(p.trim()));
    }
    return items;
  }
  List<_PostMediaItem> get _items => _mediaItemsForPost(widget.post);
  final Map<int, TransformationController> _zoomControllers = {};
  final Map<int, double> _currentScale = {};
  int _activePointers = 0;
  bool _isPinching = false;

  TransformationController _zoomFor(int index) {
    return _zoomControllers.putIfAbsent(index, () {
      final c = TransformationController();
      c.addListener(() {
        if (!mounted) return;

        final s = c.value.getMaxScaleOnAxis();

        // إذا رجع قريباً من الحجم الطبيعي → صفّر الموقع + المقياس
        if (s <= 1.02) {
          final m = c.value.storage;
          final hasTranslation =
              m[12].abs() > 0.5 || m[13].abs() > 0.5; // tx, ty
          if (s < 1.0 || hasTranslation || (s - 1.0).abs() > 0.001) {
            // تجنب حلقة لا نهائية: لا نعيد التعيين إن كان identity فعلاً
            if (hasTranslation || s < 0.999 || s > 1.001) {
              c.value = Matrix4.identity();
              _currentScale[index] = 1.0;
              setState(() {});
              _updateLock();
              return;
            }
          }
        }

        final prev = _currentScale[index] ?? 1.0;
        if ((prev - s).abs() > 0.001) {
          setState(() => _currentScale[index] = s);
          _updateLock();
        }
      });
      return c;
    });
  }

  void _resetZoom([int? index]) {
    final i = index ?? _mediaIndex;
    final c = _zoomControllers[i];
    if (c != null) {
      c.value = Matrix4.identity();
    }
    _currentScale[i] = 1.0;
    if (mounted) setState(() {});
    _updateLock();
  }

  bool get _isCurrentZoomed =>
      ((_currentScale[_mediaIndex] ?? 1.0) - 1.0).abs() > 0.05;

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
  }

  void _updateLock() {
    final lock = _isPinching || _isCurrentZoomed;
    widget.onLockScroll?.call(lock);
  }

  void _onPointerDown(PointerDownEvent event) {
    _activePointers++;
    if (_activePointers > 1) {
      setState(() => _isPinching = true);
      _updateLock();
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _activePointers = (_activePointers - 1).clamp(0, 10);
    if (_activePointers < 2 && _isPinching) {
      setState(() => _isPinching = false);
      // تأخير بسيط حتى ينتهي InteractiveViewer من آخر إطار
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _resetZoom();
      });
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _activePointers = (_activePointers - 1).clamp(0, 10);
    if (_activePointers < 2 && _isPinching) {
      setState(() => _isPinching = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _resetZoom();
      });
    }
  }

  Widget _buildImagePage(int index, String path) {
    final isNetwork =
        path.startsWith('http://') || path.startsWith('https://');
    final firebaseImage = Uri.tryParse(path)?.host == 'firebasestorage.googleapis.com';
    final imageWidget = firebaseImage
        ? AuthorizedPostImage(postId: widget.post.id!, url: path,
            active: widget.isActive && index == _mediaIndex,
            prepare: widget.prepare && (index - _mediaIndex).abs() <= 1,
            policyRevision: widget.policyRevision,
            grant: widget.mediaGrant)
        : isNetwork
            ? CachedNetworkImage(imageUrl: path, fit: BoxFit.contain)
            : Image.file(File(path), fit: BoxFit.contain);

    final zoomed = ((_currentScale[index] ?? 1.0) - 1.0).abs() > 0.05;

    return InteractiveViewer(
      transformationController: _zoomFor(index),
      maxScale: 10,
      minScale: 1,
      panEnabled: zoomed, // إصبع واحد = تحريك بعد التكبير فقط
      scaleEnabled: true, // إصبعان = تكبير
      boundaryMargin: const EdgeInsets.all(double.infinity),
      onInteractionEnd: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final s = _currentScale[index] ?? 1.0;
          if (s <= 1.05 || _activePointers < 2) {
            _resetZoom(index);
          }
        });
      },
      child: Center(child: imageWidget),
    );
  }

  Widget _buildVideoPage(int index) {
    if (_signedVideoErrors.contains(index)) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
         Text(mainText(context, "تعذر تحميل الفيديو"), style: TextStyle(color: Colors.white)),
        TextButton(onPressed: () => _initVideoAt(index), child:  Text(mainText(context, "إعادة المحاولة"))),
      ]));
    }
    final c = _videoControllers[index];
    if (c == null || !c.value.isInitialized ||
        !widget.isActive ||
        index != _mediaIndex ||
        !_videoAllowed.contains(index)) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white54),
      );
    }

    final zoomed = ((_currentScale[index] ?? 1.0) - 1.0).abs() > 0.05;
    final w = c.value.size.width;
    final h = c.value.size.height;

    return InteractiveViewer(
      transformationController: _zoomFor(index),
      maxScale: 8,
      minScale: 1,
      panEnabled: zoomed,
      scaleEnabled: true,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      onInteractionEnd: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final s = _currentScale[index] ?? 1.0;
          if (s <= 1.05 || _activePointers < 2) {
            _resetZoom(index);
          }
        });
      },
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: w > 0 ? w : 16,
            height: h > 0 ? h : 9,
            child: VideoPlayer(c),
          ),
        ),
      ),
    );
  }

  Future<void> _warmupAround(int index, {PostMediaGrant? grant}) async {
    if (!mounted || !widget.prepare) return;
    _trimVideos();
    await Future.wait([
      _initVideoAt(index, grant: grant),
      if (widget.isActive) _initVideoAt(index + 1, grant: grant),
      if (widget.isActive) _initVideoAt(index - 1, grant: grant)
    ]);

    // صور مجاورة (إن لم تكن في الكاش)
    for (final i in [index - 1, index, index + 1]) {
      if (i < 0 || i >= _items.length || (i - _mediaIndex).abs() > 1) continue;
      final item = _items[i];
      if (item.kind != _MediaKind.image) continue;
      final p = item.path.trim();
      if (p.startsWith('http') && mounted &&
          widget.prepare &&
          _foreground &&
          Uri.tryParse(p)?.host != 'firebasestorage.googleapis.com') {
        precacheImage(CachedNetworkImageProvider(p), context);
      }
    }
  }
  @override
  void initState() {
    super.initState();
    _mediaIndex = widget.initialMediaIndex.clamp(0, (_items.length - 1).clamp(0, 1 << 30));
    _mediaController = PageController(initialPage: _mediaIndex);
    WidgetsBinding.instance.addObserver(this);
    if (widget.prepare) _warmupAround(_mediaIndex, grant: widget.mediaGrant);
  }

  @override
  void didUpdateWidget(covariant _PostPagerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldItems = _mediaItemsForPost(oldWidget.post);
    final items = _items;
    final changed = oldItems.length != items.length ||
        List.generate(items.length, (i) => i).any((i) =>
            oldItems[i].path != items[i].path ||
            oldItems[i].kind != items[i].kind);
    if (changed) {
      _clearVideos();
      _mediaIndex = _mediaIndex.clamp(0, (items.length - 1).clamp(0, 1 << 30));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _mediaController.hasClients)
          _mediaController.jumpToPage(_mediaIndex);
      });
    }
    if (changed ||
        widget.isActive != oldWidget.isActive ||
        widget.policyRevision != oldWidget.policyRevision ||
        widget.prepare != oldWidget.prepare ||
        !identical(widget.mediaGrant, oldWidget.mediaGrant)) {
      _accessAttempt++;
      _videoAllowed.clear();
      _pauseAllVideos();
      _trimVideos();
      final grant = identical(widget.mediaGrant, oldWidget.mediaGrant)
          ? null
          : widget.mediaGrant;
      if (widget.prepare) _warmupAround(_mediaIndex, grant: grant);
      if (widget.isActive && _videoControllers.containsKey(_mediaIndex)) {
        _playCurrentVideo(grant: grant);
      }
    }
  }

  bool _canPrepareVideo(int index) =>
      mounted &&
      widget.prepare &&
      _foreground &&
      _viewer != null &&
      _viewer == FirebaseAuth.instance.currentUser?.uid &&
      index >= 0 &&
      index < _items.length &&
      (index == _mediaIndex ||
          (widget.isActive && (index - _mediaIndex).abs() <= 1));

  void _dropVideo(int index) {
    _signedVideoLoading.remove(index);
    _videoAllowed.remove(index);
    _videoSourceKeys.remove(index);
    _videoAuthorizedAt.remove(index);
    final controller = _videoControllers.remove(index);
    if (controller != null) unawaited(controller.dispose());
    final preparing = _preparingVideoControllers.remove(index);
    if (preparing != null) unawaited(preparing.dispose());
  }

  void _trimVideos() {
    for (final index in {
      ..._videoControllers.keys,
      ..._signedVideoLoading.keys
    }) {
      if (!_canPrepareVideo(index)) _dropVideo(index);
    }
  }

  void _clearVideos() {
    _accessAttempt++;
    for (final index in {
      ..._videoControllers.keys,
      ..._signedVideoLoading.keys
    }) {
      _dropVideo(index);
    }
    _signedVideoErrors.clear();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _clearVideos();
      if (mounted) setState(() {});
    }
  }

  Future<void> _initSignedVideoAt(int index, String path,
      {bool signed = true, String? authorizedUrl}) async {
    if (!_canPrepareVideo(index) || _signedVideoLoading.containsKey(index)) return;
    final load = Object();
    _signedVideoLoading[index] = load;
    final accessAttempt = _accessAttempt;
    final uid = _viewer;
    final postId = widget.post.id;
    bool current() =>
        _canPrepareVideo(index) &&
        identical(_signedVideoLoading[index], load) &&
        postId == widget.post.id && _items[index].path.trim() == path;
    VideoPlayerController? controller;
    setState(() => _signedVideoErrors.remove(index));
    var mediaStage = 'authorization';
    final mediaWatch = Stopwatch()..start();
    PerformanceProbe.elapsed('video_pager_authorization_start', mediaWatch);
    try {
      if (!current() || postId == null || uid == null)
        throw StateError('Video unavailable');
      final url = signed
          ? authorizedUrl ?? await PostMediaLinks.read(postId, path)
          : path;
      final authorizedAt = DateTime.now();
      if (!current()) return;
      controller = signed
          ? await createAuthorizedCachedVideo(url, uid)
          : createVideoPlaybackController(url);
      if (!current()) return;
      _preparingVideoControllers[index] = controller;
      mediaStage = 'player-initialize';
      PerformanceProbe.elapsed('video_pager_buffer_start', mediaWatch);
      try {
        await initializeVideoPlayback(controller);
      } catch (_) {
        if (!signed || controller.dataSourceType != DataSourceType.file)
          rethrow;
        // A damaged cached file must not trap retries on the same local bytes.
        await controller.dispose();
        await forgetAuthorizedVideo(url, uid);
        if (!current()) return;
        controller = createVideoPlaybackController(url);
        _preparingVideoControllers[index] = controller;
        await initializeVideoPlayback(controller);
      }
      await controller.setLooping(true);
      if (!current()) return;
      mediaStage = 'access-recheck';
      PerformanceProbe.elapsed('video_pager_buffer_ready', mediaWatch);
      // A prepared controller stays paused. Slow buffering never grants access.
      final fresh = _Post.fromData(postId, await _readAuthorizedPostData(postId));
      if (!current()) return;
      if (!fresh.videoPaths.any((p) => p.trim() == path)) throw StateError('Video removed');
      final ready = controller;
      _preparingVideoControllers.remove(index);
      _videoControllers[index] = ready;
      if (signed) {
        _videoSourceKeys[index] = authorizedMediaCacheKey(url, uid);
        _videoAuthorizedAt[index] = authorizedAt;
      }
      controller = null;
      if (PerformanceProbe.enabled)
        debugPrint(
            '[PERF] video_pager_prepared active=${widget.isActive && index == _mediaIndex}');
      observeVideoPlaybackError(ready, () {
        if (!mounted || !identical(_videoControllers[index], ready)) return;
        setState(() {
          _dropVideo(index);
          _signedVideoErrors.add(index);
        });
      });
      if (!current() || !identical(_videoControllers[index], ready)) return;
      if (widget.isActive &&
          index == _mediaIndex &&
          accessAttempt == _accessAttempt) {
        setState(() => _videoAllowed.add(index));
        await startVisibleVideo(ready,
            () => _mayPlay(index, ready) && accessAttempt == _accessAttempt);
        if (signed && _mayPlay(index, ready))
          unawaited(cacheAuthorizedVideo(url, uid));
      } else {
        setState(() {});
        if (widget.isActive && index == _mediaIndex) _playCurrentVideo();
      }
    } catch (error) {
      if (kDebugMode || PerformanceProbe.enabled) {
        final code = error is FirebaseException
            ? error.code
            : error is PlatformException
                ? error.code
                : 'none';
        debugPrint(
            '[VIDEO_FAILURE] surface=pager stage=$mediaStage type=${error.runtimeType} code=$code');
      }
      if (current()) setState(() {
          _dropVideo(index);
          _signedVideoErrors.add(index);
        });
    } finally {
      if (identical(_preparingVideoControllers[index], controller))
        _preparingVideoControllers.remove(index);
      await controller?.dispose();
      if (identical(_signedVideoLoading[index], load))
        _signedVideoLoading.remove(index);
    }
  }

  Future<void> _initVideoAt(int index, {PostMediaGrant? grant}) async {
    if (!_canPrepareVideo(index)) return;
    final item = _items[index];
    if (item.kind != _MediaKind.video || _videoControllers.containsKey(index)) return;

    final path = item.path.trim();
    if (path.isEmpty) return;
    await _initSignedVideoAt(index, path,
        authorizedUrl: grant?.link(_viewer ?? '', widget.post.id ?? '', path),
        signed: Uri.tryParse(path)?.host == 'firebasestorage.googleapis.com');
  }

  bool _mayPlay(int index, VideoPlayerController controller) =>
      !_isNavigatingComments &&
      _canPrepareVideo(index) &&
      widget.isActive && index == _mediaIndex &&
      _videoAllowed.contains(index) &&
      identical(_videoControllers[index], controller);

  Future<void> _playCurrentVideo({PostMediaGrant? grant}) async {
    final index = _mediaIndex;
    final controller = _videoControllers[index];
    if (_isNavigatingComments ||
        !widget.isActive ||
        !_canPrepareVideo(index) ||
        controller == null ||
        !controller.value.isInitialized) return;
    final attempt = ++_accessAttempt;
    final path = _items[index].path.trim();
    final postId = widget.post.id;
    String? authorizedUrl;
    final watch = Stopwatch()..start();
    final bundledUrl = grant?.link(_viewer ?? '', postId ?? '', path);
    bool current() =>
        attempt == _accessAttempt &&
        _canPrepareVideo(index) &&
        widget.isActive && index == _mediaIndex &&
        identical(_videoControllers[index], controller);
    setState(() {
      _videoAllowed.remove(index);
      _signedVideoErrors.remove(index);
    });
    try {
      await controller.pause();
      if (!current() || postId == null) return;
      if (Uri.tryParse(path)?.host == 'firebasestorage.googleapis.com') {
        // Renew authorization even when retaining bytes/controller state. An
        // overwrite at the same source path must never replay an old generation.
        final freshUrl = bundledUrl ?? await PostMediaLinks.read(postId, path);
        authorizedUrl = freshUrl;
        if (!current()) return;
        final changed = _videoSourceKeys[index] !=
            authorizedMediaCacheKey(freshUrl, _viewer!);
        final networkExpired =
            controller.dataSourceType == DataSourceType.network &&
                DateTime.now().difference(_videoAuthorizedAt[index] ??
                        DateTime.fromMillisecondsSinceEpoch(0)) >=
                    const Duration(minutes: 4);
        if (changed || networkExpired) {
          _dropVideo(index);
          await _initSignedVideoAt(index, path, authorizedUrl: freshUrl);
          return;
        }
        if (PerformanceProbe.enabled)
          debugPrint('[PERF] video_pager_controller_reuse active=true');
      } else {
        final fresh =
            _Post.fromData(postId, await _readAuthorizedPostData(postId));
        if (!current()) return;
        if (!fresh.videoPaths.any((p) => p.trim() == path))
          throw StateError('Video removed');
      }
      setState(() => _videoAllowed.add(index));
      await startVisibleVideo(
          controller, () => current() && _mayPlay(index, controller));
      if (current() && _mayPlay(index, controller)) {
        PerformanceProbe.elapsed('video_pager_activation_ready', watch);
        if (authorizedUrl != null)
          unawaited(cacheAuthorizedVideo(authorizedUrl, _viewer!));
      }
    } catch (_) {
      if (current())
        setState(() {
          _dropVideo(index);
          _signedVideoErrors.add(index);
        });
    }
  }

  void _pauseAllVideos() {
    for (final controller in _videoControllers.values) {
      unawaited(controller.pause());
    }
  }

  void _onMediaPageChanged(int index) {
    _accessAttempt++;
    _pauseAllVideos();
    setState(() {
      _mediaIndex = index;
      _videoAllowed.clear();
    });
    widget.onMediaIndexChanged?.call(index);
    _trimVideos();
    if (widget.prepare) _warmupAround(index);
    if (widget.isActive) _playCurrentVideo();
  }

  Future<void> _toggleLike() async {
    await _applyVote(widget.post, like: true);
    if (mounted) setState(() {});
    widget.onChanged?.call();
  }

  Future<void> _toggleDislike() async {
    await _applyVote(widget.post, like: false);
    if (mounted) setState(() {});
    widget.onChanged?.call();
  }

  Future<void> _openComments() async {
    if (_isNavigatingComments) return;
    _isNavigatingComments = true;
    _accessAttempt++;
    _videoAllowed.clear();
    _pauseAllVideos();
    try {
      await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CommentsScreen(post: widget.post)),
    );
    } finally {
      _isNavigatingComments = false;
    if (mounted) {
        setState(() {});
        if (widget.prepare) _warmupAround(_mediaIndex);
        if (widget.isActive) _playCurrentVideo();
        widget.onChanged?.call();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clearVideos();
    for (final c in _zoomControllers.values) {
      c.dispose();
    }
    _mediaController.dispose();
    super.dispose();
  }

  String _formatVotes(int votes) {
    if (votes >= 1000000) return '${(votes / 1000000).toStringAsFixed(1)}M';
    if (votes >= 1000) return '${(votes / 1000).toStringAsFixed(1)}k';
    return votes.toString();
  }
  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final items = _items;

    return Listener(
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: GestureDetector(
            onTap: _toggleControls,
            behavior: HitTestBehavior.translucent,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ===== الميديا =====
                Positioned.fill(
                  child: items.isEmpty
                      ? Container(color: Colors.black)
                      : PageView.builder(
                    controller: _mediaController,
                          allowImplicitScrolling: true,
                          physics: (_isPinching || _isCurrentZoomed)
                        ? const NeverScrollableScrollPhysics()
                        : const PageScrollPhysics(),
                    itemCount: items.length,
                          findChildIndexCallback: (key) {
                            final index = items.indexWhere((item) =>
                                ValueKey('${item.kind}:${item.path}') == key);
                            return index < 0 ? null : index;
                          },
                          onPageChanged: (i) {
                      _resetZoom(_mediaIndex);
                      _onMediaPageChanged(i);
                    },
                    itemBuilder: (context, index) {
                      final item = items[index];
                      if (item.kind == _MediaKind.image) {
                        return RetainedImageSlide(
                                key: ValueKey('${item.kind}:${item.path}'),
                                keepAlive: widget.prepare &&
                                    (index - _mediaIndex).abs() <= 1,
                                child: _buildImagePage(index, item.path),
                              );
                      }
                      return KeyedSubtree(
                                key: ValueKey('${item.kind}:${item.path}'),
                                child: _buildVideoPage(index));
                          },
                  ),
                ),

        // ===== شريط علوي =====
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AnimatedOpacity(
            opacity: _controlsVisible ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_controlsVisible,
              child: Container(
                width: double.infinity,
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
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        ),

        // ===== شريط سفلي (نفس الإخفاء) =====
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
                        if (items.length > 1) ...[
                          Center(
                            child: _DotsIndicator(
                              count: items.length,
                              activeIndex: _mediaIndex,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        _RedditStyleMeta(
                          authorName: post.author,
                          authorPhotoUrl: post.authorPhotoUrl,
                          postTitle: post.title,
                          postBody: post.body,
                        ),
                        if (items.isNotEmpty &&
                            items[_mediaIndex].kind == _MediaKind.video) ...[
                          const SizedBox(height: 12),
                          if (widget.isActive &&
                                      _videoAllowed.contains(_mediaIndex) &&
                                      _videoControllers[_mediaIndex] != null &&
                              _videoControllers[_mediaIndex]!
                                  .value
                                  .isInitialized)
                            _InlineVideoControls(
                              controller: _videoControllers[_mediaIndex]!,
                            ),
                        ],
                        const SizedBox(height: 12),
                        _FullscreenActionBar(
                          likeButtonKey: GlobalKey(),
                          tagsCount: post.tags.length,
                          onTagsTap: () =>
                              _showPostTagsSheet(context, post),
                          commentLabel: '${post.comments.length}',
                          onCommentTap: _openComments,
                          likeLabel: _formatVotes(post.votes),
                          isLiked: post.upvoted,
                          isDisliked: post.downvoted,
                          onLikeTap: _toggleLike,
                          onDislike: _toggleDislike,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
              ],
            )));
  }
}

// ==================== تفاعلات موحّدة (لايك/ديسلايك) قابلة لإعادة الاستخدام ====================

