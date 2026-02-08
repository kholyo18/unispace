import 'package:UniSpace/generated/l10n.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';

import '../../../models/security_audit.dart';
import '../../../services/security_audit_service.dart';
import '../session_service.dart';
import 'privacy_account_repository.dart';

class PrivacyAccountOverviewTab extends StatefulWidget {
  const PrivacyAccountOverviewTab({super.key});

  @override
  State<PrivacyAccountOverviewTab> createState() => _PrivacyAccountOverviewTabState();
}

class _PrivacyAccountOverviewTabState extends State<PrivacyAccountOverviewTab> {
  final PrivacyAccountRepository _repository = PrivacyAccountRepository();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FocusNode _currentPasswordFocusNode = FocusNode();
  final FocusNode _newPasswordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  PrivacyAccountData? _data;
  bool _loading = true;
  bool _busy = false;
  bool _updatingPassword = false;
  bool _sendingReset = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _newPasswordTouched = false;
  bool _confirmPasswordTouched = false;
  bool _passwordExpanded = false;
  bool _auditLoading = true;
  SecurityAudit? _lastPasswordAudit;

  @override
  void initState() {
    super.initState();
    _currentPasswordFocusNode.addListener(() {
      if (!_currentPasswordFocusNode.hasFocus) setState(() {});
    });
    _newPasswordFocusNode.addListener(() {
      if (!_newPasswordFocusNode.hasFocus) {
        setState(() => _newPasswordTouched = true);
      }
    });
    _confirmPasswordFocusNode.addListener(() {
      if (!_confirmPasswordFocusNode.hasFocus) {
        setState(() => _confirmPasswordTouched = true);
      }
    });
    _load();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordFocusNode.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await _repository.load();
    final audit = await SecurityAuditService.instance.loadLastPasswordChange();
    if (!mounted) return;
    setState(() {
      _data = data;
      _lastPasswordAudit = audit;
      _loading = false;
      _auditLoading = false;
    });
  }

  bool get _canEditName {
    final changedAt = _data?.lastNameChangeAt;
    if (changedAt == null) return true;
    return DateTime.now().isAfter(changedAt.add(const Duration(days: 30)));
  }

  String _nameRuleText(S s) {
    final changedAt = _data?.lastNameChangeAt;
    if (changedAt == null || _canEditName) return s.privacyNameRuleAllowed;
    final next = changedAt.add(const Duration(days: 30));
    final remaining = next.difference(DateTime.now());
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    if (days > 0) {
      return s.privacyNameRuleBlockedDays('$days', '$hours');
    }
    return s.privacyNameRuleBlockedHours('$hours');
  }

  String _maskedEmail(String email) {
    final trimmed = email.trim();
    if (!trimmed.contains('@')) return '***';
    final parts = trimmed.split('@');
    final local = parts.first;
    final domain = parts.last;
    if (local.isEmpty) return '***@$domain';
    if (local.length <= 3) return '${local[0]}***@$domain';
    return '${local.substring(0, 3)}***@$domain';
  }

  String get _currentPassword => _currentPasswordController.text;
  String get _newPassword => _newPasswordController.text;
  String get _confirmPassword => _confirmPasswordController.text;

  bool get _isNewPasswordLengthValid => _newPassword.trim().length >= 8;
  bool get _isNewPasswordDifferent => _newPassword.trim().isNotEmpty && _newPassword != _currentPassword;
  bool get _isConfirmMatch => _newPassword.isNotEmpty && _confirmPassword == _newPassword;
  bool get _canSubmitPasswordChange =>
      _currentPassword.trim().isNotEmpty &&
      _isNewPasswordLengthValid &&
      _isNewPasswordDifferent &&
      _isConfirmMatch &&
      !_updatingPassword;

  String? get _newPasswordError {
    if (!_newPasswordTouched && _newPasswordFocusNode.hasFocus) return null;
    if (_newPassword.isEmpty) return null;
    if (!_isNewPasswordLengthValid) return 'كلمة المرور الجديدة يجب أن تتكون من 8 أحرف على الأقل';
    if (!_isNewPasswordDifferent) return 'يجب أن تكون كلمة المرور الجديدة مختلفة عن الحالية';
    return null;
  }

