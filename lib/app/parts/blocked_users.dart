part of '../../main.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  bool _searchOpen = false;
  String _query = '';
  String? _busyId;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  CollectionReference<Map<String, dynamic>>? get _col {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('blocked_accounts');
  }

  void _toggleSearch() {
    setState(() => _searchOpen = !_searchOpen);
    if (_searchOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocus.requestFocus();
      });
    } else {
      _searchController.clear();
      _searchFocus.unfocus();
      setState(() => _query = '');
    }
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _prepare(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
      ) {
    final copy = [...docs];
    copy.sort((a, b) {
      final ta = a.data()['blockedAt'];
      final tb = b.data()['blockedAt'];
      if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
      return 0;
    });
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return copy;
    return copy.where((d) {
      final data = d.data();
      final name = (data['targetName'] ?? '').toString().toLowerCase();
      final user = (data['targetUsername'] ?? '').toString().toLowerCase();
      final id = (data['targetId'] ?? d.id).toString().toLowerCase();
      return name.contains(q) || user.contains(q) || id.contains(q);
    }).toList();
  }

  String _idOf(QueryDocumentSnapshot<Map<String, dynamic>> d) =>
      (d.data()['targetId'] ?? d.id).toString();

  String _nameOf(Map<String, dynamic> data) {
    final n = (data['targetName'] ?? '').toString().trim();
    return n.isEmpty ? mainText(context, "مستخدم") : n;
  }

  String? _userOf(Map<String, dynamic> data) {
    final u = (data['targetUsername'] ?? '').toString().trim();
    return u.isEmpty ? null : u;
  }

  String? _photoOf(Map<String, dynamic> data) {
    final p = (data['targetPhotoUrl'] ?? '').toString().trim();
    return p.isEmpty ? null : p;
  }

  Future<void> _confirmUnblock({
    required String userId,
    required String name,
  }) async {
    if (_busyId != null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: Directionality.of(context),
        child: AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title:  Text(
            mainText(ctx, "إلغاء الحظر؟"),
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            mainText(ctx, "ستظهر منشورات {0} في الفيد، ويمكنكما المتابعة مجدداً.", <Object?>[name]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:  Text(mainText(ctx, "إلغاء")),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:  Text(mainText(ctx, "إلغاء الحظر")),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busyId = userId);
    try {
      await unblockAccount(userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(mainText(context, "تم إلغاء حظر {0}", <Object?>[name]))));
    } catch (e) {
      debugPrint('unblock failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(mainText(context, "تعذر إلغاء الحظر، حاول مجددًا"))),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _ProfileTheme.of(context);
    final col = _col;

    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: t.pageBg,
        appBar: AppBar(
          backgroundColor: t.pageBg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 0,
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _searchOpen
                ? TextField(
              key: const ValueKey('blocked_search'),
              controller: _searchController,
              focusNode: _searchFocus,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: mainText(context, "ابحث في المحظورين"),
                border: InputBorder.none,
                hintStyle: TextStyle(color: t.textFaint),
              ),
              style: TextStyle(
                color: t.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            )
                : Text(
              mainText(context, "الحسابات المحظورة"),
              key: const ValueKey('blocked_title'),
              style: TextStyle(
                color: t.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          actions: [
            IconButton(
              tooltip: _searchOpen ? mainText(context, "إغلاق") : mainText(context, "بحث"),
              onPressed: _toggleSearch,
              icon: Icon(
                _searchOpen ? Icons.close_rounded : Icons.search_rounded,
                color: t.textPrimary,
              ),
            ),
          ],
        ),
        body: col == null
            ? Center(
          child: Text(
            mainText(context, "سجّل الدخول أولاً"),
            style: TextStyle(color: t.textFaint),
          ),
        )
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: col.snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(
                child: Text(
                  mainText(context, "تعذر تحميل القائمة"),
                  style: TextStyle(color: t.textFaint),
                ),
              );
            }
            if (!snap.hasData) {
              return const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              );
            }

            final all = snap.data!.docs;
            final docs = _prepare(all);

            if (all.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.block_rounded,
                          size: 40, color: t.textFaint),
                      const SizedBox(height: 12),
                      Text(
                        mainText(context, "لا توجد حسابات محظورة"),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (docs.isEmpty) {
              return Center(
                child: Text(
                  mainText(context, "لا نتائج مطابقة"),
                  style: TextStyle(color: t.textFaint),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
              itemCount: docs.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 72,
                color: t.cardBorder.withValues(alpha: 0.7),
              ),
              itemBuilder: (context, i) {
                final d = docs[i];
                final data = d.data();
                final id = _idOf(d);
                final name = _nameOf(data);
                return _BlockedUserRow(
                  userId: id,
                  name: name,
                  username: _userOf(data),
                  photoUrl: _photoOf(data),
                  busy: _busyId == id,
                  t: t,
                  onUnblock: () =>
                      _confirmUnblock(userId: id, name: name),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _BlockedUserRow extends StatelessWidget {
  const _BlockedUserRow({
    required this.userId,
    required this.name,
    required this.username,
    required this.photoUrl,
    required this.busy,
    required this.t,
    required this.onUnblock,
  });

  final String userId;
  final String name;
  final String? username;
  final String? photoUrl;
  final bool busy;
  final _ProfileTheme t;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      container: true,
      label: username == null
          ? name
          : mainText(context, "{0}، اسم المستخدم {1}", <Object?>[name, username]),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: t.cardBorder.withOpacity(.75),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: busy ? null : onUnblock,
              splashColor: colorScheme.primary.withOpacity(.06),
              highlightColor: colorScheme.primary.withOpacity(.03),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  14,
                  12,
                  12,
                  12,
                ),
                child: Row(

                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildAvatar(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildUserInfo(context),
                    ),
                    const SizedBox(width: 10),
                    _buildActionButton(context, colorScheme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        LiveAuthorPhoto(
          userId: userId,
          fallbackUrl: photoUrl,
          size: 48,
          radius: 24,
          iconSize: 22,
        ),
        Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(2),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: t.textFaint.withOpacity(.65),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.trim().isEmpty ? mainTextCurrent("مستخدم") : name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: t.textPrimary,
              fontSize: 15,
              height: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (username != null && username!.trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              '@${username!.trim()}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: t.textFaint,
                fontSize: 12.5,
                height: 1.1,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 7),
          _buildBlockedBadge(),
        ],
      ),
    );
  }

  Widget _buildBlockedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: t.textFaint.withOpacity(.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        mainTextCurrent("محظور"),
        style: TextStyle(
          color: t.textFaint,
          fontSize: 10.5,
          height: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, ColorScheme colorScheme) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: SizedBox(
        height: 38,
        child: FilledButton(
          onPressed: busy ? null : onUnblock,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            disabledBackgroundColor: colorScheme.primary.withOpacity(.65),
            disabledForegroundColor: colorScheme.onPrimary.withOpacity(.9),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            minimumSize: const Size(0, 38),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: busy
                ? const SizedBox(
              key: ValueKey('loading'),
              width: 17,
              height: 17,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                :  Row(
              key: ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_open_rounded,
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  mainTextCurrent("إلغاء الحظر"),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
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



// ============================================================================
// END OF FILE — UniSpace
// ============================================================================

Future<bool> isPeerUnavailable(String uid) {
  // A failed authorization check must never make an account look available.
  return PublicProfileService.isUnavailable(uid.trim());
}

Future<Set<String>> loadUnavailableUserIds(Iterable<String> ids) {
  // Bounded requests use the same authorized projection as the profile screen.
  return PublicProfileService.unavailableUserIds(ids);
}

bool isUserDocUnavailable(Map<String, dynamic>? data) {
  final status = data?['accountStatus']?.toString();
  if (status == 'disabled' || status == 'deleted') return true;
  final sec = data?['security'];
  return sec is Map && sec['frozen'] == true;
}


