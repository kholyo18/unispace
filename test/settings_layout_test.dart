import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:UniSpace/generated/l10n.dart';
import 'package:UniSpace/ui/theme.dart';
import 'package:UniSpace/ui/settings/drawer_screens.dart';
import 'package:UniSpace/ui/settings/privacy/privacy_account_overview_tab.dart';
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
  setUpAll(() async { SharedPreferences.setMockInitialValues({}); await Firebase.initializeApp(); });
  for (final locale in ['ar', 'en', 'fr']) {
    for (final dark in [false, true]) {
      for (final privacy in [false, true]) {
        testWidgets('signed-out settings layout privacy=$privacy $locale dark=$dark', (tester) async {
          tester.view.physicalSize = const Size(360, 800); tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(MaterialApp(locale: Locale(locale), supportedLocales: S.delegate.supportedLocales,
            localizationsDelegates: const [S.delegate, ...GlobalMaterialLocalizations.delegates],
            theme: dark ? AppTheme.dark : AppTheme.light,
            builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)), child: child!),
            home: Scaffold(body: privacy ? const PrivacyAccountOverviewTab() : const SecurityCenterContent())));
          await tester.pump(); await tester.pump(const Duration(milliseconds: 100));
          expect(tester.takeException(), isNull);
          if (!privacy) expect(find.byType(ListView), findsNothing);
          for (var i=0; privacy && i<5; i++) {
            await tester.drag(find.byType(ListView).first, const Offset(0,-500));
            await tester.pump(const Duration(milliseconds: 400));
            expect(tester.takeException(), isNull);
          }
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }
}
