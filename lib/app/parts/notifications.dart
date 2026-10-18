part of '../../main.dart';

Future<Set<String>> _loadNotificationBlockedIds(String? uid) async {
  if (uid == null) return <String>{};
  final snapshots = await Future.wait([
    for (final name in ['blocked_accounts', 'blocked_users', 'blocked_by'])
      FirebaseFirestore.instance.collection('users')
          .doc(uid)
          .collection(name)
          .get(),
  ]);
  if (FirebaseAuth.instance.currentUser?.uid != uid) throw StateError('Account changed');
  return {for (final snapshot in snapshots) for (final doc in snapshot.docs) doc.id};
}

class _CommunityHeader extends StatefulWidget {
  const _CommunityHeader();
  @override
  State<_CommunityHeader> createState() => _CommunityHeaderState();
}
class _CommunityHeaderState extends State<_CommunityHeader> {
  String? _uid;
  StreamSubscription<User?>? _auth;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _stream;
  late Future<Set<String>> _blocked;
  void _load() {
    _stream = _uid == null ? null : FirebaseFirestore.instance.collection('users')
            .doc(_uid)
        .collection('notifications')
            .orderBy('createdAt', descending: true)
            .limit(30)
            .snapshots();
    _blocked = _loadNotificationBlockedIds(_uid);
    unawaited(_blocked.then<void>((_) {}, onError: (Object error, StackTrace stack) {}));
  }
  void _refresh() { if (mounted) setState(_load); }
  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _load();
    blockedListRevision.addListener(_refresh);
    _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted || user?.uid == _uid) return;
      _uid = user?.uid;
      _refresh();
    });
  }
  @override
  void dispose() {
    _auth?.cancel();
    blockedListRevision.removeListener(_refresh);
    super.dispose();
  }
  Widget _retry() => TextButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh),
    label:  Text(mainText(context, "تعذر تحميل الإشعارات — إعادة المحاولة")));
  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    if (uid == null) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      key: ValueKey(uid), stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) return _retry();
        if (snap.connectionState == ConnectionState.waiting || !snap.hasData) return const LinearProgressIndicator();
        return FutureBuilder<Set<String>>(future: _blocked, builder: (context, blockedSnap) {
          if (blockedSnap.hasError) return _retry();
          if (blockedSnap.connectionState != ConnectionState.done || !blockedSnap.hasData) return const LinearProgressIndicator();
          final blocked = blockedSnap.data!;
          final items = snap.data!.docs.map(_notificationFromDoc)
              .where(
                      (n) => n.actorId == null || !blocked.contains(n.actorId))
                  .toList();
          return NotificationsShowcase(notifications: items,
            onDismiss: (id) {
              if (FirebaseAuth.instance.currentUser?.uid == uid) _dismissNotification(uid,id);
            },
            onDismissAll: () {
              if (FirebaseAuth.instance.currentUser?.uid == uid) _dismissAllNotifications(uid,items.map((n) => n.id));
            },
          );
        });
      },
    );
  }
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.sender,
    required this.message,
    this.time,
    this.createdAt,
    this.type = 'comment',
    this.actorId,
    this.actorPhotoUrl,
    this.actorIds = const [],
    this.count = 1,
    this.postId,
    this.commentId,
    this.read = false,
    this.chatId,
  });

  final String id;
  final String sender;
  final String message;
  final String? time;
  final DateTime? createdAt;
  final String type;
  final String? actorId;
  final String? actorPhotoUrl;
  final List<String> actorIds;
  final int count;
  final String? postId;
  final String? commentId;
  final bool read;
  final String? chatId;

  String get displayMessage {
    switch (type) {
      case 'message': return localizedNotificationBody(Intl.getCurrentLocale(), type: 'message');
      case 'new_post': return mainTextCurrent("نشر منشوراً جديداً");
      case 'comment': return mainTextCurrent("علّق على منشورك");
      case 'reply': return mainTextCurrent("رد على تعليقك");
      case 'repost': return mainTextCurrent("أعاد نشر محتوى");
      case 'like': return count > 1 ? mainTextCurrent("وآخرون أعجبوا بمنشورك") : mainTextCurrent("أعجب بمنشورك");
      case 'like_comment': return count > 1 ? mainTextCurrent("وآخرون أعجبوا بتعليقك") : mainTextCurrent("أعجب بتعليقك");
      default:
        return (postId?.trim().isNotEmpty ?? false)
            ? mainTextCurrent("لديك تحديث على محتوى تتابعه") : message;
    }
  }
}

