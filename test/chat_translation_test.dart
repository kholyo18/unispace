import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/services/chat_translation.dart';
import 'package:UniSpace/features/shell/chat/chat_translated_text.dart';

void main() {
  test('default target follows app language and preserves explicit targets',
      () {
    for (final code in ['ar', 'en', 'fr']) {
      expect(chatTranslationTarget('auto', code), code);
    }
    expect(chatTranslationTarget('fr', 'ar'), 'fr');
    expect(chatTranslationTarget('invalid', 'ar'), 'ar');
  });
  test('coalesces queued duplicate text and distinguishes target language',
      () async {
    var calls = 0;
    final service = ChatTranslationService(translate: (text, target) async {
      calls++;
      return ChatTranslation('$target result', 'en');
    });
    final outputs = await Future.wait([
      service.translate('hello', 'ar', isCurrent: () => true),
      service.translate('hello', 'ar', isCurrent: () => true)
    ]);
    expect(calls, 1);
    expect(outputs.last.text, 'ar result');
    await service.translate('hello', 'fr', isCurrent: () => true);
    expect(calls, 2);
    service.dispose();
  });
  test(
      'cancelled queued request does not send text; disposal rejects late response',
      () async {
    final pending = Completer<ChatTranslation>();
    var calls = 0, current = true;
    final service = ChatTranslationService(translate: (text, target) {
      calls++;
      return pending.future;
    });
    final first = service.translate('first', 'ar', isCurrent: () => true);
    final second = service.translate('second', 'ar', isCurrent: () => current);
    final expectation =
        expectLater(Future.wait([first, second]), throwsStateError);
    await Future<void>.delayed(Duration.zero);
    current = false;
    service.dispose();
    pending.complete(const ChatTranslation('late', 'en'));
    await expectation;
    expect(calls, 1);
  });
  test('failure is retryable and not stored in cache', () async {
    var calls = 0;
    final service = ChatTranslationService(translate: (a, b) async {
      if (++calls == 1) throw StateError('offline');
      return const ChatTranslation('bonjour', 'en');
    });
    await expectLater(service.translate('hello', 'fr', isCurrent: () => true),
        throwsStateError);
    expect((await service.translate('hello', 'fr', isCurrent: () => true)).text,
        'bonjour');
    service.dispose();
  });
  test('preserves original for unconfirmed or empty provider results',
      () async {
    for (final result in const [
      ChatTranslation('invented meaning', 'auto'),
      ChatTranslation('invented meaning', 'und'),
      ChatTranslation('invented meaning', 'unknown'),
      ChatTranslation('invented meaning', ''),
      ChatTranslation('   ', 'en'),
      ChatTranslation('different spelling', 'fr'),
      ChatTranslation('HELLO', 'en'),
    ]) {
      final service =
          ChatTranslationService(translate: (_, __) async => result);
      final actual =
          await service.translate('hello', 'fr', isCurrent: () => true);
      expect(actual.text, 'hello');
      service.dispose();
    }
  });
  Future<void> show(WidgetTester tester, ChatTranslationService service,
      {bool enabled = true,
      String text = 'hello',
      String target = 'fr'}) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ChatTranslatedText(
                text: text,
                style: const TextStyle(),
                enabled: enabled,
                target: target,
                service: service))));
    await tester.pump();
  }

  testWidgets(
      'disabled performs no request, enabled translates and toggles original',
      (tester) async {
    var calls = 0;
    final service = ChatTranslationService(translate: (a, b) async {
      calls++;
      return const ChatTranslation('bonjour', 'en');
    });
    await show(tester, service, enabled: false);
    expect(calls, 0);
    expect(find.text('hello'), findsOneWidget);
    await show(tester, service);
    await tester.pumpAndSettle();
    expect(find.text('bonjour'), findsOneWidget);
    await tester.tap(find.text('Translated · Show original'));
    await tester.pump();
    expect(find.text('hello'), findsOneWidget);
    expect(calls, 1);
    service.dispose();
  });
  testWidgets('turning off before response keeps original', (tester) async {
    final pending = Completer<ChatTranslation>();
    final service = ChatTranslationService(translate: (a, b) => pending.future);
    await show(tester, service);
    await show(tester, service, enabled: false);
    pending.complete(const ChatTranslation('bonjour', 'en'));
    await tester.pumpAndSettle();
    expect(find.text('hello'), findsOneWidget);
    expect(find.text('bonjour'), findsNothing);
    service.dispose();
  });
  testWidgets('edited message cannot receive a stale translation',
      (tester) async {
    final pending = Completer<ChatTranslation>();
    final service = ChatTranslationService(
        translate: (a, b) => a == 'hello'
            ? pending.future
            : Future.value(const ChatTranslation('nouveau', 'en')));
    await show(tester, service);
    await show(tester, service, text: 'new');
    pending.complete(const ChatTranslation('bonjour', 'en'));
    await tester.pumpAndSettle();
    expect(find.text('nouveau'), findsOneWidget);
    expect(find.text('bonjour'), findsNothing);
    service.dispose();
  });
  testWidgets('unknown language leaves original without a translation action',
      (tester) async {
    final service = ChatTranslationService(
        translate: (_, __) async =>
            const ChatTranslation('guessed meaning', 'auto'));
    await show(tester, service, text: 'unrecognized name');
    await tester.pumpAndSettle();
    expect(find.text('unrecognized name'), findsOneWidget);
    expect(find.text('guessed meaning'), findsNothing);
    expect(find.byType(TextButton), findsNothing);
    service.dispose();
  });
  testWidgets('unchanged translation is not presented as translated',
      (tester) async {
    final service = ChatTranslationService(
        translate: (_, __) async => const ChatTranslation('hello', 'en'));
    await show(tester, service);
    await tester.pumpAndSettle();
    expect(find.text('hello'), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
    service.dispose();
  });
}
