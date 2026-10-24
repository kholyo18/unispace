part of '../../main.dart';

class _Post {
  final String? id;
   bool isEdited;
  final String author;
  final String? authorId;
  final String? authorPhotoUrl;
  final bool authorPrivate;
  String title;
  String body;

  final DateTime createdAt;

  final List<String> imagePaths;
  final List<String> videoPaths;

  final List<PollData> pollDataList;
  final bool isRepost;
  final Map<String, dynamic>? repostOf;
  List<String> tags;

  final String? mediaUrl;
  final int commentsCount;
  int votes;

  bool upvoted;
  bool downvoted;
  final bool authorAppearInSearch;
  final List<_Comment> comments;
  final List<Map<String, dynamic>> pollSlides;
  final bool authorHideLikeCounts;

  _Post({
    this.id,
    required this.author,
    this.authorId,
    this.commentsCount = 0,
    this.authorPhotoUrl,
    required this.title,
    required this.body,
    required this.createdAt,
    this.imagePaths = const [],
    this.videoPaths = const [],
    this.pollDataList = const [],
    this.tags = const [],
    this.mediaUrl,
    this.votes = 0,
    this.upvoted = false,
    this.downvoted = false,
    this.isRepost = false,
    this.repostOf,
    this.isEdited = false,
    this.authorPrivate = false,
    this.authorAppearInSearch = true,
    this.authorHideLikeCounts = false,
    this.pollSlides = const [],
    List<_Comment>? comments,
  }) : comments = comments ?? [];

  factory _Post.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return _Post.fromData(doc.id, doc.data() ?? <String, dynamic>{});
  }

  factory _Post.fromData(String id, Map<String, dynamic> data) {
    final rawSlides = data['pollSlides'];
    final pollSlides = rawSlides is List
        ? rawSlides
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList()
        : <Map<String, dynamic>>[];
    final imageUrls = _stringList(
      data['imageUrls'] ?? data['imagePaths'],
    );

    final videoUrls = _stringList(
      data['videoUrls'] ?? data['videoPaths'],
    );

    debugPrint(
      'POST ${id} MEDIA => '
          'images=${imageUrls.length}, '
          'videos=${videoUrls.length}',
    );

    for (final url in imageUrls) {
      debugPrint('IMAGE URL: $url');
    }

    for (final url in videoUrls) {
      debugPrint('VIDEO URL: $url');
    }
    final currentUid =
        FirebaseAuth.instance.currentUser?.uid;

    final upvotedBy =
    _stringList(data['upvotedBy']);

    final downvotedBy =
    _stringList(data['downvotedBy']);

    // ----------------------------------------
    // createdAt
    // ----------------------------------------

    DateTime createdAt = DateTime.now();

    final rawDate = data['createdAt'];

    if (rawDate is Timestamp) {
      createdAt = rawDate.toDate();
    } else if (rawDate is String) {
      createdAt =
          DateTime.tryParse(rawDate) ??
              createdAt;
    }

    // ----------------------------------------
    // Polls
    // ----------------------------------------

    final rawPolls = data['polls'];

    final List<PollData> polls =
    rawPolls is List
        ? rawPolls
        .whereType<Map>()
        .map(
          (e) => _pollFromMap(
        Map<String, dynamic>.from(e),
      ),
    )
        .toList()
        : <PollData>[];

    // ----------------------------------------
    // إنشاء Model
    // ----------------------------------------
    final rawComments = data['comments'];

    final List<_Comment> comments = rawComments is List
        ? rawComments
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(item),
    )
        .where((item) {
      final replyToId = item['replyToId'];

      // التعليق الرئيسي فقط
      return replyToId == null ||
          replyToId.toString().isEmpty;
    })
        .map(
          (item) => _commentFromMap(item),
    )
        .toList()
        : <_Comment>[];

    final commentsCount = (data['commentsCount'] as num?)?.toInt()
        ?? (comments.isNotEmpty ? comments.length : 0);
    final isRepost = data['isRepost'] == true;
    final repostRaw = data['repostOf'];

    final Map<String, dynamic>? repostOf = repostRaw is Map
        ? Map<String, dynamic>.from(repostRaw)
        : null;
    return _Post(
      id: id,
      authorPrivate: data['authorPrivate'] == true,
      author:
      (data['authorName'] ??
          data['author'] ??
          mainTextCurrent("طالب UniSpace")).toString(),
      authorHideLikeCounts: data['authorHideLikeCounts'] == true,
      authorId: data['authorId']?.toString(),
      authorPhotoUrl: data['authorPhotoUrl']?.toString(),
      isEdited: data['isEdited'] == true,
      title: (data['title'] ?? '').toString(),
      commentsCount: commentsCount,
      body: (data['body'] ?? '').toString(),

      createdAt: createdAt,

      imagePaths: imageUrls,
      videoPaths: videoUrls,

      isRepost: isRepost,
      repostOf: repostOf,
      pollDataList: polls,
      pollSlides: pollSlides,

      tags: _stringList(
        data['tags'],
      ),

      mediaUrl:
      data['mediaUrl']?.toString(),

      votes:
      (data['votes'] as num?)?.toInt() ??
          0,

      upvoted:
      currentUid != null &&
          upvotedBy.contains(currentUid),

      comments: comments,

      downvoted:
      currentUid != null &&
          downvotedBy.contains(currentUid),
    );
  }

  String get timeAgo {
    final now = DateTime.now();

    final difference =
    now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d';
    }

    if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w';
    }

    if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo';
    }

    return '${(difference.inDays / 365).floor()}y';
  }
}

List<String> _stringList(dynamic value) {
  if (value is! List) {
    return <String>[];
  }

  return value
      .map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
}


// ==================== PostCard ====================
class _PostCard extends StatefulWidget {
  final _Post post;
  final VoidCallback onChanged;
  final Future<void> Function() onDelete;
  final bool isEmbedded;
  final bool isInsideComments;
  final List<_Post>? feedPosts;
  final Future<void> Function()? onLoadMoreFeed;
  final VoidCallback? onHidden;
  final bool showAuthorHeader;
  final bool compact;
  final bool allowPin;
  final bool isPinned;
  final Future<void> Function(String? postId)? onSetPinned;

  const _PostCard({
    required this.post,
    required this.onChanged,
    required this.onDelete,
    this.isEmbedded = false,
    this.isInsideComments = false,
    this.feedPosts,
    this.onLoadMoreFeed,
    this.onHidden,
    this.showAuthorHeader= true,
    this.compact = false,
    this.allowPin = false,
    this.isPinned = false,
    this.onSetPinned,

  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  final GlobalKey _likeButtonKey = GlobalKey();
  bool _submittingPollAnswers = false;
  final Map<int, dynamic> _pollAnswers = {};

  bool _isNavigating = false;
  int _currentPollPage = 0;
  final Map<String, VideoPlayerController> _pollVideoControllers = {};

  bool _isSaved = false;

  Future<void> _togglePinPost() async {
    final id = widget.post.id?.trim();
    if (id == null || id.isEmpty || widget.onSetPinned == null) return;
    final next = widget.isPinned ? null : id;
    await widget.onSetPinned!(next);
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(next == null ? mainText(context, "تم إلغاء التثبيت") : mainText(context, "تم تثبيت المنشور")),
      ),
    );
  }

  Future<void> _loadSavedState() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final postId = widget.post.id?.trim();
    if (uid == null || postId == null || postId.isEmpty) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('saved_posts')
        .doc(postId)
        .get();
    if (mounted) setState(() => _isSaved = doc.exists);
  }

  Future<void> _toggleSavePost() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final postId = widget.post.id?.trim();
    if (uid == null || postId == null || postId.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
         SnackBar(content: Text(mainText(context, "يجب تسجيل الدخول أولاً"))),
      );
      return;
    }

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('saved_posts')
        .doc(postId);

    try {
      if (_isSaved) {
        await ref.delete();
        if (!mounted) return;
        setState(() => _isSaved = false);
        widget.onChanged();
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
           SnackBar(content: Text(mainText(context, "تم إلغاء الحفظ"))),
        );
      } else {
        await ref.set({
          'postId': postId,
          'savedAt': FieldValue.serverTimestamp(),
        });
        if (!mounted) return;
        setState(() => _isSaved = true);
        widget.onChanged();
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
           SnackBar(content: Text(mainText(context, "تم حفظ المنشور"))),
        );
      }
    } catch (e) {
      debugPrint('toggle save failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
         SnackBar(content: Text(mainText(context, "تعذر حفظ المنشور"))),
      );
    }
  }

  Future<_Post> _resolveRepostRoot(_Post post) async {
    var id = post.id?.trim();
    final visited = <String>{};
    for (var depth = 0; depth < 8; depth++) {
      if (id == null || id.isEmpty || !visited.add(id)) throw StateError('Invalid repost chain');
      final data = await _readAuthorizedPostData(id);
      final fresh = _Post.fromData(id, data);
      if (!fresh.isRepost) return fresh;
      id = fresh.repostOf?['postId']?.toString().trim();
    }
    throw StateError('Repost chain too deep');
  }

  List<_PostMediaItem> _downloadableItemsFor(_Post post) {
    final items = <_PostMediaItem>[];
    for (final p in post.imagePaths) {
      if (p.trim().isNotEmpty) items.add(_PostMediaItem.image(p.trim()));
    }
    for (final p in post.videoPaths) {
      if (p.trim().isNotEmpty) items.add(_PostMediaItem.video(p.trim()));
    }
    return items;
  }

  Future<void> _saveMediaItem(_PostMediaItem item, Future<void> Function() verify, String postId) async {
    await verify();
    final path = item.path.trim();
    // Downloadable files must still belong to the current authorized post.
    if (!path.startsWith('https://') && !path.startsWith('http://')) {
      throw StateError('Invalid downloadable media URL');
    }
    var downloadUrl = path;
    final source = Uri.tryParse(path);
    if (source?.host == 'firebasestorage.googleapis.com') {
      final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('readPostMediaDownload')
              .call({'postId': postId, 'url': path});
      final data = Map<String, dynamic>.from(response.data as Map);
      final signed = data['url'], expiry = data['expiresAt'];
      if (signed is! String || Uri.tryParse(signed)?.scheme != 'https' ||
          expiry is! num || expiry <= DateTime.now().millisecondsSinceEpoch) {
        throw StateError('Invalid download authorization');
      }
      downloadUrl = signed;
      await verify();
    }
    final file = await DefaultCacheManager().getSingleFile(downloadUrl);
    await verify();
    if (item.kind == _MediaKind.video) {
      await Gal.putVideo(file.path, album: 'UniSpace');
    } else {
      await Gal.putImage(file.path, album: 'UniSpace');
    }
  }

  bool _downloadingMedia = false;
  Future<void> _downloadPostMedia() async {
    if (_downloadingMedia || !mounted) return;
    final pager = _FullscreenPostPagerState.current;
    final target = pager?.currentPost ?? widget.post;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final blocks = blockedListRevision.value;
    final overlayContext = pager?.context ?? context;
    final navigator = Navigator.of(overlayContext, rootNavigator: true);
    DialogRoute<void>? progress;
    var saved = 0;
    bool current() => mounted && overlayContext.mounted && uid != null &&
        uid == FirebaseAuth.instance.currentUser?.uid && blocks == blockedListRevision.value;
    _downloadingMedia = true;
    try {
      final data = await _readAuthorizedPostData(target.id);
      if (!current()) return;
      final fresh = _Post.fromData(target.id!, data);
      final items = _downloadableItemsFor(fresh);
      if (items.isEmpty) {
        ScaffoldMessenger.maybeOf(overlayContext)?.showSnackBar(
           SnackBar(content: Text(mainText(context, "لا توجد وسائط متاحة للتنزيل"))),
        );
        return;
      }
      List<_PostMediaItem> selected = items;
      if (items.length > 1) {
        final picked = await showModalBottomSheet<_DownloadPickResult>(
          context: overlayContext, useRootNavigator: true, showDragHandle: true,
          builder: (_) => _DownloadMediaSheet(postId: fresh.id!, items: items),
        );
        if (!current() || picked == null || picked.items.isEmpty) return;
        selected = picked.items;
      }
      final granted = await Gal.requestAccess(toAlbum: true);
      if (!current()) return;
      if (granted != true) {
        ScaffoldMessenger.maybeOf(overlayContext)?.showSnackBar(
           SnackBar(content: Text(mainText(context, "يجب السماح بالوصول لألبوم الصور"))),
        );
        return;
      }
      progress = DialogRoute<void>(context: overlayContext, barrierDismissible: false,
        builder: (_) => const PopScope(canPop: false, child: Center(child: CircularProgressIndicator())),
      );
      unawaited(navigator.push(progress));
      for (final item in selected) {
        await _saveMediaItem(item, () async {
          if (!current()) throw StateError('Download context changed');
          final latest = await _readAuthorizedPostData(target.id);
          if (!current()) throw StateError('Download context changed');
          final allowed = _downloadableItemsFor(_Post.fromData(target.id!, latest));
          if (!allowed.any((p) => p.kind == item.kind && p.path.trim() == item.path.trim())) {
            throw StateError('Media no longer available');
          }
        }, target.id!);
        saved++;
      }
      if (current()) ScaffoldMessenger.maybeOf(overlayContext)?.showSnackBar(
        SnackBar(content: Text(saved == 1 ? mainText(context, "تم حفظ الوسائط") : mainText(context, "تم حفظ {0} ملفات", <Object?>[saved]))),
      );
    } catch (_) {
      if (current()) ScaffoldMessenger.maybeOf(overlayContext)?.showSnackBar(SnackBar(
        content: Text(saved == 0 ? mainText(context, "تعذر تنزيل الوسائط أو لم تعد متاحة")
            : mainText(context, "تم حفظ {0} ملفات، وتعذر إكمال الباقي", <Object?>[saved])),
      ));
    } finally {
      if (navigator.mounted && progress != null && progress.isActive) navigator.removeRoute(progress);
      _downloadingMedia = false;
    }
  }

  Future<void> _initPollVideo(String url) async {
    final u = url.trim();
    if (u.isEmpty || !u.startsWith('http') || Uri.tryParse(u)?.host == 'firebasestorage.googleapis.com') return;
    if (_pollVideoControllers.containsKey(u)) return;

    final c = VideoPlayerController.networkUrl(Uri.parse(u));
    try {
      await c.initialize();
      await c.setLooping(true);
      if (!mounted) {
        await c.dispose();
        return;
      }
      _pollVideoControllers[u] = c;
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('poll video init failed: $e');
      await c.dispose();
    }
  }
  bool _hasAnswer(PollData poll, int key) {
    if (!_pollAnswers.containsKey(key)) return false;
    final answer = _pollAnswers[key];
    if (answer is String) return answer.trim().isNotEmpty;
    if (answer is Set) return answer.isNotEmpty;
    if (answer is Map) {
      return answer.values.any((v) => v is Set && v.isNotEmpty);
    }
    if (answer is int || answer is double) return true;
    if (answer is List) {
      return answer.isNotEmpty;
    }
    if (answer is DateTime) {
      if (poll.includeTime || poll.dateConfig?.includeTime == true) {
        return _pollAnswers.containsKey(key + 100000);
      }
      return true;
    }
    if (answer is TimeOfDay) return true;
    return false;
  }