String _notifDayLabel(DateTime? dt) {
  if (dt == null) return mainTextCurrent("سابقاً");
  final now = DateTime.now();
  final day = DateTime(dt.year, dt.month, dt.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return mainTextCurrent("اليوم");
  if (diff == 1) return mainTextCurrent("أمس");
  if (diff < 7) return mainTextCurrent("هذا الأسبوع");
  return mainTextCurrent("سابقاً");
}

class _NotificationActorEntry extends ValueNotifier<Map<String, dynamic>?> {
  _NotificationActorEntry(this.userId) : super(null);
  final String userId;
  int users = 0;
  int _generation = 0;
  bool _loading = false;
  Timer? timer;

  Future<void> reload({bool invalidate = false}) async {
    if (users == 0 || (_loading && !invalidate)) return;
    final generation = ++_generation;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _loading = true;
    value = null;
    try {
      if (uid == null || userId.isEmpty) return;
      final profile = await PublicProfileService.load(userId);
      if (users > 0 && generation == _generation && FirebaseAuth.instance.currentUser?.uid == uid) {
        value = profile;
      }
    } catch (_) { /* Failed authorization keeps every subscriber neutral. */ }
    finally { if (generation == _generation) _loading = false; }
  }

  void close() {
    users = 0;
    ++_generation;
    timer?.cancel();
    dispose();
  }
}

class _NotificationActorPool {
  static final _entries = <String, _NotificationActorEntry>{};
  static StreamSubscription<User?>? _auth;
  static String? _uid;

  static void _invalidate() {
    for (final entry in _entries.values.toList()) {
      unawaited(entry.reload(invalidate: true));
    }
  }

  static _NotificationActorEntry acquire(String id) {
    if (_entries.isEmpty) {
      _uid = FirebaseAuth.instance.currentUser?.uid;
      blockedListRevision.addListener(_invalidate);
      _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user?.uid != _uid) { _uid = user?.uid; _invalidate(); }
      });
    }
    final entry = _entries.putIfAbsent(id, () => _NotificationActorEntry(id));
    entry.users++;
    if (entry.users == 1) {
      unawaited(entry.reload());
      entry.timer = Timer.periodic(const Duration(seconds: 30), (_) => unawaited(entry.reload()));
    }
    return entry;
  }

  static void release(_NotificationActorEntry entry) {
    if (--entry.users > 0) return;
    _entries.remove(entry.userId);
    entry.close();
    if (_entries.isEmpty) {
      blockedListRevision.removeListener(_invalidate);
      _auth?.cancel();
      _auth = null;
      _uid = null;
    }
  }
}

class _NotificationActor extends StatefulWidget {
  const _NotificationActor(
      {required this.userId, this.size, this.style,
    this.maxLines = 1, this.overflow = TextOverflow.ellipsis});
  final String? userId;
  final double? size;
  final TextStyle? style;
  final int maxLines;
  final TextOverflow overflow;
  @override
  State<_NotificationActor> createState() => _NotificationActorState();
}

class _NotificationActorState extends State<_NotificationActor> {
  late _NotificationActorEntry _entry;
  void _changed() { if (mounted) setState(() {}); }
  void _attach() {
    _entry = _NotificationActorPool.acquire(widget.userId?.trim() ?? '');
    _entry.addListener(_changed);
  }
  void _detach() {
    _entry.removeListener(_changed);
    _NotificationActorPool.release(_entry);
  }
  @override
  void initState() { super.initState(); _attach(); }
  @override
  void didUpdateWidget(covariant _NotificationActor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) { _detach(); _attach(); }
  }
  @override
  void dispose() { _detach(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final p = _entry.value;
    if (widget.size != null) {
      final size = widget.size!;
      return PublicProfilePhoto(userId: widget.userId ?? '',
        fallbackUrl: p?['profileImageUrl']?.toString(), size: size,
        radius: size / 2, iconSize: size / 2);
    }
    String name = mainText(context, "مستخدم");
    if (p != null) {
      final full = [p['firstName'],p['lastName']]
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .join(' ');
      final display = (p['displayName'] ?? p['username'] ?? '').toString().trim();
      name = full.isNotEmpty ? full : (display.isNotEmpty ? display : name);
    }
    return Text(name, style: widget.style, maxLines: widget.maxLines, overflow: widget.overflow);
  }
}

class _StackedNotifAvatars extends StatelessWidget {
  const _StackedNotifAvatars({required this.item, this.size = 44});
  final NotificationItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final n = item;
    final typeColor = _notificationColor(n.type);

