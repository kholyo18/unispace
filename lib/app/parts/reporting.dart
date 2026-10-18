part of '../../main.dart';

enum CommunityReportType { post, comment, user }

class CommunityReportError implements Exception {
  const CommunityReportError(this.code);
  static const notSignedIn = 'not_signed_in';
  static const selfReport = 'self_report';
  static const invalidTarget = 'invalid_target';
  final String code;
  @override
  String toString() => 'CommunityReportError($code)';
}

String messageForCommunityReportError(Object error) {
  if (error is CommunityReportError) {
    switch (error.code) {
      case CommunityReportError.selfReport:
        return mainTextCurrent("لا يمكنك تبليغ محتواك");
      case CommunityReportError.notSignedIn:
        return mainTextCurrent("يجب تسجيل الدخول أولاً");
      case CommunityReportError.invalidTarget:
        return mainTextCurrent("تعذر تحديد المحتوى المبلَّغ عنه");
    }
  }
  if (error is FirebaseException) {
    return mainTextCurrent("تعذر إرسال التبليغ ({0})", <Object?>[error.code]);
  }
  return mainTextCurrent("تعذر إرسال التبليغ");
}

String severityForReportReason(String reasonId) {
  if (reasonId == 'academic/exam_leak' || reasonId == 'academic/cheating') {
    return 'P1';
  }
  if (reasonId.startsWith('academic')) return 'P2';
  switch (reasonId) {
    case 'hate':
    case 'harassment':
      return 'P1';
    case 'abuse':
    case 'sexual':
    case 'impersonation':
    case 'inappropriate_profile':
      return 'P2';
    case 'spam':
    case 'fake':
    case 'other':
    default:
      return 'P3';
  }
}




Future<bool> hasCommunityReport({
  required CommunityReportType type,
  required String targetId,
  String? parentId,
}) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) throw const CommunityReportError(CommunityReportError.notSignedIn);
  final id = targetId.trim();
  if (id.isEmpty) throw const CommunityReportError(CommunityReportError.invalidTarget);
  final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
      .httpsCallable('readOwnReportStatus')
      .call({'type': type.name, 'targetId': id, 'parentId': parentId?.trim()});
  if (FirebaseAuth.instance.currentUser?.uid != uid) {
    throw const CommunityReportError(CommunityReportError.notSignedIn);
  }
  final data = Map<String, dynamic>.from(response.data as Map);
  if (data['exists'] is! bool) throw StateError('Invalid report status response');
  return data['exists'] as bool;
}

String communityReportDocId({
  required String reporterId,
  required CommunityReportType type,
  required String targetId,
}) {
  switch (type) {
    case CommunityReportType.post:
      return '${reporterId}_$targetId';
    case CommunityReportType.user:
      return '${reporterId}_user_$targetId';
    case CommunityReportType.comment:
      return '${reporterId}_comment_$targetId';
  }
}

Future<T> runWithReportSpinner<T>(
    BuildContext context,
    Future<T> Function() task,
    ) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => const Center(
      child: CircularProgressIndicator(),
    ),
  );
  try {
    return await task();
  } finally {
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();
  }
}

Future<void> submitCommunityReport({
  required CommunityReportType type,
  required String targetId,
  String? parentId,
  String? ownerId,
  String? ownerName,
  required String reason,
  String details = '',
  Map<String, dynamic>? snapshot,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw const CommunityReportError(CommunityReportError.notSignedIn);
  }

  final id = targetId.trim();
  if (id.isEmpty) {
    throw const CommunityReportError(CommunityReportError.invalidTarget);
  }

  if (type == CommunityReportType.post) {
    await FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('submitPostReport')
        .call({'postId': id, 'reason': reason, 'details': details.trim()});
    return;
  }

  if (type == CommunityReportType.comment) {
    final postId = parentId?.trim();
    if (postId == null || postId.isEmpty) {
      throw const CommunityReportError(CommunityReportError.invalidTarget);
    }
    await FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('submitCommentReport')
        .call({'postId': postId, 'commentId': id, 'reason': reason, 'details': details.trim()
    });
    return;
  }
  await FirebaseFunctions.instanceFor(region: 'europe-west1')
      .httpsCallable('submitAccountReport')
      .call({'userId': id, 'reason': reason, 'details': details.trim()});
}

