import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> syncOwnPostPrivacy(String uid) async {
  String? cursor;
  while (true) {
    if (FirebaseAuth.instance.currentUser?.uid != uid) throw StateError('Account changed');
    final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('syncOwnPostPrivacy').call({'cursor': cursor});
    if (FirebaseAuth.instance.currentUser?.uid != uid) throw StateError('Account changed');
    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['exhausted'] == true) return;
    final next = data['cursor'];
    if (data['exhausted'] != false || next is! String || next.isEmpty ||
        (cursor != null && next.compareTo(cursor) <= 0)) throw StateError('Invalid sync cursor');
    cursor = next;
  }
}

Future<void> syncOwnPostIdentity(String uid, String field) async {
  String? cursor;
  while (true) {
    if (FirebaseAuth.instance.currentUser?.uid != uid) throw StateError('Account changed');
    final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('syncOwnPostIdentity').call({'cursor': cursor, 'field': field});
    if (FirebaseAuth.instance.currentUser?.uid != uid) throw StateError('Account changed');
    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['exhausted'] == true) return;
    final next = data['cursor'];
    if (data['exhausted'] != false || next is! String || next.isEmpty ||
        (cursor != null && next.compareTo(cursor) <= 0)) throw StateError('Invalid sync cursor');
    cursor = next;
  }
}
