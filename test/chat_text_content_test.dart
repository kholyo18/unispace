import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:UniSpace/features/shell/chat/chat_text_content.dart';

void main() {
  Future<void> show(
    WidgetTester tester,
    String text, {
    Future<bool> Function(Uri)? launch,
    VoidCallback? failure,
  }) =>
      tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SizedBox(
        width: 500,
        child: ChatTextContent(
            text: text,
            style: const TextStyle(fontSize: 16),
            onLaunchLink: launch,
            onLinkFailure: failure),
      ))));

  Future<void> tapSubstring(
      WidgetTester tester, String full, String part) async {
    final finder = find.descendant(
        of: find.byType(ChatTextContent), matching: find.byType(RichText));
    final paragraph = tester.renderObject<RenderParagraph>(finder);
    final start = full.indexOf(part);
    final box = paragraph
        .getBoxesForSelection(
            TextSelection(baseOffset: start, extentOffset: start + part.length))
        .first
        .toRect();
    await tester.tapAt(paragraph.localToGlobal(box.center));
    await tester.pump();
  }

  testWidgets(
      'Maps link opens externally through launcher while preserving multilingual text',
      (tester) async {
    const url = 'https://www.google.com/maps/search/?api=1&query=36.75,3.06';
    const text = 'مرحبا 👨‍👩‍👧‍👦 Bonjour $url';
    Uri? opened;
    await show(tester, text, launch: (uri) async {
      opened = uri;
      return true;
    });
    final rich = tester.widget<RichText>(find.descendant(
        of: find.byType(ChatTextContent), matching: find.byType(RichText)));
    expect(rich.text.toPlainText(), text);
    final textWidget = tester.widget<Text>(find.descendant(
        of: find.byType(ChatTextContent), matching: find.byType(Text)));
    expect(textWidget.style!.fontFamilyFallback, contains('NotoColorEmoji'));
    await tapSubstring(tester, text, url);
    expect(opened, Uri.parse(url));
  });

  testWidgets('unsafe schemes remain non-interactive', (tester) async {
    const text =
        'javascript:alert(1) tel:+213123456789 file:///tmp/a intent://example';
    var launches = 0;
    await show(tester, text, launch: (_) async {
      launches++;
      return true;
    });
    await tapSubstring(tester, text, 'javascript:alert(1)');
    await tapSubstring(tester, text, 'tel:+213123456789');
    expect(launches, 0);
    final rich = tester.widget<RichText>(find.descendant(
        of: find.byType(ChatTextContent), matching: find.byType(RichText)));
    expect(rich.text.toPlainText(), text);
  });

  testWidgets('sentence punctuation is kept outside the URL', (tester) async {
    const url = 'https://example.com/a';
    const text = 'See ($url).';
    Uri? opened;
    await show(tester, text, launch: (uri) async {
      opened = uri;
      return true;
    });
    await tapSubstring(tester, text, url);
    expect(opened, Uri.parse(url));
    expect(
        tester
            .widget<RichText>(find.descendant(
                of: find.byType(ChatTextContent),
                matching: find.byType(RichText)))
            .text
            .toPlainText(),
        text);
  });

  testWidgets(
      'reused message widget opens the new link and handles launch failure',
      (tester) async {
    Uri? opened;
    var failures = 0;
    await show(tester, 'https://old.example', launch: (_) async => true);
    const text = 'https://new.example';
    await show(tester, text, launch: (uri) async {
      opened = uri;
      throw StateError('No app');
    }, failure: () {
      failures++;
    });
    await tapSubstring(tester, text, text);
    expect(opened, Uri.parse(text));
    expect(failures, 1);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'shared coordinates render as a location card and open exact destination',
      (tester) async {
    const url =
        'https://www.google.com/maps/search/?api=1&query=36.752500,3.042000';
    Uri? opened;
    await show(tester, url, launch: (uri) async {
      opened = uri;
      return true;
    });
    expect(find.text('Shared location'), findsOneWidget);
    expect(
        tester.getSize(find.byKey(const ValueKey('openSharedLocation'))).height,
        lessThan(160));
    expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    await tester.tap(find.byKey(const ValueKey('openSharedLocation')));
    await tester.pump();
    expect(opened, Uri.parse(url));
  });
  for (final locale in ['ar', 'fr', 'en']) {
    for (final brightness in Brightness.values) {
      testWidgets('location card fits narrow $locale $brightness',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(280, 600));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        Uri? opened;
        const url =
            'https://www.google.com/maps/search/?api=1&query=36.752500,3.042000';
        await tester.pumpWidget(MaterialApp(
          locale: Locale(locale),
          supportedLocales: const [Locale('ar'), Locale('fr'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: ThemeData(brightness: brightness),
          home: Scaffold(
              body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: ChatTextContent(
              text: url,
              style: const TextStyle(fontSize: 16),
              onLaunchLink: (uri) async {
                opened = uri;
                return true;
              },
            ),
          )),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(opened, isNull);
        await tester.tap(find.byKey(const ValueKey('openSharedLocation')));
        await tester.pump();
        expect(opened, Uri.parse(url));
      });
    }
  }
}
