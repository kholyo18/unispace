part of '../../main.dart';

class UnispaceScreen extends StatelessWidget {
  const UnispaceScreen({super.key, required this.onOpenDrawer});

  final VoidCallback onOpenDrawer;

  @override
  Widget build(BuildContext context) {
    return HomeLandingScreen(
      showAppBar: true,          // keep its own AppBar if you want
      bottomPadding: 116,
      onOpenDrawer: onOpenDrawer,
    );
  }
}

// ============================================================================
// PART 2/3 — Community (Campus) + Studies Navigator + Table Calculator
// ============================================================================






// ============================================================================
//                         Community-Screen
// ============================================================================
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key, required this.onOpenDrawer});

  final VoidCallback onOpenDrawer;

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with WidgetsBindingObserver {
  final _retention = FeedItemRetentionController();
  bool _publishing = false;
  Timer? _feedAccessTimer;
  int _feedGeneration = 0;
  int _blockRequest = 0;
  bool _refreshingFeed = false;
  String? _feedUid;
  StreamSubscription<User?>? _feedAuthSub;

  bool _isCurrentFeed(int generation, String? uid) =>
      mounted && generation == _feedGeneration &&
      uid == FirebaseAuth.instance.currentUser?.uid;


  final _scrollController = ScrollController();
  final List<_Post> _posts = [];
  Map<String, dynamic>? _lastDoc;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _initialLoading = true;
  String? _error;
  Set<String> _blockedIds = {};
  String? _pinPostId;

  Timer? _newPostsSub;
  final GlobalKey _searchButtonKey = GlobalKey();
  CollectionReference<Map<String, dynamic>> get _postsRef =>
      FirebaseFirestore.instance.collection('community_posts');


  Future<String> _uploadImage(Uint8List bytes, String postId, int index) async {
    try {
      validateMediaUploadSize(bytes.length, video: false);
      final uploadId = FirebaseFirestore.instance.collection('community_posts').doc().id;
      final storage = FirebaseStorage.instance;
      final ref = storage
          .ref()
          .child('community_posts')
          .child(postId)
          .child('images')
          .child('image_${uploadId}_$index.jpg');

      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e, stack) {
      rethrow;
    } catch (e, stack) {
      rethrow;
    }
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startFeedAccessTimer();
    _feedUid = FirebaseAuth.instance.currentUser?.uid;
    _loadInitial();
    _feedAuthSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted || user?.uid == _feedUid) return;
      _feedUid = user?.uid;
      _posts.clear();
      _blockedIds = {};
      _pinPostId = null;
      _loadInitial();
    });

    hiddenListRevision.addListener(_onHiddenListChanged);
    moderationRevision.addListener(_onHiddenListChanged);
    blockedListRevision.addListener(_onBlockedListChanged);
    authorProfileRevision.addListener(_onAuthorProfileChanged);
  }
  void _startFeedAccessTimer() {
    _feedAccessTimer?.cancel();
    _feedAccessTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true &&
          TickerMode.of(context)) {
        _recheckFeedAccess();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startFeedAccessTimer();
      _recheckFeedAccess();
    } else {
      _feedAccessTimer?.cancel();
    }
  }

  Future<void> _recheckFeedAccess() async {
    if (!mounted || _refreshingFeed || _initialLoading) return;
    if (_error != null) {
      await _loadInitial();
      return;
    }
    if (_posts.isEmpty) return;
    final generation = ++_feedGeneration;
    final me = FirebaseAuth.instance.currentUser?.uid;
    final existing = List<_Post>.from(_posts);
    _newPostsSub?.cancel();
    setState(() {
      _refreshingFeed = true;
      _loadingMore = false;
    });
    try {
      final allowed = await _filterFeedPosts(existing, generation, me);
      if (!_isCurrentFeed(generation, me)) return;
      final allowedIds = allowed.map((p) => p.id).toSet();
      setState(() {
        // Only remove: do not restore posts hidden/deleted while awaiting checks.
        _posts.removeWhere((p) => !allowedIds.contains(p.id));
        _refreshingFeed = false;
      });
      _listenForNewPosts(generation, me);
    } catch (_) {
      if (!_isCurrentFeed(generation, me)) return;
      setState(() {
        _posts.clear();
        _refreshingFeed = false;
        _error = mainText(context, "تعذر التحقق من صلاحية عرض المنشورات");
      });
    }
  }

  void _onAuthorProfileChanged() {
    if (mounted) _loadInitial();
  }
  void _onHiddenListChanged() {
    if (mounted) _loadInitial(showFullLoader: false);
  }
