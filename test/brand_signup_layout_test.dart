import 'package:firebase_core/firebase_core.dart';
// Firebase's test helper initializes the platform channel without a live backend.
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/auth/signup_flow.dart';
import 'package:UniSpace/generated/l10n.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
  setUpAll(() async { await Firebase.initializeApp(); });
  for (final locale in ['ar', 'en', 'fr']) {
    for (final dark in [false, true]) {
      testWidgets('signup identity remains usable in $locale dark=$dark', (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(
          locale: Locale(locale),
          supportedLocales: const [Locale('ar'), Locale('en'), Locale('fr')],
          localizationsDelegates: const [S.delegate, ...GlobalMaterialLocalizations.delegates],
          theme: dark ? ThemeData.dark() : ThemeData.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.6),
              viewInsets: const EdgeInsets.only(bottom: 250)), child: child!),
          home: const SignUpFlowScreen(skipAccountCreation: true,
            initialFirstName: 'Sara', initialLastName: 'Student'),
        ));
        await tester.pumpAndSettle();
        final next = find.byKey(const ValueKey('signup-continue'));
        await tester.ensureVisible(next);
        await tester.tap(next);
        await tester.pumpAndSettle();
        final first = find.byType(TextField).first;
        await tester.ensureVisible(first);
        expect(tester.widget<TextField>(first).controller!.text, 'Sara');
        await tester.enterText(first, 'Lina');
        await tester.ensureVisible(next);
        await tester.tap(next);
        await tester.pumpAndSettle();
        // Empty username still fails local validation; no network request.
        await tester.ensureVisible(next);
        await tester.tap(next);
        await tester.pumpAndSettle();
        expect(find.byType(TextFormField), findsOneWidget);
        expect(tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text, isEmpty);
        expect(tester.takeException(), isNull);
        // Inspect the remaining presentation steps without submitting to Firebase.
        for (final page in [3, 4, 1]) {
          tester.widget<PageView>(find.byType(PageView)).controller!.jumpToPage(page);
          await tester.pumpAndSettle();
          await tester.ensureVisible(next);
          expect(tester.takeException(), isNull);
        }
        expect(tester.widget<TextField>(find.byType(TextField).first).controller!.text, 'Lina');
      });
    }
  }
}
