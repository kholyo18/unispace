import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/auth_session_service.dart';
import 'session_record.dart';

class SessionService with WidgetsBindingObserver {
  SessionService._();

  static final SessionService instance = SessionService._();

  static const _installationIdKey = 'auth_installation_id';
  static const _sessionIdKeyPrefix = 'auth_current_session_id_';
  static const Duration _heartbeatInterval = Duration(seconds: 55);
  static const Duration _heartbeatThrottle = Duration(seconds: 45);
  static const Duration onlineWindow = Duration(minutes: 2);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sessionSubscription;
  Timer? _heartbeatTimer;
  DateTime? _lastHeartbeatAt;
  String? _lastHeartbeatSession;
  Future<void> _initialization = Future<void>.value();
  bool _isObservingLifecycle = false;
  final ValueNotifier<int> sessionRevision = ValueNotifier<int>(0);

  Future<String> getOrCreateInstallationId() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_installationIdKey);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    final generated = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    await prefs.setString(_installationIdKey, generated);
    return generated;
  }

  Future<String> getOrCreateSessionId(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('$_sessionIdKeyPrefix$uid');
    if (existing != null && existing.isNotEmpty) return existing;

    final generated =
        '${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}_${uid.substring(0, 6)}';
    await prefs.setString('$_sessionIdKeyPrefix$uid', generated);
    return generated;
  }

  Future<String?> getCurrentSessionId(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getString('$_sessionIdKeyPrefix$uid');
    if (current != null && current.isNotEmpty) return current;
    return null;
  }

  Future<void> clearCurrentSessionId(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_sessionIdKeyPrefix$uid');
  }

  Future<void> initSession(String uid, {bool forceNew = false}) {
    final next = _initialization.then((_) => _initSession(uid, forceNew: forceNew));
    _initialization = next.catchError((Object error, StackTrace stack) {
      debugPrint('[Session] initialization failed: $error');
    });
    return next;
  }

  Future<void> _initSession(String uid, {bool forceNew = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != uid) return;

    if (forceNew) {
      _stopHeartbeat();
      await _sessionSubscription?.cancel();
      _sessionSubscription = null;
      final previous = await getCurrentSessionId(uid);
      if (previous != null) {
        final ref = _firestore.collection('users').doc(uid).collection('sessions').doc(previous);
        if ((await ref.get()).exists) await revokeSession(user: user, sessionId: previous);
      }
      await clearCurrentSessionId(uid);
    }
    final sessionId = await getOrCreateSessionId(uid);
    final info = await readCurrentDeviceInfo();
    final accepted = await _upsertSession(user: user, sessionId: sessionId, info: info);
    if (FirebaseAuth.instance.currentUser?.uid != uid) return;
    if (!accepted) {
      await clearCurrentSessionId(uid);
      await AuthSessionService.signOutFully();
      return;
    }
    await markCurrentSession(uid, sessionId);
    sessionRevision.value++;
    await _attachSessionRevocationListener(uid);
    _startHeartbeat();
    _ensureAuthListener();
    _ensureLifecycleObserver();
  }

  Future<void> updateLastSeen(String uid, {bool force = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != uid) return;
    final sessionId = await getCurrentSessionId(uid);
    if (sessionId == null) return;
    await updateHeartbeat(user: user, sessionId: sessionId, force: force);
  }

  Future<DeviceInfo> readCurrentDeviceInfo() async {
    final metadata = await _readDeviceMetadata();
    return DeviceInfo(
      platform: metadata.platform,
      model: metadata.deviceModel,
      manufacturer: metadata.manufacturer,
      osVersion: metadata.osVersion,
    );
  }

  Future<void> updateHeartbeat({
    required User user,
    required String sessionId,
    bool force = false,
  }) async {
    if (FirebaseAuth.instance.currentUser?.uid != user.uid) return;
    final key = '${user.uid}:$sessionId';
    final now = DateTime.now();
    if (!force && _lastHeartbeatSession == key && _lastHeartbeatAt != null &&
        now.difference(_lastHeartbeatAt!) < _heartbeatThrottle) {
      return;
    }
    // Update only activity: never recreate a missing record or undo revocation.
    await _firestore.collection('users').doc(user.uid).collection('sessions')
        .doc(sessionId).update(sessionHeartbeat());
    _lastHeartbeatSession = key;
    _lastHeartbeatAt = now;
  }

  Stream<List<SessionModel>> watchActiveSessions({required User user}) {
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .snapshots()
        .map((snapshot) => _dedupeSessions(snapshot.docs.map(SessionModel.fromFirestore).toList())
          ..removeWhere((session) => session.isRevoked));
  }

  Stream<List<SessionModel>> watchAllSessions({required User user}) {
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .snapshots()
        .map((snapshot) => _dedupeSessions(snapshot.docs.map(SessionModel.fromFirestore).toList()));
  }

  Future<void> revokeSession({required User user, required String sessionId}) {
    return _firestore.collection('users').doc(user.uid).collection('sessions').doc(sessionId).update({
      'isRevoked': true,
      'revokedAt': FieldValue.serverTimestamp(),
      'revokeReason': 'manual',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateSessionAlias({required String uid, required String sessionId, required String alias}) {
    return _firestore.collection('users').doc(uid).collection('sessions').doc(sessionId).set({
      'alias': alias.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setSessionTrusted({required String uid, required String sessionId, required bool trusted}) {
    return _firestore.collection('users').doc(uid).collection('sessions').doc(sessionId).set({
      'isTrusted': trusted,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> isCurrentSessionRevoked(String uid) async {
    final sessionId = await getCurrentSessionId(uid);
    if (sessionId == null) return false;
    final snapshot = await _firestore.collection('users').doc(uid).collection('sessions').doc(sessionId).get();
    final data = snapshot.data();
    if (data == null) return false;
    return data['isRevoked'] as bool? ?? false;
  }

  Future<void> markCurrentSession(String uid, String sessionId) {
    return _firestore.collection('users').doc(uid).set({'currentSessionId': sessionId}, SetOptions(merge: true));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> sessionsStream(String uid) {
    return _firestore.collection('users').doc(uid).collection('sessions').orderBy('lastSeenAt', descending: true).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> activeSessionsStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .where('isRevoked', isEqualTo: false)
        .orderBy('lastSeenAt', descending: true)
        .snapshots();
  }

  Future<void> revokeAllOtherSessions({required String uid, required String currentSessionId}) {
    if (currentSessionId.isEmpty) throw StateError('Current session is unavailable');
    return _revokeSessions(uid, except: currentSessionId, reason: 'logout_all_other');
  }

  Future<void> revokeAllSessions(String uid) => _revokeSessions(uid, reason: 'logout_all');

  Future<void> _revokeSessions(String uid, {String? except, required String reason}) async {
    final snapshot = await _firestore.collection('users').doc(uid).collection('sessions').get();
    var batch = _firestore.batch();
    var count = 0;
    for (final doc in snapshot.docs) {
      if (doc.id == except || doc.data()['isRevoked'] == true) continue;
      batch.update(doc.reference, {
        'isRevoked': true,
        'revokedAt': FieldValue.serverTimestamp(),
        'revokeReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (++count == 400) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }
    if (count > 0) await batch.commit();
  }

  Future<void> revokeCurrentSession(String uid) async {
    final sessionId = await getCurrentSessionId(uid);
    if (sessionId == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != uid) return;
    await revokeSession(user: user, sessionId: sessionId);
    await clearCurrentSessionId(uid);
    _stopHeartbeat();
    await _sessionSubscription?.cancel();
    _sessionSubscription = null;
  }

  void _ensureAuthListener() {
    _authSubscription ??= FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        _startHeartbeat();
        await _attachSessionRevocationListener(user.uid);
        _ensureLifecycleObserver();
        return;
      }
      _stopHeartbeat();
      await _sessionSubscription?.cancel();
      _sessionSubscription = null;
      _removeLifecycleObserver();
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _stopHeartbeat();
        return;
      }
      final sessionId = await getCurrentSessionId(user.uid);
      if (sessionId == null) return;
      try {
        await updateHeartbeat(user: user, sessionId: sessionId);
      } catch (error) {
        debugPrint('[Session] heartbeat failed: $error');
      }
    });
  }

  Future<void> _attachSessionRevocationListener(String uid) async {
    final sessionId = await getCurrentSessionId(uid);
    if (sessionId == null || sessionId.isEmpty) return;

    await _sessionSubscription?.cancel();
    _sessionSubscription = _firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .doc(sessionId)
        .snapshots()
        .listen(
          (snapshot) async {
        if (FirebaseAuth.instance.currentUser?.uid != uid) return;
        final data = snapshot.data();
        if (data == null) return;
        if (data['isRevoked'] != true) return;

        final currentId = await getCurrentSessionId(uid);
        if (currentId != sessionId) return;

        _stopHeartbeat();
        await _sessionSubscription?.cancel();
        _sessionSubscription = null;
        await clearCurrentSessionId(uid);

        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && currentUser.uid == uid) {
          await AuthSessionService.signOutFully();
        }
      },
      onError: (Object error, StackTrace st) async {
        debugPrint('[Session] listener failed: $error');
        if (error is FirebaseException && error.code == 'permission-denied') {
          await _checkRevokedAuthentication(uid);
        }
      },
    );
  }

  Future<void> _checkRevokedAuthentication(String uid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != uid) return;
    try {
      // A permission error alone may be a rules issue. Sign out only when
      // Firebase confirms that the current authentication is no longer valid.
      await user.getIdToken(true);
    } on FirebaseAuthException catch (error) {
      if (!const {'user-token-expired', 'invalid-user-token', 'user-disabled', 'user-not-found'}
          .contains(error.code)) {
        return;
      }
      if (FirebaseAuth.instance.currentUser?.uid != uid) return;
      _stopHeartbeat();
      await clearCurrentSessionId(uid);
      await AuthSessionService.signOutFully();
    } catch (error) {
      debugPrint('[Session] credential check unavailable: $error');
    }
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<bool> _upsertSession({
    required User user,
    required String sessionId,
    required DeviceInfo info,
  }) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final locale = WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag();
    final deviceId = await getOrCreateInstallationId();
    final docRef = _firestore.collection('users').doc(user.uid).collection('sessions').doc(sessionId);
    var created = false;
    final accepted = await _firestore.runTransaction<bool>((transaction) async {
      final existing = await transaction.get(docRef);
      final record = sessionInitialization(
        existing: existing.data(),
        sessionId: sessionId,
        deviceId: deviceId,
        metadata: {
          'model': info.model,
          'platform': info.platform,
          'manufacturer': info.manufacturer,
          'osVersion': info.osVersion,
          'appVersion': packageInfo.version,
          'buildNumber': packageInfo.buildNumber,
          'locale': locale,
        },
      );
      created = !existing.exists;
      if (record == null) return false;
      transaction.set(docRef, record, SetOptions(merge: true));
      return true;
    });
    if (accepted && created) {
      // Alert delivery is best effort; it must not turn a successful login into a failure.
      try {
        final ref = _firestore.collection('users').doc(user.uid);
        final profile = await ref.get();
        if (profile.data()?['security']?['loginAlerts'] != false) {
          await ref.set({
            'security': {
              'lastLoginAlert': {
                'sessionId': sessionId,
                'deviceName': info.model,
                'platform': info.platform,
                'at': FieldValue.serverTimestamp(),
              },
            },
          }, SetOptions(merge: true));
        }
      } catch (error) {
        debugPrint('[Session] login alert failed: $error');
      }
    }
    return accepted;
  }

  List<SessionModel> _dedupeSessions(List<SessionModel> sessions) {
    final byId = <String, SessionModel>{};
    for (final session in sessions) {
      byId[session.id] = session;
    }
    final sorted = byId.values.toList()
      ..sort((a, b) {
        final aAt = a.lastSeenAt ?? a.createdAt;
        final bAt = b.lastSeenAt ?? b.createdAt;
        if (aAt == null && bAt == null) return 0;
        if (aAt == null) return 1;
        if (bAt == null) return -1;
        return bAt.compareTo(aAt);
      });
    return sorted;
  }

  Future<_DeviceMetadata> _readDeviceMetadata() async {
    try {
      if (kIsWeb) {
        return const _DeviceMetadata(deviceModel: 'Web device', platform: 'web', osVersion: 'web');
      }
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        final manufacturer = info.manufacturer.trim();
        final model = info.model.trim();
        final name = [manufacturer, model].where((item) => item.isNotEmpty).join(' ').trim();
        return _DeviceMetadata(
          deviceModel: name.isEmpty ? 'Android device' : name,
          manufacturer: manufacturer,
          platform: 'android',
          osVersion: info.version.release,
        );
      }
      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        final model = info.name.trim().isNotEmpty ? info.name.trim() : info.utsname.machine.trim();
        return _DeviceMetadata(
          deviceModel: model.isEmpty ? 'iOS device' : model,
          manufacturer: 'Apple',
          platform: 'ios',
          osVersion: info.systemVersion,
        );
      }
      return _DeviceMetadata(
        deviceModel: Platform.operatingSystem,
        manufacturer: '',
        platform: Platform.operatingSystem,
        osVersion: Platform.operatingSystemVersion,
      );
    } catch (_) {
      return _DeviceMetadata(
        deviceModel: kIsWeb ? 'Web device' : 'Unknown device',
        manufacturer: '',
        platform: kIsWeb ? 'web' : Platform.operatingSystem,
        osVersion: 'unknown',
      );
    }
  }

  void _ensureLifecycleObserver() {
    if (_isObservingLifecycle) return;
    WidgetsBinding.instance.addObserver(this);
    _isObservingLifecycle = true;
  }

  void _removeLifecycleObserver() {
    if (!_isObservingLifecycle) return;
    WidgetsBinding.instance.removeObserver(this);
    _isObservingLifecycle = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(updateLastSeen(user.uid, force: true).catchError((Object error) {
        debugPrint('[Session] activity update failed: $error');
      }));
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      unawaited(updateLastSeen(user.uid, force: true).catchError((Object error) {
        debugPrint('[Session] activity update failed: $error');
      }));
    }
  }
}

class _DeviceMetadata {
  const _DeviceMetadata({
    required this.deviceModel,
    required this.platform,
    required this.osVersion,
    this.manufacturer = '',
  });

  final String deviceModel;
  final String manufacturer;
  final String platform;
  final String osVersion;
}

class DeviceInfo {
  const DeviceInfo({
    required this.platform,
    required this.model,
    required this.osVersion,
    this.manufacturer = '',
  });

  final String platform;
  final String model;
  final String manufacturer;
  final String osVersion;
}

class SessionModel {
  const SessionModel({
    required this.id,
    required this.sessionId,
    required this.deviceId,
    required this.alias,
    required this.model,
    required this.platform,
    required this.osVersion,
    required this.appVersion,
    required this.buildNumber,
    required this.locale,
    required this.createdAt,
    required this.lastSeenAt,
    required this.isTrusted,
    required this.isRevoked,
    required this.revokedAt,
    required this.revokeReason,
    required this.manufacturer,
    this.networkType,
  });

  factory SessionModel.fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return SessionModel.fromMap(doc.id, doc.data());
  }

  factory SessionModel.fromMap(String id, Map<String, dynamic> data) {
    final model = (data['model'] as String?) ?? (data['deviceModel'] as String?) ?? (data['deviceName'] as String?) ?? 'Unknown device';
    return SessionModel(
      id: id,
      sessionId: (data['sessionId'] as String?) ?? id,
      deviceId: (data['deviceId'] as String?) ?? id,
      alias: (data['alias'] as String?)?.trim().isNotEmpty == true
          ? (data['alias'] as String).trim()
          : model,
      model: model,
      platform: (data['platform'] as String?) ?? 'unknown',
      osVersion: (data['osVersion'] as String?) ?? 'unknown',
      appVersion: (data['appVersion'] as String?) ?? '-',
      buildNumber: (data['buildNumber'] as String?) ?? '-',
      locale: data['locale'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
      lastSeenAt: (data['lastSeenAt'] as Timestamp?) ?? (data['lastActiveAt'] as Timestamp?),
      isTrusted: data['isTrusted'] as bool? ?? data['trusted'] as bool? ?? false,
      isRevoked: data['isRevoked'] as bool? ?? false,
      revokedAt: data['revokedAt'] as Timestamp?,
      revokeReason: data['revokeReason'] as String?,
      manufacturer: (data['manufacturer'] as String?) ?? '',
      networkType: data['networkType'] as String?,
    );
  }

  bool get isOnline {
    final seen = lastSeenAt?.toDate();
    if (seen == null || isRevoked) return false;
    final elapsed = DateTime.now().difference(seen);
    return !elapsed.isNegative && elapsed <= SessionService.onlineWindow;
  }

  final String id;
  final String sessionId;
  final String deviceId;
  final String alias;
  final String model;
  final String platform;
  final String osVersion;
  final String appVersion;
  final String buildNumber;
  final String? locale;
  final Timestamp? createdAt;
  final Timestamp? lastSeenAt;
  final bool isTrusted;
  final bool isRevoked;
  final Timestamp? revokedAt;
  final String? revokeReason;
  final String manufacturer;
  final String? networkType;
}
