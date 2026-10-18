part of '../../main.dart';

class AuthorProfiles {
  AuthorProfiles._();

  static final ValueNotifier<int> revision = ValueNotifier(0);
  static final Map<String, String?> _photos = {};
  static final Set<String> _loading = {};

  static final Map<String, String?> _names = {};
  static String? _viewerScope;
  static int _blockRevision = -1;
  static int _followRevision = -1;
  static int _generation = 0;

  static void _syncScope() {
    final session = PublicProfileService.viewerSession;
    if (_viewerScope == session && _blockRevision == blockedListRevision.value
        && _followRevision == followRevision.value) return;
    _viewerScope = session;
    _blockRevision = blockedListRevision.value;
    _followRevision = followRevision.value;
    _generation++;
    _photos.clear();
    _names.clear();
    _loading.clear();
  }

  static String? nameOf(String? uid) {
    _syncScope();
    if (uid == null || uid.isEmpty) return null;
    return _names[uid];
  }

  static void putName(String uid, String name) {
    _syncScope();
    _names[uid] = name;
    revision.value++;
  }

  static String? photoOf(String? uid) {
    _syncScope();
    if (uid == null || uid.isEmpty) return null;
    return _photos[uid];
  }

  static void put(String uid, String? photoUrl) {
    _syncScope();
    _photos[uid] = photoUrl;
    revision.value++;
  }

  static Future<void> ensure(String uid) async {
    _syncScope();
    if (_viewerScope == null || uid.isEmpty || _loading.contains(uid)) return;
    if (_photos.containsKey(uid) && _names.containsKey(uid)) return;
    _loading.add(uid);
    final generation = _generation;
    try {
      final data = await PublicProfileService.load(uid);
      _syncScope();
      if (_generation != generation) return;
      _photos[uid] = data['profileImageUrl']?.toString();
      final fn = (data['firstName'] ?? '').toString().trim();
      final ln = (data['lastName'] ?? '').toString().trim();
      final display = (data['displayName'] ?? '').toString().trim();
      final fromNames = [fn, ln].where((e) => e.isNotEmpty).join(' ');
      _names[uid] = fromNames.isNotEmpty
          ? fromNames
          : (display.isNotEmpty ? display : _names[uid]);
      revision.value++;
    } catch (e) {
      _syncScope();
      if (_generation == generation) {
        _photos.remove(uid);
        _names.remove(uid);
      }
      debugPrint('AuthorProfiles.ensure failed: $e');
    } finally {
      if (_generation == generation) _loading.remove(uid);
    }
  }
}

class LiveAuthorPhoto extends StatefulWidget {
  const LiveAuthorPhoto({
    super.key,
    required this.userId,
    this.fallbackUrl,
    this.size = 40,
    this.radius,
    this.iconSize = 22,
  });

  final String? userId;
  final String? fallbackUrl;
  final double size;
  final double? radius;
  final double iconSize;

  @override
  State<LiveAuthorPhoto> createState() => _LiveAuthorPhotoState();
}

class _LiveAuthorPhotoState extends State<LiveAuthorPhoto> {
  void _load() {
    final id = widget.userId?.trim() ?? '';
    if (id.isNotEmpty) AuthorProfiles.ensure(id);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant LiveAuthorPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) _load();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AuthorProfiles.revision,
      builder: (context, _, __) {
        final live = AuthorProfiles.photoOf(widget.userId)?.trim() ?? '';
        final fallback = widget.fallbackUrl?.trim() ?? '';
        final url = live.startsWith('http')
            ? live
            : fallback.startsWith('http')
            ? fallback
            : '';
        final r = widget.radius ?? widget.size / 2;
        return Container(
          width: widget.size,
          height: widget.size,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r),
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
          ),
          child: url.isNotEmpty
              ? CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            memCacheWidth: 160,
            errorWidget: (_, __, ___) => Icon(
              Icons.person_rounded,
              size: widget.iconSize,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.75),
            ),
            placeholder: (_, __) => const SizedBox.shrink(),
          )
              : Icon(
            Icons.person_rounded,
            size: widget.iconSize,
            color: Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.75),
          ),
        );
      },
    );
  }
}

class _ProfileMediaItem {
  const _ProfileMediaItem({
    required this.post,
    required this.path,
    required this.isVideo,
  });

  final _Post post;
  final String path;
  final bool isVideo;
}

class _ProfileMediaPane extends StatelessWidget {
  const _ProfileMediaPane({
    required this.items,
    required this.t,
  });

  final List<_ProfileMediaItem> items;
  final _ProfileTheme t;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _ProfileEmptyPane(
        icon: Icons.photo_library_outlined,
        label: mainText(context, "لا توجد وسائط"),
        t: t,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final isNet =
            item.path.startsWith('http://') || item.path.startsWith('https://');

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CommentsScreen(post: item.post),
              ),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (!item.isVideo)
                isNet
                    ? Image.network(
                  item.path,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => ColoredBox(
                    color: t.cardBorder,
                    child: Icon(Icons.broken_image_outlined,
                        color: t.textFaint),
                  ),
                )
                    : Image.file(
                  File(item.path),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => ColoredBox(
                    color: t.cardBorder,
                    child: Icon(Icons.broken_image_outlined,
                        color: t.textFaint),
                  ),
                )
              else
                ColoredBox(
                  color: Colors.black87,
                  child: Icon(
                    Icons.play_circle_outline,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 36,
                  ),
                ),
              if (item.isVideo)
                const Positioned(
                  right: 6,
                  bottom: 6,
                  child: Icon(Icons.videocam, color: Colors.white, size: 16),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AuthorizedProfilePostsBuilder extends StatefulWidget {
  const _AuthorizedProfilePostsBuilder(
      {required this.userId, required this.builder, this.enabled = true});
  final String? userId;
  final bool enabled;
  final Widget Function(BuildContext, List<_Post>, bool, VoidCallback) builder;
  @override
  State<_AuthorizedProfilePostsBuilder> createState() => _AuthorizedProfilePostsBuilderState();
}

class _AuthorizedProfilePostsBuilderState extends State<_AuthorizedProfilePostsBuilder> {
  final List<_Post> _posts = [];
  Map<String, dynamic>? _cursor;
  bool _loading = false, _more = true;
  String? _error, _viewer;
  int _generation = 0;
  StreamSubscription<User?>? _auth;
  @override
  void initState() {
    super.initState();
    _viewer = FirebaseAuth.instance.currentUser?.uid;
    _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted || user?.uid == _viewer) return;
      _viewer = user?.uid; _refresh();
    });
    blockedListRevision.addListener(_refresh);
    authorProfileRevision.addListener(_refresh);
    followRevision.addListener(_refresh);
    _refresh();
  }
  @override
  void didUpdateWidget(covariant _AuthorizedProfilePostsBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId || oldWidget.enabled != widget.enabled) _refresh();
  }
  void _refresh() { if (mounted) _load(reset: true); }
  Future<void> _load({bool reset = false}) async {
    if (!mounted || (!reset && (_loading || !_more))) return;
    final generation = reset ? ++_generation : _generation;
    final viewer = FirebaseAuth.instance.currentUser?.uid;
    final target = widget.userId;
    bool current() => mounted && generation == _generation &&
        viewer == FirebaseAuth.instance.currentUser?.uid && target == widget.userId;
    setState(() {
      _error = null;
      if (reset) { _posts.clear(); _cursor = null; _more = true; }
      _loading = widget.enabled && target != null;
    });
    if (!_loading) return;
    try {
      final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('readProfilePosts', options: HttpsCallableOptions(timeout: const Duration(seconds: 120)))
          .call<Map<String, dynamic>>({'userId': target, 'cursor': _cursor});
      if (!current()) return;
      final page = result.data;
      if (page['posts'] is! List || page['exhausted'] is! bool ||
          (page['cursor'] != null && page['cursor'] is! Map) ||
          (page['exhausted'] == false && page['cursor'] == null)) throw StateError('Invalid profile page');
      final incoming = (page['posts'] as List).map((row) {
        if (row is! Map || row['id'] is! String || row['data'] is! Map) throw StateError('Invalid post');
        final post = _Post.fromData(row['id'] as String, Map<String, dynamic>.from(row['data'] as Map));
        if (post.authorId != target) throw StateError('Unexpected post author');
        return post;
      }).toList();
      final ids = _posts.map((p) => p.id).toSet();
      setState(() {
        _posts.addAll(incoming.where((p) => !ids.contains(p.id)));
        _posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _cursor = page['cursor'] == null ? null : Map<String, dynamic>.from(page['cursor'] as Map);
        _more = page['exhausted'] == false; _loading = false;
      });
    } catch (_) {
      if (!current()) return;
      setState(() { _loading = false; _posts.clear(); _error = mainText(context, "تعذر تحميل منشورات الملف"); });
    }
  }
  @override
  void dispose() {
    _generation++; _auth?.cancel();
    blockedListRevision.removeListener(_refresh);
    authorProfileRevision.removeListener(_refresh);
    followRevision.removeListener(_refresh);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => Column(children: [
    Expanded(child: widget.builder(context, List<_Post>.from(_posts), _loading && _posts.isEmpty, _refresh)),
    if (widget.enabled) SafeArea(top: false, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (_error != null) Flexible(child: Text(_error!)),
      TextButton(onPressed: _loading ? null : _refresh, child: Text(_error == null ? mainText(context, "تحديث") : mainText(context, "إعادة المحاولة"))),
      if (_more && _error == null && widget.userId != null)
        TextButton(onPressed: _loading ? null : () => _load(), child: Text(_loading ? mainText(context, "جارٍ التحميل...") : mainText(context, "تحميل المزيد"))),
    ])),
  ]);
}

