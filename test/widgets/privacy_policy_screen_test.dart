import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/settings/privacy/privacy_policy_screen.dart';
import 'package:UniSpace/generated/l10n.dart';

class _PolicyStrings extends S {
  _PolicyStrings(this.body);

  final String body;

  @override
  String get privacyPolicy => 'Privacy';

  @override
  String get privacyPolicyTitle => 'Privacy policy';

  @override
  String get privacyPolicyBody => body;
}

class _PolicyDelegate extends LocalizationsDelegate<S> {
  const _PolicyDelegate(this.body);

  final String body;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<S> load(Locale locale) => SynchronousFuture<S>(_PolicyStrings(body));

  @override
  bool shouldReload(_PolicyDelegate old) => body != old.body;
}

Future<void> _pumpPolicy(
  WidgetTester tester, {
  required String body,
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en'), Locale('fr')],
      localizationsDelegates: [
        _PolicyDelegate(body),
        ...GlobalMaterialLocalizations.delegates,
      ],
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: const PrivacyPolicyScreen(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('reads localized content and enables selection', (tester) async {
    await _pumpPolicy(tester, body: 'An introduction.\n1) Data\nA paragraph.');

    expect(find.text('Privacy policy'), findsOneWidget);
    expect(find.text('An introduction.'), findsOneWidget);
    expect(find.text('A paragraph.'), findsOneWidget);
    expect(find.byType(SelectionArea), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recognizes western, Arabic and Persian numbered headings',
      (tester) async {
    const headings = ['1) Data', '٢) البيانات', '۳) البيانات', '4. Sharing'];
    await _pumpPolicy(
      tester,
      body: '${headings.join('\n')}\n1.0 is a version, not a heading.',
    );

    for (final heading in headings) {
      final text = tester.widget<Text>(find.text(heading));
      expect(text.style?.fontWeight, FontWeight.w600);
      expect(
        find.ancestor(
          of: find.text(heading),
          matching: find.byWidgetPredicate(
            (widget) => widget is Semantics && widget.properties.header == true,
          ),
        ),
        findsOneWidget,
      );
    }
    final version = tester.widget<Text>(
      find.text('1.0 is a version, not a heading.'),
    );
    expect(version.style?.fontWeight, isNot(FontWeight.w600));
  });

  testWidgets('handles line endings, blank lines, and bullet formats',
      (tester) async {
    await _pumpPolicy(
      tester,
      body: '\r\nIntro\r\n\r\n\r\n- First\r* Second\n• Third\n\n',
    );

    expect(find.text('Intro'), findsOneWidget);
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
    expect(find.text('Third'), findsOneWidget);
    expect(find.text('•'), findsNWidgets(3));
    expect(
      find.byWidgetPredicate(
        (widget) => widget is SizedBox && widget.height == 12,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('inherits RTL and LTR from the selected locale', (tester) async {
    for (final locale in ['ar', 'en', 'fr']) {
      await _pumpPolicy(tester, body: '- Item', locale: Locale(locale));
      expect(
        Directionality.of(tester.element(find.text('Item'))),
        locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('shares its scroll controller and cleans up on close',
      (tester) async {
    await _pumpPolicy(
      tester,
      body: List.generate(
        80,
        (i) => 'Paragraph $i with readable content.',
      ).join('\n'),
    );
    final scrollbar = tester.widget<Scrollbar>(find.byType(Scrollbar));
    final scrollView = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    expect(scrollbar.controller, isNotNull);
    expect(identical(scrollbar.controller, scrollView.controller), isTrue);
    expect(scrollView.primary, isFalse);

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(scrollView.controller!.offset, greaterThan(0));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('limits reading width on wide screens', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpPolicy(tester, body: 'Readable content.');

    final content = find.byWidgetPredicate(
      (widget) => widget is ConstrainedBox && widget.constraints.maxWidth == 840,
    );
    expect(content, findsOneWidget);
    expect(tester.getSize(content).width, lessThanOrEqualTo(840));
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports narrow screens, large text and both themes',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      await _pumpPolicy(
        tester,
        body: '١) البيانات\n- فقرة طويلة نسبيًا لقراءة سياسة الخصوصية على الهاتف.',
        locale: const Locale('ar'),
        textScale: 2.5,
        themeMode: mode,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('handles an empty body without inventing legal text',
      (tester) async {
    await _pumpPolicy(tester, body: ' \r\n \n');
    expect(find.text('Privacy policy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
