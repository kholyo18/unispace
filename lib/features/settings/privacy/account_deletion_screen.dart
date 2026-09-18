import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'data_retention_policy_screen.dart';

class AccountDeletionScreen extends StatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  State<AccountDeletionScreen> createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends State<AccountDeletionScreen> {
  bool _submitting = false;
  bool _requested = false;

  Future<void> _requestDeletion() async {
    if (_submitting || _requested) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول أولاً')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('طلب حذف الحساب والبيانات؟'),
        content: const Text(
          'سيُسجل طلب حذف مرتبط بحسابك الحالي. هذا الإصدار لا ينفذ '
          'المحو الكامل فورًا، وسيظل اكتمال معالج الحذف شرطًا قبل النشر العام.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            key: const ValueKey('account-deletion-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('تأكيد الطلب'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('requestAccountDeletion')
          .call(<String, dynamic>{});
      final data = Map<String, dynamic>.from(response.data as Map);
      if (!mounted) return;
      setState(() => _requested = data['requested'] == true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data['alreadyRequested'] == true
                ? 'لديك طلب حذف نشط بالفعل'
                : 'تم تسجيل طلب حذف الحساب',
          ),
        ),
      );
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      final message = error.code == 'unauthenticated'
          ? 'أعد تسجيل الدخول ثم حاول مرة أخرى'
          : 'تعذر تسجيل طلب الحذف الآن';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تسجيل طلب الحذف الآن')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('حذف الحساب والبيانات'),
          leading: const BackButton(key: ValueKey('account-deletion-back')),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 32),
            children: [
              Text(
                'طلب حذف حساب UniSpace',
                key: const ValueKey('account-deletion-title'),
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'يمكنك تقديم طلب حذف من داخل التطبيق. يسجل الخادم الطلب '
                'للحساب الذي سجلت الدخول به، ولا نطلب منك إرسال كلمة المرور '
                'أو رمز المصادقة إلى الدعم.',
              ),
              const SizedBox(height: 16),
              const Text(
                'مهم: النسخة الحالية تسجل طلب الحذف، لكنها لا تنفذ بعد '
                'المحو الشامل التلقائي لكل بيانات Firestore وStorage '
                'وFirebase Authentication. لذلك لا نعرض تسجيل الطلب كأنه '
                'حذف مكتمل.',
                key: ValueKey('account-deletion-status-notice'),
              ),
              const SizedBox(height: 16),
              const Text(
                'يمكنك تنزيل نسخة من البيانات المدعومة من إعدادات الخصوصية '
                'قبل تقديم الطلب. للاستفسارات: unispace.0.1.0@gmail.com',
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                key: const ValueKey('account-deletion-read-retention'),
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const DataRetentionPolicyScreen(),
                  ),
                ),
                icon: const Icon(Icons.policy_outlined),
                label: const Text('قراءة سياسة الحذف والاحتفاظ'),
              ),
              const SizedBox(height: 24),
              if (_requested)
                const ListTile(
                  key: ValueKey('account-deletion-requested'),
                  leading: Icon(Icons.check_circle_outline),
                  title: Text('تم تسجيل طلب الحذف'),
                  subtitle: Text(
                    'سيبقى الطلب مسجلاً حتى تتم معالجته. لا ترسل كلمة المرور أو رموز التحقق عبر البريد.',
                  ),
                )
              else
                FilledButton.icon(
                  key: const ValueKey('account-deletion-submit'),
                  onPressed: _submitting ? null : _requestDeletion,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline),
                  label: Text(
                    _submitting ? 'جارٍ تسجيل الطلب...' : 'طلب حذف الحساب والبيانات',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