Map<String, dynamic> communityReportSnapshotFromPost(_Post post) {
  return {
    'title': post.title,
    'body': post.body,
    'authorName': post.author,
    'authorId': post.authorId,
    'tags': post.tags,
    'mediaUrls': <String>[...post.imagePaths, ...post.videoPaths],
    'createdAt': Timestamp.fromDate(post.createdAt),
  };
}

Map<String, dynamic> communityReportSnapshotFromComment(_Comment comment) {
  return {
    'text': comment.text,
    'authorName': comment.author,
    'authorId': comment.authorId,
    'mediaUrl': comment.mediaUrl,
    'mediaType': comment.mediaType,
    'createdAt': Timestamp.fromDate(comment.createdAt),
  };
}



class _ReportResult {
  const _ReportResult({required this.reasonId, required this.details});
  final String reasonId;
  final String details;
}

class _ReportReason {
  const _ReportReason(
      this.id,
      this.label,
      this.icon, {
        this.children = const <_ReportReason>[],
      });
  final String id;
  final String label;
  final IconData icon;
  final List<_ReportReason> children;
  bool get isGroup => children.isNotEmpty;
}

Future<_ReportResult?> showCommunityReportSheet(
    BuildContext context, {
      required CommunityReportType type,
      bool useRootNavigator = false,
    }) {
  return showModalBottomSheet<_ReportResult>(
    context: context,
    useRootNavigator: useRootNavigator,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: _ReportPostSheet(type: type),
      );
    },
  );
}

class _ReportPostSheet extends StatefulWidget {
  const _ReportPostSheet({this.type = CommunityReportType.post});
  final CommunityReportType type;

  @override
  State<_ReportPostSheet> createState() => _ReportPostSheetState();
}

class _ReportPostSheetState extends State<_ReportPostSheet> {
  static const _academicChildren = <_ReportReason>[
    _ReportReason(
      'academic/exam_leak',
      'تسريب امتحان أو فرض',
      Icons.lock_open_outlined,
    ),
    _ReportReason(
      'academic/cheating',
      'غش أو بيع حلول',
      Icons.menu_book_outlined,
    ),
    _ReportReason(
      'academic/misinfo',
      'معلومات دراسية مضللة',
      Icons.report_gmailerrorred_outlined,
    ),
  ];

  static const _contentReasons = <_ReportReason>[
    _ReportReason('abuse', 'إساءة أو تنمّر', Icons.mood_bad_outlined),
    _ReportReason('sexual', 'محتوى غير لائق', Icons.visibility_off_outlined),
    _ReportReason(
      'academic',
      'مخالفة أكاديمية',
      Icons.school_outlined,
      children: _academicChildren,
    ),
    _ReportReason('spam', 'إعلان أو سبام', Icons.campaign_outlined),
    _ReportReason(
      'impersonation',
      'انتحال شخصية',
      Icons.switch_account_outlined,
    ),
    _ReportReason('hate', 'خطاب كراهية', Icons.gavel_outlined),
    _ReportReason('other', 'أخرى', Icons.more_horiz_rounded),
  ];

  static const _accountReasons = <_ReportReason>[
    _ReportReason(
      'impersonation',
      'انتحال شخصية',
      Icons.switch_account_outlined,
    ),
    _ReportReason('fake', 'حساب وهمي أو مزيف', Icons.person_off_outlined),
    _ReportReason('harassment', 'مضايقة أو تنمّر', Icons.mood_bad_outlined),
    _ReportReason(
      'inappropriate_profile',
      'صورة أو معلومات غير لائقة',
      Icons.visibility_off_outlined,
    ),
    _ReportReason('spam', 'إعلانات أو سبام', Icons.campaign_outlined),
    _ReportReason('hate', 'خطاب كراهية', Icons.gavel_outlined),
    _ReportReason('other', 'أخرى', Icons.more_horiz_rounded),
  ];

