import '../../../ui/settings/account_state_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AccountDeletionScreen extends StatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  State<AccountDeletionScreen> createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends State<AccountDeletionScreen> {
  bool _understood = false;
  bool _submitting = false;

  Future<void> _requestDeletion() async {
    if (_submitting || !_understood) return;
    final expectedUid = FirebaseAuth.instance.currentUser?.uid;
    if (expectedUid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد طلب حذف الحساب'),
        content: const Text(
          'سيتم تسجيل طلب الحذف وإلغاء جلسات الحساب. قد تستغرق إزالة البيانات '
          'من الأنظمة التشغيلية حتى 30 يومًا. لا يمكن استخدام هذا الطلب لحذف حساب شخص آخر.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            key: const ValueKey('account-delete-dialog-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأكيد الطلب'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      await AccountStateService.requestDeletion(expectedUid);
      if (FirebaseAuth.instance.currentUser != null) return;

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('تم تسجيل الطلب'),
          content: const Text(
            'سُجل طلب حذف حسابك. سنعالج البيانات التشغيلية خلال مدة لا تتجاوز '
            '30 يومًا، مع الاحتفاظ المحدود فقط عندما يوجد سبب قانوني أو أمني مشروع.',
          ),
          actions: [
            FilledButton(
              key: const ValueKey('account-delete-success-close'),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('حسنًا'),
            ),
          ],
        ),
      );

      if (!mounted || FirebaseAuth.instance.currentUser != null) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      final message = switch (error.code) {
        'unauthenticated' => 'انتهت جلسة الدخول. سجّل الدخول مجددًا ثم أعد المحاولة.',
        'invalid-argument' => 'تعذر تأكيد الطلب. أعد المحاولة.',
        _ => 'تعذر تسجيل طلب الحذف الآن.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تسجيل طلب الحذف الآن.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('حذف الحساب والبيانات'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            key: const ValueKey('account-delete-scroll'),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Text(
                'طلب حذف حساب UniSpace',
                key: const ValueKey('account-delete-title'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'يمكنك طلب حذف حسابك والبيانات المرتبطة به من الأنظمة التي نديرها. '
                'هذا ليس تعطيلًا مؤقتًا للحساب.',
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              ),
              const SizedBox(height: 22),
              const _InfoCard(
                title: 'ماذا يحدث بعد الطلب؟',
                children: [
                  'يُسجّل الطلب باسم الحساب الذي أنت مسجل الدخول إليه فقط.',
                  'تُلغى جلسات الحساب ويُطلب منك تسجيل الخروج من التطبيق.',
                  'نستهدف إكمال حذف بيانات الحساب التشغيلية خلال مدة لا تتجاوز 30 يومًا.',
                  'البيانات المشتركة، مثل المحادثات مع مستخدمين آخرين، تُعالج بطريقة لا تكشف بياناتك ولا تفسد بيانات الطرف الآخر.',
                ],
              ),
              const SizedBox(height: 14),
              const _InfoCard(
                title: 'الاحتفاظ المحدود',
                children: [
                  'طلبات الدعم: حتى 180 يومًا بعد إغلاق الطلب عند الحاجة للمتابعة.',
                  'البلاغات وقرارات الإشراف: حتى 180 يومًا بعد الإغلاق أو آخر اعتراض.',
                  'سجلات الأمان التشغيلية المعتادة: حتى 90 يومًا.',
                  'النزاع أو الالتزام القانوني: فقط للمدة اللازمة للسبب القانوني.',
                ],
              ),
              const SizedBox(height: 14),
              const _InfoCard(
                title: 'قبل أن تطلب الحذف',
                children: [
                  'إذا أردت نسخة من بياناتك، اطلبها قبل حذف الحساب.',
                  'لا ترسل كلمة المرور أو رموز المصادقة أو مفاتيح الاستعادة عبر البريد.',
                  'للمساعدة: unispace.0.1.0@gmail.com',
                ],
              ),
              const SizedBox(height: 20),
              CheckboxListTile(
                key: const ValueKey('account-delete-understood'),
                value: _understood,
                onChanged: _submitting
                    ? null
                    : (value) => setState(() => _understood = value ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'أفهم أن هذا طلب لحذف الحساب والبيانات وليس مجرد تسجيل خروج.',
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                key: const ValueKey('account-delete-submit'),
                onPressed: _submitting || !_understood ? null : _requestDeletion,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_forever_outlined),
                label: Text(_submitting ? 'جارٍ تسجيل الطلب…' : 'طلب حذف الحساب'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'هذه الواجهة تسجل طلب الحذف على الخادم. إكمال إزالة جميع البيانات '
                'المشتركة والنسخ لدى مزودي الخدمة يخضع لعملية الحذف والاحتفاظ المعلنة.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<String> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            for (final item in children)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(
                      child: Text(
                        item,
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
