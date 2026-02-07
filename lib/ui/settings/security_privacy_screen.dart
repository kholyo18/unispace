import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'drawer_screens.dart';

enum _SecurityPrivacySegment { security, privacy }

class SecurityPrivacyScreen extends StatefulWidget {
  const SecurityPrivacyScreen({super.key});

  @override
  State<SecurityPrivacyScreen> createState() => _SecurityPrivacyScreenState();
}

class _SecurityPrivacyScreenState extends State<SecurityPrivacyScreen> {
  static const _segmentKey = 'settings_security_privacy_segment';
  _SecurityPrivacySegment _segment = _SecurityPrivacySegment.security;

  @override
  void initState() {
    super.initState();
    _loadSegment();
  }

  Future<void> _loadSegment() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_segmentKey);
    if (!mounted || value == null) return;
    setState(() {
      _segment = value == 'privacy'
          ? _SecurityPrivacySegment.privacy
          : _SecurityPrivacySegment.security;
    });
  }

  Future<void> _saveSegment(_SecurityPrivacySegment value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _segmentKey,
      value == _SecurityPrivacySegment.privacy ? 'privacy' : 'security',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأمان و الخصوصية'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: CupertinoSlidingSegmentedControl<_SecurityPrivacySegment>(
                groupValue: _segment,
                children: const {
                  _SecurityPrivacySegment.security: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('الأمان'),
                  ),
                  _SecurityPrivacySegment.privacy: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('الخصوصية'),
                  ),
                },
                onValueChanged: (value) {
                  if (value == null) return;
                  setState(() => _segment = value);
                  _saveSegment(value);
                },
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: IndexedStack(
              index: _segment == _SecurityPrivacySegment.security ? 0 : 1,
              children: const [
                SecurityCenterContent(),
                _PrivacyTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyTab extends StatefulWidget {
  const _PrivacyTab();

  @override
  State<_PrivacyTab> createState() => _PrivacyTabState();
}

class _PrivacyTabState extends State<_PrivacyTab> {
  static const _hideEmailKey = 'privacy_hide_email';
  static const _showFullNameKey = 'privacy_show_full_name';
  static const _confirmSensitiveKey = 'privacy_confirm_sensitive_actions';
  static const _hideActivityKey = 'privacy_hide_activity_status';
  static const _allowSearchByEmailKey = 'privacy_allow_search_by_email';

  bool _hideEmail = false;
  bool _showFullName = true;
  bool _confirmSensitiveActions = true;
  bool _hideActivityStatus = true;
  bool _allowSearchByEmail = false;

  bool _emailLoading = false;
  bool _passwordLoading = false;
  bool _deleteLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacyPrefs();
  }

  Future<void> _loadPrivacyPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _hideEmail = prefs.getBool(_hideEmailKey) ?? false;
      _showFullName = prefs.getBool(_showFullNameKey) ?? true;
      _confirmSensitiveActions = prefs.getBool(_confirmSensitiveKey) ?? true;
      _hideActivityStatus = prefs.getBool(_hideActivityKey) ?? true;
      _allowSearchByEmail = prefs.getBool(_allowSearchByEmailKey) ?? false;
    });
  }

  Future<void> _setPrivacyPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  String _friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'صيغة البريد الإلكتروني غير صحيحة.';
        case 'email-already-in-use':
          return 'هذا البريد مستخدم بالفعل.';
        case 'requires-recent-login':
          return 'لحمايتك، يرجى تسجيل الدخول مرة أخرى ثم إعادة المحاولة.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'كلمة المرور الحالية غير صحيحة.';
        case 'weak-password':
          return 'كلمة المرور الجديدة ضعيفة. يجب أن تكون 6 أحرف على الأقل.';
        case 'user-mismatch':
        case 'user-not-found':
          return 'تعذر التحقق من الجلسة الحالية. يرجى تسجيل الدخول من جديد.';
      }
    }
    return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
  }

  bool _hasPasswordProvider(User user) {
    return user.providerData.any((provider) => provider.providerId == 'password');
  }

  String _maskedEmail(String email) {
    if (!_hideEmail || !email.contains('@')) return email;
    final parts = email.split('@');
    if (parts.first.length < 3) return '***@${parts.last}';
    return '${parts.first.substring(0, 3)}***@${parts.last}';
  }

  Future<Map<String, dynamic>?> _readUserProfile(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data();
  }

  String _resolveName(Map<String, dynamic>? data, User? user) {
    final first = (data?['firstName'] as String?)?.trim();
    final last = (data?['lastName'] as String?)?.trim();
    final full = [first, last].where((part) => (part ?? '').isNotEmpty).join(' ').trim();
    final displayName = (data?['displayName'] as String?)?.trim();
    final username = (data?['username'] as String?)?.trim();
    final fallback = user?.displayName?.trim();
    final best = full.isNotEmpty
        ? full
        : (displayName?.isNotEmpty == true
            ? displayName!
            : (username?.isNotEmpty == true ? username! : (fallback ?? '')));
    if (best.isEmpty) return 'غير محدد';
    if (_showFullName) return best;
    return best.split(' ').first;
  }

  Future<void> _showChangeEmailSheet(User user) async {
    final newEmailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final hasPasswordProvider = _hasPasswordProvider(user);
        bool loading = false;
        String? formError;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, setModalState) => Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('تغيير البريد الإلكتروني', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      'سيتم إرسال رسالة تحقق إلى البريد الجديد قبل اعتماده.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      initialValue: user.email ?? 'غير متوفر',
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'البريد الحالي',
                        prefixIcon: Icon(Icons.mark_email_read_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: newEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني الجديد',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      validator: (value) {
                        final nextEmail = (value ?? '').trim();
                        final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        if (nextEmail.isEmpty) return 'يرجى إدخال البريد الإلكتروني الجديد.';
                        if (!emailRegex.hasMatch(nextEmail)) return 'يرجى إدخال بريد إلكتروني صالح.';
                        if (nextEmail == user.email) return 'البريد الجديد مطابق للبريد الحالي.';
                        return null;
                      },
                    ),
                    if (hasPasswordProvider) ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'كلمة المرور الحالية',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (value) {
                          if ((value ?? '').isEmpty) return 'أدخل كلمة المرور الحالية لإتمام العملية.';
                          return null;
                        },
                      ),
                    ] else ...[
                      const SizedBox(height: 10),
                      const Text(
                        'هذا الحساب لا يستخدم كلمة مرور. يرجى تسجيل الخروج ثم تسجيل الدخول مرة أخرى قبل تغيير البريد.',
                      ),
                    ],
                    if (formError != null) ...[
                      const SizedBox(height: 10),
                      Text(formError!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: loading
                          ? null
                          : () async {
                              if (!(formKey.currentState?.validate() ?? false)) return;
                              if (_confirmSensitiveActions) {
                                final confirmed = await _confirmAction('تأكيد العملية', 'هل تريد تغيير البريد الإلكتروني؟');
                                if (!confirmed) return;
                              }
                              setModalState(() {
                                loading = true;
                                formError = null;
                              });
                              setState(() => _emailLoading = true);
                              try {
                                await user.reload();
                                final currentUser = FirebaseAuth.instance.currentUser;
                                if (currentUser == null) {
                                  setModalState(() => formError = 'يرجى تسجيل الدخول أولاً.');
                                  return;
                                }
                                if (_hasPasswordProvider(currentUser)) {
                                  final email = currentUser.email;
                                  if (email == null) {
                                    setModalState(() => formError = 'تعذر قراءة البريد الحالي.');
                                    return;
                                  }
                                  final credential = EmailAuthProvider.credential(
                                    email: email,
                                    password: passwordController.text,
                                  );
                                  await currentUser.reauthenticateWithCredential(credential);
                                } else {
                                  setModalState(() {
                                    formError = 'لإكمال التحقق الأمني، سجّل الخروج ثم سجّل الدخول مرة أخرى.';
                                  });
                                  return;
                                }

                                await currentUser.verifyBeforeUpdateEmail(newEmailController.text.trim());
                                if (mounted) {
                                  Navigator.of(context).pop();
                                  _showMessage('تم إرسال رسالة تأكيد إلى بريدك الجديد.');
                                }
                              } catch (error) {
                                setModalState(() => formError = _friendlyError(error));
                              } finally {
                                if (mounted) {
                                  setState(() => _emailLoading = false);
                                }
                                setModalState(() => loading = false);
                              }
                            },
                      icon: loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: const Text('تحديث البريد الإلكتروني'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    newEmailController.dispose();
    passwordController.dispose();
  }

  Future<void> _showChangePasswordSheet(User user) async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        bool loading = false;
        String? formError;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, setModalState) => Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('تغيير كلمة السر', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      'اختر كلمة مرور قوية لا تقل عن 6 أحرف.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: currentPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'كلمة المرور الحالية',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) => (value ?? '').isEmpty ? 'أدخل كلمة المرور الحالية.' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'كلمة المرور الجديدة',
                        prefixIcon: Icon(Icons.password_outlined),
                      ),
                      validator: (value) {
                        if ((value ?? '').isEmpty) return 'أدخل كلمة المرور الجديدة.';
                        if ((value ?? '').length < 6) return 'كلمة المرور الجديدة يجب أن تكون 6 أحرف على الأقل.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'تأكيد كلمة المرور الجديدة',
                        prefixIcon: Icon(Icons.verified_user_outlined),
                      ),
                      validator: (value) {
                        if ((value ?? '') != newPasswordController.text) {
                          return 'تأكيد كلمة المرور غير مطابق.';
                        }
                        return null;
                      },
                    ),
                    if (formError != null) ...[
                      const SizedBox(height: 10),
                      Text(formError!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: loading
                          ? null
                          : () async {
                              if (!(formKey.currentState?.validate() ?? false)) return;
                              if (_confirmSensitiveActions) {
                                final confirmed = await _confirmAction('تأكيد العملية', 'هل تريد تغيير كلمة المرور؟');
                                if (!confirmed) return;
                              }
                              setModalState(() {
                                loading = true;
                                formError = null;
                              });
                              setState(() => _passwordLoading = true);
                              try {
                                if (!_hasPasswordProvider(user) || user.email == null) {
                                  setModalState(() {
                                    formError = 'هذا الحساب لا يستخدم كلمة مرور. يرجى تسجيل الدخول بطريقة الحساب الأساسية.';
                                  });
                                  return;
                                }
                                final credential = EmailAuthProvider.credential(
                                  email: user.email!,
                                  password: currentPasswordController.text,
                                );
                                await user.reauthenticateWithCredential(credential);
                                await user.updatePassword(newPasswordController.text);
                                if (mounted) {
                                  Navigator.of(context).pop();
                                  _showMessage('تم تغيير كلمة المرور بنجاح.');
                                }
                              } catch (error) {
                                setModalState(() => formError = _friendlyError(error));
                              } finally {
                                if (mounted) {
                                  setState(() => _passwordLoading = false);
                                }
                                setModalState(() => loading = false);
                              }
                            },
                      icon: loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: const Text('تحديث كلمة المرور'),
                    ),
                  ],
                ),
              ),
            ),
          );
      },
    );
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  Future<void> _deleteAccount(User user) async {
    final warningAccepted = await _confirmAction(
      'تحذير مهم',
      'سيتم حذف حسابك نهائياً وقد تفقد البيانات المرتبطة به. لا يمكن التراجع عن هذه العملية.',
      confirmLabel: 'متابعة',
    );
    if (!warningAccepted) return;

    final passwordController = TextEditingController();
    final phraseController = TextEditingController();
    final proceeded = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد حذف الحساب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('اكتب "حذف" للتأكيد النهائي.'),
            const SizedBox(height: 8),
            TextField(
              controller: phraseController,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(labelText: 'عبارة التأكيد'),
            ),
            if (_hasPasswordProvider(user)) ...[
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(labelText: 'كلمة المرور الحالية'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('حذف الحساب')),
        ],
      ),
    );

    if (proceeded != true) return;
    if (phraseController.text.trim() != 'حذف') {
      _showMessage('عبارة التأكيد غير صحيحة.');
      return;
    }
    if (_confirmSensitiveActions) {
      final finalConfirm = await _confirmAction('تأكيد أخير', 'هل أنت متأكد من حذف الحساب الآن؟', confirmLabel: 'نعم، حذف');
      if (!finalConfirm) return;
    }

    setState(() => _deleteLoading = true);
    try {
      if (_hasPasswordProvider(user)) {
        final email = user.email;
        final password = passwordController.text;
        if (email == null || password.isEmpty) {
          _showMessage('أدخل كلمة المرور الحالية لإتمام الحذف.');
          return;
        }
        final credential = EmailAuthProvider.credential(email: email, password: password);
        await user.reauthenticateWithCredential(credential);
      } else {
        _showMessage('لأمان الحساب: سجّل الخروج ثم الدخول مرة أخرى قبل الحذف.');
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'deletedAt': FieldValue.serverTimestamp(),
        'isDeleted': true,
        'displayName': 'مستخدم محذوف',
        'showEmailInProfile': false,
      }, SetOptions(merge: true));

      await user.delete();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      _showMessage('تم حذف الحساب بنجاح.');
    } catch (error) {
      _showMessage(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _deleteLoading = false);
    }
  }

  Future<bool> _confirmAction(String title, String message, {String confirmLabel = 'تأكيد'}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message, textAlign: TextAlign.right),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(confirmLabel)),
        ],
      ),
    );
    return result == true;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 8, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('يرجى تسجيل الدخول للوصول إلى إعدادات الخصوصية.'));
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _readUserProfile(user.uid),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final displayName = _resolveName(profile, user);
        final email = _maskedEmail(user.email ?? 'غير محدد');

        return Directionality(
          textDirection: TextDirection.rtl,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionHeader('نظرة عامة على الحساب', 'عرض معلوماتك الأساسية بشكل آمن.'),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('الاسم الكامل'),
                      subtitle: Text(displayName),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('البريد الإلكتروني'),
                      subtitle: Text(email),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionHeader('إدارة الحساب', 'قم بتحديث بيانات الدخول المرتبطة بحسابك.'),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.alternate_email),
                      title: const Text('تغيير البريد الإلكتروني'),
                      subtitle: const Text('تحديث البريد بعد التحقق من الهوية.'),
                      trailing: _emailLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_left),
                      onTap: _emailLoading ? null : () => _showChangeEmailSheet(user),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.password_outlined),
                      title: const Text('تغيير كلمة السر'),
                      subtitle: const Text('استخدم كلمة قوية لحماية حسابك.'),
                      trailing: _passwordLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_left),
                      onTap: _passwordLoading ? null : () => _showChangePasswordSheet(user),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionHeader('عناصر الخصوصية', 'اضبط ما يتم عرضه وكيفية تنفيذ العمليات الحساسة.'),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      value: _hideEmail,
                      title: const Text('إخفاء البريد الإلكتروني'),
                      subtitle: const Text('يتم إخفاء جزء من البريد في شاشة الخصوصية.'),
                      onChanged: (value) {
                        setState(() => _hideEmail = value);
                        _setPrivacyPref(_hideEmailKey, value);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      value: _showFullName,
                      title: const Text('إظهار الاسم كامل'),
                      subtitle: const Text('عند إيقافه يظهر الاسم الأول فقط.'),
                      onChanged: (value) {
                        setState(() => _showFullName = value);
                        _setPrivacyPref(_showFullNameKey, value);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      value: _confirmSensitiveActions,
                      title: const Text('طلب تأكيد قبل العمليات الحساسة'),
                      subtitle: const Text('مثل تغيير البريد أو كلمة المرور أو الحذف.'),
                      onChanged: (value) {
                        setState(() => _confirmSensitiveActions = value);
                        _setPrivacyPref(_confirmSensitiveKey, value);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      value: _hideActivityStatus,
                      title: const Text('إخفاء حالة النشاط'),
                      subtitle: const Text('يتم حفظ الإعداد محلياً للاستخدام المستقبلي.'),
                      onChanged: (value) {
                        setState(() => _hideActivityStatus = value);
                        _setPrivacyPref(_hideActivityKey, value);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      value: _allowSearchByEmail,
                      title: const Text('السماح بالبحث عني عبر البريد'),
                      subtitle: const Text('إعداد محلي قابل للتفعيل لاحقاً مع الخادم.'),
                      onChanged: (value) {
                        setState(() => _allowSearchByEmail = value);
                        _setPrivacyPref(_allowSearchByEmailKey, value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionHeader('منطقة الخطر', 'إجراءات نهائية تتطلب تأكيداً إضافياً.'),
              Card(
                color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('حذف الحساب'),
                  subtitle: const Text('سيتم حذف حسابك بشكل دائم بعد التأكيد.'),
                  trailing: _deleteLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_left, color: Colors.red),
                  onTap: _deleteLoading ? null : () => _deleteAccount(user),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
