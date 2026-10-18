import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/shell/chat/chat_message_search.dart';

void main() {
  const entries = [
    ChatSearchEntry(id: 'new', text: 'Café جديد'),
    ChatSearchEntry(id: 'middle', text: 'un CAFÉ au lait'),
    ChatSearchEntry(id: 'old', text: 'إِلَى المدرسة'),
  ];
  test('matches French accents and Arabic variants; punctuation has no results',
      () {
    final search = ChatMessageSearch();
    search.update('cafe', entries);
    expect(search.matchIds, ['new', 'middle']);
    expect(search.selectedId, 'new');
    search.update('الي المدرسه', entries);
    expect(search.matchIds, ['old']);
    search.update(' ! ', entries);
    expect(search.query, '');
    expect(search.selectedId, isNull);
    expect(search.move(1), isFalse);
  });
  test(
      'preserves selected ID after history changes and handles editing/deletion',
      () {
    final search = ChatMessageSearch()..update('cafe', entries);
    expect(search.move(-1), isFalse);
    expect(search.move(1), isTrue);
    expect(search.move(1), isFalse);
    search.update('CAFÉ',
        [const ChatSearchEntry(id: 'latest', text: 'cafe'), ...entries]);
    expect(search.selectedId, 'middle');
    expect(search.selectedIndex, 2);
    search.update('cafe',
        [entries.first, const ChatSearchEntry(id: 'middle', text: 'changed')]);
    expect(search.selectedId, 'new');
    search.update('cafe', []);
    expect(search.selectedIndex, -1);
    search.update('cafe', entries);
    expect(search.selectedId, 'new');
    search.update('lait', entries);
    expect(search.selectedId, 'middle');
  });
  for (final language in ['ar', 'fr', 'en']) {
    for (final brightness in Brightness.values) {
      testWidgets('navigation localized and bounded: $language $brightness',
          (tester) async {
        tester.view.physicalSize = const Size(240, 400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var older = 0;
        await tester.pumpWidget(MaterialApp(
          locale: Locale(language),
          supportedLocales: const [Locale('ar'), Locale('fr'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: ThemeData(brightness: brightness),
          home: Scaffold(
              body: ChatSearchNavigation(
                  current: 2,
                  total: 5,
                  loading: true,
                  hasOlder: true,
                  onOlder: () => older++,
                  onNewer: null)),
        ));
        expect(
            find.text(language == 'ar'
                ? '2 من 5+'
                : language == 'fr'
                    ? '2 sur 5+'
                    : '2 of 5+'),
            findsOneWidget);
        expect(
            tester
                .widget<IconButton>(find.widgetWithIcon(
                    IconButton, Icons.keyboard_arrow_down_rounded))
                .onPressed,
            isNull);
        await tester.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
        expect(older, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('highlight updates without replacing the message',
      (tester) async {
    var tapped = 0;
    Widget app(bool selected) => MaterialApp(
        home: Scaffold(
            body: ChatSearchHighlight(
                selected: selected,
                child: TextButton(
                    onPressed: () => tapped++, child: const Text('message')))));
    await tester.pumpWidget(app(false));
    final before = tester.getSize(find.text('message'));
    await tester.pumpWidget(app(true));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.text('message')), before);
    await tester.tap(find.text('message'));
    expect(tapped, 1);
    final decoration = tester
        .widget<AnimatedContainer>(find.byType(AnimatedContainer))
        .decoration! as BoxDecoration;
    expect(decoration.color!.a, greaterThan(0));
    expect(tester.takeException(), isNull);
  });
}
