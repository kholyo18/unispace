import 'package:cloud_functions/cloud_functions.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/config/app_links.dart';
import 'package:UniSpace/services/release_policy.dart';
import 'package:UniSpace/widgets/required_update_gate.dart';

void main() {
  Future<void> mount(
    WidgetTester tester, {
    required Future<ReleasePolicy> Function() policy,
    int build = 2,
    String language = 'en',
    Future<bool> Function()? open,
  }) async {
    await tester.pumpWidget(MaterialApp(
      locale: Locale(language),
      supportedLocales: const [Locale('en'), Locale('ar'), Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: RequiredUpdateGate(
          readPolicy: policy,
          readBuild: () async => build,
          openStore: open ?? () async => true,
          child: const Scaffold(body: Text('Application'))),
    ));
    await tester.pumpAndSettle();
  }

  test('release policy rejects malformed values and foreign store URL', () {
    final valid = {
      'enabled': true,
      'minimumBuild': 2,
      'storeUrl': AppLinks.storeUrl
    };
    expect(ReleasePolicy.fromMap(valid).allows(2), isTrue);
    expect(ReleasePolicy.fromMap(valid).allows(1), isFalse);
    for (final override in [
      <String, Object>{'enabled': 'false'},
      {'minimumBuild': 0},
      {'minimumBuild': '2'},
      {'storeUrl': 'https://example.com'}
    ]) {
      expect(() => ReleasePolicy.fromMap({...valid, ...override}),
          throwsFormatException);
    }
  });

  testWidgets('disabled policy and current build display application',
      (tester) async {
    await mount(tester,
        policy: () async =>
            const ReleasePolicy(enabled: false, minimumBuild: 99));
    expect(find.text('Application'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await mount(tester,
        policy: () async =>
            const ReleasePolicy(enabled: true, minimumBuild: 2));
    expect(find.text('Application'), findsOneWidget);
  });

  for (final locale in ['en', 'ar', 'fr']) {
    testWidgets('old build blocks application and opens store in $locale',
        (tester) async {
      var opened = 0;
      await mount(tester,
          language: locale,
          build: 1,
          policy: () async =>
              const ReleasePolicy(enabled: true, minimumBuild: 2),
          open: () async {
            opened++;
            return true;
          });
      expect(find.text('Application'), findsNothing);
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(opened, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('unknown offline policy blocks until successful retry',
      (tester) async {
    var fail = true;
    await mount(tester, policy: () async {
      if (fail) throw StateError('offline');
      return const ReleasePolicy(enabled: false, minimumBuild: 1);
    });
    expect(find.text('Application'), findsNothing);
    expect(find.text('Unable to check for updates'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Application'), findsOneWidget);
  });

  testWidgets(
      'resume refresh retains permitted child during fetch then blocks newly outdated build',
      (tester) async {
    var calls = 0;
    final refresh = Completer<ReleasePolicy>();
    await mount(tester, policy: () {
      calls++;
      return calls == 1
          ? Future.value(const ReleasePolicy(enabled: false, minimumBuild: 1))
          : refresh.future;
    });
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('Application'), findsOneWidget);
    refresh.complete(const ReleasePolicy(enabled: true, minimumBuild: 3));
    await tester.pumpAndSettle();
    expect(find.text('Application'), findsNothing);
    expect(find.text('Update UniSpace to continue'), findsOneWidget);
  });

  testWidgets('store launch failure keeps gate and displays retry information',
      (tester) async {
    await mount(tester,
        build: 1,
        policy: () async => const ReleasePolicy(enabled: true, minimumBuild: 2),
        open: () async => false);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('Application'), findsNothing);
    expect(find.text('Could not open Google Play. Please try again.'),
        findsOneWidget);
  });
  testWidgets('missing endpoint reports configuration failure, never no connection', (tester) async {
    await mount(tester, policy: () async => throw FirebaseFunctionsException(code: 'not-found', message: 'missing'));
    expect(find.text('The update service is not configured correctly. Please try again later.'), findsOneWidget);
    expect(find.text('Application'), findsNothing);
    expect(find.text('Check your connection and try again.'), findsNothing);
  });

  testWidgets('hung service times out in ten seconds and late result cannot override retry', (tester) async {
    final pending = Completer<ReleasePolicy>();
    var calls = 0;
    await tester.pumpWidget(MaterialApp(home: RequiredUpdateGate(
      readPolicy: () => ++calls == 1 ? pending.future : Future.value(const ReleasePolicy(enabled: true, minimumBuild: 5)),
      readBuild: () async => 2,
      child: const Text('Application'))));
    await tester.pump(const Duration(seconds: 11)); await tester.pumpAndSettle();
    expect(find.text('The update service did not respond. Please try again.'), findsOneWidget);
    await tester.tap(find.text('Retry')); await tester.pumpAndSettle();
    expect(find.text('Update UniSpace to continue'), findsOneWidget);
    pending.complete(const ReleasePolicy(enabled: false, minimumBuild: 1));
    await tester.pumpAndSettle();
    expect(find.text('Application'), findsNothing);
    expect(find.text('Update UniSpace to continue'), findsOneWidget);
  });

}
