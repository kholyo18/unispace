import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'account_state_client.dart';
import 'public_profile_service.dart';

class AccountStateService {
  static final _client = AccountStateClient(
    currentUid: () => FirebaseAuth.instance.currentUser?.uid,
    sessionKey: () => PublicProfileService.viewerSession,
    invoke: (name, data) async {
      final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable(name)
          .call<Map<String, dynamic>>(data);
      return Map<String, dynamic>.from(result.data);
    },
  );

  static Future<void> change(String uid, String action) => _client.change(uid, action);

  static Future<void> requestDeletion(String uid) async {
    final session = PublicProfileService.viewerSession;
    await _client.requestDeletion(uid);
    if (FirebaseAuth.instance.currentUser?.uid == uid &&
        PublicProfileService.viewerSession == session) {
      // Invoke immediately after the session guard; no awaited work may
      // intervene and accidentally sign out a replacement login.
      await FirebaseAuth.instance.signOut();
    }
  }
}
