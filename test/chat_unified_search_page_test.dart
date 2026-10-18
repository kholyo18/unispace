import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/shell/chat/chat_unified_search_page.dart';
import 'package:UniSpace/services/chat_unified_search.dart';
import 'chat_unified_search_test.dart' show Source;

void main() {
  for (final lang in ['ar', 'en', 'fr']) {
    testWidgets('search results navigate and stay within narrow $lang layout',
        (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      ChatUnifiedSearchHit? opened;
      await tester.pumpWidget(MaterialApp(
          locale: Locale(lang),
          supportedLocales: const [Locale('ar'), Locale('en'), Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: ThemeData(
              brightness: lang == 'fr' ? Brightness.dark : Brightness.light),
          home: ChatUnifiedSearchPage(
              source: Source(),
              onOpen: (hit) async {
                opened = hit;
              })));
      await tester.enterText(find.byType(TextField), 'ecole');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();
      expect(opened?.chatId, 'chat');
      expect(opened?.messageId, '4');
      await tester.pumpWidget(const SizedBox());
    });
  }
}