    final t = _ProfileTheme.of(context);
    final ids = (item.actorIds.isNotEmpty
        ? item.actorIds
        : [
      if ((item.actorId ?? '').isNotEmpty) item.actorId!,
    ])
        .take(3)
        .toList();
    if (ids.isEmpty) {
      return _NotificationAvatar(item: item, radius: size / 2);
    }
    const overlap = 12.0;
    final width = size + (ids.length - 1) * (size - overlap) + 4;
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = ids.length - 1; i >= 0; i--)
            Positioned(
              right: rtl ? i * (size - overlap) : null,
              left: rtl ? null : i * (size - overlap),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: t.pageBg, width: 2),
                ),
                child: _NotificationActor(userId: ids[i], size: size - 4),
              ),
            ),
          Positioned(
            right: rtl ? 0 : null,
            left: rtl ? null : 0,
            bottom: -1,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: typeColor,
                shape: BoxShape.circle,
                border: Border.all(color: t.pageBg, width: 1.5),
              ),
              child: Icon(
                _notificationIcon(item.type),
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



String _notifTimeAgo(DateTime? dt) {
  if (dt == null) return mainTextCurrent("الآن");
  final d = DateTime.now().difference(dt);
  if (d.inSeconds < 60) return mainTextCurrent("الآن");
  if (d.inMinutes < 60) return mainTextCurrent("{0}د", <Object?>[d.inMinutes]);
  if (d.inHours < 24) return mainTextCurrent("{0}س", <Object?>[d.inHours]);
  if (d.inDays < 7) return mainTextCurrent("{0}ي", <Object?>[d.inDays]);
  return '${dt.day}/${dt.month}';
}

NotificationItem _notificationFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    ) {
  final d = doc.data();
  final created = d['createdAt'];
  DateTime? at;
  if (created is Timestamp) at = created.toDate();
  final rawIds = d['actorIds'];
  final actorIds = rawIds is List
      ? rawIds.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
      : <String>[
    if ((d['actorId'] ?? '').toString().isNotEmpty) d['actorId'].toString(),
  ];
  return NotificationItem(
    id: doc.id,
    sender: (d['actorName'] ?? mainTextCurrent("طالب")).toString(),
    message: (d['message'] ?? '').toString(),
    time: _notifTimeAgo(at),
    createdAt: at,
    type: (d['type'] ?? 'comment').toString(),
    actorId: d['actorId']?.toString(),
    actorPhotoUrl: d['actorPhotoUrl']?.toString(),
    actorIds: actorIds,
    count: (d['count'] as num?)?.toInt() ?? actorIds.length.clamp(1, 99),
    postId: d['postId']?.toString(),
    commentId: d['commentId']?.toString(),
    read: d['read'] == true,
    chatId: d['chatId']?.toString(),
  );
}

Future<void> pushNotification({
  required String toUid,
  required String type,
  required String actorName,
  String? actorPhotoUrl,
  required String message,
  String? postId,
  String? chatId,
  String? commentId,
  String? docId,
}) async {
  final me = FirebaseAuth.instance.currentUser?.uid;
  if (me == null || toUid.isEmpty || toUid == me) return;

  try {
    if (await isAccountBlocked(toUid)) return;
    if (await isBlockedByAccount(toUid)) return;
  } catch (_) {}

  final id = docId ?? (type == 'follow' ? 'follow_$me' : null);
  final col = FirebaseFirestore.instance
      .collection('users')
      .doc(toUid)
      .collection('notifications');
  final ref = id == null ? col.doc() : col.doc(id);

  try {
    await ref.set({
      'type': type,
      'actorId': me,
      'actorName': actorName,
      'actorPhotoUrl': actorPhotoUrl,
      'message': message,
      if (postId != null) 'postId': postId,
      if (commentId != null) 'commentId': commentId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      if (chatId != null) 'chatId': chatId,
    });
    debugPrint('notif OK → $toUid type=$type id=${ref.id}');
  } catch (e) {
    debugPrint('notif FAIL → $toUid type=$type $e');
  }
}

String composeLikeNotificationMessage({
  required bool isComment,
  required List<String> ids,
  required Map<String, String> names,
}) {
  final count = ids.length;
  if (count <= 1) {
    return isComment ? mainTextCurrent("أعجب بتعليقك") : mainTextCurrent("أعجب بمنشورك");
  }
  if (count == 2) {
    final other = (names[ids[1]] ?? '').trim();
    if (other.isNotEmpty) {
      return isComment ? mainTextCurrent("و{0} أعجبا بتعليقك", <Object?>[other]) : mainTextCurrent("و{0} أعجبا بمنشورك", <Object?>[other]);
    }
    return isComment ? mainTextCurrent("وآخر أعجبا بتعليقك") : mainTextCurrent("وآخر أعجبا بمنشورك");
  }
  return isComment
      ? mainTextCurrent("و{0} آخرين أعجبوا بتعليقك", <Object?>[count - 1])
      : mainTextCurrent("و{0} آخرين أعجبوا بمنشورك", <Object?>[count - 1]);
}

