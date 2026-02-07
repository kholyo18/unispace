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

  bool _hideEmail = false;
  bool _showFullName = true;
  bool _confirmSensitiveActions = true;

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
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final hasPasswordProvider = _hasPasswordProvider(user);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('تغيير البريد الإلكتروني', textAlign: TextAlign.right),
              const SizedBox(height: 12),
              TextField(
                controller: newEmailController,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني الجديد'),
              ),
              if (hasPasswordProvider) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(labelText: 'كلمة المرور الحالية'),
                ),
              ] else
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'هذا الحساب لا يستخدم كلمة مرور. لحمايتك، يرجى تسجيل الخروج ثم تسجيل الدخول مرة أخرى قبل تغيير البريد.',
                    textAlign: TextAlign.right,
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('متابعة'),
              ),
            ],
          ),
        );
      },
    );

    final nextEmail = newEmailController.text.trim();
    final currentPassword = passwordController.text;
    if (nextEmail.isEmpty) return;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(nextEmail)) {
      _showMessage('يرجى إدخال بريد إلكتروني صالح.');
      return;
    }
    if (_confirmSensitiveActions) {
      final confirmed = await _confirmAction('تأكيد العملية', 'هل تريد تغيير البريد الإلكتروني؟');
      if (!confirmed) return;
    }

    setState(() => _emailLoading = true);
    try {
      await user.reload();
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showMessage('يرجى تسجيل الدخول أولاً.');
        return;
      }
      if (_hasPasswordProvider(currentUser)) {
        final email = currentUser.email;
        if (email == null || currentPassword.isEmpty) {
          _showMessage('أدخل كلمة المرور الحالية لإكمال العملية.');
          return;
        }
        final credential = EmailAuthProvider.credential(email: email, password: currentPassword);
        await currentUser.reauthenticateWithCredential(credential);
      } else {
        _showMessage('لإكمال التحقق الأمني، سجّل الخروج ثم سجّل الدخول مرة أخرى، ثم أعد المحاولة.');
        return;
      }

      await currentUser.verifyBeforeUpdateEmail(nextEmail);
      _showMessage('تم إرسال رسالة تأكيد إلى بريدك الجديد.');
      if (mounted) setState(() {});
    } catch (error) {
      _showMessage(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _emailLoading = false);
    }
  }

  Future<void> _showChangePasswordSheet(User user) async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('تغيير كلمة السر', textAlign: TextAlign.right),
            const SizedBox(height: 12),
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(labelText: 'كلمة المرور الحالية'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور الجديدة'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('متابعة'),
            ),
          ],
        ),
      ),
    );

    final currentPassword = currentPasswordController.text;
    final newPassword = newPasswordController.text;
    final confirm = confirmPasswordController.text;
    if (currentPassword.isEmpty && newPassword.isEmpty && confirm.isEmpty) return;
    if (newPassword != confirm) {
      _showMessage('تأكيد كلمة المرور غير مطابق.');
      return;
    }
    if (newPassword.length < 6) {
      _showMessage('كلمة المرور الجديدة يجب أن تكون 6 أحرف على الأقل.');
      return;
    }
    if (_confirmSensitiveActions) {
      final confirmed = await _confirmAction('تأكيد العملية', 'هل تريد تغيير كلمة المرور؟');
      if (!confirmed) return;
    }

    setState(() => _passwordLoading = true);
    try {
      if (!_hasPasswordProvider(user) || user.email == null) {
        _showMessage('هذا الحساب لا يستخدم كلمة مرور. يرجى تسجيل الدخول بطريقة الحساب الأساسية لتحديث بيانات الأمان.');
        return;
      }
      final credential = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      _showMessage('تم تغيير كلمة المرور بنجاح.');
    } catch (error) {
      _showMessage(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _passwordLoading = false);
    }
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

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('نظرة عامة على الحساب', textAlign: TextAlign.right),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('الاسم واللقب', textAlign: TextAlign.right),
                      subtitle: Text(displayName, textAlign: TextAlign.right),
                    ),
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('البريد الإلكتروني', textAlign: TextAlign.right),
                      subtitle: Text(email, textAlign: TextAlign.right),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _emailLoading ? null : () => _showChangeEmailSheet(user),
                      icon: _emailLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.alternate_email),
                      label: const Text('تغيير البريد الإلكتروني'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _passwordLoading ? null : () => _showChangePasswordSheet(user),
                      icon: _passwordLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.password),
                      label: const Text('تغيير كلمة السر'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _deleteLoading ? null : () => _deleteAccount(user),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      icon: _deleteLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_forever),
                      label: const Text('حذف الحساب'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    value: _hideEmail,
                    title: const Text('إخفاء البريد الإلكتروني', textAlign: TextAlign.right),
                    onChanged: (value) {
                      setState(() => _hideEmail = value);
                      _setPrivacyPref(_hideEmailKey, value);
                    },
                  ),
                  SwitchListTile.adaptive(
                    value: _showFullName,
                    title: const Text('إظهار الاسم كامل', textAlign: TextAlign.right),
                    onChanged: (value) {
                      setState(() => _showFullName = value);
                      _setPrivacyPref(_showFullNameKey, value);
                    },
                  ),
                  SwitchListTile.adaptive(
                    value: _confirmSensitiveActions,
                    title: const Text('طلب تأكيد قبل العمليات الحساسة', textAlign: TextAlign.right),
                    onChanged: (value) {
                      setState(() => _confirmSensitiveActions = value);
                      _setPrivacyPref(_confirmSensitiveKey, value);
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
