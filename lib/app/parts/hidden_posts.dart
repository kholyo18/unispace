part of '../../main.dart';

class HiddenPostsScreen extends StatefulWidget {
  const HiddenPostsScreen({super.key});

  @override
  State<HiddenPostsScreen> createState() => _HiddenPostsScreenState();
}

class _HiddenPostsScreenState extends State<HiddenPostsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _postsGeneration = 0, _commentsGeneration = 0;
  String? _uid;
  StreamSubscription<User?>? _auth;
  bool _current(String uid, int generation, bool comments) => mounted &&
      FirebaseAuth.instance.currentUser?.uid == uid &&
      generation == (comments ? _commentsGeneration : _postsGeneration);
  void _refreshAccess() { if (mounted) { _loadPosts(); _loadComments(); } }

  Future<Map<String, _Post>> _readHiddenPostContent(
    Iterable<String> input, String uid, int generation, bool comments,
  ) async {
    final ids = input.map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final posts = <String, _Post>{};
    for (var i = 0; i < ids.length; i += 5) {
      if (!_current(uid, generation, comments)) return {};
      final end = i + 5 < ids.length ? i + 5 : ids.length;
      await Future.wait(ids.sublist(i, end).map((id) async {
        try {
          final data = await _readAuthorizedPostData(id);
          if (_current(uid, generation, comments)) posts[id] = _Post.fromData(id, data);
        } on FirebaseFunctionsException catch (error) {
          if (error.code != 'not-found') rethrow;
        }
      }));
    }
    return posts;
  }

  // ===== منشورات =====
  bool _loadingPosts = true;
  String? _postsError;
  List<_Post> _posts = [];

  // ===== تعليقات =====
  bool _loadingComments = true;
  String? _commentsError;
  List<_CommentSearchHit> _hiddenComments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted || user?.uid == _uid) return;
      _uid = user?.uid;
      _refreshAccess();
    });
    blockedListRevision.addListener(_refreshAccess);
    hiddenListRevision.addListener(_refreshAccess);
    authorProfileRevision.addListener(_refreshAccess);
    moderationRevision.addListener(_refreshAccess);
    _refreshAccess();
  }

  @override
  void dispose() {
    _postsGeneration++; _commentsGeneration++;
    _auth?.cancel();
    blockedListRevision.removeListener(_refreshAccess);
    hiddenListRevision.removeListener(_refreshAccess);
    authorProfileRevision.removeListener(_refreshAccess);
    moderationRevision.removeListener(_refreshAccess);
    _tabController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // منشورات
  // ---------------------------------------------------------------------
  Future<void> _loadPosts() async {
    if (!mounted) return;
    final generation = ++_postsGeneration;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _posts = [];
        _loadingPosts = false;
        _postsError = "يجب تسجيل الدخول أولاً";
      });
      return;
    }
    setState(() {
      _posts = [];
      _loadingPosts = true;
      _postsError = null;
    });
    try {
      final hiddenSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('hidden_posts')
          .get();
      final ids = hiddenSnap.docs.map((d) => d.id).toList();
      if (ids.isEmpty) {
        if (!_current(uid, generation, false)) return;
        setState(() {
          _posts = [];
          _loadingPosts = false;
        });
        return;
      }

      final authorized = await _readHiddenPostContent(ids, uid, generation, false);
      final posts = authorized.values.toList();
      if (!_current(uid, generation, false)) return;
      setState(() {
        _posts = posts;
        _loadingPosts = false;
      });
    } catch (e) {
      debugPrint('load hidden posts failed: $e');
      if (!_current(uid, generation, false)) return;
      setState(() {
        _loadingPosts = false;
        _postsError = mainText(context, "تعذر تحميل المنشورات المخفية");
      });
    }
  }

  Future<void> _unhidePost(String postId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('hidden_posts')
          .doc(postId)
          .delete();
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != uid) return;
      setState(() => _posts.removeWhere((p) => p.id == postId));
      hiddenListRevision.value++;
    } catch (e) {
      debugPrint('unhide post failed: $e');
    }
  }

  // ---------------------------------------------------------------------
  // تعليقات
  // ---------------------------------------------------------------------
  Future<void> _loadComments() async {
    if (!mounted) return;
    final generation = ++_commentsGeneration;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _hiddenComments = [];
        _loadingComments = false;
        _commentsError = "يجب تسجيل الدخول أولاً";
      });
      return;
    }
    setState(() {
      _hiddenComments = [];
      _loadingComments = true;
      _commentsError = null;
    });
    try {
      final hiddenSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('hidden_comments')
          .get();

      final Map<String, List<String>> byPost = {};
      for (final d in hiddenSnap.docs) {
        final data = d.data();
        final postId = (data['postId'] ?? '').toString();
        final commentId = (data['commentId'] ?? d.id).toString();
        if (postId.isEmpty || commentId.isEmpty) continue;
        byPost.putIfAbsent(postId, () => []).add(commentId);
      }

      if (byPost.isEmpty) {
        if (!_current(uid, generation, true)) return;
        setState(() {
          _hiddenComments = [];
          _loadingComments = false;
        });
        return;
      }

      final posts = await _readHiddenPostContent(byPost.keys, uid, generation, true);
      if (!_current(uid, generation, true)) return;

      _Comment? find(_Comment c, String id) {
        if (c.id == id) return c;
        for (final r in c.replies) {
          final f = find(r, id);
          if (f != null) return f;
        }
        return null;
      }

      final hits = <_CommentSearchHit>[];
      byPost.forEach((postId, commentIds) {
        final post = posts[postId];
        if (post == null) return;
        for (final cid in commentIds) {
          _Comment? found;
          for (final c in post.comments) {
            found = find(c, cid);
            if (found != null) break;
          }
          if (found != null) {
            hits.add(_CommentSearchHit(post: post, comment: found));
          }
        }
      });

      if (!_current(uid, generation, true)) return;
      setState(() {
        _hiddenComments = hits;
        _loadingComments = false;
      });
    } catch (e) {
      debugPrint('load hidden comments failed: $e');
      if (!_current(uid, generation, true)) return;
      setState(() {
        _loadingComments = false;
        _commentsError = mainText(context, "تعذر تحميل التعليقات المخفية");
      });
    }
  }

  Future<void> _unhideComment(String commentId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('hidden_comments')
          .doc(commentId)
          .delete();
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != uid) return;
      setState(
          () =>
          _hiddenComments.removeWhere((h) => h.comment.id == commentId));
      hiddenListRevision.value++;
    } catch (e) {
      debugPrint('unhide comment failed: $e');
    }
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final t = _ProfileTheme.of(context);
    return Scaffold(
      backgroundColor: t.pageBg,
      appBar: AppBar(
        title:  Text(mainText(context, "العناصر المخفية")),
        backgroundColor: t.pageBg,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          labelColor: t.textPrimary,
          unselectedLabelColor: t.textFaint,
          indicatorColor: AppTeal.main,
          tabs:  [
            Tab(text: mainText(context, "منشورات")),
            Tab(text: mainText(context, "تعليقات")),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostsTab(),
          _buildCommentsTab(),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: _loadingPosts
          ? const Center(child: CircularProgressIndicator())
          : _postsError != null
          ? ListView(
        children: [
          const SizedBox(height: 80),
          Center(child: Text(mainText(context, _postsError!))),
          TextButton(onPressed: _loadPosts, child:  Text(mainText(context, "إعادة المحاولة"))),
        ],
      )
          : _posts.isEmpty
          ? ListView(
        children:  [
          SizedBox(height: 80),
          EmptyState(
            icon: Icons.visibility_off_outlined,
            title: mainText(context, "لا توجد منشورات مخفية"),
          ),
        ],
      )
          : ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        itemCount: _posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final p = _posts[i];
          return Stack(
            clipBehavior: Clip.none,
            children: [
              _RedditStylePostCard(
                post: p,
                accent: Theme.of(context).colorScheme.primary,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: p.id == null ? null : () => _unhidePost(p.id!),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.visibility_off_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCommentsTab() {
    return RefreshIndicator(
      onRefresh: _loadComments,
      child: _loadingComments
          ? const Center(child: CircularProgressIndicator())
          : _commentsError != null
          ? ListView(
        children: [
          const SizedBox(height: 80),
          Center(child: Text(mainText(context, _commentsError!))),
          TextButton(onPressed: _loadComments, child:  Text(mainText(context, "إعادة المحاولة"))),
        ],
      )
          : _hiddenComments.isEmpty
          ? ListView(
        children:  [
          SizedBox(height: 80),
          EmptyState(
            icon: Icons.visibility_off_outlined,
            title: mainText(context, "لا توجد تعليقات مخفية"),
          ),
        ],
      )
          : ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        itemCount: _hiddenComments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final hit = _hiddenComments[i];
          return Stack(
            clipBehavior: Clip.none,
            children: [
              _RedditStyleCommentTile(
                hit: hit,
                accent: Theme.of(context).colorScheme.primary,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _unhideComment(hit.comment.id),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.visibility_off_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


