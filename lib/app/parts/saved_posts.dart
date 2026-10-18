part of '../../main.dart';

enum SavedItemType {
  post,
  comment,
}

class _SavedListItem {
  const _SavedListItem({
    required this.type,
    required this.savedAt,
    this.post,
    this.savedComment,
    this.commentHit,
  });

  final SavedItemType type;
  final DateTime? savedAt;

  final _Post? post;
  final _SavedComment? savedComment;
  final _CommentSearchHit? commentHit;

  bool get isPost => type == SavedItemType.post;

  bool get isComment => type == SavedItemType.comment;

  String get id {
    if (isPost) {
      return post?.id ?? '';
    }

    return savedComment?.commentId ?? '';
  }
}

class _SavedComment {
  const _SavedComment({
    required this.commentId,
    required this.postId,
    required this.author,
    required this.text,
    this.authorId,
    this.authorPhotoUrl,
    this.mediaUrl,
    this.mediaType,
    this.postTitle,
  });

  final String commentId;
  final String postId;
  final String author;
  final String? authorId;
  final String? authorPhotoUrl;
  final String text;
  final String? mediaUrl;
  final String? mediaType;
  final String? postTitle;

  factory _SavedComment.fromMap(
      String id,
      Map<String, dynamic> data,
      ) {
    return _SavedComment(
      commentId: (data['commentId'] ?? id).toString(),
      postId: (data['postId'] ?? '').toString(),
      author: (data['author'] ?? mainTextCurrent("طالب UniSpace")).toString(),
      authorId: data['authorId']?.toString(),
      authorPhotoUrl: data['authorPhotoUrl']?.toString(),
      text: (data['text'] ?? '').toString(),
      mediaUrl: data['mediaUrl']?.toString(),
      mediaType: data['mediaType']?.toString(),
      postTitle: data['postTitle']?.toString(),
    );
  }
}

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  static const int _pageSize = 20;
  static const int _whereInLimit = 5;
  int _generation = 0;
  String? _uid;
  StreamSubscription<User?>? _authSub;
  bool _current(int generation, String uid) => mounted &&
      generation == _generation && FirebaseAuth.instance.currentUser?.uid == uid;
  void _refreshAccess() { if (mounted) _load(); }

  final TextEditingController _searchController =
  TextEditingController();

  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  bool _loadingMore = false;
  bool _isSearchOpen = false;

  String? _error;

  int _selectedTab = 0;
  String _searchQuery = '';

  final List<_SavedListItem> _items = [];

  DocumentSnapshot<Map<String, dynamic>>? _postsCursor;
  DocumentSnapshot<Map<String, dynamic>>? _commentsCursor;

  bool _hasMorePosts = true;
  bool _hasMoreComments = true;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);

    _uid = FirebaseAuth.instance.currentUser?.uid;
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user?.uid == _uid || !mounted) return;
      _uid = user?.uid;
      _load();
    });
    blockedListRevision.addListener(_refreshAccess);
    authorProfileRevision.addListener(_refreshAccess);
    _load();
  }

  @override
  void dispose() {
    _generation++;
    _authSub?.cancel();
    blockedListRevision.removeListener(_refreshAccess);
    authorProfileRevision.removeListener(_refreshAccess);
    _searchController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  DateTime? _savedAtOf(Map<String, dynamic> data) {
    final raw = data['savedAt'];

    if (raw is Timestamp) {
      return raw.toDate();
    }

    if (raw is DateTime) {
      return raw;
    }

    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }

    return null;
  }

  void _sortItems() {
    _items.sort((a, b) {
      if (a.savedAt == null && b.savedAt == null) {
        return 0;
      }

      if (a.savedAt == null) {
        return 1;
      }

      if (b.savedAt == null) {
        return -1;
      }

      return b.savedAt!.compareTo(a.savedAt!);
    });
  }

  _Comment? _findComment(
      List<_Comment> comments,
      String id,
      ) {
    for (final comment in comments) {
      if (comment.id == id) {
        return comment;
      }

      final nested = _findComment(
        comment.replies,
        id,
      );

      if (nested != null) {
        return nested;
      }
    }

    return null;
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;

    if (position.pixels >= position.maxScrollExtent - 500) {
      _loadMore();
    }
  }

  Query<Map<String, dynamic>> _savedCollectionQuery({
    required String uid,
    required String collectionName,
    required DocumentSnapshot<Map<String, dynamic>>? cursor,
  }) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(collectionName)
        .orderBy(FieldPath.documentId)
        .limit(_pageSize);

    if (cursor != null) {
      query = query.startAfterDocument(cursor);
    }

    return query;
  }

  Future<Map<String, _Post>> _fetchPostsByIds(
      Iterable<String> ids, int generation, String uid,
      ) async {
    final cleanIds = ids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final result = <String, _Post>{};

    if (cleanIds.isEmpty) {
      return result;
    }

    for (var i = 0; i < cleanIds.length; i += _whereInLimit) {
      final end = (i + _whereInLimit < cleanIds.length)
          ? i + _whereInLimit
          : cleanIds.length;

      final chunk = cleanIds.sublist(i, end);

      if (!_current(generation, uid)) return {};
      await Future.wait(chunk.map((id) async {
        try {
          final data = await _readAuthorizedPostData(id);
          if (_current(generation, uid)) result[id] = _Post.fromData(id, data);
        } on FirebaseFunctionsException catch (error) {
          if (error.code != 'not-found') rethrow;
        }
      }));
    }

    return result;
  }

  Future<void> _loadPostsPage({
    required String uid,
    required bool reset,
    required int generation,
  }) async {
    if (!reset && !_hasMorePosts) {
      return;
    }

    final query = _savedCollectionQuery(
      uid: uid,
      collectionName: 'saved_posts',
      cursor: reset ? null : _postsCursor,
    );

    final savedSnapshot = await query.get();
    if (!_current(generation, uid)) return;

    if (savedSnapshot.docs.isEmpty) {
      _hasMorePosts = false;
      return;
    }

    _postsCursor = savedSnapshot.docs.last;

    if (savedSnapshot.docs.length < _pageSize) {
      _hasMorePosts = false;
    }

    final hiddenPosts = await loadHiddenPostIds();

    final validSavedDocs = savedSnapshot.docs.where((savedDocument) {
      final postId = savedDocument.id.trim();

      return postId.isNotEmpty &&
          !hiddenPosts.contains(postId);
    }).toList();

    if (validSavedDocs.isEmpty) {
      return;
    }

    final posts = await _fetchPostsByIds(
      validSavedDocs.map((document) => document.id), generation, uid,
    );

    if (!_current(generation, uid)) return;
    for (final savedDocument in validSavedDocs) {
      final postId = savedDocument.id.trim();
      final post = posts[postId];

      if (post == null) {
        continue;
      }

      _items.add(
        _SavedListItem(
          type: SavedItemType.post,
          savedAt: _savedAtOf(savedDocument.data()),
          post: post,
        ),
      );
    }
  }

  Future<void> _loadCommentsPage({
    required String uid,
    required bool reset,
    required int generation,
  }) async {
    if (!reset && !_hasMoreComments) {
      return;
    }

    final query = _savedCollectionQuery(
      uid: uid,
      collectionName: 'saved_comments',
      cursor: reset ? null : _commentsCursor,
    );

    final commentsSnapshot = await query.get();
    if (!_current(generation, uid)) return;

    if (commentsSnapshot.docs.isEmpty) {
      _hasMoreComments = false;
      return;
    }

    _commentsCursor = commentsSnapshot.docs.last;

    if (commentsSnapshot.docs.length < _pageSize) {
      _hasMoreComments = false;
    }

    final hiddenPosts = await loadHiddenPostIds();

    final hiddenCommentsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('hidden_comments')
        .get();

    final hiddenComments = hiddenCommentsSnapshot.docs
        .map((document) => document.id).toSet();

    final validComments = <MapEntry<
        QueryDocumentSnapshot<Map<String, dynamic>>,
        _SavedComment>>[];

    for (final savedDocument in commentsSnapshot.docs) {
      final data = savedDocument.data();

      final commentId = savedDocument.id;
      final savedComment = _SavedComment.fromMap(
        commentId,
        data,
      );

      final postId = savedComment.postId.trim();

      if (hiddenComments.contains(commentId)) {
        continue;
      }

      if (postId.isNotEmpty && hiddenPosts.contains(postId)) {
        continue;
      }

      validComments.add(
        MapEntry(
          savedDocument,
          savedComment,
        ),
      );
    }

    if (validComments.isEmpty) {
      return;
    }

    final posts = await _fetchPostsByIds(
      validComments.map((entry) => entry.value.postId), generation, uid,
    );

    if (!_current(generation, uid)) return;
    for (final entry in validComments) {
      final savedDocument = entry.key;
      final savedComment = entry.value;

      final postId = savedComment.postId.trim();
      final realPost = posts[postId];

      if (realPost == null) continue;
      final foundComment = _findComment(realPost.comments, savedComment.commentId);
      if (foundComment == null) continue;
      final post = realPost;
      final currentComment = _SavedComment(
        commentId: foundComment.id, postId: postId,
        author: foundComment.author, authorId: foundComment.authorId,
        authorPhotoUrl: foundComment.authorPhotoUrl, text: foundComment.text,
        mediaUrl: foundComment.mediaUrl, mediaType: foundComment.mediaType,
        postTitle: realPost.title,
      );

      _items.add(
        _SavedListItem(
          type: SavedItemType.comment,
          savedAt: _savedAtOf(savedDocument.data()),
          savedComment: currentComment,
          commentHit: _CommentSearchHit(
            post: post,
            comment: foundComment,
          ),
        ),
      );
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    final generation = ++_generation;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = "يجب تسجيل الدخول أولاً";
        _items.clear();
      });

      return;
    }

    setState(() {
      _loading = true;
      _loadingMore = false;
      _error = null;

      _items.clear();

      _postsCursor = null;
      _commentsCursor = null;

      _hasMorePosts = true;
      _hasMoreComments = true;
    });

    try {
      await Future.wait([
        _loadPostsPage(
          uid: uid,
          reset: true,
          generation: generation,
        ),
        _loadCommentsPage(
          uid: uid,
          reset: true,
          generation: generation,
        ),
      ]);

      if (!_current(generation, uid)) return;
      _sortItems();

      setState(() {
        _loading = false;
      });
    } catch (e) {
      debugPrint('load saved items failed: $e');

      if (!_current(generation, uid)) return;

      setState(() {
        _loading = false;
        _items.clear();
        _error = mainText(context, "تعذر تحميل المحفوظات");
      });
    }
  }

  Future<void> _loadMore() async {
    if (!mounted || _error != null || _loading || _loadingMore) {
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return;
    }

    final generation = _generation;
    final loadPosts =
        _selectedTab == 0 || _selectedTab == 1;

    final loadComments =
        _selectedTab == 0 || _selectedTab == 2;

    final noMorePosts =
        !loadPosts || !_hasMorePosts;

    final noMoreComments =
        !loadComments || !_hasMoreComments;

    if (noMorePosts && noMoreComments) {
      return;
    }

    setState(() {
      _loadingMore = true;
    });

    try {
      final futures = <Future<void>>[];

      if (loadPosts && _hasMorePosts) {
        futures.add(
          _loadPostsPage(
            uid: uid,
            reset: false,
            generation: generation,
          ),
        );
      }

      if (loadComments && _hasMoreComments) {
        futures.add(
          _loadCommentsPage(
            uid: uid,
            reset: false,
            generation: generation,
          ),
        );
      }

      await Future.wait(futures);
      if (!_current(generation, uid)) return;
      _sortItems();
    } catch (e) {
      debugPrint('load more saved items failed: $e');
      if (!_current(generation, uid)) return;
      _items.clear();
      _error = mainText(context, "تعذر تحميل المحفوظات");
    } finally {
      if (!_current(generation, uid)) return;

      setState(() {
        _loadingMore = false;
      });
    }
  }

  List<_SavedListItem> get _visibleItems {
    final query = _searchQuery.trim().toLowerCase();

    return _items.where((item) {
      final matchesTab = switch (_selectedTab) {
        0 => true,
        1 => item.isPost,
        2 => item.isComment,
        _ => true,
      };

      if (!matchesTab) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      if (item.isPost && item.post != null) {
        final post = item.post!;

        return post.title.toLowerCase().contains(query) ||
            post.body.toLowerCase().contains(query) ||
            post.author.toLowerCase().contains(query);
      }

      if (item.isComment && item.savedComment != null) {
        final comment = item.savedComment!;

        return comment.text.toLowerCase().contains(query) ||
            comment.author.toLowerCase().contains(query) ||
            (comment.postTitle ?? '').toLowerCase().contains(query);
      }

      return false;
    }).toList();
  }

  String get _emptyTitle {
    switch (_selectedTab) {
      case 1:
        return mainText(context, "لا توجد منشورات محفوظة");
      case 2:
        return mainText(context, "لا توجد تعليقات محفوظة");
      default:
        return mainText(context, "لا توجد محفوظات");
    }
  }

  String get _emptySubtitle {
    if (_searchQuery.trim().isNotEmpty) {
      return mainText(context, "جرّب استخدام كلمات بحث مختلفة");
    }

    return mainText(context, "احفظ المنشورات أو التعليقات المهمة لتجدها هنا لاحقًا");
  }

  Future<void> _openSavedComment(
      _SavedComment savedComment,
      ) async {
    final postId = savedComment.postId.trim();

    if (postId.isEmpty) {
      _showMessage(mainText(context, "المنشور الأصلي غير موجود"));
      return;
    }

    try {
      final generation = _generation;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final data = await _readAuthorizedPostData(postId);
      if (!_current(generation, uid)) return;
      final post = _Post.fromData(postId, data);
      if (_findComment(post.comments, savedComment.commentId) == null) {
        _showMessage(mainText(context, "التعليق لم يعد متاحاً"));
        return;
      }

      final changed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => CommentsScreen(
            post: post,
            initialCommentId: savedComment.commentId,
          ),
        ),
      );

      if (changed == true && mounted) {
        await _load();
      }
    } catch (e) {
      debugPrint('open saved comment failed: $e');

      if (!mounted) return;

      _showMessage(mainText(context, "تعذر فتح التعليق"));
    }
  }

  Future<void> _unsavePost(
      String postId, {
        required _SavedListItem item,
      }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return;
    }

    final index = _items.indexOf(item);

    setState(() {
      _items.remove(item);
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('saved_posts')
          .doc(postId)
          .delete();

      if (!mounted) return;

      _showUndoMessage(
        message: mainText(context, "تم إلغاء حفظ المنشور"),
        onUndo: () async {
          await _restorePost(
            uid: uid,
            postId: postId,
            item: item,
            index: index,
          );
        },
      );
    } catch (e) {
      debugPrint('unsave post failed: $e');

      if (!mounted) return;

      _restoreItem(
        item: item,
        index: index,
      );

      _showMessage(mainText(context, "تعذر إلغاء حفظ المنشور"));
    }
  }

  Future<void> _unsaveComment(
      String commentId, {
        required _SavedListItem item,
      }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return;
    }

    final index = _items.indexOf(item);

    setState(() {
      _items.remove(item);
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('saved_comments')
          .doc(commentId)
          .delete();

      if (!mounted) return;

      _showUndoMessage(
        message: mainText(context, "تم إلغاء حفظ التعليق"),
        onUndo: () async {
          await _restoreComment(
            uid: uid,
            commentId: commentId,
            item: item,
            index: index,
          );
        },
      );
    } catch (e) {
      debugPrint('unsave comment failed: $e');

      if (!mounted) return;

      _restoreItem(
        item: item,
        index: index,
      );

      _showMessage(mainText(context, "تعذر إلغاء حفظ التعليق"));
    }
  }

  Future<void> _restorePost({
    required String uid,
    required String postId,
    required _SavedListItem item,
    required int index,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('saved_posts')
          .doc(postId)
          .set({
        'savedAt': item.savedAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(item.savedAt!),
      });

      if (!mounted) return;

      _restoreItem(
        item: item,
        index: index,
      );
    } catch (e) {
      debugPrint('restore saved post failed: $e');

      if (!mounted) return;

      _showMessage(mainText(context, "تعذر التراجع عن إلغاء الحفظ"));
    }
  }

  Future<void> _restoreComment({
    required String uid,
    required String commentId,
    required _SavedListItem item,
    required int index,
  }) async {
    final savedComment = item.savedComment;

    if (savedComment == null) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('saved_comments')
          .doc(commentId)
          .set({
        'commentId': savedComment.commentId,
        'postId': savedComment.postId,
        'author': savedComment.author,
        'authorId': savedComment.authorId,
        'authorPhotoUrl': savedComment.authorPhotoUrl,
        'text': savedComment.text,
        'mediaUrl': savedComment.mediaUrl,
        'mediaType': savedComment.mediaType,
        'postTitle': savedComment.postTitle,
        'savedAt': item.savedAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(item.savedAt!),
      });

      if (!mounted) return;

      _restoreItem(
        item: item,
        index: index,
      );
    } catch (e) {
      debugPrint('restore saved comment failed: $e');

      if (!mounted) return;

      _showMessage(mainText(context, "تعذر التراجع عن إلغاء الحفظ"));
    }
  }

  void _restoreItem({
    required _SavedListItem item,
    required int index,
  }) {
    if (_items.contains(item)) {
      return;
    }

    final safeIndex = index.clamp(0, _items.length).toInt();

    setState(() {
      _items.insert(safeIndex, item);
      _sortItems();
    });
  }

  void _showUndoMessage({
    required String message,
    required VoidCallback onUndo,
  }) {
    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: mainText(context, "تراجع"),
            onPressed: onUndo,
          ),
        ),
      );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  Widget _buildErrorView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        const Icon(
          Icons.cloud_off_outlined,
          size: 56,
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            mainText(context, _error ?? "حدث خطأ غير متوقع"),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label:  Text(mainText(context, "إعادة المحاولة")),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyView() {
    final isSearching = _searchQuery.trim().isNotEmpty;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 90),
        Icon(
          isSearching
              ? Icons.search_off_rounded
              : Icons.bookmark_border_rounded,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            isSearching ? mainText(context, "لا توجد نتائج مطابقة") : _emptyTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _emptySubtitle,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    final visibleItems = _visibleItems;
    final accent = Theme.of(context).colorScheme.primary;

    if (visibleItems.isEmpty) {
      return _buildEmptyView();
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: visibleItems.length + (_loadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index >= visibleItems.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final item = visibleItems[index];

        if (item.isPost && item.post != null) {
          final post = item.post!;

          return _RedditStylePostCard(
            post: post,
            accent: accent,
            onUnsave: post.id == null
                ? null
                : () {
              _unsavePost(
                post.id!,
                item: item,
              );
            },
          );
        }

        final hit = item.commentHit;
        if (hit == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: _RedditStyleCommentTile(
            hit: hit,
            accent: accent,
            onUnsave: () {
              _unsaveComment(
                item.savedComment!.commentId,
                item: item,
              );
            },
          ),
        );

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _buildErrorView();
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: _buildList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,

        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return SizeTransition(
              sizeFactor: animation,
              axis: Axis.horizontal,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: _isSearchOpen
              ? Padding(
            key: const ValueKey('search_field'),
            padding: const EdgeInsetsDirectional.only(
              start: 8,
              end: 4,
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: mainText(context, "البحث في المحفوظات"),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                  onPressed: () {
                    _searchController.clear();

                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.clear),
                ),
                filled: true,
                fillColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          )
              :  Center(child: Text(
            mainText(context, "المحفوظات"),
            key: ValueKey('saved_title'),
                    ),
                  )),
        actions: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _isSearchOpen
                ? IconButton(
              key: const ValueKey('close_search'),
              tooltip: mainText(context, "إغلاق البحث"),
              icon: const Icon(Icons.close),
              onPressed: () {
                _searchController.clear();

                setState(() {
                  _searchQuery = '';
                  _isSearchOpen = false;
                });
              },
            )
                : IconButton(
              key: const ValueKey('open_search'),
              tooltip: mainText(context, "بحث"),
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearchOpen = true;
                });
              },
            ),
          ),
        ],
      ),


      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: _SavedFilterChip(
                    label: mainText(context, "الكل"),
                    selected: _selectedTab == 0,
                    onTap: () {
                      setState(() {
                        _selectedTab = 0;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SavedFilterChip(
                    label: mainText(context, "المنشورات"),
                    selected: _selectedTab == 1,
                    onTap: () {
                      setState(() {
                        _selectedTab = 1;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SavedFilterChip(
                    label: mainText(context, "التعليقات"),
                    selected: _selectedTab == 2,
                    onTap: () {
                      setState(() {
                        _selectedTab = 2;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

}

class _SavedFilterChip extends StatelessWidget {
  const _SavedFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? colors.primary
                : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? colors.onPrimary
                  : colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}




