import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/auth/terms_of_use_screen.dart';

Future<String> visibleTerms(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: TermsOfUseScreen()));
  await tester.pumpAndSettle();
  return tester.widgetList<Text>(find.byType(Text)).map((widget) {
    return widget.data ?? widget.textSpan?.toPlainText() ?? '';
  }).join('\n');
}

void main() {
  testWidgets('copy describes screen-local agreement without claiming a ledger',
      (tester) async {
    final text = await visibleTerms(tester);
    expect(text, contains('الخانة الحالية لا تحفظ سجلًا مستقلًا'));
    expect(text, contains('ولا تطلب إعادة قبول تلقائية من الجلسات المفتوحة'));
    expect(text, contains('إلغاء التحديد يعطل زري الدخول مجددًا'));
    expect(text, isNot(contains('يسجل الإصدار والتاريخ وطريقة القبول')));
    expect(text, isNot(contains('يطبق المسار على التسجيل بالبريد وGoogle')));
  });

  testWidgets('age requirements stay distinct from unimplemented procedures',
      (tester) async {
    final text = await visibleTerms(tester);
    expect(text, contains('الحد الأدنى المختار لاستخدام الحساب والمشاركة في المجتمع هو 18 سنة كاملة'));
    expect(text, contains('موافقة الممثل القانوني حيث يلزم'));
    expect(text, contains('غير مفعّلين في النسخة الحالية'));
    expect(text, contains('ولا تعفي من متطلبات الأهلية الواجبة'));
    expect(text, isNot(contains('عند بلوغ 19 سنة يطلب قبول شخصي جديد')));
  });

  testWidgets('copy preserves rights without promising unverified services',
      (tester) async {
    final text = await visibleTerms(tester);
    expect(text, contains('يحتفظ المستخدم بالحقوق التي يملكها في محتواه'));
    expect(text, contains('لا يمنح قبول شروط الاستخدام إذنًا بتدريب النموذج'));
    expect(text, contains('اختيار منفصل واختياري لكل مورد'));
    expect(text, contains('لا ينشأ عن قبول هذه الشروط اشتراك مالي'));
    expect(text, contains('لم يكتمل التحقق من حذف جميع أنواع البيانات'));
    expect(text, contains('لا يبيح هذا التوضيح احتفاظًا غير محدود'));
    expect(text, isNot(contains('تطبّق سياسة الحذف والاحتفاظ')));
    expect(text, isNot(contains('الملحق الاختياري المنفصل')));
    expect(text, isNot(contains('خلال 15 يومًا')));
  });

  testWidgets('revision retains 22 articles and discloses publication blockers',
      (tester) async {
    final text = await visibleTerms(tester);
    expect(text, contains('الإصدار التحريري 1.1 — 17 سبتمبر 2026'));
    expect(text, contains('نسخة منقحة للمراجعة قبل النشر — غير نافذة'));
    expect(text, contains('يلزم استكمال هوية الشخص أو الجهة المسؤولة'));
    expect(text, contains('unispace.0.1.0@gmail.com'));
    for (var i = 1; i <= 22; i++) {
      expect(find.byKey(ValueKey('terms-heading-$i')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('terms-heading-23')), findsNothing);
    expect(find.byKey(const ValueKey('terms-reader-draft-notice')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
