import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/legal/legal_consent_gate.dart';
import 'package:UniSpace/features/legal/legal_consent_models.dart';
import 'package:UniSpace/features/legal/legal_consent_service.dart';
import 'package:UniSpace/ui/auth/auth_security_check.dart';

LegalConsentStatus state({String uid = 'alice', bool required = true, String version = '1'}) => LegalConsentStatus(
  uid: uid, enabled: true, required: required, acceptanceContext: List.filled(64, 'a').join(),
  policy: LegalPolicy(fingerprint: List.filled(64, version).join(), operatorName: 'جهة اختبار فقط',
    publishedAt: DateTime.utc(2026, 9, 15), documents: ['terms', 'community', 'privacy'].map((id) => LegalDocument(
      id: id, version: version, title: 'وثيقة $id', body: 'نص اختبار $id', contentHash: List.filled(64, 'b').join())).toList()));

class FakeClient implements LegalConsentClient {
  String? uid = 'alice';
  final changes = StreamController<String?>.broadcast(sync: true);
  late LegalConsentStatus status = state();
  Future<LegalConsentStatus> Function(String uid)? read;
  Future<void> Function(LegalConsentStatus displayed)? write;
  int reads = 0;
  int accepts = 0;
  int exits = 0;
  @override
  String? get currentUserId => uid;
  @override
  Stream<String?> get userChanges => changes.stream;
  @override
  Future<LegalConsentStatus> readStatus(String expectedUid) async {
    reads++;
    return read == null ? status : await read!(expectedUid);
  }
  @override
  Future<void> accept(LegalConsentStatus displayed) async {
    accepts++;
    if (write != null) return write!(displayed);
    status = state(uid: displayed.uid, required: false);
  }
  @override
  Future<void> signOut() async { exits++; switchUser(null); }
  void switchUser(String? value) { uid = value; changes.add(value); }
}

Finder key(String value) => find.byKey(ValueKey(value));
Future<void> mount(WidgetTester tester, FakeClient client, {double scale = 1}) async {
  addTearDown(client.changes.close);
  await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: LegalConsentGate(client: client, child: const Text('protected-child'))))));
  await tester.pump();
}
Future<void> tap(WidgetTester tester, String value) async {
  await tester.ensureVisible(key(value));
  await tester.tap(key(value));
  await tester.pump();
}
Future<void> selectAll(WidgetTester tester) async {
  for (final value in ['legal-terms', 'legal-community', 'legal-privacy']) { await tap(tester, value); }
}
void expectUnchecked(WidgetTester tester) {
  for (final value in ['legal-terms', 'legal-community', 'legal-privacy']) {
    expect(tester.widget<CheckboxListTile>(key(value)).value, false);
  }
}

