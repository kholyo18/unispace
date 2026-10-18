part of '../../main.dart';

class _Comment {
  final String id;
  final String author;
  final String? authorId;
  final String? authorPhotoUrl;
  String text;
  final DateTime createdAt;
  final String? replyToAuthor;
  final String? replyToId; // NEW: لازم باش القفز للتعليق الأب يخدم
  int votes;
  bool upvoted;
  bool downvoted;
  final List<_Comment> replies;
  final String? mediaUrl;   // NEW: رابط الصورة/الفيديو/GIF
  final String? mediaType;  // NEW: 'image' | 'video' | 'gif'
  bool isEdited;


  _Comment({
    required this.id,
    required this.author,
    this.authorId,
    this.authorPhotoUrl,
    required this.text,
    required this.createdAt,
    this.replyToAuthor,
    this.replyToId,
    this.votes = 0,
    this.upvoted = false,
    this.downvoted = false,
    List<_Comment>? replies,
    this.mediaUrl,   // NEW
    this.mediaType,
    this.isEdited = false,
  }) : replies = replies ?? [];

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) return '${difference.inSeconds}s';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()}w';
    if (difference.inDays < 365) return '${(difference.inDays / 30).floor()}mo';
    return '${(difference.inDays / 365).floor()}y';
  }

  int get totalReplyCount {
    var n = replies.length;
    for (final r in replies) {
      n += r.totalReplyCount;
    }
    return n;
  }
}
Future<void> _publishAuthorizedRepost(
    {required String expectedUid,
  required String sourcePostId, required _RepostDraft draft, String? commentId}) async {
  if (FirebaseAuth.instance.currentUser?.uid != expectedUid) {
    throw StateError(mainTextCurrent("تغير الحساب أثناء إعادة النشر"));
  }
  final id = FirebaseFirestore.instance.collection('community_posts').doc().id;
  final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
      .httpsCallable('publishRepost', options: HttpsCallableOptions(timeout: const Duration(seconds: 120)))
      .call<Map<String, dynamic>>({'postId': id, 'sourcePostId': sourcePostId,
        'commentId': commentId, 'title': draft.title, 'body': draft.body});
  if (FirebaseAuth.instance.currentUser?.uid != expectedUid ||
      response.data['postId'] != id || response.data['published'] != true) {
    throw StateError(mainTextCurrent("تعذر تأكيد إعادة النشر"));
  }
}

Future<void> _deleteOwnPost(String postId) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
      .httpsCallable('deleteOwnPost')
      .call<Map<String, dynamic>>({'postId': postId});
  if (FirebaseAuth.instance.currentUser?.uid != uid || response.data['postId'] != postId || response.data['deleted'] != true) {
    throw StateError(mainTextCurrent("تعذر تأكيد حذف المنشور"));
  }
}

Future<Map<String, dynamic>> _readAuthorizedPostData(String? postId) async {
  if (postId == null || postId.isEmpty) throw StateError(mainTextCurrent("المنشور غير متاح"));
  final uid = FirebaseAuth.instance.currentUser?.uid;
  final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
      .httpsCallable('readAuthorizedPost', options: HttpsCallableOptions(timeout: const Duration(seconds: 120)))
      .call<Map<String, dynamic>>({'postId': postId});
  if (FirebaseAuth.instance.currentUser?.uid != uid || response.data['id'] != postId || response.data['data'] is! Map) {
    throw StateError(mainTextCurrent("تعذر تأكيد صلاحية عرض المنشور"));
  }
  return Map<String, dynamic>.from(response.data['data'] as Map);
}

class CommentsScreen extends StatefulWidget {
  const CommentsScreen({super.key, required this.post, this.initialCommentId});
  final _Post post;
  final String? initialCommentId;
  @override
  State<CommentsScreen> createState() => _CommentsAccessState();
}

class _CommentsAccessState extends State<CommentsScreen> {
  late Future<_Post> _authorized;
  StreamSubscription<User?>? _authSubscription;
  String? _uid;
  int _revision = 0;
  Future<_Post> _load() async {
    final id = widget.post.id;
    final data = await _readAuthorizedPostData(id);
    return _Post.fromData(id!, data);
  }
  void _reload() {
    if (!mounted) return;
    setState(() { _revision++; _authorized = _load(); });
  }
  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _authorized = _load();
    blockedListRevision.addListener(_reload);
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user?.uid != _uid) { _uid = user?.uid; _reload(); }
    });
  }
  @override
  void didUpdateWidget(covariant CommentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) _reload();
  }
  @override
  void dispose() {
    blockedListRevision.removeListener(_reload);
    _authSubscription?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => FutureBuilder<_Post>(
    key: ValueKey(_revision), future: _authorized,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && !snapshot.hasError) {
        return _CommentsContentScreen(post: snapshot.data!, initialCommentId: widget.initialCommentId);
      }
      return Scaffold(appBar: AppBar(title:  Text(mainText(context, "التعليقات"))),
        body: Center(child: snapshot.connectionState != ConnectionState.done
            ? const CircularProgressIndicator()
            : Column(mainAxisSize: MainAxisSize.min, children: [
                 Text(mainText(context, "تعذر عرض المنشور. قد يكون محذوفًا أو غير متاح لك."), textAlign: TextAlign.center),
                TextButton(onPressed: _reload, child:  Text(mainText(context, "إعادة المحاولة"))),
              ])));
    },
  );
}

class _CommentsContentScreen extends StatefulWidget {
  final _Post post;
  final String? initialCommentId;
  const _CommentsContentScreen(
      {super.key,this.initialCommentId, required this.post});

  @override
  State<_CommentsContentScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<_CommentsContentScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  _Comment? _replyTo;
  CommentAttachment? _attachment; // NEW
  final FocusNode _composerFocusNode = FocusNode();
  bool _isSearching = false;
  String _searchQuery = '';
  List<String> _hiddenWords = [];

  static  Color _primaryTeal = AppTeal.main;
  static const Color _primaryBlue = Color(0xFF1565C0);
  static const Color _lightCyan = Color(0xFFEAF7F8);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _mutedText = Color(0xFF64748B);

  // NEW: خزنة مفاتيح كل تعليق باش نقدرو نمرّرو لأي واحد منهم (القفز للأب)
  final Map<String, GlobalKey> _commentKeys = {};

