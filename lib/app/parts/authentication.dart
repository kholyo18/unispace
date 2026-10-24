part of '../../main.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

/// Keeps authenticated routes unmounted until their session metadata is ready.
/// A new signed session gets a new future; ordinary rebuilds reuse the result.
class AuthenticatedSessionReady extends StatefulWidget {
  const AuthenticatedSessionReady({super.key, required this.sessionKey,
    required this.initialize, required this.child});
  final String sessionKey;
  final Future<void> Function() initialize;
  final Widget child;

  @override
  State<AuthenticatedSessionReady> createState() => _AuthenticatedSessionReadyState();
}

class _AuthenticatedSessionReadyState extends State<AuthenticatedSessionReady> {
  late Future<void> _ready;
  Future<void> _initialize() => Future<void>.sync(widget.initialize)
      .timeout(const Duration(seconds: 30));
  @override
  void initState() { super.initState(); _ready = _initialize(); }
  @override
  void didUpdateWidget(AuthenticatedSessionReady oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionKey != widget.sessionKey) _ready = _initialize();
  }
  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _ready,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const BrandLoadingScene();
      }
      if (snapshot.hasError) {
        return Scaffold(body: SafeArea(child: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(mainText(context, 'تحقق من اتصال الإنترنت ثم أعد المحاولة.'), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: () {
              final ready = _initialize();
              setState(() { _ready = ready; });
            },
              child: Text(mainText(context, 'إعادة المحاولة'))),
          ]),
        ))));
      }
      return widget.child;
    },
  );
}

class _NativeMfaRequiredScreen extends StatefulWidget {
  const _NativeMfaRequiredScreen({required this.onContinue});

  final Future<void> Function() onContinue;

  @override
  State<_NativeMfaRequiredScreen> createState() =>
      _NativeMfaRequiredScreenState();
}

class _NativeMfaRequiredScreenState extends State<_NativeMfaRequiredScreen> {
  bool _busy = false;

