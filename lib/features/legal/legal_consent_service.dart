import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_session_service.dart';
import 'legal_consent_models.dart';

abstract class LegalConsentClient {
  String? get currentUserId;
  Stream<String?> get userChanges;
  Future<LegalConsentStatus> readStatus(String expectedUid);
  Future<void> accept(LegalConsentStatus displayed);
  Future<void> signOut();
}

class FirebaseLegalConsentClient implements LegalConsentClient {
  FirebaseLegalConsentClient({FirebaseAuth? auth, FirebaseFunctions? functions})
      : _auth = auth ?? FirebaseAuth.instance,
        _functions = functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;
  @override
  String? get currentUserId => _auth.currentUser?.uid;
  @override
  Stream<String?> get userChanges => _auth.authStateChanges().map((user) => user?.uid).distinct();

  void _sameUser(String uid) {
    if (currentUserId != uid) throw const LegalConsentReloadRequired();
  }

  @override
  Future<LegalConsentStatus> readStatus(String expectedUid) async {
    _sameUser(expectedUid);
    final response = await _functions.httpsCallable('readLegalConsentStatus').call(<String, dynamic>{});
    _sameUser(expectedUid);
    final state = LegalConsentStatus.fromMap(response.data);
    if (state.uid != expectedUid) throw const LegalConsentReloadRequired();
    return state;
  }

  @override
  Future<void> accept(LegalConsentStatus displayed) async {
    _sameUser(displayed.uid);
    if (!displayed.enabled || !displayed.required || displayed.policy == null || displayed.acceptanceContext == null) {
      throw const LegalConsentReloadRequired();
    }
    try {
      final response = await _functions.httpsCallable('acceptLegalDocuments').call(<String, dynamic>{
        'fingerprint': displayed.policy!.fingerprint,
        'acceptanceContext': displayed.acceptanceContext,
        'termsAccepted': true,
        'communityAccepted': true,
        'privacyAcknowledged': true,
      });
      _sameUser(displayed.uid);
      final data = response.data;
      if (data is! Map || data['uid'] != displayed.uid || data['accepted'] != true ||
          data['fingerprint'] != displayed.policy!.fingerprint || data['alreadyAccepted'] is! bool) {
        throw const FormatException('Invalid acceptance confirmation.');
      }
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'failed-precondition') throw const LegalConsentReloadRequired();
      rethrow;
    }
  }

  @override
  Future<void> signOut() => AuthSessionService.signOutFully();
}
