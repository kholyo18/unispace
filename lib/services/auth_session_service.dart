import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthSessionService {
  AuthSessionService._();

  static Future<void> signOutFully({Future<void> Function()? beforeSignOut}) async {
    if (beforeSignOut != null) {
      await beforeSignOut();
    }

    await FirebaseAuth.instance.signOut();

    final google = GoogleSignIn();
    try {
      await google.signOut();
      await google.disconnect();
    } catch (error, stackTrace) {
      debugPrint('[Auth] Google disconnect skipped: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