Future<void> pushNotificationFromMe({
  required String toUid,
  required String type,
  required String message,
  String? postId,
  String? commentId,
  String? docId,
}) async {
  final me = FirebaseAuth.instance.currentUser;
  if (me == null) return;
  var name = (me.displayName ?? '').trim();
  String? photo = me.photoURL;
  try {
    final d =
        await FirebaseFirestore.instance.collection('users').doc(me.uid).get();
    final fn = (d.data()?['firstName'] ?? '').toString().trim();
    final ln = (d.data()?['lastName'] ?? '').toString().trim();
    final fromNames = [fn, ln].where((e) => e.isNotEmpty).join(' ');
    if (fromNames.isNotEmpty) name = fromNames;
    final p = d.data()?['profileImageUrl']?.toString();
    if (p != null && p.isNotEmpty) photo = p;
  } catch (_) {}

  await pushNotification(
    toUid: toUid,
    type: type,
    actorName: name.isEmpty ? mainTextCurrent("طالب UniSpace") : name,
    actorPhotoUrl: photo,
    message: message,
    postId: postId,
    commentId: commentId,
    docId: docId,
  );
}

Future<void> _markNotificationRead(String uid, String id) async {
  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(id)
        .update({'read': true});
  } catch (e) {
    debugPrint('mark notif read failed: $e');
  }
}

Future<void> _dismissNotification(String uid, String id) async {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('notifications')
      .doc(id)
      .delete();
}

Future<void> _dismissAllNotifications(String uid, Iterable<String> ids) async {
  final batch = FirebaseFirestore.instance.batch();
  final col = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('notifications');
  for (final id in ids) {
    batch.delete(col.doc(id));
  }
  await batch.commit();
}

Future<void> _markAllNotificationsRead(String uid, {int limit = 80}) async {
  try {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(limit.clamp(80, 400).toInt())
        .get();
    final unread = snap.docs.where((d) => d.data()['read'] != true);
    if (unread.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final d in unread) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  } catch (e) {
    debugPrint('mark all read failed: $e');
  }
}

IconData _notificationIcon(String type) {
  switch (type) {
    case 'follow':
    case 'follow_accepted':
      return Icons.person_add_alt_1_rounded;
    case 'follow_request':
      return Icons.person_add_rounded;
    case 'like':
    case 'like_comment':
      return Icons.favorite_rounded;
    case 'reply':
      return Icons.reply_rounded;
    case 'new_post':
      return Icons.article_outlined;
    case 'repost':
      return Icons.repeat_rounded;
    default:
      return Icons.chat_bubble_outline_rounded;
  }
}



Future<void> _openNotification(BuildContext context, NotificationItem n,
) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  unawaited(_markNotificationRead(uid, n.id));
  final actorId = (n.actorId ?? '').trim();
  final type = n.type;

  if (type == 'message') {
    final chatId = (n.chatId ?? '').trim();
    if (chatId.isNotEmpty) {
      await openChatById(context, chatId);
    } else if (actorId.isNotEmpty) {
      await openChatById(context, directChatId(uid, actorId));
    }
    return;
  }

  if (type == 'follow_request') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FollowRequestsScreen()),
    );
    return;
  }

  if ((type == 'follow' || type == 'follow_accepted') && actorId.isNotEmpty) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          userId: actorId,
          initialName: null,
          initialPhotoUrl: null,
        ),
      ),
    );
    return;
  }

  final postId = n.postId?.trim() ?? '';
  if (postId.isNotEmpty) {
    try {
      final data = await _readAuthorizedPostData(postId);
      if (!context.mounted || FirebaseAuth.instance.currentUser?.uid != uid) return;
      final commentId = n.commentId?.trim() ?? '';
      bool containsComment(dynamic raw, int depth) {
        if (raw is! List || depth > 30) return false;
        for (final row in raw) {
          if (row is! Map) continue;
          if (row['id'] == commentId || containsComment(row['replies'], depth + 1)) return true;
        }
        return false;
      }
      if (commentId.isNotEmpty && !containsComment(data['comments'], 0)) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
           SnackBar(content: Text(mainText(context, "هذا التعليق غير متاح حاليًا"))),
        );
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CommentsScreen(
          post: _Post.fromData(postId, data),
          initialCommentId: commentId.isEmpty ? null : commentId,
        )),
      );
    } catch (_) {
      if (!context.mounted || FirebaseAuth.instance.currentUser?.uid != uid) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
         SnackBar(content: Text(mainText(context, "تعذر فتح المحتوى. قد يكون غير متاح أو تعذر الاتصال."))),
      );
    }
    return;
  }

  if (actorId.isNotEmpty) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          userId: actorId,
          initialName: null,
          initialPhotoUrl: null,
        ),
      ),
    );
  }




}

class NotificationsShowcase extends StatelessWidget {
  const NotificationsShowcase({
    super.key,
    required this.notifications,
    required this.onDismiss,
    required this.onDismissAll,
  });

  final List<NotificationItem> notifications;
  final ValueChanged<String> onDismiss;
  final VoidCallback onDismissAll;

  @override
  Widget build(BuildContext context) {
    return NotificationsStack(
      notifications: notifications,
      onDismiss: onDismiss,
      onDismissAll: onDismissAll,
    );
  }
}

