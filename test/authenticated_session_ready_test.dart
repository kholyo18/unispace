import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/generated/l10n.dart';
import 'package:UniSpace/main.dart' show AuthenticatedSessionReady;

void main() {
  Widget gate(String session, Future<void> Function() initialize,
          {Widget child = const Text('Protected route')}) =>
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en')],
        localizationsDelegates: const [
          S.delegate,
          ...GlobalMaterialLocalizations.delegates
        ],
        home: AuthenticatedSessionReady(
            sessionKey: session, initialize: initialize, child: child),
      );

  testWidgets('protected route is not mounted before session metadata commits',
      (tester) async {
    final ready = Completer<void>();
    var mounted = 0;
    await tester.pumpWidget(
        gate('user:sid', () => ready.future, child: Builder(builder: (_) {
      mounted++;
      return const Text('Protected route');
    })));
    await tester.pump();
    expect(mounted, 0);
    expect(find.text('Protected route'), findsNothing);
    ready.complete();
    await tester.pumpAndSettle();
    expect(mounted, 1);
    expect(find.text('Protected route'), findsOneWidget);
  });

  testWidgets(
      'network failure stays gated and retry succeeds without replacing identity',
      (tester) async {
    var attempts = 0;
    await tester.pumpWidget(gate('user:sid', () async {
      attempts++;
      if (attempts == 1) throw StateError('offline');
    }));
    await tester.pumpAndSettle();
    expect(find.text('Protected route'), findsNothing);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('Protected route'), findsOneWidget);
  });

  testWidgets(
      'ordinary rebuild reuses readiness and changed signed session waits again',
      (tester) async {
    var attempts = 0;
    Future<void> initialize() async {
      attempts++;
    }

    await tester.pumpWidget(gate('user:sid:0', initialize));
    await tester.pumpAndSettle();
    await tester.pumpWidget(gate('user:sid:0', initialize));
    await tester.pumpAndSettle();
    expect(attempts, 1);
    final replacement = Completer<void>();
    await tester.pumpWidget(gate('user:new-sid:0', () {
      attempts++;
      return replacement.future;
    }));
    await tester.pump();
    expect(find.text('Protected route'), findsNothing);
    replacement.complete();
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('Protected route'), findsOneWidget);
  });

  testWidgets(
      'completion from previous account cannot expose the new account route',
      (tester) async {
    final previous = Completer<void>(), current = Completer<void>();
    await tester.pumpWidget(gate('first:sid', () => previous.future));
    await tester.pumpWidget(gate('second:sid', () => current.future));
    previous.complete();
    await tester.pump();
    expect(find.text('Protected route'), findsNothing);
    current.complete();
    await tester.pumpAndSettle();
    expect(find.text('Protected route'), findsOneWidget);
  });

  testWidgets('timeout offers retry and late completion cannot expose routes',
      (tester) async {
    final stalled = Completer<void>();
    await tester.pumpWidget(gate('user:sid', () => stalled.future));
    await tester.pump(const Duration(seconds: 31));
    await tester.pump();
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.text('Protected route'), findsNothing);
    stalled.complete();
    await tester.pumpAndSettle();
    expect(find.text('Protected route'), findsNothing);
  });
}
