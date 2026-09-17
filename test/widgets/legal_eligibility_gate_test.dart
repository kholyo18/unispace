import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/legal/legal_eligibility_client.dart';
import 'package:UniSpace/features/legal/legal_eligibility_gate.dart';
import 'package:UniSpace/features/legal/legal_eligibility_models.dart';
import 'package:UniSpace/ui/auth/auth_security_check.dart';
import '../support/legal_eligibility_fixtures.dart';

LegalEligibilityStatus response(String name, {String uid = 'test-alice', String version = 'test-1'}) =>
    LegalEligibilityStatus.fromMap(eligibilityResponse(name, uid: uid, version: version));

class FakeEligibilityClient implements LegalEligibilityClient {
  String? uid = 'test-alice';
  final changes = StreamController<String?>.broadcast(sync: true);
  LegalEligibilityStatus status = response('birth_date_required');
  Future<LegalEligibilityStatus> Function(String uid)? read;
  Future<void> Function()? writeBirth;
  Future<void> Function()? writeConsent;
  Future<void> Function()? exit;
  String? receivedDate;
  int readCount = 0;
  int birthCount = 0;
  int consentCount = 0;
  @override
  String? get currentUserId => uid;
  @override
  Stream<String?> get userChanges => changes.stream;
  @override
  Future<LegalEligibilityStatus> readStatus(String expectedUid) async {
    readCount++;
    return read == null ? status : await read!(expectedUid);
  }
  @override
  Future<void> declareBirthDate(LegalEligibilityStatus displayed, String date,
      {required bool accuracyConfirmed}) async {
    expect(accuracyConfirmed, true);
    receivedDate = date; birthCount++;
    if (writeBirth != null) { await writeBirth!(); return; }
    status = response('independent_consent_required', uid: uid!);
  }
  @override
  Future<void> accept(LegalEligibilityStatus displayed, {
    required bool termsAccepted, required bool communityAccepted, required bool privacyAcknowledged,
  }) async {
    expect([termsAccepted, communityAccepted, privacyAcknowledged], [true, true, true]);
    consentCount++;
    if (writeConsent != null) { await writeConsent!(); return; }
    status = response(displayed.phase == 'represented' ? 'representative_required' : 'ready', uid: uid!);
  }
  @override
  Future<void> signOut() async {
    if (exit != null) { await exit!(); return; }
    changeUser(null);
  }
  void changeUser(String? value) { uid = value; changes.add(value); }
}

Finder k(String id) => find.byKey(ValueKey('eligibility-$id'));
Future<void> tapKey(WidgetTester tester, String id) async {
  await tester.ensureVisible(k(id)); await tester.pump();
  await tester.tap(k(id)); await tester.pump();
}
Future<void> mount(WidgetTester tester, FakeEligibilityClient client, {double scale = 1}) async {
  addTearDown(client.changes.close);
  await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: LegalEligibilityGate(client: client, timeout: const Duration(seconds: 1),
      child: const Text('protected-eligibility-child'))))));
  await tester.pump();
}
Future<void> date(WidgetTester tester, {String year = '٢٠٠٠', String month = '١', String day = '٢'}) async {
  for (final entry in {'day': day, 'month': month, 'year': year}.entries) {
    await tester.ensureVisible(k(entry.key)); await tester.enterText(k(entry.key), entry.value);
  }
  await tester.pump();
}
Future<void> acceptAll(WidgetTester tester) async {
  for (final id in ['terms', 'community', 'privacy']) { await tapKey(tester, id); }
}
void expectUnchecked(WidgetTester tester) {
  for (final id in ['terms', 'community', 'privacy']) {
    expect(tester.widget<CheckboxListTile>(k(id)).value, false);
  }
}

