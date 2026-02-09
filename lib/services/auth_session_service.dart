import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthSessionService {
  AuthSessionService._();

  static final GoogleSignIn googleSignIn = GoogleSignIn();

  static Future<void> signOutFully({Future<void> Function()? beforeSignOut}) async {
    if (kDebugMode) {
      debugPrint('[AuthSessionService] signOutFully started');
    }
    if (beforeSignOut != null) {
      await beforeSignOut();
    }

    await FirebaseAuth.instance.signOut();

    try {
      await googleSignIn.signOut();
      await googleSignIn.disconnect();
    } catch (error, stackTrace) {
      debugPrint('[Auth] Google disconnect skipped: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    if (kDebugMode) {
      debugPrint('[AuthSessionService] signOutFully finished');
    }
  }
}
