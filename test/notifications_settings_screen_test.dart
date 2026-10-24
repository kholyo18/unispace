import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:UniSpace/generated/l10n.dart';
import 'package:UniSpace/ui/theme.dart';
import 'package:UniSpace/ui/settings/app_settings.dart';
import 'package:UniSpace/ui/settings/notifications_settings_screen.dart';
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  setUp(() async { await AppSettings.instance.load(); AppSettings.instance.notifier.value = SettingsData.initial(); });
  for (final language in ['ar', 'en', 'fr']) {
    for (final dark in [false, true]) {
      testWidgets('notification settings persist toggles and render $language dark=$dark', (tester) async {
        tester.view.physicalSize = const Size(360, 800); tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(theme: dark ? AppTheme.dark : AppTheme.light,
          locale: Locale(language), supportedLocales: S.delegate.supportedLocales,
          localizationsDelegates: const [S.delegate, ...GlobalMaterialLocalizations.delegates],
          builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)), child: child!),
          home: const NotificationsSettingsScreen()));
        await tester.pumpAndSettle(); expect(tester.takeException(), isNull);
        final master = find.byKey(const ValueKey('notifications-master'));
        await tester.tap(master); await tester.pumpAndSettle();
        expect(AppSettings.instance.notifier.value.notificationsEnabled, isFalse);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('settings_notifications_enabled'), isFalse);
        await tester.ensureVisible(find.byKey(const ValueKey('notifications-exams')));
        expect(tester.widget<SwitchListTile>(find.byKey(const ValueKey('notifications-exams'))).onChanged, isNull);
        await tester.ensureVisible(master); await tester.pumpAndSettle(); await tester.tap(master); await tester.pumpAndSettle();
        final exams = find.byKey(const ValueKey('notifications-exams'));
        await tester.ensureVisible(exams); await tester.pumpAndSettle(); await tester.tap(exams); await tester.pumpAndSettle();
        expect(AppSettings.instance.notifier.value.examRemindersEnabled, isFalse);
        expect(prefs.getBool('settings_exam_reminders_enabled'), isFalse);
        await tester.drag(find.byType(ListView), const Offset(0,-700)); await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