class NotificationsStack extends StatefulWidget {
  const NotificationsStack({
    super.key,
    required this.notifications,
    required this.onDismiss,
    required this.onDismissAll,
    this.interval = const Duration(seconds: 4),
  });

  final List<NotificationItem> notifications;
  final ValueChanged<String> onDismiss;
  final VoidCallback onDismissAll;
  final Duration interval;

  @override
  State<NotificationsStack> createState() => _NotificationsStackState();
}

class _NotificationsStackState extends State<NotificationsStack> {
  int _active = 0;
  Timer? _timer;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant NotificationsStack old) {
    super.didUpdateWidget(old);
    if (widget.notifications.isEmpty) {
      _active = 0;
      return;
    }
    if (_active >= widget.notifications.length) {
      _active = 0;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted || _paused || widget.notifications.length <= 1) return;
      setState(() => _active = (_active + 1) % widget.notifications.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _open() async {
    _paused = true;
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Notifications',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => _NotificationsOverlay(
        initial: widget.notifications,
        onDismiss: widget.onDismiss,
        onDismissAll: widget.onDismissAll,
      ),
      transitionBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return Transform.scale(
          scale: 0.9 + 0.1 * curved.value,
          child: FadeTransition(opacity: anim, child: child),
        );
      },
    );
    if (mounted) _paused = false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = widget.notifications;
    final total = items.length;
    if (total == 0) return const SizedBox(height: 0);

    final index = _active.clamp(0, total - 1);
    final unread = items.where((e) => !e.read).length;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: GestureDetector(
        onTap: _open,
        child: SizedBox(
          height: 92,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              if (total > 2) _DepthLayer(scheme: scheme, depth: 2),
              if (total > 1) _DepthLayer(scheme: scheme, depth: 1),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 340),
                transitionBuilder: (child, anim) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.18),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                  ),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: _ActiveCard(
                  key: ValueKey(items[index].id),
                  item: items[index],
                  total: unread,
                  scheme: scheme,
                ),
              ),
              if (total > 1)
                Positioned(
                  bottom: -8,
                  child: _SlideDotsIndicator(
                    count: total,
                    currentIndex: index,
                    maxWidth: 140,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DepthLayer extends StatelessWidget {
  const _DepthLayer({required this.scheme, required this.depth});

  final ColorScheme scheme;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final shrink = depth * 12.0;
    final lift = depth * 7.0;
    final tilt = depth * 0.045;

    return Positioned(
      bottom: lift,
      left: shrink,
      right: shrink,
      child: Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0015)
          ..rotateX(tilt)
          ..scale(1 - depth * 0.04),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest
                .withValues(alpha: 0.65 - depth * 0.16),
            borderRadius: BorderRadius.circular(16 - depth * 1.5),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.28),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({
    super.key,
    required this.item,
    required this.total,
    required this.scheme,
  });

  final NotificationItem item;
  final int total;
  final ColorScheme scheme;

  static final _teal = AppTeal.main;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _teal.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: _teal.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          _StackedNotifAvatars(item: item, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _NotificationActor(
                        userId: item.actorId,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    if (item.time != null)
                      Text(
                        item.time!,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.displayMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (total > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_teal, AppTeal.accent]),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$total',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotificationAvatar extends StatelessWidget {
  const _NotificationAvatar({required this.item, required this.radius});

  final NotificationItem item;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return _NotificationActor(userId: item.actorId, size: radius * 2);
  }
}



class _NotificationsOverlay extends StatefulWidget {
  const _NotificationsOverlay({
    required this.initial,
    required this.onDismiss,
    required this.onDismissAll,
  });

  final List<NotificationItem> initial;
  final ValueChanged<String> onDismiss;
  final VoidCallback onDismissAll;

  @override
  State<_NotificationsOverlay> createState() => _NotificationsOverlayState();
}

class _NotificationsOverlayState extends State<_NotificationsOverlay> {
  late List<NotificationItem> _items = List.of(widget.initial);
  final _panelKey = GlobalKey();
  late final String? _ownerUid;
  StreamSubscription<User?>? _auth;
  bool _checkingBlocks = true;
  bool _blockError = false;
  int _generation = 0;
  final Set<String> _dismissed = {};
  @override
  void initState() {
    super.initState();
    _ownerUid = FirebaseAuth.instance.currentUser?.uid;
    blockedListRevision.addListener(_checkBlocks);
    _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user?.uid != _ownerUid) _checkBlocks();
    });
    _checkBlocks();
  }
  Future<void> _checkBlocks() async {
    final generation = ++_generation;
    if (!mounted) return;
    setState(() { _checkingBlocks = true; _blockError = false; });
    try {
      if (_ownerUid == null || FirebaseAuth.instance.currentUser?.uid != _ownerUid) throw StateError('Account changed');
      final blocked = await _loadNotificationBlockedIds(_ownerUid);
      if (!mounted || generation != _generation) return;
      setState(() {
        _items = widget.initial.where((n) => !_dismissed.contains(n.id) &&
            (n.actorId == null || !blocked.contains(n.actorId)))
            .toList();
        _checkingBlocks = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() { _items = []; _checkingBlocks = false; _blockError = true; });
    }
  }
  @override
  void dispose() {
    ++_generation;
    _auth?.cancel();
    blockedListRevision.removeListener(_checkBlocks);
    super.dispose();
  }

  void _expandToScreen() {
    final box = _panelKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : (box.localToGlobal(Offset.zero) & box.size);
    final nav = Navigator.of(context, rootNavigator: true);
    nav.pop();
    nav.push(
      _ExpandPanelRoute(
        originRect: origin,
        child: const NotificationsScreen(),
      ),
    );
  }
  void _dismiss(String id) {
    if (_checkingBlocks || _blockError || FirebaseAuth.instance.currentUser?.uid != _ownerUid) return;
    _dismissed.add(id);
    widget.onDismiss(id);
    setState(() => _items.removeWhere((n) => n.id == id));
    if (_items.isEmpty) Navigator.of(context).pop();
  }

  void _dismissAll() {
    if (_checkingBlocks || _blockError || FirebaseAuth.instance.currentUser?.uid != _ownerUid) return;
    for (final item in _items) { widget.onDismiss(item.id); }
    Navigator.of(context).pop();
  }

  Future<void> _openItem(NotificationItem n) async {
    if (_checkingBlocks || _blockError || FirebaseAuth.instance.currentUser?.uid != _ownerUid) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.pop();
    await _openNotification(navigator.context, n);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 370, maxHeight: 480),
        child: ClipRRect(
          key: _panelKey,
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Material(
              color: scheme.surface.withValues(alpha: 0.92),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          mainText(context, "الإشعارات"),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_items.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        if (_items.isNotEmpty && !_checkingBlocks && !_blockError)
                          TextButton(
                            onPressed: _dismissAll,
                            child:  Text(mainText(context, "مسح الكل")),
                          ),
                        const SizedBox(height: 8),
                        IconButton(
                          tooltip: mainText(context, "توسيع"),
                          icon: const Icon(Icons.zoom_out_map),
                          onPressed: _expandToScreen,
                          iconSize: 15,
                        ),

                      ],
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Flexible(
                      child: _checkingBlocks
                          ? const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
                          : _blockError
                          ? TextButton(onPressed: _checkBlocks,
                              child: Text(FirebaseAuth.instance.currentUser?.uid == _ownerUid
                                  ? mainText(context, "تعذر التحقق من الإشعارات. إعادة المحاولة")
                                  : mainText(context, "تغيّر الحساب. أغلق هذه النافذة وافتح الإشعارات مجددًا")))
                          : _items.isEmpty
                          ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          mainText(context, "لا توجد إشعارات"),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      )
                          : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _items.length,
                        separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final n = _items[i];
                          return _OverlayTile(
                            key: ValueKey(n.id),
                            item: n,
                            scheme: scheme,
                            onDismiss: () => _dismiss(n.id),
                            onOpen: () => _openItem(n),
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
      ),
    );
  }
}
class _ExpandPanelRoute extends PageRouteBuilder {
  final Rect? originRect;
  final Widget child;

