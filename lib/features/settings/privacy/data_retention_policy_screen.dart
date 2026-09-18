import 'package:flutter/material.dart';

class DataRetentionPolicyScreen extends StatelessWidget {
  const DataRetentionPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الحذف والاحتفاظ بالبيانات'),
          leading: const BackButton(key: ValueKey('retention-reader-back')),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            key: const ValueKey('retention-reader-scroll'),
            padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: SelectionArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'سياسة حذف الحساب والاحتفاظ بالبيانات',
                        key: const ValueKey('retention-reader-title'),
                        style: textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text('الإصدار التحريري 1.0 — 18 سبتمبر 2026'),
                      const SizedBox(height: 12),
                      const Text(
                        'نسخة للمراجعة قبل النشر — غير نافذة. يسجل التطبيق طلب '
                        'الحذف حاليًا، لكن معالج المحو الكامل لكل بيانات الحساب '
                        'لم يُفعّل بعد. لا يُعتبر تسجيل الطلب وحده حذفًا مكتملًا.',
                        key: ValueKey('retention-reader-review-notice'),
                      ),
                      const SizedBox(height: 24),
                      for (var i = 0; i < _sections.length; i++) ...[
                        Semantics(
                          header: true,
                          child: Text(
                            _sections[i].heading,
                            key: ValueKey('retention-heading-${i + 1}'),
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _sections[i].body,
                          style: textTheme.bodyMedium?.copyWith(height: 1.7),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RetentionSection {
  const _RetentionSection(this.heading, this.body);

  final String heading;
  final String body;
}

const _sections = <_RetentionSection>[
  _RetentionSection(
    '1. ما الذي يعنيه حذف الحساب؟',
    'حذف الحساب يعني إنهاء حساب UniSpace وطلب إزالة البيانات المرتبطة به '
        'من الأنظمة الواقعة تحت سيطرة المشروع، وليس مجرد تسجيل الخروج أو '
        'تعطيل الحساب. لا يؤدي حذف تطبيق UniSpace من الهاتف وحده إلى حذف '
        'الحساب السحابي.',
  ),
  _RetentionSection(
    '2. طلب الحذف والمسار الحالي',
    'يمكن للمستخدم المسجل الدخول تقديم طلب حذف من صفحة الخصوصية داخل '
        'التطبيق. يُسجّل الطلب على الخادم باسم الحساب المصادق عليه فقط ولا '
        'يقبل UID يرسله العميل. الطلب المتكرر أثناء وجود طلب نشط لا ينشئ '
        'طلبات مكررة.\n\n'
        'المعالجة الحالية تسجل الطلب ولا تنفذ بعد محوًا شاملاً تلقائيًا لكل '
        'Firestore وStorage وAuthentication. لذلك يبقى اكتمال معالج الحذف '
        'شرطًا قبل تقديم هذه السياسة على أنها نافذة.',
  ),
  _RetentionSection(
    '3. الحساب والمحتوى العادي',
    'الهدف التشغيلي المعتمد بعد اكتمال معالج الحذف هو إزالة الحساب '
        'والمحتوى والوسائط العادية الواقعة تحت سيطرة UniSpace خلال مدة لا '
        'تتجاوز 30 يومًا من الطلب الموثق، ما لم توجد ضرورة قانونية أو أمنية '
        'محددة تبرر الاحتفاظ بجزء محدود من البيانات.',
  ),
  _RetentionSection(
    '4. الدعم وخدمة المستخدم',
    'سجلات طلبات الدعم والمراسلات المرتبطة بها يمكن الاحتفاظ بها لمدة تصل '
        'إلى 180 يومًا بعد إغلاق الطلب، ثم تزال أو تقلل إلى الحد اللازم، '
        'ما لم توجد مطالبة قانونية أو نزاع قائم يبرر مدة مختلفة.',
  ),
  _RetentionSection(
    '5. البلاغات والإشراف',
    'بيانات البلاغات وقرارات الإشراف والاعتراضات يمكن الاحتفاظ بها لمدة تصل '
        'إلى 180 يومًا بعد إغلاق القضية أو آخر اعتراض، بما يساعد على منع '
        'إساءة الاستخدام ومراجعة القرارات. لا يعني ذلك الاحتفاظ بمحتوى خاص '
        'كامل إذا لم يعد لازمًا للقضية.',
  ),
  _RetentionSection(
    '6. سجلات الأمان',
    'السجلات الأمنية التشغيلية العادية يمكن الاحتفاظ بها لمدة تصل إلى '
        '90 يومًا. قد يلزم الاحتفاظ بسجل أضيق لمدة أطول إذا كان مرتبطًا '
        'بحادث أمني أو احتيال أو التزام قانوني محدد.',
  ),
  _RetentionSection(
    '7. النزاعات والالتزامات القانونية',
    'عند وجود نزاع أو أمر قانوني أو التزام واجب، يمكن الاحتفاظ فقط بالبيانات '
        'الضرورية لذلك الغرض وللمدة اللازمة له. لا تستخدم هذه الاستثناءات '
        'كأساس لاحتفاظ عام وغير محدد بكل بيانات المستخدم.',
  ),
  _RetentionSection(
    '8. النسخ الاحتياطية ومقدمو الخدمة',
    'قد تستغرق إزالة بعض النسخ الاحتياطية أو النسخ الموجودة لدى مزودي '
        'البنية التحتية وقتًا تقنيًا إضافيًا وفق أنظمة المزود. حذف حساب '
        'UniSpace لا يحذف تلقائيًا حساب Google أو أي حساب خارجي مستقل.',
  ),
  _RetentionSection(
    '9. تنزيل البيانات قبل الحذف',
    'يمكن للمستخدم تنزيل نسخة من البيانات التي يدعمها مسار التصدير الحالي '
        'قبل تقديم طلب الحذف. التصدير الحالي ليس تدقيقًا شاملاً لكل معلومة '
        'محتملة، ويعرض نطاقه داخل الملف المصدر.',
  ),
  _RetentionSection(
    '10. التواصل والصفحة الخارجية',
    'للاستفسارات أو طلبات الحقوق: unispace.0.1.0@gmail.com. يجب توفير صفحة '
        'ويب عامة مستقلة لطلب الحذف قبل طرح التطبيق على Google Play؛ ملف '
        'HTML جاهز لذلك داخل المشروع لكنه لا يصبح رابطًا عامًا بمجرد وجوده '
        'في المستودع.',
  ),
];
