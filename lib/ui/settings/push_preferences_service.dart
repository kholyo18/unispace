import 'session_service.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'app_settings.dart';

class PushPreferencesService with WidgetsBindingObserver {
  PushPreferencesService._();
  static final instance = PushPreferencesService._();
  final status = ValueNotifier<String>('تخص هذه الإعدادات هذا الجهاز.');
  Future<void> _pending = Future<void>.value();
  bool _started = false;
  String? _lastSettings;
  int _revision = 0;
  String? _signingOutUid;

  Map<String, bool> get _preferences {
    final s = AppSettings.instance.notifier.value;
    return {'enabled': s.notificationsEnabled, 'community': s.communityUpdatesEnabled,
      'announcements': s.announcementsEnabled, 'exams': s.examRemindersEnabled};
  }

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    SessionService.instance.sessionRevision.addListener(() => unawaited(sync()));
    _lastSettings = _preferences.toString();
    AppSettings.instance.notifier.addListener(() {
      final next = _preferences.toString();
      if (next == _lastSettings) return;
      _lastSettings = next;
      unawaited(sync());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(sync());
  }

  bool allows(String type) {
    final p = _preferences;
    if (p['enabled'] != true) return false;
    if (const ['new_post','like','like_comment','reply','comment','repost','follow','follow_request','follow_accepted'].contains(type)) return p['community'] == true;
    if (type == 'announcement') return p['announcements'] == true;
    if (type == 'exam_reminder') return p['exams'] == true;
    // Match the server allowlist. Unknown/chat kinds have no reviewed delivery
    // contract here and must not bypass category or per-chat mute checks.
    return false;
  }

  Future<void> sync([String? refreshedToken]) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid == _signingOutUid) return Future<void>.value();
    if (uid != _signingOutUid) _signingOutUid = null;
    final revision = ++_revision;
    status.value = uid == null ? 'محفوظة على الجهاز. سجّل الدخول لمزامنة إشعاراته.' : 'جارٍ مزامنة إعدادات إشعارات هذا الجهاز…';
    _pending = _pending.then((_) async {
      if (revision != _revision || uid == null) return;
      try {
        final token = refreshedToken ?? await FirebaseMessaging.instance.getToken().timeout(const Duration(seconds: 8));
        if (revision != _revision || FirebaseAuth.instance.currentUser?.uid != uid) return;
        if (token == null || token.isEmpty) throw StateError('No push token');
        final sessionId = await SessionService.instance.getCurrentSessionId(uid);
        if (revision != _revision || FirebaseAuth.instance.currentUser?.uid != uid) return;
        if (sessionId == null || sessionId.isEmpty) throw StateError('Device session not ready');
        final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
            .httpsCallable('syncPushDevice', options: HttpsCallableOptions(timeout: const Duration(seconds: 20)))
            .call<Map<String, dynamic>>({'token':token,'sessionId':sessionId,'platform':defaultTargetPlatform.name,'preferences':_preferences});
        if (result.data['synced'] != true) throw StateError('Unconfirmed push preferences');
        if (revision == _revision && FirebaseAuth.instance.currentUser?.uid == uid) {
          status.value = 'تمت مزامنة إعدادات إشعارات هذا الجهاز.';
        }
      } catch (_) {
        if (revision == _revision && FirebaseAuth.instance.currentUser?.uid == uid) {
          status.value = 'محفوظة محليًا، لكن لم تتأكد المزامنة. قد تستمر إشعارات الخلفية حتى تنجح.';
        }
      }
    });
    return _pending;
  }
  void cancelSignOut() { _signingOutUid = null; }

  Future<void> prepareSignOut() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _signingOutUid = uid;
    ++_revision;
    // Drain the serialized registration before detaching it; suppress new registrations meanwhile.
    await _pending;
    var confirmed = false;
    try {
      final token = await FirebaseMessaging.instance.getToken().timeout(const Duration(seconds: 8));
      if (token != null && token.isNotEmpty && FirebaseAuth.instance.currentUser?.uid == uid) {
        final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
            .httpsCallable('detachPushDevice', options: HttpsCallableOptions(timeout: const Duration(seconds: 10)))
            .call<Map<String, dynamic>>({'token':token});
        confirmed = result.data['detached'] == true;
      }
    } catch (_) {}
    try {
      await FirebaseMessaging.instance.deleteToken().timeout(const Duration(seconds: 8));
    } catch (_) {}
    status.value = confirmed
        ? 'تم فصل إشعارات الجهاز عن الحساب.'
        : 'تعذر تأكيد فصل إشعارات الجهاز. قد تبقى رسائل سبق إرسالها.';
  }

}
