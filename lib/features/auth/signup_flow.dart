import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../generated/l10n.dart';
import 'signup_service.dart';

class SignUpFlowScreen extends StatefulWidget {
  const SignUpFlowScreen({super.key});

  @override
  State<SignUpFlowScreen> createState() => _SignUpFlowScreenState();
}

class _SignUpFlowScreenState extends State<SignUpFlowScreen> {
  final _service = SignupService();

  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();

  int _stepIndex = 0;
  bool _loading = false;
  bool _checkingUsername = false;
  bool? _usernameAvailable;
  String? _usernameStatus;
  Timer? _usernameDebounce;

  Timer? _cooldownTimer;
  int _cooldownRemaining = 0;

  static final _usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _usernameDebounce?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _setStep(int index) {
    setState(() => _stepIndex = index);
  }

  void _handleUsernameChange(String value) {
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
      setState(() {
        _checkingUsername = true;
      });
      try {
        final result = await _service.checkUsername(trimmed);
        if (!mounted) return;
        setState(() {
          _usernameAvailable = result.available;
          _usernameStatus = result.available
              ? 'متاح'
              : result.reason ?? 'مستعمل';
        });
      } on SignupServiceException catch (e) {
        if (!mounted) return;
        setState(() {
          _usernameAvailable = null;
          _usernameStatus = _mapSignupError(e.code);
        });
      } finally {
        if (mounted) {
          setState(() {
            _checkingUsername = false;
          });
        }
      }
    });
  }

  Future<void> _continueFromStep1() async {
    if (!_step1Key.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _service.startSignup(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      _startCooldown(60);
      _showSnack(S.of(context).verificationEmailSent);
      _setStep(1);
    } on SignupServiceException catch (e) {
      _showSnack(_mapSignupError(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continueFromStep2() async {
    if (!_step2Key.currentState!.validate()) return;
    if (_usernameAvailable != true) {
      _showSnack('يرجى اختيار اسم مستخدم متاح.');
      return;
    }
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    setState(() {
      _cooldownRemaining = seconds;
    });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownRemaining <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() => _cooldownRemaining = 0);
        }
      } else {
        if (mounted) {
          setState(() => _cooldownRemaining--);
        }
      }
    });
  }

  Future<void> _resendVerification() async {
    setState(() => _loading = true);
    try {
      await _service.resendEmailVerification();
      if (!mounted) return;
      _startCooldown(60);
      _showSnack(S.of(context).verificationEmailSent);
    } on SignupServiceException catch (e) {
      _showSnack(_mapSignupError(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkVerification() async {
    setState(() => _loading = true);
    try {
      final verified = await _service.checkEmailVerified();
      if (!mounted) return;
      if (verified) {
        _setStep(2);
      } else {
        _showSnack(S.of(context).emailNotVerifiedYet);
      }
    } on SignupServiceException catch (e) {
      _showSnack(_mapSignupError(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEmailApp() async {
    final emailUri = Uri(scheme: 'mailto');
    if (!await launchUrl(emailUri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      _showSnack('تعذر فتح تطبيق البريد.');
    }
  }

  String _mapSignupError(String code) {
    final localizations = S.of(context);
    switch (code) {
      case 'email-already-in-use':
        return localizations.emailAlreadyInUseError;
      case 'invalid-email':
        return localizations.invalidEmailError;
      case 'weak-password':
        return localizations.weakPasswordError;
      case 'operation-not-allowed':
        return localizations.emailAuthDisabledError;
      case 'user-disabled':
        return localizations.userDisabledError;
      case 'user-not-found':
        return localizations.userNotFoundError;
      case 'wrong-password':
        return localizations.wrongPasswordError;
      case 'too-many-requests':
        return localizations.tooManyRequestsError;
      case 'network-request-failed':
        return localizations.networkError;
      case 'missing-user':
        return localizations.verifyEmailToContinue;
      default:
        return localizations.genericAuthError;
    }
  }

  Widget _buildStepper() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (index) {
            final isActive = _stepIndex >= index;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsetsDirectional.only(
                  end: index == 2 ? 0 : 8,
                ),
                height: 6,
                decoration: BoxDecoration(
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          'الخطوة ${_stepIndex + 1} من 3',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ],
    );
  }

  Widget _buildCard({Key? key, required Widget child}) {
    return Card(
      key: key,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_stepIndex) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep3();
      case 2:
        return _buildStep2();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1() {
    return Form(
      key: _step1Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إنشاء حساب جديد',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإدخال بياناتك الأساسية.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'الاسم',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الاسم مطلوب.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'اللقب',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'اللقب مطلوب.';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'البريد الإلكتروني',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'البريد الإلكتروني مطلوب.';
              }
              final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'صيغة البريد الإلكتروني غير صحيحة.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'كلمة المرور',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'كلمة المرور مطلوبة.';
              }
              if (value.trim().length < 6) {
                return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'تأكيد كلمة المرور',
              prefixIcon: Icon(Icons.lock_reset_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'يرجى تأكيد كلمة المرور.';
              }
              if (value.trim() != _passwordController.text.trim()) {
                return 'كلمة المرور غير متطابقة.';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _continueFromStep1,
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('استمرار'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _step2Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اختيار اسم المستخدم',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'هذا الاسم سيظهر في ملفك الشخصي.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _usernameController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'اسم المستخدم',
              prefixIcon: const Icon(Icons.alternate_email),
              suffixIcon: _checkingUsername
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            onChanged: _handleUsernameChange,
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) {
                return 'اسم المستخدم مطلوب.';
              }
              if (!_usernameRegex.hasMatch(trimmed)) {
                return 'يسمح فقط بالأحرف والأرقام و _';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          if (_usernameStatus != null)
            Row(
              children: [
                Icon(
                  _usernameAvailable == true
                      ? Icons.check_circle
                      : Icons.error_outline,
                  color: _usernameAvailable == true
                      ? Colors.green
                      : Colors.orange,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _usernameStatus!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _continueFromStep2,
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('استمرار'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).verifyEmailTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          S.of(context).verifyEmailToContinue,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Text(
          S.of(context).verifyEmailHelper,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        Center(
          child: TextButton(
            onPressed: _loading ? null : _openEmailApp,
            child: const Text('فتح البريد'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _checkVerification,
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(S.of(context).checkNow),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed:
                _loading || _cooldownRemaining > 0 ? null : _resendVerification,
            child: Text(
              _cooldownRemaining > 0
                  ? S.of(context).resendVerificationCooldown(
                        _cooldownRemaining,
                      )
                  : S.of(context).resendVerificationEmail,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[700],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: _stepIndex == 0
              ? () => Navigator.of(context).pop()
              : () => _setStep(_stepIndex - 1),
        ),
        title: const Text('إنشاء حساب'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStepper(),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) {
                      final offsetTween = Tween<Offset>(
                        begin: const Offset(0.08, 0),
                        end: Offset.zero,
                      );
                      return SlideTransition(
                        position: animation.drive(offsetTween),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: _buildCard(
                      key: ValueKey(_stepIndex),
                      child: _buildStepContent(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