void main() {
  testWidgets('all choices start unchecked; all three are required', (tester) async {
    final client = FakeClient(); await mount(tester, client); expectUnchecked(tester);
    expect(tester.widget<FilledButton>(key('legal-accept')).onPressed, isNull);
    await tap(tester, 'legal-terms'); await tap(tester, 'legal-community');
    expect(tester.widget<FilledButton>(key('legal-accept')).onPressed, isNull);
    await tap(tester, 'legal-privacy');
    expect(tester.widget<FilledButton>(key('legal-accept')).onPressed, isNotNull);
    expect(client.accepts, 0);
  });

  testWidgets('reading a document never checks or accepts it', (tester) async {
    final client = FakeClient(); await mount(tester, client); await tap(tester, 'legal-open-terms');
    expect(find.text('نص اختبار terms'), findsOneWidget);
    await tap(tester, 'legal-document-back'); expectUnchecked(tester); expect(client.accepts, 0);
  });

  testWidgets('acceptance opens content only after a fresh status read', (tester) async {
    final client = FakeClient(); await mount(tester, client); await selectAll(tester);
    await tap(tester, 'legal-accept'); await tester.pumpAndSettle();
    expect(client.accepts, 1); expect(client.reads, 2); expect(find.text('protected-child'), findsOneWidget);
  });

  testWidgets('successful write with still-required status never opens content', (tester) async {
    final client = FakeClient()..write = (_) async {};
    await mount(tester, client); await selectAll(tester); await tap(tester, 'legal-accept');
    await tester.pumpAndSettle(); expect(find.text('protected-child'), findsNothing); expectUnchecked(tester);
  });

  testWidgets('read failure blocks content but preserves retry and rights contact', (tester) async {
    final client = FakeClient()..read = (_) async => throw StateError('offline');
    await mount(tester, client); expect(find.text('protected-child'), findsNothing);
    expect(key('legal-retry'), findsOneWidget); expect(key('legal-support'), findsOneWidget);
    client.read = null; await tap(tester, 'legal-retry'); await tester.pumpAndSettle(); expectUnchecked(tester);
  });

  testWidgets('decline signs out without writing acceptance', (tester) async {
    final client = FakeClient(); await mount(tester, client); await tap(tester, 'legal-signout');
    expect(client.exits, 1); expect(client.accepts, 0); expect(find.text('protected-child'), findsNothing);
  });

  testWidgets('old response cannot unlock a different account', (tester) async {
    final pending = Completer<LegalConsentStatus>();
    final client = FakeClient()..read = (uid) => uid == 'alice' ? pending.future : Future.value(state(uid: uid));
    await mount(tester, client); client.switchUser('bob'); await tester.pump();
    pending.complete(state(required: false)); await tester.pumpAndSettle();
    expect(find.text('protected-child'), findsNothing); expectUnchecked(tester);
  });

  testWidgets('account switch closes an open document and clears selections', (tester) async {
    final client = FakeClient(); await mount(tester, client); await tap(tester, 'legal-terms');
    await tap(tester, 'legal-open-privacy'); client.status = state(uid: 'bob'); client.switchUser('bob');
    await tester.pumpAndSettle(); expect(find.text('نص اختبار privacy'), findsNothing); expectUnchecked(tester);
  });

  testWidgets('policy refresh after stale acceptance clears every choice', (tester) async {
    final client = FakeClient(); client.write = (_) async {
      client.status = state(version: '2'); throw const LegalConsentReloadRequired();
    };
    await mount(tester, client); await selectAll(tester); await tap(tester, 'legal-accept');
    await tester.pumpAndSettle(); expectUnchecked(tester); expect(find.text('protected-child'), findsNothing);
    expect(find.text('الإصدار: 2'), findsNWidgets(3));
  });

  testWidgets('malformed enabled state cannot grant access', (tester) async {
    final client = FakeClient()..status = const LegalConsentStatus(uid: 'alice', enabled: true, required: false);
    await mount(tester, client); expect(find.text('protected-child'), findsNothing); expect(key('legal-retry'), findsOneWidget);
  });

  testWidgets('server-disabled feature passes through without writing consent', (tester) async {
    final client = FakeClient()..status = const LegalConsentStatus(uid: 'alice', enabled: false, required: false);
    await mount(tester, client); expect(find.text('protected-child'), findsOneWidget); expect(client.accepts, 0);
  });

  testWidgets('narrow Arabic layout and large text remain scrollable', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await mount(tester, FakeClient(), scale: 2);
    expect(Directionality.of(tester.element(key('legal-terms'))), TextDirection.rtl);
    await tester.ensureVisible(key('legal-support')); await tester.pump(); expect(tester.takeException(), isNull);
  });

  testWidgets('default flag keeps the existing security gate Firebase-free', (tester) async {
    expect(legalConsentPreviewEnabled, false);
    await tester.pumpWidget(MaterialApp(home: AuthSecurityCheck(check: () async => false,
      challengeBuilder: (_) => const Text('challenge'), child: const Text('protected-child'))));
    await tester.pumpAndSettle(); expect(find.text('protected-child'), findsOneWidget);
  });
}