  List<_ReportReason> get _reasons =>
      widget.type == CommunityReportType.user
          ? _accountReasons
          : _contentReasons;

  String? _selectedId;
  String? _expandedGroupId;
  final _detailsCtrl = TextEditingController();

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.type) {
      case CommunityReportType.comment:
        return mainText(context, "تبليغ عن التعليق");
      case CommunityReportType.user:
        return mainText(context, "تبليغ عن الحساب");
      case CommunityReportType.post:
        return mainText(context, "تبليغ عن المنشور");
    }
  }

  String get _privacyNote {
    switch (widget.type) {
      case CommunityReportType.comment:
        return mainText(context, "لن يعرف صاحب التعليق أنك بلّغت");
      case CommunityReportType.user:
        return mainText(context, "لن يعرف صاحب الحساب أنك بلّغت");
      case CommunityReportType.post:
        return mainText(context, "لن يعرف صاحب المنشور أنك بلّغت");
    }
  }

  bool get _needsDetails => _selectedId == 'other';
  bool get _showDetails =>
      _selectedId != null &&
          (_needsDetails || _selectedId!.startsWith('academic/'));

  bool get _canSubmit {
    if (_selectedId == null) return false;
    if (_needsDetails && _detailsCtrl.text.trim().isEmpty) return false;
    return true;
  }

  void _submit() {
    if (!_canSubmit) return;
    Navigator.pop(
      context,
      _ReportResult(
        reasonId: _selectedId!,
        details: _detailsCtrl.text.trim(),
      ),
    );
  }

  void _onTapReason(_ReportReason reason) {
    if (reason.isGroup) {
      setState(() {
        _expandedGroupId =
        _expandedGroupId == reason.id ? null : reason.id;
      });
      return;
    }
    setState(() {
      _selectedId = reason.id;
      if (!reason.id.startsWith('academic/')) {
        _expandedGroupId = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _privacyNote,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 14),
            for (final r in _reasons) ...[
              _reasonTile(theme, r),
              if (r.isGroup && _expandedGroupId == r.id)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 18),
                  child: Column(
                    children: [
                      for (final child in r.children)
                        _reasonTile(theme, child, nested: true),
                    ],
                  ),
                ),
            ],
            if (_showDetails) ...[
              const SizedBox(height: 4),
              TextField(
                controller: _detailsCtrl,
                maxLines: 3,
                maxLength: 300,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: _needsDetails
                      ? mainText(context, "اكتب سبب التبليغ...")
                      : mainText(context, "تفاصيل إضافية (اختياري)"),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _canSubmit ? _submit : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppTeal.main,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child:  Text(
                mainText(context, "إرسال التبليغ"),
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reasonTile(
      ThemeData theme,
      _ReportReason r, {
        bool nested = false,
      }) {
    final selected = _selectedId == r.id;
    final groupOpen = r.isGroup && _expandedGroupId == r.id;
    final groupHasChild = r.isGroup &&
        _selectedId != null &&
        _selectedId!.startsWith('${r.id}/');
    final active = selected || groupHasChild;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: active
            ? AppTeal.main.withValues(alpha: 0.12)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _onTapReason(r),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: nested ? 10 : 12,
            ),
            child: Row(
              children: [
                Icon(
                  r.icon,
                  size: nested ? 18 : 20,
                  color: active ? AppTeal.main : theme.hintColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    mainText(context, r.label),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: nested ? 13.5 : 14.5,
                      color: active
                          ? AppTeal.main
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  r.isGroup
                      ? (groupOpen
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded)
                      : (selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded),
                  size: 20,
                  color: active ? AppTeal.main : theme.hintColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}





Future<void> showReportSubmittedSheet(
    BuildContext context, {
      required CommunityReportType type,
      String? ownerId,
      required String ownerName,
      String? ownerPhotoUrl,
      bool useRootNavigator = false,
      bool alreadyReported = false,
      VoidCallback? onBlocked,
      VoidCallback? onUnfollowed,
    }) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: useRootNavigator,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return _ReportSubmittedSheet(
        type: type,
        ownerId: ownerId,
        ownerName: ownerName,
        ownerPhotoUrl: ownerPhotoUrl,
        alreadyReported: alreadyReported,
        onBlocked: onBlocked,
        onUnfollowed: onUnfollowed,
      );
    },
  );
}

class _ReportSubmittedSheet extends StatefulWidget {
  const _ReportSubmittedSheet({
    required this.type,
    required this.ownerName,
    this.ownerId,
    this.ownerPhotoUrl,
    this.alreadyReported = false,
    this.onBlocked,
    this.onUnfollowed,
  });

  final CommunityReportType type;
  final String? ownerId;
  final String ownerName;
  final String? ownerPhotoUrl;
  final bool alreadyReported;
  final VoidCallback? onBlocked;
  final VoidCallback? onUnfollowed;

  @override
  State<_ReportSubmittedSheet> createState() => _ReportSubmittedSheetState();
}

class _ReportSubmittedSheetState extends State<_ReportSubmittedSheet> {
  bool _following = false;
  bool _blocked = false;
  bool _busy = false;

  String get _hiddenHint {
    switch (widget.type) {
      case CommunityReportType.comment:
        return mainText(context, "أخفينا هذا التعليق عنك.");
      case CommunityReportType.user:
        return mainText(context, "يمكنك حظر الحساب حتى لا يظهر لك.");
      case CommunityReportType.post:
        return mainText(context, "أخفينا هذا المنشور عنك.");
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFollow();
  }

  Future<void> _loadFollow() async {
    final me = FirebaseAuth.instance.currentUser?.uid;
    final id = widget.ownerId?.trim();
    if (me == null || id == null || id.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(me)
          .collection('following')
          .doc(id)
          .get();
      if (!mounted) return;
      setState(() => _following = doc.exists);
    } catch (_) {}
  }

  Future<void> _block() async {
    final id = widget.ownerId?.trim();
    if (id == null || id.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await blockAccount(
        targetId: id,
        targetName: widget.ownerName,
        targetPhotoUrl: widget.ownerPhotoUrl,
      );
      if (!mounted) return;
      setState(() {
        _blocked = true;
        _following = false;
        _busy = false;
      });
      widget.onBlocked?.call();
    } catch (e) {
      debugPrint('post-report block failed: $e');
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(mainText(context, "تعذر حظر الحساب"))),
      );
    }
  }

  Future<void> _unfollow() async {
    final me = FirebaseAuth.instance.currentUser?.uid;
    final id = widget.ownerId?.trim();
    if (me == null || id == null || id.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await setFollowing(
        me: me,
        targetId: id,
        targetName: widget.ownerName,
        targetPhotoUrl: widget.ownerPhotoUrl,
        myName: '',
        follow: false,
      );
      if (!mounted) return;
      setState(() {
        _following = false;
        _busy = false;
      });
      widget.onUnfollowed?.call();
    } catch (e) {
      debugPrint('post-report unfollow failed: $e');
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(mainText(context, "تعذر إلغاء المتابعة"))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = widget.ownerName.trim().isEmpty
        ? mainText(context, "هذا الحساب")
        : widget.ownerName;
    final canAct = widget.ownerId != null &&
        widget.ownerId!.trim().isNotEmpty &&
        !_blocked;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: AppTeal.main, size: 48),
            const SizedBox(height: 12),
            Text(
              widget.alreadyReported ? mainText(context, "سبق أن بلّغت") : mainText(context, "تم إرسال التبليغ"),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              mainText(context, "لن يعرف {0} أنك بلّغت. {1}", <Object?>[name, _hiddenHint]),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
                height: 1.4,
              ),
            ),
            if (canAct) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _block,
                  icon: const Icon(Icons.block_rounded, size: 18),
                  label: Text(
                    mainText(context, "حظر {0}", <Object?>[name]),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFDC2626)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              if (_following) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _busy ? null : _unfollow,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child:  Text(
                      mainText(context, "إلغاء المتابعة"),
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTeal.main,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child:  Text(
                  mainText(context, "تم"),
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}









