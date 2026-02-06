import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SessionService {
  SessionService._();

  static final SessionService instance = SessionService._();

  static const _installationIdKey = 'auth_installation_id';
  static const _sessionIdKeyPrefix = 'auth_current_session_id_';
  static const _lastUidKey = 'auth_last_session_uid';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sessionSubscription;
  Timer? _heartbeatTimer;
  String? _lastKnownUid;
  DateTime? _lastHeartbeatAt;
  static const Duration _heartbeatInterval = Duration(seconds: 90);
  static const Duration _heartbeatThrottle = Duration(seconds: 60);

  Future<String> getOrCreateInstallationId() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_installationIdKey);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    final generated = _generateUuidV4();
    await prefs.setString(_installationIdKey, generated);
    return generated;
  }

  Future<String> getOrCreateSessionId(String uid) async {
    final current = await getCurrentSessionId(uid);
    if (current != null && current.isNotEmpty) {
      return current;
    }
    final generated = _generateUuidV4();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_sessionIdKeyPrefix$uid', generated);
    return generated;
  }

  Future<String?> getCurrentSessionId(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getString('$_sessionIdKeyPrefix$uid');
    if (current == null || current.isEmpty) {
      return null;
    }
    return current;
  }

  Future<void> clearCurrentSessionId(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_sessionIdKeyPrefix$uid');
  }

  Future<void> initSession(String uid, {bool forceNew = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != uid) return;
    if (forceNew) {
      await clearCurrentSessionId(uid);
    }
    final currentSessionId = await getCurrentSessionId(uid);
    if (currentSessionId == null || currentSessionId.isEmpty) {
      final info = await readCurrentDeviceInfo();
      await createSession(user: user, info: info);
    } else {
      await updateHeartbeat(user: user, sessionId: currentSessionId, force: true);
      await markCurrentSession(uid, currentSessionId);
    }
    await cleanupSessions(uid: uid);
    await _attachSessionRevocationListener(user.uid);
    _startHeartbeat();
    _ensureAuthListener();
  }

  Future<void> updateLastSeen(String uid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != uid) return;
    final sessionId = await getCurrentSessionId(uid);
    if (sessionId == null) return;
    await updateHeartbeat(user: user, sessionId: sessionId);
  }

  Future<DeviceInfo> readCurrentDeviceInfo() async {
    final metadata = await _readDeviceMetadata();
    return DeviceInfo(
      platform: metadata.platform,
      model: metadata.deviceModel,
      osVersion: metadata.osVersion,
    );
  }

  Future<String> createSession({required User user, required DeviceInfo info}) async {
    final installationId = await getOrCreateInstallationId();
    final sessionId = _generateUuidV4();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_sessionIdKeyPrefix${user.uid}', sessionId);
    await prefs.setString(_lastUidKey, user.uid);
    _lastKnownUid = user.uid;

    final docRef = _firestore.collection('users').doc(user.uid).collection('sessions').doc(sessionId);
    final payload = await _buildSessionPayload(
      sessionId: sessionId,
      installationId: installationId,
      info: info,
    );
    await docRef.set(payload, SetOptions(merge: true));
    await markCurrentSession(user.uid, sessionId);
    return sessionId;
  }

  Future<void> updateHeartbeat({
    required User user,
    required String sessionId,
    bool force = false,
  }) async {
    final now = DateTime.now();
    if (!force && _lastHeartbeatAt != null && now.difference(_lastHeartbeatAt!) < _heartbeatThrottle) {
      return;
    }
    _lastHeartbeatAt = now;

    final docRef = _firestore.collection('users').doc(user.uid).collection('sessions').doc(sessionId);
    await docRef.set({
      'sessionId': sessionId,
      'isActive': true,
      'endedAt': null,
      'revokedAt': null,
      'forceLogout': false,
      'lastActiveAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await markCurrentSession(user.uid, sessionId);
  }

  Stream<List<SessionModel>> watchActiveSessions({required User user}) {
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .where('isActive', isEqualTo: true)
        .orderBy('lastActiveAt', descending: true)
        .snapshots()
        .map((snapshot) => _dedupeSessions(snapshot.docs.map(SessionModel.fromFirestore).toList()));
  }

  Stream<List<SessionModel>> watchAllSessions({required User user}) {
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .orderBy('lastActiveAt', descending: true)
        .snapshots()
        .map((snapshot) => _dedupeSessions(snapshot.docs.map(SessionModel.fromFirestore).toList()));
  }

  Future<void> revokeSession({required User user, required String sessionId}) {
    return _firestore.collection('users').doc(user.uid).collection('sessions').doc(sessionId).set({
      'isActive': false,
      'endedAt': FieldValue.serverTimestamp(),
      'revokedAt': FieldValue.serverTimestamp(),
      'forceLogout': true,
      'lastActiveAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> isCurrentSessionRevoked(String uid) async {
    final sessionId = await getCurrentSessionId(uid);
    if (sessionId == null) return false;
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .doc(sessionId)
        .get();
    final data = snapshot.data();
    if (data == null) return false;
    final isActive = data['isActive'] as bool? ?? true;
    final revokedAt = data['revokedAt'];
    final forceLogout = data['forceLogout'] as bool? ?? false;
    return !isActive || revokedAt != null || forceLogout;
  }

  Future<void> markCurrentSession(String uid, String sessionId) {
    return _firestore.collection('users').doc(uid).set({
      'currentSessionId': sessionId,
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> sessionsStream(String uid) {
    debugPrint('[SessionService] sessionsStream path=users/$uid/sessions orderBy=lastSeenAt desc');
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .orderBy('lastSeenAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> activeSessionsStream(String uid) {
    debugPrint('[SessionService] activeSessionsStream path=users/$uid/sessions isActive=true orderBy=lastSeenAt desc');
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .where('isActive', isEqualTo: true)
        .orderBy('lastSeenAt', descending: true)
        .snapshots();
  }

  Future<void> revokeAllOtherSessions({required String uid, required String currentSessionId}) async {
    final snapshot = await _firestore.collection('users').doc(uid).collection('sessions').get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      if (doc.id == currentSessionId) continue;
      batch.set(doc.reference, {
        'isActive': false,
        'endedAt': FieldValue.serverTimestamp(),
        'revokedAt': FieldValue.serverTimestamp(),
        'forceLogout': true,
        'lastActiveAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> revokeCurrentSession(String uid) async {
    final sessionId = await getCurrentSessionId(uid);
    if (sessionId == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != uid) return;
    await revokeSession(user: user, sessionId: sessionId);
    debugPrint('[SessionService] revokeCurrentSession uid=$uid sessionId=$sessionId');
    _stopHeartbeat();
    _sessionSubscription?.cancel();
    _sessionSubscription = null;
  }

  void _ensureAuthListener() {
    _authSubscription ??= FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        _lastKnownUid = user.uid;
        _startHeartbeat();
        await _attachSessionRevocationListener(user.uid);
        return;
      }
      await _markLastKnownSessionInactive();
      _stopHeartbeat();
      _sessionSubscription?.cancel();
      _sessionSubscription = null;
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
      await updateHeartbeat(user: user, sessionId: sessionId);
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
        .listen((snapshot) async {
      final data = snapshot.data();
      if (data == null) return;
      final revoked = data['revokedAt'] != null;
      final isActive = data['isActive'] as bool? ?? true;
      final forceLogout = data['forceLogout'] as bool? ?? false;
      if (!revoked && isActive && !forceLogout) return;
      _stopHeartbeat();
      await _sessionSubscription?.cancel();
      _sessionSubscription = null;
      await clearCurrentSessionId(uid);
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid == uid) {
        await FirebaseAuth.instance.signOut();
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _markLastKnownSessionInactive() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = _lastKnownUid ?? prefs.getString(_lastUidKey);
    if (uid == null || uid.isEmpty) return;
    final sessionId = await getCurrentSessionId(uid);
    if (sessionId == null || sessionId.isEmpty) return;
    final docRef = _firestore.collection('users').doc(uid).collection('sessions').doc(sessionId);
    debugPrint('[SessionService] markInactive uid=$uid sessionId=$sessionId path=${docRef.path}');
    await docRef.set({
      'sessionId': sessionId,
      'isActive': false,
      'endedAt': FieldValue.serverTimestamp(),
      'revokedAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await clearCurrentSessionId(uid);
    await prefs.remove(_lastUidKey);
    _lastKnownUid = null;
  }

  Future<void> cleanupSessions({required String uid}) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .orderBy('createdAt', descending: true)
        .get();
    if (snapshot.docs.isEmpty) return;

    final currentSessionId = await getCurrentSessionId(uid);
    final latestByInstallation = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    final keepIds = <String>{};
    for (final doc in snapshot.docs) {
      final installationId = (doc.data()['installationId'] as String?)?.trim();
      if (installationId == null || installationId.isEmpty) {
        keepIds.add(doc.id);
        continue;
      }
      latestByInstallation.putIfAbsent(installationId, () => doc);
    }
    keepIds.addAll(latestByInstallation.values.map((doc) => doc.id));
    keepIds.addAll(snapshot.docs.take(5).map((doc) => doc.id));
    if (currentSessionId != null) {
      keepIds.add(currentSessionId);
    }

    final batch = _firestore.batch();
    var hasChanges = false;
    for (final doc in snapshot.docs) {
      if (keepIds.contains(doc.id)) continue;
      hasChanges = true;
      batch.set(doc.reference, {
        'isActive': false,
        'endedAt': FieldValue.serverTimestamp(),
        'revokedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    if (hasChanges) {
      await batch.commit();
    }
  }

  List<SessionModel> _dedupeSessions(List<SessionModel> sessions) {
    final byDocId = <String, SessionModel>{};
    for (final session in sessions) {
      byDocId[session.id] = session;
    }
    final sorted = byDocId.values.toList()
      ..sort((a, b) {
        final aTs = a.lastActiveAt ?? a.createdAt;
        final bTs = b.lastActiveAt ?? b.createdAt;
        if (aTs == null && bTs == null) return 0;
        if (aTs == null) return 1;
        if (bTs == null) return -1;
        return bTs.compareTo(aTs);
      });
    final byInstallation = <String, SessionModel>{};
    final fallback = <SessionModel>[];
    for (final session in sorted) {
      final installationId = session.installationId.trim();
      if (installationId.isEmpty) {
        fallback.add(session);
        continue;
      }
      byInstallation.putIfAbsent(installationId, () => session);
    }
    return [...byInstallation.values, ...fallback];
  }

  String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  Future<Map<String, dynamic>> _buildSessionPayload({
    required String sessionId,
    required String installationId,
    required DeviceInfo info,
  }) async {
    final packageInfo = await PackageInfo.fromPlatform();
    return {
      'sessionId': sessionId,
      'installationId': installationId,
      'deviceId': installationId,
      'deviceModel': info.model,
      'deviceName': info.model,
      'platform': info.platform,
      'appVersion': '${packageInfo.version}+${packageInfo.buildNumber}',
      'osVersion': info.osVersion,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
      'endedAt': null,
      'isActive': true,
      'revokedAt': null,
      'forceLogout': false,
    };
  }

  Future<_DeviceMetadata> _readDeviceMetadata() async {
    try {
      if (kIsWeb) {
        return const _DeviceMetadata(
          deviceModel: 'web browser',
          platform: 'web',
          osVersion: 'web',
        );
      }
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        final brand = info.brand.trim();
        final model = info.model.trim();
        final value = [brand, model].where((item) => item.isNotEmpty).join(' ').trim();
        return _DeviceMetadata(
          deviceModel: value.isEmpty ? 'android device' : value,
          platform: 'android',
          osVersion: info.version.release,
        );
      }
      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        final model = info.name.trim().isNotEmpty ? info.name.trim() : info.utsname.machine.trim();
        return _DeviceMetadata(
          deviceModel: model.isEmpty ? 'ios device' : model,
          platform: 'ios',
          osVersion: info.systemVersion,
        );
      }
      return _DeviceMetadata(
        deviceModel: Platform.operatingSystem,
        platform: Platform.operatingSystem,
        osVersion: Platform.operatingSystemVersion,
      );
    } catch (_) {
      return _DeviceMetadata(
        deviceModel: 'unknown',
        platform: kIsWeb ? 'web' : Platform.operatingSystem,
        osVersion: 'unknown',
      );
    }
  }
}

class _DeviceMetadata {
  const _DeviceMetadata({
    required this.deviceModel,
    required this.platform,
    required this.osVersion,
  });

  final String deviceModel;
  final String platform;
  final String osVersion;
}

class DeviceInfo {
  const DeviceInfo({
    required this.platform,
    required this.model,
    required this.osVersion,
  });

  final String platform;
  final String model;
  final String osVersion;
}

class SessionModel {
  const SessionModel({
    required this.id,
    required this.deviceModel,
    required this.platform,
    required this.isActive,
    required this.lastActiveAt,
    required this.createdAt,
    required this.revokedAt,
    required this.installationId,
  });

  factory SessionModel.fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return SessionModel(
      id: doc.id,
      deviceModel: (data['deviceModel'] as String?) ?? (data['deviceName'] as String?) ?? 'unknown',
      platform: (data['platform'] as String?) ?? 'unknown',
      isActive: data['isActive'] as bool? ?? false,
      lastActiveAt: data['lastActiveAt'] as Timestamp? ?? data['lastSeenAt'] as Timestamp?,
      createdAt: data['createdAt'] as Timestamp?,
      revokedAt: data['revokedAt'] as Timestamp?,
      installationId: (data['installationId'] as String?) ?? (data['deviceId'] as String?) ?? '',
    );
  }

  final String id;
  final String deviceModel;
  final String platform;
  final bool isActive;
  final Timestamp? lastActiveAt;
  final Timestamp? createdAt;
  final Timestamp? revokedAt;
  final String installationId;
}
