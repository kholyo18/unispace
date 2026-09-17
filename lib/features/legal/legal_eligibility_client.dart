import 'dart:async';
import 'legal_eligibility_models.dart';

typedef LegalEligibilityCall = Future<Object?> Function(
  String name, Map<String, dynamic> payload,
);

abstract class LegalEligibilityClient {
  String? get currentUserId;
  Stream<String?> get userChanges;
  Future<LegalEligibilityStatus> readStatus(String expectedUid);
  Future<void> declareBirthDate(LegalEligibilityStatus displayed, String date,
      {required bool accuracyConfirmed});
  Future<void> accept(LegalEligibilityStatus displayed, {
    required bool termsAccepted,
    required bool communityAccepted,
    required bool privacyAcknowledged,
  });
  Future<void> signOut();
}

/// A transport seam for exercising payload/identity checks without real Firebase.
/// Never stores a date or a consent decision in device preferences or profile data.
class CallableLegalEligibilityClient implements LegalEligibilityClient {
  CallableLegalEligibilityClient({
    required String? Function() currentUserId,
    required Stream<String?> userChanges,
    required LegalEligibilityCall call,
    required Future<void> Function() signOut,
  }) : _currentUserId = currentUserId, _userChanges = userChanges,
       _call = call, _signOut = signOut;

  final String? Function() _currentUserId;
  final Stream<String?> _userChanges;
  final LegalEligibilityCall _call;
  final Future<void> Function() _signOut;
  @override
  String? get currentUserId => _currentUserId();
  @override
  Stream<String?> get userChanges => _userChanges;

  void _sameUser(String uid) {
    if (currentUserId != uid) throw const LegalEligibilityReloadRequired();
  }

  @override
  Future<LegalEligibilityStatus> readStatus(String expectedUid) async {
    _sameUser(expectedUid);
    final raw = await _call('readLegalEligibilityStatus', <String, dynamic>{});
    _sameUser(expectedUid);
    final status = LegalEligibilityStatus.fromMap(raw);
    if (status.uid != expectedUid) throw const LegalEligibilityReloadRequired();
    return status;
  }

  @override
  Future<void> declareBirthDate(LegalEligibilityStatus displayed, String date,
      {required bool accuracyConfirmed}) async {
    _sameUser(displayed.uid);
    if (displayed.step != LegalEligibilityStep.birthDateRequired ||
        displayed.declarationContext == null || !accuracyConfirmed) {
      throw const LegalEligibilityReloadRequired();
    }
    final parts = date.split('-');
    if (parts.length != 3 || legalBirthDateFromFields(
        year: parts[0], month: parts[1], day: parts[2]) != date) {
      throw const LegalBirthDateRejected();
    }
    final raw = await _call('declareLegalBirthDate', <String, dynamic>{
      'birthDate': date,
      'declarationContext': displayed.declarationContext,
      'accuracyConfirmed': true,
    });
    _sameUser(displayed.uid);
    final result = legalEligibilityMap(raw);
    if (result['uid'] != displayed.uid || result['recorded'] != true ||
        result['alreadyRecorded'] is! bool) {
      throw const FormatException('Invalid birth declaration acknowledgment.');
    }
  }

  @override
  Future<void> accept(LegalEligibilityStatus displayed, {
    required bool termsAccepted,
    required bool communityAccepted,
    required bool privacyAcknowledged,
  }) async {
    _sameUser(displayed.uid);
    if (!displayed.needsPersonalAcceptance || displayed.policy == null ||
        displayed.acceptanceContext == null || !termsAccepted ||
        !communityAccepted || !privacyAcknowledged) {
      throw const LegalEligibilityReloadRequired();
    }
    final raw = await _call('acceptEligibleLegalDocuments', <String, dynamic>{
      'fingerprint': displayed.policy!.fingerprint,
      'acceptanceContext': displayed.acceptanceContext,
      'termsAccepted': true,
      'communityAccepted': true,
      'privacyAcknowledged': true,
    });
    _sameUser(displayed.uid);
    final result = legalEligibilityMap(raw);
    // V2 deliberately returns no fingerprint: do not apply the old V1 parser.
    if (result['uid'] != displayed.uid || result['accepted'] != true ||
        result['alreadyAccepted'] is! bool) {
      throw const FormatException('Invalid eligibility consent acknowledgment.');
    }
  }

  @override
  Future<void> signOut() => _signOut();
}
