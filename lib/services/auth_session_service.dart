import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'sign_out_pipeline.dart';
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

  static Future<void>? _pendingSignOut;
  static Future<void> signOutFully({Future<void> Function()? beforeSignOut}) {
    return _pendingSignOut ??= _performSignOut(beforeSignOut: beforeSignOut)
        .whenComplete(() => _pendingSignOut = null);
  }

  static Future<void> _performSignOut(
      {Future<void> Function()? beforeSignOut}) async {
    if (kDebugMode) {
      debugPrint('[AuthSessionService] signOutFully started');
    }
    await runSignOutPipeline(
      cleanup: {
        if (beforeSignOut != null) 'beforeSignOut': beforeSignOut,
        'downloads': chatDownloads.clear,
        'transfers': chatTransfers.clear,
        'outbox': ChatOutboxStore.clear,
        'drafts': ChatDraftStore.clear,
        'images': chatImageMemoryCache.clear,
        'decodedImages': () => PaintingBinding.instance.imageCache.clear(),
        'liveImages': () => PaintingBinding.instance.imageCache.clearLiveImages(),
        'diskImages': () => DefaultCacheManager().emptyCache(),
        'audio': chatAudioCoordinator.stop,
        'localStorage': ChatLocalPersistence.purgeActive,
        'push': PushPreferencesService.instance.prepareSignOut,
      },
      signOut: () async {
        await FirebaseAuth.instance.signOut();
        PushPreferencesService.instance.cancelSignOut();
      },
      providers: {
        'googleSignOut': () async {
          await googleSignIn.signOut();
        },
      },
      onAuthFailure: PushPreferencesService.instance.cancelSignOut,
      onFailure: (stage, error, stack) {
        // Do not claim that local data was wiped when cleanup failed.
        // Avoid logging potentially sensitive exception payloads.
        debugPrint('[AuthSessionService] Cleanup incomplete: $stage');
      },
    );
    if (kDebugMode) {
      debugPrint('[AuthSessionService] signOutFully finished');
    }
  }
}
