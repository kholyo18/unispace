part of '../../main.dart';

class _ProfileTheme {
  final bool isDark;
  final Color pageBg;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textMuted;
  final Color textFaint;
  final Color avatarRing;

  const _ProfileTheme._({
    required this.isDark,
    required this.pageBg,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textMuted,
    required this.textFaint,
    required this.avatarRing,
  });

  factory _ProfileTheme.of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return _ProfileTheme._(
      isDark: dark,
      pageBg: Theme.of(context).scaffoldBackgroundColor,
      cardBg: dark ? UniSpaceColors.darkSurface : UniSpaceColors.lightSurface,
      cardBorder: dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
      textPrimary: UniSpaceColors.ink(dark),
      textMuted: dark ? UniSpaceColors.darkMuted : UniSpaceColors.lightMuted,
      textFaint: UniSpaceColors.muted(dark),
      avatarRing: dark ? UniSpaceColors.darkSurface : UniSpaceColors.lightSurface,
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  String? pinnedPostId;
  String? profileImageUrl;
  String? coverImageUrl;

  bool _uploadingProfile = false;
  bool _uploadingCover = false;

  String userName = 'KAOSU DS';
  String accountUsername = '';
  String department = '';
  String email = 'kaosu@email.com';
  String mood = '🚀 Feeling motivated';

  String uni = '';
  String fac = '';
  String clas = '';
  String section = '';
  String firstName = '';
  String lastName = '';
  String birthDate = '';
  String residence = '';
  String phone = '';
  String gender = '';
  String work = '';
  String otherInfo = '';
  String studyLevel = '';
  String github = '';
  String linkedin = '';
  String portfolio = '';

  final List<String> followingUsers = [];
  final List<String> followersUsers = []; // NEW: قائمة المتابعين

  int _followersCount = 0;
  int _followingCount = 0;
  int _postsCount = 0;

    File? profileImage;
  File? coverImage;

  static const double _coverHeight = 168;
  static const double _avatarRadius = 46;
  final ScrollController _scrollController = ScrollController();
  double _appBarOpacity = 0;

  late final TabController _tabController;
  List<_ProfileCommentHit> _userComments = [];
  bool _loadingComments=true;
  String? _commentsError;
  int _commentsGeneration = 0;
  bool _showDisliked = false;

// NEW: حذف منشور من داخل صفحة البروفايل (نفس منطق onDelete فالخلاصة الرئيسية)
  Future<void> _deleteUserPost(String postId) => _deleteOwnPost(postId);

  Future<void> _pickProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final cropped = await _cropImage(image.path, isCircle: true);
    if (cropped == null || !mounted) return;

    final file = File(cropped.path);
    setState(() {
      profileImage = file;
      _uploadingProfile = true;
    });

    await _uploadProfileAsset(file: file, isProfile: true);

    if (mounted) setState(() => _uploadingProfile = false);
  }

  Future<void> _pickCoverImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final cropped = await _cropImage(image.path, isCircle: false);
    if (cropped == null || !mounted) return;

    final file = File(cropped.path);
    setState(() {
      coverImage = file;
      _uploadingCover = true;
    });

    await _uploadProfileAsset(file: file, isProfile: false);