  Future<void> _continue() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onContinue();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_user_outlined, size: 48),
                const SizedBox(height: 16),
                 Text(
                  mainText(context, "أعد تسجيل الدخول لإكمال التأكيد بخطوتين عبر تطبيق المصادقة."),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _continue,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      :  Text(mainText(context, "متابعة إلى تسجيل الدخول")),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<MapEntry<User?, String>> _authSessions =
      FirebaseAuth.instance.idTokenChanges().asyncMap((user) async {
    if (user == null) return const MapEntry<User?, String>(null, '');
    try {
      final token = await user.getIdTokenResult();
      return MapEntry<User?, String>(user, '${token.claims?['sid'] ?? ''}');
    } catch (_) {
      // Keep the authenticated account on a retry screen when offline.
      return MapEntry<User?, String>(user, 'unresolved');
    }
  });
  User? _lastAuthUser;
  bool _blockingSignOut = false;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userDocStream;
  String? _userDocStreamUid;

  Stream<DocumentSnapshot<Map<String, dynamic>>> _statusStreamFor(String uid) {
    if (_userDocStream == null || _userDocStreamUid != uid) {
      _userDocStreamUid = uid;
      _userDocStream = FirebaseFirestore.instance
          .collection('users').doc(uid).snapshots();
    }
    return _userDocStream!;
  }

  Future<bool> _isTwoFactorRequired(User user) async {
    final factors =
    await user.multiFactor.getEnrolledFactors();
    final hasTotp = factors.any((factor) => factor.factorId == 'totp');
    if (!hasTotp) return false;
    final token = await user.getIdTokenResult();
    final firebase = token.claims?['firebase'];
    return firebase is! Map || firebase['sign_in_second_factor'] != 'totp';
  }

  Future<void> _blockAndSignOut(String reason) async {
    if (_blockingSignOut) return;
    _blockingSignOut = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await SessionService.instance.revokeCurrentSession(user.uid);
      }
      await AuthSessionService.signOutFully();
      if (kDebugMode) debugPrint('[AuthGate] blocked: $reason');
    } finally {
      _blockingSignOut = false;
    }
  }

  void _refreshStatus() {
    if (!mounted) return;
    setState(() {});
  }

  Widget _routeAuthenticated(User user, bool isPasswordUser) {
    return AuthSecurityCheck(
      key: ValueKey('security-check:${user.uid}:${TwoFactorService.instance.authRefresh.value}'),
      check: () => _isTwoFactorRequired(user),
      challengeBuilder: (_) => _NativeMfaRequiredScreen(
        onContinue: () => _blockAndSignOut('native_mfa_required'),
      ),
      child: const HomeShell(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: TwoFactorService.instance.authRefresh,
      builder: (_, __, ___) {
        return StreamBuilder<MapEntry<User?, String>>(
          stream: _authSessions,
          builder: (ctx, snap) {
            if (Firebase.apps.isEmpty) {
              return  Scaffold(
                body: Center(
                  child: Text(mainText(ctx, "تعذر تشغيل Firebase. أعد فتح التطبيق.")),
                ),
              );
            }
            if (snap.connectionState == ConnectionState.waiting) {
              return const BrandLoadingScene();
            }

            if (!identical(_lastAuthUser, snap.data?.key)) {
              _lastAuthUser = snap.data?.key;
              if (kDebugMode) {
                debugPrint(
                  '[AuthGate] authStateChanges user=${snap.data?.key?.uid ?? 'null'}',
                );
              }
            }

            if (snap.data?.key == null) {
              _userDocStream = null;
              _userDocStreamUid = null;
              return const SignInScreen();
            }

            final user = snap.data!.key!;
            final signedSid = snap.data!.value;
            final isPasswordUser = user.providerData
                .any((info) => info.providerId == 'password');
// if (isPasswordUser && !user.emailVerified) {
            //   return VerifyEmailScreen(
            //     key: ValueKey('verify_${user.uid}'),
            //     email: user.email ?? '',
            //     password: '',
            //   );
            // }
            Widget ready(Widget child) => AuthenticatedSessionReady(
              sessionKey: '${user.uid}:$signedSid:${TwoFactorService.instance.authRefresh.value}',
              initialize: () async {
                if (FirebaseAuth.instance.currentUser?.uid != user.uid) throw StateError('Session changed.');
                final expectedSid = signedSid == 'unresolved'
                    ? '${(await user.getIdTokenResult()).claims?['sid'] ?? ''}' : signedSid;
                await SessionService.instance.initSession(user.uid);
                final current = FirebaseAuth.instance.currentUser;
                if (current?.uid != user.uid ||
                    '${(await current!.getIdTokenResult()).claims?['sid'] ?? ''}' != expectedSid) {
                  throw StateError('Session changed.');
                }
              },
              child: child,
            );
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _statusStreamFor(user.uid),
              builder: (context, statusSnap) {
                if (statusSnap.hasError) {
                  debugPrint('AuthGate user doc: ${statusSnap.error}');
                  return ready(_routeAuthenticated(user, isPasswordUser));
                }

                final doc = statusSnap.data;
                final data = doc?.data();
                final status = data?['accountStatus']?.toString();

                if (status == 'deleted') {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _blockAndSignOut(mainText(context, "الحساب محذوف"));
                  });
                  return const SignInScreen();
                }

                if (status == 'disabled') {
                  if (kDebugMode) {
                    debugPrint('[AuthGate] routing -> ReactivateAccountScreen');
                  }
                  return ready(ReactivateAccountScreen(onReactivated: _refreshStatus));
                }

                if (!statusSnap.hasData) {
                  return const BrandLoadingScene();
                }

                final completed = data?['onboardingCompleted'] == true;
                final hasProfile =
                    (data?['username'] ?? '').toString().trim().isNotEmpty ||
                        (data?['name'] ?? '').toString().trim().isNotEmpty;
                final needsOnboarding =
                    doc == null || !doc.exists || (!completed && !hasProfile);

                if (needsOnboarding) {
                  final isGoogle =
                  user.providerData.any((p) => p.providerId == 'google.com');
                  final parts = (user.displayName ?? '').trim().split(RegExp(r'\s+'));
                  final first = parts.isNotEmpty ? parts.first : '';
                  final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
                  return ready(SignUpFlowScreen(
                    skipAccountCreation: isGoogle,
                    initialFirstName: first,
                    initialLastName: last,
                  ));
                }

                return ready(_routeAuthenticated(user, isPasswordUser));
              },
            );
          },
        );
      },
    );
  }
}
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final GoogleSignIn _googleSignIn = AuthSessionService.googleSignIn;
  bool loading = false;
  bool googleLoading = false;
  bool _termsAccepted = false;
  bool _obscure = true;

  String _mapAuthError(FirebaseAuthException error) {
    final localizations = S.of(context);
    switch (error.code) {
      case 'invalid-email':
        return localizations.invalidEmailError;
      case 'user-disabled':
        return localizations.userDisabledError;
      case 'user-not-found':
        return localizations.userNotFoundError;
      case 'wrong-password':
        return localizations.wrongPasswordError;
      case 'email-already-in-use':
        return localizations.emailAlreadyInUseError;
      case 'weak-password':
        return localizations.weakPasswordError;
      case 'operation-not-allowed':
        return localizations.emailAuthDisabledError;
      case 'network-request-failed':
        return localizations.networkError;
      case 'too-many-requests':
        return localizations.tooManyRequestsError;
      default:
        return localizations.genericAuthError;
    }
  }

  void _showAuthSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _mapGoogleAuthError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'network-request-failed':
          return mainText(context, "تحقق من اتصال الإنترنت ثم أعد المحاولة.");
        case 'invalid-credential':
          return mainText(context, "بيانات الاعتماد غير صالحة. تحقق من إعدادات تسجيل الدخول.");
        case 'user-disabled':
          return mainText(context, "تم تعطيل الحساب.");
        default:
          return mainText(context, "حدث خطأ أثناء تسجيل الدخول عبر Google. حاول مرة أخرى.");
      }
    }
    if (error is PlatformException) {
      final details = [
        error.message,
        error.details?.toString(),
      ].where((value) => value != null && value!.trim().isNotEmpty).join(' ');
      final detailsLower = details.toLowerCase();
      if (error.code == 'sign_in_canceled') {
        return mainText(context, "تم إلغاء تسجيل الدخول عبر Google.");
      }
      if (error.code == 'network_error') {
        return mainText(context, "تحقق من اتصال الإنترنت ثم أعد المحاولة.");
      }
      if (error.code == 'api_exception' ||
          detailsLower.contains('apiexception: 10') ||
          detailsLower.contains('apiexception:10') ||
          detailsLower.contains('12500')) {
        return mainText(context, "تعذر إكمال تسجيل الدخول. تأكد من إعدادات Firebase/Google (SHA-1، الحزمة، OAuth) ثم أعد المحاولة.");
      }
      return mainText(context, "حدث خطأ أثناء تسجيل الدخول عبر Google. حاول مرة أخرى.");
    }
    return mainText(context, "حدث خطأ أثناء تسجيل الدخول عبر Google. حاول مرة أخرى.");
  }

  Future<void> _login() async {
    if (!_termsAccepted) {
      return;
    }
    if (loading || googleLoading) {
      if (kDebugMode) {
        debugPrint('[Auth] email login ignored: another auth request is active');
      }
      return;
    }
    final trimmedEmail = email.text.trim();
    final trimmedPassword = password.text.trim();
    if (trimmedEmail.isEmpty || trimmedPassword.isEmpty) {
      _showAuthSnack(mainText(context, "الرجاء إدخال البريد الإلكتروني وكلمة المرور."));
      return;
    }
    if (!mounted) return;
    setState(() => loading = true);
    if (kDebugMode) {
      debugPrint('[Auth] email login started: $trimmedEmail');
    }
    try {
      User? user;
      try {
        final credential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: trimmedEmail,
          password: trimmedPassword,
        );
        user = credential.user;
      } on FirebaseAuthMultiFactorException catch (e) {
        if (!mounted) return;
        final ok = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => MfaSignInPage(resolver: e.resolver),
          ),
        );
        if (ok != true) return;
        user = FirebaseAuth.instance.currentUser;
      }

      if (user != null) {
        final isPasswordUser =
        user.providerData.any((info) => info.providerId == 'password');
        if (isPasswordUser && !user.emailVerified) {
          await SessionService.instance.revokeCurrentSession(user.uid);
          await AuthSessionService.signOutFully();
          if (!mounted) return;
          await _showUnverifiedDialog(trimmedEmail, trimmedPassword);
          return;
        }
      }
      if (user != null) {
        if (kDebugMode) {
          debugPrint('[Auth] email login success uid=${user.uid}');
        }
        await SessionService.instance.initSession(user.uid, forceNew: true,
        );
      }
    } on FirebaseAuthException catch (e, stackTrace) {
      debugPrint('Login failed: ${e.code} ${e.message}');
      debugPrintStack(stackTrace: stackTrace);
      _showAuthSnack(_mapAuthError(e));
    } catch (e, stackTrace) {
      debugPrint('Login failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      _showAuthSnack(mainText(context, "حدث خطأ أثناء تسجيل الدخول."));
    } finally {
      if (kDebugMode) {
        debugPrint('[Auth] email login finished loading=false');
      }
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _showUnverifiedDialog(
      String email,
      String password,
      ) async {
    final localizations = S.of(context);
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(localizations.verifyEmailTitle),
          content: Text(localizations.verifyEmailToContinue),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(localizations.cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _resendVerificationEmail(email, password);
              },
              child: Text(localizations.resendVerificationEmail),
            ),
            // FilledButton(
            //   onPressed: () {
            //     Navigator.of(dialogContext).pop();
            //     Navigator.of(context).push(
            //       MaterialPageRoute(
            //         builder: (_) => VerifyEmailScreen(
            //           email: email,
            //           password: password,
            //         ),
            //       ),
            //     );
            //   },
            //   child: Text(localizations.checkNow),
            // ),
          ],
        );
      },
    );
  }

  Future<void> _resendVerificationEmail(
      String email,
      String password,
      ) async {
    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final user = credential.user;
      if (user == null) {
        _showAuthSnack(S.of(context).genericAuthError);
        return;
      }
      await user.sendEmailVerification();
      await SessionService.instance.revokeCurrentSession(user.uid);
      await AuthSessionService.signOutFully();
      _showAuthSnack(S.of(context).verificationEmailSent);
    } on FirebaseAuthException catch (e) {
      _showAuthSnack(_mapAuthError(e));
    } catch (e, stackTrace) {
      debugPrint('Resend verification failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      _showAuthSnack(S.of(context).genericAuthError);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!_termsAccepted) {
      return;
    }
    if (googleLoading || loading) {
      if (kDebugMode) {
        debugPrint('[Auth] google login ignored: another auth request is active');
      }
      return;
    }
    if (!mounted) return;
    setState(() => googleLoading = true);
    if (kDebugMode) {
      debugPrint('[Auth] google login started');
    }
    try {
      // تأكد من إضافة SHA-1/SHA-256 في Firebase لكل من debug/release عند الحاجة.
      if (kDebugMode) {
        debugPrint('[Auth] google login before GoogleSignIn.signIn()');
      }
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Google sign-in canceled by user.');
        _showAuthSnack(
          _mapGoogleAuthError(
            PlatformException(code: 'sign_in_canceled'),
          ),
        );
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      if (kDebugMode) {
        debugPrint('[Auth] google login credential ready (idToken=${googleAuth.idToken != null})');
      }
      User? user;
      try {
        user = (await FirebaseAuth.instance.signInWithCredential(credential)).user;
      } on FirebaseAuthMultiFactorException catch (e) {
        if (!mounted) return;
        final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(
          builder: (_) => MfaSignInPage(resolver: e.resolver),
        ));
        if (ok != true) return;
        user = FirebaseAuth.instance.currentUser;
      }
      if (kDebugMode) {
        debugPrint('[Auth] google login FirebaseAuth.currentUser=${FirebaseAuth.instance.currentUser?.uid ?? 'null'}');
      }
      if (user != null) {
        await SessionService.instance.initSession(user.uid, forceNew: true);
        if (kDebugMode) {
          debugPrint('[Auth] google login success uid=${user.uid}');
        }
      }
    } on FirebaseAuthException catch (e, stackTrace) {
      debugPrint(
        'Google sign-in failed (FirebaseAuthException): code=${e.code}, message=${e.message}',
      );
      debugPrintStack(stackTrace: stackTrace);
      _showAuthSnack(_mapGoogleAuthError(e));
    } on PlatformException catch (e, stackTrace) {
      debugPrint(
        'Google sign-in platform error: code=${e.code}, message=${e.message}, details=${e.details}',
      );
      debugPrintStack(stackTrace: stackTrace);
      _showAuthSnack(_mapGoogleAuthError(e));
    } catch (e, stackTrace) {
      debugPrint('Google sign-in failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      _showAuthSnack(mainText(context, "حدث خطأ أثناء تسجيل الدخول عبر Google. حاول مرة أخرى."));
    } finally {
      if (kDebugMode) {
        debugPrint('[Auth] google login finished loading=false');
      }
      if (mounted) setState(() => googleLoading = false);
    }
  }

  Future<void> _register() async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignUpFlowScreen()),
    );
  }

  Future<void> _showForgotPasswordSheet() => showPasswordResetSheet(context, initialEmail: email.text.trim());

  bool get _dark => Theme.of(context).brightness == Brightness.dark;

  Color get _accent => _dark ? UniSpaceColors.mint : UniSpaceBrand.forest;

  Color get _bg => UniSpaceColors.background(_dark);
  Color get _sheet => _dark ? UniSpaceColors.darkSurface : UniSpaceColors.lightSurface;
  Color get _ink => UniSpaceColors.ink(_dark);
  Color get _muted => _dark ? UniSpaceColors.darkMuted : UniSpaceColors.lightMuted;
  Color get _field => _dark ? UniSpaceColors.darkField : UniSpaceColors.lightField;
  Color get _stroke => _dark ? UniSpaceColors.darkBorder : UniSpaceColors.lightBorder;

  InputDecoration _deco({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: _muted),
      suffixIcon: suffix,
      filled: true,
      fillColor: _field,
      labelStyle: TextStyle(color: _muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _stroke),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _stroke),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _accent, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = loading || googleLoading;
    return Theme(
      data: Theme.of(context).copyWith(textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Tajawal')),
      child: Builder(builder: (context) {
      return Scaffold(
      backgroundColor: _bg,
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [_bg, UniSpaceColors.field(_dark)],
        )),
        child: SafeArea(child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            key: const ValueKey('login-scroll'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Center(child: UniSpaceBrandMark(width: 148)),
              const SizedBox(height: 14),
              Text('UniSpace', textDirection: TextDirection.ltr, textAlign: TextAlign.center,
                style: TextStyle(color: _ink, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1)),
              const SizedBox(height: 22),
              Theme(data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(primary: _accent),
              ), child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(color: _sheet, borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: _stroke),
                  boxShadow: [BoxShadow(color: UniSpaceBrand.forest.withValues(alpha: .05), blurRadius: 28, offset: const Offset(0, 12))]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(mainText(context, 'مرحبًا بك'),
                    key: const ValueKey('login-welcome'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _ink, fontSize: 30, height: 1.3, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 26),
                              TextField(
                                controller: email,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(color: _ink),
                                decoration: _deco(
                                  label: S.of(context).email,
                                  icon: Icons.mail_outline_rounded,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: password,
                                obscureText: _obscure,
                                style: TextStyle(color: _ink),
                                decoration: _deco(
                                  label: S.of(context).password,
                                  icon: Icons.lock_outline_rounded,
                                  suffix: IconButton(
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: _muted,
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed:
                                  busy ? null : _showForgotPasswordSheet,
                                  child: Text(
                                    S.of(context).forgotPassword,
                                    style: TextStyle(color: _accent),
                                  ),
                                ),
                              ),
                              Column(
                                children: [
                                  Material(
                                    color: Colors.transparent,
                                    child: CheckboxListTile(
                                      key:
                                          const ValueKey('login-terms-consent'),
                                      value: _termsAccepted,
                                      onChanged: busy ? null : (value) => setState(() =>
                                              _termsAccepted = value ?? false),
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                      visualDensity: VisualDensity.compact,
                                      title: Text(
                                        mainText(context, "أوافق على شروط الاستخدام"),
                                        style: TextStyle(
                                            color: _ink, fontSize: 13.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                height: 54,
                                child: FilledButton(
                                  key: const ValueKey('login-email-submit'),
                                  onPressed: busy || !_termsAccepted ? null : _login,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _accent,
                                    foregroundColor: _dark ? UniSpaceBrand.forest : Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: loading
                                      ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                      : Text(
                                    S.of(context).login,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(children: [Expanded(child: Divider(color: _stroke)),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(mainText(context, 'أو'), style: TextStyle(color: _muted))),
                      Expanded(child: Divider(color: _stroke))])),
                              ConstrainedBox(
                                constraints: const BoxConstraints(minHeight: 50),
                                child: OutlinedButton(
                                  key: const ValueKey('login-google-submit'),
                                  onPressed: busy || !_termsAccepted ? null : _signInWithGoogle,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _ink,
                                    backgroundColor: _dark
                                        ? Colors.transparent
                                        : UniSpaceColors.lightField,
                                    side: BorderSide(color: _stroke),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: googleLoading
                                      ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _ink,
                                    ),
                                  )
                                      :  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      FaIcon(
                                        FontAwesomeIcons.google,
                                        size: 16,
                                        color: Color(0xFFDB4437),
                                      ),
                                      SizedBox(width: 10),
                                      Flexible(child: Text(
                                        mainText(context, "متابعة عبر Google"),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      )),
                                    ],
                                  ),
                                ),
                              ),

                ]),
              )),
                              const SizedBox(height: 14),
                              GestureDetector(
                                onTap: busy ? null : _register,
                                child: Text.rich(
                                  TextSpan(
                                    text: mainText(context, "ليس لديك حساب؟  "),
                                    style: TextStyle(color: _muted),
                                    children: [
                                      TextSpan(
                                        text: S.of(context).register,
                                        style: TextStyle(
                                          color: _accent,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

              const SizedBox(height: 12),
                                  Wrap(
                                    key: const ValueKey('login-legal-details'),
                                    alignment: WrapAlignment.center,
                                    spacing: 2,
                                    runSpacing: 4,
                                    children: [
                                      TextButton(
                                        key: const ValueKey('login-read-terms'),
                                        onPressed: busy
                                            ? null
                                            : () => Navigator.of(context)
                                                    .push<void>(
                                                MaterialPageRoute<void>(
                                                  builder: (_) =>
                                                      const TermsOfUseScreen(),
                                                ),
                                              ),
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              _accent,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          textStyle: const TextStyle(
                                            fontFamily: 'Tajawal',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        child:  Text(mainText(context, "شروط الاستخدام")),
                                      ),
                                      Text(' · ',
                                          style: TextStyle(
                                              color: _muted, fontSize: 12)),
                                      TextButton(
                                      key: const ValueKey('login-read-privacy'),
                                      onPressed: busy
                                          ? null
                                          : () => Navigator.of(context)
                                                    .push<void>(
                                                MaterialPageRoute<void>(
                                                  builder: (_) =>
                                                      const PrivacyPolicyScreen(),
                                                ),
                                              ),
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              _accent,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          textStyle: const TextStyle(
                                            fontFamily: 'Tajawal',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        child:  Text(mainText(context, "سياسة الخصوصية")),
                                      ),
                                      Text(' · ',
                                          style: TextStyle(
                                              color: _muted, fontSize: 12)),
                                      TextButton(
                                      key: const ValueKey('login-read-community'),
                                      onPressed: busy
                                          ? null
                                          : () => Navigator.of(context)
                                                    .push<void>(
                                                MaterialPageRoute<void>(
                                                  builder: (_) =>
                                                      const CommunityGuidelinesScreen(),
                                                ),
                                              ),
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              _accent,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          textStyle: const TextStyle(
                                            fontFamily: 'Tajawal',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        child:  Text(mainText(context, "قواعد المجتمع")),
                                  ),
                                ],
                              ),

                              TextButton(
                                key: const ValueKey('login-authenticator-recovery'),
                                style: TextButton.styleFrom(foregroundColor: _muted),
                                onPressed: busy ? null : () => Navigator.of(context).push<void>(
                                  MaterialPageRoute<void>(builder: (_) => const AccountRecoveryScreen())),
                                child: Text(authSettingsText(context, 'فقدت تطبيق المصادقة؟')),
                              ),

            ]),
          ),
        ))),
      ),
    );
    }));
  }
}

class ReactivateAccountScreen extends StatefulWidget {
  const ReactivateAccountScreen({
    super.key,
    this.onReactivated,
  });

  final VoidCallback? onReactivated;

  @override
  State<ReactivateAccountScreen> createState() =>
      _ReactivateAccountScreenState();
}

class _ReactivateAccountScreenState extends State<ReactivateAccountScreen> {
  bool _busy = false;

  Future<void> _reactivate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _busy = true);
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

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(mainText(context, "تم إعادة تفعيل الحساب"))),
      );

      // يخبر AuthGate بإعادة قراءة الحالة → HomeShell
      widget.onReactivated?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mainText(context, "تعذر إعادة تفعيل الحساب: {0}", <Object?>[e]))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await SessionService.instance.revokeCurrentSession(user.uid);
    }
    await AuthSessionService.signOutFully();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.pause_circle_outline,
                size: 72,
                color: Colors.orange.shade800,
              ),
              const SizedBox(height: 20),
              Text(
                mainText(context, "الحساب معطّل"),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                mainText(context, "حسابك متوقف مؤقتاً. يمكنك إعادة تفعيله الآن للعودة إلى UniSpace."),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _busy ? null : _reactivate,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _busy
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    :  Text(mainText(context, "إعادة تفعيل الحساب")),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _busy ? null : _logout,
                child:  Text(mainText(context, "تسجيل الخروج")),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Home Landing — كروت كليات احترافية + دخول إلى Navigator الدراسة
// ============================================================================



// ============================================================================
// Notes — واجهة ملاحظات احترافية (إنشاء/بحث/تثبيت/أرشفة)
// ============================================================================
