import 'package:flutter/material.dart';

/// Read-only Arabic community-guidelines draft for UniSpace.
/// Reading this page does not record agreement or change login state.
class CommunityGuidelinesScreen extends StatelessWidget {
  const CommunityGuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('قواعد المجتمع'),
          leading: const BackButton(key: ValueKey('community-reader-back')),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            key: const ValueKey('community-reader-scroll'),
            padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: SelectionArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'قواعد مجتمع UniSpace',
                        key: const ValueKey('community-reader-title'),
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('نسخة عربية للمراجعة — 17 سبتمبر 2026'),
                      const SizedBox(height: 12),
                      const Text(
                        'هذه القواعد توضّح السلوك والمحتوى المقبولين في مجتمع UniSpace. '
                        'هي نسخة مراجعة قبل النشر، وقراءتها وحدها لا تحدد خانة الموافقة '
                        'على شروط الاستخدام ولا تغيّر حالة تسجيل الدخول.',
                        key: ValueKey('community-reader-review-notice'),
                      ),
                      const SizedBox(height: 24),
                      for (var i = 0; i < _sections.length; i++) ...[
                        Semantics(
                          header: true,
                          child: Text(
                            _sections[i].heading,
                            key: ValueKey('community-heading-${i + 1}'),
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

class _GuidelineSection {
  const _GuidelineSection(this.heading, this.body);

  final String heading;
  final String body;
}

const _sections = <_GuidelineSection>[
  _GuidelineSection(
    '1. الهدف والنطاق',
    'تنطبق هذه القواعد على المنشورات والتعليقات والرسائل والمجموعات والملفات '
        'والمحتوى الذي يشاركه المستخدمون داخل UniSpace. الهدف هو توفير مساحة جامعية '
        'مفيدة وآمنة تحترم الدراسة والنقاش والاختلاف المشروع.',
  ),
  _GuidelineSection(
    '2. الاحترام ومنع الإساءة',
    'يمنع التحرش والتهديد والتنمر والإهانة المتكررة والاستهداف الشخصي والتحريض '
        'على الكراهية أو الإقصاء على أساس صفات شخصية محمية قانونًا. الاختلاف والنقد '
        'مسموحان ما داما لا يتحولان إلى إساءة أو مضايقة.',
  ),
  _GuidelineSection(
    '3. السلامة والمحتوى غير المقبول',
    'يمنع نشر أو الترويج لمحتوى غير قانوني أو استغلالي أو شديد الخطورة، أو محتوى '
        'يشجع على إيذاء الآخرين أو استغلال القاصرين. كما يمنع المحتوى الجنسي الصريح '
        'والمحتوى الذي ينتهك كرامة الأشخاص أو خصوصيتهم.',
  ),
  _GuidelineSection(
    '4. الخصوصية والهوية',
    'لا تنشر بيانات شخصية أو صورًا أو محادثات خاصة تخص شخصًا آخر دون أساس مشروع أو '
        'إذنه حيث يلزم. يمنع انتحال شخصية طالب أو أستاذ أو جامعة أو جهة رسمية، كما '
        'يمنع إنشاء حسابات بقصد التضليل أو تجاوز الحظر.',
  ),
  _GuidelineSection(
    '5. النزاهة الأكاديمية وحقوق المحتوى',
    'يسمح بالنقاش الدراسي ومشاركة الشروح والموارد التي يملك المستخدم حق نشرها. '
        'يمنع نشر أعمال مقرصنة أو وثائق مزورة أو اختبارات سرية أو محتوى يقدَّم على '
        'أنه عمل المستخدم وهو منسوب في الحقيقة إلى شخص آخر.',
  ),
  _GuidelineSection(
    '6. السبام والاحتيال والترويج المضلل',
    'يمنع السبام والرسائل المتكررة المزعجة والروابط الخادعة ومحاولات الاحتيال '
        'وانتحال العروض الرسمية. يجب تمييز المحتوى التجاري أو الممول بوضوح عندما '
        'يكون ذلك مطلوبًا، ولا يجوز استخدام المجتمع لخداع الطلاب أو جمع بياناتهم '
        'بأساليب مضللة.',
  ),
  _GuidelineSection(
    '7. الرسائل والمجموعات',
    'استخدم المراسلة والمجموعات للغرض المتوقع منها واحترم رغبة الآخرين في عدم '
        'التواصل. لا تستخدم الرسائل للمضايقة أو الإغراق أو تجاوز الحظر. عند توفر '
        'أدوات الحظر أو الإبلاغ داخل التطبيق، يمكن للمستخدم استعمالها لحماية تجربته.',
  ),
  _GuidelineSection(
    '8. الإبلاغ عن المحتوى والمستخدمين',
    'يمكن الإبلاغ عن محتوى أو حساب مخالف من خلال أدوات الإبلاغ المتاحة داخل التطبيق '
        'أو عبر البريد unispace.0.1.0@gmail.com عند الحاجة. يجب وصف المشكلة بوضوح '
        'ومن دون إرسال كلمات مرور أو رموز تحقق أو بيانات حساسة لا تلزم لمعالجة البلاغ.',
  ),
  _GuidelineSection(
    '9. الإشراف والإجراءات',
    'قد تتخذ إدارة UniSpace إجراءات متناسبة مثل إخفاء محتوى أو تقييد وظيفة أو '
        'تعليق حساب عندما توجد مخالفة معقولة لهذه القواعد أو للقانون. تتأثر شدة '
        'الإجراء بطبيعة المخالفة وتكرارها وخطرها. لا تعني هذه القواعد أن كل محتوى '
        'يُراجع مسبقًا قبل ظهوره.',
  ),
  _GuidelineSection(
    '10. الاعتراض والتواصل والتحديثات',
    'عند توفر مسار اعتراض داخل التطبيق يمكن استخدامه، كما يمكن التواصل عبر '
        'unispace.0.1.0@gmail.com بشأن قرارات الإشراف أو الاستفسارات. قد تُحدَّث '
        'هذه القواعد مع تطور الخدمة، ويجب توضيح التغييرات المهمة عند اعتماد نسخة '
        'جديدة للنشر. هذه النسخة لا تُنشئ موافقة مستقلة خارج خانة شروط الاستخدام.',
  ),
];
