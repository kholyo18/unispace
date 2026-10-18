import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/shell/chat/new_conversation_page.dart';
import 'package:UniSpace/l10n/chat_compose_strings.dart';

void main() {
  testWidgets(
      'debounce searches only latest query; preserves email punctuation',
      (tester) async {
    final calls = <String>[];
    final controller = ChatContactSearchController(
        currentUserId: () => 'me',
        search: (query) async {
          calls.add(query);
          return const ChatContactSearchResult([]);
        });
    controller.updateQuery('a');
    await tester.pump(const Duration(milliseconds: 200));
    controller.updateQuery(' alice.name@example.com ');
    await tester.pump(const Duration(milliseconds: 450));
    expect(calls, ['alice.name@example.com']);
    expect(controller.loading, false);
    expect(controller.searched, true);
    controller.updateQuery(' @  ');
    await tester.pump(const Duration(milliseconds: 500));
    expect(calls.length, 1);
    expect(controller.loading, false);
    controller.dispose();
  });

  testWidgets('late prior-query results cannot replace latest contacts',
      (tester) async {
    final requests = <String, Completer<ChatContactSearchResult>>{};
    final controller = ChatContactSearchController(
        currentUserId: () => 'me',
        search: (query) => (requests[query] = Completer()).future);
    controller.updateQuery('old');
    await tester.pump(const Duration(milliseconds: 450));
    controller.updateQuery('new');
    await tester.pump(const Duration(milliseconds: 450));
    requests['new']!.complete(const ChatContactSearchResult([
      ChatContact(id: 'new', name: 'New person'),
      ChatContact(id: 'me', name: 'Self'),
      ChatContact(id: 'new', name: 'Duplicate')
    ], truncated: true));
    await tester.pump();
    requests['old']!.complete(
        const ChatContactSearchResult([ChatContact(id: 'old', name: 'Old')]));
    await tester.pump();
    expect(controller.people.map((p) => p.id), ['new']);
    expect(controller.truncated, true);
    controller.dispose();
  });

  testWidgets(
      'account change clears people and blocks stale completion and selection',
      (tester) async {
    String? owner = 'alice';
    final result = Completer<ChatContactSearchResult>();
    final controller = ChatContactSearchController(
        currentUserId: () => owner, search: (_) => result.future);
    controller.updateQuery('bob');
    await tester.pump(const Duration(milliseconds: 450));
    owner = null;
    controller.accountChanged();
    result.complete(
        const ChatContactSearchResult([ChatContact(id: 'bob', name: 'Bob')]));
    await tester.pump();
    expect(controller.people, isEmpty);
    expect(controller.errorKey, 'unauthenticated');
    expect(
        controller.canSelect(const ChatContact(id: 'bob', name: 'Bob')), false);
    controller.dispose();
  });

  testWidgets(
      'quota error and retry show explicit state without retaining stale results',
      (tester) async {
    var fail = true;
    final controller = ChatContactSearchController(
        currentUserId: () => 'me',
        search: (_) async {
          if (fail) {
            throw FirebaseFunctionsException(
                code: 'resource-exhausted', message: 'wait');
          }
          return const ChatContactSearchResult([]);
        });
    controller.updateQuery('Alice');
    await tester.pump(const Duration(milliseconds: 450));
    expect(controller.errorKey, 'limited');
    expect(controller.loading, false);
    fail = false;
    controller.updateQuery('Alice');
    await tester.pump(const Duration(milliseconds: 450));
    expect(controller.errorKey, null);
    expect(controller.searched, true);
    controller.dispose();
  });

  testWidgets(
      'picker returns selected typed contact and all three locales render',
      (tester) async {
    for (final locale in ['ar', 'en', 'fr']) {
      final controller = ChatContactSearchController(
          currentUserId: () => 'me',
          search: (_) async => const ChatContactSearchResult(
              [ChatContact(id: 'alice', name: 'Alice', username: 'alice')]));
      ChatContact? chosen;
      await tester.pumpWidget(MaterialApp(
          locale: Locale(locale),
          supportedLocales: const [Locale('ar'), Locale('en'), Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Builder(
              builder: (context) => TextButton(
                  onPressed: () async {
                    chosen = await Navigator.of(context).push<ChatContact>(
                        MaterialPageRoute(
                            builder: (_) =>
                                NewConversationPage(controller: controller)));
                  },
                  child: const Text('open')))));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(
          find.text(chatComposeTextForLocale(locale, 'title')), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'ali');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump();
      expect(find.text('@alice'), findsOneWidget);
      await tester.tap(find.text('Alice'));
      await tester.pumpAndSettle();
      expect(chosen?.id, 'alice');
      controller.dispose();
      await tester.pumpWidget(const SizedBox());
    }
  });
}
