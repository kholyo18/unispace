part of '../../main.dart';

class AppEndDrawer extends StatefulWidget {
  const AppEndDrawer({super.key});

  @override
  State<AppEndDrawer> createState() => _AppEndDrawerState();
}

class _AppEndDrawerState extends State<AppEndDrawer> {
  static const bool _showPrivacyAndContactInDrawer = false;
  static const _privacyHideMenuKey = 'privacy_hide_menu_item';
  bool _sendingOtp = false;
  int _otpCooldownSeconds = 0;
  Timer? _otpTimer;
  bool _hidePrivacyEntry = false;
  String? _coverImageUrl;
  bool _isLoggingOut = false;


  @override
  void initState() {
    super.initState();
    _loadPrivacyDrawerVisibility();
    _loadCover();
  }

  Future<void> _loadCover() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final url = doc.data()?['coverImageUrl']?.toString().trim();
      if (!mounted) return;
      if (url != null && url.isNotEmpty) {
        setState(() => _coverImageUrl = url);
      }
    } catch (_) {}
  }
  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
    );
  }

  Future<void> _loadPrivacyDrawerVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    final hidden = prefs.getBool(_privacyHideMenuKey) ?? false;
    if (!mounted) return;

    setState(() => _hidePrivacyEntry = hidden);
  }

  Future<void> _sendOtp(User user) async {
    if (_sendingOtp) return;
    if (_otpCooldownSeconds > 0) return;
    setState(() => _sendingOtp = true);
    try {
      final result = await EmailVerificationService.instance.sendOtp(user: user);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).otpSentSuccess)),
      );
      _startOtpCooldown(result.cooldownSeconds);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).otpSentFailed)),
      );
    } finally {
      if (mounted) {
        setState(() => _sendingOtp = false);
      }
    }
  }

  void _startOtpCooldown(int seconds) {
    _otpTimer?.cancel();
    setState(() => _otpCooldownSeconds = seconds);
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_otpCooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _otpCooldownSeconds = 0);
      } else {
        setState(() => _otpCooldownSeconds -= 1);
      }
    });
  }

  @override
  void dispose() {
    _otpTimer?.cancel();
    super.dispose();
  }

  Future<void> _rateApp() async {
    final launched = await launchUrl(
      Uri.parse(AppLinks.storeUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).rateAppFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = UniSpaceApp.of(context);
    final theme = Theme.of(context);

    return AppGuide(id: 'navigation', steps: const [GuideStep('nav.profile', 'nav.profile'),GuideStep('nav.chat', 'nav.chat'),GuideStep('nav.gpa', 'nav.gpa')], child: SafeArea(
      child: Drawer(
        backgroundColor: theme.scaffoldBackgroundColor,
        child: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.userChanges(),
          initialData: FirebaseAuth.instance.currentUser,
          builder: (context, authSnapshot) {
            final user = authSnapshot.data;
            return ValueListenableBuilder<UserProfileData>(
              valueListenable: UserProfileService.instance.notifier,
              builder: (context, profile, _) {

                final emailText = user?.email == null
                    ? S.of(context).emailUnavailable
                    : profile.showEmailInProfile
                    ? user!.email!
                    : S.of(context).emailHidden;
                final isVerified = user?.emailVerified ?? false;
                final uid = user?.uid;

                return ValueListenableBuilder<int>(
                    valueListenable: AuthorProfiles.revision,
                    builder: (context, _, __) {
                      if (uid != null) AuthorProfiles.ensure(uid);
                      final live = AuthorProfiles.nameOf(uid)?.trim();
                      final displayName = (live != null && live.isNotEmpty)
                          ? live
                          : (user?.displayName ??
                          user?.email?.split('@').first ??
                          S.of(context).guestUser);

                      return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Builder(
                      builder: (context) {
                        final coverUrl = _coverImageUrl;
                        final hasCover = coverUrl != null && coverUrl.isNotEmpty;

                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
                          decoration: BoxDecoration(
                            gradient: hasCover
                                ? null
                                : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context)
                                                .colorScheme.primary,
                                AppTeal.main,
                              ],
                            ),
                            image: hasCover
                                ? DecorationImage(
                              image: ProtectedNetworkImage(coverUrl!),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black.withValues(alpha: 0.45),
                                BlendMode.darken,
                              ),
                            )
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  LiveAuthorPhoto(
                                    userId: uid,
                                    fallbackUrl: user?.photoURL,
                                    size: 48,
                                    radius: 24,
                                    iconSize: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          emailText,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: Colors.white.withValues(alpha: 0.85),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (user?.email != null) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding:
                                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.35),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isVerified
                                                ? Icons.verified
                                                : Icons.warning_amber_rounded,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            isVerified
                                                ? S.of(context)
                                                          .emailVerified
                                                : S.of(context)
                                                          .emailNotVerified,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!isVerified)
                                      TextButton.icon(
                                        onPressed: _sendingOtp || _otpCooldownSeconds > 0
                                            ? null
                                            : () => _sendOtp(user!),
                                        icon: _sendingOtp
                                            ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                            : const Icon(Icons.mark_email_unread),
                                        label: Text(
                                          _otpCooldownSeconds > 0
                                              ? S.of(context)
                                                        .otpCooldownLabel(_otpCooldownSeconds)
                                              : S.of(context).sendOtpNow,
                                        ),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                    _sectionHeader(context, S.of(context).drawerSectionAccount),
                    GuideTarget(id: 'nav.profile', child: _drawerItem(
                      context,
                      icon: Icons.person_outline,
                      title: mainText(context, "Profile"),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                    )),


                    _sectionHeader(context, S.of(context).drawerSectionStudent),
                    GuideTarget(id: 'nav.chat', child: _drawerItem(
                      context,
                      icon: Icons.chat_outlined,
                      title: mainText(context, "Chat"),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatPage(onOpenDrawer: () {}),
                          ),
                        );
                      },
                    )),
                    GuideTarget(id: 'nav.gpa', child: _drawerItem(
                      context,
                      icon: Icons.school_outlined,
                      title: S.of(context).gpu,
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const HomeLandingScreen(showAppBar: true),
                          ),
                        );
                      },
                    )),


                    _sectionHeader(context, S.of(context).drawerSectionContent),
                    // _drawerItem(
                    //   context,
                    //   icon: Icons.download_outlined,
                    //   title: S.of(context).downloadsTitle,
                    //   onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (_) => const DownloadsScreen(),
                    //       ),
                    //     );
                    //   },
                    // ),
                    _drawerItem(
                      context,
                      icon: Icons.bookmark_border_rounded,
                      title: mainText(context, "المنشورات المحفوظة"),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(builder: (_) => const SavedPostsScreen()),
                        );
                      },
                    ),
                    Builder(
                      builder: (context) {
                        if (uid == null) {
                          return _drawerItem(
                            context,
                            icon: Icons.notifications_outlined,
                            title: mainText(context, "الإشعارات"),
                            onTap: () {
                              // يمكن توجيه المستخدم إلى تسجيل الدخول هنا
                            },
                          );
                        }

                        final notificationsQuery = FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('notifications')
                            .where('read', isEqualTo: false)
                            .limit(100);

                        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: notificationsQuery.snapshots(),
                          builder: (context, snap) {
                            if (snap.hasError) {
                              return _drawerItem(
                                context,
                                icon: Icons.notifications_outlined,
                                title: mainText(context, "الإشعارات"),
                                onTap: () {
                                  Navigator.of(context).pop();

                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const NotificationsScreen(),
                                    ),
                                  );
                                },
                              );
                            }

                            final unreadCount = snap.data?.docs.length ?? 0;

                            return _drawerItem(
                              context,
                              icon: unreadCount > 0
                                  ? Icons.notifications_rounded
                                  : Icons.notifications_outlined,
                              title: mainText(context, "الإشعارات"),
                              badge: unreadCount,
                              onTap: () {
                                Navigator.of(context).pop();

                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const NotificationsScreen(),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),

                    // _drawerItem(
                    //   context,
                    //   icon: Icons.note_alt_outlined,
                    //   title: S.of(context).clipboard,
                    //   onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (_) => const NotesScreen(),
                    //       ),
                    //     );
                    //   },
                    // ),
                    // _drawerItem(
                    //   context,
                    //   icon: Icons.psychology_outlined,
                    //   title: S.of(context).smartReviewPlanTitle,
                    //   onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (_) => const SmartReviewPlanPage(),
                    //       ),
                    //     );
                    //   },
                    // ),
                    // _drawerItem(
                    //   context,
                    //   icon: Icons.calendar_month_outlined,
                    //   title: S.of(context).examCalendar,
                    //   onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (_) => const ExamsCalendarPage(),
                    //       ),
                    //     );
                    //   },
                    // ),
                    if (user != null) _drawerItem(
                      context,
                      icon: Icons.person_add_alt_1_outlined,
                      title: mainText(context, 'طلبات المتابعة'),
                      onTap: () {
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        navigator.push(MaterialPageRoute(builder: (_) => const FollowRequestsScreen()));
                      },
                    ),
                    _sectionHeader(context, S.of(context).drawerSectionApp),
                    // _drawerItem(
                    //   context,
                    //   icon: Icons.text_fields_outlined,
                    //   title: S.of(context).fontSizeTitle,
                    //   onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (_) => const FontSizeScreen(),
                    //       ),
                    //     );
                    //   },
                    // ),

                    _drawerItem(
                      context,
                      icon: Icons.settings_rounded,
                      title: mainText(context, "Settings"),
                      onTap: () {
                        Navigator.of(context).pop();
                        _openSettings();
                      },
                    ),


                    _drawerItem(
                      context,
                      icon: Icons.star_rate_outlined,
                      title: S.of(context).rateApp,
                      onTap: _rateApp,
                    ),
                    _drawerItem(
                      context,
                      icon: Icons.share_outlined,
                      title: S.of(context).shareApp,
                      onTap: () => Share.share(AppLinks.shareMessage),
                    ),
                    if (_showPrivacyAndContactInDrawer)
                      _drawerItem(
                        context,
                        icon: Icons.email_outlined,
                        title: S.of(context).contactUs,
                        onTap: () {
                          _showContactDialog(context);
                        },
                      ),
                    _drawerItem(
                      context,
                      icon: Icons.info_outline,
                      title: S.of(context).aboutApp,
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AboutScreen(),
                          ),
                        );
                      },
                    ),
                    if (_showPrivacyAndContactInDrawer)
                      _drawerItem(
                        context,
                        icon: Icons.privacy_tip_outlined,
                        title: S.of(context).privacyPolicy,
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyScreen(),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 8),
                    const Divider(height: 24),
                    if (user != null)
                      _drawerItem(
                        context,
                        icon: Icons.logout,
                        title: S.of(context).logout,
                        iconColor: Colors.redAccent,
                        textColor: Colors.redAccent,
                        onTap: _isLoggingOut
                            ? null
                            : () async {
                          setState(() {
                            _isLoggingOut = true;
                          });

                          try {
                            final currentUser = FirebaseAuth.instance.currentUser;
                            await AuthSessionService.signOutFully(
                              beforeSignOut: currentUser == null ? null :
                                  () => SessionService.instance.revokeCurrentSession(currentUser.uid));

                            if (!context.mounted) return;

                            Navigator.of(context).pop();
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isLoggingOut = false;
                              });
                            }
                          }
                        },
                      )
                    else
                      _drawerItem(
                        context,
                        icon: Icons.login,
                        title: S.of(context).login,
                        onTap: () {
                          if (kDebugMode) {
                            debugPrint('[Auth] login drawer item tapped while signed out');
                          }
                          Navigator.of(context).pop();
                        },
                      ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'UniSpace © ${DateTime.now().year}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
                    });
              },
            );
          },
        ),
      ),
    ));
  }

  Widget _sectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        22,
        20,
        22,
        8,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 17,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _drawerItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        VoidCallback? onTap,
        Color? iconColor,
        Color? textColor,
        int badge = 0,
        bool selected = false,
      }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color primaryColor = colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 3,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: primaryColor.withValues(alpha: 0.10),
          highlightColor: primaryColor.withValues(alpha: 0.06),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? primaryColor.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: selected
                  ? Border.all(
                color: primaryColor.withValues(alpha: 0.16),
                width: 1,
              )
                  : null,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected
                        ? primaryColor.withValues(alpha: 0.16)
                        : colorScheme.onSurface.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    size: 21,
                    color: selected
                        ? primaryColor
                        : iconColor ??
                        colorScheme.onSurface.withValues(alpha: 0.70),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? primaryColor
                          : textColor ?? colorScheme.onSurface,
                      fontSize: 14.5,
                      fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),

                if (badge > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 25,
                      minHeight: 23,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTeal.main,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge > 99 ? '99+' : '$badge',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],

                if (selected) ...[
                  const SizedBox(width: 5),
                  Icon(
                    Icons.chevron_left_rounded,
                    size: 20,
                    color: primaryColor,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }





  void _showContactDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ContactUsSheet(),
    );
  }

  
}



