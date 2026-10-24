import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:UniSpace/generated/l10n.dart';
import 'package:UniSpace/features/exams/presentation/pages/exams_calendar_page.dart';

void main() {
  testWidgets('corrupt calendar exits loading, preserves data and can retry', (tester) async {
    SharedPreferences.setMockInitialValues({'exam_calendar_items': '{broken'});
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [S.delegate,
        GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate],
      supportedLocales: S.delegate.supportedLocales,
      home: const ExamsCalendarPage(),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Saved exams could not be loaded. Your data has not been deleted.'), findsOneWidget);
    final add = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add));
    expect(add.onPressed, isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('exam_calendar_items'), '{broken');
    await prefs.setString('exam_calendar_items', '[]');
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsNothing);
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add)).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });
}
