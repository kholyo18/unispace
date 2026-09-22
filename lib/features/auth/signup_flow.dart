import 'package:UniSpace/services/storage_upload_service.dart';
import '../../services/media_upload_limits.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../generated/l10n.dart';
import 'signup_service.dart';

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:UniSpace/core/branding.dart';
import 'package:UniSpace/ui/settings/app_settings.dart';
import 'package:UniSpace/ui/settings/user_profile_service.dart';

class SignUpFlowScreen extends StatefulWidget {
  const SignUpFlowScreen({
    super.key,
    this.initialFirstName = '',
    this.initialLastName = '',
    this.skipAccountCreation = false,
  });

  final String initialFirstName;
  final String initialLastName;
  final bool skipAccountCreation;

  @override
  State<SignUpFlowScreen> createState() => _SignUpFlowScreenState();
}

class AccountSetupFlow extends SignUpFlowScreen {
  const AccountSetupFlow({
    super.key,
    super.initialFirstName,
    super.initialLastName,
    super.skipAccountCreation,
  });
}

enum _SignUpPage { welcome, account, verify, username, photos, identity, academic }

class _SignUpFlowScreenState extends State<SignUpFlowScreen> {
  /// أعدها true بعد إصلاح Firebase للتحقق من البريد.
  static const bool kRequireEmailVerification = false;

  final _pageCtrl = PageController();
  final _service = SignupService();
  final _accountKey = GlobalKey<FormState>();
  final _usernameKey = GlobalKey<FormState>();

  late final TextEditingController _first;
  late final TextEditingController _last;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _username = TextEditingController();
  final _college = TextEditingController();
  final _department = TextEditingController();
  final _major = TextEditingController();
  final _level = TextEditingController();

  int _index = 0;
  bool _busy = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _checkingUsername = false;
  bool? _usernameAvailable;
  String? _usernameStatus;
  Timer? _usernameDebounce;
  Timer? _cooldownTimer;
  int _cooldownRemaining = 0;
  DateTime? _birth;
  String? _gender;
  XFile? _photo;
  XFile? _cover;

  static final _usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

  bool get _dark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _dark ? const Color(0xFF071114) : const Color(0xFFF2F7F6);
  Color get _ink => _dark ? const Color(0xFFF4FBFA) : const Color(0xFF102027);
  Color get _muted => _dark ? const Color(0xFF9BB0B8) : const Color(0xFF5B6E75);
  Color get _field => _dark ? const Color(0xFF111C21) : const Color(0xFFF4F8F8);
  Color get _stroke => _dark ? const Color(0xFF24343C) : const Color(0xFFD5E2E4);

  List<_SignUpPage> get _pages {
    if (widget.skipAccountCreation) {
      return const [
        _SignUpPage.welcome,
        _SignUpPage.identity,
        _SignUpPage.username,
        _SignUpPage.photos,
        _SignUpPage.academic,
      ];
    }
    return [
      _SignUpPage.welcome,
      _SignUpPage.account,
      if (kRequireEmailVerification) _SignUpPage.verify,
      _SignUpPage.username,
      _SignUpPage.photos,
      _SignUpPage.identity,
      _SignUpPage.academic,
    ];
  }

  _SignUpPage get _current => _pages[_index];
  bool get _lastPage => _index >= _pages.length - 1;