class _ThemeModeSheet extends StatelessWidget {
  final _UniSpaceAppState app;

  const _ThemeModeSheet({
    required this.app,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SafeArea(
      child: Material(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SheetDragHandle(color: colors.outlineVariant),

              const SizedBox(height: 18),

              Row(
                children: [
                  _SheetIcon(
                    icon: Icons.palette_outlined,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mainText(context, "المظهر والألوان"),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mainText(context, "خصص شكل التطبيق بما يناسبك"),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Text(
                mainText(context, "السمة"),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 10),

              _ThemeOptionTile(
                icon: Icons.light_mode_outlined,
                title: S.of(context).light,
                subtitle: mainText(context, "استخدام المظهر الفاتح دائمًا"),
                value: ThemeMode.light,
                groupValue: app._themeMode,
                color: Colors.orange,
                onChanged: (value) => _apply(context, value),
              ),

              const SizedBox(height: 10),

              _ThemeOptionTile(
                icon: Icons.dark_mode_outlined,
                title: S.of(context).dark,
                subtitle: mainText(context, "استخدام المظهر الداكن دائمًا"),
                value: ThemeMode.dark,
                groupValue: app._themeMode,
                color: Theme.of(context).colorScheme.primary,
                onChanged: (value) => _apply(context, value),
              ),

              const SizedBox(height: 10),

              _ThemeOptionTile(
                icon: Icons.brightness_auto_outlined,
                title: S.of(context).system,
                subtitle: mainText(context, "اتباع إعدادات الجهاز تلقائيًا"),
                value: ThemeMode.system,
                groupValue: app._themeMode,
                color: colors.primary,
                onChanged: (value) => _apply(context, value),
              ),

              const SizedBox(height: 26),

              Text(
                mainText(context, "ألوان التطبيق"),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 10),

              _ColorSettingTile(
                icon: Icons.palette_outlined,
                title: mainText(context, "Main color"),
                subtitle: mainText(context, "The app main color"),
                color: app.tealColor,
                onTap: () {
                  Navigator.pop(context);

                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: false,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _AppColorWheelSheet(
                      title: mainText(context, "Main color"),
                      subtitle: mainText(context, "Chose the app main color as you like"),
                      initial: app.tealColor,
                      onApply: app.setTealColor,
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              _ColorSettingTile(
                icon: Icons.brush_outlined,
                title: mainText(context, "Sub color"),
                subtitle: mainText(context, "the app sub color"),
                color: app.primaryColor,
                onTap: () {
                  Navigator.pop(context);

                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: false,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _AppColorWheelSheet(
                      title: mainText(context, "Sub color"),
                      subtitle: mainText(context, "Chose the app sub color as you like"),
                      initial: app.primaryColor,
                      onApply: app.setPrimaryColor,
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: () async {
                  await app.resetAccentColors();

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.restart_alt_rounded),
                label:  Text(mainText(context, "العودة للألوان الأصلية")),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _apply(BuildContext context, ThemeMode mode) {
    app.setThemeMode(mode);
    Navigator.pop(context);
  }
}


class _SheetIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _SheetIcon({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ThemeMode value;
  final ThemeMode groupValue;
  final Color color;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isSelected = value == groupValue;

    return Material(
      color: isSelected
          ? colors.primaryContainer.withOpacity(.55)
          : colors.surfaceContainerHighest.withOpacity(.38),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => onChanged(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? colors.primary
                            : colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Radio<ThemeMode>(
                value: value,
                groupValue: groupValue,
                onChanged: (newValue) {
                  if (newValue != null) {
                    onChanged(newValue);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorSettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ColorSettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: colors.surfaceContainerHighest.withOpacity(.38),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.outline.withOpacity(.25),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              Icon(
                Icons.chevron_left_rounded,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}







/// ===============================================================
/// Color Wheel Bottom Sheet
/// ===============================================================

class _AppColorWheelSheet extends StatefulWidget {
  const _AppColorWheelSheet({
    required this.title,
    required this.subtitle,
    required this.initial,
    required this.onApply,
  });

  final String title;
  final String subtitle;
  final Color initial;
  final Future<void> Function(Color color) onApply;

  @override
  State<_AppColorWheelSheet> createState() => _AppColorWheelSheetState();
}

class _AppColorWheelSheetState extends State<_AppColorWheelSheet> {
  late HSVColor _hsv;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initial);
  }

  Future<void> _apply() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onApply(_hsv.toColor());

      if (!mounted) return;

      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _updateColor(HSVColor value) {
    setState(() {
      _hsv = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final selectedColor = _hsv.toColor();

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Directionality(
      textDirection: Directionality.of(context),
      child: SafeArea(
        top: false,
        child: Material(
          color: colors.surface,
          elevation: 12,
          clipBehavior: Clip.antiAlias,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(32),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20 + bottomInset,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SheetDragHandle(
                  color: colors.outlineVariant,
                ),

                const SizedBox(height: 22),

                _ColorSheetHeader(
                  title: widget.title,
                  subtitle: widget.subtitle,
                  color: selectedColor,
                ),

                const SizedBox(height: 24),

                _ColorPickerCard(
                  hsv: _hsv,
                  selectedColor: selectedColor,
                  onChanged: _updateColor,
                ),

                const SizedBox(height: 18),

                _ColorPreview(
                  color: selectedColor,
                  colors: colors,
                ),

                const SizedBox(height: 20),

                _ApplyColorButton(
                  color: selectedColor,
                  isSaving: _isSaving,
                  onPressed: _apply,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


/// Header
class _ColorSheetHeader extends StatelessWidget {
  const _ColorSheetHeader({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(.30),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Icon(
            Icons.palette_rounded,
            color: _onColor(color),
            size: 28,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.4,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


/// Color picker container
class _ColorPickerCard extends StatelessWidget {
  const _ColorPickerCard({
    required this.hsv,
    required this.selectedColor,
    required this.onChanged,
  });

  final HSVColor hsv;
  final Color selectedColor;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(.42),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: colors.outlineVariant.withOpacity(.35),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.colorize_rounded,
                color: colors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                mainText(context, "اختر اللون"),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              _ColorValueBadge(
                color: selectedColor,
              ),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 270,
            width: double.infinity,
            child: _ColorWheel(
              hsv: hsv,
              onChanged: onChanged,
            ),
          ),

          const SizedBox(height: 10),

          _BrightnessSlider(
            hsv: hsv,
            color: selectedColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}


/// Small color badge
class _ColorValueBadge extends StatelessWidget {
  const _ColorValueBadge({
    required this.color,
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    final hex = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.14),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        hex,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
          fontFeatures: const [
            FontFeature.tabularFigures(),
          ],
        ),
      ),
    );
  }
}

class _BrightnessSlider extends StatelessWidget {
  const _BrightnessSlider({
    required this.hsv,
    required this.color,
    required this.onChanged,
  });

  final HSVColor hsv;
  final Color color;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colors.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.brightness_5_outlined,
            size: 20,
            color: colors.onSurfaceVariant,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mainText(context, "السطوع"),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 7,
                  activeTrackColor: color,
                  inactiveTrackColor: colors.outlineVariant.withOpacity(.35),
                  thumbColor: color,
                  overlayColor: color.withOpacity(.15),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 9,
                  ),
                ),
                child: Slider(
                  value: hsv.value.clamp(0.0, 1.0),
                  min: 0,
                  max: 1,
                  onChanged: (value) {
                    onChanged(hsv.withValue(value));
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        Text(
          '${(hsv.value * 100).round()}%',
          style: theme.textTheme.labelMedium?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ColorPreview extends StatelessWidget {
  const _ColorPreview({
    required this.color,
    required this.colors,
  });

  final Color color;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 58,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(.28),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Center(
              child: Text(
                mainText(context, "المعاينة"),
                style: TextStyle(
                  color: _onColor(color),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: colors.outline.withOpacity(.28),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(.22),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ApplyColorButton extends StatelessWidget {
  const _ApplyColorButton({
    required this.color,
    required this.isSaving,
    required this.onPressed,
  });

  final Color color;
  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: isSaving ? null : onPressed,
        // style: FilledButton.styleFrom(
        //   backgroundColor: color,
        //   foregroundColor: _onColor(color),
        //   disabledBackgroundColor: color.withOpacity(.55),
        //   disabledForegroundColor: _onColor(color).withOpacity(.75),
        //   elevation: 0,
        //   shape: RoundedRectangleBorder(
        //     borderRadius: BorderRadius.circular(18),
        //   ),
        // ),
        icon: isSaving
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.3,
            color: _onColor(color),
          ),
        )
            : const Icon(Icons.check_rounded),

        label: Text(
          isSaving ? mainText(context, "جارٍ الحفظ...") : mainText(context, "اعتماد اللون"),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _ColorWheel extends StatelessWidget {
  const _ColorWheel({
    required this.hsv,
    required this.onChanged,
  });

  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(
          constraints.maxWidth,
          constraints.maxHeight,
        );

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,

              onPanDown: (details) {
                _handlePosition(
                  details.localPosition,
                  size,
                );
              },

              onPanUpdate: (details) {
                _handlePosition(
                  details.localPosition,
                  size,
                );
              },

              child: CustomPaint(
                painter: _ColorWheelPainter(hsv),
                size: Size.square(size),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handlePosition(
      Offset position,
      double size,
      ) {
    final center = Offset(
      size / 2,
      size / 2,
    );

    final offset = position - center;
    final radius = size / 2;
    final distance = offset.distance;

    // حصر المؤشر داخل حدود الدائرة
    final saturation = (distance / radius).clamp(0.0, 1.0);

    // atan2 في إحداثيات الشاشة يبدأ من الجهة اليمنى
    // ويزداد مع اتجاه عقارب الساعة، وهو نفس اتجاه SweepGradient
    var hue = math.atan2(
      offset.dy,
      offset.dx,
    ) *
        180 /
        math.pi;

    if (hue < 0) {
      hue += 360;
    }

    onChanged(
      HSVColor.fromAHSV(
        1.0,
        hue,
        saturation,
        hsv.value,
      ),
    );
  }
}

class _ColorWheelPainter extends CustomPainter {
  _ColorWheelPainter(this.hsv);

  final HSVColor hsv;

  static const List<Color> _wheelColors = [
    Color(0xFFFF0000), // Red
    Color(0xFFFFFF00), // Yellow
    Color(0xFF00FF00), // Green
    Color(0xFF00FFFF), // Cyan
    Color(0xFF0000FF), // Blue
    Color(0xFFFF00FF), // Magenta
    Color(0xFFFF0000), // Red
  ];

  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = math.min(
      size.width,
      size.height,
    ) /
        2;

    final wheelRect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    // ------------------------------------------------------------
    // 1. رسم ألوان Hue
    //
    // لا نستخدم GradientRotation هنا.
    // يبدأ اللون الأحمر من الجهة اليمنى، وهي نفس نقطة حساب atan2.
    // ------------------------------------------------------------

    final huePaint = Paint()
      ..shader = const SweepGradient(
        colors: _wheelColors,
        stops: [
          0.0,
          1 / 6,
          2 / 6,
          3 / 6,
          4 / 6,
          5 / 6,
          1.0,
        ],
      ).createShader(wheelRect);

    canvas.drawCircle(
      center,
      radius,
      huePaint,
    );

    // ------------------------------------------------------------
    // 2. إضافة التشبع Saturation
    //
    // المركز أبيض = تشبع 0
    // الحافة = تشبع 1
    // ------------------------------------------------------------

    final saturationPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          Colors.white.withOpacity(0.0),
        ],
        stops: const [
          0.0,
          1.0,
        ],
      ).createShader(wheelRect);

    canvas.drawCircle(
      center,
      radius,
      saturationPaint,
    );

    // ------------------------------------------------------------
    // 3. تطبيق قيمة السطوع Value على كامل الدائرة
    //
    // عند value = 1 لا يوجد تعتيم.
    // عند value = 0 تصبح الدائرة سوداء.
    // ------------------------------------------------------------

    final brightness = hsv.value.clamp(0.0, 1.0);
    final darkness = 1.0 - brightness;

    if (darkness > 0) {
      final brightnessPaint = Paint()
        ..color = Colors.black.withOpacity(darkness);

      canvas.drawCircle(
        center,
        radius,
        brightnessPaint,
      );
    }

    // ------------------------------------------------------------
    // 4. رسم مؤشر اللون المختار
    // ------------------------------------------------------------

    final angle = hsv.hue * math.pi / 180;
    final selectedRadius = radius * hsv.saturation;

    final selectedPosition = Offset(
      center.dx + math.cos(angle) * selectedRadius,
      center.dy + math.sin(angle) * selectedRadius,
    );

    // ظل خلف المؤشر حتى يكون واضحًا على جميع الألوان
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(.28)
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        4,
      );

    canvas.drawCircle(
      selectedPosition,
      16,
      shadowPaint,
    );

    // الحلقة الخارجية
    final outerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(
      selectedPosition,
      14,
      outerPaint,
    );

    // لون المؤشر الداخلي
    final innerPaint = Paint()
      ..color = hsv.toColor()
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      selectedPosition,
      10,
      innerPaint,
    );

    // نقطة صغيرة داخل المؤشر لتحسين الوضوح
    final centerPaint = Paint()..color = _getContrastColor(hsv.toColor());

    canvas.drawCircle(
      selectedPosition,
      3,
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(
      covariant _ColorWheelPainter oldDelegate,
      ) {
    return oldDelegate.hsv != hsv;
  }

  Color _getContrastColor(Color color) {
    final brightness = ThemeData.estimateBrightnessForColor(color);

    return brightness == Brightness.dark
        ? Colors.white
        : Colors.black.withOpacity(.75);
  }
}


/// ===============================================================
/// Language Bottom Sheet
/// ===============================================================

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final app = UniSpaceApp.of(context);
    final currentLanguage = app._locale.languageCode;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final languages = [
      _LanguageOption(
        code: 'ar',
        title: S.of(context).arabic,
        subtitle: 'العربية',
        flag: '🇸🇦',
        direction: TextDirection.rtl,
      ),
      _LanguageOption(
        code: 'fr',
        title: 'Français',
        subtitle: mainText(context, "الفرنسية"),
        flag: '🇫🇷',
        direction: TextDirection.ltr,
      ),
      _LanguageOption(
        code: 'en',
        title: 'English',
        subtitle: mainText(context, "الإنجليزية"),
        flag: '🇬🇧',
        direction: TextDirection.ltr,
      ),
    ];

    return Directionality(
      textDirection: Directionality.of(context),
      child: SafeArea(
        top: false,
        child: Material(
          color: colors.surface,
          elevation: 12,
          clipBehavior: Clip.antiAlias,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(32),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              22,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SheetDragHandle(
                  color: colors.outlineVariant,
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        Icons.translate_rounded,
                        color: colors.onPrimaryContainer,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            S.of(context).chooseLanguage,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            mainText(context, "اختر اللغة المناسبة لتجربتك"),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                ...languages.map(
                      (language) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LanguageTile(
                      option: language,
                      selected: language.code == currentLanguage,
                      onTap: () {
                        app.setLocale(
                          Locale(language.code),
                        );

                        Navigator.of(context).pop();
                      },
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


class _LanguageOption {
  const _LanguageOption({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.flag,
    required this.direction,
  });

  final String code;
  final String title;
  final String subtitle;
  final String flag;
  final TextDirection direction;
}


class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _LanguageOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final backgroundColor = selected
        ? colors.primaryContainer.withOpacity(.72)
        : colors.surfaceContainerHighest.withOpacity(.40);

    final borderColor = selected
        ? colors.primary.withOpacity(.72)
        : colors.outlineVariant.withOpacity(.30);

    return Semantics(
      selected: selected,
      button: true,
      label: option.title,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Material(
          // مهم: يجب أن يكون Material داخل الـ Container
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            onTap: onTap,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 7,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),

            leading: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? colors.surface
                    : colors.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Text(
                option.flag,
                style: const TextStyle(
                  fontSize: 25,
                ),
              ),
            ),

            title: Directionality(
              textDirection: option.direction,
              child: Text(
                option.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: selected
                      ? colors.onPrimaryContainer
                      : colors.onSurface,
                ),
              ),
            ),

            subtitle: Directionality(
              textDirection: option.direction,
              child: Text(
                option.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: selected
                      ? colors.onPrimaryContainer.withOpacity(.72)
                      : colors.onSurfaceVariant,
                ),
              ),
            ),

            trailing: AnimatedScale(
              duration: const Duration(milliseconds: 180),
              scale: selected ? 1 : .8,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: selected ? 1 : 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 19,
                    color: colors.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}



/// ===============================================================
/// Shared UI Helpers
/// ===============================================================

class _SheetDragHandle extends StatelessWidget {
  const _SheetDragHandle({
    required this.color,
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 5,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}


/// Returns a readable foreground color.
Color _onColor(Color color) {
  final brightness = ThemeData.estimateBrightnessForColor(color);

  return brightness == Brightness.dark
      ? Colors.white
      : Colors.black87;
}


