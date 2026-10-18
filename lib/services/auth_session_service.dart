import 'chat_download_coordinator.dart';
import '../features/shell/chat/chat_transfer_center.dart';
import 'chat_local_persistence.dart';
import 'chat_media_policy.dart';
import 'chat_audio_coordinator.dart';
import 'chat_message_service.dart';
import '../ui/settings/push_preferences_service.dart';
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

    await chatDownloads.clear();
    chatTransfers.clear();
    ChatOutboxStore.clear();
    ChatDraftStore.clear();
    chatImageMemoryCache.clear();
    await chatAudioCoordinator.stop();
    await ChatLocalPersistence.purgeActive();
    await PushPreferencesService.instance.prepareSignOut();
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      PushPreferencesService.instance.cancelSignOut();
      rethrow;
    }

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
