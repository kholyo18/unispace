part of '../../main.dart';

final followRevision = ValueNotifier<int>(0);


class _FollowListSheet extends StatefulWidget {
  const _FollowListSheet({
    required this.ownerId,
    required this.isFollowers,
    required this.isSelf,
  });

  final String ownerId;
  final bool isFollowers;
  final bool isSelf;

  @override
  State<_FollowListSheet> createState() => _FollowListSheetState();
}

class _FollowListSheetState extends State<_FollowListSheet> {
  final _search = TextEditingController();
  String _query = '';
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _listError;
  int? _nextOffset;
  bool _truncated = false;
  int _generation = 0;
  final Set<String> _busyIds = {};
  late bool _showFollowers = widget.isFollowers;

  @override
  void initState() {
    super.initState();
    _refresh();
    blockedListRevision.addListener(_refresh);
  }

  @override
  void dispose() {
    blockedListRevision.removeListener(_refresh);
    _search.dispose();
    super.dispose();
  }

  void _refresh() { _loadPage(reset: true); }

  Future<void> _loadPage({bool reset = false}) async {
    if (!reset && (_loading || _nextOffset == null)) return;
    final generation = ++_generation;
    final me = FirebaseAuth.instance.currentUser?.uid;
    final offset = reset ? 0 : _nextOffset!;
    setState(() {
      _loading = true;
      _listError = null;
      if (reset) { _items = []; _nextOffset = null; _truncated = false; }
    });
    try {
      final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('readFollowList')
              .call<Map<String, dynamic>>({
        'userId': widget.ownerId, 'kind': _showFollowers ? 'followers' : 'following', 'offset': offset,
      });
      final rows = response.data['items'];
      if (rows is! List) throw const FormatException('Invalid list response');
      final items = rows.map((r) => Map<String, dynamic>.from(r as Map)).toList();
      if (items.any((r) => r['id'] is! String || r['name'] is! String)) {
        throw const FormatException('Invalid list member');
      }
      if (!mounted || generation != _generation) return;
      if (FirebaseAuth.instance.currentUser?.uid != me) {
        setState(() { _items = []; _loading = false; _listError = mainText(context, "أعد فتح القائمة بعد تسجيل الدخول."); });
        return;
      }
      setState(() {
        final merged = {for (final item in _items) item['id']: item,
          for (final item in items) item['id']: item};
        _items = merged.values.toList()
          ..sort((a,b) =>
            ((b['createdAtMs'] as num?) ?? 0)
              .compareTo((a['createdAtMs'] as num?) ?? 0));
        _nextOffset = response.data['nextOffset'] as int?;
        _truncated = response.data['truncated'] == true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        // Clear previously loaded identities if access has changed or cannot be confirmed.
        _items = []; _nextOffset = null; _loading = false;
        _listError = e is FirebaseFunctionsException && e.code == 'permission-denied'
            ? mainText(context, "هذه القائمة خاصة وفق إعدادات صاحب الحساب.")
            : mainText(context, "تعذر عرض القائمة. قد تكون غير متاحة؛ حاول مجددًا.");
      });
    }
  }

