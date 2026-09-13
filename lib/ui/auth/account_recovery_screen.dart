import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../services/auth_session_service.dart';

String recoveryError(Object error) {
  if (error is FirebaseFunctionsException) {
    switch (error.code) {
      case 'permission-denied':
      case 'unauthenticated':
      case 'invalid-argument':
        return 'تعذر التحقق من البيانات. راجع حسابك ومفتاح الاستعادة.';
      case 'resource-exhausted':
        return 'محاولات كثيرة. انتظر 15 دقيقة ثم حاول مجددًا.';
      case 'aborted':
        return 'الاستعادة قيد التنفيذ. انتظر قليلًا ثم أعد المحاولة بالمفتاح نفسه.';
      case 'failed-precondition':
        return 'أكّد هويتك بتطبيق المصادقة ثم حاول مجددًا.';
      case 'not-found':
      case 'unimplemented':
        return 'خدمة الاستعادة غير متاحة حاليًا.';
    }
  }
  return 'تعذر إكمال العملية. احتفظ بالمفتاح وأعد المحاولة بالبيانات نفسها.';
}

class AccountRecoveryScreen extends StatefulWidget {
  const AccountRecoveryScreen({super.key});
  @override
  State<AccountRecoveryScreen> createState() => _AccountRecoveryScreenState();
}

class _AccountRecoveryScreenState extends State<AccountRecoveryScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _key = TextEditingController();
  bool _busy = false;
  bool _complete = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _key.dispose();
    super.dispose();
  }

  Future<void> _recover({bool google = false}) async {
    if (_busy) return;
    final key = _key.text.replaceAll(RegExp(r'[-\s]'), '').toUpperCase();
    if (!RegExp(r'^[0-9A-F]{32}$').hasMatch(key) ||
        (!google && (_email.text.trim().isEmpty || _password.text.isEmpty))) {
      setState(() => _error = 'أدخل مفتاح الاستعادة الكامل وبيانات الدخول.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = <String, dynamic>{
        'key': key,
        'provider': google ? 'google' : 'password'
      };
      if (google) {
        final account = await AuthSessionService.googleSignIn.signIn();
        if (account == null) return;
        final tokens = await account.authentication;
        if (tokens.idToken == null) throw StateError('No Google credential');
        data['email'] = account.email;
        data['googleIdToken'] = tokens.idToken;
      } else {
        data['email'] = _email.text.trim();
        data['password'] = _password.text;
      }
      // Recovery invalidates existing sessions; do not attach an old Auth token on retries.
      await FirebaseAuth.instance.signOut();
      final response = await FirebaseFunctions.instanceFor(
              region: 'europe-west1')
          .httpsCallable('recoverTotpAccount',
              options:
                  HttpsCallableOptions(timeout: const Duration(seconds: 65)))
          .call<Map<String, dynamic>>(data);
      if (response.data['recovered'] != true)
        throw StateError('Recovery not confirmed');
      _password.clear();
      _key.clear();
      if (mounted) setState(() => _complete = true);
    } catch (error) {
      if (mounted) setState(() => _error = recoveryError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('استعادة الوصول للحساب')),
        body: ListView(padding: const EdgeInsets.all(24), children: [
          if (_complete) ...[
            const Icon(Icons.check_circle_outline, size: 56),
            const SizedBox(height: 16),
            const Text(
                'تمت استعادة الوصول. أُلغيت الجلسات السابقة وأُزيل تطبيق المصادقة المفقود. سجّل الدخول مجددًا، ثم فعّل التأكيد بخطوتين وأنشئ مفتاح استعادة جديدًا.'),
            FilledButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('العودة إلى تسجيل الدخول')),
          ] else ...[
            const Text(
                'تحتاج مفتاح الاستعادة الذي أنشأته مسبقًا، مع كلمة المرور أو حساب Google. ستُلغي العملية الجلسات السابقة وتزيل تطبيق المصادقة المفقود.'),
            const SizedBox(height: 12),
            const Text(
                'الرموز من النسخ القديمة لا تعمل هنا. إذا لم تحفظ مفتاحًا، استخدم تطبيق المصادقة أو نسخة احتياطية منه.'),
            const SizedBox(height: 20),
            TextField(
                controller: _key,
                enabled: !_busy,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                    labelText: 'مفتاح الاستعادة',
                    helperText: '32 حرفًا ورقمًا، دون احتساب الشرطات')),
            TextField(
                controller: _email,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration:
                    const InputDecoration(labelText: 'البريد الإلكتروني')),
            TextField(
                controller: _password,
                enabled: !_busy,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: const InputDecoration(labelText: 'كلمة المرور')),
            const SizedBox(height: 20),
            if (_error != null)
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            if (_busy) const Center(child: CircularProgressIndicator()),
            FilledButton(
                onPressed: _busy ? null : () => _recover(),
                child: const Text('استعادة بكلمة المرور')),
            if (!kIsWeb)
              OutlinedButton(
                  onPressed: _busy ? null : () => _recover(google: true),
                  child: const Text('استعادة بحساب Google')),
          ],
        ]),
      );
}

/// The key is held only in this route's memory, never in preferences or the clipboard.
class RecoveryKeyScreen extends StatefulWidget {
  const RecoveryKeyScreen({super.key, required this.recoveryKey});
  final String recoveryKey;
  @override
  State<RecoveryKeyScreen> createState() => _RecoveryKeyScreenState();
}

class _RecoveryKeyScreenState extends State<RecoveryKeyScreen> {
  bool _saved = false;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('احفظ مفتاح الاستعادة')),
        body: ListView(padding: const EdgeInsets.all(24), children: [
          const Text(
              'يظهر المفتاح في هذه الشاشة فقط. احفظه في مكان آمن خارج هذا الجهاز. إنشاء مفتاح جديد يُلغي السابق.'),
          const SizedBox(height: 24),
          SelectableText(widget.recoveryKey,
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 22)),
          const SizedBox(height: 16),
          const Text(
              'يُستخدم عند فقدان تطبيق المصادقة، مع بيانات دخولك. لا تشاركه مع أحد.'),
          CheckboxListTile(
              value: _saved,
              onChanged: (value) => setState(() => _saved = value ?? false),
              title: const Text('حفظت المفتاح في مكان آمن')),
          FilledButton(
              onPressed: _saved ? () => Navigator.pop(context) : null,
              child: const Text('تم')),
        ]),
      );
}