  @override
  void initState() {
    super.initState();
    _first = TextEditingController(text: widget.initialFirstName);
    _last = TextEditingController(text: widget.initialLastName);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _username.dispose();
    _college.dispose();
    _department.dispose();
    _major.dispose();
    _level.dispose();
    _usernameDebounce?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }




  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _go(int i) async {
    setState(() => _index = i.clamp(0, _pages.length - 1));
    await _pageCtrl.animateToPage(
      _index,
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _back() async {
    if (_index == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    await _go(_index - 1);
  }

  Future<void> _next() async {
    switch (_current) {
      case _SignUpPage.account:
        if (!await _createAccount()) return;
        break;
      case _SignUpPage.verify:
        if (!await _checkVerification()) return;
        break;
      case _SignUpPage.username:
        if (!_validateUsername()) return;
        break;
      case _SignUpPage.identity:
        if (_first.text.trim().isEmpty) {
          _snack('الاسم مطلوب');
          return;
        }
        break;
      case _SignUpPage.academic:
        await _finish(skipAcademic: false);
        return;
      case _SignUpPage.welcome:
      case _SignUpPage.photos:
        break;
    }
    if (!_lastPage) await _go(_index + 1);
  }

  Future<void> _skip() async {
    switch (_current) {
      case _SignUpPage.welcome:
      case _SignUpPage.photos:
        await _go(_index + 1);
        return;
      case _SignUpPage.academic:
        await _finish(skipAcademic: true);
        return;
      default:
        return;
    }
  }

  bool get _canSkip =>
      _current == _SignUpPage.welcome ||
          _current == _SignUpPage.photos ||
          _current == _SignUpPage.academic;

  Future<bool> _createAccount() async {
    if (!_accountKey.currentState!.validate()) return false;
    if (FirebaseAuth.instance.currentUser != null) return true;
    setState(() => _busy = true);
    try {
      await _service.startSignup(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );
      if (!mounted) return false;
      if (kRequireEmailVerification) {
        _startCooldown(60);
        _snack(S.of(context).verificationEmailSent);
      }
      return true;
    } on SignupServiceException catch (e) {
      _snack(_mapSignupError(e.code));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _validateUsername() {
    if (!_usernameKey.currentState!.validate()) return false;
    if (_usernameAvailable != true) {
      _snack('يرجى اختيار اسم مستخدم متاح.');
      return false;
    }
    return true;
  }

  int _usernameGeneration = 0;
  void _handleUsernameChange(String value) {
    final generation = ++_usernameGeneration;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    bool current() => mounted && generation == _usernameGeneration && uid == FirebaseAuth.instance.currentUser?.uid;
    setState(() { _usernameAvailable = null; _usernameStatus = null; _checkingUsername = false; });
    _usernameDebounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _usernameAvailable = null;
        _usernameStatus = null;
      });
      return;
    }
    if (!_usernameRegex.hasMatch(trimmed)) {
      setState(() {
        _usernameAvailable = false;
        _usernameStatus = 'الاسم يجب أن يكون 3-20 أحرف (a-z, 0-9, _)';
      });
      return;
    }
    _usernameDebounce = Timer(const Duration(milliseconds: 400), () async {
      if (!current()) return;
      setState(() => _checkingUsername = true);
      try {
        final result = await _service.checkUsername(trimmed);
        if (!current()) return;
        setState(() {
          _usernameAvailable = result.available;
          _usernameStatus =
          result.available ? 'متاح وقت الفحص (غير محجوز)' : result.reason ?? 'مستعمل';
        });
      } on SignupServiceException catch (e) {
        if (!current()) return;
        setState(() {
          _usernameAvailable = null;
          _usernameStatus = _mapSignupError(e.code);
        });
      } finally {
        if (current()) setState(() => _checkingUsername = false);
      }
    });
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    setState(() => _cooldownRemaining = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownRemaining <= 1) {
        timer.cancel();
        if (mounted) setState(() => _cooldownRemaining = 0);
      } else if (mounted) {
        setState(() => _cooldownRemaining--);
      }
    });
  }

