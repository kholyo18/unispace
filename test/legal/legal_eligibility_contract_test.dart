import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/legal/legal_eligibility_client.dart';
import 'package:UniSpace/features/legal/legal_eligibility_models.dart';
import '../support/legal_eligibility_fixtures.dart';

void main() {
  for (final name in ['not_configured', 'birth_date_required', 'under_minimum_age',
    'personal_consent_required', 'independent_consent_required', 'representative_required', 'ready']) {
    test('parses V2 state $name; only ready grants the preview child', () {
      final result = LegalEligibilityStatus.fromMap(eligibilityResponse(name));
      expect(result.canProceed, name == 'ready');
    });
  }
  test('represented ready requires both decisions', () {
    final valid = eligibilityResponse('ready', phase: 'represented');
    expect(LegalEligibilityStatus.fromMap(valid).canProceed, isTrue);
    valid['representativeVerified'] = false;
    expect(() => LegalEligibilityStatus.fromMap(valid), throwsFormatException);
  });
  for (final entry in <String, Object?>{
    'schemaVersion': 1, 'rulesVersion': 'unknown', 'timeZone': 'UTC',
    'uid': '../other', 'state': 'approved', 'enabled': false,
    'canProceed': 'true', 'canAccept': false, 'userAccepted': false,
    'representativeVerified': true, 'phase': 'unknown', 'acceptanceContext': 'bad',
  }.entries) {
    test('rejects inconsistent ready field ${entry.key}', () {
      final data = eligibilityResponse('ready')..[entry.key] = entry.value;
      expect(() => LegalEligibilityStatus.fromMap(data), throwsFormatException);
    });
  }
  test('not configured is closed and cannot contain a ready flag', () {
    final data = eligibilityResponse('not_configured')..['canProceed'] = true;
    expect(() => LegalEligibilityStatus.fromMap(data), throwsFormatException);
  });
  test('date-required cannot claim personal acceptance', () {
    final data = eligibilityResponse('birth_date_required')..['userAccepted'] = true;
    expect(() => LegalEligibilityStatus.fromMap(data), throwsFormatException);
  });
  test('rejects corrupt document contents instead of displaying them for consent', () {
    final data = eligibilityResponse('independent_consent_required');
    (data['policy']['documents'] as List).first['body'] = 'changed';
    expect(() => LegalEligibilityStatus.fromMap(data), throwsFormatException);
  });
  test('hash with a trailing newline is not accepted', () {
    final data = eligibilityResponse('ready');
    data['acceptanceContext'] = '${data['acceptanceContext']}\n';
    expect(() => LegalEligibilityStatus.fromMap(data), throwsFormatException);
  });
  for (final example in <List<String>>[
    ['2004', '2', '29', '2004-02-29'],
    ['٢٠٠٤', '٠٢', '٢٩', '2004-02-29'],
    ['۲۰۰۴', '۲', '۲۹', '2004-02-29'],
    [' 2000 ', ' 1 ', ' 9 ', '2000-01-09'],
  ]) {
    test('normalizes calendar entry ${example.take(3).join('/')}', () {
      expect(legalBirthDateFromFields(year: example[0], month: example[1], day: example[2]), example[3]);
    });
  }
  for (final example in <List<String>>[
    ['1900', '2', '29'], ['2003', '2', '29'], ['2000', '13', '1'],
    ['2000', '0', '1'], ['2000', '1', '0'], ['2000', '4', '31'],
    ['1899', '1', '1'], ['00', '1', '1'], ['2e03', '1', '1'], ['2000', '1a', '1'],
  ]) {
    test('rejects invalid calendar entry ${example.join('/')}', () {
      expect(legalBirthDateFromFields(year: example[0], month: example[1], day: example[2]), isNull);
    });
  }
  test('calendar syntax does not use the phone clock to decide future date or age', () {
    expect(legalBirthDateFromFields(year: '9999', month: '1', day: '1'), '9999-01-01');
  });

  group('callable client contract', () {
    String? uid;
    late List<Map<String, dynamic>> calls;
    late Object? response;
    late CallableLegalEligibilityClient client;
    setUp(() {
      uid = 'test-alice'; calls = [];
      response = eligibilityResponse('birth_date_required');
      client = CallableLegalEligibilityClient(currentUserId: () => uid,
        userChanges: const Stream<String?>.empty(), signOut: () async { uid = null; },
        call: (name, payload) async { calls.add({'name': name, 'payload': payload}); return response; });
    });
    test('status sends an empty payload to V2 only', () async {
      await client.readStatus(uid!);
      expect(calls.single, {'name': 'readLegalEligibilityStatus', 'payload': <String, dynamic>{}});
    });
    test('birth declaration sends exactly the approved date and context', () async {
      final state = await client.readStatus(uid!);
      response = {'uid': uid, 'recorded': true, 'alreadyRecorded': false};
      await client.declareBirthDate(state, '2000-01-01', accuracyConfirmed: true);
      expect(calls.last, {'name': 'declareLegalBirthDate', 'payload': {
        'birthDate': '2000-01-01', 'declarationContext': state.declarationContext,
        'accuracyConfirmed': true}});
    });
    test('unconfirmed date is never transmitted', () async {
      final state = await client.readStatus(uid!);
      await expectLater(client.declareBirthDate(state, '2000-01-01', accuracyConfirmed: false),
        throwsA(isA<LegalEligibilityReloadRequired>()));
      expect(calls.length, 1);
    });
    test('malformed date is never transmitted', () async {
      final state = await client.readStatus(uid!);
      await expectLater(client.declareBirthDate(state, '2000-02-30', accuracyConfirmed: true),
        throwsA(isA<LegalBirthDateRejected>()));
      expect(calls.length, 1);
    });
    test('V2 acceptance does not expect a V1 fingerprint in its acknowledgment', () async {
      final state = LegalEligibilityStatus.fromMap(eligibilityResponse('independent_consent_required'));
      response = {'uid': uid, 'accepted': true, 'alreadyAccepted': false};
      await client.accept(state, termsAccepted: true, communityAccepted: true, privacyAcknowledged: true);
      expect(calls.single, {'name': 'acceptEligibleLegalDocuments', 'payload': {
        'fingerprint': state.policy!.fingerprint, 'acceptanceContext': state.acceptanceContext,
        'termsAccepted': true, 'communityAccepted': true, 'privacyAcknowledged': true}});
    });
    for (final missing in ['terms', 'community', 'privacy']) {
      test('requires explicit $missing choice before sending', () async {
        final state = LegalEligibilityStatus.fromMap(eligibilityResponse('independent_consent_required'));
        await expectLater(client.accept(state, termsAccepted: missing != 'terms',
          communityAccepted: missing != 'community', privacyAcknowledged: missing != 'privacy'),
          throwsA(isA<LegalEligibilityReloadRequired>()));
        expect(calls, isEmpty);
      });
    }
    test('a different response UID cannot be accepted', () async {
      response = eligibilityResponse('ready', uid: 'test-bob');
      await expectLater(client.readStatus('test-alice'), throwsA(isA<LegalEligibilityReloadRequired>()));
    });
    test('changed current account prevents any request for the displayed identity', () async {
      final state = await client.readStatus(uid!); uid = 'test-bob';
      await expectLater(client.declareBirthDate(state, '2000-01-01', accuracyConfirmed: true),
        throwsA(isA<LegalEligibilityReloadRequired>()));
      expect(calls.length, 1);
    });
    test('a response arriving after account switch is rejected', () async {
      final pending = Completer<Object?>();
      final lateClient = CallableLegalEligibilityClient(currentUserId: () => uid,
        userChanges: const Stream<String?>.empty(), signOut: () async {},
        call: (_, __) => pending.future);
      final result = lateClient.readStatus('test-alice');
      final assertion = expectLater(result, throwsA(isA<LegalEligibilityReloadRequired>()));
      uid = 'test-bob'; pending.complete(eligibilityResponse('ready'));
      await assertion;
    });
    test('malformed write acknowledgment cannot report completion', () async {
      final state = await client.readStatus(uid!); response = {'uid': uid, 'recorded': true};
      await expectLater(client.declareBirthDate(state, '2000-01-01', accuracyConfirmed: true), throwsFormatException);
    });
    test('decline invokes sign-out without sending any consent', () async {
      await client.signOut(); expect(uid, isNull); expect(calls, isEmpty);
    });
  });
}