  Future<void> _applyFollow(
      {required String id, required String name,
    String? photo, required bool follow}) async {
    if (_busyIds.contains(id)) return;
    final row = _items.firstWhere((r) => r['id'] == id);
    final pending = row['pending'] == true;
    if (!follow && !pending) {
      final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title:  Text(mainText(ctx, "إلغاء المتابعة؟")), content: Text(mainText(ctx, "لن يظهر {0} في قائمة المتابَعين.", <Object?>[name])),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child:  Text(mainText(ctx, "إلغاء"))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child:  Text(mainText(ctx, "إلغاء المتابعة")))
                ],
              ));
      if (ok != true || !mounted) return;
    }
    if (!mounted || _busyIds.contains(id)) return;
    setState(() => _busyIds.add(id));
    try {
      await _manageFollow(pending ? 'cancel' : (follow ? 'follow' : 'unfollow'), id);
      if (mounted) await _loadPage(reset: true);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(mainText(context, "تعذر تحديث المتابعة. حاول مرة أخرى."))));
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  void _openUser(String id, String name, String? photo) {
    Navigator.pop(context);
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me != null && me == id) {
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
          initialName: name,
          initialPhotoUrl: photo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _ProfileTheme.of(context);
    final me = FirebaseAuth.instance.currentUser?.uid;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.94,
        expand: false,
        builder: (context, sc) {
          return Material(
            color: t.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            clipBehavior: Clip.antiAlias,
            child: Column(
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
                const SizedBox(height: 14),

                // ===== Segmented switch عصري (Followers / Following) =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _FollowSegmentedSwitch(
                    t: t,
                    showFollowers: _showFollowers,
                    onChanged: (v) {
                      if (_showFollowers == v) return;
                      setState(() => _showFollowers = v);
                      _refresh();
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // ===== حقل البحث العصري =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _FollowSearchField(
                    t: t,
                    controller: _search,
                    query: _query,
                    onChanged: (v) =>
                        setState(() => _query = v.trim().toLowerCase()),
                    onClear: () {
                      _search.clear();
                      setState(() => _query = '');
                    },
                  ),
                ),
                const SizedBox(height: 6),

                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (_loading && _items.isEmpty) {
                        return ListView.builder(itemCount: 6, itemBuilder: (_, __) => _FollowTileSkeleton(t: t));
                      }
                      if (_listError != null) {
                        return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(_listError!, textAlign: TextAlign.center),
                          TextButton(onPressed: _refresh, child:  Text(mainText(context, "إعادة المحاولة"))),
                        ]));
                      }
                      final docs = _items;
                      final items = docs.where((d) => _query.isEmpty ||
                          (d['name'] as String)
                                  .toLowerCase()
                                  .contains(_query))
                          .toList();
                      if (docs.isEmpty && _nextOffset == null) {
                        return Column(children: [
                          Expanded(child: _FollowEmptyState(t: t, isFollowers: _showFollowers)),
                          if (_truncated)  Text(mainText(context, "وصلت إلى حد العرض الحالي لهذه القائمة.")),
                          TextButton(onPressed: _refresh, child:  Text(mainText(context, "تحديث القائمة"))),
                        ]);
                      }
                      if (items.isEmpty && _nextOffset == null) {
                        return Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(mainText(context, "لا توجد نتائج ضمن الحسابات المحمّلة"), style: TextStyle(color: t.textFaint)),
                            TextButton(onPressed: _refresh, child:  Text(mainText(context, "تحديث القائمة"))),
                          ]),
                        );
                      }

                      return ListView.separated(
                        controller: sc,
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                        itemCount: items.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 2),
                        itemBuilder: (context, i) {
                          if (i == items.length) {
                            return Column(children: [
                              if (_nextOffset != null) TextButton(
                                onPressed: _loading ? null : () => _loadPage(),
                                child: Text(_loading ? mainText(context, "جارٍ التحميل…") : mainText(context, "تحميل المزيد")),
                              ),
                              if (_truncated)  Text(mainText(context, "وصلت إلى حد العرض الحالي لهذه القائمة.")),
                              TextButton(onPressed: _refresh, child:  Text(mainText(context, "تحديث القائمة"))),
                              if (_query.isNotEmpty)  Text(mainText(context, "البحث يشمل الحسابات المحمّلة فقط.")),
                            ]);
                          }
                          final d = items[i];
                          final id = d['id'] as String;
                          final name = d['name'] as String;
                          final photo = d['photoUrl'] as String?;
                          final isMe = me != null && me == id;
                          final iFollow = d['iFollow'] == true;
                          final followsMe = d['followsMe'] == true;

                          return _FollowUserTile(
                            userId: id,
                            name: name,
                            photoUrl: photo,
                            t: t,
                            isMe: isMe,
                            iFollow: iFollow,
                            pending: d['pending'] == true,
                            busy: _busyIds.contains(id),
                            followsMe: followsMe,
                            onTap: () => _openUser(id, name, photo),
                            onFollow: () => _applyFollow(
                              id: id,
                              name: name,
                              photo: photo,
                              follow: true,
                            ),
                            onUnfollow: () => _applyFollow(
                              id: id,
                              name: name,
                              photo: photo,
                              follow: false,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ==================== Segmented Switch (Followers / Following) ====================

class _FollowSegmentedSwitch extends StatelessWidget {
  const _FollowSegmentedSwitch({
    required this.t,
    required this.showFollowers,
    required this.onChanged,
  });

  final _ProfileTheme t;
  final bool showFollowers;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment:
            showFollowers ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTeal.main,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: AppTeal.main.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _segTab(
                  label: 'Followers',
                  selected: showFollowers,
                  onTap: () => onChanged(true),
                ),
              ),
              Expanded(
                child: _segTab(
                  label: mainText(context, "Following"),
                  selected: !showFollowers,
                  onTap: () => onChanged(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _segTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: selected ? Colors.white : t.textMuted,
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

// ==================== حقل البحث العصري ====================

class _FollowSearchField extends StatelessWidget {
  const _FollowSearchField({
    required this.t,
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final _ProfileTheme t;
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: t.isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(color: t.textPrimary, fontSize: 14.5),
        decoration: InputDecoration(
          hintText: mainText(context, "ابحث بالاسم..."),
          hintStyle: TextStyle(color: t.textFaint, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: t.textFaint, size: 21),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
            icon: Icon(Icons.close_rounded, color: t.textFaint, size: 18),
            onPressed: onClear,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
          isDense: true,
        ),
      ),
    );
  }
}

// ==================== حالة فارغة عصرية ====================

class _FollowEmptyState extends StatelessWidget {
  const _FollowEmptyState({required this.t, required this.isFollowers});

  final _ProfileTheme t;
  final bool isFollowers;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTeal.main.withValues(alpha: t.isDark ? 0.14 : 0.08),
              ),
              child: Icon(
                isFollowers
                    ? Icons.people_outline_rounded
                    : Icons.person_add_alt_1_outlined,
                size: 32,
                color: AppTeal.foreground(context),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isFollowers ? mainText(context, "لا يوجد متابعون بعد") : mainText(context, "لا تتابع أحدًا بعد"),
              style: TextStyle(
                color: t.textPrimary,
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isFollowers
                  ? mainText(context, "عندما يتابعك أحد، سيظهر هنا")
                  : mainText(context, "ابحث عن أشخاص وابدأ بمتابعتهم"),
              textAlign: TextAlign.center,
              style: TextStyle(color: t.textFaint, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== Skeleton أثناء التحميل ====================

class _FollowTileSkeleton extends StatelessWidget {
  const _FollowTileSkeleton({required this.t});
  final _ProfileTheme t;

  Color get _base => t.isDark
      ? Colors.white.withValues(alpha: 0.08)
      : Colors.black.withValues(alpha: 0.06);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: _base, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 13,
                  decoration: BoxDecoration(
                    color: _base,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 70,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _base,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 72,
            height: 30,
            decoration: BoxDecoration(
              color: _base,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowUserTile extends StatelessWidget {
  const _FollowUserTile({
    required this.userId,
    required this.name,
    required this.photoUrl,
    required this.t,
    required this.isMe,
    required this.iFollow,
    this.pending = false,
    this.busy = false,
    required this.followsMe,
    required this.onTap,
    required this.onFollow,
    required this.onUnfollow,
  });

  final String userId;
  final String name;
  final String? photoUrl;
  final _ProfileTheme t;
  final bool isMe;
  final bool iFollow;
  final bool pending;
  final bool busy;
  final bool followsMe;
  final VoidCallback onTap;
  final VoidCallback onFollow;
  final VoidCallback onUnfollow;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            PublicProfilePhoto(
              userId: userId,
              fallbackUrl: photoUrl,
              size: 44,
              radius: 22,
              iconSize: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
            ),
            if (!isMe) _actionButton(context),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context) {
    if (iFollow || pending) {
      return OutlinedButton(
        onPressed: busy ? null : onUnfollow,
        style: OutlinedButton.styleFrom(
          foregroundColor: t.textPrimary,
          side: BorderSide(color: t.cardBorder),
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: const Size(0, 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          pending ? mainText(context, "إلغاء الطلب") : mainText(context, "متابَع"),
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
      );
    }

    final label = followsMe ? mainText(context, "ردّ المتابعة") : mainText(context, "متابعة");
    return FilledButton(
      onPressed: busy ? null : onFollow,
      style: FilledButton.styleFrom(
        backgroundColor: t.isDark ? Colors.white : Colors.black,
        foregroundColor: t.isDark ? Colors.black : Colors.white,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        minimumSize: const Size(0, 32),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}



DocumentReference<Map<String, dynamic>> _followRequestRef(
    String toUid,
    String fromUid,
    ) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(toUid)
      .collection('follow_requests')
      .doc(fromUid);
}

Future<bool> isUserPrivate(String userId) async {
  if (userId.isEmpty) return true;
  try {
    final profile = await PublicProfileService.load(userId);
    return ProfilePrivacy.fromDocument(profile).isPrivate;
  } catch (e) {
    debugPrint('isUserPrivate failed: $e');
  }
  return true;
}

Future<Set<String>> loadFollowingIds() async {
  final me = FirebaseAuth.instance.currentUser?.uid;
  if (me == null) return {};
  try {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(me)
        .collection('following')
        .get();
    return snap.docs.map((d) => d.id).toSet();
  } catch (e) {
    debugPrint('loadFollowingIds failed: $e');
    return {};
  }
}

Future<void> syncAuthorPrivateOnPosts({
  required String uid,
  required bool isPrivate,
}) async {
  await syncOwnPostPrivacy(uid);
}
Future<bool> canInteractWithAuthor({
  required String authorId,
  required String audience, // everyone | followers | mutual | none
}) async {
  final me = FirebaseAuth.instance.currentUser?.uid;
  if (me == null) return false;
  if (authorId.isEmpty || me == authorId) return true;

  switch (audience) {
    case 'none':
      return false;
    case 'everyone':
      return true;
    case 'followers':
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(authorId)
          .collection('followers')
          .doc(me)
          .get();
      return snap.exists;
    case 'mutual':
      final a = await FirebaseFirestore.instance
          .collection('users')
          .doc(authorId)
          .collection('followers')
          .doc(me)
          .get();
      if (!a.exists) return false;
      final b = await FirebaseFirestore.instance
          .collection('users')
          .doc(me)
          .collection('followers')
          .doc(authorId)
          .get();
      return b.exists;
    default:
      return true;
  }
}

Future<bool> canSeeAudienceList({
  required String ownerId,
  required String visibility,
}) async {
  return canInteractWithAuthor(authorId: ownerId, audience: visibility);
}

Future<bool> canRepostAuthor(String authorId) async {
  final me = FirebaseAuth.instance.currentUser?.uid;
  if (me == null) return false;
  try {
    final profile = await PublicProfileService.load(authorId);
    if (FirebaseAuth.instance.currentUser?.uid != me || profile['canViewContent'] != true) return false;
    if (me == authorId) return true;
    final who = (profile['privacy'] as Map)['whoCanRepost'];
    if (who == 'everyone') return true;
    if (profile['isFollowing'] != true) return false;
    if (who == 'followers') return true;
    if (who == 'mutual') {
      final follower = await FirebaseFirestore.instance.collection('users')
          .doc(me)
          .collection('followers')
          .doc(authorId)
          .get();
      return FirebaseAuth.instance.currentUser?.uid == me && follower.exists;
    }
    return false;
  } catch (_) {
    return false;
  }
}

Future<bool> canCommentOnAuthor(String authorId) async {
  final me = FirebaseAuth.instance.currentUser?.uid;
  if (me == null) return false;
  if (me == authorId) return true;
  try {
    final session = PublicProfileService.viewerSession;
    final profile = await PublicProfileService.load(authorId);
    if (profile['canViewContent'] != true) return false;
    final who = (profile['privacy'] as Map)['whoCanComment'];
    if (!['everyone', 'followers', 'mutual'].contains(who)) return false;
    final allowed = await canInteractWithAuthor(authorId: authorId, audience: who as String);
    return PublicProfileService.viewerSession == session && allowed;
  } catch (e) {
    debugPrint('canCommentOnAuthor failed: $e');
    return false;
  }
}
Future<void> _manageFollow(String action, String userId) async {
  if (FirebaseAuth.instance.currentUser == null) throw StateError('Sign in first');
  final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
      .httpsCallable('manageFollow')
      .call<Map<String, dynamic>>({'action': action, 'userId': userId});
  if (!['none', 'pending', 'following'].contains(result.data['state'])) {
    throw StateError('Follow operation not confirmed');
  }
  followRevision.value++;
}

Future<void> setFollowing(
    {required String me, required String targetId,
  required String targetName, String? targetPhotoUrl, required String myName,
  String? myPhotoUrl, required bool follow}) async {
  if (FirebaseAuth.instance.currentUser?.uid != me) throw StateError('Account changed');
  await _manageFollow(follow ? 'follow' : 'unfollow', targetId);
}

Future<void> cancelFollowRequest(String targetId) => _manageFollow('cancel', targetId);

Future<void> acceptFollowRequest(
        {required String fromId, required String fromName,
  String? fromPhotoUrl}) => _manageFollow('accept', fromId);

Future<void> rejectFollowRequest(String fromId) => _manageFollow('reject', fromId);

DocumentReference<Map<String, dynamic>> _blockedAccountRef(
    String ownerId,
    String targetId,
    ) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(ownerId)
      .collection('blocked_accounts')
      .doc(targetId);
}



Future<bool> isAccountBlocked(String targetId) async {
  final me = FirebaseAuth.instance.currentUser?.uid;
  if (me == null || targetId.isEmpty || me == targetId) return false;
  try {
    final doc = await _blockedAccountRef(me, targetId).get();
    return doc.exists;
  } catch (e) {
    debugPrint('isAccountBlocked failed: $e');
    return false;
  }
}
Future<bool> isBlockedByAccount(String otherId) async {
  final me = FirebaseAuth.instance.currentUser?.uid;
  if (me == null || otherId.isEmpty || me == otherId) return false;

  try {
    final reverse = await FirebaseFirestore.instance
        .collection('users')
        .doc(me)
        .collection('blocked_by')
        .doc(otherId)
        .get();
    if (reverse.exists) return true;
  } catch (e) {
    debugPrint('blocked_by read failed: $e');
  }

  try {
    final theirs = await FirebaseFirestore.instance
        .collection('users')
        .doc(otherId)
        .collection('blocked_accounts')
        .doc(me)
        .get();
    if (theirs.exists) return true;
  } catch (e) {
    debugPrint('their blocked_accounts read failed: $e');
  }

  return false;
}
Future<Set<String>> loadHiddenAuthorIds() async {
  final me = FirebaseAuth.instance.currentUser?.uid;
  if (me == null) return {};
  final ids = <String>{};
  try {
    final blocked = await FirebaseFirestore.instance
        .collection('users')
        .doc(me)
        .collection('blocked_accounts')
        .get();
    for (final d in blocked.docs) {
      ids.add(d.id);
    }
  } catch (e) {
    debugPrint('load blocked_accounts failed: $e');
  }
  try {
    final blockedBy = await FirebaseFirestore.instance
        .collection('users')
        .doc(me)
        .collection('blocked_by')
        .get();
    for (final d in blockedBy.docs) {
      ids.add(d.id);
    }
  } catch (e) {
    debugPrint('load blocked_by failed: $e');
  }
  return ids;
}

Future<void> blockAccount(
    {required String targetId, required String targetName,
  String? targetPhotoUrl}) async {
  await _manageFollow('block', targetId);
  blockedListRevision.value++;
}

Future<void> unblockAccount(String targetId) async {
  await _manageFollow('unblock', targetId);
  blockedListRevision.value++;
}




class FollowRequestsScreen extends StatefulWidget {
  const FollowRequestsScreen({super.key});
  @override
  State<FollowRequestsScreen> createState() => _FollowRequestsScreenState();
}
class _FollowRequestsScreenState extends State<FollowRequestsScreen> {
  String? _uid;
  late Future<Set<String>> _blocked;
  StreamSubscription<User?>? _auth;
  int _revision = 0;
  void _load() {
    _blocked = _loadNotificationBlockedIds(_uid);
    unawaited(_blocked.then<void>((_) {}, onError: (Object error, StackTrace stack) {}));
  }
  void _refresh() { if (mounted) setState(() { _revision++; _load(); }); }
  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _load();
    blockedListRevision.addListener(_refresh);
    _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user?.uid != _uid) { _uid = user?.uid; _refresh(); }
    });
  }
  @override
  void dispose() { _auth?.cancel(); blockedListRevision.removeListener(_refresh); super.dispose(); }
  Widget _retry() => Center(child: TextButton(onPressed: _refresh,
    child:  Text(mainText(context, "تعذر تحميل طلبات المتابعة. إعادة المحاولة"))));

  @override
  Widget build(BuildContext context) {
    final t = _ProfileTheme.of(context);
    final me = _uid;

    return Scaffold(
      backgroundColor: t.pageBg,
      appBar: AppBar(
        title:  Text(mainText(context, "طلبات المتابعة")),
        backgroundColor: t.pageBg,
        surfaceTintColor: Colors.transparent,
      ),
      body: me == null
          ? Center(
        child: Text(mainText(context, "سجّل الدخول أولاً"), style: TextStyle(color: t.textFaint)),
      )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        key: ValueKey('$me:$_revision'),
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(me)
            .collection('follow_requests')
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return _retry();
          if (snap.connectionState == ConnectionState.waiting || !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return FutureBuilder<Set<String>>(
            future: _blocked,
            builder: (context, blockedSnap) {
              if (blockedSnap.hasError) return _retry();
              if (blockedSnap.connectionState != ConnectionState.done || !blockedSnap.hasData) return const Center(child: CircularProgressIndicator());
              final blocked = blockedSnap.data!;
              final visible = snap.data!.docs.where((d) {
                final id = (d.data()['uid'] ?? d.id).toString();
                return !blocked.contains(id);
              }).toList();

              if (visible.isEmpty) {
                return Center(
                  child: Text(
                    mainText(context, "لا توجد طلبات"),
                    style: TextStyle(color: t.textFaint),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                itemCount: visible.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, i) {
                  final d = visible[i].data();
                  final id = (d['uid'] ?? visible[i].id).toString();
                  final name = (d['name'] ?? mainText(context, "طالب UniSpace")).toString();
                  final photo = d['photoUrl']?.toString();
                  return _FollowRequestTile(
                    userId: id,
                    name: name,
                    photoUrl: photo,
                    t: t,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _FollowRequestTile extends StatelessWidget {
  const _FollowRequestTile({
    required this.userId,
    required this.name,
    required this.photoUrl,
    required this.t,
  });

  final String userId;
  final String name;
  final String? photoUrl;
  final _ProfileTheme t;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserProfileScreen(
              userId: userId,
              initialName: name,
              initialPhotoUrl: photoUrl,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            LiveAuthorPhoto(
              userId: userId,
              fallbackUrl: photoUrl,
              size: 44,
              radius: 22,
              iconSize: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            TextButton(
              onPressed: () => rejectFollowRequest(userId),
              child: Text(
                mainText(context, "رفض"),
                style: TextStyle(color: t.textMuted, fontWeight: FontWeight.w700),
              ),
            ),
            FilledButton(
              onPressed: () => acceptFollowRequest(
                fromId: userId,
                fromName: name,
                fromPhotoUrl: photoUrl,
              ),
              style: FilledButton.styleFrom(foregroundColor: Colors.white,
                backgroundColor: AppTeal.main,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child:  Text(
                mainText(context, "قبول"),
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
//======================================================================
// BLOCK & REPORT
//======================================================================