// في CommunityScreen
  void _onBlockedListChanged() {
    if (mounted) _loadInitial();
  }
  @override
  void dispose() {
    _retention.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _feedAccessTimer?.cancel();
    _feedGeneration++;
    _feedAuthSub?.cancel();
    authorProfileRevision.removeListener(_onAuthorProfileChanged);
    blockedListRevision.removeListener(_onBlockedListChanged);
    hiddenListRevision.removeListener(_onHiddenListChanged);
    moderationRevision.removeListener(_onHiddenListChanged);
    _scrollController.dispose();
    _newPostsSub?.cancel();
    super.dispose();
  }

  Future<Map<String, dynamic>> _readFeedPage(Map<String, dynamic>? cursor,
      {int? pageSize}) async {
    final watch = Stopwatch()..start();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final page = await requestFeedPage(
        cursor: cursor,
        pageSize: pageSize,
        call: (data) async =>
            (await FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('readContentFeedPage', options: HttpsCallableOptions(
          timeout: const Duration(seconds: 120),
                        ))
                    .call<Map<String, dynamic>>(data))
                .data);
    PerformanceProbe.elapsed('feed_server', watch);
    if (uid != FirebaseAuth.instance.currentUser?.uid || page['posts'] is! List ||
        page['exhausted'] is! bool ||
        (page['cursor'] != null && page['cursor'] is! Map) ||
        (page['exhausted'] == false && page['cursor'] == null)) {
      throw StateError(mainText(context, "تعذر تأكيد صفحة الخلاصة"));
    }
    return page;
  }

  Future<FreshFeedPage?> _readFreshPage(
          Map<String, dynamic>? cursor, int generation, String? me,
          {int? pageSize}) =>
      loadFreshFeedPage(
        readPage: () => _readFeedPage(cursor, pageSize: pageSize),
        readHidden: loadHiddenPostIds,
        readBlocked: loadBlockedUserIds,
        isCurrent: () => _isCurrentFeed(generation, me),
      );
  List<_Post> _feedPagePosts(Map<String, dynamic> page) =>
      (page['posts'] as List).map((row) {
        if (row is! Map || row['id'] is! String || row['data'] is! Map) {
          throw StateError(mainText(context, "بيانات منشور غير صالحة"));
        }
        return _Post.fromData(row['id'] as String,
            Map<String, dynamic>.from(row['data'] as Map));
      }).toList();

  Future<void> _loadInitial({bool showFullLoader = true}) async {
    if (!mounted) return;
    _retention.clear();
    final generation = ++_feedGeneration;
    final me = FirebaseAuth.instance.currentUser?.uid;
    _newPostsSub?.cancel();
    setState(() {
      _refreshingFeed = true;
      _loadingMore = false;
      _lastDoc = null;
      _blockedIds = {};
      if (showFullLoader || _posts.isEmpty) _initialLoading = true;
      _error = null;
    });

    try {
      final watch = Stopwatch()..start();
      final freshPage = await _readFreshPage(null, generation, me, pageSize: 8);
      if (freshPage == null) return;
      final page = freshPage.page;

      final list = await _filterFeedPosts(_feedPagePosts(page), generation, me,
          freshPage: freshPage);
      PerformanceProbe.elapsed('feed_ready', watch);
      if (!_isCurrentFeed(generation, me)) return;
      final ordered = _ordered(list);

      setState(() {
        _refreshingFeed = false;
        _posts
          ..clear()
          ..addAll(ordered);
        _lastDoc = page['cursor'] == null ? null : Map<String, dynamic>.from(page['cursor'] as Map);
        _hasMore = page['exhausted'] == false;
        _initialLoading = false;
      });
      _newPostsSub?.cancel();
      _listenForNewPosts(generation, me);
      _precacheImages(ordered);
      _prefetchFirstVideos(ordered);
    } catch (e) {
      if (!_isCurrentFeed(generation, me)) return;
      if (kDebugMode) {
        if (e is FirebaseException) {
          debugPrint('[FEED_ERROR] ${e.plugin}/${e.code}');
          debugPrint('[FEED_MESSAGE] ${e.message ?? "No message"}');
        } else {
          debugPrint('[FEED_ERROR] ${e.runtimeType}');
        }
      }
      setState(() {
        _refreshingFeed = false;
        _posts.clear();
        _error = e.toString();
        _initialLoading = false;
      });

    }
  }

  Future<List<_Post>> loadMoreForPager() async {
    await _loadMore();
    return List<_Post>.from(_posts);
  }
  Future<void> _loadMore() async {
    if (!mounted || _refreshingFeed || _initialLoading || _error != null || _loadingMore || !_hasMore || _lastDoc == null) return;

    final generation = _feedGeneration;
    final me = FirebaseAuth.instance.currentUser?.uid;
    final cursor = _lastDoc!;
    setState(() => _loadingMore = true);

    try {
      final freshPage = await _readFreshPage(cursor, generation, me);
      if (freshPage == null) return;
      final page = freshPage.page;

      final list = await _filterFeedPosts(_feedPagePosts(page), generation, me,
          freshPage: freshPage);
      if (!_isCurrentFeed(generation, me)) return;
      final existingIds = _posts.map((p) => p.id).toSet();
      final extra = list.where((p) => !existingIds.contains(p.id)).toList()
        ..shuffle();

      setState(() {
        _posts.addAll(extra);
        _lastDoc = page['cursor'] == null ? null : Map<String, dynamic>.from(page['cursor'] as Map);
        _hasMore = page['exhausted'] == false;
        _loadingMore = false;
      });

      _precacheImages(list);
      _prefetchFirstVideos(list);
    } catch (e) {
      if (!_isCurrentFeed(generation, me)) return;
      setState(() => _loadingMore = false);
      debugPrint('loadMore failed: $e');
    }
  }
  void _prefetchFirstVideos(List<_Post> posts) {
    // لا await في الحلقة حتى لا تُحظر الواجهة
    for (final post in posts.take(1)) {
      final urls = [
        ...post.videoPaths,
        ...post.pollSlides
            .where((s) => s['type']?.toString() == 'video')
            .map((s) => (s['url'] ?? s['mediaPath'] ?? '').toString()),
      ];
      final first = urls.map((e) => e.trim()).firstWhere(
            (u) => u.startsWith('http'),
        orElse: () => '',
      );
      // Firebase video delivery is authorized when its card becomes visible.
      if (first.isEmpty || Uri.tryParse(first)?.host == 'firebasestorage.googleapis.com') continue;

      // في الخلفية — DefaultCacheManager يتجاهل إن وُجد في الكاش
      DefaultCacheManager().getSingleFile(first).then((_) {}, onError: (_) {});
    }
  }

  // Recheck current server-side audience decisions for every loaded batch.
  Future<List<_Post>> _filterFeedPosts(
    List<_Post> raw, int generation, String? me,
      {FreshFeedPage? freshPage}) async {
    if (!_isCurrentFeed(generation, me)) return [];
    final filters = freshPage == null
        ? await Future.wait([loadHiddenPostIds(), loadBlockedUserIds()])
        : [freshPage.hidden, freshPage.blocked];
    final hidden = filters[0];
    final blocked = filters[1];
    if (!_isCurrentFeed(generation, me)) return [];
    final candidates = raw.where((p) {
      final id = p.id?.trim();
      return id != null && id.isNotEmpty && !hidden.contains(id) &&
          !isBlockedPost(p, blocked) && !isBlockedPost(p, _blockedIds);
    }).toList();
    // Trust only a freshly returned page with explicit server boundary checks.
    // Periodic/resume rechecks and older servers retain the full path below.
    if (freshPage?.authorAccessRechecked == true) return candidates;
    final authors = <String>{
      ...candidates.map((p) => (p.authorId ?? '').trim()),
      ...candidates.where((p) => p.isRepost).map(
        (p) => (p.repostOf?['authorId'] ?? '').toString().trim(),
      ),
    }..remove('');
    final ids = authors.toList();
    final allowed = <String>{};
    // No persistent permission cache; cap concurrent callable requests.
    for (var i = 0; i < ids.length; i += 5) {
      if (!_isCurrentFeed(generation, me)) return [];
      final end = i + 5 < ids.length ? i + 5 : ids.length;
      await Future.wait(ids.sublist(i, end).map((author) async {
        try {
          final profile = await PublicProfileService.load(author);
          if (profile['canViewContent'] == true) allowed.add(author);
        } on FirebaseFunctionsException catch (error) {
          // Unavailable/blocked accounts are omitted; transport and session
          // errors must reach the loader instead of looking like an empty feed.
          if (error.code != 'not-found') rethrow;
        }
      }));
    }
    if (!_isCurrentFeed(generation, me)) return [];
    return candidates.where((p) {
      if (isBlockedPost(p, _blockedIds)) return false;
      if (!allowed.contains((p.authorId ?? '').trim())) return false;
      if (p.isRepost && !allowed.contains(
        (p.repostOf?['authorId'] ?? '').toString().trim(),
      )) return false;
      return true;
    }).toList();
  }

  List<_Post> _ordered(List<_Post> input) {
    _Post? pinned;
    final rest = <_Post>[];
    for (final p in input) {
      if (_pinPostId != null && p.id == _pinPostId) {
        pinned = p;
      } else {
        rest.add(p);
      }
    }
    rest.shuffle();
    return [
      if (pinned != null) pinned,
      ...rest,
    ];
  }
  void _precacheImages(List<_Post> posts) {
    // Firebase images resolve authorized links in the card, not during feed prefetch.
    for (final post in posts.take(3)) {
      for (final url in post.imagePaths.take(2)) {
        final u = url.trim();
        if (u.startsWith('http') && Uri.tryParse(u)?.host != 'firebasestorage.googleapis.com') {
          precacheImage(CachedNetworkImageProvider(u), context);
        }
      }

      for (final s in post.pollSlides.take(2)) {
        if (s['type']?.toString() != 'image') continue;
        final u = (s['url'] ?? s['mediaPath'] ?? '').toString().trim();
        if (u.startsWith('http') && Uri.tryParse(u)?.host != 'firebasestorage.googleapis.com') {
          precacheImage(CachedNetworkImageProvider(u), context);
        }
      }
    }
  }



  /// منشورات جديدة تُضاف في الأعلى بدون إعادة تحميل الكل
  void _listenForNewPosts(int generation, String? me) {
    _newPostsSub?.cancel();
    var loading = false;
    _newPostsSub = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (loading || !_isCurrentFeed(generation, me) || _refreshingFeed ||
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed ||
          ModalRoute.of(context)?.isCurrent != true || !TickerMode.of(context)) return;
      loading = true;
      try {
        final freshPage = await _readFreshPage(null, generation, me);
        if (freshPage == null) return;
        final page = freshPage.page;
        if (!_isCurrentFeed(generation, me)) return;
        await _applyNewPosts(_feedPagePosts(page), generation, me, freshPage);
      } catch (_) {
        if (!_isCurrentFeed(generation, me)) return;
        _feedGeneration++;
        _newPostsSub?.cancel();
        setState(() {
          _posts.clear();
          _loadingMore = false;
          _error = mainText(context, "تعذر تحديث المنشورات بأمان");
        });
      } finally {
        loading = false;
      }
    });
  }

  Future<void> _applyNewPosts(
    List<_Post> posts, int generation, String? me,
    FreshFeedPage freshPage,
  ) async {
      final newest = await _filterFeedPosts(posts, generation, me, freshPage: freshPage);
      if (!_isCurrentFeed(generation, me)) return;
      if (newest.isEmpty) return;

      final toAdd = <_Post>[];
      for (final p in newest.reversed) {
        if (!_posts.any((e) => e.id == p.id)) {
          toAdd.add(p);
        }
      }
      if (toAdd.isEmpty) return;

      setState(() {
        for (final p in toAdd) {
          if (p.authorId == me || p.id == _pinPostId) {
            _posts.insert(0, p);
          } else {
            final i = _posts.isEmpty
                ? 0
                : 1 + (DateTime.now().microsecondsSinceEpoch % _posts.length);
            _posts.insert(i.clamp(0, _posts.length), p);
          }
        }
      });
      _precacheImages(toAdd);
  }



  Future<String> _uploadVideo(String localPath, String postId, int index) async {
    final file = File(localPath);
    if (!await file.exists()) {
      throw Exception('Video file not found: $localPath');
    }

    final extension = localPath.split('.').last.toLowerCase();
    validateMediaUploadSize(await file.length(), video: true);
    final contentType = postVideoContentType(extension);
    final uploadId = FirebaseFirestore.instance.collection('community_posts').doc().id;

    final ref = FirebaseStorage.instance
        .ref().child('community_posts/$postId/videos/video_${uploadId}_$index.$extension');

    await ref.putFile(file, SettableMetadata(contentType: contentType));
    return await ref.getDownloadURL();
  }

  Future<void> _newPost() async {
    if (_publishing) return;

    final result = await Navigator.of(context).push<List<PostItem>>(
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );

    if (!mounted || result == null || result.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(mainText(context, "يجب تسجيل الدخول أولاً"))),
      );
      return;
    }

    String title = '';
    String body = '';
    final outsideImages = <Uint8List>[];
    final outsideVideos = <String>[]; // مسارات محلية
    List<PollData> pollDataList = [];
    List<Map<String, dynamic>> pollSlides = [];
    List<String> postTags = [];

    for (final item in result) {
      switch (item.type) {
        case PostItemType.text:
          final text = item.title.trim();
          if (text.isEmpty) break;
          if (title.isEmpty) {
            title = text;
          } else {
            body = body.isEmpty ? text : '$body\n$text';
          }
          break;

        case PostItemType.image:
          if (item.imageBytes != null) outsideImages.add(item.imageBytes!);
          break;

        case PostItemType.video:
          if (item.mediaPath != null && item.mediaPath!.isNotEmpty) {
            outsideVideos.add(item.mediaPath!);
          }
          break;

        case PostItemType.poll:
          pollDataList = item.pollDataList ?? [];
          pollSlides = List<Map<String, dynamic>>.from(item.pollSlides ?? []);
          break;

        case PostItemType.tags:
          postTags = item.tags ?? [];
          break;
      }
    }

    final hasContent = title.isNotEmpty ||
        body.isNotEmpty ||
        outsideImages.isNotEmpty ||
        outsideVideos.isNotEmpty ||
        pollDataList.isNotEmpty ||
        pollSlides.isNotEmpty;

    if (!hasContent) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(mainText(context, "المنشور فارغ"))),
      );
      return;
    }
    setState(() => _publishing = true);
    DocumentReference<Map<String, dynamic>>? postRef;
    var publicationConfirmed = false;
    final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');

    try {
      postRef = _postsRef.doc();

      final reservation = await functions.httpsCallable('reserveOwnPost')
          .call<Map<String, dynamic>>({'postId': postRef.id});
      if (FirebaseAuth.instance.currentUser?.uid != user.uid ||
          reservation.data['postId'] != postRef.id || reservation.data['reserved'] != true) {
        throw StateError(mainText(context, "تعذر تأكيد بدء النشر"));
      }

      // ===== 1) رفع وسائط خارج البول =====
      final imageUrls = <String>[];
      for (int i = 0; i < outsideImages.length; i++) {
        final url = await _uploadImage(outsideImages[i], postRef.id, i);
        imageUrls.add(url);
      }

      final videoUrls = <String>[];
      for (int i = 0; i < outsideVideos.length; i++) {
        final url = await _uploadVideo(outsideVideos[i], postRef.id, i);
        videoUrls.add(url);
      }

      // ===== 2) رفع شرائح البول بالترتيب =====
      final resolvedSlides = <Map<String, dynamic>>[];
      int pollImg = 0;
      int pollVid = 0;

      for (final s in pollSlides) {
        final type = s['type']?.toString();

        if (type == 'text') {
          final t = s['text']?.toString() ?? '';
          if (t.isNotEmpty) {
            resolvedSlides.add({'type': 'text', 'text': t});
          }
        } else if (type == 'poll') {
          resolvedSlides.add({
            'type': 'poll',
            'pollIndex': s['pollIndex'],
          });
        } else if (type == 'image') {
          final path = s['mediaPath']?.toString() ?? s['path']?.toString();
          if (path != null && path.isNotEmpty) {
            final file = File(path);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              final url = await _uploadImage(bytes, postRef.id, 1000 + pollImg);
              pollImg++;
              resolvedSlides.add({'type': 'image', 'url': url});
            }
          } else if (s['imageBytes'] is Uint8List) {
            final url = await _uploadImage(
              s['imageBytes'] as Uint8List,
              postRef.id,
              1000 + pollImg,
            );
            pollImg++;
            resolvedSlides.add({'type': 'image', 'url': url});
          }
        } else if (type == 'video') {
          final path = s['mediaPath']?.toString() ?? s['path']?.toString();
          if (path != null && path.isNotEmpty) {
            final url = await _uploadVideo(path, postRef.id, 1000 + pollVid);
            pollVid++;
            resolvedSlides.add({'type': 'video', 'url': url});
          }
        } else if (type == 'text') {
          final t = s['text']?.toString() ?? '';
          if (t.isNotEmpty) {
            resolvedSlides.add({'type': 'text', 'text': t});
          }
        }
      }
      if (FirebaseAuth.instance.currentUser?.uid != user.uid) {
        throw StateError(mainText(context, "تغير الحساب أثناء النشر"));
      }
      final publication = await functions.httpsCallable('publishOwnPost')
          .call<Map<String, dynamic>>({
        'postId': postRef.id,
        'content': {
          'title': title,
          'body': body,
          'imageUrls': imageUrls,
          'videoUrls': videoUrls,
          'pollSlides': resolvedSlides,
          'polls': pollDataList.map(_pollToMap).toList(),
          'tags': postTags,
        },
      });
      if (FirebaseAuth.instance.currentUser?.uid != user.uid ||
          publication.data['postId'] != postRef.id || publication.data['published'] != true) {
        throw StateError(mainText(context, "تعذر تأكيد نشر المنشور"));
      }
      publicationConfirmed = true;

      _pinPostId = postRef.id;
      await _loadInitial(showFullLoader: false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).post)),
      );

    } catch (e, stack) {
      debugPrintStack(stackTrace: stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is MediaUploadValidation ? serviceErrorText(context, e) : publicationConfirmed
              ? mainText(context, "تم نشر المنشور، لكن تعذر تحديث القائمة. حدّث الصفحة.")
              : mainText(context, "تعذر تأكيد النشر. حدّث الصفحة قبل إعادة المحاولة."))),
        );
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _deletePost(_Post post) async {
    final id = post.id;
    if (id == null || id.isEmpty) throw StateError(mainText(context, "تعذر تحديد المنشور"));
    await _deleteOwnPost(id);
  }

  List<_Post> _visiblePosts(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final List<_Post> posts = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final status = data['status']?.toString().trim().toLowerCase();

      if (status == 'uploading') continue;

      try {
        posts.add(_Post.fromFirestore(doc));
      } catch (e, stack) {
        debugPrintStack(stackTrace: stack);
        posts.add(
          _Post(
            id: doc.id,
            author: (data['authorName'] ?? data['author'] ?? mainText(context, "طالب UniSpace"))
                .toString(),
            authorId: data['authorId']?.toString(),
            authorPhotoUrl: data['authorPhotoUrl']?.toString(),
            title: (data['title'] ?? '').toString(),
            body: (data['body'] ?? '').toString(),
            authorAppearInSearch: data['authorAppearInSearch'] != false,
            createdAt: data['createdAt'] is Timestamp
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
            imagePaths: _stringList(data['imageUrls']),
            videoPaths: _stringList(data['videoUrls']),
            tags: _stringList(data['tags']),
            votes: (data['votes'] as num?)?.toInt() ?? 0,
            isRepost: data['isRepost'] == true,
            repostOf: data['repostOf'] is Map
                ? Map<String, dynamic>.from(data['repostOf'] as Map)
                : null,
          ),
        );
      }
    }

    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  void _openAiSearch() async {
    final RenderBox? box =
    _searchButtonKey.currentContext?.findRenderObject() as RenderBox?;

    Rect? originRect;
    if (box != null && box.hasSize) {
      final offset = box.localToGlobal(Offset.zero);
      originRect = offset & box.size;
    }

    await Navigator.of(context).push(
      _ExpandSearchRoute(
        originRect: originRect,
        child: const RedditStyleAiSearchScreen(),
      ),
    );

    // بعد الرجوع من البحث → حدّث المنشورات
    if (mounted) {
      _loadInitial();
    }
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppGuide(id: 'feed', steps: const [GuideStep('feed.menu', 'feed.menu'),GuideStep('feed.create', 'feed.create')], child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: DecoratedBox(
          // ← تدرّج واحد للصفحة كاملة، من فوق (AppBar) لتحت (body)
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                 AppTeal.main.withValues(alpha: 0.3),
                theme.scaffoldBackgroundColor,
              ]
                  : [
                 AppTeal.main.withValues(alpha: 0.16),
                theme.scaffoldBackgroundColor,
              ],
              stops: const [0.0, 0.6], // يخفت بسرعة، بلا رجوع للأبيض
            ),
          ),
          child:RefreshIndicator(
              color: AppTeal.main,
              notificationPredicate: (n) => n.depth == 1,
              onRefresh: () {
                _pinPostId = null;
                return _loadInitial(showFullLoader: false);
              },
              child: NestedScrollView(
            controller: _scrollController,
            floatHeaderSlivers: true,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [const SliverToBoxAdapter(
                child: SizedBox(height: 0),
              ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child:

                  SliverAppBar(
                    pinned: false,
                    floating: true,
                    snap: true,
                    forceElevated: innerBoxIsScrolled,
                    automaticallyImplyLeading: false,
                    titleSpacing: 0,
                    toolbarHeight: 40,
                    backgroundColor: Colors.transparent, // ← شفاف، التدرّج من ورا
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    title: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          GuideTarget(id: 'feed.menu', child: IconButton(
                            icon: const Icon(Icons.menu),
                            onPressed: widget.onOpenDrawer,
                            visualDensity: VisualDensity.compact,
                          )),
                          const SizedBox(width: 46),
                          Expanded(
                            child: Center(
                              child: Icon(
                                Icons.groups, // أيقونة القبعة/التخرج
                                color: Theme.of(context).colorScheme.primary,
                                size: 26,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                key: _searchButtonKey,
                                icon: const Icon(Icons.search_outlined),
                                onPressed: _openAiSearch,
                                visualDensity: VisualDensity.compact,
                              ),

                              const SizedBox(width: 0),
                              GuideTarget(id: 'feed.create', child: IconButton(

                                icon:  Icon(Icons.add_rounded,
                                    color: Theme.of(context)
                                            .colorScheme.onSurface, size: 30),

                                onPressed: _publishing ? null : _newPost,
                                tooltip: mainText(context, "إنشاء منشور"),
                                visualDensity: VisualDensity.compact,
                              )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                ),
              ];
            },
            body: Directionality(
              textDirection: TextDirection.ltr,
              child: Container(
                color: Colors.transparent,
                child: FeedPaginationListener(
                        onLoadMore: _loadMore,
                        child: _buildFeedBody()), // ← هنا فقط
              ),
            ),
          )),
        )));
  }
  Widget _buildFeedBody() {
    if (_initialLoading) {
      return const _FeedSkeleton();
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
             Text(mainText(context, "تعذر تحميل المنشورات بأمان"), textAlign: TextAlign.center),
            TextButton(onPressed: () => _loadInitial(), child:  Text(mainText(context, "إعادة المحاولة"))),
          ]),
        ),
      );
    }

    if (_posts.isEmpty) {
      return CustomScrollView(
        slivers: [
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  _CommunityHeader(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 152),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _CommunityEmptyState(onCreatePost: _newPost),
                if (_hasMore) TextButton(
                  onPressed: _loadingMore ? null : _loadMore,
                  child: Text(_loadingMore ? mainText(context, "جارٍ التحميل...") : mainText(context, "عرض منشورات أقدم")),
                ),
              ]),
            ),
          ),
        ],
      );
    }

    final postIndices = {
      for (var i = 0; i < _posts.length; i++) _posts[i].id: i
    };
    return CustomScrollView(
      cacheExtent: 1500,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                const _CommunityHeader(),
                if (_publishing) ...[

                  const LinearProgressIndicator(),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 152),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                if (index == _posts.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Center(
                      child: _loadingMore
                          ? const CircularProgressIndicator()
                          : (!_hasMore
                          ? Text(
                        mainText(context, "لا مزيد من المنشورات"),
                        style: TextStyle(color: Colors.grey.shade600),
                      )
                          : const SizedBox.shrink()),
                    ),
                  );
                }

                final post = _posts[index];
                return RetainedFeedItem(
                  key: ValueKey<String>(post.id!),
                  id: post.id!,
                  controller: _retention,
                  child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: ClipRRect(
                    borderRadius: index == 0
                        ? const BorderRadius.vertical(top: Radius.circular(20))
                        : BorderRadius.zero,
                    child: _PostCard(
                      post: post,
                      onChanged: () async {
                        final generation = _feedGeneration;
                        final me = FirebaseAuth.instance.currentUser?.uid;
                        final request = ++_blockRequest;
                        try {
                          final blocked = await loadBlockedUserIds();
                          if (!_isCurrentFeed(generation, me) || request != _blockRequest) return;
                          setState(() {
                            _blockedIds = blocked;
                            _posts.removeWhere(
                                  (p) => isBlockedPost(p, blocked));
                          });
                        } catch (_) {
                          if (!_isCurrentFeed(generation, me) || request != _blockRequest) return;
                          _feedGeneration++;
                          _newPostsSub?.cancel();
                          setState(() { _posts.clear(); _error = mainText(context, "تعذر التحقق من قائمة الحظر"); });
                        }
                      },
                      onDelete: () async {
                        await _deletePost(post);
                        if (!mounted) return;
                        setState(() {
                          _posts.removeWhere((p) => p.id == post.id);
                        });
                      },
                      onHidden: () {
                        setState(() {
                          _posts.removeWhere((p) => p.id == post.id);
                        });
                      },
                      feedPosts: _posts,
                      onLoadMoreFeed: _loadMore,
                    ),
                  ),
                  ),
                );
              },
              findChildIndexCallback: (key) =>
                  key is ValueKey<String> ? postIndices[key.value] : null,
              childCount: _posts.length + 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => const _SkeletonPostCard(),
    );
  }
}

