part of '../../main.dart';

class UniSpaceApp extends StatefulWidget {
  const UniSpaceApp({
    super.key,
    required this.initialThemeMode,
    required this.initialLocale,
  });

  final ThemeMode initialThemeMode;
  final Locale initialLocale;

  static _UniSpaceAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_UniSpaceAppState>()!;

  @override
  State<UniSpaceApp> createState() => _UniSpaceAppState();
}

class _UniSpaceAppState extends State<UniSpaceApp> {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');

  Color _primaryColor = AppPrimary.seed;
  static const _kPrimary = 'pref_primaryColor';

  Color get primaryColor => _primaryColor;

  static const Color _defaultPrimary = Color(0xFF30475E);

  Future<void> resetAccentColors() async {
    _tealColor = kDefaultTeal;
    _primaryColor = _defaultPrimary;
    AppTeal.apply(_tealColor);
    AppPrimary.apply(_primaryColor);
    setState(() {});

    final p = await SharedPreferences.getInstance();
    await p.remove(_kTeal);
    await p.remove(_kPrimary);
  }

  Future<void> setTealColor(Color c) async {
    _tealColor = c;
    AppTeal.apply(c);
    setState(() {});
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kTeal, c.value);
  }

  Future<void> setPrimaryColor(Color c) async {
    _primaryColor = c;
    AppPrimary.apply(c);
    setState(() {});
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kPrimary, c.value);
  }
  static const _kTheme = 'pref_themeMode';
  static const _kLocale = 'pref_locale';
  Color _tealColor = kDefaultTeal;
  static const _kTeal = 'pref_tealColor';

  Color get tealColor => _tealColor;


  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
    _locale = widget.initialLocale;
    _restorePrefs();
  }

  Future<void> _restorePrefs() async {
    final p = await SharedPreferences.getInstance();
    final themeIdx = p.getInt(_kTheme);
    final lang = p.getString(_kLocale);

    final tealVal = p.getInt('pref_tealColor');
    if (tealVal != null) AppTeal.apply(Color(tealVal));
    final primaryVal = p.getInt(_kPrimary);
    if (primaryVal != null) {
      _primaryColor = Color(primaryVal);
      AppPrimary.apply(_primaryColor);
    }
    if (tealVal != null) {
      _tealColor = Color(tealVal);
      AppTeal.apply(_tealColor);
    }
    if (themeIdx != null &&
        themeIdx >= 0 &&
        themeIdx < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeIdx];
    }
    if (lang != null && lang.isNotEmpty) {
      _locale = supportedAppLocale(lang);
    }
    if (mounted) setState(() {});
  }

  Future<void> setThemeMode(ThemeMode m) async {
    setState(() => _themeMode = m);
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kTheme, m.index);
  }

  Future<void> setLocale(Locale l) async {
    final supported = supportedAppLocale(l.languageCode);
    setState(() => _locale = supported);
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLocale, supported.languageCode);
    Intl.defaultLocale = supported.languageCode;
    unawaited(PushPreferencesService.instance.sync());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: unispaceNavigatorKey,
      title: 'UniSpace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      locale: _locale,
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      builder: (context, child) {
        return LoginAlertWatcher(
          navigatorKey: unispaceNavigatorKey,
          child: ValueListenableBuilder<SettingsData>(
            valueListenable: AppSettings.instance.notifier,
            builder: (context, settings, _) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(settings.fontScale.scale),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
          ),
        );
      },
      home: const AuthGate(),
    );
  }
}

// ============================================================================
// Global End Drawer — يعمل فعليًا (مظهر/لغة/إعادة كلمة السر/روابط)
// ============================================================================
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  

  
  bool _openingGroupLink = false;
  StreamSubscription<Uri>? _linkSub;
  final _appLinks = deep_links.AppLinks();
  
  

  
  late final Widget _home;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCurrentSession();
    setUserPresence(online: true);
    _home = CommunityScreen(onOpenDrawer: _openEndDrawer);
    _initDeepLinks();
  }
  Future<void> _initDeepLinks() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handleIncomingLink(initial);
    } catch (e) {
      debugPrint('Initial link error: $e');
    }

    _linkSub = _appLinks.uriLinkStream.listen(
      _handleIncomingLink,
      onError: (e) => debugPrint('Link stream error: $e'),
    );
  }

  void _handleIncomingLink(Uri uri) {
    if (uri.scheme != 'unispace') return;
    if (isChatGroupJoinLink(uri)) {
      if (!mounted || _openingGroupLink) return;
      _openingGroupLink = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) { _openingGroupLink = false; return; }
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatGroupJoinPage(initialLink: uri.toString())))
          .whenComplete(() => _openingGroupLink = false);
      });
      return;
    }
    if (uri.host != 'post') return;

    final postId = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.first
        : uri.path.replaceFirst('/', '');

    if (postId.isEmpty) return;
    debugPrint('Open post from link: $postId');
    _openPostById(postId);
  }

  Future<void> _openPostById(String postId) async {
    try {
      final data = await _readAuthorizedPostData(postId);
      final post = _Post.fromData(postId, data);
      if (!mounted) return;

      // انتقل لتبويب المجتمع ثم افتح المنشور


      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CommentsScreen(post: post),
        ),
      );
    } catch (e) {
      debugPrint('Open post failed: $e');
    }
  }
  Future<void> _initializeCurrentSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await SessionService.instance.initSession(user.uid);
  }

  Future<void> _touchCurrentSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final revoked = await SessionService.instance.isCurrentSessionRevoked(user.uid);
    if (revoked) {
      if (kDebugMode) debugPrint('[Auth] session revoked -> signOut');
      await AuthSessionService.signOutFully();
      return;
    }
    await SessionService.instance.updateLastSeen(user.uid);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _touchCurrentSession();
        setUserPresence(online: true);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        setUserPresence(online: false);
        break;
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    setUserPresence(online: false);
    super.dispose();
  }

  void _openEndDrawer() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 8,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height,
              child: const AppEndDrawer(),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          )),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _home,
    );
  }
}



// ============================================================================
// Auth Gate + SignIn
// ============================================================================