    if (mounted) setState(() => _uploadingCover = false);
  }
  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _loadSavedProfileImages();
    _scrollController.addListener(_onScroll);
    _tabController = TabController(length: 5, vsync: this);
    _loadUserComments();
    _loadFollowCounts();
    followRevision.addListener(_loadFollowCounts);
  }

  Future<void> _setPinnedPost(String? postId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      if (postId == null)
        'pinnedPostId': FieldValue.delete()
      else
        'pinnedPostId': postId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (mounted) setState(() => pinnedPostId = postId);
  }

  Future<void> _loadSavedProfileImages() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final authPhoto = user.photoURL?.trim();
    final authName = user.displayName?.trim();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();

      if (!mounted) return;

      final saved = data?['profileImageUrl']?.toString().trim();

      String? resolvedPhoto;
      if (saved != null && saved.isNotEmpty) {
        resolvedPhoto = saved;
      } else if (authPhoto != null && authPhoto.isNotEmpty) {
        resolvedPhoto = authPhoto;
        // مزامنة صورة Google إلى Firestore مرة واحدة
        FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'profileImageUrl': authPhoto,
          'updatedAt': FieldValue.serverTimestamp(),

        }, SetOptions(merge: true));
      }

      setState(() {
        profileImageUrl = resolvedPhoto;
        coverImageUrl = data?['coverImageUrl']?.toString();

        final account = AccountProfileFields(data);
        accountUsername = account.username;
        department = account.department;
        firstName = data?['firstName']?.toString() ?? firstName;
        lastName = data?['lastName']?.toString() ?? lastName;
        birthDate = account.birthDate;
        residence = data?['residence']?.toString() ?? residence;
        phone = data?['phone']?.toString() ?? phone;
        gender = data?['gender']?.toString() ?? gender;
        work = data?['work']?.toString() ?? work;
        otherInfo = data?['otherInfo']?.toString() ?? otherInfo;
        studyLevel = account.studyLevel;
        github = data?['github']?.toString() ?? github;
        linkedin = data?['linkedin']?.toString() ?? linkedin;
        portfolio = data?['portfolio']?.toString() ?? portfolio;
        pinnedPostId = data?['pinnedPostId']?.toString();
        uni = data?['university']?.toString() ?? uni;
        fac = account.faculty;
        section = data?['major']?.toString() ?? section;
        mood = data?['mood']?.toString() ?? mood;
        // الاسم المعروض
        final fn = (data?['firstName']?.toString() ?? '').trim();
        final ln = (data?['lastName']?.toString() ?? '').trim();
        if (fn.isNotEmpty || ln.isNotEmpty) {
          userName = [fn, ln].where((e) => e.isNotEmpty).join(' ');
        } else if (authName != null &&
            authName.isNotEmpty &&
            userName == 'KAOSU DS') {
          userName = authName;
        }

        final authEmail = user.email?.trim();
        if (authEmail != null && authEmail.isNotEmpty) {
          email = authEmail;
        }
      });
    } catch (e) {
      debugPrint('Load profile images failed: $e');
      if (!mounted) return;
      if (authPhoto != null && authPhoto.isNotEmpty) {
        setState(() => profileImageUrl = authPhoto);
        // محاولة الحفظ حتى بعد فشل القراءة
        try {
          await FirebaseFirestore.instance.collection('users')
              .doc(user.uid)
              .set({
            'profileImageUrl': authPhoto,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (_) {}
      }
    }
  }

  Future<void> _editMood() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MoodEditSheet(initial: mood),
    );

    if (!mounted || result == null) return;

    setState(() => mood = result);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'mood': result,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Save mood failed: $e');
    }
  }
  // NEW: يفتح واجهة الاقتصاص (بحال إنستغرام/فيسبوك) بعد اختيار الصورة
  Future<CroppedFile?> _cropImage(String sourcePath, {required bool isCircle}) {
    return ImageCropper().cropImage(
      sourcePath: sourcePath,
      compressFormat: ImageCompressFormat.jpg,
      aspectRatio: isCircle
          ? const CropAspectRatio(ratioX: 1, ratioY: 1)
          : const CropAspectRatio(ratioX: 16, ratioY: 9),
      compressQuality: 85,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: isCircle ? mainText(context, "ضبط صورة الحساب") : mainText(context, "ضبط صورة الغلاف"),
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          backgroundColor: Colors.black,
          lockAspectRatio: true,
          cropStyle: isCircle ? CropStyle.circle : CropStyle.rectangle, // FIX: هنا دابا
        ),
        IOSUiSettings(
          title: isCircle ? mainText(context, "ضبط صورة الحساب") : mainText(context, "ضبط صورة الغلاف"),
          aspectRatioLockEnabled: true,
          cropStyle: isCircle ? CropStyle.circle : CropStyle.rectangle, // FIX: وهنا
        ),
      ],
    );
  }

  // NEW: رفع الصورة المقتصة لـ Firebase Storage، وحفظ الرابط فـ Firestore
  Future<void> _uploadProfileAsset({
    required File file,
    required bool isProfile,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final fileName = isProfile ? 'profile.jpg' : 'cover.jpg';
    final field = isProfile ? 'profileImageUrl' : 'coverImageUrl';
    final ref = FirebaseStorage.instance.ref('users/$uid/$fileName');

    try {
      final size = await file.length();
      if (size <= 0 || size > 20 * 1024 * 1024) {
        throw  _MediaUploadError(mainText(context, "يجب أن تكون الصورة غير فارغة وألا تتجاوز 20 ميغابايت"));
      }
      if (FirebaseAuth.instance.currentUser?.uid != uid) throw StateError(mainText(context, "تغيّر الحساب"));
      await StorageUploadService.putFile(ref, file, SettableMetadata(contentType: 'image/jpeg'));
      var url = StorageUploadService.locator(ref);
      if (isProfile) {
        final sep = url.contains('?') ? '&' : '?';
        url = '$url${sep}v=${DateTime.now().millisecondsSinceEpoch}';
      }

      if (FirebaseAuth.instance.currentUser?.uid != uid) throw StateError(mainText(context, "تغيّر الحساب"));
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        field: url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (isProfile) {
        AuthorProfiles.put(uid, url);
        await propagateAuthorToPosts(uid: uid, photoUrl: url);
      }

      if (!mounted) return;
      setState(() {
        if (isProfile) {
          profileImageUrl = url;
        } else {
          coverImageUrl = url;
        }
      });
    } catch (e) {
      debugPrint('Upload ${isProfile ? "profile" : "cover"} image failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is _MediaUploadError ? e.message : mainText(context, "تعذر رفع الصورة، حاول مجددًا"))),
      );
    }
  }

  void _editProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        name: userName,
        mood: mood,
        uni: uni,
        fac: fac,
        clas: clas,
        section: section,
        onSave: (n, m, u, f, c, s) async {
          setState(() {
            userName = n;
            mood = m;
            uni = u;
            fac = f;
            clas = c;
            section = s;
          });
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid == null) return;
          AuthorProfiles.putName(uid, n.trim());
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'displayName': n.trim(),
            'mood': m,
            'university': u,
            'faculty': f,
            'department': c,
            'major': s,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          await propagateAuthorToPosts(uid: uid, authorName: n.trim());
        },
      ),
    );
  }
  void _showShareSheet(_ProfileTheme t) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final link = 'unispace://user/$uid';

    Future<void> copyLink() async {
      await Clipboard.setData(ClipboardData(text: link));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(mainText(context, "تم نسخ الرابط"))),
      );
    }

    Future<void> shareProfile() async {
      await Share.share(
        '$userName\n$link',
        subject: userName,
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final sheetBg =
        t.isDark ? UniSpaceColors.darkSurface : UniSpaceColors.ivory;
        final groupBg = t.isDark ? UniSpaceColors.darkContainer : UniSpaceColors.lightSurface;
        final divider = t.isDark
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.black.withValues(alpha: 0.08);

        Widget row({
          required String label,
          required IconData icon,
          required VoidCallback onTap,
        }) {
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
                          color: t.textPrimary,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(icon, size: 22, color: t.textPrimary),
                  ],
                ),
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
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: t.isDark
                              ? Colors.white.withValues(alpha: 0.28)
                              : Colors.black.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ColoredBox(
                        color: groupBg,
                        child: Column(
                          children: [
                            row(
                              label: mainText(ctx, "Copy link"),
                              icon: Icons.link_rounded,
                              onTap: () {
                                Navigator.pop(ctx);
                                copyLink();
                              },
                            ),
                            Divider(
                              height: 0.5,
                              thickness: 0.5,
                              indent: 16,
                              endIndent: 16,
                              color: divider,
                            ),
                            row(
                              label: mainText(ctx, "Share to"),
                              icon: Icons.ios_share_rounded,
                              onTap: () {
                                Navigator.pop(ctx);
                                shareProfile();
                              },
                            ),
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
      },
    );
  }


  void _showUserListSheet(
      {required String title, required List<String> users}) {
    final t = _ProfileTheme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: t.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: t.cardBorder, borderRadius: BorderRadius.circular(999)),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(title, style: TextStyle(color: t.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              Expanded(
                child: users.isEmpty
                    ? Center(
                  child: Text(mainText(context, "noResultsFound"), style: TextStyle(color: t.textFaint, fontSize: 13)),
                )
                    : ListView.builder(
                  controller: scrollController,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final u = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: t.cardBorder,
                        child: Icon(Icons.person, color: t.textMuted),
                      ),
                      title: Text(u, style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w600)),
                      onTap: () {
                        // TODO: افتح بروفايل المستخدم
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.dispose();
    followRevision.removeListener(_loadFollowCounts);
    super.dispose();
  }

  Future<void> _loadFollowCounts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final followers = await userRef.collection('followers').count().get();
      final following = await userRef.collection('following').count().get();
      if (!mounted) return;
      setState(() {
        _followersCount = followers.count ?? 0;
        _followingCount = following.count ?? 0;
      });
    } catch (e) {
      debugPrint('load follow counts failed: $e');
    }
  }

  void _showFollowersSheet() {
    _openFollowListSheet(isFollowers: true);
  }

  void _showFollowingSheet() {
    _openFollowListSheet(isFollowers: false);
  }

  void _openFollowListSheet({required bool isFollowers}) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FollowListSheet(
        ownerId: uid,
        isFollowers: isFollowers,
        isSelf: true,
      ),
    );
  }
  Future<void> _loadUserComments() async {
    if (!mounted) return;
    final generation = ++_commentsGeneration;
    final viewer = FirebaseAuth.instance.currentUser?.uid;
    final target = FirebaseAuth.instance.currentUser?.uid;
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

  Widget _reactionFilterButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final t = _ProfileTheme.of(context);
    return Expanded(
      child: Material(
        color: selected ? AppTeal.main : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? AppTeal.main
                    : t.cardBorder,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? Colors.white : t.textPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : t.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  void _openProfileSearch(_ProfileTheme t) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileSearchSheet(
        t: t,
        authorId: uid,
        authorName: userName,
      ),
    );
  }

  Widget _postsTab(_ProfileTheme t) {
    return TabBar(
      padding: const EdgeInsetsDirectional.only(start: 12),
      splashFactory: NoSplash.splashFactory,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
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
        Tab(text: mainText(context, "وسائط")),
        Tab(text: mainText(context, "إعادة نشر")),
        Tab(text: mainText(context, "تعليقات")),
        Tab(text: mainText(context, "إعجابات")),
      ],
    );
  }
  void _onScroll() {
    final topInset = MediaQuery.paddingOf(context).top;
    final coverH = _coverHeight + topInset;
    final opacity =
    (_scrollController.offset / (coverH - kToolbarHeight)).clamp(0.0, 1.0);
    // حدّث فقط عند تغيّر واضح — وبدون لمس الـ TabBar
    if ((opacity - _appBarOpacity).abs() > 0.03) {
      setState(() => _appBarOpacity = opacity);
    }
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
  Widget _metaRow(_ProfileTheme t) {
    final academic = [uni, fac, if (studyLevel.isNotEmpty) studyLevel]
        .where((e) => e.trim().isNotEmpty)
        .join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (academic.isNotEmpty || work.isNotEmpty)
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              if (academic.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school_outlined, size: 15, color: t.textFaint),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        academic,
                        style: TextStyle(
                          color: t.textFaint,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              if (work.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.work_outline_rounded, size: 15, color: t.textFaint),
                    const SizedBox(width: 4),
                    Text(
                      work,
                      style: TextStyle(
                        color: t.textFaint,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),

        if (github.isNotEmpty || linkedin.isNotEmpty || portfolio.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (github.isNotEmpty)
                _SocialLinkPill(
                  t: t,
                  icon: Icons.code_rounded,
                  label: 'GitHub',
                  onTap: () => _openLink(github),
                ),
              if (linkedin.isNotEmpty)
                _SocialLinkPill(
                  t: t,
                  icon: Icons.work_outline_rounded,
                  label: 'LinkedIn',
                  onTap: () => _openLink(linkedin),
                ),
              if (portfolio.isNotEmpty)
                _SocialLinkPill(
                  t: t,
                  icon: Icons.language_rounded,
                  label: mainText(context, "Portfolio"),
                  onTap: () => _openLink(portfolio),
                ),
            ],
          ),
        ],
      ],
    );
  }
  List<_ProfileMediaItem> _mediaFromPosts(List<_Post> posts) {
    final items = <_ProfileMediaItem>[];
    for (final p in posts) {
      for (final path in p.imagePaths) {
        if (path.trim().isNotEmpty) {
          items.add(_ProfileMediaItem(
            post: p,
            path: path.trim(),
            isVideo: false,
          ));
        }
      }
      for (final path in p.videoPaths) {
        if (path.trim().isNotEmpty) {
          items.add(_ProfileMediaItem(
            post: p,
            path: path.trim(),
            isVideo: true,
          ));
        }
      }
    }
    return items;
  }
  Widget _metaIconButton(
      _ProfileTheme t, {
        required IconData icon,
        required String tooltip,
        required VoidCallback onTap,
      }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: t.isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 18, color: AppTeal.foreground(context)),
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
  // NEW: واجهة معلومات الحساب — بدّلت بيها الـ Drawer الجانبي
  void _showAccountInfoSheet() {
    final user = FirebaseAuth.instance.currentUser;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccountInfoPanel(
        username: accountUsername,
        department: department,
        firstName: firstName,
        lastName: lastName,
        birthDate: birthDate,
        residence: residence,
        uni: uni,
        fac: fac,
        major: section,
        work: work,
        phone: phone,
        email: user?.email ?? email,
        gender: gender,
        otherInfo: otherInfo,
        studyLevel: studyLevel,
        github: github,
        linkedin: linkedin,
        portfolio: portfolio,
        onSaved: (v) {
          setState(() {
            department = v.department;
            firstName = v.firstName;
            lastName = v.lastName;
            birthDate = v.birthDate;
            residence = v.residence;
            uni = v.uni;
            fac = v.fac;
            section = v.major;
            work = v.work;
            phone = v.phone;
            gender = v.gender;
            otherInfo = v.otherInfo;
            studyLevel = v.studyLevel;
            github = v.github;
            linkedin = v.linkedin;
            portfolio = v.portfolio;
            if (v.firstName.isNotEmpty || v.lastName.isNotEmpty) {
              userName = [v.firstName, v.lastName]
                  .where((e) => e.trim().isNotEmpty)
                  .join(' ');
            }
          });
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null && userName.trim().isNotEmpty) {
            AuthorProfiles.putName(uid, userName.trim());
            propagateAuthorToPosts(uid: uid, authorName: userName.trim(), useFullName: true);
          }
          }),
    );
  }
  void _openCvEditor() {
    ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text(mainText(context, "واجهة السيرة قريباً"))),
    );
    // لاحقاً: Navigator.push(... CvEditorScreen ...);
  }
  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
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
            UniSpaceColors.forest,
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final t = _ProfileTheme.of(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final coverH = _coverHeight + topInset;
    final iconColor =
    Color.lerp(Colors.white, t.textPrimary, _appBarOpacity)!;
    final btnBg = Color.lerp(
      Colors.black.withValues(alpha: 0.35),
      Colors.transparent,
      _appBarOpacity,
    )!;

    return AppGuide(
      id: 'profile',
      steps: const [
        GuideStep('profile.header', 'profile.header'),
        GuideStep('profile.info', 'profile.info'),
        GuideStep('profile.statistics', 'profile.statistics'),
      ],
      child: Scaffold(
      backgroundColor: t.pageBg,
      body: Stack(
        children: [
          _AuthorizedProfilePostsBuilder(
            userId: FirebaseAuth.instance.currentUser?.uid,
            builder: (context, all, waiting, refreshPosts) {
              final originals = all.where((p) => !p.isRepost).toList();
              final reposts = all.where((p) => p.isRepost).toList();

              _Post? pinned;
              if (pinnedPostId != null && pinnedPostId!.isNotEmpty) {
                for (final p in originals) {
                  if (p.id == pinnedPostId) {
                    pinned = p;
                    break;
                  }
                }
              }
              final mediaItems = _mediaFromPosts(originals);


              return NestedScrollView(
                controller: _scrollController,
                headerSliverBuilder: (context, inner) => [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: coverH + _avatarRadius + 8,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                height: coverH,
                                child: GestureDetector(
                                  onTap: _pickCoverImage,
                                  child: ClipRRect(
                                    borderRadius:
                                    const BorderRadius.vertical(
                                      bottom: Radius.circular(4),
                                    ),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        if (coverImage != null)
                                          Image.file(
                                            coverImage!,
                                            fit: BoxFit.cover,
                                          )
                                        else if (coverImageUrl != null)
                                          ProtectedImage.network(
                                            coverImageUrl!,
                                            fit: BoxFit.cover,
                                            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                              if (wasSynchronouslyLoaded || frame != null) return child;
                                              return _ShimmerBlock(t: t); // ممتد كامل
                                            },
                                            errorBuilder: (_, __, ___) => _coverFallback(),
                                          )
                                        else
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  AppTeal.main,
                                                  UniSpaceColors.forest,
                                                  const Color(0xFF1A237E),
                                                ],
                                              ),
                                            ),
                                            child: Center(
                                              child: Icon(
                                                Icons.add_a_photo_outlined,
                                                size: 32,
                                                color: Colors.white
                                                    .withValues(alpha: 0.7),
                                              ),
                                            ),
                                          ),
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: 0,
                                          height: 48,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withValues(
                                                    alpha: 0.25,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (_uploadingCover)
                                          const ColoredBox(
                                            color: Colors.black38,
                                            child: Center(
                                              child:
                                              CircularProgressIndicator(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 18,
                                top: coverH - _avatarRadius,
                                child: GuideTarget(id: 'profile.header', child: GestureDetector(
                                  onTap: _pickProfileImage,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: t.pageBg,
                                        width: 4,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.18),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: _avatarRadius,
                                      backgroundColor: t.cardBorder,
                                      backgroundImage: profileImage != null
                                          ? FileImage(profileImage!)
                                      as ImageProvider
                                          : (profileImageUrl != null
                                          ? ProtectedCachedNetworkImageProvider(
                                        profileImageUrl!,
                                      )
                                          : null),
                                      child: (profileImage == null &&
                                          profileImageUrl == null)
                                          ? Icon(
                                        Icons.person,
                                        size: _avatarRadius,
                                        color: t.textMuted,
                                      )
                                          : null,
                                    ),
                                  ),
                                )),
                              ),
                              Positioned(
                                left: 18 + _avatarRadius * 2 - 6,
                                top: coverH + _avatarRadius - 28,
                                child: GestureDetector(
                                  onTap: _pickProfileImage,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppTeal.main,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: t.pageBg,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: TextStyle(
                                  color: t.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                accountUsername.isEmpty ? '' : '@$accountUsername',
                                style: TextStyle(color: t.textFaint, fontSize: 15),
                              ),
                              const SizedBox(height: 2),

                              _metaRow(t),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: _editMood,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: t.isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : const Color(0xFFF0F4F5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          mood.trim().isEmpty
                                              ? mainText(context, "أضف شعوراً...")
                                              : mood,
                                          style: TextStyle(
                                            color: mood.trim().isEmpty
                                                ? t.textFaint
                                                : t.textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 14,
                                        color: t.textFaint,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: GuideTarget(id: 'profile.info', child: FilledButton.icon(
                                      onPressed: _showAccountInfoSheet,
                                      icon: const Icon(
                                        Icons.medical_information_outlined,
                                        size: 18,
                                      ),
                                      label:  Text(mainText(context, "Profile info")),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppTeal.main,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(12),
                                        ),
                                      ),
                                    )),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _openCvEditor,
                                      icon: const Icon(
                                        Icons.description_outlined,
                                        size: 18,
                                      ),
                                      label:  Text(mainText(context, "(CV) السيرة")),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: t.textPrimary,
                                        side: BorderSide(color: t.cardBorder),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                          child: GuideTarget(id: 'profile.statistics', child: Container(
                            decoration: BoxDecoration(
                              color: t.cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: t.cardBorder),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _StatColumn(
                                    count: _followersCount,
                                    label: 'Followers',
                                    onTap: _showFollowersSheet,
                                    t: t,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 32,
                                  color: t.cardBorder,
                                ),
                                Expanded(
                                  child: _StatColumn(
                                    count: _followingCount,
                                    label: mainText(context, "Following"),
                                    onTap: _showFollowingSheet,
                                    t: t,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 32,
                                  color: t.cardBorder,
                                ),
                                Expanded(
                                  child: _StatColumn(
                                    count: all.length,
                                    label: mainText(context, "Posts"),
                                    onTap: null,
                                    t: t,
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _ProfileTabsDelegate(
                      tabBar: _postsTab(t),
                      background: t.pageBg,
                    ),
                  ),
                ],
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    // 0 منشورات
                    waiting
                        ? const _ProfileTabLoading()
                        : _ProfilePostsPane(
                      posts: originals,
                      pinnedPost: pinned,
                      emptyLabel: mainText(context, "لا توجد منشورات بعد"),
                      emptyIcon: Icons.article_outlined,
                      t: t,
                      actionLabel: mainText(context, "أنشئ أول منشور"),
                      onAction: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                        );
                      },
                      onChanged: refreshPosts,
                      onSetPinned: _setPinnedPost,
                      currentPinnedId: pinnedPostId,
                    ),
                    // 1 وسائط
                    waiting
                        ? const _ProfileTabLoading()
                        : _ProfileMediaPane(items: mediaItems, t: t),
                    // 2 إعادة نشر
                    waiting
                        ? const _ProfileTabLoading()
                        : _ProfilePostsPane(
                      posts: reposts,
                      emptyLabel: mainText(context, "لا توجد إعادة نشر"),
                      emptyIcon: Icons.repeat_rounded,
                      t: t,
                      onChanged: refreshPosts,
                    ),
                    // 3 تعليقات
                    _ProfileCommentsPane(
                      loading: _loadingComments,
                      error: _commentsError,
                      onRetry: _loadUserComments,
                      comments: _userComments,
                      t: t,
                    ),
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                          child: Row(
                            children: [
                              _reactionFilterButton(
                                label: mainText(context, "إعجابات"),
                                icon: Icons.favorite_rounded,
                                selected: !_showDisliked,
                                onTap: () {
                                  if (_showDisliked) {
                                    setState(() => _showDisliked = false);
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              _reactionFilterButton(
                                label: mainText(context, "لم يعجبني"),
                                icon: Icons.heart_broken_rounded,
                                selected: _showDisliked,
                                onTap: () {
                                  if (!_showDisliked) {
                                    setState(() => _showDisliked = true);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _AuthorizedReactionPosts(
                            key: ValueKey(_showDisliked),
                            disliked: _showDisliked,
                            t: t,
                          ),
                        ),
                      ],
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
                      if (Navigator.of(context).canPop())
                        _appBarCircleButton(
                          icon: Icons.arrow_back,
                          color: iconColor,
                          bg: btnBg,
                          onTap: () => Navigator.of(context).maybePop(),
                        )
                      else
                        const SizedBox(width: 12),
                      Expanded(
                        child: Opacity(
                          opacity: _appBarOpacity,
                          child: Text(
                            userName,
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
                      _appBarCircleButton(
                        icon: Icons.ios_share_rounded,
                        color: iconColor,
                        bg: btnBg,
                        onTap: () => _showShareSheet(t),
                      ),
                      _appBarCircleButton(
                        icon: Icons.settings_outlined,
                        color: iconColor,
                        bg: btnBg,
                        onTap: _openSettings,
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
    ));
  }
}
class _SocialLinkPill extends StatelessWidget {
  const _SocialLinkPill({
    required this.t,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final _ProfileTheme t;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppTeal.main;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: accent.withValues(alpha: t.isDark ? 0.14 : 0.08),
            border: Border.all(
              color: accent.withValues(alpha: t.isDark ? 0.32 : 0.22),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: accent,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodEditSheet extends StatefulWidget {
  const _MoodEditSheet({required this.initial});

  final String initial;

  @override
  State<_MoodEditSheet> createState() => _MoodEditSheetState();
}

class _MoodEditSheetState extends State<_MoodEditSheet> {
  late final TextEditingController _ctrl;

  static const _presets = [
    '🚀 متحمس',
    '📚 أذاكر',
    '☕ استراحة',
    '😴 متعب',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _ProfileTheme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Material(
        color: t.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                const SizedBox(height: 14),
                Text(
                  mainText(context, "الشعور"),
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ctrl,
                  autofocus: true,
                  maxLength: 80,
                  maxLines: 2,
                  minLines: 1,
                  style: TextStyle(color: t.textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: mainText(context, "اكتب شعورك..."),
                    hintStyle: TextStyle(color: t.textFaint),
                    filled: true,
                    fillColor: t.isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : const Color(0xFFF2F4F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presets.map((s) {
                    return GestureDetector(
                      onTap: () => setState(() => _ctrl.text = mainText(context, s)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: t.isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : const Color(0xFFEEF1F4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          mainText(context, s),
                          style: TextStyle(
                            color: t.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 46,
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.pop(context, _ctrl.text.trim()),
                    style: FilledButton.styleFrom(foregroundColor: Colors.white,
                      backgroundColor: AppTeal.main,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:  Text(
                      mainText(context, "حفظ"),
                      style: TextStyle(fontWeight: FontWeight.w700),
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

class _AccountInfoValues {
  final String firstName, lastName, birthDate, residence;
  final String uni, fac, major, work, phone, email, gender, otherInfo;
  final String studyLevel, github, linkedin, portfolio, department;

  const _AccountInfoValues({
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.residence,
    required this.uni,
    required this.fac,
    required this.major,
    required this.work,
    required this.phone,
    required this.email,
    required this.gender,
    required this.otherInfo,
    required this.studyLevel,
    required this.department,
    required this.github,
    required this.linkedin,
    required this.portfolio,
  });
}

class _AccountInfoPanel extends StatefulWidget {
  const _AccountInfoPanel({
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.residence,
    required this.uni,
    required this.fac,
    required this.major,
    required this.work,
    required this.phone,
    required this.email,
    required this.gender,
    required this.otherInfo,
    required this.studyLevel,
    required this.department,
    required this.github,
    required this.linkedin,
    required this.portfolio,
    required this.onSaved,
  });

  final String firstName, lastName, birthDate, residence;
  final String uni, fac, major, work, phone, email, gender, otherInfo;
  final String studyLevel, github, linkedin, portfolio, department;
  final String username;
  final void Function(_AccountInfoValues values) onSaved;

  @override
  State<_AccountInfoPanel> createState() => _AccountInfoPanelState();
}

class _AccountInfoPanelState extends State<_AccountInfoPanel> {
  bool _editing = false;
  bool _saving = false;

  late final TextEditingController _department;
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _birthDate;
  late final TextEditingController _residence;
  late final TextEditingController _uni;
  late final TextEditingController _fac;
  late final TextEditingController _major;
  late final TextEditingController _work;
  late final TextEditingController _phone;
  late final TextEditingController _gender;
  late final TextEditingController _other;
  late final TextEditingController _studyLevel;
  late final TextEditingController _github;
  late final TextEditingController _linkedin;
  late final TextEditingController _portfolio;

  @override
  void initState() {
    super.initState();
    _department = TextEditingController(text: widget.department);
    _firstName = TextEditingController(text: widget.firstName);
    _lastName = TextEditingController(text: widget.lastName);
    _birthDate = TextEditingController(text: widget.birthDate);
    _residence = TextEditingController(text: widget.residence);
    _uni = TextEditingController(text: widget.uni);
    _fac = TextEditingController(text: widget.fac);
    _major = TextEditingController(text: widget.major);
    _work = TextEditingController(text: widget.work);
    _phone = TextEditingController(text: widget.phone);
    _gender = TextEditingController(text: widget.gender);
    _other = TextEditingController(text: widget.otherInfo);
    _studyLevel = TextEditingController(text: widget.studyLevel);
    _github = TextEditingController(text: widget.github);
    _linkedin = TextEditingController(text: widget.linkedin);
    _portfolio = TextEditingController(text: widget.portfolio);
  }

  @override
  void dispose() {
    _department.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _birthDate.dispose();
    _residence.dispose();
    _uni.dispose();
    _fac.dispose();
    _major.dispose();
    _work.dispose();
    _phone.dispose();
    _gender.dispose();
    _other.dispose();
    _studyLevel.dispose();
    _github.dispose();
    _linkedin.dispose();
    _portfolio.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_birthDate.text) ??
        DateTime(now.year - 20, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked != null) {
      _birthDate.text =
      '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    final values = _AccountInfoValues(
      department: _department.text.trim(),
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      birthDate: _birthDate.text.trim(),
      residence: _residence.text.trim(),
      uni: _uni.text.trim(),
      fac: _fac.text.trim(),
      major: _major.text.trim(),
      work: _work.text.trim(),
      phone: _phone.text.trim(),
      email: widget.email,
      gender: _gender.text.trim(),
      otherInfo: _other.text.trim(),
      studyLevel: _studyLevel.text.trim(),
      github: _github.text.trim(),
      linkedin: _linkedin.text.trim(),
      portfolio: _portfolio.text.trim(),
    );

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'department': values.department,
        'displayName': [values.firstName, values.lastName].where((v) => v.isNotEmpty).join(' '),
        'name': [values.firstName, values.lastName].where((v) => v.isNotEmpty).join(' '),
        'firstName': values.firstName,
        'lastName': values.lastName,
        'birthDate': values.birthDate,
        'residence': values.residence,
        'university': values.uni,
        'faculty': values.fac,
        'college': values.fac,
        'major': values.major,
        'work': values.work,
        'phone': values.phone,
        'gender': values.gender,
        'otherInfo': values.otherInfo,
        'studyLevel': values.studyLevel,
        'level': values.studyLevel,
        'academic': {'college': values.fac, 'major': values.major, 'level': values.studyLevel},
        'github': values.github,
        'linkedin': values.linkedin,
        'portfolio': values.portfolio,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      widget.onSaved(values);
      if (!mounted) return;
      setState(() {
        _editing = false;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(mainText(context, "تم الحفظ"))),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mainText(context, "تعذر الحفظ: {0}", <Object?>[e]))),
      );
    }
  }

  InputDecoration _dec(_ProfileTheme t, String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: t.isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.04),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      suffixIcon: suffix,
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final t = _ProfileTheme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: t.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // مقبض
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: t.cardBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              // رأس: عنوان + أزرار (ثابت، خارج القائمة)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
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
                    if (_editing) ...[
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => setState(() => _editing = false),
                        child: Text(
                          'cancel',
                          style: TextStyle(color: t.textMuted),
                        ),
                      ),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          minimumSize: const Size(0, 36),
                        ),
                        child: _saving
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text('save'),
                      ),
                    ] else
                      TextButton.icon(
                        onPressed: () => setState(() => _editing = true),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('edit'),
                      ),
                  ],
                ),
              ),
              Divider(height: 1, color: t.cardBorder),
              // المحتوى فقط — مع مساحة للكيبورد
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    32 + bottomInset,
                  ),
                  children: [
                    _AccountSection(
                      title: mainText(context, "شخصية"),
                      t: t,
                      children: [
                        _readOnly(t, mainText(context, "اسم المستخدم"), widget.username),
                        _field(t, mainText(context, "الاسم"), _firstName),
                        _field(t, mainText(context, "اللقب"), _lastName),
                        _birthField(t),
                        _genderField(t),
                        _field(t, mainText(context, "مكان الإقامة"), _residence),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _AccountSection(
                      title: mainText(context, "تواصل"),
                      t: t,
                      children: [
                        _readOnly(t, mainText(context, "البريد"), widget.email),
                        _field(t, mainText(context, "رقم الهاتف"), _phone,
                            keyboard: TextInputType.phone),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _AccountSection(
                      title: mainText(context, "دراسة"),
                      t: t,
                      children: [
                        _field(t, mainText(context, "الجامعة"), _uni),
                        _field(t, mainText(context, "الكلية"), _fac),
                        _field(t, mainText(context, "القسم"), _department),
                        _field(t, mainText(context, "التخصص"), _major),
                        _field(t, mainText(context, "المستوى / السنة"), _studyLevel),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _AccountSection(
                      title: mainText(context, "عمل وروابط"),
                      t: t,
                      children: [
                        _field(t, mainText(context, "العمل / الوظيفة"), _work),
                        _field(t, 'GitHub', _github,
                            keyboard: TextInputType.url),
                        _field(t, 'LinkedIn', _linkedin,
                            keyboard: TextInputType.url),
                        _field(t, mainText(context, "Portfolio"), _portfolio,
                            keyboard: TextInputType.url),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _AccountSection(
                      title: mainText(context, "أخرى"),
                      t: t,
                      children: [
                        _field(t, mainText(context, "معلومات إضافية"), _other, maxLines: 3),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _field(
      _ProfileTheme t,
      String label,
      TextEditingController c, {
        TextInputType keyboard = TextInputType.text,
        int maxLines = 1,
      }) {
    if (!_editing) {
      return _AccountFieldTile(
        label: label,
        value: c.text.trim().isEmpty ? '—' : c.text.trim(),
        t: t,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        maxLines: maxLines,
        style: TextStyle(color: t.textPrimary, fontSize: 14),
        decoration: _dec(t, label),
      ),
    );
  }

  Widget _readOnly(_ProfileTheme t, String label, String value) {
    return _AccountFieldTile(
      label: label,
      value: value.trim().isEmpty ? '—' : value,
      t: t,
    );
  }

  Widget _birthField(_ProfileTheme t) {
    if (!_editing) {
      return _AccountFieldTile(
        label: mainText(context, "تاريخ الميلاد"),
        value: _birthDate.text.trim().isEmpty ? '—' : _birthDate.text.trim(),
        t: t,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: _birthDate,
        readOnly: true,
        onTap: _pickBirthDate,
        style: TextStyle(color: t.textPrimary, fontSize: 14),
        decoration: _dec(
          t,
          mainText(context, "تاريخ الميلاد"),
          suffix: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
      ),
    );
  }

  Widget _genderField(_ProfileTheme t) {
    if (!_editing) {
      return _AccountFieldTile(
        label: mainText(context, "الجنس"),
        value: _gender.text.trim().isEmpty ? '—' : mainText(context, _gender.text.trim()),
        t: t,
      );
    }
    const options = ['ذكر', 'أنثى', 'أفضل عدم القول'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: options.contains(_gender.text) ? _gender.text : null,
        items: options
            .map((e) => DropdownMenuItem(value: e, child: Text(mainText(context, e))))
            .toList(),
        onChanged: (v) {
          if (v == null) return;
          setState(() => _gender.text = v);
        },
        decoration: _dec(t, mainText(context, "الجنس")),
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({
    required this.title,
    required this.children,
    required this.t,
  });

  final String title;
  final List<Widget> children;
  final _ProfileTheme t;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.cardBorder),
        color: t.isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: t.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _AccountFieldTile extends StatelessWidget {
  const _AccountFieldTile({
    required this.label,
    required this.value,
    required this.t,
  });

  final String label;
  final String value;
  final _ProfileTheme t;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: t.textFaint,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: t.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.count,
    required this.label,
    required this.onTap,
    required this.t,
  });

  final int count;
  final String label;
  final VoidCallback? onTap;
  final _ProfileTheme t;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: t.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: t.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final String name;
  final String mood;
  final String uni;
  final String fac;
  final String clas;
  final String section;
  final Function(String, String, String, String, String, String) onSave;

  const _EditProfileSheet(
      {required this.name,
        required this.mood,
        required this.uni,
        required this.fac,
        required this.clas,
        required this.section,
        required this.onSave});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late TextEditingController nameCtrl;
  late TextEditingController moodCtrl;
  late TextEditingController uniCtrl;
  late TextEditingController facCtrl;
  late TextEditingController clasCtrl;
  late TextEditingController sectionCtrl;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.name);
    moodCtrl = TextEditingController(text: widget.mood);
    uniCtrl = TextEditingController(text: widget.uni);
    facCtrl = TextEditingController(text: widget.fac);
    clasCtrl = TextEditingController(text: widget.clas);
    sectionCtrl = TextEditingController(text: widget.section);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
           Text(mainText(context, "تعديل الحساب"),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: S.of(context).name)),
          SizedBox(
            height: 15,
          ),
          TextField(
              controller: moodCtrl,
              decoration: InputDecoration(labelText: S.of(context).mood)),
          SizedBox(
            height: 15,
          ),
          TextField(
              controller: uniCtrl,
              decoration: InputDecoration(labelText: S.of(context).university)),
          SizedBox(
            height: 15,
          ),
          TextField(
              controller: facCtrl,
              decoration: InputDecoration(labelText: S.of(context).faculty)),
          SizedBox(
            height: 15,
          ),
          TextField(
              controller: clasCtrl,
              decoration: InputDecoration(labelText: S.of(context).department)),
          SizedBox(
            height: 15,
          ),
          TextField(
              controller: sectionCtrl,
              decoration: InputDecoration(labelText: S.of(context).major)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              widget.onSave(nameCtrl.text, moodCtrl.text, uniCtrl.text,
                  facCtrl.text, clasCtrl.text, sectionCtrl.text);
              Navigator.pop(context);
            },
            child:  Text(mainText(context, "حفظ")),
          ),
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const InfoRow({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  Future<void> _deactivateAccount(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:  Text(mainText(ctx, "تعطيل الحساب")),
        content:  Text(
          mainText(ctx, "سيتم إخفاء حسابك مؤقتاً. يمكنك طلب إعادة التفعيل لاحقاً عبر الدعم أو بتسجيل الدخول إن سمحت بذلك لاحقاً."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:  Text(mainText(ctx, "إلغاء")),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:  Text(mainText(ctx, "تعطيل")),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'accountStatus': 'disabled',
        'disabledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!context.mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mainText(context, "تعذر التعطيل: {0}", <Object?>[e]))),
      );
    }
  }
  Future<void> _reactivateAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'accountStatus': 'active',
        'reactivatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'security': {
          'frozen': false,
          'frozenAt': null,
        },
      }, SetOptions(merge: true));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(mainText(context, "تم إعادة تفعيل الحساب"))),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mainText(context, "تعذر إعادة التفعيل: {0}", <Object?>[e]))),
      );
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:  Text(mainText(ctx, "حذف الحساب نهائياً")),
        content: const Text(
          'سيتم حذف حسابك من التطبيق. المنشورات القديمة قد تبقى إلى أن تُنظَّف لاحقاً من الخادم.\n\n'
          'لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:  Text(mainText(ctx, "إلغاء")),
          ),
          FilledButton(
            style: FilledButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child:  Text(mainText(ctx, "متابعة")),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    // إعادة مصادقة قبل الحذف
    final reauthed = await _reauthForDelete(context, user);
    if (!reauthed || !context.mounted) return;

    final uid = user.uid;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );

    try {
      // 1) تأكيد أن المستخدم ما زال مسجّلاً بعد إعادة المصادقة
      final current = FirebaseAuth.instance.currentUser;
      if (current == null || current.uid != uid) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: mainText(context, "انتهت الجلسة. سجّل الدخول ثم أعد المحاولة."),
        );
      }

      // 2) حذف Auth أولاً — هذا يحرّر الإيميل
      // لا تستخدم ?. حتى لا يُتخطى الحذف بصمت
      await current.delete();

      // 3) بعد نجاح الحذف فقط: تنظيف اختياري لـ Firestore
      // قد يفشل لأن المستخدم لم يعد مصادقاً — هذا مقبول
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'accountStatus': 'deleted',
          'deletedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore cleanup after auth delete (optional): $e');
      }

      // 4) خروج محلي (Auth غالباً أصبح null بعد delete)
      try {
        await AuthSessionService.signOutFully();
      } catch (_) {}

      if (!context.mounted) return;
      Navigator.of(context).pop(); // إغلاق التحميل
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Text(
            mainText(context, "تم حذف الحساب. يمكنك إنشاء حساب جديد بنفس البريد."),
          ),
        ),
      );
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on FirebaseAuthException catch (e) {
      debugPrint('DELETE AUTH FAILED: ${e.code} ${e.message}');
      if (context.mounted) Navigator.of(context).pop();
      if (!context.mounted) return;

      // لا نوسُم الحساب deleted هنا — Auth ما زال موجوداً
      final msg = switch (e.code) {
        'requires-recent-login' =>
        mainText(context, "انتهت صلاحية الجلسة. سجّل الدخول من جديد ثم احذف الحساب مباشرة."),
        'user-not-found' =>
        mainText(context, "انتهت الجلسة. سجّل الدخول ثم أعد محاولة الحذف."),
        _ => mainText(context, "تعذر حذف الحساب ({0})", <Object?>[e.code]),
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e, st) {
      debugPrint('DELETE ACCOUNT FAILED: $e');
      debugPrintStack(stackTrace: st);
      if (context.mounted) Navigator.of(context).pop();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mainText(context, "تعذر حذف الحساب: {0}", <Object?>[e]))),
      );
    }
  }
  Future<bool> _reauthForDelete(BuildContext context, User user) async {
    final isPassword =
    user.providerData.any((p) => p.providerId == 'password');
    final isGoogle =
    user.providerData.any((p) => p.providerId == 'google.com');

    // ----- بريد + كلمة مرور -----
    if (isPassword && user.email != null) {
      final ctrl = TextEditingController();
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (ctx) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                 Text(
                  mainText(ctx, "أكد هويتك قبل الحذف"),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  mainText(ctx, "أدخل كلمة مرور {0}", <Object?>[user.email]),
                  style: TextStyle(color: Theme.of(ctx).hintColor),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  obscureText: true,
                  autofocus: true,
                  decoration:  InputDecoration(
                    labelText: mainText(ctx, "كلمة المرور"),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(ctx, true),
                  child:  Text(mainText(ctx, "تأكيد والحذف")),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child:  Text(mainText(ctx, "إلغاء")),
                ),
              ],
            ),
          );
        },
      );

      if (confirmed != true) {
        ctrl.dispose();
        return false;
      }

      try {
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: ctrl.text.trim(),
        );
        await FirebaseAuth.instance.currentUser!
            .reauthenticateWithCredential(cred);
        await SessionService.instance.initSession(user.uid);
        ctrl.dispose();
        return true;
      } on FirebaseAuthException catch (e) {
        ctrl.dispose();
        if (!context.mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.code == 'wrong-password' || e.code == 'invalid-credential'
                  ? mainText(context, "كلمة المرور غير صحيحة")
                  : mainText(context, "فشلت إعادة المصادقة"),
            ),
          ),
        );
        return false;
      } catch (_) {
        ctrl.dispose();
        return false;
      }
    }

    // ----- Google -----
    if (isGoogle) {
      try {
        final googleUser = await AuthSessionService.googleSignIn.signIn();
        if (googleUser == null) return false;
        final googleAuth = await googleUser.authentication;
        final cred = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.currentUser!
            .reauthenticateWithCredential(cred);
        await SessionService.instance.initSession(user.uid);
        return true;
      } catch (e) {
        if (!context.mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mainText(context, "تعذر تأكيد Google: {0}", <Object?>[e]))),
        );
        return false;
      }
    }

    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
        content: Text(mainText(context, "لا يمكن حذف هذا النوع من الحساب من التطبيق حالياً")),
      ),
    );
    return false;
  }


  Future<void> _rateApp(BuildContext context) async {
    final launched = await launchUrl(
      Uri.parse(AppLinks.storeUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(mainText(context, "تعذر فتح المتجر"))),
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:  Text(mainText(ctx, "تسجيل الخروج")),
        content:  Text(mainText(ctx, "هل تريد تسجيل الخروج من الحساب؟")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:  Text(mainText(ctx, "إلغاء")),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:  Text(mainText(ctx, "خروج")),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    await AuthSessionService.signOutFully(beforeSignOut: user == null ? null :
      () => SessionService.instance.revokeCurrentSession(user.uid));
    if (!context.mounted) return;
    // AuthGate يتكفّل بإظهار SignIn
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final app = UniSpaceApp.of(context);
    final user = FirebaseAuth.instance.currentUser;

    final displayName = user?.displayName?.trim();
    final email = user?.email?.trim();

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
          children: [
            _buildPageHeader(context),

            const SizedBox(height: 20),

            if (user != null) ...[
              _buildProfileCard(
                context,
                user: user,
                displayName: displayName,
                email: email,
              ),
              const SizedBox(height: 26),
            ],

            _buildSection(
              context,
              title: mainText(context, "الحساب والمجتمع"),
              icon: Icons.people_alt_outlined,
              children: [
                if (isCommunityModerator())
                  _settingsTile(
                    context,
                    icon: Icons.flag_outlined,
                    title: mainText(context, "مراجعة التبليغات"),
                    subtitle: mainText(context, "إدارة البلاغات الواردة من المجتمع"),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                          const CommunityReportsInboxScreen(),
                        ),
                      );
                    },
                  ),

                // _settingsTile(
                //   context,
                //   icon: Icons.block_rounded,
                //   title: 'الحسابات المحظورة',
                //   subtitle: 'عرض الحسابات التي قمت بحظرها',
                //   onTap: () {
                //     Navigator.of(context).push(
                //       MaterialPageRoute(
                //         builder: (_) => const BlockedUsersScreen(),
                //       ),
                //     );
                //   },
                // ),


              ],
            ),

            _buildSection(
              context,
              title: mainText(context, "المظهر واللغة"),
              icon: Icons.palette_outlined,
              children: [
                _settingsTile(
                  context,
                  icon: Icons.color_lens_outlined,
                  title: mainText(context, "السمة"),
                  subtitle: app._themeMode == ThemeMode.light
                      ? mainText(context, "فاتح")
                      : app._themeMode == ThemeMode.dark
                      ? mainText(context, "داكن")
                      : mainText(context, "حسب إعدادات النظام"),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _ThemeModeSheet(app: app),
                    );
                  },
                ),

                _settingsTile(
                  context,
                  icon: Icons.language_outlined,
                  title: mainText(context, "اللغة"),
                  subtitle: mainText(context, "تغيير لغة التطبيق"),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const _LanguageSheet(),
                    );
                  },
                ),
              ],
            ),

            _buildSection(
              context,
              title: mainText(context, "الخصوصية والأمان"),
              icon: Icons.shield_outlined,
              children: [
                _settingsTile(
                  context,
                  icon: Icons.security_outlined,
                  title: mainText(context, "الأمان والخصوصية"),
                  subtitle: mainText(context, "إدارة إعدادات الحساب والخصوصية"),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SecurityPrivacyScreen(),
                      ),
                    );
                  },
                ),

                _settingsTile(
                  context,
                  icon: Icons.notifications_none_rounded,
                  title: mainText(context, "الإشعارات"),
                  subtitle: mainText(context, "اختيار الإشعارات التي تريد استقبالها"),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                        const NotificationsSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            _buildSection(
              context,
              title: mainText(context, "عن التطبيق"),
              icon: Icons.apps_outlined,
              children: [
                _settingsTile(
                  context,
                  icon: Icons.star_outline_rounded,
                  title: mainText(context, "تقييم التطبيق"),
                  subtitle: mainText(context, "شاركنا رأيك حول UniSpace"),
                  showArrow: false,
                  onTap: () => _rateApp(context),
                ),

                _settingsTile(
                  context,
                  icon: Icons.share_outlined,
                  title: mainText(context, "مشاركة التطبيق"),
                  subtitle: mainText(context, "دع أصدقاءك يعرفون عن UniSpace"),
                  showArrow: false,
                  onTap: () => Share.share(AppLinks.shareMessage),
                ),

                _settingsTile(
                  context,
                  icon: Icons.info_outline_rounded,
                  title: mainText(context, "حول التطبيق"),
                  subtitle: mainText(context, "معلومات عن UniSpace وإصدار التطبيق"),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AboutScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            if (user != null)
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, snap) {
                  final status =
                  snap.data?.data()?['accountStatus']?.toString();
                  final disabled = status == 'disabled';
                  return _buildDangerSection(
                    context,
                    children: [
                      _settingsTile(
                        context,
                        icon: Icons.logout_rounded,
                        title: mainText(context, "تسجيل الخروج"),
                        subtitle: mainText(context, "الخروج من حسابك الحالي"),
                        iconColor: colors.error,
                        titleColor: colors.error,
                        showArrow: false,
                        onTap: () => _logout(context),
                      ),
                      if (disabled)
                        _settingsTile(
                          context,
                          icon: Icons.play_circle_outline_rounded,
                          title: mainText(context, "إلغاء التعطيل"),
                          subtitle: mainText(context, "إعادة إظهار حسابك والعودة للاستخدام"),
                          iconColor: const Color(0xFF16A34A),
                          showArrow: false,
                          onTap: () => _reactivateAccount(context),
                        )
                      else
                        _settingsTile(
                          context,
                          icon: Icons.pause_circle_outline_rounded,
                          title: mainText(context, "تعطيل الحساب"),
                          subtitle:
                          mainText(context, "إخفاء حسابك مؤقتًا مع إمكانية العودة لاحقًا"),
                          iconColor: Colors.orange.shade700,
                          showArrow: false,
                          onTap: () => _deactivateAccount(context),
                        ),
                      _settingsTile(
                        context,
                        icon: Icons.delete_forever_outlined,
                        title: mainText(context, "حذف الحساب"),
                        subtitle:
                        mainText(context, "حذف نهائي للبيانات ولا يمكن التراجع عنه"),
                        iconColor: colors.error,
                        titleColor: colors.error,
                        showArrow: false,
                        onTap: () => _deleteAccount(context),
                      ),
                    ],
                  );
                },
              )
            else
              _buildSection(
                context,
                title: mainText(context, "الحساب"),
                icon: Icons.account_circle_outlined,
                children: [
                  _settingsTile(
                    context,
                    icon: Icons.login_rounded,
                    title: mainText(context, "تسجيل الدخول"),
                    subtitle: mainText(context, "سجّل الدخول للوصول إلى حسابك"),
                    showArrow: false,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

            const SizedBox(height: 28),

            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 22,
                    color: colors.primary.withOpacity(.65),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'UniSpace',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colors.onSurface.withOpacity(.75),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '© ${DateTime.now().year}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: mainText(context, "رجوع"),
          color: colors.onSurface,
        ),

        const SizedBox(width: 4),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mainText(context, "الإعدادات"),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.4,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                mainText(context, "خصص تجربتك داخل UniSpace"),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.tune_rounded,
            color: colors.onPrimaryContainer,
          ),
        ),
      ],
    );
  }


  Widget _buildProfileCard(
      BuildContext context, {
        required User user,
        String? displayName,
        String? email,
      }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final name = displayName?.isNotEmpty == true
        ? displayName!
        : mainText(context, "مستخدم UniSpace");

    final userEmail = email?.isNotEmpty == true
        ? email!
        : mainText(context, "مرحبًا بك في UniSpace");

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            colors.primary,
            Color.alphaBlend(
              colors.secondary.withOpacity(.35),
              colors.primary,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 31,
            backgroundColor: Colors.white.withOpacity(.22),
            backgroundImage: user.photoURL != null
                ? ProtectedCachedNetworkImageProvider(user.photoURL!)
                : null,
            child: user.photoURL == null
                ? const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 34,
            )
                : null,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  userEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(.82),
                  ),
                ),
              ],
            ),
          ),

          Icon(
            Icons.verified_user_outlined,
            color: Colors.white.withOpacity(.88),
            size: 23,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, {
        required String title,
        required IconData icon,
        required List<Widget> children,
      }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: 4,
              end: 4,
              bottom: 10,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: colors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          _buildGroupCard(
            context,
            children: children,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerSection(
      BuildContext context, {
        required List<Widget> children,
      }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: 4,
              end: 4,
              bottom: 10,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: colors.error,
                ),
                const SizedBox(width: 8),
                Text(
                  mainText(context, "إجراءات الحساب"),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.error,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          Container(
            decoration: BoxDecoration(
              color: colors.errorContainer.withOpacity(.32),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.error.withOpacity(.12),
              ),
            ),
            child: Column(
              children: _addDividers(
                children,
                dividerColor: colors.error.withOpacity(.10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(
      BuildContext context, {
        required List<Widget> children,
      }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(.42),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.outlineVariant.withOpacity(.28),
        ),
      ),
      child: Column(
        children: _addDividers(
          children,
          dividerColor: colors.outlineVariant.withOpacity(.28),
        ),
      ),
    );
  }

  List<Widget> _addDividers(
      List<Widget> children, {
        required Color dividerColor,
      }) {
    final result = <Widget>[];

    for (var i = 0; i < children.length; i++) {
      result.add(children[i]);

      if (i < children.length - 1) {
        result.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: 72,
            endIndent: 16,
            color: dividerColor,
          ),
        );
      }
    }

    return result;
  }

  Widget _settingsTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
        Color? iconColor,
        Color? titleColor,
        bool showArrow = true,
      }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final resolvedIconColor = iconColor ?? colors.primary;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 7,
      ),
      minVerticalPadding: 8,
      leading: Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          color: resolvedIconColor.withOpacity(.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          size: 21,
          color: resolvedIconColor,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: titleColor ?? colors.onSurface,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.25,
          ),
        ),
      ),
      trailing: showArrow
          ? Icon(
        Icons.chevron_left_rounded,
        size: 22,
        color: colors.onSurfaceVariant,
      )
          : null,
    );
  }

}