class _SkeletonPostCard extends StatefulWidget {
  const _SkeletonPostCard();

  @override
  State<_SkeletonPostCard> createState() => _SkeletonPostCardState();
}

class _SkeletonPostCardState extends State<_SkeletonPostCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(_c),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: base, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 120, height: 10, color: base),
                      const SizedBox(height: 8),
                      Container(width: 72, height: 8, color: base),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(width: double.infinity, height: 12, color: base),
            const SizedBox(height: 8),
            Container(width: 180, height: 12, color: base),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}








class _RedditStylePostCard extends StatefulWidget {
  const _RedditStylePostCard({
    required this.post,
    required this.accent,
    this.onUnsave,
  });

  final _Post post;
  final Color accent;
  final VoidCallback? onUnsave;
  @override
  State<_RedditStylePostCard> createState() => _RedditStylePostCardState();
}

class _RedditStylePostCardState extends State<_RedditStylePostCard> {
  late int _score;
  late bool _isLiked;
  late bool _isDisliked;

  @override
  void initState() {
    super.initState();
    _score = widget.post.votes;
    _isLiked = widget.post.upvoted;
    _isDisliked = widget.post.downvoted;
    final id = widget.post.authorId?.trim() ?? '';
    if (id.isNotEmpty) AuthorProfiles.ensure(id);
  }