void main() {
  testWidgets('birth date starts empty and needs explicit accuracy confirmation', (tester) async {
    final client = FakeEligibilityClient(); await mount(tester, client);
    expect(tester.widget<TextField>(k('year')).controller!.text, isEmpty);
    expect(tester.widget<CheckboxListTile>(k('accuracy')).value, false);
    expect(tester.widget<FilledButton>(k('save-date')).onPressed, isNull);
    await date(tester); await tapKey(tester, 'accuracy');
    await tapKey(tester, 'save-date'); await tester.pumpAndSettle();
    expect(client.receivedDate, '2000-01-02'); expect(client.birthCount, 1);
    expect(client.readCount, 2); expectUnchecked(tester);
    expect(find.text('protected-eligibility-child'), findsNothing);
  });
  testWidgets('editing a date clears its accuracy confirmation', (tester) async {
    await mount(tester, FakeEligibilityClient()); await date(tester); await tapKey(tester, 'accuracy');
    await tester.ensureVisible(k('day')); await tester.enterText(k('day'), '3'); await tester.pump();
    expect(tester.widget<CheckboxListTile>(k('accuracy')).value, false);
  });
  testWidgets('invalid calendar dates never reach the server', (tester) async {
    final client = FakeEligibilityClient(); await mount(tester, client);
    await date(tester, year: '2003', month: '2', day: '29'); await tapKey(tester, 'accuracy');
    await tapKey(tester, 'save-date'); expect(client.birthCount, 0); expect(k('error'), findsOneWidget);
  });
  testWidgets('under-minimum response blocks even when entered date looks adult locally', (tester) async {
    final client = FakeEligibilityClient();
    client.writeBirth = () async { client.status = response('under_minimum_age'); };
    await mount(tester, client); await date(tester); await tapKey(tester, 'accuracy');
    await tapKey(tester, 'save-date'); await tester.pumpAndSettle();
    expect(k('step-underMinimumAge'), findsOneWidget); expect(k('accept'), findsNothing);
    expect(k('year'), findsNothing); expect(k('support'), findsOneWidget);
    expect(find.text('protected-eligibility-child'), findsNothing);
  });
  testWidgets('reading a document does not accept it or discard typed date', (tester) async {
    final client = FakeEligibilityClient(); await mount(tester, client); await date(tester);
    await tapKey(tester, 'open-terms'); expect(find.text('نص اختبار فقط terms test-1'), findsOneWidget);
    await tapKey(tester, 'document-back');
    expect(tester.widget<TextField>(k('year')).controller!.text, '٢٠٠٠');
    expect(client.birthCount, 0); expect(client.consentCount, 0);
  });
  testWidgets('represented personal acceptance leads to waiting, never automatic approval', (tester) async {
    final client = FakeEligibilityClient()..status = response('personal_consent_required');
    await mount(tester, client); expectUnchecked(tester); await acceptAll(tester);
    await tapKey(tester, 'accept'); await tester.pumpAndSettle();
    expect(k('step-representativeRequired'), findsOneWidget); expect(k('accept'), findsNothing);
    expect(find.text('protected-eligibility-child'), findsNothing);
    expect(client.consentCount, 1); expect(client.readCount, 2);
  });
  testWidgets('independent acceptance needs every choice and a ready reread', (tester) async {
    final client = FakeEligibilityClient()..status = response('independent_consent_required');
    await mount(tester, client); expectUnchecked(tester);
    await tapKey(tester, 'terms'); await tapKey(tester, 'community');
    expect(tester.widget<FilledButton>(k('accept')).onPressed, isNull);
    await tapKey(tester, 'privacy'); await tapKey(tester, 'accept'); await tester.pumpAndSettle();
    expect(find.text('protected-eligibility-child'), findsOneWidget); expect(client.readCount, 2);
  });
  testWidgets('write acknowledgment alone cannot open content', (tester) async {
    final client = FakeEligibilityClient()..status = response('independent_consent_required')
      ..writeConsent = () async {};
    await mount(tester, client); await acceptAll(tester); await tapKey(tester, 'accept');
    await tester.pumpAndSettle(); expectUnchecked(tester);
    expect(find.text('protected-eligibility-child'), findsNothing);
  });
  testWidgets('not-configured response never falls back to V1 or opens content', (tester) async {
    final client = FakeEligibilityClient()..status = response('not_configured');
    await mount(tester, client); expect(k('step-notConfigured'), findsOneWidget);
    expect(k('accept'), findsNothing); expect(find.text('protected-eligibility-child'), findsNothing);
  });
  testWidgets('read failure keeps support, retry and decline available', (tester) async {
    final client = FakeEligibilityClient()..read = (_) async => throw StateError('offline');
    await mount(tester, client); expect(k('error'), findsOneWidget); expect(k('support'), findsOneWidget);
    expect(k('signout'), findsOneWidget); expect(find.text('protected-eligibility-child'), findsNothing);
    client.read = null; await tapKey(tester, 'refresh'); await tester.pumpAndSettle();
    expect(k('year'), findsOneWidget);
  });
  testWidgets('late response from account A cannot open account B', (tester) async {
    final pending = Completer<LegalEligibilityStatus>();
    final client = FakeEligibilityClient()..read = (uid) => uid == 'test-alice'
      ? pending.future : Future.value(response('birth_date_required', uid: uid));
    await mount(tester, client); client.changeUser('test-bob'); await tester.pump();
    pending.complete(response('ready')); await tester.pumpAndSettle();
    expect(find.text('protected-eligibility-child'), findsNothing); expect(k('year'), findsOneWidget);
  });
  testWidgets('account switch clears birth text and closes document reader', (tester) async {
    final client = FakeEligibilityClient(); await mount(tester, client); await date(tester);
    await tapKey(tester, 'open-privacy'); client.status = response('birth_date_required', uid: 'test-bob');
    client.changeUser('test-bob'); await tester.pumpAndSettle();
    expect(find.text('نص اختبار فقط privacy test-1'), findsNothing);
    expect(tester.widget<TextField>(k('year')).controller!.text, isEmpty);
  });
  testWidgets('stale-policy failure blocks until fresh reload and clears decisions', (tester) async {
    final client = FakeEligibilityClient()..status = response('independent_consent_required');
    client.writeConsent = () async {
      client.status = response('independent_consent_required', version: 'test-2');
      throw const LegalEligibilityReloadRequired();
    };
    await mount(tester, client); await acceptAll(tester); await tapKey(tester, 'accept');
    await tester.pumpAndSettle(); expect(k('accept'), findsNothing);
    await tapKey(tester, 'refresh'); await tester.pumpAndSettle(); expectUnchecked(tester);
    expect(find.text('الإصدار: test-2'), findsNWidgets(3));
  });
  testWidgets('timed-out date write hides editable fields until a status refresh', (tester) async {
    final pending = Completer<void>(); final client = FakeEligibilityClient()..writeBirth = () => pending.future;
    await mount(tester, client); await date(tester); await tapKey(tester, 'accuracy');
    await tapKey(tester, 'save-date'); await tester.pump(const Duration(seconds: 2));
    expect(k('year'), findsNothing); expect(k('error'), findsOneWidget);
    pending.complete(); await tester.pump(); expect(find.text('protected-eligibility-child'), findsNothing);
    client.status = response('independent_consent_required'); await tapKey(tester, 'refresh');
    await tester.pumpAndSettle(); expectUnchecked(tester); expect(client.birthCount, 1);
  });
  testWidgets('refusing signs out without transmitting acceptance', (tester) async {
    final client = FakeEligibilityClient()..status = response('personal_consent_required');
    await mount(tester, client); await tapKey(tester, 'signout'); await tester.pumpAndSettle();
    expect(client.uid, isNull); expect(client.consentCount, 0);
    expect(find.text('protected-eligibility-child'), findsNothing);
  });
  testWidgets('failed sign-out does not reopen content', (tester) async {
    final client = FakeEligibilityClient()..status = response('representative_required')..exit = () async {};
    await mount(tester, client); await tapKey(tester, 'signout'); await tester.pumpAndSettle();
    expect(k('error'), findsOneWidget); expect(find.text('protected-eligibility-child'), findsNothing);
  });
  testWidgets('resume rechecks independent consent rather than keeping an old ready result', (tester) async {
    final client = FakeEligibilityClient()..status = response('ready');
    await mount(tester, client); expect(find.text('protected-eligibility-child'), findsOneWidget);
    // Follow Flutter's actual lifecycle graph, not a paused -> resumed shortcut.
    for (final state in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();
    expect(find.text('protected-eligibility-child'), findsNothing);
    client.status = response('independent_consent_required');
    for (final state in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
    expect(find.text('protected-eligibility-child'), findsNothing); expectUnchecked(tester);
  });
  testWidgets('narrow RTL and large text remain scrollable without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await mount(tester, FakeEligibilityClient(), scale: 2.5);
    expect(Directionality.of(tester.element(k('accuracy'))), TextDirection.rtl);
    await tester.ensureVisible(k('support')); await tester.pump(); expect(tester.takeException(), isNull);
  });
  testWidgets('disposing during a status read cannot setState later', (tester) async {
    final pending = Completer<LegalEligibilityStatus>(); final client = FakeEligibilityClient()..read = (_) => pending.future;
    await mount(tester, client); await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(response('ready')); await tester.pump(); expect(tester.takeException(), isNull);
  });
  testWidgets('default build preserves existing security check and requires no Firebase initialization', (tester) async {
    expect(legalEligibilityPreviewEnabled, false);
    await tester.pumpWidget(MaterialApp(home: AuthSecurityCheck(check: () async => false,
      challengeBuilder: (_) => const Text('challenge'), child: const Text('existing-home'))));
    await tester.pumpAndSettle(); expect(find.text('existing-home'), findsOneWidget);
  });
}