// فقط منشورات فيها صورة/فيديو وما فيهاش بول
  List<_Post> _swipeableMediaPosts(List<_Post> source) {
    return source.where((p) {
      final hasPoll = p.pollDataList.isNotEmpty;
      if (hasPoll) return false;
      final hasMedia = p.imagePaths.any((s) => s.trim().isNotEmpty) ||
          p.videoPaths.any((s) => s.trim().isNotEmpty);
      return hasMedia;
    }).toList();
  }

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
  void _precachePostMedia() {
    // ===== خارج البول =====
    for (final p in widget.post.imagePaths) {
      final u = p.trim();
      if (u.startsWith('http') && Uri.tryParse(u)?.host != 'firebasestorage.googleapis.com') {
        precacheImage(ProtectedCachedNetworkImageProvider(u), context);
      }
    }

    // ===== داخل البول =====
    for (final s in widget.post.pollSlides) {
      final type = s['type']?.toString();
      if (type == 'image') {
        final u = (s['url'] ?? s['mediaPath'] ?? '').toString().trim();
        if (u.startsWith('http') && Uri.tryParse(u)?.host != 'firebasestorage.googleapis.com') {
          precacheImage(ProtectedCachedNetworkImageProvider(u), context);
        }
      }
      if (s['type']?.toString() == 'video') {
        final u = (s['url'] ?? s['mediaPath'] ?? '').toString();
        _initPollVideo(u);
      }
      // الفيديو: لا يوجد precache جاهز مثل الصور؛ يُهيَّأ عند العرض
      // يمكن لاحقاً تهيئة خفيفة للفيديو الحالي فقط
    }
  }
  @override
  void initState() {
    super.initState();
    _loadSavedState();

    // بعد أول إطار (لأن context جاهز لـ precacheImage)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _precachePostMedia();
    });
  }

  List<_PostMediaItem> _postMediaItems() {
    final items = <_PostMediaItem>[];
    for (final p in widget.post.imagePaths) {
      if (p.trim().isNotEmpty) {
        items.add(_PostMediaItem.image(p.trim()));
      }
    }
    for (final p in widget.post.videoPaths) {
      if (p.trim().isNotEmpty) {
        items.add(_PostMediaItem.video(p.trim()));
      }
    }
    return items;
  }

  bool _openingMedia = false;
  Future<void> _openPostMediaFullscreen(String currentPath) async {
    if (_openingMedia) return;
    final postId = widget.post.id;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final blocks = blockedListRevision.value;
    bool current() => mounted && uid == FirebaseAuth.instance.currentUser?.uid &&
        blocks == blockedListRevision.value && postId == widget.post.id;
    _openingMedia = true;
    try {
    final data = await _readAuthorizedPostData(postId);
    if (!current()) return;
    final fresh = _Post.fromData(postId!, data);
    final items = _mediaItemsForPost(fresh);
    if (items.isEmpty) return;

    final i = items.indexWhere((e) => e.path == currentPath);
    if (i < 0) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
         SnackBar(content: Text(mainText(context, "هذا الملف لم يعد متاحاً في المنشور"))),
      );
      return;
    }
    final index = i;

    // ===== الجديد: إذا عندنا لائحة كل المنشورات، نفتح الـ Pager العمودي =====
    final allPosts = widget.feedPosts;
    if (allPosts != null && allPosts.isNotEmpty) {
      final swipeable = _swipeableMediaPosts(allPosts.map((p) => p.id == postId ? fresh : p).toList());
      debugPrint('ALL feedPosts = ${allPosts.length}');
      debugPrint('SWIPEABLE     = ${swipeable.length}');
      debugPrint('CURRENT id    = ${fresh.id}');
      final startIndex = swipeable.indexWhere((p) => p.id == fresh.id);

      if (startIndex != -1) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FullscreenPostPager(
              posts: swipeable,
              initialIndex: startIndex,
              initialMediaIndex: index,
              onChanged: widget.onChanged,
              menuButton: _buildFullscreenMenu(),
              onAuthorBlocked: (id) {
                widget.onChanged();
              },
              onNearEnd: () async {
                // 1) حمّل الدفعة التالية في الشاشة الأم
                await widget.onLoadMoreFeed?.call();
                // 2) أعد كل المنشورات الحالية (بعد التحديث)
                return widget.feedPosts ?? <_Post>[];
              },
            ),
          ),
        );
        return;
      }
    }

    // Use the same authorized media path when no swipeable feed is available.
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenPostPager(
          posts: [fresh],
          initialIndex: 0,
          initialMediaIndex: index,
          onChanged: widget.onChanged,
          menuButton: _buildFullscreenMenu(),
          onAuthorBlocked: (_) => widget.onChanged(),
        ),
      ),
    );
    } on FirebaseFunctionsException catch (error) {
      if (!current()) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(
        error.code == 'not-found' ? mainText(context, "المنشور لم يعد متاحاً") : mainText(context, "تعذر فتح الوسائط، حاول مجدداً"),
      )));
    } catch (_) {
      if (!current()) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
         SnackBar(content: Text(mainText(context, "تعذر فتح الوسائط، حاول مجدداً"))),
      );
    } finally {
      _openingMedia = false;
    }
  }
  bool _openingOriginal = false;

  Future<void> _openOriginalPost() async {
    if (_openingOriginal) return;
    final id = widget.post.repostOf?['postId']?.toString().trim();
    if (id == null || id.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final blockRevision = blockedListRevision.value;
    bool stillCurrent() => mounted &&
        FirebaseAuth.instance.currentUser?.uid == uid &&
        blockedListRevision.value == blockRevision &&
        widget.post.repostOf?['postId']?.toString().trim() == id;
    final nav = Navigator.of(context, rootNavigator: true);
    _openingOriginal = true;
    try {
      final data = await _readAuthorizedPostData(id);
      if (!stillCurrent()) return;
      final original = _Post.fromData(id, data);
      await nav.push(
        MaterialPageRoute(builder: (_) => CommentsScreen(post: original)),
      );
      if (stillCurrent()) widget.onChanged();
    } on FirebaseFunctionsException catch (error) {
      if (!stillCurrent()) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
        content: Text(error.code == 'not-found'
            ? mainText(context, "المنشور الأصلي لم يعد متاحاً")
            : mainText(context, "تعذر فتح المنشور الأصلي، حاول مجدداً")),
      ));
    } catch (_) {
      if (!stillCurrent()) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
         SnackBar(content: Text(mainText(context, "تعذر فتح المنشور الأصلي، حاول مجدداً"))),
      );
    } finally {
      _openingOriginal = false;
    }
  }
  @override
  void dispose() {
    for (final c in _pollVideoControllers.values) {
      c.dispose();
    }
    _pollVideoControllers.clear();
    super.dispose();
  }

  Future<void> _openComments() async {
    if (widget.isInsideComments) return;
    if (_isNavigating) return;
    _isNavigating = true;
    final hidden = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CommentsScreen(post: widget.post)),
    );
    _isNavigating = false;
    if (!mounted) return;
    if (hidden == true) {
      widget.onHidden?.call();
    } else {
      widget.onChanged();
    }
  }

  Future<void> _openPollImage(String path) async {
    if (_openingMedia) return;
    final id = widget.post.id;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final blockVersion = blockedListRevision.value;
    final moderationVersion = moderationRevision.value;
    final profileVersion = authorProfileRevision.value;
    bool current() => mounted && id == widget.post.id && uid != null &&
        uid == FirebaseAuth.instance.currentUser?.uid &&
        blockVersion == blockedListRevision.value &&
        moderationVersion == moderationRevision.value &&
        profileVersion == authorProfileRevision.value;
    _openingMedia = true;
    try {
      final fresh = _Post.fromData(id!, await _readAuthorizedPostData(id));
      if (!current()) return;
      if (!fresh.pollSlides.any((slide) => slide['type'] == 'image' &&
          (slide['url'] ?? slide['mediaPath'] ?? slide['path'] ?? '')
                  .toString()
                  .trim() == path)) {
        throw StateError('Poll image removed');
      }
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => Uri.tryParse(path)?.host == 'firebasestorage.googleapis.com'
            ? _AuthorizedImageView(postId: id, path: path)
            : SimpleFullscreenImageViewer(images: [path], initialIndex: 0),
      ));
    } catch (_) {
      if (current()) ScaffoldMessenger.maybeOf(context)?.showSnackBar(
         SnackBar(content: Text(mainText(context, "تعذر فتح الصورة، ربما تغيّر الوصول إلى المنشور"))),
      );
    } finally {
      _openingMedia = false;
    }
  }

  Widget _buildImageSlide(String path) {
    final value = path.trim();

    if (value.isEmpty) {
      return _mediaErrorWidget(mainText(context, "رابط الصورة فارغ"));
    }

    final bool isNetwork =
        value.startsWith('http://') || value.startsWith('https://');

    return RetainedImageSlide(
      key: ValueKey([widget.post.id, value].join('|')),
      child: _AutoSizeImage(
      postId: Uri.tryParse(value)?.host == 'firebasestorage.googleapis.com' ? (widget.post.id ?? '') : null,
      path: value,
      isNetwork: isNetwork,
      maxHeight: 480,
      onTap: () {
        final postImages = widget.post.imagePaths
            .where((p) => p.trim().isNotEmpty).toList();
        final isFromPost = postImages.contains(value);

        if (isFromPost) {
          _openPostMediaFullscreen(value); // ← هنا
        } else {
          _openPollImage(value);
        }
      },
      ),
    );
  }

  Widget _mediaErrorWidget(String message) {
    return Container(
      color: UniSpaceColors.ivory,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.broken_image_rounded,
            size: 38,
            color: UniSpaceColors.lightMuted,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              color: UniSpaceColors.lightMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSlide(String path) => _VideoSlideWidget(
    key: ValueKey([widget.post.id, path].join('|')),
    postId: Uri.tryParse(path.trim())?.host == 'firebasestorage.googleapis.com' ? (widget.post.id ?? '') : null,
    videoPath: path,
    authorName: _authorLabel(widget.post.author),   // NEW
    authorPhotoUrl: widget.post.authorPhotoUrl,       // NEW
    postTitle: widget.post.title,                     // NEW
  );

  Widget _buildAutoSizeVideoSlide(String path) => _AutoSizeVideo(
    key: ValueKey([widget.post.id, path].join('|')),
    postId: Uri.tryParse(path.trim())?.host == 'firebasestorage.googleapis.com' ? (widget.post.id ?? '') : null,
    path: path,
    maxHeight: 480,
    authorName: _authorLabel(widget.post.author),
    authorPhotoUrl: widget.post.authorPhotoUrl,
    postTitle: widget.post.title,
    postBody: widget.post.body,
    menuButton: _buildFullscreenMenu(),
    votes: widget.post.votes,
    isLiked: widget.post.upvoted,
    isDisliked: widget.post.downvoted,
    commentsCount: widget.post.comments.length,
    tagsCount: widget.post.tags.length,
    onLike: _likePost,
    onDislike: _dislikePost,
    onComment: () async {
      await _openComments();
      return widget.post.comments.length;
    },
    onTags: _showTagsSheet,
    onOpenFullscreen: () => _openPostMediaFullscreen(path), // ← الجديد
  );
  Widget _buildPollSlide(PollData poll, {int slideIndex = 0}) {
    return PollQuestionSlideView(
      poll: poll,
      slideIndex: slideIndex,
      answers: _pollAnswers,
      onAnswer: (key, value) {
        setState(() => _pollAnswers[key] = value);
      },
    );
  }

  List<Widget> _mediaSlides(_Post post) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final slides = <Widget>[];
    final autoHeightFlags = <bool>[];

    // ===== 1) وسائط خارج البول أولاً — auto-height =====
    for (final img in post.imagePaths) {
      slides.add(_buildImageSlide(img));
      autoHeightFlags.add(true); // NEW
    }
    for (final vid in post.videoPaths) {
      // FIX: فيديو خارج البول → بعرض كامل ونسبة حقيقية، بدل _buildVideoSlide الثابت
      slides.add(_buildAutoSizeVideoSlide(vid));
      autoHeightFlags.add(true);
    }
    // ===== 2) شرائح البول بنفس الترتيب المحفوظ =====
    for (final s in post.pollSlides) {
      final type = s['type']?.toString();

      if (type == 'text') {
        slides.add(
          _wrapSlide(
            isDark: isDark,
            theme: theme,

              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Text(
                  s['text']?.toString() ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

          ),
        );
        autoHeightFlags.add(false);
      }

      if (type == 'poll') {
        final idx = (s['pollIndex'] as num?)?.toInt() ?? 0;
        if (idx >= 0 && idx < post.pollDataList.length) {
          slides.add(
            _wrapSlide(
              isDark: isDark,
              theme: theme,
              child: PollQuestionSlideView(
                poll: post.pollDataList[idx],
                slideIndex: idx,
                answers: _pollAnswers,
                onAnswer: (key, value) {
                  setState(() => _pollAnswers[key] = value);
                },
              ),
            ),
          );
          autoHeightFlags.add(false);
        }
      }

      if (type == 'image') {
        final url = s['url']?.toString();
        if (url != null && url.isNotEmpty) {
          slides.add(_buildImageSlide(url));
          autoHeightFlags.add(false);
        }
      }

      if (type == 'video') {
        final url = s['url']?.toString();
        if (url != null && url.isNotEmpty) {
          slides.add(_buildVideoSlide(url));
          autoHeightFlags.add(false);
        }
      }
    }

    // ===== 3) شريحة الإرسال =====
    if (post.pollDataList.isNotEmpty) {
      slides.add(
        _wrapSlide(
          isDark: isDark,
          theme: theme,
          child: _buildSubmitSlide(post.pollDataList, theme, isDark),
        ),
      );
      autoHeightFlags.add(false);
    }
    _lastAutoHeightFlags = autoHeightFlags;
    return slides;
  }
  List<bool> _lastAutoHeightFlags = const [];
  void _openAuthorProfile() {
    final id = widget.post.authorId?.trim();
    if (id == null || id.isEmpty) return;

    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me != null && me == id) {
      // صاحب الحساب → بروفايلك الحالي
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          userId: id,
          initialName: _authorLabel(widget.post.author),
          initialPhotoUrl: widget.post.authorPhotoUrl,
        ),
      ),
    );
  }
  Widget _wrapSlide({
    required Widget child,
    required bool isDark,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: () {}, // لا يفتح التعليقات
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: ColoredBox(
          color: isDark ? theme.colorScheme.surface : Colors.white,
          child: child,
        ),
      ),
    );
  }

  Widget _buildPollBlock(List<PollData> polls) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pages = <Widget>[];

    for (final s in widget.post.pollSlides) {
      if (s['type'] == 'text') {
        pages.add(
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                s['text']?.toString() ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }
      // لاحقاً: image / video
    }

    for (int i = 0; i < polls.length; i++) {
      pages.add(
        PollQuestionSlideView(
          poll: polls[i],
          slideIndex: i,
          answers: _pollAnswers,
          onAnswer: (key, value) {
            setState(() => _pollAnswers[key] = value);
          },
        ),
      );
    }

    pages.add(_buildSubmitSlide(polls, theme, isDark));

    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 320, // ← ارتفاع ثابت واضح
          color: isDark ? theme.colorScheme.surface : Colors.white,
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => _currentPollPage = i),
                  itemBuilder: (context, index) => pages[index],
                ),
              ),
              if (pages.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(pages.length, (i) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentPollPage == i ? 10 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentPollPage == i
                              ? theme.colorScheme.primary
                              : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitSlide(
      List<PollData> polls,
      ThemeData theme,
      bool isDark,
      ) {
    final required = <int>[];
    for (int i = 0; i < polls.length; i++) {
      if (polls[i].isRequired) required.add(i);
    }

    final answeredRequired =
        required.where((i) => _hasAnswer(polls[i], i)).length;
    final totalRequired = required.length;
    final answeredAll = List.generate(polls.length, (i) => i)
        .where((i) => _hasAnswer(polls[i], i))
        .length;

    final ok = totalRequired == 0
        ? answeredAll == polls.length
        : answeredRequired == totalRequired;

    

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            ok ? Icons.check_circle_outline : Icons.pending_outlined,
            size: 48,
            color: ok ? AppTeal.main : theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
           Text(
            mainText(context, "Submit answers"),
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(mainText(context, "{0} / {1} answered", <Object?>[answeredAll, polls.length])),
          if (totalRequired > 0) ...[
            const SizedBox(height: 4),
            Text(
              mainText(context, "{0} / {1} required", <Object?>[answeredRequired, totalRequired]),
              style: TextStyle(
                color: ok ? AppTeal.main : Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submittingPollAnswers ? null : () async {
                if (_submittingPollAnswers) return;
                if (!ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(
                      content: Text(mainText(context, "يجب الإجابة على جميع الأسئلة الإلزامية أولاً")),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                final uid = FirebaseAuth.instance.currentUser?.uid;
                final postId = widget.post.id; // ← متاح في _PostCard فقط
                if (uid == null || postId == null || postId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text(mainText(context, "يجب تسجيل الدخول أولاً"))),
                  );
                  return;
                }
                

                final messenger = ScaffoldMessenger.maybeOf(context);

                setState(() => _submittingPollAnswers = true);
                try {
                  final encoded = <String, dynamic>{};
                  _pollAnswers.forEach((k, v) {
                    encoded[k.toString()] = serializePollAnswer(v);
                  });
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  await FirebaseFunctions.instanceFor(region: 'europe-west1')
                      .httpsCallable('submitPollAnswers')
                      .call({'postId': postId, 'answers': encoded});

                  if (!mounted || FirebaseAuth.instance.currentUser?.uid != uid) return;
                  messenger?.hideCurrentSnackBar();
                  messenger?.showSnackBar(
                     SnackBar(content: Text(mainText(context, "تم إرسال الإجابات"))),
                  );
                } catch (e) {
                  if (!mounted || FirebaseAuth.instance.currentUser?.uid != uid) return;
                  messenger?.showSnackBar(
                    SnackBar(content: Text(
                      e is FirebaseFunctionsException && e.code == 'invalid-argument'
                          ? mainText(context, "راجع الإجابات والأسئلة الإلزامية، ثم أعد المحاولة")
                          : mainText(context, "تعذر إرسال الإجابات"),
                    )),
                  );
                } finally {
                  if (mounted) setState(() => _submittingPollAnswers = false);
                }
              },
              child:  Text(mainText(context, "Confirm & Submit")),
            ),
          ),
        ],
      ),
    );
  }

  String _authorLabel(String author) {
    final cleaned = author.trim();
    if (cleaned.isEmpty || cleaned == 'current_user') return mainText(context, "طالب UniSpace");
    return cleaned.replaceFirst(RegExp(r'^u/'), '');
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

      });
      HapticFeedback.lightImpact();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        post.votes = previousScore;
        post.upvoted = previousVote == 1; post.downvoted = previousVote == -1;

      });
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
           SnackBar(content: Text(mainText(context, "تعذر تحديث التصويت. حاول مرة أخرى."))));
    } finally {
      if (mounted) setState(() => _voteBusy = false);
    }
  }

  void _showTagsSheet() {
    final tags = widget.post.tags;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Directionality(
        textDirection: Directionality.of(context),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   Icon(Icons.device_hub_rounded, color: AppTeal.foreground(context)),
                  const SizedBox(width: 8),
                  Text(
                    mainText(context, "الوسوم على هذا المنشور"),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (tags.isEmpty)
                Text(
                  mainText(context, "لا توجد وسوم على هذا المنشور"),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: tags
                      .map((tag) => _CommunityPostTagChip(label: tag))
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }


  String formatVotes(int votes) {
    if (votes >= 1000000) return '${(votes / 1000000).toStringAsFixed(1)}M';
    if (votes >= 1000) return '${(votes / 1000).toStringAsFixed(1)}k';
    return votes.toString();
  }

  bool get _isOwner {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final ownerId = widget.post.authorId?.trim();
    if (ownerId == null || ownerId.isEmpty) return false;
    return ownerId == currentUserId ||
        (currentUserId == null && ownerId == 'local_current_user');
  }

  String _postShareText([_Post? source]) {
    final post = source ?? widget.post;
    final parts = [
      post.title.trim(),
      post.body.trim(),
    ].where((part) => part.isNotEmpty).join('\n\n');
    return parts.isEmpty ? mainText(context, "منشور UniSpace") : parts;
  }

  /// رابط شكلي للمنشور — يُستبدل لاحقًا برابط الويب الحقيقي
  String? _postShareLink() {
    final id = widget.post.id?.trim();
    if (id == null || id.isEmpty) return null;
    return 'unispace://post/$id';
  }

  String _postSharePayload([_Post? source]) {
    final post = source ?? widget.post;
    final text = _postShareText(post);
    final author = _authorLabel(post.author);
    final link = _postShareLink();
    final buffer = StringBuffer()
      ..writeln(text)
      ..writeln()
      ..write(mainText(context, "— {0} على UniSpace", <Object?>[author]));
    if (link != null) {
      buffer
        ..writeln()
        ..write(link);
    }
    return buffer.toString().trim();
  }

  Future<void> _sharePost() async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Directionality(
          textDirection: Directionality.of(context),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        mainText(ctx, "مشاركة المنشور"),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ShareActionTile(
                      icon: Icons.link_rounded,
                      label: mainText(ctx, "نسخ الرابط"),
                      enabled: _postShareLink() != null,
                      onTap: () async {
                        final link = _postShareLink();
                        Navigator.pop(ctx);
                        if (link == null) return;
                        await Clipboard.setData(ClipboardData(text: link));
                        if (!mounted) return;
                        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                           SnackBar(content: Text(mainText(ctx, "تم نسخ الرابط"))),
                        );
                      },
                    ),
                    _ShareActionTile(
                      icon: Icons.copy_rounded,
                      label: mainText(ctx, "نسخ النص"),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _copyAuthorizedShareText();
                      },
                    ),
                    _ShareActionTile(
                      icon: Icons.ios_share_rounded,
                      label: mainText(ctx, "مشاركة عبر التطبيقات"),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _openSystemShareSheet();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _copyingShareText = false;
  Future<void> _copyAuthorizedShareText() async {
    if (!mounted || _copyingShareText) return;
    _copyingShareText = true;
    final id = widget.post.id, uid = FirebaseAuth.instance.currentUser?.uid;
    final blocks = blockedListRevision.value, profiles = authorProfileRevision.value,
        moderation = moderationRevision.value;
    bool current() => mounted && uid != null && uid == FirebaseAuth.instance.currentUser?.uid &&
        id == widget.post.id && blocks == blockedListRevision.value &&
        profiles == authorProfileRevision.value && moderation == moderationRevision.value;
    try {
      final fresh = _Post.fromData(id!, await _readAuthorizedPostData(id));
      if (!current()) return;
      await Clipboard.setData(ClipboardData(text: _postSharePayload(fresh)));
      if (!current()) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
         SnackBar(content: Text(mainText(context, "تم نسخ النص"))),
      );
    } catch (_) {
      if (current()) ScaffoldMessenger.maybeOf(context)?.showSnackBar(
         SnackBar(content: Text(mainText(context, "تعذر نسخ النص، ربما لم يعد المنشور متاحًا"))),
      );
    } finally {
      _copyingShareText = false;
    }
  }

  bool _preparingShare = false;
  Future<void> _openSystemShareSheet() async {
    if (_preparingShare || !mounted) return;
    _preparingShare = true;
    final id = widget.post.id, uid = FirebaseAuth.instance.currentUser?.uid;
    final blocks = blockedListRevision.value, profiles = authorProfileRevision.value,
        moderation = moderationRevision.value;
    bool current() => mounted && uid != null && uid == FirebaseAuth.instance.currentUser?.uid &&
        id == widget.post.id && blocks == blockedListRevision.value &&
        profiles == authorProfileRevision.value && moderation == moderationRevision.value;
    String firstImage(_Post post) => post.imagePaths.map((p) => p.trim())
        .firstWhere((p) => p.startsWith('http'), orElse: () => '');
    try {
      final fresh = _Post.fromData(id!, await _readAuthorizedPostData(id));
      if (!current()) return;
      final originalImage = firstImage(fresh);
      var imageUrl = originalImage;
      if (Uri.tryParse(imageUrl)?.host == 'firebasestorage.googleapis.com') {
        imageUrl = await PostMediaLinks.read(id, imageUrl);
        if (!current()) return;
      }
      if (imageUrl.isNotEmpty) {
        Object? imageError;
        await precacheImage(ProtectedNetworkImage(imageUrl), context, onError: (error, _) => imageError = error);
        if (imageError != null) throw StateError('Share image unavailable');
        if (!current()) return;
      }
      final file = await _buildPostShareImage(fresh, imageUrl);
      if (!current()) return;
      final latest = _Post.fromData(id, await _readAuthorizedPostData(id));
      if (!current()) return;
      if (latest.title != fresh.title || latest.body != fresh.body || latest.author != fresh.author ||
          latest.authorPhotoUrl != fresh.authorPhotoUrl || firstImage(latest) != originalImage) {
        throw StateError('Post changed while preparing share');
      }
      final text = _postSharePayload(fresh);

      final box = context.findRenderObject() as RenderBox?;
      final origin =
      box != null ? box.localToGlobal(Offset.zero) & box.size : null;

      if (file != null) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: text,
          subject: 'UniSpace',
          sharePositionOrigin: origin,
        );
      } else {
        // احتياطي: نص فقط إذا فشل توليد الصورة
        await Share.share(
          text,
          subject: 'UniSpace',
          sharePositionOrigin: origin,
        );
      }
    } catch (e, st) {
      if (!current()) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
         SnackBar(content: Text(mainText(context, "تعذر تجهيز المشاركة، ربما تغيّر المنشور أو الوصول إليه"))),
      );
    } finally {
      _preparingShare = false;
    }
  }

  Future<File?> _buildPostShareImage(_Post post, String imageUrl) async {
    final repaintKey = GlobalKey();
    final completed = Completer<void>();

    // نعرض البطاقة خارج الشاشة لالتقاطها
    final entry = OverlayEntry(
      builder: (ctx) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!completed.isCompleted) completed.complete();
        });
        return Positioned(
          left: -5000, // خارج الشاشة
          top: 0,
          child: Material(
            color: Colors.transparent,
            child: RepaintBoundary(
              key: repaintKey,
              child: _PostShareCard(
                author: _authorLabel(post.author),
                authorPhotoUrl: post.authorPhotoUrl,
                title: post.title.trim(),
                body: post.body.trim(),
                imageUrl: imageUrl,
              ),
            ),
          ),
        );
      },
    );

    final overlay = Overlay.of(context);
    overlay.insert(entry);

    try {
      await completed.future;
      // إطار إضافي لضمان اكتمال الرسم
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await WidgetsBinding.instance.endOfFrame;

      final boundary =
      repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return null;

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/unispace_share_${widget.post.id ?? DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List());
      return file;
    } finally {
      entry.remove();
    }
  }

  bool _textSelectable = false;

  void _copyPostText() {
    setState(() => _textSelectable = true);
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
       SnackBar(content: Text(mainText(context, "حدد النص ثم انسخه"))),
    );
  }

  Future<void> _reportPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(mainText(context, "يجب تسجيل الدخول أولاً"))),
      );
      return;
    }

    final pager = _FullscreenPostPagerState.current;
    final target = pager?.currentPost ?? widget.post;
    final postId = target.id?.trim();
    if (postId == null || postId.isEmpty) return;

    final ownerId = target.authorId?.trim();
    if (ownerId != null && ownerId.isNotEmpty && ownerId == user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(mainText(context, "لا يمكنك تبليغ محتواك"))),
      );
      return;
    }

    bool already;
    try {
      already = await hasCommunityReport(
        type: CommunityReportType.post,
        targetId: postId,
      );
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(mainText(context, "تعذر التحقق من البلاغ السابق؛ أعد المحاولة"))));
      return;
    }
    if (!mounted) return;
    if (already) {
      await showReportSubmittedSheet(
        context,
        type: CommunityReportType.post,
        ownerId: ownerId,
        ownerName: _authorLabel(target.author),
        ownerPhotoUrl: target.authorPhotoUrl,
        useRootNavigator: true,
        alreadyReported: true,
      );
      return;
    }

    if (!already) {
      final result = await showCommunityReportSheet(
        context,
        type: CommunityReportType.post,
        useRootNavigator: true,
      );
      if (result == null || !mounted) return;

      try {
        await runWithReportSpinner(context, () => submitCommunityReport(
          type: CommunityReportType.post,
          targetId: postId,
          ownerId: ownerId,
          ownerName: _authorLabel(target.author),
          reason: result.reasonId,
          details: result.details,
          snapshot: communityReportSnapshotFromPost(target),
        ));
      } catch (error) {
        debugPrint('Community report failed: $error');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(messageForCommunityReportError(error))),
        );
        return;
      }
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('hidden_posts')
          .doc(postId)
          .set({
        'postId': postId,
        'source': 'report',
        'hiddenAt': FieldValue.serverTimestamp(),
      });
      hiddenListRevision.value++;
    } catch (e) {
      debugPrint('hide after report failed: $e');
    }

    if (!mounted) return;
    await showReportSubmittedSheet(
      context,
      type: CommunityReportType.post,
      ownerId: ownerId,
      ownerName: _authorLabel(target.author),
      ownerPhotoUrl: target.authorPhotoUrl,
      useRootNavigator: true,
      alreadyReported: already,
      onBlocked: () {
        if (ownerId == null) return;
        final livePager = _FullscreenPostPagerState.current;
        if (livePager != null && livePager.mounted) {
          livePager._onAuthorBlocked(ownerId);
        }
        widget.onHidden?.call();
        widget.onChanged();
      },
    );

    if (!mounted) return;
    final livePager = _FullscreenPostPagerState.current;
    if (livePager != null && livePager.mounted) {
      livePager.hidePost(postId);
    } else {
      widget.onHidden?.call();
      if (!widget.isInsideComments) widget.onChanged();
    }
  }

  Future<void> _repostPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
         SnackBar(content: Text(mainText(context, "يجب تسجيل الدخول أولاً"))),
      );
      return;
    }

    if (widget.post.id == null || widget.post.id!.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
         SnackBar(content: Text(mainText(context, "تعذر إعادة نشر هذا المنشور"))),
      );
      return;
    }

    final _Post original;
    try {
      original = await _resolveRepostRoot(widget.post);
    } catch (_) {
      if (mounted) ScaffoldMessenger.maybeOf(context)?.showSnackBar(
         SnackBar(content: Text(mainText(context, "تعذر الوصول إلى المنشور الأصلي لإعادة نشره"))),
      );
      return;
    }
    if (!mounted || FirebaseAuth.instance.currentUser?.uid != user.uid) return;
    if (!mounted) return;

    final originalId = original.id?.trim();
    if (originalId == null || originalId.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
         SnackBar(content: Text(mainText(context, "تعذر إعادة نشر هذا المنشور"))),
      );
      return;
    }

    final allowed = await canRepostAuthor(original.authorId ?? '');
    if (!allowed) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
         SnackBar(content: Text(mainText(context, "إعادة النشر غير مسموحة لهذا الحساب"))),
      );
      return;
    }

    final draft = await _askRepostDraft(original);
    if (!mounted) return;
    if (draft == null) return;

    try {
      await _publishAuthorizedRepost(expectedUid: user.uid,
        sourcePostId: originalId, draft: draft);

      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
         SnackBar(content: Text(mainText(context, "تمت إعادة النشر"))),
      );
    } catch (e, st) {
      debugPrint('Repost failed: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
         SnackBar(content: Text(mainText(context, "تعذر إعادة النشر، حاول مجددًا"))),
      );
    }
  }

  Future<void> _publishCommunityRepost(
      {required _Post original,
    required _RepostDraft draft, _Comment? comment}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final id = original.id;
    if (uid == null || id == null || id.isEmpty) throw StateError(mainText(context, "تعذر تحديد مصدر إعادة النشر"));
    await _publishAuthorizedRepost(expectedUid: uid, sourcePostId: id,
      draft: draft, commentId: comment?.id);
  }

  Future<_RepostDraft?> _askRepostDraft([
    _Post? previewPost,
    _Comment? comment,
  ]) async {
    final original = previewPost ?? widget.post;
    final nav = Navigator.of(context, rootNavigator: true);

    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return null;

    return nav.push<_RepostDraft>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _RepostComposePage(
          original: original,
          comment: comment,
        ),
      ),
    );
  }

  Future<void> _blockAccount({bool closeViewer = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    final pager = _FullscreenPostPagerState.current;
    final targetPost = pager?.currentPost ?? widget.post;
    final targetId = targetPost.authorId?.trim();

    if (user == null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
         SnackBar(content: Text(mainText(context, "يجب تسجيل الدخول أولاً"))),
      );
      return;
    }
    if (targetId == null || targetId.isEmpty) return;
    if (targetId == user.uid) return;

    final name = _authorLabel(targetPost.author);
    final overlayContext = pager?.context ?? context;

    final confirmed = await showDialog<bool>(
      context: overlayContext,
      useRootNavigator: true,
      builder: (ctx) => Directionality(
        textDirection: Directionality.of(context),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title:  Text(mainText(ctx, "حظر الحساب؟")),
          content: Text(
            mainText(ctx, "لن تظهر منشورات {0} في فيدك بعد الآن. يمكنك إلغاء الحظر لاحقًا من الإعدادات.", <Object?>[name]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:  Text(mainText(ctx, "إلغاء")),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child:  Text(mainText(ctx, "حظر")),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await blockAccount(
        targetId: targetId,
        targetName: name,
        targetPhotoUrl: targetPost.authorPhotoUrl,
      );
      if (!mounted) return;

      if (pager != null && pager.mounted) {
        pager._onAuthorBlocked(targetId);
        widget.onChanged();
        return;
      }

      widget.onHidden?.call();
      if (widget.isInsideComments) return;
      widget.onChanged();
      if (closeViewer && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(mainText(context, "تم حظر {0}", <Object?>[name]))),
      );
    } catch (e) {
      debugPrint('Block account failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
         SnackBar(content: Text(mainText(context, "تعذر حظر الحساب، حاول مجددًا"))),
      );
    }
  }

  String _liveAuthorName(_Post post) {
    final live = AuthorProfiles.nameOf(post.authorId)?.trim();
    if (live != null && live.isNotEmpty) return _authorLabel(live);
    return _authorLabel(post.author);
  }

  Future<void> _confirmDeletePost() async {
    if (!_isOwner) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: Directionality.of(context),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title:  Text(mainText(context, "حذف المنشور؟")),
          content:  Text(
            mainText(context, "سيتم حذف هذا المنشور نهائيًا ولا يمكن التراجع عن العملية."),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:  Text(mainText(context, "إلغاء")),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label:  Text(mainText(context, "حذف")),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    try {
      await widget.onDelete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(mainText(context, "تم حذف المنشور"))),
      );
    } catch (error) {
      debugPrint('Community delete failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(mainText(context, "تعذر حذف المنشور، حاول مجددًا"))),
      );
    }
  }

  Future<void> _editPost() async {
    if (!_isOwner) return;
    if (widget.post.id == null || widget.post.id!.isEmpty) return;

    final editingUid = FirebaseAuth.instance.currentUser?.uid;
    if (editingUid == null) return;
    final nav = Navigator.of(context, rootNavigator: true);
    final post = widget.post;

    final result = await nav.push<List<PostItem>>(
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(editingPost: post),
      ),
    );


    if (!mounted || result == null || result.isEmpty) return;
    if (FirebaseAuth.instance.currentUser?.uid != editingUid) return;
    final editUploadId = FirebaseFirestore.instance.collection('community_posts').doc().id;

    String title = '';
    String body = '';
    final newImages = <Uint8List>[];
    final keepImageUrls = <String>[];
    final newVideos = <String>[];
    final keepVideoUrls = <String>[];
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
          if (item.imageBytes != null) {
            newImages.add(item.imageBytes!);
          } else {
            final u = item.mediaPath?.trim() ?? '';
            if (u.startsWith('http')) keepImageUrls.add(u);
          }
          break;
        case PostItemType.video:
          final u = item.mediaPath?.trim() ?? '';
          if (u.startsWith('http')) {
            keepVideoUrls.add(u);
          } else if (u.isNotEmpty) {
            newVideos.add(u);
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

    final postId = widget.post.id!;

    try {
      final imageUrls = [...keepImageUrls];
      for (int i = 0; i < newImages.length; i++) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('community_posts')
            .child(postId)
            .child('images')
            .child('edit_${editUploadId}_$i.jpg');
        validateMediaUploadSize(newImages[i].length, video: false);
        await StorageUploadService.putData(ref,
            newImages[i], SettableMetadata(contentType: 'image/jpeg'));
        imageUrls.add(StorageUploadService.locator(ref));
      }

      final videoUrls = [...keepVideoUrls];
      for (int i = 0; i < newVideos.length; i++) {
        final file = File(newVideos[i]);
        if (!await file.exists()) continue;
        validateMediaUploadSize(await file.length(), video: true);
        final ext = newVideos[i].split('.').last.toLowerCase();
        final ref = FirebaseStorage.instance
            .ref().child('community_posts/$postId/videos/edit_${editUploadId}_$i.$ext');
        await StorageUploadService.putFile(ref,
          file,
          SettableMetadata(contentType: postVideoContentType(ext)),
        );
        videoUrls.add(StorageUploadService.locator(ref));
      }

      final resolvedSlides = <Map<String, dynamic>>[];
      int pollImg = 0;
      int pollVid = 0;
      for (final s in pollSlides) {
        final type = s['type']?.toString();
        if (type == 'text') {
          final t = s['text']?.toString() ?? '';
          if (t.isNotEmpty) resolvedSlides.add({'type': 'text', 'text': t});
        } else if (type == 'poll') {
          resolvedSlides.add({'type': 'poll', 'pollIndex': s['pollIndex']});
        } else if (type == 'image') {
          final existing = s['url']?.toString() ?? '';
          if (existing.startsWith('http')) {
            resolvedSlides.add({'type': 'image', 'url': existing});
          } else if (s['imageBytes'] is Uint8List) {
            final ref = FirebaseStorage.instance.ref(
              'community_posts/$postId/images/poll_edit_${editUploadId}_${pollImg++}.jpg',
            );
            validateMediaUploadSize((s['imageBytes'] as Uint8List).length, video: false);
            await StorageUploadService.putData(ref,
              s['imageBytes'] as Uint8List,
              SettableMetadata(contentType: 'image/jpeg'),
            );
            resolvedSlides.add({'type': 'image', 'url': StorageUploadService.locator(ref)});
          }
        } else if (type == 'video') {
          final existing = s['url']?.toString() ?? '';
          if (existing.startsWith('http')) {
            resolvedSlides.add({'type': 'video', 'url': existing});
          } else {
            final path = s['mediaPath']?.toString() ?? '';
            if (path.isNotEmpty) {
              final file = File(path);
              if (await file.exists()) {
                validateMediaUploadSize(await file.length(), video: true);
                final videoExtension = path.split('.').last.toLowerCase();
                final videoMime = postVideoContentType(videoExtension);
                final ref = FirebaseStorage.instance.ref(
                  'community_posts/$postId/videos/poll_edit_${editUploadId}_${pollVid++}.$videoExtension',
                );
                await StorageUploadService.putFile(ref,
                    file, SettableMetadata(contentType: videoMime));
                resolvedSlides.add({'type': 'video', 'url': StorageUploadService.locator(ref)});
              }
            }
          }
        }
      }

      if (FirebaseAuth.instance.currentUser?.uid != editingUid) {
        throw StateError(mainText(context, "تغير الحساب أثناء التعديل"));
      }
      final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('editOwnPost')
              .call<Map<String, dynamic>>({
        'postId': postId,
        'content': {
          'title': title,
          'body': body,
          'tags': postTags,
          'imageUrls': imageUrls,
          'videoUrls': videoUrls,
          'polls': pollDataList.map(_pollToMap).toList(),
          'pollSlides': resolvedSlides,
        },
      });
      if (FirebaseAuth.instance.currentUser?.uid != editingUid ||
          response.data['postId'] != postId || response.data['edited'] != true) {
        throw StateError(mainText(context, "تعذر تأكيد تعديل المنشور"));
      }

      if (!mounted) return;

      setState(() {
        widget.post.title = title;
        widget.post.body = body;
        widget.post.tags
          ..clear()
          ..addAll(postTags);
        widget.post.isEdited = true;

        widget.post.imagePaths
          ..clear()
          ..addAll(imageUrls);
        widget.post.videoPaths
          ..clear()
          ..addAll(videoUrls);
        widget.post.pollDataList
          ..clear()
          ..addAll(pollDataList);
        widget.post.pollSlides
          ..clear()
          ..addAll(resolvedSlides);
      });

      widget.onChanged();
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
         SnackBar(content: Text(mainText(context, "تم تعديل المنشور"))),
      );
    } catch (e, st) {
      debugPrint('Edit post failed: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(e is MediaUploadValidation ? serviceErrorText(context, e) : mainText(context, "تعذر تعديل المنشور"))),
      );
    }
  }

  PopupMenuItem<_PostMenuAction> _menuItem({
    required _PostMenuAction value,
    required IconData icon,
    required String label,
    Color? color,
  }) {
    final itemColor = color ?? UniSpaceColors.lightMuted;
    return PopupMenuItem<_PostMenuAction>(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        textDirection: Directionality.of(context),
        children: [
          Icon(icon, size: 18, color: itemColor),
          const SizedBox(width: 9),
          Text(
            label,
            style: TextStyle(
              color: itemColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsMenu() {
    return Container(
      width: 24,
      height: 30,

      child: PopupMenuButton<_PostMenuAction>(
        tooltip: mainText(context, "خيارات المنشور"),
        padding: EdgeInsets.zero,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            Icons.more_vert_rounded,
            color: AppTeal.foreground(context),
            size: 20,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        color: Theme.of(context).colorScheme.surface,
        position: PopupMenuPosition.under,
        onSelected: (action) {
          switch (action) {
            case _PostMenuAction.pin:
              _togglePinPost();
              break;
            case _PostMenuAction.pollResponses:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PollResponsesScreen(post: widget.post),
                ),
              );
              break;
            case _PostMenuAction.edit:
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _editPost();
              });
              break;
            case _PostMenuAction.delete:
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _confirmDeletePost();
              });
              break;
            case _PostMenuAction.share:
              _sharePost();
              break;
            case _PostMenuAction.save:
              _toggleSavePost();
              break;
            case _PostMenuAction.download:
              _downloadPostMedia();
              break;
            case _PostMenuAction.repost:
              Future<void>.delayed(const Duration(milliseconds: 150), () async {
                if (!mounted) return;
                final ok = await canRepostAuthor(widget.post.authorId ?? '');
                if (!ok) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(
                      content: Text(mainText(context, "إعادة النشر غير مسموحة لهذا الحساب")),
                    ),
                  );
                  return;
                }
                await _repostPost();
              });
              break;
            case _PostMenuAction.report:
              _reportPost();
              break;
            case _PostMenuAction.block:
              Future<void>.delayed(const Duration(milliseconds: 150), () {
                if (mounted) _blockAccount();
              });
              break;
            case _PostMenuAction.copy:
              _copyPostText();
              break;
          }
        },
        itemBuilder: (context) => [
          if (widget.allowPin && _isOwner)
            _menuItem(
              value: _PostMenuAction.pin,
              icon: widget.isPinned
                  ? Icons.push_pin_rounded
                  : Icons.push_pin_outlined,
              label: widget.isPinned ? mainText(context, "إلغاء التثبيت") : mainText(context, "تثبيت المنشور"),
              color: widget.isPinned ? AppTeal.main : null,
            ),
          if (_isOwner && widget.post.pollDataList.isNotEmpty)
            _menuItem(
              value: _PostMenuAction.pollResponses,
              label:mainText(context, "ردود الاستطلاع"),
              icon: Icons.find_in_page,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          if (_isOwner) ...[
            _menuItem(
              value: _PostMenuAction.edit,
              icon: Icons.edit_rounded,
              label: mainText(context, "تعديل المنشور"),
              color:  AppTeal.main,
            ),
            _menuItem(
              value: _PostMenuAction.delete,
              icon: Icons.delete_outline_rounded,
              label: mainText(context, "حذف المنشور"),
              color: const Color(0xFFDC2626),
            ),
            const PopupMenuDivider(height: 6),
          ],
          _menuItem(
            value: _PostMenuAction.save,
            icon: _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            label: _isSaved ? mainText(context, "إلغاء الحفظ") : mainText(context, "حفظ المنشور"),
            color: _isSaved ? AppTeal.main : null,
          ),
          if (_downloadableItemsFor(widget.post).isNotEmpty)
            _menuItem(
              value: _PostMenuAction.download,
              icon: Icons.download_rounded,
              label: mainText(context, "تحميل "),
            ),
          _menuItem(
            value: _PostMenuAction.repost,
            icon: Icons.repeat_rounded,
            label: mainText(context, "إعادة نشر"),
          ),
          _menuItem(
            value: _PostMenuAction.share,
            icon: Icons.ios_share_rounded,
            label: mainText(context, "مشاركة"),
          ),

          if (!_isOwner) ...[
            _menuItem(
              value: _PostMenuAction.report,
              icon: Icons.flag_outlined,
              label: mainText(context, "تبليغ"),
            ),
            _menuItem(
              value: _PostMenuAction.block,
              icon: Icons.block_rounded,
              label: mainText(context, "حظر الحساب"),
              color: const Color(0xFFDC2626),
            ),
          ],
          _menuItem(
            value: _PostMenuAction.copy,
            icon: Icons.copy_rounded,
            label: mainText(context, "نسخ النص"),
          ),
        ],
      ),
    );
  }
  Widget _buildFullscreenMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    PopupMenuItem<_PostMenuAction> item({
      required _PostMenuAction value,
      required IconData icon,
      required String label,
      Color? color,
    }) {
      final c = color ?? (isDark ? Colors.white : Colors.white);
      return PopupMenuItem<_PostMenuAction>(
        value: value,
        child: Row(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: c,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
      ),
      child: PopupMenuButton<_PostMenuAction>(
        tooltip: mainText(context, "خيارات المنشور"),
        padding: EdgeInsets.zero,
        color: UniSpaceColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        icon: const Icon(
          Icons.more_vert_rounded,
          color: Colors.white,
          size: 22,
        ),
        onSelected: (action) {
          switch (action) {
            case _PostMenuAction.pin:
              _togglePinPost();
              break;
            case _PostMenuAction.pollResponses:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PollResponsesScreen(post: widget.post),
                ),
              );
              break;
            case _PostMenuAction.edit:
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _editPost();
              });
              break;
            case _PostMenuAction.delete:
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _confirmDeletePost();
              });
              break;
            case _PostMenuAction.share:
              _sharePost();
              break;
            case _PostMenuAction.save:
              _toggleSavePost();
              break;
            case _PostMenuAction.repost:
              Future<void>.delayed(const Duration(milliseconds: 150), () async {
                if (!mounted) return;
                final ok = await canRepostAuthor(widget.post.authorId ?? '');
                if (!ok) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(
                      content: Text(mainText(context, "إعادة النشر غير مسموحة لهذا الحساب")),
                    ),
                  );
                  return;
                }
                await _repostPost();
              });
              break;
            case _PostMenuAction.report:
              _reportPost();
              break;
            case _PostMenuAction.download:
              _downloadPostMedia();
              break;
            case _PostMenuAction.block:
              Future<void>.delayed(const Duration(milliseconds: 150), () {
                if (mounted) _blockAccount(closeViewer: true);
              });
              break;
            case _PostMenuAction.copy:
              _copyPostText();
              break;
          }
        },
        itemBuilder: (context) => [
          if (widget.allowPin && _isOwner)
            _menuItem(
              value: _PostMenuAction.pin,
              icon: widget.isPinned
                  ? Icons.push_pin_rounded
                  : Icons.push_pin_outlined,
              label: widget.isPinned ? mainText(context, "إلغاء التثبيت") : mainText(context, "تثبيت المنشور"),
              color: widget.isPinned ? AppTeal.main : null,
            ),
          if (_isOwner && widget.post.pollDataList.isNotEmpty)
            item(
              value: _PostMenuAction.pollResponses,
              icon: Icons.poll_outlined,
              label: mainText(context, "ردود الاستطلاع"),
              color: const Color(0xFF4FD1C5),
            ),
          if (_isOwner) ...[
            item(
              value: _PostMenuAction.edit,
              icon: Icons.edit_rounded,
              label: mainText(context, "تعديل المنشور"),
              color: const Color(0xFF4FD1C5),
            ),
            item(
              value: _PostMenuAction.delete,
              icon: Icons.delete_outline_rounded,
              label: mainText(context, "حذف المنشور"),
              color: const Color(0xFFDC2626),
            ),
            const PopupMenuDivider(height: 6),
          ],
          item(
            value: _PostMenuAction.save,
            icon: _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            label: _isSaved ? mainText(context, "إلغاء الحفظ") : mainText(context, "حفظ المنشور"),
            color: _isSaved ? AppTeal.main : null,
          ),
          if (_downloadableItemsFor(
            _FullscreenPostPagerState.current?.currentPost ?? widget.post,
          ).isNotEmpty)
            item(
              value: _PostMenuAction.download,
              icon: Icons.download_rounded,
              label: mainText(context, "تحميل الوسائط"),
            ),
          item(
            value: _PostMenuAction.repost,
            icon: Icons.repeat_rounded,
            label: mainText(context, "إعادة نشر"),
          ),
          item(
            value: _PostMenuAction.share,
            icon: Icons.ios_share_rounded,
            label: mainText(context, "مشاركة"),
          ),
          if (!_isOwner) ...[
            item(
              value: _PostMenuAction.report,
              icon: Icons.flag_outlined,
              label: mainText(context, "تبليغ"),
            ),
            item(
              value: _PostMenuAction.block,
              icon: Icons.block_rounded,
              label: mainText(context, "حظر الحساب"),
              color: const Color(0xFFDC2626),
            ),
          ],
          item(
            value: _PostMenuAction.copy,
            icon: Icons.copy_rounded,
            label: mainText(context, "نسخ النص"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final titleColor =
    isDark ? theme.colorScheme.onSurface : UniSpaceColors.forest;
    final bodyColor = isDark
        ? theme.colorScheme.onSurfaceVariant
        : UniSpaceColors.lightMuted;
    final metaColor = isDark
        ? theme.colorScheme.onSurfaceVariant
        : UniSpaceColors.lightMuted;

    final slides = _mediaSlides(post);

    // فاصل خفيف بدل ظل ثقيل
    final dividerColor = theme.colorScheme.onSurface.withValues(alpha: 0.08);

    return ValueListenableBuilder<int>(
        valueListenable: AuthorProfiles.revision,
        builder: (context, _, __) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: theme.scaffoldBackgroundColor, // نفس خلفية الفيد
        child: Column(
          children: [
            Padding(
              // نظام 8: أفقي 16، داخلي عمودي 12
              padding: widget.compact
                  ? const EdgeInsets.fromLTRB(16, 8, 16, 6)
                  : const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== رأس + عنوان → تعليقات =====
                  InkWell(
                    onTap: (widget.isInsideComments || _textSelectable)
                        ? null
                        : _openComments,
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //if (widget.showAuthorHeader) ...[
                        Row(
                          children: [
                    Expanded(
                    child: GestureDetector(
                        onTap: _openAuthorProfile,
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            LiveAuthorPhoto(
                              userId: post.authorId,
                              fallbackUrl: post.authorPhotoUrl,
                              size: 36,
                              radius: 18,
                              iconSize: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: GestureDetector(
                                      onTap: _openAuthorProfile,
                                      child: Text(
                                        _liveAuthorName(post),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          height: 1.2,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    ' · ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: metaColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Flexible(
                                    child: _PostTimeLabel(
                                      label: () => post.timeAgo,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: metaColor,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                  if (post.isRepost) ...[
                                    Text(' · ', style: TextStyle(fontSize: 12, color: metaColor)),
                                    Text(
                                      mainText(context, "Reposted"),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: metaColor,
                                      ),
                                    ),
                                  ],
                                  if (post.isEdited) ...[
                                    Text(' · ', style: TextStyle(fontSize: 12, color: metaColor)),
                                    Text(
                                      mainText(context, "Edited"),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: metaColor,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                    ),
                    ),
                            if (!widget.isEmbedded) ...[
                              if (widget.isPinned)
                                IconButton(
                                  tooltip: mainText(context, "إلغاء التثبيت"),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: _togglePinPost,
                                  icon: Icon(
                                    Icons.push_pin_rounded,
                                    color: AppTeal.foreground(context),
                                    size: 18,
                                  ),
                                ),
                              if (_isSaved)
                                IconButton(
                                  tooltip: mainText(context, "إلغاء الحفظ"),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: _toggleSavePost,
                                  icon: Icon(
                                    Icons.bookmark_rounded,
                                    color: AppTeal.foreground(context),
                                    size: 20,
                                  ),
                                ),
                              _buildOptionsMenu(),
                            ],
                                  ],
                        ),
                       // ],
                        if (post.title.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            post.title.trim(),
                            textDirection: Directionality.of(context),
                            textAlign: TextAlign.start,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                              color: titleColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ===== النص =====
                  if (post.body.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: (widget.isInsideComments || _textSelectable)
                          ? null
                          : _openComments,
                      child: ExpandableText(
                        text: post.body.trim(),
                        maxLines: 3,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                          color: bodyColor,
                        ),
                      ),
                    ),
                  ],

                  if (post.isRepost && post.repostOf != null) ...[
                    const SizedBox(height: 10),
                    _RepostEmbedCard(
                      data: post.repostOf!,
                      onChanged: widget.onChanged,
                    ),
                  ],

                  // ===== وسائط / بول — بدون فتح تعليقات =====
                  if (slides.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _MediaCarousel(
                        slides: slides,
                        autoHeightFlags: _lastAutoHeightFlags,
                      ),
                    ),
                  ],

                  if (!widget.isEmbedded) ...[
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 44,
                      child: _CommunityPostActionBar(
                        likeButtonKey: _likeButtonKey,
                        tagsCount: post.tags.length,
                        onTagsTap: _showTagsSheet,
                        commentLabel: '${post.comments.length}',
                        onCommentTap:
                        widget.isInsideComments ? () {} : _openComments,
                        likeLabel: (post.authorHideLikeCounts &&
                            post.authorId !=
                                FirebaseAuth.instance.currentUser?.uid)
                            ? ''
                            : formatVotes(post.votes),
                        isLiked: post.upvoted,
                        isDisliked: post.downvoted,
                        onLikeTap: _likePost,
                        onDislike: _dislikePost,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // فاصل بين المنشورات
            Divider(height: 1, thickness: 1, color: dividerColor),
          ],
        ),
      ),
          );
        });
  }
}

class _ShareActionTile extends StatelessWidget {
  const _ShareActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = enabled
        ? theme.colorScheme.onSurface
        : theme.disabledColor;

    return ListTile(
      enabled: enabled,
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      onTap: enabled ? onTap : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
class _PostShareCard extends StatelessWidget {
  const _PostShareCard({
    required this.author,
    required this.authorPhotoUrl,
    required this.title,
    required this.body,
    required this.imageUrl,
  });

  final String author;
  final String? authorPhotoUrl;
  final String title;
  final String body;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    const width = 360.0;
    final hasImage = imageUrl.startsWith('http');

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: UniSpaceColors.darkBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasImage)
            SizedBox(
              height: 200,
              child: ProtectedImage.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: UniSpaceColors.darkContainer,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_outlined,
                      color: Colors.white38, size: 40),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: UniSpaceColors.darkContainer,
                      ),
                      child: (authorPhotoUrl != null &&
                          authorPhotoUrl!.trim().isNotEmpty)
                          ? ProtectedImage.network(
                        authorPhotoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.person,
                            color: Colors.white70,
                            size: 18),
                      )
                          : const Icon(Icons.person,
                          color: Colors.white70, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Text(
                      'UniSpace',
                      style: TextStyle(
                        color: Color(0xFF2DD4BF),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (title.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      height: 1.3,
                    ),
                  ),
                ],
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    body,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w500,
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RepostDraft {
  const _RepostDraft({required this.title, required this.body});
  final String title;
  final String body;
}
class _RepostComposePage extends StatefulWidget {
  const _RepostComposePage({this.comment,required this.original});
  final _Post original;
  final _Comment? comment;
  @override
  State<_RepostComposePage> createState() => _RepostComposePageState();
}
class _RepostComposePageState extends State<_RepostComposePage> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _bodyCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.pop(
      context,
      _RepostDraft(
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final original = widget.original;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(
                  mainText(context, "Repost"),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _submit,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child:  Text(
                      mainText(context, "Post"),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            TextField(
              controller: _titleCtrl,
              onChanged: (_) => setState(() {}),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              cursorColor: Theme.of(context).colorScheme.primary,
              cursorWidth: 2.5,
              decoration: InputDecoration(
                hintText: mainText(context, "Title"),
                hintStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).hintColor.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                filled: false,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _bodyCtrl,
              onChanged: (_) => setState(() {}),
              maxLines: null,
              minLines: 4,
              style: TextStyle(
                fontSize: 16,
                height: 1.45,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              cursorColor: Theme.of(context).colorScheme.primary,
              decoration: InputDecoration(
                hintText: widget.comment != null
                    ? mainText(context, "Body ...what you think about this comment?")
                    : mainText(context, "Body ...what you think of about this post?"),
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).hintColor.withValues(alpha: 0.55),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                filled: false,
              ),
            ),
            const SizedBox(height: 16),
            IgnorePointer(
              ignoring: widget.comment == null,
              child: widget.comment != null
                  ? _CommentRepostPreview(
                postId: original.id ?? '',
                commentId: widget.comment!.id,
                author: widget.comment!.author,

                authorPhotoUrl: widget.comment!.authorPhotoUrl,
                text: widget.comment!.text,
                timeLabel: widget.comment!.timeAgo,
                mediaUrl: widget.comment!.mediaUrl,
                mediaType: widget.comment!.mediaType,
                contextLabel: original.title.trim().isEmpty
                    ? mainText(context, "تعليق")
                    : mainText(context, "replide to: @ {0}", <Object?>[original.title.trim()]),
              )
                  : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.45),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _PostCard(
                  post: original,
                  isEmbedded: true,
                  onChanged: () {},
                  onDelete: () async {},
                  feedPosts: [original],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _RepostEmbedCard extends StatefulWidget {
  const _RepostEmbedCard({
    required this.data,
    this.onChanged,
  });

  final Map<String, dynamic> data;
  final VoidCallback? onChanged;

  @override
  State<_RepostEmbedCard> createState() => _RepostEmbedCardState();
}

class _RepostEmbedCardState extends State<_RepostEmbedCard> {
  _Post? _post;
  bool _loading = true;
  String? _loadError;
  Map<String, dynamic> _authorizedQuote = {};
  int _loadGeneration = 0;
  StreamSubscription<User?>? _authSubscription;
  String? _uid;

  bool get _isCommentRepost {
    final kind = widget.data['kind']?.toString();
    final id = widget.data['commentId']?.toString().trim() ?? '';
    return kind == 'comment' || id.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _load();
    blockedListRevision.addListener(_invalidate);
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (_uid != user?.uid) { _uid = user?.uid; _invalidate(); }
    });
  }

  void _invalidate() { _load(); }

  @override
  void didUpdateWidget(covariant _RepostEmbedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data['postId'] != widget.data['postId'] ||
        oldWidget.data['commentId'] != widget.data['commentId'] ||
        oldWidget.data['kind'] != widget.data['kind']) _load();
  }

  @override
  void dispose() {
    blockedListRevision.removeListener(_invalidate);
    _authSubscription?.cancel();
    super.dispose();
  }

  String? _http(String? s) {
    final u = (s ?? '').trim();
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    return null;
  }

  Future<void> _openTarget() async {
    // Recheck on tap, since privacy or deletion may have changed after rendering.
    if (!await _load() || !mounted) return;
    final post = _post;
    if (post == null) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CommentsScreen(
      post: post, initialCommentId: _isCommentRepost ? widget.data['commentId']?.toString() : null,
    )));
    if (!mounted) return;
    widget.onChanged?.call();
    await _load();
  }

  Future<bool> _load() async {
    if (!mounted) return false;
    final generation = ++_loadGeneration;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final id = widget.data['postId']?.toString().trim();
    final commentId = widget.data['commentId']?.toString().trim();
    final commentQuote = _isCommentRepost;
    setState(() { _loading = true; _post = null; _authorizedQuote = {}; _loadError = null; });
    try {
      final data = await _readAuthorizedPostData(id);
      final post = _Post.fromData(id!, data);
      Map<String, dynamic> quote = {};
      if (commentQuote) {
        Map<String, dynamic>? find(dynamic rows, [int depth = 0]) {
          if (rows is! List || depth > 30) return null;
          for (final row in rows) {
            if (row is! Map) continue;
            if (row['id'] == commentId) return Map<String, dynamic>.from(row);
            final hit = find(row['replies'], depth + 1);
            if (hit != null) return hit;
          }
          return null;
        }
        if (commentId == null || commentId.isEmpty) throw StateError('Missing comment');
        final raw = find(data['comments']);
        if (raw == null) throw StateError('Comment unavailable');
        final comment = _commentFromMap(raw);
        quote = {'commentAuthor': comment.author, 'commentAuthorId': comment.authorId,
          'commentAuthorPhotoUrl': comment.authorPhotoUrl, 'commentText': comment.text,
          'commentMediaUrl': comment.mediaUrl, 'commentMediaType': comment.mediaType, 'title': post.title};
      }
      if (!mounted || generation != _loadGeneration || FirebaseAuth.instance.currentUser?.uid != uid) return false;
      setState(() { _post = post; _authorizedQuote = quote; _loading = false; });
      return true;
    } catch (_) {
      if (!mounted || generation != _loadGeneration) return false;
      setState(() { _loading = false; _post = null; _authorizedQuote = {};
        _loadError = mainText(context, "المحتوى الأصلي غير متاح حاليًا. قد يكون محذوفًا أو خاصًا."); });
      return false;
    }
  }

  Widget _mediaHero({
    required bool isDark,
    String? image,
    required bool hasVideo,
  }) {
    if (image == null && !hasVideo) return const SizedBox.shrink();
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (image != null)
            Uri.tryParse(image)?.host == 'firebasestorage.googleapis.com'
                ? _AuthorizedImageView(
                    postId: _post?.id ?? '',
                    commentId: _isCommentRepost ? (widget.data['commentId']?.toString().trim() ?? '') : null,
                    path: image, preview: true,
                  )
                : ProtectedImage.network(
              image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => ColoredBox(
                color: isDark ? Colors.white10 : UniSpaceColors.lightBorder,
              ),
            )
          else
            ColoredBox(
              color: isDark ? UniSpaceColors.darkField : UniSpaceColors.lightBorder,
            ),
          if (hasVideo)
            Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pollStrip(_Post post, ThemeData theme, bool isDark) {
    final polls = post.pollDataList;

    if (polls.isEmpty && post.pollSlides.isEmpty) {
      return const SizedBox.shrink();
    }

    final questions = <String>[];

    for (final slide in post.pollSlides) {
      if (slide['type']?.toString() == 'text') {
        final text = (slide['text'] ?? '').toString().trim();
        if (text.isNotEmpty && !questions.contains(text)) {
          questions.add(text);
        }
      }
    }

    if (polls.isNotEmpty) {
      for (final poll in polls) {
        final pollMap = _pollToMap(poll);
        for (final key in ['question', 'title', 'text', 'prompt']) {
          final value = (pollMap[key] ?? '').toString().trim();
          if (value.isNotEmpty && !questions.contains(value)) {
            questions.add(value);
            break;
          }
        }
      }
    }

    if (questions.isEmpty) {
      final fallback = post.title.trim();
      questions.add(fallback.isNotEmpty ? fallback : mainText(context, "ما رأيك؟"));
    }

    return _pollGlassStyle(
      questions: questions,
      isDark: isDark,
      author: post.author,
      authorId: post.authorId,
    );
  }


  Widget _pollGlassStyle({
    required List<String> questions,

    required bool isDark,
    required String author,
    String? authorId,
  }) {
    final textColor = isDark ? Colors.white : UniSpaceColors.forest;
    final mutedColor = isDark
        ? Colors.white.withValues(alpha: 0.65)
        : UniSpaceColors.lightMuted;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
              Color.lerp(AppTeal.main, UniSpaceColors.darkBackground, 0.72)!,
              Color.lerp(AppTeal.main, UniSpaceColors.darkSurface, 0.88)!,
            ]
                : [
              Color.lerp(AppTeal.main, Colors.white, 0.88)!,
              Color.lerp(AppTeal.main, Colors.white, 0.96)!,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTeal.main.withValues(alpha: 0.28),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.poll_outlined,
                  color: AppTeal.foreground(context),
                  size: 19,
                ),
                const SizedBox(width: 7),
                Text(
                  mainText(context, "Poll"),
                  style: TextStyle(
                    color: AppTeal.foreground(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: questions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  return Container(
                    width: 160,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: isDark ? 0.07 : 0.65),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.85),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppTeal.main.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: AppTeal.foreground(context),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            questions[i],
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              height: 1.3,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AppTeal.main;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : UniSpaceColors.lightBorder;
    final fill = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white;

    if (_loading) {
      return Container(
        height: 88,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_loadError != null || _post == null) {
      return Container(padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
        child: Column(children: [
          Text(_loadError ?? mainText(context, "المحتوى الأصلي غير متاح"), textAlign: TextAlign.center),
          TextButton(onPressed: _invalidate, child:  Text(mainText(context, "إعادة المحاولة"))),
        ]));
    }

    if (_isCommentRepost) {
      final author =
      (_authorizedQuote['commentAuthor'] ?? mainText(context, "طالب UniSpace")).toString();
      final authorId = _authorizedQuote['commentAuthorId']?.toString();
      final photo = _authorizedQuote['commentAuthorPhotoUrl']?.toString();
      final text =
      (_authorizedQuote['commentText'] ?? _authorizedQuote['body'] ?? '')
          .toString()
          .trim();
      final mediaType = _authorizedQuote['commentMediaType']?.toString();
      final mediaUrl = _authorizedQuote['commentMediaUrl']?.toString();
      final image = (mediaType == 'image' || mediaType == 'gif')
          ? _http(mediaUrl)
          : null;
      final hasVideo = mediaType == 'video';
      final t = (_authorizedQuote['title'] ?? '').toString().trim();
      final footer = t.isEmpty ? mainText(context, "تعليق أصلي") : mainText(context, "تعليق على: {0}", <Object?>[t]);

      return _ogShell(
        theme: theme,
        isDark: isDark,
        accent: accent,
        border: border,
        fill: fill,
        onTap: _openTarget,
        hero: _mediaHero(isDark: isDark, image: image, hasVideo: hasVideo),
        author: author,
        authorId: authorId,
        photo: photo,
        time: '',
        title: text,
        snippet: '',
        extra: null,
        footer: footer,
      );
    }

    final post = _post;
    if (post == null) return const SizedBox.shrink();

    String? image;
    for (final p in post.imagePaths) {
      image = _http(p);
      if (image != null) break;
    }
    final hasVideo = post.videoPaths.any((p) => p.trim().isNotEmpty);
    final title = post.title.trim();
    final snippet = post.body.trim();

    return _ogShell(
      theme: theme,
      isDark: isDark,
      accent: accent,
      border: border,
      fill: fill,
      onTap: _openTarget,
      hero: _mediaHero(isDark: isDark, image: image, hasVideo: hasVideo),
      author: post.author,
      authorId: post.authorId,
      photo: post.authorPhotoUrl,
      time: post.timeAgo,
      title: title,
      snippet: snippet,
      extra: _pollStrip(post, theme, isDark),
      footer: post.pollDataList.isNotEmpty || post.pollSlides.isNotEmpty
          ? mainText(context, "استطلاع أصلي · UniSpace")
          : mainText(context, "منشور أصلي · UniSpace"),
    );
  }

  Widget _ogShell({
    required ThemeData theme,
    required bool isDark,
    required Color accent,
    required Color border,
    required Color fill,
    required VoidCallback onTap,
    required Widget hero,
    required String author,
    required String? authorId,
    required String? photo,
    required String time,
    required String title,
    required String snippet,
    required Widget? extra,
    required String footer,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              hero,
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        PublicProfilePhoto(
                          userId: authorId ?? '',
                          fallbackUrl: photo,
                          size: 24,
                          radius: 12,
                          iconSize: 12,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(author, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        ),
                        if (time.isNotEmpty)
                          Text(
                            time,
                            style: TextStyle(
                              color: theme.hintColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    if (title.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        title,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          height: 1.3,
                        ),
                      ),
                    ],
                    if (snippet.isNotEmpty && snippet != title) ...[
                      const SizedBox(height: 4),
                      Text(
                        snippet,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                    if (extra != null) extra,
                    const SizedBox(height: 8),
                    Text(
                      footer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _CommentRepostPreview extends StatelessWidget {
  const _CommentRepostPreview({
    required this.postId,
    required this.commentId,
    required this.author,
    this.authorId,
    this.authorPhotoUrl,
    required this.text,
    this.timeLabel,
    this.mediaUrl,
    this.mediaType,
    this.contextLabel,
  });

  final String postId, commentId;
  final String author;
  final String? authorPhotoUrl;
  final String text;
  final String? timeLabel;
  final String? mediaUrl;
  final String? mediaType;
  final String? contextLabel;
  final String? authorId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final accent = AppTeal.main;
    final url = (mediaUrl ?? '').trim();
    final type = (mediaType ?? '').trim().toLowerCase();

    final validUrl =
        url.startsWith('http://') || url.startsWith('https://');

    final hasImage =
        validUrl && (type == 'image' || type == 'gif');

    final hasVideo =
        validUrl && type == 'video';

    final hasMedia = hasImage || hasVideo;

    final background = isDark
        ? UniSpaceColors.darkSurface
        : Colors.white;

    final secondaryBackground = isDark
        ? UniSpaceColors.darkField
        : UniSpaceColors.lightField;

    final primaryText = isDark
        ? Colors.white
        : UniSpaceColors.forest;

    final mutedText = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : UniSpaceColors.lightMuted;

    return Directionality(
      textDirection: Directionality.of(context),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.09)
                : UniSpaceColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: isDark ? 0.25 : 0.08,
              ),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _buildTopBanner(
              accent: accent,
              isDark: isDark,
            ),

            Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    _buildAuthorSection(
                      primaryText: primaryText,
                      mutedText: mutedText,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 14),

                    if (text.trim().isNotEmpty)
                      _buildCommentSection(
                        accent: accent,
                        secondaryBackground: secondaryBackground,
                        primaryText: primaryText,
                        isDark: isDark,
                      ),

                    if (hasMedia) ...[
                      const SizedBox(height: 15),
                      _buildMediaSection(
                        url: url,
                        hasImage: hasImage,
                        hasVideo: hasVideo,
                        accent: accent,
                        isDark: isDark,
                      ),
                    ],

                    const SizedBox(height: 16),

                    _buildBottomInfo(
                      accent: accent,
                      mutedText: mutedText,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBanner({
    required Color accent,
    required bool isDark,
  }) {
    return Container(
      height: 108,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            accent,
            Color.alphaBlend(
              Colors.black.withValues(alpha: 0.20),
              accent,
            ),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -35,
            left: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -42,
            right: 75,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.30),
                  ),
                ),
                child: const Icon(
                  Icons.repeat_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(
                      mainTextCurrent("إعادة نشر تعليق"),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      mainTextCurrent("مشاركة رأي من المجتمع"),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if ((timeLabel ?? '').trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    timeLabel!.trim(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorSection({
    required Color primaryText,
    required Color mutedText,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isDark
                ? UniSpaceColors.darkSurface
                : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: LiveAuthorPhoto(
            userId: authorId,
            fallbackUrl: authorPhotoUrl,
            size: 52,
            radius: 26,
            iconSize: 21,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: AuthorProfiles.revision,
            builder: (context, _, __) {
              if ((authorId ?? '').isNotEmpty) {
                AuthorProfiles.ensure(authorId!);
              }

              final liveName =
              AuthorProfiles.nameOf(authorId)?.trim();

              final resolvedName =
              liveName != null && liveName.isNotEmpty
                  ? liveName
                  : author.trim();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resolvedName.isEmpty ? mainText(context, "مستخدم") : resolvedName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 13,
                        color: mutedText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        mainText(context, "تعليق منقول"),
                        style: TextStyle(
                          color: mutedText,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : UniSpaceColors.lightField,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.more_horiz_rounded,
            color: mutedText,
            size: 21,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentSection({
    required Color accent,
    required Color secondaryBackground,
    required Color primaryText,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      decoration: BoxDecoration(
        color: secondaryBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : UniSpaceColors.lightField,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Icon(
              Icons.format_quote_rounded,
              size: 33,
              color: accent.withValues(alpha: 0.22),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  constraints: const BoxConstraints(
                    minHeight: 34,
                  ),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text.trim(),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryText,
                      fontSize: 14.5,
                      height: 1.5,
                      fontWeight: FontWeight(650),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection({
    required String url,
    required bool hasImage,
    required bool hasVideo,
    required Color accent,
    required bool isDark,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 1.55,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              Uri.tryParse(url)?.host == 'firebasestorage.googleapis.com'
                  ? _AuthorizedImageView(postId: postId, commentId: commentId, path: url, preview: true)
                  : ProtectedImage.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return _buildMediaPlaceholder(
                    isDark: isDark,
                    icon: Icons.image_not_supported_outlined,
                  );
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;

                  return _buildMediaPlaceholder(
                    isDark: isDark,
                    icon: Icons.hourglass_empty_rounded,
                  );
                },
              )
            else
              _buildMediaPlaceholder(
                isDark: isDark,
                icon: Icons.video_library_outlined,
              ),

            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.45),
                  ],
                ),
              ),
            ),

            if (hasVideo)
              Center(
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.75),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),

            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasVideo
                          ? Icons.videocam_rounded
                          : Icons.image_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      hasVideo ? mainTextCurrent("فيديو") : mainTextCurrent("صورة"),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPlaceholder({
    required bool isDark,
    required IconData icon,
  }) {
    return Container(
      color: isDark
          ? UniSpaceColors.darkContainer
          : UniSpaceColors.lightField,
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: isDark
            ? Colors.white.withValues(alpha: 0.45)
            : UniSpaceColors.lightMuted,
        size: 42,
      ),
    );
  }

  Widget _buildBottomInfo({
    required Color accent,
    required Color mutedText,
    required bool isDark,
  }) {
    final label = (contextLabel ?? '').trim().isEmpty
        ? mainTextCurrent("تعليق أصلي")
        : contextLabel!.trim();

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Icon(
          Icons.verified_rounded,
          color: accent,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          mainTextCurrent("محتوى موثّق"),
          style: TextStyle(
            color: mutedText,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}





/// Only the relative date rebuilds each minute, never the media/post subtree.
class _PostTimeLabel extends StatefulWidget {
  const _PostTimeLabel({required this.label, required this.style});
  final String Function() label;
  final TextStyle style;
  @override
  State<_PostTimeLabel> createState() => _PostTimeLabelState();
}
class _PostTimeLabelState extends State<_PostTimeLabel> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && TickerMode.of(context) &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) setState(() {});
    });
  }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Text(widget.label(), maxLines: 1,
      overflow: TextOverflow.ellipsis, style: widget.style);
}