  static String _timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return mainTextCurrent("منذ {0}ث", <Object?>[diff.inSeconds]);
    if (diff.inMinutes < 60) return mainTextCurrent("منذ {0}د", <Object?>[diff.inMinutes]);
    if (diff.inHours < 24) return mainTextCurrent("منذ {0}س", <Object?>[diff.inHours]);
    if (diff.inDays < 7) return mainTextCurrent("منذ {0}ي", <Object?>[diff.inDays]);
    if (diff.inDays < 30) return mainTextCurrent("منذ {0}أ", <Object?>[(diff.inDays / 7).floor()]);
    if (diff.inDays < 365) return mainTextCurrent("منذ {0}ش", <Object?>[(diff.inDays / 30).floor()]);
    return mainTextCurrent("منذ {0}سنة", <Object?>[(diff.inDays / 365).floor()]);
  }
  late final AnimationController _searchAnimController;
  late final Animation<double> _searchAnim;
  final ScrollController _scrollController = ScrollController();

  Set<String> _blockedIds = {};
  Set<String> _hiddenCommentIds = {};
  Set<String> _savedCommentIds = {};
  bool _canComment = false;
  _Comment? _editingComment;
  String? _selectingCommentId;

  void _startSelectCommentText(_Comment comment) {
    setState(() => _selectingCommentId = comment.id);
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
       SnackBar(content: Text(mainText(context, "حدد النص ثم انسخه"))),
    );
  }

  void _stopSelectCommentText() {
    setState(() => _selectingCommentId = null);
  }

  Future<void> _loadHiddenCommentIds() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ids = <String>{};
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('hidden_comments')
          .get();
      ids.addAll(snap.docs.map((d) => d.id));
    } catch (_) {}

    // Moderator-hidden comments are removed by readAuthorizedPost.

    if (!mounted) return;
    setState(() => _hiddenCommentIds = ids);
  }

  bool _isHiddenComment(String id) => _hiddenCommentIds.contains(id);

  @override
  void dispose() {
    _searchAnimController.dispose();
    _commentController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _composerFocusNode.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    _searchAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _searchAnim = CurvedAnimation(
      parent: _searchAnimController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _loadBlockedIds();
    _loadHiddenWords();
    _loadHiddenCommentIds();
    _loadCommentPermission();
    final jumpId = widget.initialCommentId?.trim();
    if (jumpId != null && jumpId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) _scrollToComment(jumpId);
        });
      });
    }
  }

  Future<void> _loadHiddenWords() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users').doc(uid).get();
      final raw = doc.data()?['privacy'];
      final list = raw is Map ? raw['hiddenWords'] : null;
      if (list is! List) return;
      final words = list
          .map((e) => e.toString().trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList();
      if (mounted) setState(() => _hiddenWords = words);
    } catch (e) {
      debugPrint('load hidden words failed: $e');
    }
  }

  bool _matchesHiddenWords(String text) {
    if (_hiddenWords.isEmpty) return false;
    final t = text.toLowerCase();
    return _hiddenWords.any((w) => t.contains(w));
  }

  Future<void> _loadCommentPermission() async {
    try {
      final data = await _readAuthorizedPostData(widget.post.id);
      if (mounted) setState(() => _canComment = data['canComment'] == true);
    } catch (_) {
      if (mounted) setState(() => _canComment = false);
    }
  }
  Future<void> _loadSavedCommentIds() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('saved_comments')
        .get();
    if (!mounted) return;
    setState(() {
      _savedCommentIds = snap.docs.map((d) => d.id).toSet();
    });
  }

  Future<void> _toggleSaveComment(_Comment comment) async {
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
        .collection('saved_comments')
        .doc(comment.id);

    try {
      if (_savedCommentIds.contains(comment.id)) {
        await ref.delete();
        if (!mounted) return;
        setState(() => _savedCommentIds.remove(comment.id));
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
           SnackBar(content: Text(mainText(context, "تم إلغاء الحفظ"))),
        );
      } else {
        await ref.set({
          'commentId': comment.id,
          'postId': postId,
          'postTitle': widget.post.title,
          'author': comment.author,
          'authorId': comment.authorId,
          'authorPhotoUrl': comment.authorPhotoUrl,
          'text': comment.text,
          'mediaUrl': comment.mediaUrl,
          'mediaType': comment.mediaType,
          'savedAt': FieldValue.serverTimestamp(),
        });
        if (!mounted) return;
        setState(() => _savedCommentIds.add(comment.id));
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
           SnackBar(content: Text(mainText(context, "تم حفظ التعليق"))),
        );
      }
    } catch (e) {
      debugPrint('toggle save comment failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
         SnackBar(content: Text(mainText(context, "تعذر حفظ التعليق"))),
      );
    }
  }
  bool _checkingCommentBlocks = true;
  bool _commentBlockError = false;
  Future<void> _loadBlockedIds() async {
    if (mounted) setState(() { _checkingCommentBlocks = true; _commentBlockError = false; });
    try {
      final ids = await loadBlockedUserIds();
      if (!mounted) return;
      setState(() { _blockedIds = ids; _checkingCommentBlocks = false; });
      final jumpId = widget.initialCommentId?.trim();
      if (jumpId != null && jumpId.isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToComment(jumpId);
      });
    } catch (_) {
      if (mounted) setState(() { _checkingCommentBlocks = false; _commentBlockError = true; });
    }
  }

  bool _isBlockedAuthor(String? authorId) {
    final id = authorId?.trim() ?? '';
    return id.isNotEmpty && _blockedIds.contains(id);
  }

  List<_Comment> _withoutBlocked(List<_Comment> list) {
    final filtered = <_Comment>[];
    for (final c in list) {
      if (_isBlockedAuthor(c.authorId) ||
          _isHiddenComment(c.id) ||
          _matchesHiddenWords(c.text)) {
        continue;
      }
      filtered.add(
        _Comment(
          id: c.id,
          author: c.author,
          authorId: c.authorId,
          authorPhotoUrl: c.authorPhotoUrl,
          text: c.text,
          createdAt: c.createdAt,
          replyToAuthor: c.replyToAuthor,
          replyToId: c.replyToId,
          votes: c.votes,
          upvoted: c.upvoted,
          downvoted: c.downvoted,
          mediaUrl: c.mediaUrl,
          mediaType: c.mediaType,
          isEdited: c.isEdited,
          replies: _withoutBlocked(c.replies), // نسخة للفروع أيضاً
        ),
      );
    }
    return filtered;
  }

  void _onSearchChanged(String value) {
    final q = value.trim();
    setState(() => _searchQuery = q);

    if (q.isEmpty) return;

    // بعد إعادة البناء، مرّر لأول نتيجة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final matches = widget.post.comments
          .where((c) => _commentMatchesQuery(c, q))
          .toList();
      if (matches.isEmpty) return;

      final key = _commentKeys[matches.first.id];
      final ctx = key?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          alignment: 0.1,
        );
      }
    });
  }
  bool _commentMatchesQuery(_Comment comment, String query) {
    if (query.isEmpty) return true;
    final lower = query.toLowerCase();
    if (comment.text.toLowerCase().contains(lower)) return true;
    if (comment.author.toLowerCase().contains(lower)) return true;
    return comment.replies.any((r) => _commentMatchesQuery(r, query));
  }




  Future<void> _pickCommentImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final att = await CommentAttachment.fromFile(File(picked.path), CommentMediaKind.image); // FIX
    if (!mounted) return;
    setState(() => _attachment = att);
  }

  Future<void> _pickCommentVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    final att = await CommentAttachment.fromFile(File(picked.path), CommentMediaKind.video); // FIX
    if (!mounted) return;
    setState(() => _attachment = att);
  }

  void _onMediaInserted(KeyboardInsertedContent content) {
    if (!content.hasData) return;
    setState(
        () => _attachment = CommentAttachment.fromKeyboardContent(content));
  }

  void _removeAttachment() => setState(() => _attachment = null);

  Future<void> _deletePostAndPop() async {
    final postId = widget.post.id;
    if (postId == null || postId.isEmpty) return;
    try {
      await _deleteOwnPost(postId);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(mainText(context, "تعذر حذف المنشور، حاول مجددًا"))),
      );
    }
  }
  Future<void> _toggleCommentDownvote(_Comment comment) =>
      _setCommentVote(comment, comment.downvoted ? 0 : -1);

  bool _insertReplyIntoComments(
      List<Map<String, dynamic>> comments,
      String parentId,
      Map<String, dynamic> reply,
      ) {
    for (final comment in comments) {
      if (comment['id'] == parentId) {
        final replies = List<Map<String, dynamic>>.from(
          (comment['replies'] as List? ?? []).map(
                (item) => Map<String, dynamic>.from(item as Map),
          ),
        );

        replies.insert(0, reply);

        comment['replies'] = replies;

        return true;
      }

      final replies = List<Map<String, dynamic>>.from(
        (comment['replies'] as List? ?? []).map(
              (item) => Map<String, dynamic>.from(item as Map),
        ),
      );

      if (_insertReplyIntoComments(replies, parentId, reply)) {
        comment['replies'] = replies;
        return true;
      }
    }

    return false;
  }

  final Set<String> _collapsedCommentIds = {};

  bool _isCommentCollapsed(String id) => _collapsedCommentIds.contains(id);

  void _toggleCommentCollapse(String id) {
    setState(() {
      if (_collapsedCommentIds.contains(id)) {
        _collapsedCommentIds.remove(id);
      } else {
        _collapsedCommentIds.add(id);
      }
    });
  }

  // NEW: مفتاح فريد لكل تعليق، نديرو lazily
  GlobalKey _keyForComment(String id) =>
      _commentKeys.putIfAbsent(id, () => GlobalKey());

  // NEW: فتح شاشة مخصصة لفرع رد وصل للحد الأقصى للعمق
  void _openThread(_Comment comment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ThreadDetailScreen(
          rootComment: comment,
          postId: widget.post.id!,
          allComments: widget.post.comments,
          onCommentsChanged: () => setState(() {}),
          parentActions: _CommentActionsCallbacks(
            postId: widget.post.id!,
            onReply: (c) {}, // ماستعملهاش _ThreadDetailScreen عندها composer خاص بيها
            onEdit: (c) {
              Navigator.pop(context);
              _editComment(c);
            },
            onDelete: _deleteComment,
            onReport: _reportComment,
            onBlock: _blockCommentAuthor,
            onRepost: _repostComment,
            onToggleLike: _toggleCommentLike,
            onToggleDownvote: _toggleCommentDownvote,
            isCollapsed: _isCommentCollapsed,
            onToggleCollapse: _toggleCommentCollapse,
            keyFor: _keyForComment,
            onJumpToParent: _scrollToComment,
            onOpenThread: _openThread,
            onSave: _toggleSaveComment,
            isCommentSaved: (id) => _savedCommentIds.contains(id),

          ),
        ),
      ),
    );
  }

  /// مسار الأسلاف من الجذر حتى التعليق (بدون التعليق نفسه)
  List<String> _ancestorIds(String targetId) {
    final path = <String>[];

    bool walk(List<_Comment> nodes, List<String> trail) {
      for (final c in nodes) {
        if (c.id == targetId) {
          path.addAll(trail);
          return true;
        }
        if (walk(c.replies, [...trail, c.id])) return true;
      }
      return false;
    }

    walk(widget.post.comments, const []);
    return path;
  }

  void _expandAncestorsOf(String id) {
    final ancestors = _ancestorIds(id);
    if (ancestors.isEmpty) return;
    var changed = false;
    for (final a in ancestors) {
      if (_collapsedCommentIds.remove(a)) changed = true;
    }
    if (changed) setState(() {});
  }

  void _scrollToComment(String id) {
    _expandAncestorsOf(id);

    void tryScroll() {
      final ctx = _commentKeys[id]?.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        alignment: 0.12,
      );
    }

    // بعد فتح الفروع وإعادة البناء
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      tryScroll();
      // محاولة ثانية إن لم يُبنَ المفتاح بعد
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) tryScroll();
      });
    });
  }

  bool _mutateCommentMap(
      List<Map<String, dynamic>> comments,
      String id,
      void Function(Map<String, dynamic> node) mutate,
      ) {
    for (final comment in comments) {
      if (comment['id'] == id) {
        mutate(comment);
        return true;
      }
      final replies = List<Map<String, dynamic>>.from(
        (comment['replies'] as List? ?? []).map(
              (item) => Map<String, dynamic>.from(item as Map),
        ),
      );
      if (_mutateCommentMap(replies, id, mutate)) {
        comment['replies'] = replies;
        return true;
      }
    }
    return false;
  }

  bool _removeCommentMap(List<Map<String, dynamic>> comments, String id) {
    for (int i = 0; i < comments.length; i++) {
      if (comments[i]['id'] == id) {
        comments.removeAt(i);
        return true;
      }
      final replies = List<Map<String, dynamic>>.from(
        (comments[i]['replies'] as List? ?? []).map(
              (item) => Map<String, dynamic>.from(item as Map),
        ),
      );
      if (_removeCommentMap(replies, id)) {
        comments[i]['replies'] = replies;
        return true;
      }
    }
    return false;
  }

  bool _findCommentLocal(
      List<_Comment> comments,
      String id,
      void Function(_Comment) apply,
      ) {
    for (final c in comments) {
      if (c.id == id) {
        apply(c);
        return true;
      }
      if (_findCommentLocal(c.replies, id, apply)) return true;
    }
    return false;
  }

  bool _removeCommentLocal(List<_Comment> comments, String id) {
    for (int i = 0; i < comments.length; i++) {
      if (comments[i].id == id) {
        comments.removeAt(i);
        return true;
      }
      if (_removeCommentLocal(comments[i].replies, id)) return true;
    }
    return false;
  }

  Future<void> _editComment(_Comment comment) async {
    setState(() {
      _replyTo = null;
      _attachment = null;
      _editingComment = comment;
      _commentController.text = comment.text;
    });
    _composerFocusNode.requestFocus();
  }

  void _cancelEdit() {
    setState(() {
      _editingComment = null;
      _commentController.clear();
    });
  }

  Future<void> _mutateOwnComment(String action, String commentId, {String? text}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('mutateComment', options: HttpsCallableOptions(timeout: const Duration(seconds: 120)))
        .call<Map<String, dynamic>>({
          'action': action, 'postId': widget.post.id, 'commentId': commentId,
          if (text != null) 'text': text,
        });
    if (FirebaseAuth.instance.currentUser?.uid != uid || response.data['action'] != action ||
        response.data['commentId'] != commentId || response.data['commentsCount'] is! num) {
      throw StateError(mainText(context, "تعذر تأكيد تحديث التعليق"));
    }
  }

  Future<void> _saveEditedComment(_Comment comment) async {
    final newText = _commentController.text.trim();
    if (newText.isEmpty) return;

    try {
      await _mutateOwnComment('edit', comment.id, text: newText);
      if (!mounted) return;
      setState(() {
        _findCommentLocal(widget.post.comments, comment.id, (c) {
          c.text = newText;
          c.isEdited = true;
        });
        _editingComment = null;
        _commentController.clear();
      });
      FocusScope.of(context).unfocus();
    } catch (e) {
      debugPrint('Edit comment failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(mainText(context, "تعذر تعديل التعليق، حاول مجددًا"))),
      );
    }
  }

  Future<void> _deleteComment(_Comment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title:  Text(mainText(context, "حذف التعليق؟")),
          content:  Text(mainText(context, "سيتم حذف التعليق وكل الردود عليه نهائيًا.")),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:  Text(mainText(context, "إلغاء")),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child:  Text(mainText(context, "حذف")),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await _mutateOwnComment('delete', comment.id);
      if (!mounted) return;
      setState(() {
        _removeCommentLocal(widget.post.comments, comment.id);
      });
    } catch (e) {
      debugPrint('Delete comment failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(mainText(context, "تعذر حذف التعليق، حاول مجددًا"))),
      );
    }
  }

  Future<void> _reportComment(_Comment comment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(mainText(context, "يجب تسجيل الدخول أولاً"))),
      );
      return;
    }

    final postId = widget.post.id?.trim();
    if (postId == null || postId.isEmpty) return;

    final ownerId = comment.authorId?.trim();
    if (ownerId != null && ownerId.isNotEmpty && ownerId == user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(mainText(context, "لا يمكنك تبليغ محتواك"))),
      );
      return;
    }

    bool already;
    try {
      already = await hasCommunityReport(
        type: CommunityReportType.comment,
        targetId: comment.id,
        parentId: postId,
      );
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(mainText(context, "تعذر التحقق من البلاغ السابق؛ أعد المحاولة"))));
      return;
    }
    if (!mounted) return;

    if (already) {
      setState(() => _hiddenCommentIds.add(comment.id));
      await showReportSubmittedSheet(
        context,
        type: CommunityReportType.comment,
        ownerId: ownerId,
        ownerName: comment.author,
        ownerPhotoUrl: comment.authorPhotoUrl,
        alreadyReported: true,
      );
      return;
    }

    final result = await showCommunityReportSheet(
      context,
      type: CommunityReportType.comment,
    );
    if (result == null || !mounted) return;

    try {
      await runWithReportSpinner(context, () => submitCommunityReport(
        type: CommunityReportType.comment,
        targetId: comment.id,
        parentId: postId,
        ownerId: ownerId,
        ownerName: comment.author,
        reason: result.reasonId,
        details: result.details,
        snapshot: communityReportSnapshotFromComment(comment),
      ));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('hidden_comments')
          .doc(comment.id)
          .set({
        'commentId': comment.id,
        'postId': postId,
        'source': 'report',
        'hiddenAt': FieldValue.serverTimestamp(),
      });
      hiddenListRevision.value++;

      if (!mounted) return;
      setState(() => _hiddenCommentIds.add(comment.id));
      await showReportSubmittedSheet(
        context,
        type: CommunityReportType.comment,
        ownerId: ownerId,
        ownerName: comment.author,
        ownerPhotoUrl: comment.authorPhotoUrl,
      );
    } catch (e) {
      debugPrint('Report comment failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messageForCommunityReportError(e))),
      );
    }
  }

  Future<void> _blockCommentAuthor(_Comment comment) async {
    final user = FirebaseAuth.instance.currentUser;
    final targetId = comment.authorId?.trim();
    if (user == null || targetId == null || targetId.isEmpty) return;
    if (targetId == user.uid) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: Directionality.of(context),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title:  Text(mainText(ctx, "حظر الحساب؟")),
          content: Text(
            mainText(ctx, "لن تظهر منشورات وتعليقات {0} بعد الآن.", <Object?>[comment.author]),
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
        targetName: comment.author,
        targetPhotoUrl: comment.authorPhotoUrl,
      );

      if (!mounted) return;
      setState(() => _blockedIds.add(targetId));
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(mainText(context, "تم حظر {0}", <Object?>[comment.author]))),
      );
    } catch (e) {
      debugPrint('Block comment author failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
         SnackBar(content: Text(mainText(context, "تعذر حظر الحساب"))),
      );
    }
  }

  Future<void> _repostComment(_Comment comment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
         SnackBar(content: Text(mainText(context, "يجب تسجيل الدخول أولاً"))),
      );
      return;
    }

    final original = widget.post;
    final originalId = original.id?.trim();
    if (originalId == null || originalId.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
         SnackBar(content: Text(mainText(context, "تعذر إعادة نشر هذا التعليق"))),
      );
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    final draft = await Navigator.of(context, rootNavigator: true).push<_RepostDraft>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _RepostComposePage(
          original: original,
          comment: comment,
        ),
      ),
    );
    if (!mounted || draft == null) return;

    try {
      await _publishAuthorizedRepost(expectedUid: user.uid,
        sourcePostId: originalId, draft: draft, commentId: comment.id);

      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
         SnackBar(content: Text(mainText(context, "تمت إعادة نشر التعليق"))),
      );
    } catch (e) {
      debugPrint('Repost comment failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
         SnackBar(content: Text(mainText(context, "تعذر إعادة النشر، حاول مجددًا"))),
      );
    }
  }

  final Set<String> _commentVotesInFlight = {};
  Future<void> _toggleCommentLike(_Comment comment) =>
      _setCommentVote(comment, comment.upvoted ? 0 : 1);

  Future<void> _setCommentVote(_Comment comment, int vote) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _commentVotesInFlight.contains(comment.id)) return;
    _commentVotesInFlight.add(comment.id);
    try {
      final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('mutateComment', options: HttpsCallableOptions(timeout: const Duration(seconds: 120)))
          .call<Map<String, dynamic>>({
            'action': 'vote', 'postId': widget.post.id, 'commentId': comment.id, 'vote': vote,
          });
      final data = response.data;
      if (data['action'] != 'vote' || data['commentId'] != comment.id || data['vote'] != vote ||
          data['votes'] is! num || data['previousVote'] is! num || data['ownerId'] is! String) {
        throw const FormatException('Invalid comment vote response');
      }
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != uid) return;
      setState(() {
        void apply(_Comment c) {
          c.votes = (data['votes'] as num).toInt();
          c.upvoted = vote == 1; c.downvoted = vote == -1;
        }
        apply(comment);
        _findCommentLocal(widget.post.comments, comment.id, apply);
      });
      HapticFeedback.lightImpact();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(mainText(context, "تعذر تحديث التصويت على التعليق. حاول مرة أخرى."))));
    } finally {
      _commentVotesInFlight.remove(comment.id);
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_checkingCommentBlocks || _commentBlockError) {
      return Scaffold(appBar: AppBar(title:  Text(mainText(context, "التعليقات"))),
        body: Center(child: _checkingCommentBlocks ? const CircularProgressIndicator()
          : Column(mainAxisSize: MainAxisSize.min, children: [
               Text(mainText(context, "تعذر التحقق من قائمة الحظر")),
              TextButton(onPressed: _loadBlockedIds, child:  Text(mainText(context, "إعادة المحاولة"))),
            ])));
    }
    final allComments = _withoutBlocked(widget.post.comments);
    final filteredComments = _searchQuery.isEmpty
        ? allComments
        : allComments
        .where((c) => _commentMatchesQuery(c, _searchQuery))
        .toList();
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;


    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AnimatedBuilder(
            animation: _searchAnim,
            builder: (context, _) {
              final t = _CommentTheme.of(context);
              final progress = _searchAnim.value; // 0 → 1

              return Container(
                color: t.pageBg,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SafeArea(
                  bottom: false,
                  child: SizedBox(
                    height: kToolbarHeight,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // ===== الوضع العادي (عنوان + أزرار) =====
                        Opacity(
                          opacity: (1 - progress).clamp(0.0, 1.0),
                          child: IgnorePointer(
                            ignoring: progress > 0.05,
                            child: Row(
                              children: [
                                // زر الرجوع
                                InkWell(
                                  onTap: () => Navigator.maybePop(context),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: t.cardBg,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: t.cardBorder),
                                    ),
                                    child: Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      size: 17,
                                      color: t.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    mainText(context, "Comments"),
                                    style: TextStyle(
                                      color: t.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                // أيقونة البحث (نقطة الانطلاق)
                                IconButton(
                                  icon: Icon(Icons.search_rounded, color: t.textPrimary),
                                  onPressed: () {
                                    setState(() => _isSearching = true);
                                    _searchAnimController.forward();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ===== حقل البحث المتمدد من الأيقونة =====
                        if (progress > 0.01)
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final fullWidth = constraints.maxWidth;
                                  final w = (fullWidth * progress)
                                      .clamp(0.0, fullWidth);

                                  return Align(
                                    alignment: Alignment.centerRight,
                                    child: SizedBox(
                                      width: w,
                                      height: 42,
                                      child: ClipRect(
                                        child: OverflowBox(
                                          alignment: Alignment.centerRight,
                                          minWidth: fullWidth,
                                          maxWidth: fullWidth,
                                          minHeight: 42,
                                          maxHeight: 42,
                                          child: SizedBox(
                                            width: fullWidth,
                                            height: 42,
                                            child: Material(
                                              color: Colors.transparent, // ← لا خلفية إضافية
                                              child: TextField(
                                                controller: _searchController,
                                                autofocus: progress > 0.9,
                                                style: TextStyle(
                                                  color: t.textPrimary,
                                                  fontSize: 15,
                                                ),
                                                decoration: InputDecoration(
                                                  hintText: mainText(context, "Search comments..."),
                                                  hintStyle: TextStyle(color: t.textMuted, fontSize: 15),
                                                  filled: true,
                                                  fillColor: t.inputBg, // الخلفية الوحيدة
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(21),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(21),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(21),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: t.textMuted),
                                                  suffixIcon: IconButton(
                                                    visualDensity: VisualDensity.compact,
                                                    icon: Icon(Icons.close_rounded, size: 20, color: t.textMuted),
                                                    onPressed: () async {
                                                      FocusScope.of(context)
                                                          .unfocus();
                                                      await _searchAnimController.reverse();
                                                      if (!mounted) return;
                                                      setState(() {
                                                        _isSearching = false;
                                                        _searchQuery = '';
                                                        _searchController.clear();
                                                      });
                                                    },
                                                  ),
                                                ),
                                                onChanged: _onSearchChanged,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        body: CustomScrollView(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(2, 8, 2, 10),
                child: _PostCard(
                  post: widget.post,
                  onChanged: () => setState(() {}),
                  onDelete: _deletePostAndPop,
                  isInsideComments: true,
                  onHidden: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ),
            ),
             SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: theme.dividerColor.withValues(alpha: 0.45),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        mainText(context, "Comments"),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: muted,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: theme.dividerColor.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
            )),
            if (filteredComments.isEmpty)
              SliverToBoxAdapter(
                child: _EmptyCommentsState(isSearching: _searchQuery.isNotEmpty),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final comment = filteredComments[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == filteredComments.length - 1 ? 0 : 12,
                        ),
                        child: _CommentThreadCard(
                          comment: comment,
                          actions: _CommentActionsCallbacks(
                            postId: widget.post.id!,
                            onReply: (c) {
                              setState(() {
                                _replyTo = c;
                                _commentController.clear();
                              });
                              _composerFocusNode.requestFocus();
                            },
                            onEdit: _editComment,
                            onDelete: _deleteComment,
                            onReport: _reportComment,
                            onBlock: _blockCommentAuthor,
                            onRepost: _repostComment,
                            onToggleLike: _toggleCommentLike,
                            onToggleDownvote: _toggleCommentDownvote,
                            isCollapsed: _isCommentCollapsed,
                            onToggleCollapse: _toggleCommentCollapse,
                            keyFor: _keyForComment,
                            onJumpToParent: _scrollToComment,
                            onOpenThread: _openThread, // NEW
                            onSave: _toggleSaveComment,
                            isCommentSaved: (id) => _savedCommentIds.contains(id),

                          ),
                        ),
                      );
                    },
                    childCount: filteredComments.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 116)),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child:_canComment
                ? _CommentComposer(
              controller: _commentController,
              replyTo: _replyTo,
              onCancelReply: () => setState(() => _replyTo = null),
              onSubmit: _submitComment,
              attachment: _attachment,           // NEW
              onPickImage: _pickCommentImage,    // NEW
              onPickVideo: _pickCommentVideo,    // NEW
              onMediaInserted: _onMediaInserted,    // NEW
              onRemoveAttachment: _removeAttachment, // NEW
              focusNode: _composerFocusNode,
              editingComment: _editingComment,
              onCancelEdit: _cancelEdit,

            )
                  : Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Text(
            mainText(context, "التعليق على منشورات هذا الحساب مقيّد."),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).hintColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitComment() async {
    final postId = widget.post.id;
    if (postId == null || postId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(mainText(context, "تعذر تحديد المنشور"))),
      );
      return;
    }

    if (_editingComment != null) {
      await _saveEditedComment(_editingComment!);
      return;
    }

    final replyTo = _replyTo;
    final attachment = _attachment; // NEW
    if (!_canComment) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(mainText(context, "التعليق غير مسموح على هذا المنشور"))),
      );
      return;
    }
    await _postComment(
      context: context,
      postId: postId,
      text: _commentController.text,
      replyTo: replyTo,
      attachment: attachment,
      onSuccess: (newComment, isReply) {
        if (!mounted) return;
        setState(() {
          if (isReply) {
            _findCommentLocal(widget.post.comments, replyTo!.id, (c) {
              c.replies.insert(0, newComment);
            });
          } else {
            widget.post.comments.insert(0, newComment);
          }
          _replyTo = null;
          _attachment = null; // NEW
          _commentController.clear();
        });
        FocusScope.of(context).unfocus();
      },
    );
  }
}
class _EmptyCommentsState extends StatelessWidget {
  const _EmptyCommentsState({required this.isSearching});
  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    final t = _CommentTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Icon(
            isSearching ? Icons.search_off_rounded : Icons.mode_comment_outlined,
            size: 38,
            color: t.textFaint,
          ),
          const SizedBox(height: 10),
          Text(
            isSearching ? mainText(context, "لا توجد نتائج مطابقة") : mainText(context, "لا توجد تعليقات بعد"),
            style: TextStyle(color: t.textMuted, fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
          if (!isSearching) ...[
            const SizedBox(height: 4),
            Text(
              mainText(context, "كن أول من يعلّق على هذا المنشور"),
              style: TextStyle(color: t.textFaint, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }
}

class _CommentComposer extends StatefulWidget {
  final TextEditingController controller;
  final _Comment? replyTo;
  final VoidCallback onCancelReply;
  final Future<void> Function() onSubmit; // FIX: بقات Future بدل VoidCallback باش نقدرو نستناو نهايتها
  final CommentAttachment? attachment;
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;
  final void Function(KeyboardInsertedContent) onMediaInserted;
  final VoidCallback onRemoveAttachment;
  final FocusNode focusNode;
  final _Comment? editingComment;
  final VoidCallback? onCancelEdit;

  const _CommentComposer({
    required this.controller,
    required this.replyTo,
    required this.onCancelReply,
    required this.onSubmit,
    required this.attachment,
    required this.onPickImage,
    required this.onPickVideo,
    required this.onMediaInserted,
    required this.onRemoveAttachment,
    required this.focusNode,
    this.editingComment,
    this.onCancelEdit,
  });

  @override
  State<_CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<_CommentComposer> {
  String? _avatarUrl;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }
  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
  Future<void> _loadAvatar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String? url;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final saved = doc.data()?['profileImageUrl']?.toString().trim();
      if (saved != null && saved.isNotEmpty) {
        url = saved;
      }
    } catch (e) {
      debugPrint('Load comment avatar failed: $e');
    }

    // صورة حساب Google / الإيميل
    url ??= user.photoURL?.trim();
    if (url != null && url.isEmpty) url = null;

    if (mounted && url != null) {
      setState(() => _avatarUrl = url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _CommentTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPhoto = _avatarUrl != null && _avatarUrl!.trim().isNotEmpty;

    final sendActiveColor =
    isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB);
    final sendDisabledColor =
    isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: t.cardBg,
        border: Border(
          top: BorderSide(
            color: t.cardBorder.withValues(alpha: isDark ? 0.5 : 0.7),
            width: 0.6,
          ),
        ),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.editingComment != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: t.inputBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.inputBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_rounded, size: 16, color: t.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      mainText(context, "تعديل التعليق"),
                      style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: widget.onCancelEdit,
                    child: Icon(Icons.close_rounded, size: 18, color: t.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ] else if (widget.replyTo != null) ...[
            _ReplyBanner(
              replyTo: widget.replyTo!,
              onCancel: widget.onCancelReply,
              t: t,
            ),
            const SizedBox(height: 8),
          ],
          if (widget.attachment != null) ...[
            _AttachmentPreview(
              attachment: widget.attachment!,
              onRemove: widget.onRemoveAttachment,
            ),
            const SizedBox(height: 8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ===== أفاتار البروفايل =====
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Container(
                  width: 34,
                  height: 34,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: t.avatarBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                      width: 1,
                    ),
                  ),
                  child: hasPhoto
                      ? Image.network(
                    _avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.person_rounded,
                      size: 18,
                      color: t.textMuted,
                    ),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: t.textMuted,
                          ),
                        ),
                      );
                    },
                  )
                      : Icon(
                    Icons.person_rounded,
                    size: 18,
                    color: t.textMuted,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // ===== حقل الكتابة =====
              Expanded(
                child: AnimatedBuilder(
                  animation: widget.focusNode,
                  builder: (context, _) {
                    final focused = widget.focusNode.hasFocus;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      constraints: const BoxConstraints(
                        minHeight: 44,
                        maxHeight: 130,
                      ),
                      decoration: BoxDecoration(
                        color: t.inputBg,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: focused
                              ? sendActiveColor.withValues(alpha: 0.45)
                              : t.inputBorder,
                          width: focused ? 1.3 : 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: widget.controller,
                              focusNode: widget.focusNode,
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              maxLines: null,
                              minLines: 1,
                              textAlignVertical: TextAlignVertical.center,
                              contentInsertionConfiguration:
                              ContentInsertionConfiguration(
                                onContentInserted: widget.onMediaInserted,
                                allowedMimeTypes: const [
                                  'image/gif',
                                  'image/png',
                                  'image/jpeg',
                                  'image/webp',
                                ],
                              ),
                              decoration: InputDecoration(
                                hintText: widget.editingComment != null
                                    ? mainText(context, "عدّل التعليق...")
                                    : widget.replyTo == null
                                    ? mainText(context, "أضف تعليقاً...")
                                    : mainText(context, "أضف رداً..."),
                                hintStyle: TextStyle(
                                  color: t.textMuted,
                                  fontSize: 13.5,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 13.5,
                                color: t.textPrimary,
                                height: 1.35,
                              ),
                            ),
                          ),
                          _InlineMediaIcon(
                            icon: Icons.image_outlined,
                            onTap: widget.onPickImage,
                            t: t,
                          ),
                          _InlineMediaIcon(
                            icon: Icons.videocam_outlined,
                            onTap: widget.onPickVideo,
                            t: t,
                          ),
                          const SizedBox(width: 6),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: 8),

              // ===== زر الإرسال =====
              // ===== زر الإرسال =====
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.controller,
                builder: (context, value, _) {
                  // FIX: الزر معطل أثناء النشر، حتى لو النص مازال موجود
                  final canSend = !_isSubmitting &&
                      (value.text.trim().isNotEmpty || widget.attachment != null);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 1),
                    child: AnimatedScale(
                      scale: canSend ? 1.0 : 0.92,
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: canSend ? _handleSubmit : null, // FIX: _handleSubmit بدل widget.onSubmit مباشرة
                          borderRadius: BorderRadius.circular(22),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: canSend
                                  ? sendActiveColor
                                  : sendDisabledColor,
                              shape: BoxShape.circle,
                            ),
                            // NEW: مؤشر تحميل صغير بدل السهم أثناء النشر
                            child: _isSubmitting
                                ? const Padding(
                              padding: EdgeInsets.all(11),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : Icon(
                              Icons.arrow_upward_rounded,
                              size: 20,
                              color: canSend
                                  ? Colors.white
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CommentTile extends StatefulWidget {
  final _Comment comment;
  final int depth;
  final _CommentActionsCallbacks actions;


  const CommentTile({
    super.key,
    required this.comment,
    required this.depth,
    required this.actions,

  });

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  bool get _isReply => widget.depth > 0;
  bool _pressed = false;
  bool _textSelectable = false;

  bool get _isOwner {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final authorId = widget.comment.authorId;
    return uid != null && authorId != null && uid == authorId;
  }

  @override
  void initState() {
    super.initState();
    final id = widget.comment.authorId?.trim() ?? '';
    if (id.isNotEmpty) AuthorProfiles.ensure(id);
  }

  PopupMenuItem<String> _menuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Future<void> _showCommentMenu(BuildContext context, Offset globalPosition) async {
    final t = _CommentTheme.of(context);

    final overlayObject = Overlay.of(context).context.findRenderObject();
    if (overlayObject is! RenderBox) return;
    final overlay = overlayObject;

    final position = RelativeRect.fromLTRB(
      globalPosition.dx,
      globalPosition.dy,
      overlay.size.width - globalPosition.dx,
      overlay.size.height - globalPosition.dy,
    );

    final selected = await showMenu<String>(
      context: context,
      position: position,
      color: t.sheetBg,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: t.cardBorder),
      ),
      constraints: const BoxConstraints(minWidth: 180),
      items: [
        _menuItem(value: 'reply', icon: Icons.reply_rounded, label: mainText(context, "رد"), color: t.textPrimary),
        _menuItem(
          value: 'save',
          icon: (widget.actions.isCommentSaved?.call(widget.comment.id) ?? false)
              ? Icons.bookmark_rounded
              : Icons.bookmark_border,
          label: (widget.actions.isCommentSaved?.call(widget.comment.id) ?? false)
              ? mainText(context, "إلغاء الحفظ")
              : mainText(context, "حفظ"),
          color: t.textPrimary,
        ),
        if (_isOwner)
          _menuItem(value: 'edit', icon: Icons.edit_rounded, label: mainText(context, "تعديل"), color: t.textPrimary),
        _menuItem(value: 'repost', icon: Icons.repeat_rounded, label: mainText(context, "إعادة نشر"), color: t.textPrimary),
        _menuItem(value: 'share', icon: Icons.ios_share_rounded, label: mainText(context, "مشاركة"), color: t.textPrimary),
        _menuItem(value: 'copy', icon: Icons.copy_rounded, label: mainText(context, "نسخ النص"), color: t.textPrimary),
        if (!_isOwner)
          _menuItem(value: 'report', icon: Icons.flag_outlined, label: mainText(context, "تبليغ"), color: t.textPrimary),
        const PopupMenuDivider(height: 1),
        if (_isOwner)
          _menuItem(value: 'delete', icon: Icons.delete_outline_rounded, label: mainText(context, "حذف"), color: t.danger),
        if (!_isOwner)
          _menuItem(value: 'block', icon: Icons.block_rounded, label: mainText(context, "حظر الحساب"), color: t.danger),
      ],
    );

    if (!mounted || selected == null) return;

    switch (selected) {
      case 'reply':
        widget.actions.onReply(widget.comment);
        break;
      case 'save':
        await widget.actions.onSave?.call(widget.comment);
        break;
      case 'edit':
        widget.actions.onEdit(widget.comment);
        break;
      case 'delete':
        widget.actions.onDelete(widget.comment);
        break;
      case 'repost':
        widget.actions.onRepost(widget.comment);
        break;
      case 'share':
        await Share.share(widget.comment.text);
        break;
      case 'copy':
        setState(() => _textSelectable = true);
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
           SnackBar(content: Text(mainText(context, "حدد النص ثم انسخه"))),
        );
        break;
      case 'report':
        widget.actions.onReport(widget.comment);
        break;
      case 'block':
        widget.actions.onBlock(widget.comment);
        break;
    }
  }

  // NEW: يبدأ أثر "الرفع" بمجرد لمس الإصبع للشاشة (قبل ما نعرفو واش راح يكون long press)
  // NEW: يبدأ أثر "الرفع" بمجرد لمس الإصبع للشاشة (قبل ما نعرفو واش راح يكون long press)
  void _onTapDown(TapDownDetails details) {
    setState(() => _pressed = true);
  }

  // NEW: تاب قصير عادي (بلا سحب) — يتصفّر الأثر، بلا فتح قائمة
  void _onTapUp(TapUpDetails details) {
    if (!mounted) return;
    setState(() => _pressed = false);
  }

  // NEW: كيتفعّل إما إذا خرج الإصبع برا الودجة، أو إذا الـ long press ربح الـ arena
  void _onTapCancel() {
    if (!mounted) return;
    setState(() => _pressed = false);
  }

  // NEW: هنا الضغط اتأكد أنه فعلاً مطوّل — نفتحو القائمة بمكان الإصبع
  Future<void> _onLongPressStart(LongPressStartDetails details) async {
    if (!mounted) return;
    setState(() => _pressed = true);
    HapticFeedback.mediumImpact();
    await _showCommentMenu(context, details.globalPosition);
    if (!mounted) return;
    setState(() => _pressed = false);
  }


  @override
  Widget build(BuildContext context) {
    final t = _CommentTheme.of(context);
    final comment = widget.comment;

    return KeyedSubtree(
      key: widget.actions.keyFor(comment.id),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onLongPressStart: _onLongPressStart,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            curve: Curves.easeOut,
            padding: EdgeInsets.all(_pressed ? 6 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: _pressed ? t.chipBg : Colors.transparent,
              boxShadow: _pressed && !t.isDark
                  ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
                  : const [],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: _isReply ? 32 : 36,
                          height: _isReply ? 32 : 36,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:

                            [Padding(padding: EdgeInsetsGeometry.only(top:7),

                                child: Row(
                              children: [

                                Flexible(

                                  child: ValueListenableBuilder<int>(
                                    valueListenable: AuthorProfiles.revision,
                                    builder: (context, _, __) {
                                      final live = AuthorProfiles.nameOf(
                                        widget.comment.authorId,
                                      )?.trim();
                                      final name = (live != null &&
                                          live.isNotEmpty)
                                          ? live
                                          : comment.author;
                                      return Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: t.textPrimary,
                                          fontSize: _isReply ? 12 : 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Text(
                                  '  • ',
                                  style: TextStyle(
                                    color: t.textFaint,
                                    fontSize: _isReply ? 13 : 15.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  comment.timeAgo,
                                  style: TextStyle(
                                    color: t.textMuted,
                                    fontSize: _isReply ? 10.8 : 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (comment.isEdited) ...[
                                        Text(
                                    '  • ',
                                    style: TextStyle(
                                      color: t.textFaint,
                                      fontSize: _isReply ? 13 : 15.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    mainText(context, "edited"),
                                    style: TextStyle(
                                      color: t.textMuted,
                                      fontSize: _isReply ? 10 : 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                        ),
                                      ]
                                    ],
                            )),
                              if (_textSelectable)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      Icon(Icons.content_copy_rounded, size: 15, color: t.textMuted),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          mainText(context, "حدد النص ثم انسخه"),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: t.textMuted,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => setState(
                                            () => _textSelectable = false),
                                        child:  Text(mainText(context, "تم")),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 2),
                              // NEW: تاب هنا فقط = رد
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => widget.actions.onReply(comment),
                                child:                               GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: _textSelectable
                                      ? null
                                      : () => widget.actions.onReply(comment),
                                  child: _textSelectable
                                      ? SelectableText(
                                    comment.text,
                                    style: TextStyle(
                                      color: t.textBody,
                                      fontSize: _isReply ? 13 : 13.5,
                                      height: 1.4,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                                      : ExpandableText(
                                    text: comment.text,
                                    style: TextStyle(
                                      color: t.textBody,
                                      fontSize: _isReply ? 13 : 13.5,
                                      height: 1.4,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              if (comment.mediaUrl != null && comment.mediaUrl!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                _CommentMedia(postId: widget.actions.postId, commentId: comment.id, url: comment.mediaUrl!, type: comment.mediaType),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        // NEW: عمود التصويت — هادئ بصريًا فحالة الراحة، منطقة لمس كافية
                        _VoteColumn(
                          votes: comment.votes,
                          upvoted: comment.upvoted,
                          downvoted: comment.downvoted,
                          onUpvote: () => widget.actions.onToggleLike(comment),
                          onDownvote: () => widget.actions.onToggleDownvote(comment),
                        ),
                      ],
                    ),
                  ],
                ),
                PositionedDirectional(
                  start: -2,
                  top: 0,
                  child: IgnorePointer(
                    child: SizedBox(
                      width: _isReply ? 32 : 36,
                      height: _isReply ? 32 : 36,
                      child: Center(
                        child: _CommentAvatar(
                          isReply: _isReply,
                          userId: comment.authorId,
                          photoUrl: comment.authorPhotoUrl,
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
// =============================Sub-Comments Screen==============================
class _ThreadDetailScreen extends StatefulWidget {
  const _ThreadDetailScreen({
    required this.rootComment,
    required this.postId,
    required this.allComments,
    required this.parentActions,
    required this.onCommentsChanged,
  });

  final _Comment rootComment;
  final String postId;
  final List<_Comment> allComments; // NEW: جذر شجرة التعليقات الكاملة ديال المنشور
  final _CommentActionsCallbacks parentActions;
  final VoidCallback onCommentsChanged; // NEW: باش الشاشة الأصلية تحدث نفسها بعد الرجوع

  @override
  State<_ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends State<_ThreadDetailScreen> {
  final Set<String> _collapsedIds = {};
  final Map<String, GlobalKey> _keys = {};
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _composerFocusNode = FocusNode();
  _Comment? _replyTo;
  CommentAttachment? _attachment;
  late final _CommentActionsCallbacks _localActions;

  bool _isCollapsed(String id) => _collapsedIds.contains(id);


  Future<void> _pickCommentImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final att = await CommentAttachment.fromFile(File(picked.path), CommentMediaKind.image); // FIX
    if (!mounted) return;
    setState(() => _attachment = att);
  }

  Future<void> _pickCommentVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    final att = await CommentAttachment.fromFile(File(picked.path), CommentMediaKind.video); // FIX
    if (!mounted) return;
    setState(() => _attachment = att);
  }

// NEW: بدل _pickCommentGif — هذا كيتفعّل أوتوماتيكيا ملي المستخدم
// يختار GIF من زر الكيبورد نفسو
  void _onMediaInserted(KeyboardInsertedContent content) {
    if (!content.hasData) return;
    setState(
        () => _attachment = CommentAttachment.fromKeyboardContent(content));
  }

  void _removeAttachment() => setState(() => _attachment = null);

  void _toggleCollapse(String id) {
    setState(() {
      if (_collapsedIds.contains(id)) {
        _collapsedIds.remove(id);
      } else {
        _collapsedIds.add(id);
      }
    });
  }

  GlobalKey _keyFor(String id) => _keys.putIfAbsent(id, () => GlobalKey());

  void _jumpTo(String id) {
    final ctx = _keys[id]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      alignment: 0.08,
    );
  }

  // NEW: نفتح صفحة تانية فوق هاد الصفحة كي نوصلو لعمق آخر داخل الفرع
  void _openNestedThread(_Comment comment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ThreadDetailScreen(
          rootComment: comment,
          postId: widget.postId,
          allComments: widget.allComments,
          parentActions: widget.parentActions,
          onCommentsChanged: widget.onCommentsChanged,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _replyTo = widget.rootComment;
    _localActions = _CommentActionsCallbacks(
      postId: widget.postId,
      onReply: (c) {
        setState(() {
          _replyTo = c;
          _commentController.clear();
        });
        _composerFocusNode.requestFocus(); // NEW

      },
      onEdit: widget.parentActions.onEdit,
      onDelete: widget.parentActions.onDelete,
      onReport: widget.parentActions.onReport,
      onBlock: widget.parentActions.onBlock,
      onRepost: widget.parentActions.onRepost,
      onToggleLike: widget.parentActions.onToggleLike,
      onToggleDownvote: widget.parentActions.onToggleDownvote,
      isCollapsed: _isCollapsed,
      onToggleCollapse: _toggleCollapse,
      keyFor: _keyFor,
      onJumpToParent: _jumpTo,
      onOpenThread: _openNestedThread,
      onSave: widget.parentActions.onSave,
      isCommentSaved: widget.parentActions.isCommentSaved,
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _composerFocusNode.dispose(); // NEW
    super.dispose();
  }

  Future<void> _submitLocalComment() async {
    final replyTo = _replyTo;
    final attachment = _attachment;

    await _postComment(
      context: context,
      postId: widget.postId,
      text: _commentController.text,
      replyTo: replyTo,
      attachment: attachment,
      onSuccess: (newComment, isReply) {
        if (!mounted) return;
        setState(() {
          if (isReply) {
            _findCommentLocalStatic(widget.allComments, replyTo!.id, (c) {
              c.replies.insert(0, newComment);
            });
          }
          // ملاحظة: هاد الشاشة كتعرض غير فرع رد موجود أصلاً، فما كاينش
          // حالة "تعليق رئيسي جديد" هنا — كل رد هو دايمًا رد على شي حاجة.
          _replyTo = null;
          _attachment = null;
          _commentController.clear();
        });
        FocusScope.of(context).unfocus();
        widget.onCommentsChanged(); // نحدثو الشاشة الأصلية باش يبان الرد الجديد فيها تما
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _CommentTheme.of(context);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: t.pageBg,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: t.pageBg,
          centerTitle: true,
          title: Text(
            mainText(context, "Deep Replies"),
            style: TextStyle(color: t.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
          ),
          leadingWidth: 58,
          leading: Padding(
            padding: const EdgeInsetsDirectional.only(start: 12),
            child: Center(
              child: InkWell(
                onTap: () => Navigator.maybePop(context),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: t.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: t.cardBorder),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 17, color: t.textPrimary),
                ),
              ),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _FocusedRootComment(comment: widget.rootComment, actions: _localActions),
            const SizedBox(height: 120),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: _CommentComposer(
              controller: _commentController,
              replyTo: _replyTo,
              onCancelReply: () => setState(() => _replyTo = null),
              onSubmit: _submitLocalComment,
              attachment: _attachment,           // NEW
              onPickImage: _pickCommentImage,    // NEW
              onPickVideo: _pickCommentVideo,    // NEW
              onMediaInserted: _onMediaInserted,       // NEW
              onRemoveAttachment: _removeAttachment, // NEW
              focusNode: _composerFocusNode, // NEW

            ),

          ),
        ),
      ),
    );
  }
}
_Comment _commentFromMap(Map<String, dynamic> data) {
  DateTime createdAt = DateTime.now();

  final rawDate = data['createdAt'];
  if (rawDate is Timestamp) {
    createdAt = rawDate.toDate();
  } else if (rawDate is String) {
    createdAt = DateTime.tryParse(rawDate) ?? createdAt;
  }

  final rawReplies = data['replies'];
  final replies = rawReplies is List
      ? rawReplies
      .whereType<Map>()
      .map((item) => _commentFromMap(Map<String, dynamic>.from(item)))
      .toList()
      : <_Comment>[];

  final currentUid = FirebaseAuth.instance.currentUser?.uid;
  final upvotedBy = _stringList(data['upvotedBy']);
  final downvotedBy = _stringList(data['downvotedBy']);

  return _Comment(
    id: (data['id'] ?? '').toString(),
    author: (data['author'] ?? mainTextCurrent("طالب UniSpace")).toString(),
    authorId: data['authorId']?.toString(),
    authorPhotoUrl: data['authorPhotoUrl']?.toString(),
    text: (data['text'] ?? '').toString(),
    createdAt: createdAt,
    replyToAuthor: data['replyToAuthor']?.toString(),
    replyToId: data['replyToId']?.toString(), // NEW
    votes: (data['votes'] as num?)?.toInt() ?? 0,
    upvoted: currentUid != null && upvotedBy.contains(currentUid),
    downvoted: currentUid != null && downvotedBy.contains(currentUid),
    mediaUrl: data['mediaUrl']?.toString(),    // NEW
    mediaType: data['mediaType']?.toString(),  // NEW
    replies: replies,
    isEdited:data['isEdited'] == true,
  );
}
// ==========================Tree-Line=========================================
class _ThreadedReplies extends StatefulWidget {
  const _ThreadedReplies({
    required this.replies,
    required this.depth,
    required this.actions,
    this.firstItemTopOffset,
  });

  final List<_Comment> replies;
  final int depth;
  final _CommentActionsCallbacks actions;
  final double? firstItemTopOffset;

  static const double _avatarSize = 28;
  static const double _rowTopPadding = 4;
  static const double _connectorWidth = 24;
  static const double _trunkX = 12;
  static const double _cornerRadius = 10;

  static const double _mobileBreakpoint = 540;
  static const int _maxMobileDepth = 4;
  static const int _maxDesktopDepth = 8;

  // NEW: كم رد يبان أول مرة، وكم كيزاد كل ضغطة على "عرض المزيد"
  static const int _initialVisible = 1;
  static const int _revealStep = 5;

  @override
  State<_ThreadedReplies> createState() => _ThreadedRepliesState();
}

class _ThreadedRepliesState extends State<_ThreadedReplies> {
  late int _visibleCount =
  _ThreadedReplies._initialVisible.clamp(0, widget.replies.length);

  @override
  void didUpdateWidget(covariant _ThreadedReplies oldWidget) {
    super.didUpdateWidget(oldWidget);
    // NEW: إذا نقص عدد الردود (حذف مثلاً)، نضمنو العداد ما يفوتش الحد الجديد
    if (widget.replies.length < _visibleCount) {
      setState(() => _visibleCount = widget.replies.length);
    }
  }

  void _revealMore() {
    setState(() {
      _visibleCount = (_visibleCount + _ThreadedReplies._revealStep)
          .clamp(0, widget.replies.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final replies = widget.replies;
    if (replies.isEmpty) return const SizedBox.shrink();

    final depth = widget.depth;
    final actions = widget.actions;

    final t = _CommentTheme.of(context);
    final isMobile = MediaQuery.of(context).size.width < _ThreadedReplies._mobileBreakpoint;
    final maxDepth = isMobile ? _ThreadedReplies._maxMobileDepth : _ThreadedReplies._maxDesktopDepth;
    final connectorWidth = _threadIndentForDepth(depth);
    final avatarCenterY = _ThreadedReplies._rowTopPadding + (_ThreadedReplies._avatarSize / 5);
    final trunkGap = connectorWidth -
        (_ThreadedReplies._trunkX * (connectorWidth / _ThreadedReplies._connectorWidth));

    final visibleReplies = replies.take(_visibleCount).toList();
    final hasMore = _visibleCount < replies.length;

    // NEW: صف "عرض المزيد" بيصير جزء من نفس القائمة، مايتضافش برا
    final rowCount = visibleReplies.length + (hasMore ? 1 : 0);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(rowCount, (i) {
          final isMoreRow = hasMore && i == visibleReplies.length;

          // NEW: صف زر "عرض المزيد" — نفس بنية الخط ديال أي رد عادي
          if (isMoreRow) {
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _TreeLinePainter(
                        isLast: true, // هذا آخر عنصر فعلي فالقائمة دايمًا
                        avatarCenterY: _RevealMoreRepliesButton.rowHeight / 2,
                        trunkGap: trunkGap,
                        connectorWidth: connectorWidth,
                        cornerRadius: _ThreadedReplies._cornerRadius,
                        color: t.threadLine,
                        topOffset: (i == 0 && widget.firstItemTopOffset != null)
                            ? widget.firstItemTopOffset!
                            : -42,
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: TextDirection.ltr,
                    children: [
                      SizedBox(width: connectorWidth),
                      Expanded(
                        child: _RevealMoreRepliesButton(
                          remaining: replies.length - _visibleCount,
                          onTap: _revealMore,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          final reply = visibleReplies[i];
          // FIX: إذا كاين "عرض المزيد" بعدو، هاد الرد ماشي آخر واحد فعليًا
          final isLast = (i == visibleReplies.length - 1) && !hasMore;
          final atDepthCap = depth >= maxDepth;
          final replyHasChildren = reply.replies.isNotEmpty;
          final childrenCollapsed = actions.isCollapsed(reply.id);
          final childrenIndent = _threadIndentForDepth(depth + 1);
          final replyAvatarSize = depth > 0 ? 32.0 : 36.0;

          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TreeLinePainter(
                      isLast: isLast,
                      avatarCenterY: avatarCenterY,
                      trunkGap: trunkGap,
                      connectorWidth: connectorWidth,
                      cornerRadius: _ThreadedReplies._cornerRadius,
                      color: t.threadLine,
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: TextDirection.ltr,
                  children: [
                    SizedBox(width: connectorWidth),
                    Expanded(
                      child: (replyHasChildren && childrenCollapsed)
                          ? _CollapsedThreadConnector(
                        avatarSize: replyAvatarSize,
                        indent: childrenIndent,
                        onTap: () => actions.onToggleCollapse(reply.id),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CommentTile(
                              key: ValueKey(reply.id),
                              comment: reply,
                              depth: depth,
                              actions: actions,
                            ),
                            _CollapsedThreadStub(
                              parent: reply,
                              indent: childrenIndent,
                              onTap: () => actions.onToggleCollapse(reply.id),
                            ),
                          ],
                        ),
                      )
                          : (!replyHasChildren)
                          ? CommentTile(
                        key: ValueKey(reply.id),
                        comment: reply,
                        depth: depth,
                        actions: actions,
                      )
                          : atDepthCap
                      // FIX: نفس منطق الطي العادي (_CollapsedThreadConnector) — كيرسم
                      // الخط من الأفاتار نزولا لزر "عرض المزيد" اللي كيفتح الردود العميقة
                          ? _CollapsedThreadConnector(
                        avatarSize: replyAvatarSize,
                        indent: childrenIndent,
                        onTap: () => actions.onOpenThread(reply),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CommentTile(
                              key: ValueKey(reply.id),
                              comment: reply,
                              depth: depth,
                              actions: actions,
                            ),
                            _ContinueThreadLink(comment: reply, onTap: () => actions.onOpenThread(reply)),
                          ],
                        ),
                      )
                          : _ExpandedThreadBranch(
                        // FIX: التعليق والزر دابا فنفس الـ Stack، فالخط ماعادش
                        // مرتبط بطول نص الرد إطلاقًا
                        header: CommentTile(
                          key: ValueKey(reply.id),
                          comment: reply,
                          depth: depth,
                          actions: actions,
                        ),
                        repliesChild: _ThreadedReplies(
                          replies: reply.replies,
                          depth: depth + 1,
                          actions: actions,
                        ),
                        avatarSize: replyAvatarSize,
                        buttonIndent: childrenIndent,
                        onToggle: () => actions.onToggleCollapse(reply.id),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
class _FocusedRootComment extends StatelessWidget {
  const _FocusedRootComment({
    required this.comment,
    required this.actions,
  });

  final _Comment comment;
  final _CommentActionsCallbacks actions;
  static const double _rootGap = 23;

  @override
  Widget build(BuildContext context) {
    final t = _CommentTheme.of(context);
    final hasReplies = comment.replies.isNotEmpty;
    final collapsed = actions.isCollapsed(comment.id);
    final childrenIndent = _threadIndentForDepth(1);

    final rootContainer = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: t.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(width: 1.4, color: t.accent.withValues(alpha: 0.35)),
        boxShadow: t.isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: CommentTile(
        key: ValueKey(comment.id),
        comment: comment,
        depth: 0,
        actions: actions,
      ),
    );

    if (!hasReplies) return rootContainer;

    if (collapsed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          rootContainer,
          const SizedBox(height: _rootGap),
          _CollapsedThreadStub(
            parent: comment,
            indent: childrenIndent,
            onTap: () => actions.onToggleCollapse(comment.id),
          ),
        ],
      );
    }

    // NEW: نمررو الإزاحة الحقيقية لمركز الأفاتار — الحاوية عندها
    // padding:14 + border:1.4، فمركز الأفاتار مزاح بـ ~15.4px عن حواف
    // الحاوية، ماشي 0 بحال CommentTile لوحدها بلا حاوية
    const double containerInset = 15.4;
    return _ExpandedThreadBranch(
      header: rootContainer,
      repliesChild: _ThreadedReplies(replies: comment.replies, depth: 1, actions: actions
        ,firstItemTopOffset: -(_rootGap + 12),
      ),
      avatarSize: 36,
      buttonIndent: childrenIndent,
      onToggle: () => actions.onToggleCollapse(comment.id),
      headerAvatarOffset: const Offset(containerInset + (36 / 2) - 2, containerInset + (36 / 2)),
      showLine: false,
      repliesTopSpacing: _rootGap,
      buttonVerticalOffset: 25,
    );
  }
}

class _TreeLinePainter extends CustomPainter {
  _TreeLinePainter({
    required this.isLast,
    required this.avatarCenterY,
    required this.trunkGap,
    required this.connectorWidth,
    required this.cornerRadius,
    required this.color,
    this.topOffset = -8,
  });
  final bool isLast;
  final double avatarCenterY;
  final double trunkGap;
  final double connectorWidth;
  final double cornerRadius;
  final Color color;
  final double topOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double trunkXPos = trunkGap;
    final double avatarEdgeX = connectorWidth;

    final branch = Path()
      ..moveTo(trunkXPos, -48)
      ..lineTo(trunkXPos, avatarCenterY - cornerRadius)
      ..quadraticBezierTo(
        trunkXPos, avatarCenterY,
        avatarEdgeX, avatarCenterY,
      );
    canvas.drawPath(branch, paint);

    if (!isLast) {
      canvas.drawLine(
        Offset(trunkXPos, -45),
        Offset(trunkXPos, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TreeLinePainter oldDelegate) {
    return oldDelegate.isLast != isLast ||
        oldDelegate.avatarCenterY != avatarCenterY ||
        oldDelegate.color != color;
    oldDelegate.topOffset != topOffset;
  }
}

class _ThreadToggleButton extends StatelessWidget {
  const _ThreadToggleButton({required this.collapsed, required this.onTap});

  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = _CommentTheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: t.cardBg,
          shape: BoxShape.circle,
          border: Border.all(color:  Theme.of(context).colorScheme.onSurface, width: 1.3),
        ),
        child: Icon(
          collapsed ? Icons.add_rounded : Icons.remove_rounded,
          size: 12,
          color:  Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _CollapsedThreadConnector extends StatelessWidget {
  const _CollapsedThreadConnector({
    required this.avatarSize,
    required this.indent,
    required this.child,
    this.onTap,
    this.showLine = true, // NEW: بحال ما دايرين فـ _ExpandedThreadBranch
  });

  final double avatarSize;
  final double indent;
  final Widget child;
  final VoidCallback? onTap;
  final bool showLine; // NEW

  @override
  Widget build(BuildContext context) {
    final t = _CommentTheme.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            // FIX: إلا showLine=false، منطقة قابلة للمس بلا رسم خط
            child: showLine
                ? CustomPaint(
              painter: _CollapsedLinePainter(
                avatarSize: avatarSize,
                indent: indent,
                color: t.threadLine,
              ),
            )
                : const SizedBox.expand(),
          ),
        ),
        child,
      ],
    );
  }
}

class _CollapsedLinePainter extends CustomPainter {
  _CollapsedLinePainter({
    required this.avatarSize,
    required this.indent,
    required this.color,
  });

  final double avatarSize;
  final double indent;
  final Color color;

  static const double _cornerRadius = 8;
  static const double _buttonCenterOffsetFromBottom = _CollapsedThreadStub.rowHeight / 2;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // نفس منطق _TreeLinePainter: نطرحو من size.width لأن الاتجاه RTL
    final double avatarX = avatarSize / 2;
    final double buttonX = indent;
    final double avatarCenterY = avatarSize / 2;
    final double buttonCenterY = size.height - _buttonCenterOffsetFromBottom;

    final path = Path()
      ..moveTo(avatarX, avatarCenterY)
      ..lineTo(avatarX, buttonCenterY - _cornerRadius)
      ..quadraticBezierTo(
        avatarX, buttonCenterY,
        buttonX, buttonCenterY,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CollapsedLinePainter oldDelegate) {
    return oldDelegate.avatarSize != avatarSize ||
        oldDelegate.indent != indent ||
        oldDelegate.color != color;
  }
}

class _CollapsedThreadStub extends StatelessWidget {
  const _CollapsedThreadStub({
    required this.parent,
    required this.indent,
    required this.onTap,
  });

  final _Comment parent;
  final double indent;
  final VoidCallback onTap;
  static const double rowHeight = 18;
  @override
  Widget build(BuildContext context) {
    final t = _CommentTheme.of(context);
    final children = parent.replies;
    final label = children.length == 1
        ? '${children.first.author} • ${children.first.timeAgo}'
        : ' ${children.length} more replies ';

    return Padding(
      padding: EdgeInsetsDirectional.only(start: indent -0, top: 8),
      child:SizedBox(
          height: rowHeight,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: TextDirection.ltr,
              children: [
                _ThreadToggleButton(collapsed: true, onTap: onTap),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(color: t.textMuted, fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          )),
    );
  }
}



class _ContinueThreadLink extends StatelessWidget {
  const _ContinueThreadLink({required this.comment, required this.onTap});

  final _Comment comment;
  final VoidCallback onTap; // NEW: بدل الـ TODO الفارغ

  @override
  Widget build(BuildContext context) {
    final t = _CommentTheme.of(context);
    final count = comment.totalReplyCount;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 10,start: 25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.ltr,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: t.cardBg,
                shape: BoxShape.circle,
                border: Border.all(
                    color:Theme.of(context)
                        .colorScheme.onSurface.withValues(alpha: 0.9),
                    width: 1.3),
              ),
              child: Icon(Icons.add_rounded, size: 12,
                color: Theme.of(context)
                    .colorScheme.onSurface.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              count == 1 ? mainText(context, "{0} more reply", <Object?>[count]) : mainText(context, "{0} more replies", <Object?>[count]),
              style: TextStyle(color: t.textMuted, fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
class _RevealMoreRepliesButton extends StatelessWidget {
  const _RevealMoreRepliesButton({
    required this.remaining,
    required this.onTap,
  });

  final int remaining;
  final VoidCallback onTap;

  static const double rowHeight = 18;

  @override
  Widget build(BuildContext context) {
    final t = _CommentTheme.of(context);
    return SizedBox(
      height: rowHeight,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.ltr,
          children: [
            _ThreadToggleButton(collapsed: true, onTap: onTap),
            const SizedBox(width: 8),
            Text(
              remaining == 1 ? mainText(context, "{0} more reply", <Object?>[remaining]) : mainText(context, "{0} more replies", <Object?>[remaining]),
              style: TextStyle(color: t.textMuted, fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandedThreadBranch extends StatefulWidget {
  const _ExpandedThreadBranch({
    required this.header,
    required this.repliesChild,
    required this.avatarSize,
    required this.buttonIndent,
    required this.onToggle,
    this.headerAvatarOffset, // NEW: موقع مركز الأفاتار داخل الهيدر (اختياري)
    this.showLine = true,
    this.repliesTopSpacing = 0,
    this.buttonVerticalOffset = 0,
  });

  final Widget header;
  final Widget repliesChild;
  final double avatarSize;
  final double buttonIndent;
  final VoidCallback onToggle;
  final Offset? headerAvatarOffset;
  final bool showLine;
  final double repliesTopSpacing; // NEW
  final double buttonVerticalOffset;

  @override
  State<_ExpandedThreadBranch> createState() => _ExpandedThreadBranchState();
}

class _ExpandedThreadBranchState extends State<_ExpandedThreadBranch> {
  double? _headerHeight;

  @override
  Widget build(BuildContext context) {
    final t = _CommentTheme.of(context);

    // موقع مركز الأفاتار داخل الهيدر — افتراضي: نفس منطق CommentTile
    // (PositionedDirectional(start: -2, top: 0))
    final avatarOffset = widget.headerAvatarOffset ??
        Offset((widget.avatarSize / 2) - 2, widget.avatarSize / 2);

    final headerHeight = _headerHeight;
    final lineHeight = headerHeight == null
        ? 0.0
        : (headerHeight - avatarOffset.dy + 13).clamp(0.0, double.infinity);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NEW: نقيسو طول الهيدر الحقيقي هنا
            _MeasureSize(
              onChange: (size) {
                if (_headerHeight != size.height) {
                  setState(() => _headerHeight = size.height);
                }
              },
              child: widget.header,
            ),
            if (widget.repliesTopSpacing > 0)
              SizedBox(height: widget.repliesTopSpacing), // NEW
            widget.repliesChild,
          ],
        ),
        if (headerHeight != null) ...[
          if (widget.showLine)
            Positioned(
              left: 0,
              right: 55,
              top: avatarOffset.dy,
              height: lineHeight,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ExpandedLinePainter(
                    avatarX: avatarOffset.dx,
                    buttonX: widget.buttonIndent,
                    color: t.threadLine,
                  ),
                ),
              ),
            ),
          Positioned(
            left: widget.buttonIndent - 22,
            top: headerHeight - 13+ widget.buttonVerticalOffset,
            child: _ThreadToggleButton(collapsed: false, onTap: widget.onToggle),
          ),
        ],
      ],
    );
  }
}

class _ExpandedLinePainter extends CustomPainter {
  _ExpandedLinePainter({
    required this.avatarX,
    required this.buttonX,
    required this.color,
  });

  final double avatarX;
  final double buttonX;
  final Color color;

  static const double _cornerRadius = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(avatarX, 16)
      ..lineTo(avatarX, size.height - _cornerRadius)
      ..quadraticBezierTo(avatarX, size.height, buttonX-13.5, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ExpandedLinePainter oldDelegate) {
    return oldDelegate.avatarX != avatarX ||
        oldDelegate.buttonX != buttonX ||
        oldDelegate.color != color;
  }
}

// ==========================Comment====================================


class _MediaUploadError implements Exception {
  const _MediaUploadError(this.message);
  final String message;
}

enum CommentMediaKind { image, video, gif }

class CommentAttachment {
  final CommentMediaKind kind;
  final Uint8List bytes;
  final String extension; // 'jpg' | 'mp4' | 'gif' | 'png' ...

  String get uploadContentType {
    const types = {
      'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'png': 'image/png',
      'gif': 'image/gif', 'webp': 'image/webp', 'bmp': 'image/bmp',
      'heic': 'image/heic', 'heif': 'image/heif', 'avif': 'image/avif',
      'mp4': 'video/mp4', 'mov': 'video/quicktime', 'm4v': 'video/x-m4v',
      'webm': 'video/webm', 'mkv': 'video/x-matroska', '3gp': 'video/3gpp',
    };
    final type = types[extension.toLowerCase()];
    if (type == null || (kind == CommentMediaKind.video) != type.startsWith('video/') ||
        (kind == CommentMediaKind.gif && type != 'image/gif')) {
      throw  _MediaUploadError(mainTextCurrent("صيغة المرفق غير مدعومة؛ اختر صورة أو فيديو آخر"));
    }
    return type;
  }

  const CommentAttachment({
    required this.kind,
    required this.bytes,
    required this.extension,
  });

  // NEW: من ملف مختار من المعرض (صورة أو فيديو)
  static Future<CommentAttachment> fromFile(File file, CommentMediaKind kind) async {
    final bytes = await file.readAsBytes();
    final rawExt = file.path.contains('.') ? file.path.split('.').last.toLowerCase() : '';
    final ext = rawExt.isNotEmpty ? rawExt : (kind == CommentMediaKind.video ? 'mp4' : 'jpg');
    return CommentAttachment(kind: kind, bytes: bytes, extension: ext);
  }

  // NEW: من محتوى مبعوث مباشرة من الكيبورد (GIF أو صورة/ستيكر)
  static CommentAttachment fromKeyboardContent(KeyboardInsertedContent content) {
    final mime = content.mimeType.toLowerCase();
    final isGif = mime.contains('gif');
    final ext = isGif
        ? 'gif'
        : mime.contains('png')
        ? 'png'
        : mime.contains('webp')
        ? 'webp'
        : 'jpg';
    return CommentAttachment(
      kind: isGif ? CommentMediaKind.gif : CommentMediaKind.image,
      bytes: content.data!,
      extension: ext,
    );
  }
}





class _VoteColumn extends StatelessWidget {
  const _VoteColumn({
    required this.votes,
    required this.upvoted,
    required this.downvoted,
    required this.onUpvote,
    required this.onDownvote,
  });

  final int votes;
  final bool upvoted;
  final bool downvoted;
  final VoidCallback onUpvote;
  final VoidCallback onDownvote;

  static const Color _upColor = Color(0xFFFF4500);
  static const Color _downColor = Color(0xFF7193FF);

  @override
  Widget build(BuildContext context) {
    final t = _CommentTheme.of(context);
    final Color countColor = upvoted
        ? _upColor
        : downvoted
        ? _downColor
        : t.textFaint; // NEW: أخف من textMuted فحالة الراحة، باش ما يزاحمش النص

    return Transform.translate(
        offset: const Offset(0, -0),
        child:
    Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _VoteArrowButton(
          icon: Icons.keyboard_arrow_up_rounded,
          active: upvoted,
          activeColor: _upColor,
          restColor: t.textFaint,
          onTap: onUpvote,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 0),
          child: Text(
            _formatVoteCount(votes),
            style: TextStyle(
              color: countColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
        _VoteArrowButton(
          icon: Icons.keyboard_arrow_down_rounded,
          active: downvoted,
          activeColor: _downColor,
          restColor: t.textFaint,
          onTap: onDownvote,
        ),
      ],
    ));
  }

  // NEW: تقصير الأرقام الكبيرة (1.2k) باش العمود يبقى ضيق وما يكسرش التخطيط
  String _formatVoteCount(int v) {
    final abs = v.abs();
    if (abs < 1000) return '$v';
    final sign = v < 0 ? '-' : '';
    final k = abs / 1000;
    return '$sign${k.toStringAsFixed(k < 10 ? 1 : 0)}k';
  }
}

class _VoteArrowButton extends StatelessWidget {
  const _VoteArrowButton({
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.restColor,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final Color activeColor;
  final Color restColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: onTap,
        radius: 18, // منطقة تأثير اللمس بصريًا
        highlightShape: BoxShape.circle,
        child: SizedBox(
          width: 26,
          height: 24, // منطقة اللمس الفعلية أكبر من الأيقونة الظاهرة
          child: Center(
            child: AnimatedScale(
              scale: active ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: Icon(
                icon,
                size: 15, // NEW: مصغّرة أكثر لتخفيف الوزن البصري بجانب النص
                color: active ? activeColor : restColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}



class _InlineMediaIcon extends StatelessWidget {
  const _InlineMediaIcon(
      {required this.icon, required this.onTap, required this.t});
  final IconData icon;
  final VoidCallback onTap;
  final _CommentTheme t;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 10),
        child: Icon(icon, size: 19, color: t.textMuted),
      ),
    );
  }
}

class _ReplyBanner extends StatelessWidget {
  const _ReplyBanner(
      {required this.replyTo, required this.onCancel, required this.t});
  final _Comment replyTo;
  final VoidCallback onCancel;
  final _CommentTheme t;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: t.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.reply_rounded, size: 15, color: t.accent),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: mainText(context, "Replying to "),
                  style: TextStyle(color: t.textMuted, fontSize: 12),
                ),
                TextSpan(
                  text: replyTo.author,
                  style: TextStyle(color: t.accent, fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: onCancel,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Icon(Icons.close_rounded, size: 15, color: t.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentAvatar extends StatelessWidget {
  final bool isReply;
  final String? userId;
  final String? photoUrl;

  const _CommentAvatar({
    super.key,
    required this.isReply,
    this.userId,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return LiveAuthorPhoto(
      userId: userId,
      fallbackUrl: photoUrl,
      size: isReply ? 28 : 32,
      radius: isReply ? 11 : 12,
      iconSize: isReply ? 15 : 17,
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({required this.attachment, required this.onRemove});
  final CommentAttachment attachment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = _CommentTheme.of(context);
    Widget preview;
    String label;
    switch (attachment.kind) {
      case CommentMediaKind.image:
        preview = Image.memory(attachment.bytes, width: 56, height: 56, fit: BoxFit.cover);
        label = mainText(context, "صورة مرفقة");
        break;
      case CommentMediaKind.video:
        preview = Container(
          width: 56, height: 56,
          color: t.chipBg,
          child: Icon(Icons.videocam_rounded, color: t.textMuted),
        );
        label = mainText(context, "فيديو مرفق");
        break;
      case CommentMediaKind.gif:
        preview = Image.memory(attachment.bytes, width: 56, height: 56, fit: BoxFit.cover); // FIX: memory بدل network
        label = mainText(context, "GIF مرفق");
        break;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: t.chipBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.cardBorder),
      ),
      child: Row(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: preview),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: t.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          const Spacer(),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(12),
            child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.close_rounded, size: 18, color: t.textMuted)),
          ),
        ],
      ),
    );
  }
}

class _CommentMedia extends StatefulWidget {
  const _CommentMedia(
      {required this.postId, required this.commentId, required this.url, required this.type});
  final String postId, commentId;
  final String url;
  final String? type;

  @override
  State<_CommentMedia> createState() => _CommentMediaState();
}

class _CommentMediaState extends State<_CommentMedia> {
  bool _opening = false;
  Future<void> _openImage() async {
    if (_opening) return;
    final postId = widget.postId, commentId = widget.commentId, url = widget.url;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final blocks = blockedListRevision.value, moderation = moderationRevision.value,
        profiles = authorProfileRevision.value;
    bool current() => mounted && uid != null && uid == FirebaseAuth.instance.currentUser?.uid &&
        postId == widget.postId && commentId == widget.commentId && url == widget.url &&
        blocks == blockedListRevision.value && moderation == moderationRevision.value &&
        profiles == authorProfileRevision.value;
    _opening = true;
    try {
      final fresh = _Post.fromData(postId, await _readAuthorizedPostData(postId));
      if (!current()) return;
      final matches = <_Comment>[];
      void visit(List<_Comment> comments) {
        for (final comment in comments) {
          if (comment.id == commentId) matches.add(comment);
          visit(comment.replies);
        }
      }
      visit(fresh.comments);
      if (matches.length != 1 || matches.single.mediaUrl != url || matches.single.mediaType == 'video') {
        throw StateError('Comment image unavailable');
      }
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => Uri.tryParse(url)?.host == 'firebasestorage.googleapis.com'
            ? _AuthorizedImageView(postId: postId, commentId: commentId, path: url)
            : FullscreenImageViewer(images: [url], initialIndex: 0),
      ));
    } catch (_) {
      if (current()) ScaffoldMessenger.maybeOf(context)?.showSnackBar(
         SnackBar(content: Text(mainText(context, "تعذر فتح الصورة، ربما لم يعد التعليق متاحًا"))),
      );
    } finally {
      _opening = false;
    }
  }
  @override
  Widget build(BuildContext context) {
    final url = widget.url, type = widget.type;
    final isVideo = type == 'video';
    return GestureDetector(
      onTap: isVideo ? null : _openImage,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: isVideo
              ? _VideoSlideWidget(
                  key: ValueKey(
                      [widget.postId, widget.commentId, url].join('|')),
                  videoPath: url,
                  postId: Uri.tryParse(url)?.host == 'firebasestorage.googleapis.com' ? widget.postId : null,
                  commentId: Uri.tryParse(url)?.host == 'firebasestorage.googleapis.com' ? widget.commentId : null,
                )
              : Uri.tryParse(url)?.host == 'firebasestorage.googleapis.com'
              ? _AuthorizedImageView(key: ValueKey(
                          [widget.postId, widget.commentId, url].join('|')),
                  postId: widget.postId, commentId: widget.commentId, path: url, preview: true)
              : Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) =>
            progress == null ? child : const Center(child: CircularProgressIndicator()),
            errorBuilder: (context, error, stack) => Container(
              height: 140,
              color: Colors.black12,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_rounded),
            ),
          ),
        ),
      ),
    );
  }
}

class _CommentDialog extends StatefulWidget {
  const _CommentDialog({super.key});

  @override
  State<_CommentDialog> createState() => __CommentDialogState();
}

class __CommentDialogState extends State<_CommentDialog> {
  final _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:  Text(mainText(context, "Add Comment")),
      content: TextField(
        controller: _commentController,
        decoration:  InputDecoration(hintText: mainText(context, "Enter your comment")),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child:  Text(mainText(context, "Cancel")),
        ),
        ElevatedButton(
          onPressed: () {
            if (_commentController.text.trim().isNotEmpty) {
              Navigator.pop(context, _commentController.text);
            }
          },
          child:  Text(mainText(context, "Post")),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}

class _CommentThreadCard extends StatelessWidget {
  const _CommentThreadCard({
    required this.comment,
    required this.actions,
  });

  final _Comment comment;
  final _CommentActionsCallbacks actions;

  @override
  Widget build(BuildContext context) {
    final t = _CommentTheme.of(context);
    final hasReplies = comment.replies.isNotEmpty;
    final collapsed = actions.isCollapsed(comment.id);
    final childrenIndent = _threadIndentForDepth(1);

    return Container(
      decoration: BoxDecoration(
        color: t.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(width: 1, color: t.cardBorder),
        boxShadow: t.isDark ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      padding: const EdgeInsets.all(13),
      child: !hasReplies
          ? CommentTile(
        key: ValueKey(comment.id),
        comment: comment,
        depth: 0,
        actions: actions,
      )
          : collapsed
          ? _CollapsedThreadConnector(
        avatarSize: 36,
        indent: childrenIndent,
        onTap: () => actions.onToggleCollapse(comment.id),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CommentTile(
              key: ValueKey(comment.id),
              comment: comment,
              depth: 0,
              actions: actions,
            ),
            _CollapsedThreadStub(
              parent: comment,
              indent: childrenIndent,
              onTap: () => actions.onToggleCollapse(comment.id),
            ),
          ],
        ),
      )
          : _ExpandedThreadBranch(
        // FIX: نفس الإصلاح — التعليق الجذر والزر فنفس الـ Stack
        header: CommentTile(
          key: ValueKey(comment.id),
          comment: comment,
          depth: 0,
          actions: actions,
        ),
        repliesChild: _ThreadedReplies(replies: comment.replies, depth: 1, actions: actions),
        avatarSize: 36,
        buttonIndent: childrenIndent,
        onToggle: () => actions.onToggleCollapse(comment.id),
        showLine: false,
      ),
    );
  }
}

//================================================
class ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;

  const ExpandableText({
    super.key,
    required this.text,
    this.style,
    this.maxLines = 3,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;
  bool _overflowing = false;

  bool _isArabic(String t) => RegExp(r'[\u0600-\u06FF]').hasMatch(t);

  void _checkOverflow(double maxWidth, TextStyle style, TextDirection dir) {
    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: style),
      maxLines: widget.maxLines,
      textDirection: dir,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);

    final next = painter.didExceedMaxLines;
    if (next != _overflowing && mounted) {
      setState(() => _overflowing = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DefaultTextStyle.of(context).style;
    final isAr = _isArabic(widget.text);
    final dir = isAr ? TextDirection.rtl : TextDirection.ltr;
    final align = isAr ? TextAlign.right : TextAlign.left;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 48;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkOverflow(width, style, dir);
        });

        return Column(
          crossAxisAlignment:
          isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              textDirection: dir,
              textAlign: align,
              style: style,
              softWrap: true,
              maxLines: _expanded ? null : widget.maxLines,
              overflow:
              _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (_overflowing)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded ? mainText(context, "عرض أقل") : mainText(context, "عرض المزيد"),
                    style: style.copyWith(
                      color: const Color(0xFF1565C0),
                      fontWeight: FontWeight.w800,
                      fontSize: (style.fontSize ?? 13) * 0.95,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
//=============================================================

double _threadIndentForDepth(int depth) {
  const connectorWidth = 27.0;
  const decayStart = 15;
  const minIndent = 15.0;
  if (depth <= decayStart) return connectorWidth;
  final shrink = (depth - decayStart) * 5.0;
  return (connectorWidth - shrink).clamp(minIndent, connectorWidth);
}
class _CommentTheme {
  final bool isDark;
  final Color pageBg;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textMuted;
  final Color textFaint;
  final Color accent;
  final Color accentSecondary;
  final Color threadLine;
  final Color avatarBg;
  final Color chipBg;
  final Color inputBg;
  final Color inputBorder;
  final Color sheetBg;
  final Color danger;
  final Color textBody;

  const _CommentTheme._({
    required this.isDark,
    required this.pageBg,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textMuted,
    required this.textFaint,
    required this.accent,
    required this.accentSecondary,
    required this.threadLine,
    required this.avatarBg,
    required this.chipBg,
    required this.inputBg,
    required this.inputBorder,
    required this.sheetBg,
    required this.danger,
    required this.textBody,

  });

  factory _CommentTheme.of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    const accent = Color(0xFF17A2A8);
    const accentSecondary = Color(0xFF1565C0);

    return _CommentTheme._(
      isDark: dark,
      pageBg: Theme.of(context).colorScheme.surface,
      cardBg: dark ? const Color(0xFF171B1E) : Colors.white,
      cardBorder: dark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.06),
      textPrimary: dark ? const Color(0xFFE7EAEB) : const Color(0xFF1C1C1C),
      textMuted: dark ? const Color(0xFF8B9296) : const Color(0xFF6B7280),
      textFaint: dark ? const Color(0xFF5B6266) : const Color(0xFF9CA3AF),
      accent: accent,
      accentSecondary: accentSecondary,
      threadLine: dark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.black.withValues(alpha: 0.1),
      avatarBg: dark ? const Color(0xFF2A2F33) : const Color(0xFFE9EAEB),
      chipBg: dark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
      inputBg: dark ? const Color(0xFF1D2226) : const Color(0xFFF5F6F7),
      inputBorder: dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
      sheetBg: dark ? const Color(0xFF1B1F22) : Colors.white,
      danger: const Color(0xFFE5484D),
      textBody: dark ? const Color(0xFFC9CDCE) : const Color(0xFF34383C),
    );
  }
}

Future<void> _postComment({required BuildContext context, required String postId, required String text,
  required _Comment? replyTo, CommentAttachment? attachment,
  required void Function(_Comment newComment, bool isReply) onSuccess,
}) async {
  final txt = text.trim();
  if (txt.isEmpty && attachment == null) return;
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context)
        .showSnackBar( SnackBar(content: Text(mainText(context, "يجب تسجيل الدخول أولاً"))));
    return;
  }
  final commentId = FirebaseFirestore.instance.collection('community_comments').doc().id;
  try {
    // Check before uploading; the server checks again transactionally at creation.
    final post = await _readAuthorizedPostData(postId);
    if (post['canComment'] != true) throw StateError(mainText(context, "التعليق غير مسموح على هذا المنشور"));
    String? mediaUrl;
    String? mediaType;
    if (attachment != null) {
      final ref = FirebaseStorage.instance.ref(
          'community_posts/$postId/comments/${user.uid}/$commentId/media.${attachment.extension}');
      if (attachment.bytes.isEmpty || attachment.bytes.length > 40 * 1024 * 1024) {
        throw  _MediaUploadError(mainText(context, "يجب أن يكون المرفق غير فارغ وألا يتجاوز 40 ميغابايت"));
      }
      final contentType = attachment.uploadContentType;
      if (FirebaseAuth.instance.currentUser?.uid != user.uid) throw StateError(mainText(context, "تغيّر الحساب"));
      await ref.putData(
          attachment.bytes, SettableMetadata(contentType: contentType));
      mediaUrl = await ref.getDownloadURL();
      mediaType = switch (attachment.kind) {
        CommentMediaKind.video => 'video', CommentMediaKind.gif => 'gif', CommentMediaKind.image => 'image',
      };
    }
    if (FirebaseAuth.instance.currentUser?.uid != user.uid) throw StateError(mainText(context, "تغيّر الحساب"));
    final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('createComment', options: HttpsCallableOptions(timeout: const Duration(seconds: 120)))
        .call<Map<String, dynamic>>({
          'postId': postId, 'commentId': commentId, 'text': txt, 'replyToId': replyTo?.id,
          'media': mediaUrl == null ? null : {'url': mediaUrl, 'type': mediaType},
        });
    final raw = response.data['comment'];
    if (raw is! Map || raw['id'] != commentId || raw['authorId'] != user.uid) {
      throw const FormatException('Invalid comment response');
    }
    if (!context.mounted || FirebaseAuth.instance.currentUser?.uid != user.uid) return;
    onSuccess(_commentFromMap(Map<String, dynamic>.from(raw)), replyTo != null);
  } catch (e) {
    if (!context.mounted) return;
    if (e is _MediaUploadError) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    final denied = e is FirebaseFunctionsException && e.code == 'permission-denied';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(denied
        ? mainText(context, "التعليق غير مسموح وفق إعدادات الخصوصية الحالية.")
        : mainText(context, "تعذر تأكيد حفظ التعليق. حدّث القائمة قبل إعادة الإرسال."))));
  }
}

bool _insertReplyIntoCommentsStatic(List<Map<String, dynamic>> comments, String parentId, Map<String, dynamic> reply,
) {
  for (final comment in comments) {
    if (comment['id'] == parentId) {
      final replies = List<Map<String, dynamic>>.from(
        (comment['replies'] as List? ?? [])
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );
      replies.insert(0, reply);
      comment['replies'] = replies;
      return true;
    }
    final replies = List<Map<String, dynamic>>.from(
      (comment['replies'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map)),
    );
    if (_insertReplyIntoCommentsStatic(replies, parentId, reply)) {
      comment['replies'] = replies;
      return true;
    }
  }
  return false;
}




class _CommentActionsCallbacks {
  final String postId;
  const _CommentActionsCallbacks({
    required this.postId,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
    required this.onReport,
    required this.onBlock,
    required this.onRepost,
    required this.onToggleLike,
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.keyFor,
    required this.onToggleDownvote,
    required this.onJumpToParent,
    required this.onOpenThread,
    this.onSave,
    this.isCommentSaved,

  });

  final void Function(_Comment) onToggleDownvote;
  final void Function(_Comment) onReply;
  final void Function(_Comment) onEdit;
  final void Function(_Comment) onDelete;
  final void Function(_Comment) onReport;
  final void Function(_Comment) onBlock;
  final void Function(_Comment) onRepost;
  final void Function(_Comment) onToggleLike;
  final bool Function(String commentId) isCollapsed;
  final void Function(String commentId) onToggleCollapse;
  final GlobalKey Function(String commentId) keyFor;
  final void Function(String commentId) onJumpToParent;
  final Future<void> Function(_Comment comment)? onSave;
  final bool Function(String commentId)? isCommentSaved;

  final void Function(_Comment) onOpenThread; // NEW: فتح صفحة مخصصة للفرع العميق
}

// NEW: زر "تحميل المزيد" — يُستعمل الآن كصف إضافي داخل نفس نظام خطوط الشجرة


bool _findCommentLocalStatic(List<_Comment> comments,
    String id,
    void Function(_Comment) apply,
) {
  for (final c in comments) {
    if (c.id == id) {
      apply(c);
      return true;
    }
    if (_findCommentLocalStatic(c.replies, id, apply)) return true;
  }
  return false;
}





// ============================================================================
//                              Profil
// ============================================================================

// =========================== Main-Profil ==========================
