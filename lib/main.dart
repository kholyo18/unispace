import 'services/chat_notification_actions.dart';
import 'features/shell/chat/chat_group_pages.dart' show ChatGroupJoinPage;
import 'services/chat_group_link.dart';
import 'services/community_search_text.dart';
import 'services/content_search_scan.dart';
import 'ui/settings/account_profile_fields.dart';
import 'features/guide/app_guide.dart';
import 'features/community/polls/poll_values.dart';
import 'features/community/media/video_values.dart';
import 'app/startup_tasks.dart';
import 'l10n/main_strings.dart';
import 'package:intl/intl.dart' show DateFormat, Intl;
import 'services/notification_display_text.dart';
import 'l10n/shell_strings.dart' show serviceErrorText;
import 'services/feed_item_retention.dart';
import 'services/fresh_feed_page.dart';
import 'services/feed_pagination_listener.dart';
import 'services/retained_image_slide.dart';
import 'services/authorized_media_cache.dart';
import 'services/video_playback_source.dart';
import 'services/performance_probe.dart';
import 'services/post_media_links.dart';
import 'services/authorized_post_image.dart';
import 'services/authorized_video_cache.dart';
import 'services/media_upload_limits.dart';
import 'services/post_privacy_sync.dart';
import 'ui/settings/push_preferences_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'ui/settings/public_profile_service.dart';
import 'ui/settings/profile_privacy.dart';

import 'ui/auth/auth_security_check.dart';
import 'features/auth/terms_of_use_screen.dart';
import 'features/settings/privacy/privacy_policy_screen.dart';
import 'features/legal/community_guidelines_screen.dart';
// ============================================================================
// UniSpace startup and shared application library.
// Feature implementations live in app/parts; reusable pure logic has its own imports.
// ============================================================================
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'dart:ui' as ui;
import 'dart:math';
import 'dart:math' as math;

import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app_links/app_links.dart' as deep_links;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:UniSpace/module/moduls.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:gal/gal.dart';

// Local

// PDF / Printing

import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import 'firebase_options.dart';
import 'generated/l10n.dart';
import 'ui/theme.dart';
import 'ui/contact/contact_us_sheet.dart';
import 'ui/widgets/widgets.dart';

import 'ui/settings/app_settings.dart';
import 'ui/settings/drawer_screens.dart';
import 'ui/settings/security_privacy_screen.dart';
import 'ui/settings/email_verification_service.dart';
import 'ui/settings/user_profile_service.dart';
import 'ui/settings/session_service.dart';
import 'services/auth_session_service.dart';
import 'services/two_factor_service.dart';
import 'features/auth/signup_flow.dart';
import 'features/settings/about/about_screen.dart';

import 'config/app_links.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:translator/translator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'package:video_player/video_player.dart';
import 'package:flutter/rendering.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'ui/settings/privacy/privacy_account_overview_tab.dart';

import 'core/branding.dart';

export 'features/shell/presentation/pages/bottom_bar.dart';

export 'features/shell/sliding_view_switcher.dart';
import 'features/shell/chat_page.dart';
export 'features/shell/chat_page.dart';

export 'features/auth/auth_gate.dart';

export 'features/spider/spider.dart';
import 'features/gpa/gpa.dart';
export 'features/gpa/gpa.dart';
export 'core/translate_subject.dart';

part 'app/parts/appearance.dart';
part 'app/parts/app_shell.dart';
part 'app/parts/notes.dart';
part 'app/parts/common.dart';
part 'app/parts/authentication.dart';
part 'app/parts/feed.dart';
part 'app/parts/notifications.dart';
part 'app/parts/community_search.dart';
part 'app/parts/post_cards.dart';
part 'app/parts/saved_posts.dart';
part 'app/parts/community_data.dart';
part 'app/parts/feed_images.dart';
part 'app/parts/poll_question.dart';
part 'app/parts/post_composer.dart';
part 'app/parts/poll_results.dart';
part 'app/parts/poll_models.dart';
part 'app/parts/post_actions.dart';
part 'app/parts/media_carousel.dart';
part 'app/parts/feed_videos.dart';
part 'app/parts/simple_video_viewer.dart';
part 'app/parts/video_controls.dart';
part 'app/parts/post_images.dart';
part 'app/parts/fullscreen_media.dart';
part 'app/parts/video_preview.dart';
part 'app/parts/fullscreen_images.dart';
part 'app/parts/fullscreen_video.dart';
part 'app/parts/post_pager.dart';
part 'app/parts/fullscreen_actions.dart';
part 'app/parts/poll_builder.dart';
part 'app/parts/poll_question_card.dart';
part 'app/parts/post_models.dart';
part 'app/parts/comments.dart';
part 'app/parts/own_profile.dart';
part 'app/parts/public_profile.dart';
part 'app/parts/relationships.dart';
part 'app/parts/reporting.dart';
part 'app/parts/blocked_users.dart';
part 'app/parts/push_notifications.dart';
part 'app/parts/hidden_posts.dart';
part 'app/parts/moderation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  PrivacyExternalRoutes.blockedAccounts = (_) => const BlockedUsersScreen();
  PrivacyExternalRoutes.hiddenPosts = (_) => const HiddenPostsScreen();

  ThemeMode themeMode = ThemeMode.system;
  Locale locale = supportedAppLocale(
    WidgetsBinding.instance.platformDispatcher.locale.languageCode,
  );

  await initializeStartupDependencies(
    initializeFirebase: () async {
      try {
        await _initFirebaseWithRetry();
        await _initFirebaseAppCheck();
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
      } catch (error, stackTrace) {
        debugPrint('Firebase initialization failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    },
    initializeLocalSettings: () async {
      try {
        await Hive.initFlutter();
        tz.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('Africa/Algiers'));
        if (!Hive.isAdapterRegistered(ModuleModelAdapter().typeId)) {
          Hive.registerAdapter(ModuleModelAdapter());
        }
        await AppSettings.instance.load();
      } catch (e, st) {
        debugPrint('local bootstrap failed: $e');
        debugPrintStack(stackTrace: st);
      }
    },
  );

  if (Firebase.apps.isNotEmpty) {
    try {
      await UserProfileService.instance.initialize();
    } catch (e) {
      debugPrint('UserProfileService.initialize: $e');
    }
  }

  try {
    final p = await SharedPreferences.getInstance();
    final themeIdx = p.getInt('pref_themeMode');
    final lang = p.getString('pref_locale');
    if (themeIdx != null &&
        themeIdx >= 0 &&
        themeIdx < ThemeMode.values.length) {
      themeMode = ThemeMode.values[themeIdx];
    }
    if (lang != null && lang.isNotEmpty) locale = supportedAppLocale(lang);
  } catch (_) {}

  PerformanceProbe.install();
  runApp(UniSpaceApp(initialThemeMode: themeMode, initialLocale: locale));

  if (Firebase.apps.isNotEmpty) {
    unawaited(initPushNotifications());
  }
}

Future<void> _initFirebaseAppCheck() async {
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
    );
  } catch (error, stackTrace) {
    // App Check attestation can be unavailable on unsupported devices. Keep the
    // app usable while Firebase records the failure for diagnosis.
    debugPrint('Firebase App Check initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> _initFirebaseWithRetry() => initializeFirebaseWithRetry(
      initialize: () async {
        if (Firebase.apps.isNotEmpty) return;
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      },
      onFailure: (attempt, error) =>
          debugPrint('Firebase init attempt $attempt failed: $error'),
    );