class _AuthorizedReactionPosts extends StatefulWidget {
  const _AuthorizedReactionPosts(
      {super.key, required this.disliked, required this.t});
  final bool disliked;
  final _ProfileTheme t;
  @override
  State<_AuthorizedReactionPosts> createState() => _AuthorizedReactionPostsState();
}

class _AuthorizedReactionPostsState extends State<_AuthorizedReactionPosts> {
  final List<_Post> _posts = [];
  Map<String, dynamic>? _cursor;
  bool _loading = true, _more = true;
  String? _error, _uid;
  int _generation = 0;
  StreamSubscription<User?>? _auth;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted || _uid == user?.uid) return;
      _uid = user?.uid;
      _refresh();
    });
    blockedListRevision.addListener(_refresh);
    authorProfileRevision.addListener(_refresh);
    followRevision.addListener(_refresh);
    _refresh();
  }

  void _refresh() { if (mounted) _load(reset: true); }

  Future<void> _load({bool reset = false}) async {
    if (!mounted || (!reset && (_loading || !_more))) return;
    final generation = reset ? ++_generation : _generation;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    bool current() => mounted && generation == _generation &&
        uid == FirebaseAuth.instance.currentUser?.uid;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) { _posts.clear(); _cursor = null; _more = true; }
    });
    try {
      if (uid == null) throw StateError('Sign in first');
      final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('readOwnReactionPosts', options: HttpsCallableOptions(
            timeout: const Duration(seconds: 120),
                  ))
              .call<Map<String, dynamic>>({
            'reaction': widget.disliked ? 'dislike' : 'like', 'cursor': _cursor,
          });
      if (!current()) return;
      final page = response.data;
      if (page['posts'] is! List || page['exhausted'] is! bool ||
          (page['cursor'] != null && page['cursor'] is! Map) ||
          (page['exhausted'] == false && page['cursor'] == null)) {
        throw StateError('Invalid reaction page');
      }
      final incoming = (page['posts'] as List).map((row) {
        if (row is! Map || row['id'] is! String || row['data'] is! Map) {
          throw StateError('Invalid reaction post');
        }
        return _Post.fromData(row['id'] as String, Map<String, dynamic>.from(row['data'] as Map));
      }).toList();
      final existing = _posts.map((p) => p.id).toSet();
      setState(() {
        _posts.addAll(incoming.where((p) => !existing.contains(p.id)));
        _posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _cursor = page['cursor'] == null ? null : Map<String, dynamic>.from(page['cursor'] as Map);
        _more = page['exhausted'] == false;
        _loading = false;
      });
    } catch (_) {
      if (!current()) return;
      setState(() { _loading = false; _posts.clear(); _error = mainText(context, "تعذر تحميل التفاعلات"); });
    }
  }

  @override
  void dispose() {
    _generation++;
    _auth?.cancel();
    blockedListRevision.removeListener(_refresh);
    authorProfileRevision.removeListener(_refresh);
    followRevision.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Center(child: Column(
      mainAxisSize: MainAxisSize.min, children: [Text(_error!),
        TextButton(onPressed: _refresh, child:  Text(mainText(context, "إعادة المحاولة")))
        ],
      ));
    if (_loading && _posts.isEmpty) return const _ProfileTabLoading();
    return Column(children: [
      Align(alignment: AlignmentDirectional.centerEnd, child: TextButton.icon(
        onPressed: _loading ? null : _refresh,
        icon: const Icon(Icons.refresh), label:  Text(mainText(context, "تحديث")),
      )),
      Expanded(child: _ProfilePostsPane(
        posts: _posts, t: widget.t,
        emptyLabel: widget.disliked ? mainText(context, "لا توجد منشورات غير معجب بها") : mainText(context, "لا توجد إعجابات"),
        emptyIcon: widget.disliked ? Icons.heart_broken_rounded : Icons.favorite_border_rounded,
        onChanged: _refresh,
      )),
      if (_more) TextButton(
        onPressed: _loading ? null : () => _load(),
        child: Text(_loading ? mainText(context, "جارٍ التحميل...") : mainText(context, "تحميل المزيد")),
      ),
    ]);
  }
}

class _ProfilePostsPane extends StatelessWidget {
  const _ProfilePostsPane({
    required this.posts,
    required this.emptyLabel,
    required this.emptyIcon,
    required this.t,
    required this.onChanged,
    this.pinnedPost,
    this.actionLabel,
    this.onAction,
    this.onSetPinned,
    this.currentPinnedId,
  });

  final List<_Post> posts;
  final String emptyLabel;
  final IconData emptyIcon;
  final _ProfileTheme t;
  final VoidCallback onChanged;
  final _Post? pinnedPost;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Future<void> Function(String? postId)? onSetPinned;
  final String? currentPinnedId;

  @override
  Widget build(BuildContext context) {
    final feed = pinnedPost == null
        ? posts
        : posts.where((p) => p.id != pinnedPost!.id).toList();

    if (feed.isEmpty && pinnedPost == null) {
      return _ProfileEmptyPane(
        icon: emptyIcon,
        label: emptyLabel,
        t: t,
        actionLabel: actionLabel,
        onAction: onAction,
      );
    }

    final extra = pinnedPost != null ? 2 : 0; // عنوان + بطاقة

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 80),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                if (pinnedPost != null) {
                  if (index == 0) {
                    return _PostCard(
                      post: pinnedPost!,
                      showAuthorHeader: false,
                      compact: true,
                      onChanged: onChanged,
                      onDelete: () async {},
                      onHidden: onChanged,
                      allowPin: onSetPinned != null,
                      isPinned: true,
                      onSetPinned: onSetPinned,
                    );
                  }
                  final post = feed[index - 1];
                  return _PostCard(
                    post: post,
                    showAuthorHeader: false,
                    compact: true,
                    onChanged: onChanged,
                    onDelete: () async {},
                    onHidden: onChanged,
                    allowPin: onSetPinned != null,
                    isPinned: false,
                    onSetPinned: onSetPinned,
                  );
                }