  Future<void> _resendVerification() async {
    setState(() => _busy = true);
    try {
      await _service.resendEmailVerification();
      if (!mounted) return;
      _startCooldown(60);
      _snack(S.of(context).verificationEmailSent);
    } on SignupServiceException catch (e) {
      _snack(_mapSignupError(e.code));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _checkVerification() async {
    setState(() => _busy = true);
    try {
      final verified = await _service.checkEmailVerified();
      if (!mounted) return false;
      if (!verified) {
        _snack(S.of(context).emailNotVerifiedYet);
        return false;
      }
      return true;
    } on SignupServiceException catch (e) {
      _snack(_mapSignupError(e.code));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openEmailApp() async {
    final emailUri = Uri(scheme: 'mailto');
    if (!await launchUrl(emailUri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      _snack('تعذر فتح تطبيق البريد.');
    }
  }

  Future<String?> _upload(XFile file, String name) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final ref = FirebaseStorage.instance.ref('users/$uid/$name');
    final image = File(file.path);
    validateMediaUploadSize(await image.length(), video: false);
    if (FirebaseAuth.instance.currentUser?.uid != uid) throw StateError('تغيّر الحساب');
    await StorageUploadService.putFile(ref, image, SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();
    if (FirebaseAuth.instance.currentUser?.uid != uid) throw StateError('تغيّر الحساب');
    return url;
  }

  Future<void> _pick({required bool cover}) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    setState(() {
      if (cover) {
        _cover = file;
      } else {
        _photo = file;
      }
    });
  }

  Future<void> _finish({required bool skipAcademic}) async {
    if (_first.text.trim().isEmpty) {
      final i = _pages.indexOf(_SignUpPage.identity);
      _snack('الاسم مطلوب');
      await _go(i);
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack('انتهت الجلسة. سجّل الدخول ثم أكمل الملف.');
      return;
    }

    setState(() => _busy = true);
    try {
      String? photoUrl;
      String? coverUrl;
      if (_photo != null) photoUrl = await _upload(_photo!, 'profile.jpg');
      if (_cover != null) coverUrl = await _upload(_cover!, 'cover.jpg');

      final first = _first.text.trim();
      final last = _last.text.trim();
      final full = last.isEmpty ? first : '$first $last';
      await user.updateDisplayName(full);
      if (photoUrl != null) await user.updatePhotoURL(photoUrl);

      final college = skipAcademic ? '' : _college.text.trim();
      final department = skipAcademic ? '' : _department.text.trim();
      final major = skipAcademic ? '' : _major.text.trim();
      final level = skipAcademic ? '' : _level.text.trim();

      await _service.completeProfile({
        'firstName': first,
        'lastName': last,
        'username': _username.text.trim(),
        'birthDate': _birth?.millisecondsSinceEpoch,
        'gender': _gender,
        if (photoUrl != null) 'profileImageUrl': photoUrl,
        if (coverUrl != null) 'coverImageUrl': coverUrl,
        'college': college,
        'department': department,
        'major': major,
        'level': level,
      }, expectedUid: user.uid);

      if (!skipAcademic && college.isNotEmpty) {
        await AppSettings.instance.setAcademicShortcut(
          hasAcademicShortcut: true,
          facultyId: college,
          departmentId: department,
          specialtyId: major,
          level: level,
          facultyName: college,
          departmentName: department,
          specialtyName: major,
        );
        try {
          await UserProfileService.instance.updateAcademic(
            college: college,
            major: major,
            level: level,
          );
        } catch (_) {}
      }

      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      _snack(e is SignupServiceException && e.code == 'already-exists'
          ? 'اسم المستخدم حُجز لحساب آخر، اختر اسمًا مختلفًا' : 'تعذر حفظ الملف: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _mapSignupError(String code) {
    final l = S.of(context);
    switch (code) {
      case 'email-already-in-use':
        return l.emailAlreadyInUseError;
      case 'invalid-email':
        return l.invalidEmailError;
      case 'weak-password':
        return l.weakPasswordError;
      case 'operation-not-allowed':
        return l.emailAuthDisabledError;
      case 'user-disabled':
        return l.userDisabledError;
      case 'user-not-found':
        return l.userNotFoundError;
      case 'wrong-password':
        return l.wrongPasswordError;
      case 'too-many-requests':
        return l.tooManyRequestsError;
      case 'network-request-failed':
        return l.networkError;
      case 'missing-user':
        return l.verifyEmailToContinue;
      default:
        return l.genericAuthError;
    }
  }

  InputDecoration _deco({
    required String label,
    IconData? icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon, size: 20, color: _muted),
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

  Widget _shell({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _busy ? null : _back,
                icon: Icon(Icons.arrow_back_rounded, color: _ink),
              ),
              Expanded(
                child: Row(
                  children: List.generate(_pages.length, (i) {
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        height: 4,
                        margin: EdgeInsets.only(left: i == _pages.length - 1 ? 0 : 5),
                        decoration: BoxDecoration(
                          color: i <= _index ? AppTeal.main : _stroke,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              if (_canSkip)
                TextButton(
                  onPressed: _busy ? null : _skip,
                  child: Text('تخطي', style: TextStyle(color: _muted)),
                )
              else
                const SizedBox(width: 64),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: TextStyle(
              color: _ink,
              fontSize: 30,
              height: 1.15,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: _muted, fontSize: 15, height: 1.45)),
          const SizedBox(height: 20),
          Expanded(child: child),
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: _busy ? null : _next,
              style: FilledButton.styleFrom(
                backgroundColor: AppTeal.main,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: _busy
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : Text(
                _lastPage ? 'إنهاء والدخول' : 'متابعة',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageWelcome() {
    Widget feature(IconData icon, String title, String hint) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _field,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _stroke),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTeal.main.withValues(alpha: _dark ? 0.22 : 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTeal.main, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: TextStyle(color: _muted, fontSize: 12, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return _shell(
      title: 'Welcome to UniSpace. ',
      subtitle: 'Made by students for students. ',
      child: ListView(
        children: [
          Center(
            child: SizedBox(
              width: 128,
              height: 128,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTeal.main.withValues(alpha: 0.28),
                        width: 1.5,
                      ),
                    ),
                  ),
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
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
                          color: AppTeal.main.withValues(alpha: _dark ? 0.5 : 0.3),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'UniSpace',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 22),
          feature(
            Icons.groups_2_outlined,
            'المجتمع',
            'منشورات وزملاء من كليتك',
          ),
          feature(
            Icons.chat_bubble_outline_rounded,
            'المحادثات',
            'تواصل مباشر مع دفعتك',
          ),
          feature(
            Icons.calculate_outlined,
            'المعدل',
            'حاسبة سريعة لموادك',
          ),
        ],
      ),
    );
  }

  Widget _pageAccount() {
    return _shell(
      title: 'حسابك',
      subtitle: 'البريد وكلمة المرور لإنشاء الحساب.',
      child: Form(
        key: _accountKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _email,
              style: TextStyle(color: _ink),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: _deco(label: 'البريد الإلكتروني', icon: Icons.mail_outline_rounded),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'البريد الإلكتروني مطلوب.';
                final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                if (!emailRegex.hasMatch(value.trim())) return 'صيغة البريد الإلكتروني غير صحيحة.';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              style: TextStyle(color: _ink),
              obscureText: _obscurePass,
              textInputAction: TextInputAction.next,
              decoration: _deco(
                label: 'كلمة المرور',
                icon: Icons.lock_outline,
                suffix: IconButton(
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: _muted),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'كلمة المرور مطلوبة.';
                if (v.trim().length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل.';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirm,
              style: TextStyle(color: _ink),
              obscureText: _obscureConfirm,
              decoration: _deco(
                label: 'تأكيد كلمة المرور',
                icon: Icons.lock_reset_outlined,
                suffix: IconButton(
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: _muted),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'يرجى تأكيد كلمة المرور.';
                if (v.trim() != _password.text.trim()) return 'كلمة المرور غير متطابقة.';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  /// مخفي ما دام kRequireEmailVerification = false
  Widget _pageVerify() {
    return _shell(
      title: S.of(context).verifyEmailTitle,
      subtitle: S.of(context).verifyEmailToContinue,
      child: ListView(
        children: [
          Text(S.of(context).verifyEmailHelper, style: TextStyle(color: _muted, fontSize: 13)),
          const SizedBox(height: 20),
          TextButton(
            onPressed: _busy ? null : _openEmailApp,
            child: Text('فتح البريد', style: TextStyle(color: AppTeal.main, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy || _cooldownRemaining > 0 ? null : _resendVerification,
            child: Text(
              _cooldownRemaining > 0
                  ? S.of(context).resendVerificationCooldown(_cooldownRemaining)
                  : S.of(context).resendVerificationEmail,
              style: TextStyle(color: _muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageUsername() {
    return _shell(
      title: 'اسم المستخدم',
      subtitle: 'سيظهر في ملفك الشخصي.',
      child: Form(
        key: _usernameKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _username,
              style: TextStyle(color: _ink),
              onChanged: _handleUsernameChange,
              decoration: _deco(
                label: 'اسم المستخدم',
                icon: Icons.alternate_email,
                suffix: _checkingUsername
                    ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                )
                    : null,
              ),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) return 'اسم المستخدم مطلوب.';
                if (!_usernameRegex.hasMatch(trimmed)) return 'يسمح فقط بالأحرف والأرقام و _';
                return null;
              },
            ),
            const SizedBox(height: 12),
            if (_usernameStatus != null)
              Row(
                children: [
                  Icon(
                    _usernameAvailable == true ? Icons.check_circle : Icons.error_outline,
                    color: _usernameAvailable == true ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: Text(_usernameStatus!, style: TextStyle(color: _muted))),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _pagePhotos() {
    return _shell(
      title: 'صورتك',
      subtitle: 'غلاف وصورة شخصية. يمكنك التخطي.',
      child: ListView(
        children: [
          SizedBox(
            height: 210,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: () => _pick(cover: true),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _field,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _stroke),
                      image: _cover == null
                          ? null
                          : DecorationImage(image: FileImage(File(_cover!.path)), fit: BoxFit.cover),
                    ),
                    alignment: Alignment.center,
                    child: _cover == null ? Text('إضافة غلاف', style: TextStyle(color: _muted)) : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => _pick(cover: false),
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: _bg,
                        child: CircleAvatar(
                          radius: 42,
                          backgroundColor: _field,
                          backgroundImage: _photo == null ? null : FileImage(File(_photo!.path)),
                          child: _photo == null ? Icon(Icons.camera_alt_outlined, color: _muted) : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageIdentity() {
    return _shell(
      title: 'من أنت؟',
      subtitle: 'الاسم إلزامي. الباقي اختياري.',
      child: ListView(
        children: [
          TextField(
            controller: _first,
            style: TextStyle(color: _ink),
            onChanged: (_) => setState(() {}),
            decoration: _deco(label: 'الاسم *', icon: Icons.person_outline),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _last,
            style: TextStyle(color: _ink),
            decoration: _deco(label: 'اللقب', icon: Icons.badge_outlined),
          ),
          const SizedBox(height: 12),
          Material(
            color: _field,
            borderRadius: BorderRadius.circular(16),
            child: ListTile(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(1950),
                  lastDate: now,
                  initialDate: DateTime(now.year - 18),
                );
                if (picked != null) setState(() => _birth = picked);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: _stroke),
              ),
              title: Text(
                _birth == null ? 'تاريخ الميلاد' : '${_birth!.day}/${_birth!.month}/${_birth!.year}',
                style: TextStyle(color: _birth == null ? _muted : _ink),
              ),
              trailing: Icon(Icons.calendar_today_outlined, color: _muted, size: 18),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in ['ذكر', 'أنثى', 'أفضل عدم القول'])
                ChoiceChip(
                  label: Text(g),
                  selected: _gender == g,
                  selectedColor: AppTeal.main.withValues(alpha: 0.22),
                  labelStyle: TextStyle(
                    color: _gender == g ? AppTeal.main : _ink,
                    fontWeight: FontWeight.w700,
                  ),
                  side: BorderSide(color: _gender == g ? AppTeal.main : _stroke),
                  backgroundColor: _field,
                  onSelected: (_) => setState(() => _gender = g),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pageAcademic() {
    return _shell(
      title: 'دراستك',
      subtitle: 'الكلية والتخصص والمستوى — يمكن تخطيها.',
      child: ListView(
        children: [
          TextField(controller: _college, style: TextStyle(color: _ink), decoration: _deco(label: 'الكلية / الجامعة')),
          const SizedBox(height: 12),
          TextField(controller: _department, style: TextStyle(color: _ink), decoration: _deco(label: 'القسم')),
          const SizedBox(height: 12),
          TextField(controller: _major, style: TextStyle(color: _ink), decoration: _deco(label: 'التخصص')),
          const SizedBox(height: 12),
          TextField(controller: _level, style: TextStyle(color: _ink), decoration: _deco(label: 'المستوى')),
        ],
      ),
    );
  }

  Widget _buildPage(_SignUpPage page) {
    switch (page) {
      case _SignUpPage.welcome:
        return _pageWelcome();
      case _SignUpPage.account:
        return _pageAccount();
      case _SignUpPage.verify:
        return _pageVerify();
      case _SignUpPage.identity:
        return _pageIdentity();
      case _SignUpPage.username:
        return _pageUsername();
      case _SignUpPage.photos:
        return _pagePhotos();
      case _SignUpPage.academic:
        return _pageAcademic();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -70,
            child: IgnorePointer(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTeal.main.withValues(alpha: _dark ? 0.45 : 0.2),
                      AppTeal.main.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _index = i),
              children: _pages.map(_buildPage).toList(),
            ),
          ),
        ],
      ),
    );
  }
}