  @override
  void didUpdateWidget(covariant _RedditStylePostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.votes != widget.post.votes ||
        oldWidget.post.upvoted != widget.post.upvoted ||
        oldWidget.post.downvoted != widget.post.downvoted) {
      _score = widget.post.votes;
      _isLiked = widget.post.upvoted;
      _isDisliked = widget.post.downvoted;
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return mainText(context, "{0} ي", <Object?>[diff.inDays]);
    if (diff.inHours > 0) return mainText(context, "{0} س", <Object?>[diff.inHours]);
    if (diff.inMinutes > 0) return mainText(context, "{0} د", <Object?>[diff.inMinutes]);
    return mainText(context, "الآن");
  }

  String _authorLabel(String author) {
    final cleaned = author.trim();
    if (cleaned.isEmpty || cleaned == 'current_user') return mainText(context, "طالب UniSpace");
    return cleaned.replaceFirst(RegExp(r'^u/'), '');
  }

  bool get _hasMedia {
    final p = widget.post;
    return p.imagePaths.any((s) => s.trim().isNotEmpty) ||
        p.videoPaths.any((s) => s.trim().isNotEmpty) ||
        p.pollSlides.isNotEmpty ||
        p.pollDataList.isNotEmpty;
  }

  String? get _firstImageUrl {
    for (final u in widget.post.imagePaths) {
      final s = u.trim();
      if (s.startsWith('http')) return s;
    }
    for (final s in widget.post.pollSlides) {
      if (s['type']?.toString() == 'image') {
        final url = (s['url'] ?? s['mediaPath'] ?? '').toString().trim();
        if (url.startsWith('http')) return url;
      }
    }
    return null;
  }

