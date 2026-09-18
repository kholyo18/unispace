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
    expect(text, contains('الخانة الحالية لا تحفظ سجلًا مستقلاً'));
    expect(text, contains('ولا تطلب إعادة قبول تلقائية من الجلسات المفتوحة'));
    expect(text, contains('إلغاء التحديد يعطل زري الدخول مجددًا'));
    expect(text, isNot(contains('يسجل الإصدار والتاريخ وطريقة القبول')));
  });

  testWidgets('age rule is final without claiming independent age verification',
      (tester) async {
    final text = await visibleTerms(tester);
    expect(
      text,
      contains('الحد الأدنى لاستخدام الحساب والمشاركة في المجتمع هو 18 سنة كاملة'),
    );
    expect(text, contains('القانون المطبق يتطلب أهلية أو موافقة إضافية'));
    expect(text, contains('لا تعني إمكانية إنشاء الحساب تقنيًا'));
    expect(text, isNot(contains('غير مفعّلين في النسخة الحالية')));
    expect(text, isNot(contains('أقل من 19 سنة')));
  });

  testWidgets('copy preserves rights and describes deployed deletion flow',
      (tester) async {
    final text = await visibleTerms(tester);
    expect(text, contains('يحتفظ المستخدم بالحقوق التي يملكها في محتواه'));
    expect(text, contains('لا يمنح قبول شروط الاستخدام إذنًا بتدريب النموذج'));
    expect(text, contains('اختيار منفصل واختياري لكل مورد'));
    expect(text, contains('لا ينشأ عن قبول هذه الشروط اشتراك مالي'));
    expect(
      text,
      contains('https://fachub-c631c.web.app/delete-account'),
    );
    expect(text, contains('مدة لا تتجاوز 30 يومًا'));
    expect(text, isNot(contains('لم يكتمل التحقق من حذف جميع أنواع البيانات')));
    expect(text, isNot(contains('نسخة للمراجعة')));
  });

  testWidgets('final version retains 22 articles and publication metadata',
      (tester) async {
    final text = await visibleTerms(tester);
    expect(text, contains('الإصدار 1.0 — نافذ من 18 سبتمبر 2026'));
    expect(text, contains('يُشار في هذه الشروط إلى المشروع والقائمين على تشغيله'));
    expect(text, contains('unispace.0.1.0@gmail.com'));
    expect(text, isNot(contains('غير نافذة')));
    expect(text, isNot(contains('يلزم استكمال هوية')));
    for (var i = 1; i <= 22; i++) {
      expect(find.byKey(ValueKey('terms-heading-$i')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('terms-heading-23')), findsNothing);
    expect(
      find.byKey(const ValueKey('terms-reader-version-notice')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