                final post = feed[index];
                return _PostCard(
                  post: post,
                  showAuthorHeader: false,
                  compact: true,
                  onChanged: onChanged,
                  onDelete: () async {},
                  onHidden: onChanged,
                  allowPin: onSetPinned != null,
                  isPinned: currentPinnedId != null &&
                      currentPinnedId == post.id,
                  onSetPinned: onSetPinned,
                );
              },
              childCount: feed.length + (pinnedPost != null ? 1 : 0),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileEmptyPane extends StatelessWidget {
  const _ProfileEmptyPane({
    required this.icon,
    required this.label,
    required this.t,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String label;
  final _ProfileTheme t;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: t.textFaint),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: t.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: onAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTeal.main,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      actionLabel!,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
// =========================== Sub-Profil ==========================
// =========================== بروفايل زائر ==========================
// ============================================================


class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({
    super.key,
    required this.userId,
    this.initialName,
    this.initialPhotoUrl,
  });

  final String userId;
  final String? initialName;
  final String? initialPhotoUrl;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<_ProfileCommentHit> _userComments = [];
  bool _loadingComments=true;
  String? _commentsError;
  int _commentsGeneration = 0;
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<Map<String, dynamic>>? _presenceSub;
  Set<String> _hiddenPostIds = {};

  bool _isOnline = false;
  DateTime? _lastSeenAt;
  bool _showOnlineStatus = true;
  bool _showLastSeen = true;
  bool _loadingProfile = true;
  bool _profileFailed = false;
  bool _serverCanViewContent = false;
  String _displayName = '';
  String _username = '';
  String? _photoUrl;
  String? _coverUrl;
  String _mood = '';
  String _uni = '';
  String _fac = '';
  String _major = '';
  String _studyLevel = '';
  String _github = '';
  String _linkedin = '';
  String _portfolio = '';
  String _otherInfo = '';
  String _work = '';
  String _residence = '';
  int _followersCount = 0;
  int _followingCount = 0;
  int _postsCount = 0;
  bool _isFollowing = false;
  bool _followBusy = false;
  double _appBarOpacity = 0;
  bool _targetIsPrivate = false;
  bool _requestPending = false;

  bool _showAcademicInfo = true;
  bool _showSocialLinks = true;
  String _email = '';
  bool _showEmailOnProfile = false;
  String _followersVisibility = 'everyone';
  String _followingVisibility = 'everyone';

  static const double _coverHeight = 140;
  static const double _avatarSize = 72;
  bool _unavailable = false;
  bool _checkingAccess = true;
  bool _iBlockThem = false;
  bool _theyBlockMe = false;
  bool _blockStateReady = false;
  bool get _isSelf {
    final me = FirebaseAuth.instance.currentUser?.uid;
    return me != null && me == widget.userId;
  }

  @override
  void initState() {
    super.initState();
    _displayName = (widget.initialName ?? '').trim();
    _photoUrl = widget.initialPhotoUrl;
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
    _loadProfile();
    _listenPresence();
    _loadBlockState();
    _loadHiddenPosts();
    _checkAccess();
    _checkFollowing();
    _loadCounts();
    _loadBlockState();
    blockedListRevision.addListener(_loadBlockState);
    hiddenListRevision.addListener(_loadHiddenPosts);

  }
  Future<void> _blockFromProfile() async {
    if (_isSelf) return;
    try {
      await blockAccount(
        targetId: widget.userId,
        targetName: _displayName,
        targetPhotoUrl: _photoUrl,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('block from profile failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(mainText(context, "تعذر حظر الحساب"))),
      );
    }
  }
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.dispose();
    _presenceSub?.cancel();
    hiddenListRevision.removeListener(_loadHiddenPosts);
    blockedListRevision.removeListener(_loadBlockState);
    super.dispose();
  }

  void _listenPresence() {
    _presenceSub?.cancel();
    final session = PublicProfileService.viewerSession;
    final Stream<Map<String, dynamic>> stream = _isSelf
        ? FirebaseFirestore.instance.collection('users')
            .doc(widget.userId)
            .snapshots()
            .map((doc) => doc.data() ?? <String, dynamic>{})
        : PublicProfileService.watch(widget.userId);
    _presenceSub = stream.listen((data) {
      if (!mounted || PublicProfileService.viewerSession != session) return;
      final priv = data['privacy'];
      final pmap = priv is Map ? Map<String, dynamic>.from(priv) : null;
      final ts = data['lastSeenAt'];
      setState(() {
        _serverCanViewContent = data['canViewContent'] == true;
        if (!_isSelf) {
          _mood = (data['mood'] ?? '').toString();
          _followersVisibility = (pmap?['followersVisibility'] ?? 'none').toString();
          _followingVisibility = (pmap?['followingVisibility'] ?? 'none').toString();
          _followersCount = (data['followersCount'] as num?)?.toInt() ?? 0;
          _followingCount = (data['followingCount'] as num?)?.toInt() ?? 0;
          _showAcademicInfo = pmap?['showAcademicInfo'] == true;
          _showSocialLinks = pmap?['showSocialLinks'] == true;
          _uni = (data['university'] ?? '').toString();
          _fac = (data['faculty'] ?? '').toString();
          _major = (data['major'] ?? '').toString();
          _studyLevel = (data['studyLevel'] ?? '').toString();
          _github = (data['github'] ?? '').toString();
          _linkedin = (data['linkedin'] ?? '').toString();
          _portfolio = (data['portfolio'] ?? '').toString();
          _otherInfo = (data['otherInfo'] ?? '').toString();
          _work = (data['work'] ?? '').toString();
          _residence = (data['residence'] ?? '').toString();
          _coverUrl = data['coverImageUrl']?.toString();
          if (!_serverCanViewContent) _userComments = [];
        }
        final privacy = ProfilePrivacy.fromDocument(data);
        _targetIsPrivate = privacy.isPrivate;
        _showEmailOnProfile = privacy.showEmail;
        _email = privacy.showEmail || _isSelf ? (data['email'] ?? '').toString().trim() : '';
        _isOnline = data['isOnline'] == true;
        _lastSeenAt = ts is Timestamp ? ts.toDate() : null;
        if (!_isSelf) {
          _unavailable = isUserDocUnavailable(data);
        }
        _showOnlineStatus = pmap?['showOnline'] != false;
        _showLastSeen = pmap?['showLastSeen'] == true;
      });
    }, onError: (Object error) {
      if (!mounted || PublicProfileService.viewerSession != session) return;
      setState(() { _profileFailed = true; _serverCanViewContent = false; _email = ''; });
    });
  }

  String? get _presenceText {
    final allowOnline = _isSelf || _showOnlineStatus;
    final allowSeen = _isSelf || _showLastSeen;
    if (allowOnline && _isOnline) return mainText(context, "متصل");
    if (allowSeen && _lastSeenAt != null) {
      final d = DateTime.now().difference(_lastSeenAt!);
      if (d.inMinutes < 1) return mainText(context, "آخر ظهور الآن");
      if (d.inMinutes < 60) return mainText(context, "آخر ظهور منذ {0}د", <Object?>[d.inMinutes]);
      if (d.inHours < 24) return mainText(context, "آخر ظهور منذ {0}س", <Object?>[d.inHours]);
      if (d.inDays == 1) return mainText(context, "آخر ظهور أمس");
      return mainText(context, "آخر ظهور منذ {0}ي", <Object?>[d.inDays]);
    }
    return null;
  }

  Future<void> _checkAccess() async {
    if (_isSelf) {
      if (mounted) setState(() => _checkingAccess = false);
      return;
    }
    try {
      final hidden = await isBlockedByAccount(widget.userId) ||
          await isAccountBlocked(widget.userId);
      if (!mounted) return;
      setState(() {
        _unavailable = hidden;
        _checkingAccess = false;
      });
    } catch (e) {
      debugPrint('profile access check failed: $e');
      if (mounted) setState(() => _checkingAccess = false);
    }
  }
  Future<void> _loadBlockState() async {
    if (_isSelf) {
      if (!mounted) return;
      setState(() {
        _iBlockThem = false;
        _theyBlockMe = false;
        _blockStateReady = true;
        _checkingAccess = false;
      });
      return;
    }

    final iBlock = await isAccountBlocked(widget.userId);
    final theyBlock = await isBlockedByAccount(widget.userId);

    if (!mounted) return;
    setState(() {
      _iBlockThem = iBlock;
      _theyBlockMe = theyBlock;
      _blockStateReady = true;
      _checkingAccess = false;
    });
  }
  Future<void> _loadHiddenPosts() async {
    if (_isSelf) return;
    final ids = await loadHiddenPostIds();
    if (!mounted) return;
    setState(() => _hiddenPostIds = ids);
  }
  Future<void> _confirmBlock() async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(mainText(context, "يجب تسجيل الدخول أولاً"))),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: Directionality.of(context),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title:  Text(mainText(ctx, "حظر الحساب؟")),
          content: Text(
            mainText(ctx, "لن تظهر منشورات {0} في فيدك بعد الآن. يمكنك إلغاء الحظر لاحقًا من الإعدادات.", <Object?>[_displayName]),
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
    if (confirmed != true) return;

    try {
      await blockAccount(
        targetId: widget.userId,
        targetName: _displayName,
        targetPhotoUrl: _photoUrl,
      );
    } catch (e) {
      debugPrint('blockAccount failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mainText(context, "تعذر الحظر: {0}", <Object?>[e]))),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _iBlockThem = true;
      _isFollowing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mainText(context, "تم حظر {0}", <Object?>[_displayName]))),
    );
  }

  Future<void> _unblock() async {
    await unblockAccount(widget.userId);
    if (!mounted) return;
    setState(() => _iBlockThem = false);
    _loadProfile();
    _listenPresence();
    ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text(mainText(context, "تم إلغاء الحظر"))),
    );
  }

  Future<void> _reportAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(mainText(context, "يجب تسجيل الدخول أولاً"))),
      );
      return;
    }

    final targetId = widget.userId.trim();
    if (targetId.isEmpty) return;
    if (targetId == user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(mainText(context, "لا يمكنك تبليغ محتواك"))),
      );
      return;
    }

    bool already;
    try {
      already = await hasCommunityReport(
        type: CommunityReportType.user,
        targetId: targetId,
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
        type: CommunityReportType.user,
        ownerId: targetId,
        ownerName: _displayName,
        ownerPhotoUrl: _photoUrl,
        alreadyReported: true,
        onBlocked: () {
          if (!mounted) return;
          setState(() {
            _iBlockThem = true;
            _isFollowing = false;
          });
        },
        onUnfollowed: () {
          if (!mounted) return;
          setState(() => _isFollowing = false);
        },
      );
      return;
    }

    final result = await showCommunityReportSheet(
      context,
      type: CommunityReportType.user,
    );
    if (result == null || !mounted) return;

    try {
      await runWithReportSpinner(context, () => submitCommunityReport(
        type: CommunityReportType.user,
        targetId: targetId,
        ownerId: targetId,
        ownerName: _displayName,
        reason: result.reasonId,
        details: result.details,
        snapshot: {
          'displayName': _displayName,
          'username': _username,
          'photoUrl': _photoUrl,
          'mood': _mood,
        },
      ));
      if (!mounted) return;
      await showReportSubmittedSheet(
        context,
        type: CommunityReportType.user,
        ownerId: targetId,
        ownerName: _displayName,
        ownerPhotoUrl: _photoUrl,
        onBlocked: () {
          if (!mounted) return;
          setState(() {
            _iBlockThem = true;
            _isFollowing = false;
          });
        },
        onUnfollowed: () {
          if (!mounted) return;
          setState(() => _isFollowing = false);
        },
      );
    } catch (e) {
      debugPrint('account report failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messageForCommunityReportError(e))),
      );
    }
  }

  void _onScroll() {
    final topInset = MediaQuery.paddingOf(context).top;
    final coverH = _coverHeight + topInset;
    final opacity =
    (_scrollController.offset / (coverH - kToolbarHeight)).clamp(0.0, 1.0);
    if ((opacity - _appBarOpacity).abs() > 0.01) {
      setState(() => _appBarOpacity = opacity);
    }
  }

  void _openProfileSearch(_ProfileTheme t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileSearchSheet(
        t: t,
        authorId: widget.userId ,
        authorName: _displayName ,
      ),
    );
  }
  Future<void> _loadUserComments() async {
    if (!mounted) return;
    final generation = ++_commentsGeneration;
    final viewer = FirebaseAuth.instance.currentUser?.uid;
    final target = widget.userId;
    bool current() => mounted && generation == _commentsGeneration &&
        viewer == FirebaseAuth.instance.currentUser?.uid;
    setState(() { _loadingComments = true; _commentsError = null; _userComments = []; });
    try {
      if (viewer == null || target == null) throw StateError('Sign in first');
      final hits = await loadCommentsByAuthor(target);
      if (!current()) return;
      setState(() { _userComments = hits; _loadingComments = false; });
    } catch (_) {
      if (!current()) return;
      setState(() { _loadingComments = false; _userComments = []; _commentsError = mainText(context, "تعذر تحميل التعليقات"); });
    }
  }

  Future<void> _loadProfile() async {
    final session = PublicProfileService.viewerSession;
    setState(() { _loadingProfile = true; _profileFailed = false; });
    try {
      final Map<String, dynamic> data;
      if (_isSelf) {
        final doc = await FirebaseFirestore.instance.collection('users')
            .doc(widget.userId)
            .get(const GetOptions(source: Source.server));
        if (!doc.exists) throw StateError('Profile unavailable');
        data = doc.data()!;
      } else {
        data = await PublicProfileService.load(widget.userId);
      }
      if (!mounted || PublicProfileService.viewerSession != session) return;
      final fn = (data['firstName'] ?? '').toString().trim();
      final ln = (data['lastName'] ?? '').toString().trim();
      final fromNames = [fn, ln].where((e) => e.isNotEmpty).join(' ');
      final display =
      (data['displayName'] ?? data['username'] ?? '').toString().trim();
      final uname = (data['username'] ?? '').toString().trim();
      final priv = data['privacy'];
      final pmap = priv is Map ? Map<String, dynamic>.from(priv) : null;
      _targetIsPrivate = ProfilePrivacy.fromDocument(data).isPrivate;
      _showAcademicInfo = pmap?['showAcademicInfo'] != false;
      _showSocialLinks = pmap?['showSocialLinks'] != false;
      _followersVisibility =
          (pmap?['followersVisibility'] ?? 'everyone').toString();
      _followingVisibility =
          (pmap?['followingVisibility'] ?? 'everyone').toString();

      if (!widget.userId.isEmpty &&
          !_isSelf &&
          isUserDocUnavailable(data)) {
        if (!mounted) return;
        setState(() {
          _unavailable = true;
          _loadingProfile = false;
          _checkingAccess = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _serverCanViewContent = data['canViewContent'] == true;
        _targetIsPrivate = ProfilePrivacy.fromDocument(data).isPrivate;
        _displayName = fromNames.isNotEmpty
            ? fromNames
            : (display.isNotEmpty
            ? display
            : (_displayName.isNotEmpty ? _displayName : mainText(context, "طالب UniSpace")));
        _username = uname.isNotEmpty
            ? uname
            : _displayName.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
        _photoUrl =
        (data['profileImageUrl']?.toString().trim().isNotEmpty == true)
            ? data['profileImageUrl'].toString()
            : _photoUrl;
        _coverUrl = data['coverImageUrl']?.toString();
        _mood = (data['mood'] ?? '').toString();
        _uni = (data['university'] ?? '').toString();
        _fac = (data['faculty'] ?? '').toString();
        _major = (data['major'] ?? '').toString();
        _studyLevel = (data['studyLevel'] ?? '').toString();
        _github = (data['github'] ?? '').toString().trim();
        _linkedin = (data['linkedin'] ?? '').toString().trim();
        _portfolio = (data['portfolio'] ?? '').toString().trim();
        _otherInfo = (data['otherInfo'] ?? '').toString().trim();
        _work = (data['work'] ?? '').toString().trim();
        _residence = (data['residence'] ?? '').toString().trim();
        _followersCount =
            (data['followersCount'] as num?)?.toInt() ?? 0;
        _followingCount =
            (data['followingCount'] as num?)?.toInt() ?? 0;
        _loadingProfile = false;
        _email = (data['email'] ?? '').toString().trim();
        _showEmailOnProfile = ProfilePrivacy.fromDocument(data).showEmail;
      });
      if (_canSeePrivateContent) unawaited(_loadUserComments());
      if (_photoUrl != null && _photoUrl!.isNotEmpty) {
        AuthorProfiles.put(widget.userId, _photoUrl);
      }
    } catch (e) {
      debugPrint('UserProfile load failed: $e');
      if (!mounted || PublicProfileService.viewerSession != session) return;
      setState(() {
        _loadingProfile = false;
        _profileFailed = true;
        _targetIsPrivate = true;
        _showEmailOnProfile = false;
        _email = '';
        if (_displayName.isEmpty) _displayName = mainText(context, "طالب UniSpace");
      });
    }
  }

  int _countsGeneration = 0;
  Future<void> _loadCounts() async {
    if (!_isSelf) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid != widget.userId) return;
    final generation = ++_countsGeneration;
    try {
      final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('readOwnProfileCounts')
              .call(<String, dynamic>{});
      if (!mounted || generation != _countsGeneration ||
          FirebaseAuth.instance.currentUser?.uid != uid || widget.userId != uid) return;
      final data = Map<String, dynamic>.from(response.data as Map);
      int count(String key) {
        final value = data[key];
        if (value is! num || !value.isFinite || value < 0 || value != value.roundToDouble()) {
          throw StateError('Invalid profile count');
        }
        return value.toInt();
      }
      final followers = count('followers'), following = count('following'), posts = count('posts');
      setState(() {
        _followersCount = followers;
        _followingCount = following;
        _postsCount = posts;
      });
    } catch (e) {
      debugPrint('load counts failed: '+ e.runtimeType.toString());
    }
  }

  bool get _canSeePrivateContent =>
      _isSelf || _serverCanViewContent;

  Future<void> _checkFollowing() async {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null || _isSelf) return;
    try {
      final following = await FirebaseFirestore.instance
          .collection('users')
          .doc(me)
          .collection('following')
          .doc(widget.userId)
          .get();
      final requested =
      await _followRequestRef(widget.userId, me).get();
      if (!mounted) return;
      setState(() {
        _isFollowing = following.exists;
        _requestPending = !_isFollowing && requested.exists;
      });
    } catch (_) {}
  }

  Future<void> _toggleFollow() async {
    final me = FirebaseAuth.instance.currentUser;
    final myUid = me?.uid;
    if (myUid == null || _isSelf || _followBusy) return;

    setState(() => _followBusy = true);
    HapticFeedback.lightImpact();

    try {
      String myName = (me?.displayName ?? '').trim();
      String? myPhoto = me?.photoURL;
      try {
        final myDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(myUid)
            .get();
        final d = myDoc.data();
        final fn = (d?['firstName'] ?? '').toString().trim();
        final ln = (d?['lastName'] ?? '').toString().trim();
        final fromNames = [fn, ln].where((e) => e.isNotEmpty).join(' ');
        if (fromNames.isNotEmpty) myName = fromNames;
        final p = d?['profileImageUrl']?.toString();
        if (p != null && p.isNotEmpty) myPhoto = p;
      } catch (_) {}
      if (myName.isEmpty) myName = mainText(context, "طالب UniSpace");

      if (_isFollowing) {
        await setFollowing(
          me: myUid,
          targetId: widget.userId,
          targetName: _displayName,
          targetPhotoUrl: _photoUrl,
          myName: myName,
          myPhotoUrl: myPhoto,
          follow: false,
        );
      } else if (_requestPending) {
        await cancelFollowRequest(widget.userId);
      } else {
        await setFollowing(
          me: myUid,
          targetId: widget.userId,
          targetName: _displayName,
          targetPhotoUrl: _photoUrl,
          myName: myName,
          myPhotoUrl: myPhoto,
          follow: true,
        );
      }
      await _checkFollowing();
      await _loadProfile();
      await _loadCounts();
    } catch (e) {
      debugPrint('toggle follow failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(mainText(context, "تعذر تحديث المتابعة"))),
        );
      }
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  Widget _followButton(_ProfileTheme t, bool isDark) {
    final requested = _requestPending && !_isFollowing;
    final filled = !_isFollowing && !requested;
    final label = _isFollowing
        ? mainText(context, "Following")
        : (requested ? 'Requested' : 'Follow');

    return Material(
      color: filled
          ? (isDark ? Colors.white : Colors.black)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: _followBusy ? null : _toggleFollow,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: filled ? null : Border.all(color: t.cardBorder, width: 1.2),
          ),
          child: _followBusy
              ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: filled
                  ? (isDark ? Colors.black : Colors.white)
                  : t.textPrimary,
            ),
          )
              : Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: filled
                  ? (isDark ? Colors.black : Colors.white)
                  : t.textPrimary,
            ),
          ),
        ),
      ),
    );
  }



  Future<void> _openLink(String url) async {
    var u = url.trim();
    if (u.isEmpty) return;
    if (!u.startsWith('http')) u = 'https://$u';
    final uri = Uri.tryParse(u);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _formatCount(int n) {
    if (n >= 1000000) {
      final v = n / 1000000;
      return v >= 10 ? '${v.toStringAsFixed(0)}M' : '${v.toStringAsFixed(1)}M';
    }
    if (n >= 1000) {
      final v = n / 1000;
      return v >= 10 ? '${v.toStringAsFixed(0)}K' : '${v.toStringAsFixed(1)}K';
    }
    return '$n';
  }

  @override

  Widget _blockedProfileScaffold({
    required _ProfileTheme t,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Scaffold(
      backgroundColor: t.pageBg,
      appBar: AppBar(
        backgroundColor: t.pageBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: t.textPrimary),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PublicProfilePhoto(
                userId: widget.userId,
                fallbackUrl: _photoUrl,
                size: 72,
                radius: 36,
                iconSize: 32,
              ),
              const SizedBox(height: 16),
              Text(
                _displayName,
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              Icon(Icons.block_rounded, size: 40, color: t.textFaint),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: t.textMuted,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              if (action != null) ...[
                const SizedBox(height: 24),
                action,
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _ProfileTheme.of(context);
    final iconColor =
    Color.lerp(Colors.white, t.textPrimary, _appBarOpacity)!;
    final btnBg = Color.lerp(
      Colors.black.withValues(alpha: 0.35),
      Colors.transparent,
      _appBarOpacity,
    )!;

    if (_loadingProfile || _checkingAccess || (!_isSelf && !_blockStateReady)) {
      return Scaffold(
        backgroundColor: t.pageBg,
        appBar: AppBar(
          backgroundColor: t.pageBg,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.textPrimary),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (!_isSelf && _theyBlockMe) {
      return _blockedProfileScaffold(
        t: t,
        title: mainText(context, "لقد حظرك هذا الحساب"),
        subtitle: mainText(context, "لن تتمكن من مشاهدة منشوراته أو التفاعل معه."),
        action: TextButton(
          onPressed: _reportAccount,
          child:  Text(
            mainText(context, "تبليغ"),
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      );
    }

    if (!_isSelf && _iBlockThem) {
      return _blockedProfileScaffold(
        t: t,
        title: mainText(context, "لقد حظرت هذا الحساب"),
        subtitle: mainText(context, "لن تظهر منشوراته في فيدك. يمكنك إلغاء الحظر في أي وقت."),
        action: OutlinedButton(
          onPressed: _unblock,
          style: OutlinedButton.styleFrom(
            foregroundColor: t.textPrimary,
            side: BorderSide(color: t.cardBorder),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child:  Text(
            mainText(context, "إلغاء الحظر"),
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      );
    }
    if (_profileFailed) {
      return Scaffold(appBar: AppBar(title:  Text(mainText(context, "الملف الشخصي"))),
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
           Text(mainText(context, "تعذر التحقق من خصوصية الملف. حاول مجددًا.")),
          TextButton(onPressed: () { _loadProfile(); _listenPresence(); }, child:  Text(mainText(context, "إعادة المحاولة"))),
        ])));
    }
    if (!_isSelf && _unavailable) {
      return _blockedProfileScaffold(
        t: t,
        title: mainText(context, "هذا الحساب غير متاح"),
        subtitle: mainText(context, "تم تعطيل هذا الحساب أو لم يعد موجودًا."),
      );
    }
    return Scaffold(
      backgroundColor: t.pageBg,
      body: Stack(
        children: [
          _AuthorizedProfilePostsBuilder(
            userId: widget.userId,
            enabled: _canSeePrivateContent,
            builder: (context, authorized, waiting, refreshPosts) {
              final t = _ProfileTheme.of(context);
              final all = authorized.where((p) => _isSelf || !_hiddenPostIds.contains(p.id))
                  .toList();
              final originals = all.where((p) => !p.isRepost).toList();
              final reposts = all.where((p) => p.isRepost).toList();

              final n = originals.length;
              if (n != _postsCount) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _postsCount = n);
                });
              }

              return NestedScrollView(
                controller: _scrollController,
                headerSliverBuilder: (context, inner) => [
                  SliverToBoxAdapter(child: _buildXHeader(t, t.isDark)),
                  if (_canSeePrivateContent)
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _ProfileTabsDelegate(
                        tabBar: _postsTab(t),
                        background: t.pageBg,
                      ),
                    ),
                ],
                body: !_canSeePrivateContent
                    ? ListView(
                  padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 42, color: t.textFaint),
                    const SizedBox(height: 12),
                    Text(
                      mainText(context, "هذا الحساب خاص"),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      mainText(context, "تابع هذا الحساب لرؤية منشوراته."),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: t.textFaint),
                    ),
                  ],
                )

                    : TabBarView(
                  controller: _tabController,
                  children: [
                    waiting
                        ? const _ProfileTabLoading()
                        : _ProfilePostsPane(
                      posts: originals,
                      emptyLabel: mainText(context, "لا توجد منشورات بعد"),
                      emptyIcon: Icons.article_outlined,
                      t: t,
                      actionLabel: mainText(context, "أنشئ أول منشور"),
                      onAction: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CreatePostScreen(),
                          ),
                        );
                      },
                      onChanged: () { _loadHiddenPosts(); refreshPosts(); },
                    ),
                    waiting
                        ? const _ProfileTabLoading()
                        : _ProfilePostsPane(
                      posts: reposts,
                      emptyLabel: mainText(context, "لا توجد إعادة نشر"),
                      emptyIcon: Icons.repeat_rounded,
                      t: t,
                      onChanged: () { _loadHiddenPosts(); refreshPosts(); },
                    ),
                    _ProfileCommentsPane(
                      loading: _loadingComments,
                      error: _commentsError,
                      onRetry: _loadUserComments,
                      comments: _userComments,
                      t: t,
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              color: t.pageBg.withValues(alpha: _appBarOpacity),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: kToolbarHeight,
                  child: Row(
                    children: [
                      _appBarCircleButton(
                        icon: Icons.arrow_back,
                        color: iconColor,
                        bg: btnBg,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      Expanded(
                        child: Opacity(
                          opacity: _appBarOpacity,
                          child: Text(
                            _displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: t.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      _appBarCircleButton(
                        icon: Icons.search_rounded,
                        color: iconColor,
                        bg: btnBg,
                        onTap: () => _openProfileSearch(t),
                      ),
                      if (!_isSelf)
                        _appBarCircleButton(
                          icon: Icons.more_horiz,
                          color: iconColor,
                          bg: btnBg,
                          onTap: () => _showMoreSheet(t),
                        ),
                      const SizedBox(width: 6),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _appBarCircleButton({
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: bg,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(icon, size: 19, color: color),
          ),
        ),
      ),
    );
  }


  Widget _buildXHeader(_ProfileTheme t, bool isDark) {
    final topInset = MediaQuery.paddingOf(context).top;
    final coverH = _coverHeight + topInset;
    final bio = _mood.trim().isNotEmpty
        ? _mood.trim()
        : (_otherInfo.trim().isNotEmpty ? _otherInfo.trim() : '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: coverH + _avatarSize / 2 + 8,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: coverH,
                child: _coverUrl != null && _coverUrl!.trim().isNotEmpty
                    ? Image.network(
                  _coverUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: coverH,
                  errorBuilder: (_, __, ___) => _coverFallback(),
                )
                    : _coverFallback(),
              ),
              Positioned(
                left: 16,
                top: coverH - _avatarSize / 2,
                child: Container(
                  width: _avatarSize,
                  height: _avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: t.pageBg,
                    border: Border.all(color: t.pageBg, width: 4),
                  ),
                  child: ClipOval(
                    child: PublicProfilePhoto(
                      userId: widget.userId,
                      fallbackUrl: _photoUrl,
                      size: _avatarSize - 8,
                      radius: (_avatarSize - 8) / 2,
                      iconSize: 30,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                top: coverH + 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_isSelf) ...[
                      _circleIconButton(
                        t,
                        FaIcon(
                          FontAwesomeIcons.commentDots,
                          size: 16,
                          color: t.textPrimary,
                        ),
                            () async {
                          if (await isAccountBlocked(widget.userId) ||
                              await isBlockedByAccount(widget.userId)) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text(mainText(context, "لا يمكن المراسلة بسبب الحظر"))),
                            );
                            return;
                          }
                          final peer = await PublicProfileService.load(widget.userId);
                          if (isUserDocUnavailable(peer)) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(
                                content: Text(mainText(context, "لا يمكن مراسلة هذا الحساب")),
                              ),
                            );
                            return;
                          }
                          if (!mounted) return;
                          await openDirectChat(
                            context,
                            peerId: widget.userId,
                            peerName: _displayName,
                            peerPhotoUrl: _photoUrl,
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _followButton(t, isDark),
                    ] else
                      _outlineChip(t, mainText(context, "Edit profile"), () {
                        Navigator.of(context).maybePop();
                      }),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_loadingProfile) ...[
                _ShimmerLine(width: 140, height: 18, t: t),
                const SizedBox(height: 8),
                _ShimmerLine(width: 90, height: 13, t: t),
              ] else ...[
                Text(
                  _displayName,
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@$_username',
                  style: TextStyle(color: t.textFaint, fontSize: 15),
                ),
                if (_email.isNotEmpty &&
                    (_isSelf || _showEmailOnProfile)) ...[
                  const SizedBox(height: 4),
                  Text(
                    _email,
                    style: TextStyle(color: t.textFaint, fontSize: 13.5),
                  ),
                ],
                if (_presenceText != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _presenceText!,
                    style: TextStyle(
                      color: _isOnline && (_isSelf || _showOnlineStatus)
                          ? const Color(0xFF16A34A)
                          : t.textFaint,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
              if (bio.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  bio,
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _metaRow(t),
              const SizedBox(height: 12),
              _statsRow(t),
              const SizedBox(height: 8),

            ],
          ),
        ),
      ],
    );
  }

  Widget _metaRow(_ProfileTheme t) {
    // ===== المعلومات النصية العادية (إقامة/جامعة/عمل) =====
    final meta = <(IconData, String, VoidCallback?)>[];
    if (_isSelf || _showAcademicInfo) {
    if (_uni.isNotEmpty || _fac.isNotEmpty) {
      final line = [_uni, _fac, if (_studyLevel.isNotEmpty) _studyLevel]
          .where((e) =>
      e
          .trim().isNotEmpty)
          .join(' · ');
      if (line.isNotEmpty) {
        meta.add((Icons.school_outlined, line, null));
      }
    }
    if (_work.isNotEmpty) {
      meta.add((Icons.work_outline_rounded, _work, null));
    }
  }

    final linkPills = <Widget>[
      if ((_isSelf || _showSocialLinks) &&_github.isNotEmpty)
        _SocialLinkPill(
          t: t,
          icon: Icons.code_rounded,
          label: 'GitHub',
          onTap: () => _openLink(_github),
        ),
      if ((_isSelf || _showSocialLinks) &&_linkedin.isNotEmpty)
        _SocialLinkPill(
          t: t,
          icon: Icons.work_outline_rounded,
          label: 'LinkedIn',
          onTap: () => _openLink(_linkedin),
        ),
      if ((_isSelf || _showSocialLinks) &&_portfolio.isNotEmpty)
        _SocialLinkPill(
          t: t,
          icon: Icons.language_rounded,
          label: mainText(context, "Portfolio"),
          onTap: () => _openLink(_portfolio),
        ),
    ];

    if (meta.isEmpty && linkPills.isEmpty) return const SizedBox.shrink();

    final metaWidgets = meta.map((m) {
      final (icon, text, onTap) = m;
      final child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: t.textFaint),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: onTap != null ? AppTeal.main : t.textFaint,
                fontSize: 13.5,
                fontWeight: onTap != null ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      );
      if (onTap == null) return child;
      return GestureDetector(onTap: onTap, child: child);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (metaWidgets.isNotEmpty)
          Wrap(spacing: 14, runSpacing: 8, children: metaWidgets),
        if (linkPills.isNotEmpty) ...[
          if (metaWidgets.isNotEmpty) const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: linkPills),
        ],
      ],
    );
  }


  Widget _statsRow(_ProfileTheme t) {
    Widget chip({
      required String value,
      required String label,
      VoidCallback? onTap,
    }) {
      return Expanded(
        child: Material(
          color: t.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 34,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        label,
                        style: TextStyle(
                          color: t.textFaint,
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                          height: 1,
                        ),
                      ),
                      if (onTap != null) ...[
                        const SizedBox(width: 1),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 14,
                          color: t.textFaint,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
      child: Row(
        children: [
          chip(value: _formatCount(_postsCount), label: mainText(context, "منشورات")),
          const SizedBox(width: 6),
          chip(
            value: _formatCount(_followersCount),
            label: mainText(context, "متابعون"),
            onTap: () => _openFollowList(isFollowers: true),
          ),
          const SizedBox(width: 6),
          chip(
            value: _formatCount(_followingCount),
            label: mainText(context, "يتابع"),
            onTap: () => _openFollowList(isFollowers: false),
          ),
        ],
      ),
    );
  }

  void _showUserListSheetPlaceholder(_ProfileTheme t, String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: t.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Text(mainText(context, "قريباً"), style: TextStyle(color: t.textFaint)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _postsTab(_ProfileTheme t) {
    return TabBar(
      splashFactory: NoSplash.splashFactory,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      controller: _tabController,
      labelColor: t.textPrimary,
      unselectedLabelColor: t.textFaint,
      indicatorColor: AppTeal.main,
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: t.cardBorder,
      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
      unselectedLabelStyle:
      const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      tabs:  [
        Tab(text: mainText(context, "منشورات")),
        Tab(text: mainText(context, "إعادة نشر")),
        Tab(text: mainText(context, "تعليقات")),
      ],
    );
  }



  Widget _circleIconButton(_ProfileTheme t, Widget icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: t.cardBorder, width: 1.2),
          ),
          child: Center(child: icon),
        ),
      ),
    );
  }

  Widget _outlineChip(_ProfileTheme t, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: t.cardBorder, width: 1.2),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: t.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _coverFallback() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTeal.main.withValues(alpha: 0.85),
            const Color(0xFF1565C0),
          ],
        ),
      ),
    );
  }

  void _showMoreSheet(_ProfileTheme t) {
    final link = 'unispace://user/${widget.userId}';

    Future<void> copyLink() async {
      await Clipboard.setData(ClipboardData(text: link));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(mainText(context, "تم نسخ الرابط"))),
      );
    }

    Future<void> shareProfile() async {
      await Share.share(
        '$_displayName  (@$_username)\n$link',
        subject: _displayName,
      );
    }

    showModalBottomSheet(
      context: context,

      isScrollControlled: true,
      builder: (ctx) {
        final sheetBg = t.isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
        final groupBg = t.isDark ? const Color(0xFF2C2C2E) : Colors.white;
        final danger = t.isDark ? const Color(0xFFFF453A) : const Color(0xFFD70015);
        final divider = t.isDark
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.black.withValues(alpha: 0.08);
        final handleColor = t.isDark
            ? Colors.white.withValues(alpha: 0.28)
            : Colors.black.withValues(alpha: 0.18);

        Widget handle() => Center(
          child: Container(
            width: 36,
            height: 5,
            margin: const EdgeInsets.only(top: 10, bottom: 14),
            // decoration: BoxDecoration(
            //   color: handleColor,
            //   borderRadius: BorderRadius.circular(99),
            // ),
          ),
        );

        Widget row({
          required String label,
          required IconData icon,
          required VoidCallback onTap,
          bool destructive = false,
        }) {
          final color = destructive ? danger : t.textPrimary;
          return InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(icon, size: 22, color: color),
                  ],
                ),
              ),
            ),
          );
        }

        Widget group(List<Widget> rows) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ColoredBox(
              color: groupBg,
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 0.5,
                        thickness: 0.5,
                        indent: 16,
                        endIndent: 16,
                        color: divider,
                      ),
                    rows[i],
                  ],
                ],
              ),
            ),
          );
        }

        return Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    handle(),
                    group([
                      row(
                        label: mainText(ctx, "Copy link"),
                        icon: Icons.link_rounded,
                        onTap: () {
                          Navigator.pop(ctx);
                          copyLink();
                        },
                      ),
                      row(
                        label: mainText(ctx, "Share to"),
                        icon: Icons.ios_share_rounded,
                        onTap: () {
                          Navigator.pop(ctx);
                          shareProfile();
                        },
                      ),
                    ]),
                    const SizedBox(height: 8),
                    group([
                      row(
                        label: mainText(ctx, "معلومات الحساب"),
                        icon: Icons.info_outline_rounded,
                        onTap: () {
                          Navigator.pop(ctx);
                          _openInfoSheet(t);
                        },
                      ),
                      row(
                        label: mainText(ctx, "السيرة"),
                        icon: Icons.description_outlined,
                        onTap: () {
                          Navigator.pop(ctx);
                          _openCvSheet(t);
                        },
                      ),
                    ]),
                    const SizedBox(height: 8),
                    group([
                      row(
                        label: mainText(ctx, "تبليغ"),
                        icon: Icons.flag_outlined,
                        onTap: () {
                          Navigator.pop(ctx);
                          _reportAccount();
                        },
                      ),
                      row(
                        label: _iBlockThem ? mainText(ctx, "إلغاء الحظر") : mainText(ctx, "حظر الحساب"),
                        icon: _iBlockThem
                            ? Icons.lock_open_rounded
                            : Icons.block_rounded,
                        destructive: true,
                        onTap: () {
                          Navigator.pop(ctx);
                          if (_iBlockThem) {
                            _unblock();
                          } else {
                            _confirmBlock();
                          }
                        },
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openInfoSheet(_ProfileTheme t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            final hasPersonal = _residence.isNotEmpty ||
                _displayName.trim().isNotEmpty;
            final hasStudy = _uni.isNotEmpty ||
                _fac.isNotEmpty ||
                _major.isNotEmpty ||
                _studyLevel.isNotEmpty;
            final hasWork = _work.isNotEmpty;
            final hasLinks = _github.isNotEmpty ||
                _linkedin.isNotEmpty ||
                _portfolio.isNotEmpty;
            final hasOther = _otherInfo.isNotEmpty;
            final isEmpty = !hasPersonal &&
                !hasStudy &&
                !hasWork &&
                !hasLinks &&
                !hasOther;

            return Container(
              decoration: BoxDecoration(
                color: t.cardBg,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: t.cardBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            mainText(context, "Profile info"),
                            style: TextStyle(
                              color: t.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: t.cardBorder),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      children: [
                        if (isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                mainText(context, "لا توجد معلومات"),
                                style: TextStyle(
                                  color: t.textFaint,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                        else ...[
                          // —— شخصية ——
                          if (hasPersonal) ...[
                            _AccountSection(
                              title: mainText(context, "شخصية"),
                              t: t,
                              children: [
                                if (_displayName.trim().isNotEmpty)
                                  _AccountFieldTile(
                                    label: mainText(context, "الاسم"),
                                    value: _displayName.trim(),
                                    t: t,
                                  ),
                                if (_username.trim().isNotEmpty)
                                  _AccountFieldTile(
                                    label: mainText(context, "المعرّف"),
                                    value: '@$_username',
                                    t: t,
                                  ),
                                if (_residence.isNotEmpty)
                                  _AccountFieldTile(
                                    label: mainText(context, "مكان الإقامة"),
                                    value: _residence,
                                    t: t,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                          ],

                          // —— دراسة ——
                          if (hasStudy) ...[
                            _AccountSection(
                              title: mainText(context, "دراسة"),
                              t: t,
                              children: [
                                if (_uni.isNotEmpty)
                                  _AccountFieldTile(
                                    label: mainText(context, "الجامعة"),
                                    value: _uni,
                                    t: t,
                                  ),
                                if (_fac.isNotEmpty)
                                  _AccountFieldTile(
                                    label: mainText(context, "الكلية"),
                                    value: _fac,
                                    t: t,
                                  ),
                                if (_major.isNotEmpty)
                                  _AccountFieldTile(
                                    label: mainText(context, "التخصص"),
                                    value: _major,
                                    t: t,
                                  ),
                                if (_studyLevel.isNotEmpty)
                                  _AccountFieldTile(
                                    label: mainText(context, "المستوى / السنة"),
                                    value: _studyLevel,
                                    t: t,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                          ],

                          // —— عمل ——
                          if (hasWork) ...[
                            _AccountSection(
                              title: mainText(context, "عمل"),
                              t: t,
                              children: [
                                _AccountFieldTile(
                                  label: mainText(context, "العمل / الوظيفة"),
                                  value: _work,
                                  t: t,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                          ],

                          // —— روابط ——
                          if (hasLinks) ...[
                            _AccountSection(
                              title: mainText(context, "روابط"),
                              t: t,
                              children: [
                                if (_github.isNotEmpty)
                                  _AccountFieldTile(
                                    label: 'GitHub',
                                    value: _github,
                                    t: t,
                                  ),
                                if (_linkedin.isNotEmpty)
                                  _AccountFieldTile(
                                    label: 'LinkedIn',
                                    value: _linkedin,
                                    t: t,
                                  ),
                                if (_portfolio.isNotEmpty)
                                  _AccountFieldTile(
                                    label: mainText(context, "Portfolio"),
                                    value: _portfolio,
                                    t: t,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                          ],

                          // —— أخرى ——
                          if (hasOther)
                            _AccountSection(
                              title: mainText(context, "أخرى"),
                              t: t,
                              children: [
                                _AccountFieldTile(
                                  label: mainText(context, "معلومات إضافية"),
                                  value: _otherInfo,
                                  t: t,
                                ),
                              ],
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openCvSheet(_ProfileTheme t) {
    final hasText = _otherInfo.isNotEmpty;
    final hasLinks =
        _github.isNotEmpty || _linkedin.isNotEmpty || _portfolio.isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.45,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: t.cardBg,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: t.cardBorder,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    mainText(context, "السيرة"),
                    style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!hasText && !hasLinks)
                    Text(mainText(context, "لا توجد سيرة بعد"),
                        style: TextStyle(color: t.textFaint))
                  else ...[
                    if (hasText)
                      Text(
                        _otherInfo,
                        style: TextStyle(
                          color: t.textMuted,
                          fontSize: 15,
                          height: 1.45,
                        ),
                      ),
                    if (hasLinks) ...[
                      if (hasText) const SizedBox(height: 16),
                      if (_github.isNotEmpty)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.code, color: AppTeal.main),
                          title: const Text('GitHub'),
                          trailing: const Icon(Icons.open_in_new, size: 16),
                          onTap: () => _openLink(_github),
                        ),
                      if (_linkedin.isNotEmpty)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading:
                          Icon(Icons.work_outline, color: AppTeal.main),
                          title: const Text('LinkedIn'),
                          trailing: const Icon(Icons.open_in_new, size: 16),
                          onTap: () => _openLink(_linkedin),
                        ),
                      if (_portfolio.isNotEmpty)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.language, color: AppTeal.main),
                          title:  Text(mainText(context, "Portfolio")),
                          trailing: const Icon(Icons.open_in_new, size: 16),
                          onTap: () => _openLink(_portfolio),
                        ),
                    ],
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
  Future<void> _openFollowList({required bool isFollowers}) async {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FollowListSheet(
        ownerId: widget.userId,
        isFollowers: isFollowers,
        isSelf: _isSelf,
      ),
    );
  }
}
class _ProfileCommentHit {
  const _ProfileCommentHit({required this.post, required this.comment});
  final _Post post;
  final _Comment comment;
}
class _ProfileTabsDelegate extends SliverPersistentHeaderDelegate {
  _ProfileTabsDelegate({required this.tabBar, required this.background});
  final Widget tabBar;
  final Color background;

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      ) {
    return ColoredBox(color: background, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _ProfileTabsDelegate old) =>
      tabBar != old.tabBar || background != old.background;
}

class _ProfileTabLoading extends StatelessWidget {
  const _ProfileTabLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }
}
class _ProfileCommentsPane extends StatelessWidget {
  const _ProfileCommentsPane({
    required this.loading,
    this.error,
    this.onRetry,
    required this.comments,
    required this.t,
  });

  final bool loading;
  final String? error;
  final VoidCallback? onRetry;
  final List<_ProfileCommentHit> comments;
  final _ProfileTheme t;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }
    if (error != null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(error!), TextButton(onPressed: onRetry, child:  Text(mainText(context, "إعادة المحاولة"))),
    ]));
    if (comments.isEmpty) {
      return CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(mainText(context, "لا توجد تعليقات"),
                  style: TextStyle(color: t.textFaint)),
            ),
          ),
        ],
      );
    }
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, i) =>
                  _ProfileCommentTile(hit: comments[i], t: t),
              childCount: comments.length,
            ),
          ),
        ),
      ],
    );
  }
}
class _ProfileCommentTile extends StatelessWidget {
  const _ProfileCommentTile({required this.hit, required this.t});
  final _ProfileCommentHit hit;
  final _ProfileTheme t;

  @override
  Widget build(BuildContext context) {
    final c = hit.comment;
    final title = hit.post.title.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: t.cardBg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CommentsScreen(post: hit.post)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    LiveAuthorPhoto(
                      userId: c.authorId,
                      fallbackUrl: c.authorPhotoUrl,
                      size: 28,
                      radius: 10,
                      iconSize: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ValueListenableBuilder<int>(
                        valueListenable: AuthorProfiles.revision,
                        builder: (context, _, __) {
                          final id = c.authorId?.trim() ?? '';
                          if (id.isNotEmpty) AuthorProfiles.ensure(id);
                          final live = AuthorProfiles.nameOf(c.authorId)?.trim();
                          final name = (live != null && live.isNotEmpty)
                              ? live
                              : c.author;
                          return Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: t.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          );
                        },
                      ),
                    ),
                    Text(
                      c.timeAgo,
                      style: TextStyle(color: t.textFaint, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  c.text.trim(),
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                if (title.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    mainText(context, "على: {0}", <Object?>[title]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: t.textFaint, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class _ShimmerLine extends StatelessWidget {
  const _ShimmerLine({
    required this.width,
    required this.height,
    required this.t,
  });
  final double width;
  final double height;
  final _ProfileTheme t;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: t.isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _ProfileSearchSheet extends StatefulWidget {
  const _ProfileSearchSheet({
    required this.t,
    required this.authorId,
    required this.authorName,
  });

  final _ProfileTheme t;
  final String authorId;
  final String authorName;

  @override
  State<_ProfileSearchSheet> createState() => _ProfileSearchSheetState();
}
class _ShimmerBlock extends StatelessWidget {
  const _ShimmerBlock({required this.t});
  final _ProfileTheme t;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: t.isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.05),
    );
  }
}
class _ProfileSearchHit {
  const _ProfileSearchHit.post(this.post)
      : comment = null,
        isComment = false;

  const _ProfileSearchHit.comment(this.post, this.comment)
      : isComment = true;

  final _Post post;
  final _Comment? comment;
  final bool isComment;
}

class _ProfileSearchSheetState extends State<_ProfileSearchSheet> {
  final _ctrl = TextEditingController();
  String _query = '';
  bool _loading = false;
  List<_ProfileSearchHit> _results = [];
  Timer? _debounce;
  int _generation = 0;
  String? _error, _viewer;
  StreamSubscription<User?>? _auth;

  @override
  void initState() {
    super.initState();
    _viewer = FirebaseAuth.instance.currentUser?.uid;
    _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted || user?.uid == _viewer) return;
      _viewer = user?.uid; _refreshAccess();
    });
    blockedListRevision.addListener(_refreshAccess);
    hiddenListRevision.addListener(_refreshAccess);
    authorProfileRevision.addListener(_refreshAccess);
    followRevision.addListener(_refreshAccess);
    moderationRevision.addListener(_refreshAccess);
  }

  void _refreshAccess() { if (mounted) _onQueryChanged(_ctrl.text); }

  @override
  void didUpdateWidget(covariant _ProfileSearchSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authorId != widget.authorId) _refreshAccess();
  }

  @override
  void dispose() {
    _generation++;
    _auth?.cancel();
    blockedListRevision.removeListener(_refreshAccess);
    hiddenListRevision.removeListener(_refreshAccess);
    authorProfileRevision.removeListener(_refreshAccess);
    followRevision.removeListener(_refreshAccess);
    moderationRevision.removeListener(_refreshAccess);
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String q) {
    if (!mounted) return;
    _generation++;
    setState(() { _query = q.trim().toLowerCase(); _results = []; _error = null; _loading = _query.isNotEmpty; });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      _runSearch(q);
    });
  }

  Future<void> _runSearch(String q) async {
    final text = q.trim().toLowerCase();
    if (!mounted) return;
    final generation = ++_generation;
    final viewer = FirebaseAuth.instance.currentUser?.uid;
    final author = widget.authorId;
    bool current() => mounted && generation == _generation &&
        viewer == FirebaseAuth.instance.currentUser?.uid && author == widget.authorId;

    setState(() {
      _error = null;
      _results = [];
      _query = text;
      _loading = text.isNotEmpty;
      if (text.isEmpty) _results = [];
    });

    if (text.isEmpty || widget.authorId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final authorized = <String, _Post>{};
      Map<String, dynamic>? cursor;
      for (var pageNumber = 0; pageNumber < 4; pageNumber++) {
        if (!current()) return;
        final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
            .httpsCallable('readProfilePosts', options: HttpsCallableOptions(timeout: const Duration(seconds: 120)))
            .call<Map<String, dynamic>>({'userId': author, 'cursor': cursor});
        if (!current()) return;
        final page = response.data;
        if (page['posts'] is! List || page['exhausted'] is! bool ||
            (page['cursor'] != null && page['cursor'] is! Map) ||
            (page['exhausted'] == false && page['cursor'] == null)) throw StateError('Invalid search page');
        for (final row in page['posts'] as List) {
          if (row is! Map || row['id'] is! String || row['data'] is! Map) throw StateError('Invalid post');
          final post = _Post.fromData(row['id'] as String, Map<String, dynamic>.from(row['data'] as Map));
          if (post.authorId != author) throw StateError('Unexpected author');
          authorized[row['id'] as String] = post;
        }
        if (page['exhausted'] == true) break;
        cursor = Map<String, dynamic>.from(page['cursor'] as Map);
      }

      final hits = <_ProfileSearchHit>[];

      void walkComments(_Post post, List<_Comment> list) {
        for (final c in list) {
          // تعليقات صاحب الحساب فقط
          if (c.authorId == widget.authorId) {
            final body = c.text.toLowerCase();
            if (body.contains(text)) {
              hits.add(_ProfileSearchHit.comment(post, c));
            }
          }
          if (c.replies.isNotEmpty) {
            walkComments(post, c.replies);
          }
        }
      }

      final hiddenPosts = await loadHiddenPostIds();
      if (!current()) return;
      final posts = authorized.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      for (final post in posts.take(100)) {
        final postId = post.id?.trim();
        if (postId != null && hiddenPosts.contains(postId)) continue;

        final title = post.title.toLowerCase();
        final body = post.body.toLowerCase();
        final tags = post.tags.join(' ').toLowerCase();
        if (title.contains(text) || body.contains(text) || tags.contains(text)) {
          hits.add(_ProfileSearchHit.post(post));
        }

        walkComments(post, post.comments);
      }

      if (!current()) return;
      setState(() {
        _results = hits;
        _loading = false;
      });
    } catch (e) {
      debugPrint('profile search failed: $e');
      if (!current()) return;
      setState(() {
        _loading = false;
        _results = [];
        _error = mainText(context, "تعذر إتمام البحث، حاول مجدداً");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxH = MediaQuery.sizeOf(context).height * 0.75;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: t.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: t.cardBorder,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            autofocus: true,
                            onChanged: _onQueryChanged,
                            textInputAction: TextInputAction.search,
                            style: TextStyle(color: t.textPrimary, fontSize: 15),
                            decoration: InputDecoration(
                              hintText:
                              mainText(context, "بحث في منشورات وتعليقات {0}...", <Object?>[widget.authorName]),
                              hintStyle:
                              TextStyle(color: t.textFaint, fontSize: 13),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: t.textFaint,
                                size: 22,
                              ),
                              filled: true,
                              fillColor: t.isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            mainText(context, "إلغاء"),
                            style: TextStyle(
                              color: AppTeal.main,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: t.cardBorder),

                  // المحتوى القابل للتمرير — يمنع Overflow
                  Flexible(
                    child: _loading
                        ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                          ),
                        ),
                      ),
                    )
                        : _error != null
                        ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(
                          mainAxisSize: MainAxisSize.min, children: [
                            Text(_error!),
                            TextButton(onPressed: () => _onQueryChanged(_ctrl.text), child:  Text(mainText(context, "إعادة المحاولة"))),
                          ],
                        )))
                        : _query.isEmpty
                        ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          mainText(context, "ابحث في المنشورات والتعليقات"),
                          style: TextStyle(
                            color: t.textFaint,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    )
                        : _results.isEmpty
                        ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          mainText(context, "لا توجد نتائج"),
                          style: TextStyle(
                            color: t.textFaint,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    )
                        : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        12,
                        8,
                        12,
                        20,
                      ),
                      itemCount: _results.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final hit = _results[i];
                        if (hit.isComment) {
                          return _searchCommentTile(hit, t);
                        }
                        return _PostCard(
                          post: hit.post,
                          showAuthorHeader: false,
                          compact: true,
                          onChanged: () {},
                          onDelete: () async {},
                          onHidden: () {},
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchCommentTile(_ProfileSearchHit hit, _ProfileTheme t) {
    final c = hit.comment!;
    final title = hit.post.title.trim();

    return Material(
      color: t.isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.black.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CommentsScreen(post: hit.post, initialCommentId: c.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 14, color: t.textFaint),
                  const SizedBox(width: 6),
                  Text(
                    mainText(context, "تعليق"),
                    style: TextStyle(
                      color: t.textFaint,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    c.timeAgo,
                    style: TextStyle(color: t.textFaint, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                c.text.trim(),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
              if (title.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  mainText(context, "على: {0}", <Object?>[title]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: t.textFaint, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

//======================================================================
