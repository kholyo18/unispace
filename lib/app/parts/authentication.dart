part of '../../main.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
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
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (ctx, snap) {
            if (Firebase.apps.isEmpty) {
              return  Scaffold(
                body: Center(
                  child: Text(mainText(ctx, "تعذر تشغيل Firebase. أعد فتح التطبيق.")),
                ),
              );
            }
            if (snap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!identical(_lastAuthUser, snap.data)) {
              _lastAuthUser = snap.data;
              if (kDebugMode) {
                debugPrint(
                  '[AuthGate] authStateChanges user=${snap.data?.uid ?? 'null'}',
                );
              }
            }

            if (!snap.hasData) {
              _userDocStream = null;
              _userDocStreamUid = null;
              return const SignInScreen();
            }

            final user = snap.data!;
            final isPasswordUser = user.providerData
                .any((info) => info.providerId == 'password');
// if (isPasswordUser && !user.emailVerified) {
            //   return VerifyEmailScreen(
            //     key: ValueKey('verify_${user.uid}'),
            //     email: user.email ?? '',
            //     password: '',
            //   );
            // }
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _statusStreamFor(user.uid),
              builder: (context, statusSnap) {
                if (statusSnap.hasError) {
                  debugPrint('AuthGate user doc: ${statusSnap.error}');
                  return _routeAuthenticated(user, isPasswordUser);
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
                  return ReactivateAccountScreen(onReactivated: _refreshStatus);
                }

                if (!statusSnap.hasData) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
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
                  return SignUpFlowScreen(
                    skipAccountCreation: isGoogle,
                    initialFirstName: first,
                    initialLastName: last,
                  );
                }

                return _routeAuthenticated(user, isPasswordUser);
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

  String _mapPasswordResetError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return S.of(context).invalidEmailError;
      case 'user-not-found':
        return S.of(context).userNotFoundError;
      case 'too-many-requests':
        return S.of(context).tooManyRequestsError;
      default:
        return S.of(context).resetLinkFailed;
    }
  }

  Future<void> _showForgotPasswordSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ForgotPasswordSheet(
        initialEmail: email.text.trim(),
        onShowSnack: _showAuthSnack,
        mapPasswordResetError: _mapPasswordResetError,
      ),
    );
  }

  bool get _dark => Theme.of(context).brightness == Brightness.dark;

  Color get _bg => _dark ? const Color(0xFF061016) : const Color(0xFFF3F7F6);
  Color get _sheet => _dark ? const Color(0xFF0A1216) : Colors.white;
  Color get _ink => _dark ? Colors.white : const Color(0xFF102027);
  Color get _muted => _dark ? const Color(0xFF9BB0B8) : const Color(0xFF5B6E75);
  Color get _field => _dark ? const Color(0xFF0E171C) : const Color(0xFFF4F7F8);
  Color get _stroke => _dark ? const Color(0xFF1E2C33) : const Color(0xFFD7E3E6);

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
        borderSide: BorderSide(color: AppTeal.main, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = loading || googleLoading;

    return Scaffold(
      backgroundColor: _bg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: _GlowOrb(size: 280, opacity: _dark ? 0.55 : 0.28),
          ),
          Positioned(
            top: 180,
            left: -90,
            child: _GlowOrb(size: 180, opacity: _dark ? 0.28 : 0.16),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                final sheetHeight = c.maxHeight < 560
                    ? c.maxHeight
                    : c.maxHeight * 0.6;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(35, 28, 28, 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'UNISPACE',
                              style: TextStyle(
                                color: AppTeal.main,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                letterSpacing: 3.2,
                              ),
                            ),
                            const SizedBox(height: 50),
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTeal.main,
                                    Color.lerp(AppTeal.main, Colors.black, 0.22)!,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTeal.main.withValues(
                                      alpha: _dark ? 0.45 : 0.28,
                                    ),
                                    blurRadius: 22,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.school_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              mainText(context, "مساحتك الجامعية"),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _ink,
                                fontSize: 42,
                                height: 1.05,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              mainText(context, "Welcome to UniSpace where we all meet"),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _muted,
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: sheetHeight,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                        decoration: BoxDecoration(
                          color: _sheet,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                          border: Border(top: BorderSide(color: _stroke)),
                          boxShadow: _dark
                              ? null
                              : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 24,
                              offset: const Offset(0, -8),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height:5),
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
                                    style: TextStyle(color: AppTeal.main),
                                  ),
                                ),
                              ),
                              // TextButton(
                              //   onPressed: busy ? null : () => Navigator.of(context).push(
                              //     MaterialPageRoute(builder: (_) => const AccountRecoveryScreen())),
                              //   child: const Text('فقدت تطبيق المصادقة؟'),
                              // ),
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
                                  Text(
                                    mainText(context, "اطّلع على"),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: _muted,
                                        fontSize: 12,
                                        height: 1.4),
                                  ),
                                  Row(
                                    key: const ValueKey('login-legal-details'),
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                              const Color(0xFF00376B),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          textStyle: const TextStyle(
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
                                              const Color(0xFF00376B),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          textStyle: const TextStyle(
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
                                              const Color(0xFF00376B),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          textStyle: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        child:  Text(mainText(context, "قواعد المجتمع")),
                                  ),
                                ],
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
                                    backgroundColor: AppTeal.main,
                                    foregroundColor: Colors.white,
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
                                          color: AppTeal.main,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                height: 50,
                                child: OutlinedButton(
                                  key: const ValueKey('login-google-submit'),
                                  onPressed: busy || !_termsAccepted ? null : _signInWithGoogle,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _ink,
                                    backgroundColor: _dark
                                        ? Colors.transparent
                                        : const Color(0xFFF7FAFA),
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
                                      Text(
                                        mainText(context, "متابعة عبر Google"),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
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
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.opacity});
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppTeal.main.withValues(alpha: opacity),
              AppTeal.main.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

typedef _PasswordResetErrorMapper = String Function(FirebaseAuthException error);

class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet({
    required this.initialEmail,
    required this.onShowSnack,
    required this.mapPasswordResetError,
  });

  final String initialEmail;
  final ValueChanged<String> onShowSnack;
  final _PasswordResetErrorMapper mapPasswordResetError;

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  late final TextEditingController _resetEmailController;
  late final FocusNode _resetFocusNode;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _resetEmailController = TextEditingController(text: widget.initialEmail);
    _resetFocusNode = FocusNode();
  }

  @override
  void dispose() {
    // Dispose sheet-owned controllers/nodes to avoid dangling dependents when the sheet is swipe-dismissed.
    _resetEmailController.dispose();
    _resetFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final localizations = S.of(context);
    final trimmedEmail = _resetEmailController.text.trim();
    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      widget.onShowSnack(localizations.invalidEmailValidation);
      return;
    }

    setState(() => _isSending = true);

    try {
      await FirebaseAuth.instance.setLanguageCode(Localizations.localeOf(context).languageCode);
      await FirebaseAuth.instance.sendPasswordResetEmail(email: trimmedEmail);
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onShowSnack(localizations.resetLinkSentSuccess);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      widget.onShowSnack(widget.mapPasswordResetError(e));
    } catch (_) {
      if (!mounted) return;
      widget.onShowSnack(localizations.resetLinkFailed);
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final localizations = S.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 12, 24, viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kUniSpaceBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.lock_reset, color: kUniSpaceBlue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      localizations.resetPasswordTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed:
                    _isSending ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                localizations.resetPasswordHelper,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _resetEmailController,
                focusNode: _resetFocusNode,
                enabled: !_isSending,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined),
                  labelText: localizations.email,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSending ? null : _sendResetEmail,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSending)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      if (_isSending) const SizedBox(width: 12),
                      Text(
                        _isSending
                            ? localizations.sendResetLinkLoading
                            : localizations.sendResetLink,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _isSending ? null : () => Navigator.of(context).pop(),
                  child: Text(localizations.cancel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