  String? get _confirmPasswordError {
    if (!_confirmPasswordTouched && _confirmPasswordFocusNode.hasFocus) return null;
    if (_confirmPassword.isEmpty) return null;
    if (!_isConfirmMatch) return 'كلمتا المرور غير متطابقتين';
    return null;
  }

  ({String label, Color color}) _passwordStrength() {
    final value = _newPassword;
    if (value.isEmpty) {
      return (label: '—', color: Colors.grey);
    }
    int score = 0;
    if (value.length >= 8) score++;
    if (RegExp(r'\d').hasMatch(value)) score++;
    if (RegExp(r'[A-Z]').hasMatch(value) && RegExp(r'[a-z]').hasMatch(value)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-\\/\[\]]').hasMatch(value)) score++;
    if (score <= 1) return (label: 'ضعيف', color: Colors.red);
    if (score <= 3) return (label: 'متوسط', color: Colors.orange);
    return (label: 'قوي', color: Colors.green);
  }

  Future<void> _handleChangePassword() async {
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تأكيد التحديث'),
            content: const Text('هل تريد تحديث كلمة المرور؟'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
              ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('تحديث')),
            ],
          ),
        );
      },
    );

    if (shouldProceed != true) return;

    setState(() => _updatingPassword = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        _snack('تعذر تحديث كلمة المرور، يرجى تسجيل الدخول مرة أخرى');
        return;
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPassword,
      );

      try {
        await user.reauthenticateWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _snack('كلمة المرور الحالية غير صحيحة');
          return;
        }
        _snack('تعذر التحقق من الهوية، حاول لاحقًا');
        return;
      }

      await user.updatePassword(_newPassword);
      final audit = await SecurityAuditService.instance.buildAuditRecord();
      await SecurityAuditService.instance.saveLastPasswordChange(audit);
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() {
        _newPasswordTouched = false;
        _confirmPasswordTouched = false;
        _lastPasswordAudit = audit;
      });
      _snack('تم تحديث كلمة المرور بنجاح');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        _snack('تحقق من اتصال الإنترنت ثم أعد المحاولة');
      } else {
        _snack('تعذر تحديث كلمة المرور، حاول لاحقًا');
      }
    } catch (_) {
      _snack('حدث خطأ غير متوقع، حاول مجددًا');
    } finally {
      if (mounted) setState(() => _updatingPassword = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    final maskedEmail = email == null ? 'غير متوفر' : _maskedEmail(email);

    final send = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إعادة تعيين كلمة المرور'),
            content: Text('سنرسل رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني المسجل: $maskedEmail'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
              ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('إرسال الرابط')),
            ],
          ),
        );
      },
    );

    if (send != true) return;
    setState(() => _sendingReset = true);
    try {
      if (email == null || email.trim().isEmpty) {
        _snack('لا يوجد بريد إلكتروني مرتبط بالحساب');
        return;
      }
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _snack('تم إرسال رابط إعادة التعيين إلى بريدك الإلكتروني');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        _snack('تحقق من اتصال الإنترنت ثم أعد المحاولة');
      } else {
        _snack('تعذر إرسال الرابط، حاول لاحقًا');
      }
    } catch (_) {
      _snack('تعذر إرسال الرابط، حاول لاحقًا');
    } finally {
      if (mounted) setState(() => _sendingReset = false);
    }
  }

  Future<void> _handleEditName() async {
    final s = S.of(context);
    if (_busy || _data == null) return;
    if (!_canEditName) {
      _snack(_nameRuleText(s));
      return;
    }
    final authenticated = await _showReauthSheet();
    if (!authenticated) return;

    final result = await _showNameEditSheet(_data!);
    if (result == null) return;

    setState(() => _busy = true);
    final changedAt = DateTime.now();
    try {
      await _repository.saveName(
        firstName: result.$1,
        lastName: result.$2,
        changedAt: changedAt,
      );
      if (!mounted) return;
      setState(() {
        _data = _data!.copyWith(
          firstName: result.$1,
          lastName: result.$2,
          lastNameChangeAt: changedAt,
        );
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    _snack(s.privacyNameSaved);
  }

  Future<void> _handleEditEmail() async {
    final s = S.of(context);
    if (_busy || _data == null) return;
    final authenticated = await _showReauthSheet();
    if (!authenticated) return;

    final updatedEmail = await _showEmailFlowSheet(_data!.email);
    if (updatedEmail == null) return;

    setState(() => _busy = true);
    try {
      await _repository.saveEmail(updatedEmail);
      if (!mounted) return;
      setState(() {
        _data = _data!.copyWith(email: updatedEmail);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    _snack(s.privacyEmailSaved);
  }

  Future<bool> _showReauthSheet() async {
    final s = S.of(context);
    final passwordController = TextEditingController();
    String? error;
    bool loading = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AnimatedPadding(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(s.privacyReauthTitle, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(s.privacyReauthSubtitle, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: s.password,
                          errorText: error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: loading ? null : () => Navigator.of(context).pop(false),
                              child: Text(s.cancel),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: loading
                                  ? null
                                  : () async {
                                      setModalState(() {
                                        loading = true;
                                        error = null;
                                      });
                                      final ok = await _reauthenticate(passwordController.text);
                                      if (!context.mounted) return;
                                      if (ok) {
                                        Navigator.of(context).pop(true);
                                      } else {
                                        setModalState(() {
                                          loading = false;
                                          error = s.privacyReauthFailed;
                                        });
                                      }
                                    },
                              child: loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(s.privacyContinue),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    return result == true;
  }

  Future<bool> _reauthenticate(String password) async {
    final user = FirebaseAuth.instance.currentUser;
    if (password.trim().isEmpty) return false;
    if (user == null) return false;

    final hasPasswordProvider = user.providerData.any((provider) => provider.providerId == 'password');
    if (hasPasswordProvider && user.email != null) {
      try {
        final credential = EmailAuthProvider.credential(email: user.email!, password: password);
        await user.reauthenticateWithCredential(credential);
        return true;
      } catch (_) {
        return false;
      }
    }

    // TODO(dev): Replace this fallback with a backend-issued ephemeral re-auth token flow.
    return password.trim().length >= 6;
  }

  Future<(String, String)?> _showNameEditSheet(PrivacyAccountData data) async {
    final s = S.of(context);
    final firstController = TextEditingController(text: data.firstName);
    final lastController = TextEditingController(text: data.lastName);
    final formKey = GlobalKey<FormState>();

    return showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(s.privacyEditNameTitle, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: firstController,
                      decoration: InputDecoration(labelText: s.privacyFirstName),
                      validator: (value) => _validateName(value, s),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: lastController,
                      decoration: InputDecoration(labelText: s.privacyLastName),
                      validator: (value) => _validateName(value, s),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (!(formKey.currentState?.validate() ?? false)) return;
                        Navigator.of(context).pop((firstController.text.trim(), lastController.text.trim()));
                      },
                      child: Text(s.save),
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

  String? _validateName(String? value, S s) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return s.privacyNameValidationRequired;
    if (input.length < 2) return s.privacyNameValidationShort;
    if (input.length > 40) return s.privacyNameValidationLong;
    return null;
  }

  Future<String?> _showEmailFlowSheet(String currentEmail) async {
    final s = S.of(context);
    final currentController = TextEditingController();
    final newEmailController = TextEditingController();
    final confirmEmailController = TextEditingController();

    int step = 1;
    bool loading = false;
    String? error;

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AnimatedPadding(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Column(
                      key: ValueKey(step),
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('${s.privacyEmailFlowTitle} (${s.privacyStepOf('$step', '4')})', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text(s.privacyEmailFlowSecurityNote, style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 16),
                        if (step == 1) ...[
                          Text(s.privacyEmailFlowStep1Help(_maskedEmail(currentEmail))),
                          const SizedBox(height: 12),
                          TextField(controller: currentController, decoration: InputDecoration(labelText: s.privacyEmailCurrentLabel)),
                        ] else if (step == 2) ...[
                          Text(s.privacyEmailFlowStep2Help),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: loading
                                      ? null
                                      : () async {
                                          setModalState(() {
                                            loading = true;
                                            error = null;
                                          });
                                          await Future<void>.delayed(const Duration(milliseconds: 1200));
                                          if (!context.mounted) return;
                                          setModalState(() {
                                            loading = false;
                                            step = 3;
                                          });
                                        },
                                  child: loading
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                      : Text(s.privacyEmailFlowSendLink),
                                ),
                              ),
                            ],
                          ),
                        ] else if (step == 3) ...[
                          Text(s.privacyEmailFlowStep3Help),
                          const SizedBox(height: 12),
                          TextField(
                            controller: newEmailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(labelText: s.privacyEmailNewLabel),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: confirmEmailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(labelText: s.privacyEmailConfirmLabel),
                          ),
                        ] else ...[
                          Text(s.privacyEmailFlowStep4Help(_maskedEmail(newEmailController.text.trim()))),
                        ],
                        if (error != null) ...[
                          const SizedBox(height: 10),
                          Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: loading ? null : () => Navigator.of(context).pop(),
                                child: Text(s.cancel),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: loading
                                    ? null
                                    : () {
                                        final validation = _validateStep(
                                          step: step,
                                          currentEmail: currentEmail,
                                          currentInput: currentController.text,
                                          newEmail: newEmailController.text,
                                          confirmEmail: confirmEmailController.text,
                                          s: s,
                                        );
                                        if (validation != null) {
                                          setModalState(() => error = validation);
                                          return;
                                        }
                                        setModalState(() => error = null);
                                        if (step < 4) {
                                          setModalState(() => step += 1);
                                          return;
                                        }
                                        Navigator.of(context).pop(newEmailController.text.trim());
                                      },
                                child: Text(step == 4 ? s.save : s.privacyContinue),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String? _validateStep({
    required int step,
    required String currentEmail,
    required String currentInput,
    required String newEmail,
    required String confirmEmail,
    required S s,
  }) {
    if (step == 1 && currentInput.trim().toLowerCase() != currentEmail.trim().toLowerCase()) {
      return s.privacyEmailCurrentMismatch;
    }
    if (step == 3) {
      final next = newEmail.trim();
      final confirm = confirmEmail.trim();
      if (next.isEmpty || confirm.isEmpty) return s.privacyEmailValidationRequired;
      if (!next.contains('@')) return s.invalidEmailValidation;
      if (next.toLowerCase() != confirm.toLowerCase()) return s.privacyEmailConfirmMismatch;
    }
    return null;
  }


  String _networkLabel(String value) {
    switch (value) {
      case 'wifi':
        return 'Wi-Fi';
      case 'cellular':
        return 'بيانات الهاتف';
      default:
        return 'غير معروف';
    }
  }

  String _dateWithDzTimezone(SecurityAudit audit) {
    final local = audit.timestampUtc.toLocal();
    final formatted = DateFormat('yyyy/MM/dd - HH:mm:ss').format(local);
    return '$formatted (GMT+1 الجزائر)';
  }

  Future<void> _showPasswordAuditDetails() async {
    final audit = _lastPasswordAudit;
    if (audit == null) {
      _snack('لا توجد بيانات متاحة بعد');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        Widget detailRow(String title, String value) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700))),
                const SizedBox(width: 8),
                Expanded(flex: 6, child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
              ],
            ),
          );
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('آخر تغيير كلمة المرور', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                detailRow('التاريخ والوقت', _dateWithDzTimezone(audit)),
                detailRow('الجهاز', [audit.deviceName, audit.deviceModel].whereType<String>().where((v) => v.trim().isNotEmpty).join(' - ').isEmpty ? 'غير متوفر' : [audit.deviceName, audit.deviceModel].whereType<String>().where((v) => v.trim().isNotEmpty).join(' - ')),
                detailRow('الشركة المصنّعة', audit.deviceManufacturer?.trim().isNotEmpty == true ? audit.deviceManufacturer! : 'غير متوفر'),
                detailRow('نظام التشغيل', '${audit.osName ?? 'غير متوفر'} ${audit.osVersion ?? ''}'.trim()),
                detailRow('إصدار التطبيق', '${audit.appVersion ?? 'غير متوفر'} (${audit.buildNumber ?? '-'})'),
                detailRow('نوع الاتصال', _networkLabel(audit.networkType)),
                detailRow('الموقع التقريبي', audit.locationApprox?.trim().isNotEmpty == true ? audit.locationApprox! : 'غير متوفر'),
                detailRow('عنوان IP', audit.maskedIp),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _copyFullIpSecurely,
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('نسخ IP الكامل'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: _handleThisWasNotMe,
                    icon: const Icon(Icons.warning_amber_rounded),
                    label: const Text('هذا ليس أنا'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _copyFullIpSecurely() async {
    final audit = _lastPasswordAudit;
    final ip = audit?.ipAddress?.trim();
    if (ip == null || ip.isEmpty) {
      _snack('عنوان IP غير متوفر');
      return;
    }

    final reAuthed = await _promptSensitiveReAuth();
    if (!reAuthed) return;

    await Clipboard.setData(ClipboardData(text: ip));
    if (!mounted) return;
    Navigator.of(context).pop();
    _snack('تم نسخ IP الكامل بأمان');
  }

  Future<bool> _promptSensitiveReAuth() async {
    final localAuth = LocalAuthentication();
    try {
      final canUseBiometric = await localAuth.canCheckBiometrics && await localAuth.isDeviceSupported();
      if (canUseBiometric) {
        final didAuth = await localAuth.authenticate(
          localizedReason: 'تحقق من هويتك لنسخ IP الكامل',
          options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
        );
        if (didAuth) return true;
      }
    } catch (_) {
      // fallback to password prompt below
    }

    return _showReauthSheet();
  }

  Future<void> _handleThisWasNotMe() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تحذير أمني شديد'),
            content: const Text('إذا لم تكن أنت من غيّر كلمة المرور، سنقوم بتسجيل الخروج من جميع الجلسات فوراً. هل تريد المتابعة؟'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
              ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('متابعة')),
            ],
          ),
        );
      },
    );

    if (confirm != true) return;
    final reAuthed = await _promptSensitiveReAuth();
    if (!reAuthed) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final currentSessionId = await SessionService.instance.getCurrentSessionId(user.uid) ??
            await SessionService.instance.getOrCreateSessionId(user.uid);
        await SessionService.instance.revokeAllOtherSessions(uid: user.uid, currentSessionId: currentSessionId);
      } else {
        throw StateError('No active user');
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      _snack('تم إنهاء الجلسات الأخرى كإجراء احترازي.');
    } catch (_) {
      _snack('تعذر إنهاء جميع الجلسات حالياً. TODO: دعم كامل من الخادم.');
    }

    if (!mounted) return;
    setState(() => _passwordExpanded = true);
    _snack('يرجى تغيير كلمة المرور فوراً. التحقق بخطوتين: قريباً');
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final data = _data;
    if (data == null) {
      return Center(child: Text(s.privacyLoadFailed));
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(s.privacyTabTitle, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(s.privacyTabSubtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700)),
          const SizedBox(height: 20),
          Text(s.privacyAccountOverviewSection, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                    title: Text(s.privacyNameRowTitle),
                    subtitle: Text(data.fullName.isEmpty ? '-' : data.fullName),
                    trailing: IconButton(
                      onPressed: _busy ? null : _handleEditName,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 72, end: 16, bottom: 10),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(_nameRuleText(s), style: Theme.of(context).textTheme.bodySmall),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.email_outlined)),
                    title: Text(s.privacyEmailRowTitle),
                    subtitle: Text(_maskedEmail(data.email)),
                    trailing: IconButton(
                      onPressed: _busy ? null : _handleEditEmail,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.history_toggle_off_rounded)),
              title: const Text('آخر تغيير كلمة المرور'),
              subtitle: Text(
                _auditLoading
                    ? 'جارِ تحميل البيانات...'
                    : (_lastPasswordAudit == null
                        ? 'غير متوفر'
                        : '${_dateWithDzTimezone(_lastPasswordAudit!)} • IP: ${_lastPasswordAudit!.maskedIp}'),
              ),
              trailing: TextButton.icon(
                onPressed: _lastPasswordAudit == null ? null : _showPasswordAuditDetails,
                icon: const Icon(Icons.expand_more),
                label: const Text('عرض التفاصيل'),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ExpansionTile(
              title: const Text('تغيير كلمة المرور', style: TextStyle(fontWeight: FontWeight.w700)),
              leading: const Icon(Icons.password_outlined),
              trailing: Icon(_passwordExpanded ? Icons.expand_less : Icons.expand_more),
              initiallyExpanded: _passwordExpanded,
              onExpansionChanged: (value) => setState(() => _passwordExpanded = value),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                TextField(
                  controller: _currentPasswordController,
                  focusNode: _currentPasswordFocusNode,
                  obscureText: !_showCurrentPassword,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _newPasswordFocusNode.requestFocus(),
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الحالية',
                    helperText: 'أدخل كلمة المرور الحالية لإثبات ملكية الحساب.',
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _showCurrentPassword = !_showCurrentPassword),
                      icon: Icon(_showCurrentPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    ),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: _sendingReset ? null : _handleForgotPassword,
                    child: _sendingReset
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('نسيت كلمة المرور؟'),
                  ),
                ),
                Text(
                  'قد يصل البريد خلال دقيقة، وتأكد من مجلد الرسائل غير المرغوب فيها.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _newPasswordController,
                  focusNode: _newPasswordFocusNode,
                  obscureText: !_showNewPassword,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() => _newPasswordTouched = true),
                  onSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الجديدة',
                    helperText: 'يجب أن تحتوي على 8 أحرف على الأقل.',
                    errorText: _newPasswordError,
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _showNewPassword = !_showNewPassword),
                      icon: Icon(_showNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Builder(
                  builder: (context) {
                    final strength = _passwordStrength();
                    return Row(
                      children: [
                        const Icon(Icons.shield_outlined, size: 16),
                        const SizedBox(width: 6),
                        Text('قوة كلمة المرور: ', style: Theme.of(context).textTheme.bodySmall),
                        Text(
                          strength.label,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: strength.color, fontWeight: FontWeight.w700),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocusNode,
                  obscureText: !_showConfirmPassword,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() => _confirmPasswordTouched = true),
                  onSubmitted: (_) {
                    FocusScope.of(context).unfocus();
                    if (_canSubmitPasswordChange) _handleChangePassword();
                  },
                  decoration: InputDecoration(
                    labelText: 'تأكيد كلمة المرور الجديدة',
                    helperText: 'أعد إدخال كلمة المرور الجديدة للتأكيد.',
                    errorText: _confirmPasswordError,
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                      icon: Icon(_showConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      _confirmPassword.isEmpty ? Icons.info_outline : (_isConfirmMatch ? Icons.check_circle : Icons.error_outline),
                      size: 16,
                      color: _confirmPassword.isEmpty ? Colors.grey : (_isConfirmMatch ? Colors.green : Theme.of(context).colorScheme.error),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _confirmPassword.isEmpty
                          ? 'قم بإدخال التأكيد للتحقق من التطابق.'
                          : (_isConfirmMatch ? 'كلمتا المرور متطابقتان' : 'كلمتا المرور غير متطابقتين'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _confirmPassword.isEmpty
                                ? Colors.grey.shade700
                                : (_isConfirmMatch ? Colors.green : Theme.of(context).colorScheme.error),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _canSubmitPasswordChange ? _handleChangePassword : null,
                  child: _updatingPassword
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('حفظ كلمة المرور الجديدة'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
