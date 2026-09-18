import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/settings/privacy/privacy_policy_screen.dart';

Future<String> visiblePrivacy(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: PrivacyPolicyScreen()),
  );
  await tester.pumpAndSettle();
  return tester.widgetList<Text>(find.byType(Text)).map((widget) {
    return widget.data ?? widget.textSpan?.toPlainText() ?? '';
  }).join('\n');
}

void main() {
  testWidgets('final privacy policy exposes current deletion and retention terms',
      (tester) async {
    final text = await visiblePrivacy(tester);

    expect(text, contains('الإصدار 1.0 — نافذ من 18 سبتمبر 2026'));
    expect(text, contains('https://fachub-c631c.web.app/delete-account'));
    expect(text, contains('30 يومًا'));
    expect(text, contains('90 يومًا'));
    expect(text, contains('180 يومًا'));
    expect(text, contains('خدمة الحساب والمشاركة في المجتمع مخصصة لمن أتم 18 سنة'));
    expect(text, isNot(contains('نسخة منقحة للمراجعة')));
    expect(text, isNot(contains('قبل اعتماد السياسة')));
    expect(
      find.byKey(const ValueKey('privacy-reader-policy-notice')),
      findsOneWidget,
    );

    for (var i = 1; i <= 11; i++) {
      expect(find.byKey(ValueKey('privacy-heading-$i')), findsOneWidget);
    }
  });
}
