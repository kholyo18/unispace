import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:UniSpace/services/chat_translation_consent.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('legacy enabled setting is not consent and consent is account scoped',
      () async {
    SharedPreferences.setMockInitialValues({'autoTranslate': true});
    expect(await hasChatTranslationConsent('a'), isFalse);
    await recordChatTranslationConsent('a');
    expect(await hasChatTranslationConsent('a'), isTrue);
    expect(await hasChatTranslationConsent('b'), isFalse);
    expect(await hasChatTranslationConsent(''), isFalse);
  });
  test('outdated consent is not silently accepted', () async {
    SharedPreferences.setMockInitialValues({'chat_translation_consent_a': 0});
    expect(await hasChatTranslationConsent('a'), isFalse);
  });
  test('malformed consent fails closed', () async {
    SharedPreferences.setMockInitialValues({'chat_translation_consent_a': '1'});
    expect(await hasChatTranslationConsent('a'), isFalse);
  });
  for (final language in ['ar', 'en', 'fr']) {
    testWidgets('explicit consent required in $language', (tester) async {
      bool? result;
      await tester.pumpWidget(MaterialApp(
        locale: Locale(language),
        supportedLocales: const [Locale('ar'), Locale('en'), Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () async {
                      result = await confirmChatTranslation(context);
                    },
                    child: const Text('Open')))),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text(chatTranslationDisclosure(language)), findsOneWidget);
      expect(result, isNull);
      await tester
          .tap(find.byKey(const ValueKey('translation-consent-cancel')));
      await tester.pumpAndSettle();
      expect(result, isFalse);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('translation-consent-enable')));
      await tester.pumpAndSettle();
      expect(result, isTrue);
      // The dialog alone never grants a different/current account persistence.
      expect(await hasChatTranslationConsent('a'), isFalse);
    });
  }
  testWidgets('back dismissal declines consent', (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () async {
                      result = await confirmChatTranslation(context);
                    },
                    child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });
}

