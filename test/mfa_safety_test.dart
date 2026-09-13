import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/ui/auth/auth_security_check.dart';
import 'package:UniSpace/ui/settings/private_totp_qr.dart';
import 'package:UniSpace/ui/settings/security_checklist.dart';

Widget gate(Future<bool> Function() check, {Duration timeout = const Duration(seconds: 10), Key? key}) => MaterialApp(
  home: AuthSecurityCheck(key: key, check: check, timeout: timeout,
    challengeBuilder: (_) => const Text('challenge'), child: const Text('protected')),
);

class NoNetwork extends HttpOverrides {
  int calls = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    calls++;
    throw StateError('A TOTP secret must never be sent to an image service');
  }
}

void main() {
  testWidgets('pending security checks do not expose protected content', (tester) async {
    final pending = Completer<bool>();
    await tester.pumpWidget(gate(() => pending.future));
    expect(find.text('protected'), findsNothing);
    pending.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('challenge'), findsOneWidget);
    expect(find.text('protected'), findsNothing);
  });
  testWidgets('confirmed lack of an extra requirement allows access', (tester) async {
    await tester.pumpWidget(gate(() async => false));
    await tester.pumpAndSettle();
    expect(find.text('protected'), findsOneWidget);
  });
  testWidgets('failure blocks access and offers a retry', (tester) async {
    var calls = 0;
    await tester.pumpWidget(gate(() async {
      if (++calls == 1) throw StateError('offline');
      return true;
    }));
    await tester.pumpAndSettle();
    expect(find.text('protected'), findsNothing);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('challenge'), findsOneWidget);
    expect(calls, 2);
  });
  testWidgets('timeout does not bypass authentication even if the old request finishes', (tester) async {
    final pending = Completer<bool>();
    await tester.pumpWidget(gate(() => pending.future, timeout: const Duration(seconds: 1)));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    pending.complete(false);
    await tester.pumpAndSettle();
    expect(find.text('protected'), findsNothing);
  });
  testWidgets('an old account check cannot grant access after switching accounts', (tester) async {
    final pending = Completer<bool>();
    await tester.pumpWidget(gate(() => pending.future, key: const ValueKey('first')));
    await tester.pumpWidget(gate(() async => true, key: const ValueKey('second')));
    pending.complete(false);
    await tester.pumpAndSettle();
    expect(find.text('challenge'), findsOneWidget);
    expect(find.text('protected'), findsNothing);
  });
  testWidgets('TOTP QR renders without any HTTP request', (tester) async {
    final original = HttpOverrides.current;
    final guard = NoNetwork();
    HttpOverrides.global = guard;
    addTearDown(() => HttpOverrides.global = original);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Center(child:
      PrivateTotpQr(data: 'otpauth://totp/UniSpace:test?secret=JBSWY3DPEHPK3PXP&issuer=UniSpace'),
    ))));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(guard.calls, 0);
    expect(find.byType(Image), findsNothing);
  });
  test('MFA is necessary for a complete security checklist', () {
    const before = SecurityChecklist(hasEmail: true, emailVerified: true, hasPhone: true,
      loginAlerts: true, twoFactor: false);
    const after = SecurityChecklist(hasEmail: true, emailVerified: true, hasPhone: true,
      loginAlerts: true, twoFactor: true);
    expect(before.completed, 4);
    expect(after.completed, SecurityChecklist.total);
  });
  test('a missing email cannot count as verified', () {
    const value = SecurityChecklist(hasEmail: false, emailVerified: true, hasPhone: false,
      loginAlerts: false, twoFactor: false);
    expect(value.completed, 0);
  });
}