  _ExpandPanelRoute({
    required this.originRect,
    required this.child,
  }) : super(
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionDuration: const Duration(milliseconds: 480),
    reverseTransitionDuration: const Duration(milliseconds: 360),
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
    final dest = Offset.zero & size;
    final origin = originRect ??
        Rect.fromCenter(
          center: dest.center,
          width: dest.width * 0.86,
          height: dest.height * 0.55,
        );

    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final t = curved.value;
        final rect = Rect.lerp(origin, dest, t)!;
        final radius = 20.0 * (1 - t);
        return Stack(
          children: [
            Positioned(
              left: rect.left,
              top: rect.top,
              width: rect.width,
              height: rect.height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: child,
              ),
            ),
          ],
        );
      },
      child: child,
    );
  }
}
class _OverlayTile extends StatelessWidget {
  const _OverlayTile({
    super.key,
    required this.item,
    required this.scheme,
    required this.onDismiss,
    required this.onOpen,
  });

  final NotificationItem item;
  final ColorScheme scheme;
  final VoidCallback onDismiss;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.read
          ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : AppTeal.main.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              _StackedNotifAvatars(item: item, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _NotificationActor(
                        userId: item.actorId,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        if (item.time != null)
                          Text(
                            item.time!,
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        if (!item.read) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTeal.main,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.displayMessage,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: onDismiss,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


enum _NotifFilter { all, follows, activity }

Color _notificationColor(String type) {
  switch (type) {
    case 'follow':
    case 'follow_accepted':
    case 'follow_request':
      return const Color(0xFF2563EB); // أزرق - متابعة
    case 'like':
    case 'like_comment':
      return const Color(0xFFE0245E); // وردي - إعجاب
    case 'reply':
    case 'comment':
      return AppTeal.main; // تيل - تعليق/رد
    case 'new_post':
      return const Color(0xFF8B5CF6); // بنفسجي - منشور جديد
    case 'repost':
      return const Color(0xFF10B981); // أخضر - إعادة نشر
    default:
      return AppTeal.main;
  }
}

bool _isFollowType(String type) =>
    type == 'follow' || type == 'follow_accepted' || type == 'follow_request';



class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  _NotifFilter _filter = _NotifFilter.all;
  int _limit = 80;
  String? _uid;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _notifications;
  late Future<Set<String>> _blocked;
  StreamSubscription<User?>? _auth;

  Future<Set<String>> _loadBlocked() => _loadNotificationBlockedIds(_uid);
  Future<Set<String>> _startBlockedLoad() {
    final future = _loadBlocked();
    // Observe early errors while the notification stream is still loading;
    // FutureBuilder still receives the original failed future and shows retry.
    unawaited(future.then<void>((_) {}, onError: (Object error, StackTrace stack) {}));
    return future;
  }

  void _subscribe() {
    _notifications = _uid == null ? null : FirebaseFirestore.instance
        .collection('users')
            .doc(_uid)
            .collection('notifications')
        .orderBy('createdAt', descending: true)
            .limit(_limit)
            .snapshots();
  }
  void _refresh() {
    if (!mounted) return;
    setState(() { _blocked = _startBlockedLoad(); _subscribe(); });
  }
  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _blocked = _startBlockedLoad();
    _subscribe();
    blockedListRevision.addListener(_refresh);
    _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted || user?.uid == _uid) return;
      _uid = user?.uid;
      _limit = 80;
      _refresh();
    });
  }
  @override
  void dispose() {
    blockedListRevision.removeListener(_refresh);
    _auth?.cancel();
    super.dispose();
  }
  Widget _loadError() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
     Text(mainText(context, "تعذر تحميل الإشعارات بأمان")),
    TextButton(onPressed: _refresh, child:  Text(mainText(context, "إعادة المحاولة"))),
  ]));

  @override
  Widget build(BuildContext context) {
    final t = _ProfileTheme.of(context);
    final uid = _uid;

    return Scaffold(
      backgroundColor: t.pageBg,
      appBar: AppBar(
        title:  Text(mainText(context, "الإشعارات")),
        backgroundColor: t.pageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(onPressed: _refresh, tooltip: mainText(context, "تحديث"), icon: const Icon(Icons.refresh)),
          if (uid != null)
            TextButton(
              onPressed: () => _markAllNotificationsRead(uid, limit: _limit),
              child: Text(
                mainText(context, "قراءة أحدث {0}", <Object?>[_limit]),
                style: TextStyle(color: AppTeal.main, fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
      body: uid == null
          ? Center(child: Text(mainText(context, "سجّل الدخول أولاً"), style: TextStyle(color: t.textFaint)))
          : Column(
        children: [
          // ===== تبويبات تصنيف بأسلوب X =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: _NotifFilterTabs(
              t: t,
              value: _filter,
              onChanged: (v) => setState(() => _filter = v),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              key: ValueKey(uid),
              stream: _notifications,
              builder: (context, snap) {
                if (snap.hasError) {
                  return _loadError();
                }
                if (snap.connectionState == ConnectionState.waiting || !snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return FutureBuilder<Set<String>>(
                  future: _blocked,
                  builder: (context, blockedSnap) {
                    if (blockedSnap.hasError) return _loadError();
                    if (blockedSnap.connectionState != ConnectionState.done || !blockedSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final blocked = blockedSnap.data!;
                    var items = snap.data!.docs
                        .map(_notificationFromDoc)
                        .where((n) => n.actorId == null || !blocked.contains(n.actorId))
                        .toList();

                    // ===== الفلترة حسب التبويب المختار =====
                    items = items.where((n) {
                      switch (_filter) {
                        case _NotifFilter.follows:
                          return _isFollowType(n.type);
                        case _NotifFilter.activity:
                          return !_isFollowType(n.type);
                        case _NotifFilter.all:
                          return true;
                      }
                    }).toList();

                    Widget withControls(Widget child) => Column(children: [
                      Expanded(child: child),
                      if (snap.data!.docs.length >= _limit)
                        SafeArea(top: false, child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: _limit < 400
                              ? TextButton(onPressed: () => setState(() {
                                  _limit += 80;
                                  _subscribe();
                                }), child:  Text(mainText(context, "تحميل إشعارات أقدم")))
                              :  Text(mainText(context, "تعرض هذه الصفحة أحدث 400 إشعار")),
                        )),
                    ]);

                    if (items.isEmpty) {
                      return withControls(Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_none_rounded, size: 48, color: t.textFaint),
                            const SizedBox(height: 10),
                            Text(
                              _filter == _NotifFilter.all ? mainText(context, "لا توجد إشعارات في القائمة المحمّلة") : mainText(context, "لا توجد إشعارات محمّلة في هذا التصنيف"),
                              style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ));
                    }

                    // ===== تجميع زمني: اليوم / أمس / هذا الأسبوع / سابقًا =====
                    final grouped = <String, List<NotificationItem>>{};
                    final order = <String>[];
                    for (final n in items) {
                      // نحتاج التاريخ الفعلي؛ نعيد استخراجه من time المُنسّق
                      // غير كافٍ، لذا نمرر DateTime عبر دالة مساعدة مصغّرة هنا:
                      final label = n.sectionLabel;
                      if (!grouped.containsKey(label)) {
                        grouped[label] = [];
                        order.add(label);
                      }
                      grouped[label]!.add(n);
                    }

                    return withControls(ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                      itemCount: order.fold<int>(0, (sum, k) => sum + 1 + grouped[k]!.length),
                      itemBuilder: (context, index) {
                        var cursor = 0;
                        for (final label in order) {
                          if (index == cursor) {
                            return Padding(
                              padding: EdgeInsets.fromLTRB(4, cursor == 0 ? 4 : 18, 4, 8),
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: t.textFaint,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }
                          cursor += 1;
                          final list = grouped[label]!;
                          if (index < cursor + list.length) {
                            final n = list[index - cursor];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: _NotificationTile(uid: uid, item: n),
                            );
                          }
                          cursor += list.length;
                        }
                        return const SizedBox.shrink();
                      },
                    ));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

extension _NotifSection on NotificationItem {
  String get sectionLabel => _notifDayLabel(createdAt);
}

/// تبويبات تصنيف الإشعارات - أسلوب X (كبسولة مقسّمة بثلاث خيارات)
class _NotifFilterTabs extends StatelessWidget {
  const _NotifFilterTabs(
      {required this.t, required this.value, required this.onChanged});

  final _ProfileTheme t;
  final _NotifFilter value;
  final ValueChanged<_NotifFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(_NotifFilter f, String label) {
      final active = value == f;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: active ? AppTeal.main.withValues(alpha: t.isDark ? 0.22 : 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: active ? AppTeal.main : t.textFaint,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          tab(_NotifFilter.all, mainText(context, "الكل")),
          tab(_NotifFilter.follows, mainText(context, "المتابعة")),
          tab(_NotifFilter.activity, mainText(context, "التفاعل")),
        ],
      ),
    );
  }
}

/// بطاقة إشعار واحدة - مؤشر غير مقروء كشريط جانبي رفيع بدل خلفية
/// كاملة، ولون شارة النوع يتغيّر حسب نوع الإشعار.
class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.uid, required this.item});

  final String uid;
  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final t = _ProfileTheme.of(context);
    final n = item;
    final typeColor = _notificationColor(n.type);

    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _dismissNotification(uid, n.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
      ),
      child: Material(
        color: t.cardBg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openNotification(context, n),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: t.isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
              ),
              // ===== مؤشر غير مقروء: شريط جانبي بدل خلفية كاملة =====
              gradient: !n.read
                  ? LinearGradient(
                colors: [typeColor.withValues(alpha: 0.06), Colors.transparent],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                stops: const [0, 0.35],
              )
                  : null,
            ),
            child: Row(
              children: [
                if (!n.read)
                  Container(
                    width: 3,
                    height: 44,
                    margin: const EdgeInsets.only(right: 2),
                    decoration: BoxDecoration(
                      color: typeColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  )
                else
                  const SizedBox(width: 5),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            _StackedNotifAvatars(item: n, size: 44),

                          ],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _NotificationActor(
                        userId: n.actorId,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                n.displayMessage,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: t.textMuted, fontSize: 13, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(n.time ?? '', style: TextStyle(color: t.textFaint, fontSize: 11)),
                      ],
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





class _CommunityEmptyState extends StatelessWidget {
  const _CommunityEmptyState({required this.onCreatePost});

  final VoidCallback onCreatePost;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [const Color(0xFFCCFBF1), const Color(0xFFBAE6FD).withValues(alpha: 0.9)
                  ],
                ),
              ),
              child: const Icon(Icons.forum_rounded, color: Color(0xFF0F766E), size: 42),
            ),
            const SizedBox(height: 18),
            Text(
              mainText(context, "Noting to show."),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              mainText(context, "كن أول من يبدأ نقاشاً جامعياً مع زملائك."),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF0891B2)]),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0891B2).withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: onCreatePost,
                icon: const Icon(Icons.add_rounded),
                label:  Text(mainText(context, "أنشئ منشوراً")),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

