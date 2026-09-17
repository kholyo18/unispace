import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_session_service.dart';
import 'legal_eligibility_client.dart';
import 'legal_eligibility_models.dart';

/// Uses only the three V2 callables. No client Firestore writes or V1 fallback.
class FirebaseLegalEligibilityClient extends CallableLegalEligibilityClient {
  factory FirebaseLegalEligibilityClient({
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  }) {
    final identity = auth ?? FirebaseAuth.instance;
    final server = functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');
    return FirebaseLegalEligibilityClient._(identity, server);
  }

  FirebaseLegalEligibilityClient._(FirebaseAuth auth, FirebaseFunctions functions)
      : super(
          currentUserId: () => auth.currentUser?.uid,
          userChanges: auth.authStateChanges().map((user) => user?.uid).distinct(),
          signOut: AuthSessionService.signOutFully,
          call: (name, payload) async {
            try {
              return (await functions.httpsCallable(name).call(payload)).data;
            } on FirebaseFunctionsException catch (error) {
              if (error.code == 'failed-precondition') {
                throw const LegalEligibilityReloadRequired();
              }
              if (name == 'declareLegalBirthDate' && error.code == 'invalid-argument') {
                throw const LegalBirthDateRejected();
              }
              rethrow;
            }
          },
        );
}