  bool get _hasVideo {
    if (widget.post.videoPaths.any((s) => s.trim().isNotEmpty)) return true;
    for (final s in widget.post.pollSlides) {
      if (s['type']?.toString() == 'video') return true;
    }
    return false;
  }

  bool get _hasPoll {
    if (widget.post.pollDataList.isNotEmpty) return true;
    for (final s in widget.post.pollSlides) {
      if (s['type']?.toString() == 'poll') return true;
    }
    return false;
  }

  bool _voteBusy = false;
  Future<void> _likePost() => _setPostVote(widget.post.upvoted ? 0 : 1);
  Future<void> _dislikePost() => _setPostVote(widget.post.downvoted ? 0 : -1);

  Future<void> _setPostVote(int vote) async {
    final post = widget.post;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (_voteBusy || uid == null || post.id == null || post.id!.isEmpty) return;
    final previousVote = (post.upvoted ? 1 : 0) - (post.downvoted ? 1 : 0);
    final previousScore = post.votes;
    setState(() {
      _voteBusy = true;
      post.votes = previousScore - previousVote + vote;
      post.upvoted = vote == 1; post.downvoted = vote == -1;
      _score = post.votes; _isLiked = post.upvoted; _isDisliked = post.downvoted;
    });
    try {
      final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('setPostVote', options: HttpsCallableOptions(timeout: const Duration(seconds: 120)))
          .call<Map<String, dynamic>>({'postId': post.id, 'vote': vote});
      final data = response.data;
      if (data['votes'] is! num || data['vote'] != vote || data['previousVote'] is! num || data['ownerId'] is! String) {
        throw const FormatException('Invalid vote response');
      }
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != uid) return;
      setState(() {
        post.votes = (data['votes'] as num).toInt();
        post.upvoted = vote == 1; post.downvoted = vote == -1;
        _score = post.votes; _isLiked = post.upvoted; _isDisliked = post.downvoted;
      });
      HapticFeedback.lightImpact();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        post.votes = previousScore;
        post.upvoted = previousVote == 1; post.downvoted = previousVote == -1;
        _score = post.votes; _isLiked = post.upvoted; _isDisliked = post.downvoted;
      });
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
           SnackBar(content: Text(mainText(context, "تعذر تحديث التصويت. حاول مرة أخرى."))));
    } finally {
      if (mounted) setState(() => _voteBusy = false);
    }
  }

  Future<void> _openComments() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CommentsScreen(post: widget.post)),
    );
    if (!mounted) return;

    try {
      final data = await _readAuthorizedPostData(widget.post.id);
      final uid = FirebaseAuth.instance.currentUser?.uid;

      final votes = (data['votes'] as num?)?.toInt() ?? widget.post.votes;
      final count = (data['commentsCount'] as num?)?.toInt()
          ?? widget.post.commentsCount;
      final upvotedBy = List<String>.from(data['upvotedBy'] ?? []);
      final downvotedBy = List<String>.from(data['downvotedBy'] ?? []);

      setState(() {
        _score = votes;
        _isLiked = uid != null && upvotedBy.contains(uid);
        _isDisliked = uid != null && downvotedBy.contains(uid);
        widget.post.votes = votes;
        widget.post.upvoted = _isLiked;
        widget.post.downvoted = _isDisliked;
      });
    } catch (e) {
      debugPrint('Refresh post after comments failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final post = widget.post;
    final accent = widget.accent;
    final community = post.tags.isNotEmpty ? post.tags.first : mainText(context, "عام");
    final commentsCount = post.commentsCount;
    final isRepost = post.isRepost && post.repostOf != null;
    final repostData = post.repostOf;
    final isCommentRepost = isRepost &&
        (repostData!['kind']?.toString() == 'comment' ||
            (repostData['commentId']?.toString().trim().isNotEmpty ?? false));

    return Material(
      color: isDark ? const Color(0xFF16181C) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _openComments,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // ===== رأس البطاقة =====
              Row(
                children: [
                  LiveAuthorPhoto(
                    userId: post.authorId,
                    fallbackUrl: post.authorPhotoUrl,
                    size: 24,
                    radius: 12,
                    iconSize: 14,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: ValueListenableBuilder<int>(
                      valueListenable: AuthorProfiles.revision,
                      builder: (context, _, __) {
                        final live =
                        AuthorProfiles.nameOf(post.authorId)
                                        ?.trim();
                        final name = (live != null && live.isNotEmpty)
                            ? _authorLabel(live)
                            : _authorLabel(post.author);
                        return Text(
                          name,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: theme.hintColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ),
                  Text(
                    ' • ${_timeAgo(post.createdAt)}',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                  if (isRepost) ...[
                    Text(
                      mainText(context, " • إعادة نشر"),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // ===== المحتوى + الوسائط =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (post.title.isNotEmpty)
                          Text(
                            post.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (post.body.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            post.body,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                              height: 1.45,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (isRepost) ...[
                          const SizedBox(height: 8),
                          _SearchRepostQuote(
                            data: repostData!,
                            isComment: isCommentRepost,
                            isDark: isDark,
                            accent: accent,
                          ),
                        ],
                        if (post.tags.length > 1) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: post.tags.skip(1).take(3).map((t) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  t,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_hasMedia && !isRepost) ...[
                    const SizedBox(width: 12),
                    _MediaThumbnail(
                      imageUrl: _firstImageUrl,
                      hasVideo: _hasVideo,
                      hasPoll: _hasPoll,
                      isDark: isDark,
                      accent: accent,
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 10),

              // ===== شريط التفاعل =====
            Row(
              children: [
                _LikeActionPill(
                  label: '$_score',
                  isLiked: _isLiked,
                  isDisliked: _isDisliked,
                  onLike: _likePost,
                  onDislike: _dislikePost,
                ),
                const SizedBox(width: 8),
                _PillAction(
                  icon: Icons.mode_comment_outlined,
                  label: '$commentsCount',
                  isDark: isDark,
                  onTap: _openComments,
                ),
                if (widget.onUnsave != null) ...[
                  const Spacer(),
                  _PillAction(
                    icon: Icons.bookmark_rounded,
                    label: mainText(context, "محفوظ"),
                    isDark: isDark,
                    onTap: widget.onUnsave!,
                  ),
                ],
              ],
            ),
          ],
        ),
      )
      ],
            )));
  }
}
class _SearchRepostQuote extends StatelessWidget {
  const _SearchRepostQuote({
    required this.data,
    required this.isComment,
    required this.isDark,
    required this.accent,
  });

  final Map<String, dynamic> data;
  final bool isComment;
  final bool isDark;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final author = isComment
        ? (data['commentAuthor'] ?? data['authorName'] ?? mainText(context, "طالب UniSpace"))
        .toString()
        : (data['authorName'] ?? mainText(context, "طالب UniSpace")).toString();
    final text = isComment
        ? (data['commentText'] ?? data['body'] ?? '').toString().trim()
        : () {
      final t = (data['title'] ?? '').toString().trim();
      final b = (data['body'] ?? '').toString().trim();
      if (t.isNotEmpty) return t;
      return b;
    }();
    final postTitle = (data['title'] ?? '').toString().trim();
    String? image;
    final one = (data['imageUrl'] ?? '').toString().trim();
    if (one.startsWith('http')) image = one;
    if (image == null) {
      final urls = data['imageUrls'];
      if (urls is List) {
        for (final u in urls) {
          final s = u.toString().trim();
          if (s.startsWith('http')) {
            image = s;
            break;
          }
        }
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF4F5F7),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          right: BorderSide(color: accent.withValues(alpha: 0.55), width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isComment
                          ? Icons.mode_comment_outlined
                          : Icons.repeat_rounded,
                      size: 13,
                      color: accent,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        isComment ? mainText(context, "تعليق لـ {0}", <Object?>[author]) : author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                if (text.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                  ),
                ],
                if (isComment && postTitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    mainText(context, "على: {0}", <Object?>[postTitle]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (image != null && !isComment) ...[
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                image,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
class _MediaThumbnail extends StatelessWidget {
  final String? imageUrl;
  final bool hasVideo;
  final bool hasPoll;
  final bool hasGif;
  final bool isDark;
  final Color accent;

  const _MediaThumbnail({
    required this.imageUrl,
    required this.hasVideo,
    required this.hasPoll,
    required this.isDark,
    required this.accent,
    this.hasGif = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 88,
        height: 72,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            else
              _placeholder(),
            if (hasVideo)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            if (hasPoll && !hasVideo)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.poll_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            if (hasGif && !hasVideo)
              Positioned(
                left: 6,
                bottom: 6,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'GIF',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.grey.shade200,
      child: Icon(
        hasPoll
            ? Icons.poll_rounded
            : hasVideo
            ? Icons.videocam_rounded
            : hasGif
            ? Icons.gif_rounded
            : Icons.image_rounded,
        color: accent.withValues(alpha: 0.6),
        size: 28,
      ),
    );
  }
}

class _PillAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  const _PillAction({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFF1F2F3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: theme.hintColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.hintColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandSearchRoute extends PageRouteBuilder {
  final Rect? originRect;
  final Widget child;

  _ExpandSearchRoute({
    required this.originRect,
    required this.child,
  }) : super(
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionDuration: const Duration(milliseconds: 520),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    opaque: false,
  );

  @override
  Widget buildTransitions(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    final size = MediaQuery.sizeOf(context);

    // مركز الدائرة = مركز زر البحث
    final Offset center = originRect?.center ??
        Offset(size.width * 0.82, 52); // احتياطي قريب من مكان الزر

    // أكبر مسافة محتاجينها عشان الدائرة تغطي الشاشة كلها
    final double maxRadius = _calcMaxRadius(center, size);

    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final double radius = maxRadius * curved.value;

        return ClipPath(
          clipper: _CircleRevealClipper(
            center: center,
            radius: radius,
          ),
          child: child,
        );
      },
      child: child,
    );
  }

  double _calcMaxRadius(Offset center, Size size) {
    final distances = [
      (center - Offset.zero).distance,
      (center - Offset(size.width, 0)).distance,
      (center - Offset(0, size.height)).distance,
      (center - Offset(size.width, size.height)).distance,
    ];
    return distances.reduce((a, b) => a > b ? a : b);
  }
}

class _CircleRevealClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  _CircleRevealClipper({
    required this.center,
    required this.radius,
  });

  @override
  Path getClip(Size size) {
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(_CircleRevealClipper oldClipper) {
    return oldClipper.radius != radius || oldClipper.center != center;
  }
}

class _CommentSearchHit {
  const _CommentSearchHit({required this.post, required this.comment});
  final _Post post;
  final _Comment comment;
}

class _RedditStyleCommentTile extends StatelessWidget {
  const _RedditStyleCommentTile({
    required this.hit,
    required this.accent,
    this.onUnsave,
  });

  final _CommentSearchHit hit;
  final Color accent;
  final VoidCallback? onUnsave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final c = hit.comment;
    final isReply = (c.replyToId != null && c.replyToId!.trim().isNotEmpty) ||
        (c.replyToAuthor != null && c.replyToAuthor!.trim().isNotEmpty);
    final replyTo = (c.replyToAuthor ?? '').trim();
    final title = hit.post.title.trim();
    final body = hit.post.body.trim();
    final postLine = title.isNotEmpty ? title : body;
    final mediaUrl = (c.mediaUrl ?? '').trim();
    final mediaType = (c.mediaType ?? '').toLowerCase().trim();
    final hasMedia = mediaUrl.startsWith('http');


    return Material(
      color: isDark ? const Color(0xFF16181C) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CommentsScreen(
                post: hit.post,
                initialCommentId: c.id,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 0),
              Row(
                children: [
                  LiveAuthorPhoto(
                    userId: c.authorId,
                    fallbackUrl: c.authorPhotoUrl,
                    size: 28,
                    radius: 14,
                    iconSize: 15,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ValueListenableBuilder<int>(
                      valueListenable: AuthorProfiles.revision,
                      builder: (context, _, __) {
                        if ((c.authorId ?? '').isNotEmpty) {
                          AuthorProfiles.ensure(c.authorId!);
                        }
                        final live = AuthorProfiles.nameOf(c.authorId)?.trim();
                        final name = (live != null && live.isNotEmpty)
                            ? live
                            : c.author;
                        return Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      },
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      Text(
                        c.timeAgo,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.hintColor),
                      ),
                      if (onUnsave != null)
                        IconButton(
                          tooltip: mainText(context, "إلغاء الحفظ"),
                          visualDensity: VisualDensity.compact,
                          onPressed: onUnsave,
                          icon: Icon(
                            Icons.bookmark_rounded,
                            color: accent,
                            size: 20,
                          ),
                        ),

                    ],
                  ),
                ],
              ),
              if (isReply) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.subdirectory_arrow_right_outlined,
                        size: 15,
                        color:Theme.of(context)
                            .colorScheme.onSurface.withValues(alpha: 0.4)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        replyTo.isEmpty
                            ? mainText(context, "رد على تعليق")
                            : mainText(context, "رد على {0}", <Object?>[replyTo]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color:Theme.of(context)
                              .colorScheme.onSurface.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      c.text.trim(),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.45,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (hasMedia) ...[
                    const SizedBox(width: 12),
                    _MediaThumbnail(
                      imageUrl: mediaUrl,
                      hasVideo: mediaType == 'video',
                      hasPoll: false,
                      isDark: isDark,
                      accent: accent,
                    ),
                  ],
                ],
              ),
              if (postLine.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF4F5F7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      right: BorderSide(color: accent.withValues(alpha: 0.5), width: 3),
                    ),
                  ),
                  child: Text(
                    mainText(context, " المنشور: {0}", <Object?>[postLine]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.hintColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}



