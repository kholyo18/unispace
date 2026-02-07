import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'drawer_screens.dart';

enum _SecurityPrivacySegment { security, privacy }

enum _PrivacyPreset { strict, balanced, open, custom }

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
  static const _deactivatedKey = 'privacy_account_deactivated';
  static const _deactivatedUntilKey = 'privacy_account_deactivated_until';
  static const _activityLogKey = 'privacy_activity_log';
  static const _presetKey = 'privacy_preset';
  static const _lockEnabledKey = 'privacy_lock_enabled';
  static const _pinHashKey = 'privacy_lock_pin_hash';
  static const _hideMenuKey = 'privacy_hide_menu_item';

  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _hideEmail = false;
  bool _showFullName = true;
  bool _confirmSensitiveActions = true;
  bool _hideActivityStatus = true;
  bool _allowSearchByEmail = false;
  bool _accountDeactivated = false;
  bool _privacyLockEnabled = false;
  bool _privacyUnlocked = true;
  bool _hideMenuEntry = false;
  DateTime? _deactivatedUntil;
  _PrivacyPreset _preset = _PrivacyPreset.balanced;
  List<String> _activity = const [];

  bool _emailLoading = false;
  bool _passwordLoading = false;
  bool _deleteLoading = false;
  bool _exportLoading = false;
  bool _resetLoading = false;
  bool _clearCacheLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacyPrefs();
  }

  Future<void> _loadPrivacyPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final untilMs = prefs.getInt(_deactivatedUntilKey);
    if (!mounted) return;
    setState(() {
      _hideEmail = prefs.getBool(_hideEmailKey) ?? false;
      _showFullName = prefs.getBool(_showFullNameKey) ?? true;
      _confirmSensitiveActions = prefs.getBool(_confirmSensitiveKey) ?? true;
      _hideActivityStatus = prefs.getBool(_hideActivityKey) ?? true;
      _allowSearchByEmail = prefs.getBool(_allowSearchByEmailKey) ?? false;
      _accountDeactivated = prefs.getBool(_deactivatedKey) ?? false;
      _hideMenuEntry = prefs.getBool(_hideMenuKey) ?? false;
      _privacyLockEnabled = prefs.getBool(_lockEnabledKey) ?? false;
      _privacyUnlocked = !_privacyLockEnabled;
      _preset = _decodePreset(prefs.getString(_presetKey));
      _deactivatedUntil = untilMs == null ? null : DateTime.fromMillisecondsSinceEpoch(untilMs);
      _activity = prefs.getStringList(_activityLogKey) ?? <String>[];
    });
  }

  _PrivacyPreset _decodePreset(String? value) {
    return _PrivacyPreset.values.firstWhere(
      (item) => item.name == value,
      orElse: () => _PrivacyPreset.custom,
    );
  }

  Future<void> _setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _addSensitiveAction(String action) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final entry = '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} - $action';
    final updated = <String>[entry, ..._activity].take(25).toList();
    await prefs.setStringList(_activityLogKey, updated);
    if (mounted) setState(() => _activity = updated);
  }

  Future<bool> _unlockPrivacy() async {
    if (!_privacyLockEnabled) return true;
    try {
      final canUseBiometric = await _localAuth.canCheckBiometrics && await _localAuth.isDeviceSupported();
      if (canUseBiometric) {
        final ok = await _localAuth.authenticate(
          localizedReason: 'افتح إعدادات الخصوصية',
          options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
        );
        if (ok) {
          if (mounted) setState(() => _privacyUnlocked = true);
          return true;
        }
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final hash = prefs.getString(_pinHashKey);
    if (hash == null) return false;
    final pinController = TextEditingController();
    final pass = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('أدخل PIN الخصوصية'),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(labelText: 'PIN'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('تحقق')),
        ],
      ),
    );
    final valid = pass == true && _pin(pinController.text) == hash;
    if (valid && mounted) setState(() => _privacyUnlocked = true);
    return valid;
  }

  Future<bool> _guardSensitiveEdit() async {
    if (!_privacyLockEnabled || _privacyUnlocked) return true;
    final unlocked = await _unlockPrivacy();
    if (!unlocked) _showMessage('تعذر فتح إعدادات الخصوصية.');
    return unlocked;
  }

  String _pin(String value) => sha256.convert(utf8.encode(value)).toString();

  Future<void> _setPrivacyLock(bool value) async {
    if (value) {
      final pin = TextEditingController();
      final confirm = TextEditingController();
      final shouldEnable = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تفعيل قفل الخصوصية'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('أدخل PIN احتياطي (4-6 أرقام) في حال عدم توفر البصمة.'),
              const SizedBox(height: 8),
              TextField(controller: pin, obscureText: true, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'PIN')),
              const SizedBox(height: 8),
              TextField(controller: confirm, obscureText: true, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'تأكيد PIN')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('تفعيل')),
          ],
        ),
      );
      if (shouldEnable != true || pin.text.length < 4 || pin.text != confirm.text) {
        _showMessage('لم يتم تفعيل القفل. تحقق من PIN.');
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pinHashKey, _pin(pin.text));
      await prefs.setBool(_lockEnabledKey, true);
      setState(() {
        _privacyLockEnabled = true;
        _privacyUnlocked = false;
      });
      await _addSensitiveAction('تفعيل قفل الخصوصية');
      return;
    }
    await _setBool(_lockEnabledKey, false);
    setState(() {
      _privacyLockEnabled = false;
      _privacyUnlocked = true;
    });
    await _addSensitiveAction('إلغاء قفل الخصوصية');
  }

  Future<void> _applyPreset(_PrivacyPreset preset) async {
    if (!await _guardSensitiveEdit()) return;
    setState(() {
      switch (preset) {
        case _PrivacyPreset.strict:
          _hideEmail = true;
          _showFullName = false;
          _confirmSensitiveActions = true;
          _hideActivityStatus = true;
          _allowSearchByEmail = false;
          break;
        case _PrivacyPreset.balanced:
          _hideEmail = true;
          _showFullName = true;
          _confirmSensitiveActions = true;
          _hideActivityStatus = true;
          _allowSearchByEmail = false;
          break;
        case _PrivacyPreset.open:
          _hideEmail = false;
          _showFullName = true;
          _confirmSensitiveActions = false;
          _hideActivityStatus = false;
          _allowSearchByEmail = true;
          break;
        case _PrivacyPreset.custom:
          break;
      }
      _preset = preset;
    });
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool(_hideEmailKey, _hideEmail),
      prefs.setBool(_showFullNameKey, _showFullName),
      prefs.setBool(_confirmSensitiveKey, _confirmSensitiveActions),
      prefs.setBool(_hideActivityKey, _hideActivityStatus),
      prefs.setBool(_allowSearchByEmailKey, _allowSearchByEmail),
      prefs.setString(_presetKey, preset.name),
    ]);
    await _addSensitiveAction('تغيير نمط الخصوصية: ${_presetLabel(preset)}');
  }

  Future<void> _markCustomIfNeeded() async {
    if (_preset == _PrivacyPreset.custom) return;
    final current = (_hideEmail, _showFullName, _confirmSensitiveActions, _hideActivityStatus, _allowSearchByEmail);
    final strict = (true, false, true, true, false);
    final balanced = (true, true, true, true, false);
    final open = (false, true, false, false, true);
    final next = current == strict
        ? _PrivacyPreset.strict
        : current == balanced
            ? _PrivacyPreset.balanced
            : current == open
                ? _PrivacyPreset.open
                : _PrivacyPreset.custom;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_presetKey, next.name);
    if (mounted) setState(() => _preset = next);
  }

  Future<void> _toggleSetting(String key, bool value, void Function(bool v) apply) async {
    if (!await _guardSensitiveEdit()) return;
    setState(() => apply(value));
    await _setBool(key, value);
    await _markCustomIfNeeded();
  }

  Future<void> _exportData(User user, String displayName) async {
    setState(() => _exportLoading = true);
    try {
      final payload = <String, dynamic>{
        'fullName': displayName,
        'email': user.email,
        'privacySettings': {
          'hideEmail': _hideEmail,
          'showFullName': _showFullName,
          'confirmSensitiveActions': _confirmSensitiveActions,
          'hideActivityStatus': _hideActivityStatus,
          'allowSearchByEmail': _allowSearchByEmail,
          'accountDeactivated': _accountDeactivated,
          'deactivatedUntil': _deactivatedUntil?.toIso8601String(),
        },
        'generatedAt': DateTime.now().toIso8601String(),
      };
      await _addSensitiveAction('تنزيل بيانات الحساب');
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('بياناتك جاهزة'),
          content: SingleChildScrollView(
            child: Text(const JsonEncoder.withIndent('  ').convert(payload), textDirection: TextDirection.ltr),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إغلاق')),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _exportLoading = false);
    }
  }

  Future<void> _resetLocalData() async {
    bool accepted = false;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('مسح بيانات التطبيق'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('سيتم إعادة تهيئة جميع إعدادات الخصوصية المحلية.'),
              CheckboxListTile(
                value: accepted,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (value) => setStateDialog(() => accepted = value ?? false),
                title: const Text('أفهم أن الإعدادات ستُعاد الافتراضية'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
            ElevatedButton(onPressed: accepted ? () => Navigator.of(context).pop(true) : null, child: const Text('متابعة')),
          ],
        ),
      ),
    );
    if (proceed != true) return;

    setState(() => _resetLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_hideEmailKey),
        prefs.remove(_showFullNameKey),
        prefs.remove(_confirmSensitiveKey),
        prefs.remove(_hideActivityKey),
        prefs.remove(_allowSearchByEmailKey),
        prefs.remove(_deactivatedKey),
        prefs.remove(_deactivatedUntilKey),
        prefs.remove(_presetKey),
      ]);
      await _addSensitiveAction('إعادة ضبط بيانات التطبيق');
      await _loadPrivacyPrefs();
      _showMessage('تمت إعادة تعيين البيانات المحلية.');
    } finally {
      if (mounted) setState(() => _resetLoading = false);
    }
  }

  Future<void> _clearCache() async {
    setState(() => _clearCacheLoading = true);
    try {
      await _addSensitiveAction('مسح الكاش المحلي');
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: const Text('تم مسح الكاش المحلي.'),
          action: SnackBarAction(
            label: 'تراجع',
            onPressed: () {
              messenger.showSnackBar(const SnackBar(content: Text('لا يمكن استعادة الكاش بالكامل، تم إلغاء الإجراء القادم فقط.')));
            },
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _clearCacheLoading = false);
    }
  }

  Future<void> _showActivityLog() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('سجل النشاط الحساس', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Flexible(
                child: _activity.isEmpty
                    ? const Text('لا توجد عمليات حساسة مسجلة حتى الآن.')
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _activity.length,
                        itemBuilder: (_, index) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.history, size: 18),
                          title: Text(_activity[index]),
                        ),
                      ),
              ),
              TextButton.icon(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove(_activityLogKey);
                  if (mounted) setState(() => _activity = []);
                  if (context.mounted) Navigator.of(context).pop();
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('مسح السجل'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleDeactivated(bool value) async {
    if (value) {
      final selected = await showModalBottomSheet<Duration>(
        context: context,
        showDragHandle: true,
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: Wrap(
            children: [
              ListTile(title: const Text('تعطيل مؤقت لمدة 24 ساعة'), onTap: () => Navigator.pop(context, const Duration(hours: 24))),
              ListTile(title: const Text('تعطيل مؤقت لمدة 72 ساعة'), onTap: () => Navigator.pop(context, const Duration(hours: 72))),
              ListTile(title: const Text('تعطيل مؤقت لمدة 7 أيام'), onTap: () => Navigator.pop(context, const Duration(days: 7))),
            ],
          ),
        ),
      );
      if (selected == null) return;
      _deactivatedUntil = DateTime.now().add(selected);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_deactivatedUntilKey, _deactivatedUntil!.millisecondsSinceEpoch);
    } else {
      _deactivatedUntil = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_deactivatedUntilKey);
    }

    setState(() => _accountDeactivated = value);
    await _setBool(_deactivatedKey, value);
    await _addSensitiveAction(value ? 'تعطيل الحساب مؤقتًا' : 'إعادة تفعيل الحساب');
  }

  Future<void> _deleteAccount(User user) async {
    if (_deactivatedUntil != null && DateTime.now().isBefore(_deactivatedUntil!)) {
      _showMessage('الحذف النهائي متاح بعد انتهاء فترة التعطيل المؤقت.');
      return;
    }
    final warningAccepted = await _confirmAction('تحذير مهم', 'سيتم حذف حسابك نهائيًا. هذا الإجراء غير قابل للتراجع.', confirmLabel: 'متابعة');
    if (!warningAccepted) return;

    final phraseController = TextEditingController();
    final passwordController = TextEditingController();
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد نهائي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('اكتب "حذف" للمتابعة النهائية.'),
            TextField(controller: phraseController, decoration: const InputDecoration(labelText: 'عبارة التأكيد')),
            if (_hasPasswordProvider(user)) TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور')),
            const SizedBox(height: 8),
            const Text('TODO: ربط إعادة المصادقة النهائية مع واجهة الخادم عند توفرها.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('حذف نهائي')),
        ],
      ),
    );
    if (proceed != true || phraseController.text.trim() != 'حذف') {
      _showMessage('تم إلغاء عملية الحذف.');
      return;
    }

    setState(() => _deleteLoading = true);
    try {
      if (_hasPasswordProvider(user)) {
        final email = user.email;
        if (email == null || passwordController.text.isEmpty) {
          _showMessage('أدخل كلمة المرور الحالية.');
          return;
        }
        final credential = EmailAuthProvider.credential(email: email, password: passwordController.text);
        await user.reauthenticateWithCredential(credential);
      }
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'deletedAt': FieldValue.serverTimestamp(),
        'isDeleted': true,
      }, SetOptions(merge: true));
      await _addSensitiveAction('محاولة حذف الحساب نهائيًا');
      await user.delete();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      _showMessage(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _deleteLoading = false);
    }
  }

  Future<void> _showChangeEmailSheet(User user) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير البريد الإلكتروني'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'البريد الجديد')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: const Text('تحديث')),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    setState(() => _emailLoading = true);
    try {
      await user.verifyBeforeUpdateEmail(result);
      await _addSensitiveAction('طلب تغيير البريد الإلكتروني');
      _showMessage('تم إرسال رسالة تحقق إلى البريد الجديد.');
    } catch (error) {
      _showMessage(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _emailLoading = false);
    }
  }

  Future<void> _showChangePasswordSheet(User user) async {
    final current = TextEditingController();
    final next = TextEditingController();
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير كلمة المرور'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: current, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور الحالية')),
            TextField(controller: next, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('تحديث')),
        ],
      ),
    );
    if (proceed != true) return;
    setState(() => _passwordLoading = true);
    try {
      final email = user.email;
      if (email == null || current.text.isEmpty || next.text.length < 6) {
        _showMessage('تحقق من المدخلات.');
        return;
      }
      final credential = EmailAuthProvider.credential(email: email, password: current.text);
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(next.text);
      await _addSensitiveAction('تغيير كلمة المرور');
      _showMessage('تم تحديث كلمة المرور.');
    } catch (error) {
      _showMessage(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _passwordLoading = false);
    }
  }

  bool _hasPasswordProvider(User user) => user.providerData.any((provider) => provider.providerId == 'password');

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

  String _friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'صيغة البريد الإلكتروني غير صحيحة.';
        case 'email-already-in-use':
          return 'هذا البريد مستخدم بالفعل.';
        case 'requires-recent-login':
          return 'يرجى تسجيل الدخول مرة أخرى ثم المحاولة.';
      }
    }
    return 'حدث خطأ غير متوقع.';
  }

  Future<Map<String, dynamic>?> _readUserProfile(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data();
  }

  String _resolveName(Map<String, dynamic>? data, User? user) {
    final name = (data?['displayName'] as String?)?.trim();
    final best = name?.isNotEmpty == true ? name! : (user?.displayName ?? 'غير محدد');
    if (_showFullName) return best;
    return best.split(' ').first;
  }

  String _maskedEmail(String email) {
    if (!_hideEmail || !email.contains('@')) return email;
    final parts = email.split('@');
    if (parts.first.length < 3) return '***@${parts.last}';
    return '${parts.first.substring(0, 3)}***@${parts.last}';
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _presetLabel(_PrivacyPreset preset) {
    switch (preset) {
      case _PrivacyPreset.strict:
        return 'صارم';
      case _PrivacyPreset.balanced:
        return 'متوازن';
      case _PrivacyPreset.open:
        return 'مفتوح';
      case _PrivacyPreset.custom:
        return 'مخصص';
    }
  }

  int get _privacyScore {
    int score = 0;
    if (_hideEmail) score += 20;
    if (!_showFullName) score += 20;
    if (_confirmSensitiveActions) score += 20;
    if (_hideActivityStatus) score += 20;
    if (!_allowSearchByEmail) score += 20;
    return score;
  }

  (Color, String, String) get _privacyHealth {
    final score = _privacyScore;
    if (score >= 80) return (Colors.green, '🟢 ممتاز', 'إعداداتك تقلل التعرض وتزيد حماية الحساب.');
    if (score >= 50) return (Colors.amber, '🟡 متوسط', 'حمايتك جيدة، ويمكن تعزيزها باختيار نمط أكثر صرامة.');
    return (Colors.red, '🔴 منخفض', 'هناك إعدادات مفتوحة؛ راجع عناصر الخصوصية لرفع مستوى الأمان.');
  }

  Widget _badge(String text, {bool cloud = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cloud ? Colors.orange.withOpacity(0.14) : Colors.teal.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: cloud ? Colors.orange.shade900 : Colors.teal.shade900)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('يرجى تسجيل الدخول للوصول إلى إعدادات الخصوصية.'));
    }

    final health = _privacyHealth;

    return FutureBuilder<Map<String, dynamic>?>(
      future: _readUserProfile(user.uid),
      builder: (context, snapshot) {
        final displayName = _resolveName(snapshot.data, user);
        final email = _maskedEmail(user.email ?? 'غير متوفر');

        if (_privacyLockEnabled && !_privacyUnlocked) {
          return Center(
            child: ElevatedButton.icon(
              onPressed: _unlockPrivacy,
              icon: const Icon(Icons.lock_open),
              label: const Text('فتح إعدادات الخصوصية'),
            ),
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: ListView(
            key: ValueKey(_preset),
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: health.$1.withOpacity(0.12), child: Icon(Icons.privacy_tip_outlined, color: health.$1)),
                  title: Text('مؤشر الخصوصية: $_privacyScore/100'),
                  subtitle: Text('${health.$2}\n${health.$3}'),
                  isThreeLine: true,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    children: _PrivacyPreset.values.map((preset) {
                      return ChoiceChip(
                        label: Text(_presetLabel(preset)),
                        selected: _preset == preset,
                        onSelected: (_) => _applyPreset(preset),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(title: const Text('نظرة عامة على الحساب'), subtitle: Text(displayName)),
                    ListTile(title: const Text('البريد الإلكتروني'), subtitle: Text(email), trailing: _badge('محلي فقط')),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.alternate_email_outlined),
                      title: const Text('تغيير البريد الإلكتروني'),
                      trailing: _emailLoading ? const CircularProgressIndicator() : const Icon(Icons.chevron_left),
                      onTap: _emailLoading ? null : () => _showChangeEmailSheet(user),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.password_outlined),
                      title: const Text('تغيير كلمة المرور'),
                      trailing: _passwordLoading ? const CircularProgressIndicator() : const Icon(Icons.chevron_left),
                      onTap: _passwordLoading ? null : () => _showChangePasswordSheet(user),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    SwitchListTile.adaptive(value: _hideEmail, title: const Text('إخفاء البريد الإلكتروني'), subtitle: const Text('إخفاء جزء من بريدك في الواجهة.'), secondary: _badge('محلي فقط'), onChanged: (v) => _toggleSetting(_hideEmailKey, v, (x) => _hideEmail = x)),
                    SwitchListTile.adaptive(value: _showFullName, title: const Text('إظهار الاسم الكامل'), subtitle: const Text('إظهار الاسم الكامل بدل الاسم الأول فقط.'), secondary: _badge('محلي فقط'), onChanged: (v) => _toggleSetting(_showFullNameKey, v, (x) => _showFullName = x)),
                    SwitchListTile.adaptive(value: _confirmSensitiveActions, title: const Text('تأكيد العمليات الحساسة'), subtitle: const Text('طلب تأكيد إضافي قبل الإجراءات المهمة.'), secondary: _badge('محلي فقط'), onChanged: (v) => _toggleSetting(_confirmSensitiveKey, v, (x) => _confirmSensitiveActions = x)),
                    SwitchListTile.adaptive(value: _hideActivityStatus, title: const Text('إخفاء حالة النشاط'), subtitle: const Text('سيتم تطبيق هذا الإعداد محليًا.'), secondary: _badge('محلي فقط'), onChanged: (v) => _toggleSetting(_hideActivityKey, v, (x) => _hideActivityStatus = x)),
                    SwitchListTile.adaptive(value: _allowSearchByEmail, title: const Text('السماح بالبحث عني عبر البريد'), subtitle: const Text('يتطلب ربطًا سحابيًا كاملًا لاحقًا.'), secondary: _badge('سحابي لاحقًا', cloud: true), onChanged: (v) => _toggleSetting(_allowSearchByEmailKey, v, (x) => _allowSearchByEmail = x)),
                    SwitchListTile.adaptive(value: _privacyLockEnabled, title: const Text('قفل الخصوصية'), subtitle: const Text('طلب بصمة/‏PIN قبل الوصول أو التعديل.'), secondary: _badge('محلي فقط'), onChanged: _setPrivacyLock),
                    SwitchListTile.adaptive(
                      value: _hideMenuEntry,
                      title: const Text('إخفاء الخصوصية من القائمة'),
                      subtitle: const Text('إخفاء مدخل الأمان والخصوصية من القائمة الرئيسية.'),
                      secondary: _badge('محلي فقط'),
                      onChanged: (value) async {
                        if (!await _guardSensitiveEdit()) return;
                        setState(() => _hideMenuEntry = value);
                        await _setBool(_hideMenuKey, value);
                        await _addSensitiveAction(value ? 'إخفاء الخصوصية من القائمة' : 'إظهار الخصوصية في القائمة');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(leading: const Icon(Icons.download_outlined), title: const Text('تنزيل بياناتي'), trailing: _exportLoading ? const CircularProgressIndicator() : const Icon(Icons.chevron_left), onTap: _exportLoading ? null : () => _exportData(user, displayName)),
                    ListTile(leading: const Icon(Icons.restart_alt_outlined), title: const Text('مسح بيانات التطبيق'), trailing: _resetLoading ? const CircularProgressIndicator() : const Icon(Icons.chevron_left), onTap: _resetLoading ? null : _resetLocalData),
                    ListTile(leading: const Icon(Icons.cleaning_services_outlined), title: const Text('مسح الكاش'), trailing: _clearCacheLoading ? const CircularProgressIndicator() : const Icon(Icons.chevron_left), onTap: _clearCacheLoading ? null : _clearCache),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.history_toggle_off_outlined),
                  title: const Text('سجل النشاط الحساس'),
                  subtitle: Text(_activity.take(3).join('\n').ifEmpty('لا توجد عناصر بعد.')),
                  isThreeLine: _activity.isNotEmpty,
                  trailing: const Icon(Icons.chevron_left),
                  onTap: _showActivityLog,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.4),
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.warning_amber_rounded, color: Colors.red),
                      title: Text('منطقة الخطر'),
                      subtitle: Text('إجراءات حساسة وغير قابلة للتراجع. تعامل بحذر شديد.'),
                    ),
                    SwitchListTile.adaptive(
                      value: _accountDeactivated,
                      activeColor: Colors.red,
                      title: const Text('تعطيل الحساب مؤقتًا'),
                      subtitle: Text(_deactivatedUntil == null ? 'اختر مدة التعطيل ثم يمكنك الحذف النهائي بعد انتهاء المدة.' : 'حتى: ${_deactivatedUntil!.toLocal()}'),
                      onChanged: _toggleDeactivated,
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text('حذف الحساب نهائيًا'),
                      subtitle: Text(_deactivatedUntil != null && DateTime.now().isBefore(_deactivatedUntil!) ? 'متاح بعد انتهاء العد التنازلي للتعطيل المؤقت.' : 'يتطلب تأكيدًا قويًا وقد يطلب كلمة المرور.'),
                      trailing: _deleteLoading ? const CircularProgressIndicator() : const Icon(Icons.chevron_left, color: Colors.red),
                      onTap: _deleteLoading ? null : () => _deleteAccount(user),
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
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}