Future<void> showBlockedAccountsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => const _BlockedAccountsSheet(),
  );
}

class _BlockedAccount {
  const _BlockedAccount({
    required this.id,
    required this.name,
    this.photoUrl,
  });
  final String id;
  final String name;
  final String? photoUrl;
}

class _BlockedAccountsSheet extends StatefulWidget {
  const _BlockedAccountsSheet();

  @override
  State<_BlockedAccountsSheet> createState() => _BlockedAccountsSheetState();
}

class _BlockedAccountsSheetState extends State<_BlockedAccountsSheet> {
  bool _loading = true;
  String? _error;
  List<_BlockedAccount> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _loading = false;
        _error = "يجب تسجيل الدخول أولاً";
        _items = [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('blocked_accounts')
          .get();

      final items = snap.docs.map((d) {
        final data = d.data();
        final name = (data['targetName'] ?? mainText(context, "حساب محظور")).toString().trim();
        return _BlockedAccount(
          id: d.id,
          name: name.isEmpty ? mainText(context, "حساب محظور") : name,
          photoUrl: data['targetPhotoUrl']?.toString(),
        );
      }).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      debugPrint('load blocked accounts failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = mainText(context, "تعذر تحميل الحسابات المحظورة");
      });
    }
  }

  Future<void> _unblock(_BlockedAccount account) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: Directionality.of(context),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title:  Text(mainText(ctx, "إلغاء الحظر؟")),
          content: Text(mainText(ctx, "ستظهر منشورات {0} في الفيد مجددًا.", <Object?>[account.name])),
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
    if (confirmed != true) return;

    try {
      if (FirebaseAuth.instance.currentUser?.uid != uid) return;
      await unblockAccount(account.id);
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != uid) return;
      setState(() => _items.removeWhere((e) => e.id == account.id));
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(mainText(context, "تم إلغاء حظر {0}", <Object?>[account.name]))),
      );
    } catch (e) {
      debugPrint('unblock failed: $e');
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != uid) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
         SnackBar(content: Text(mainText(context, "تعذر إلغاء الحظر"))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final h = MediaQuery.sizeOf(context).height * 0.72;

    return Directionality(
      textDirection: Directionality.of(context),
      child: SafeArea(
        child: SizedBox(
          height: h,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  mainText(context, "الحسابات المحظورة"),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(child: Text(mainText(context, _error!)))
                    : _items.isEmpty
                    ?  EmptyState(
                  icon: Icons.block_rounded,
                  title: mainText(context, "لا توجد حسابات محظورة"),
                )
                    : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) =>
                  const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final a = _items[i];
                    final photo = a.photoUrl?.trim() ?? '';
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: theme.colorScheme.primary
                            .withValues(alpha: 0.12),
                        backgroundImage: photo.startsWith('http')
                            ? ProtectedCachedNetworkImageProvider(photo)
                            : null,
                        child: photo.startsWith('http')
                            ? null
                            : Icon(
                          Icons.person_rounded,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        a.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      trailing: TextButton(
                        onPressed: () => _unblock(a),
                        child:  Text(mainText(context, "إلغاء الحظر")),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
