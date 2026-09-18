import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/legal/community_guidelines_screen.dart';

Future<String> visibleCommunity(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: CommunityGuidelinesScreen()),
  );
  await tester.pumpAndSettle();
  return tester.widgetList<Text>(find.byType(Text)).map((widget) {
    return widget.data ?? widget.textSpan?.toPlainText() ?? '';
  }).join('\n');
}

void main() {
  testWidgets('final community rules expose reporting, blocking and version terms',
      (tester) async {
    final text = await visibleCommunity(tester);

    expect(text, contains('الإصدار 1.0 — نافذ من 18 سبتمبر 2026'));
    expect(text, contains('تتوفر أدوات للإبلاغ'));
    expect(text, contains('الحسابات المحظورة'));
    expect(text, contains('unispace.0.1.0@gmail.com'));
    expect(text, isNot(contains('نسخة للمراجعة')));
    expect(text, isNot(contains('غير نافذة')));
    expect(
      find.byKey(const ValueKey('community-reader-policy-notice')),
      findsOneWidget,
    );

    for (var i = 1; i <= 12; i++) {
      expect(find.byKey(ValueKey('community-heading-$i')), findsOneWidget);
    }
  });
}
