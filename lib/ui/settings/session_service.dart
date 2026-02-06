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

  static const _deviceIdKey = 'auth_device_id';
  static const _sessionIdKeyPrefix = 'auth_current_session_id_';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  StreamSubscription<User?>? _authSubscription;
  Timer? _heartbeatTimer;

  Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_deviceIdKey);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    final generated = DateTime.now().microsecondsSinceEpoch.toString();
    await prefs.setString(_deviceIdKey, generated);
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
    final deviceId = await getOrCreateDeviceId();
    final sessionId = forceNew ? _generateUuidV4() : await getOrCreateSessionId(uid);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_sessionIdKeyPrefix$uid', sessionId);
    final docRef = _firestore.collection('users').doc(uid).collection('sessions').doc(sessionId);
    final payload = await _buildSessionPayload(sessionId: sessionId, deviceId: deviceId);
    await docRef.set(payload, SetOptions(merge: true));
    await markCurrentSession(uid, sessionId);
    _startHeartbeat();
    _ensureAuthListener();
  }

  Future<void> updateLastSeen(String uid) async {
    final sessionId = await getCurrentSessionId(uid);
    if (sessionId == null) return;
    final docRef = _firestore.collection('users').doc(uid).collection('sessions').doc(sessionId);
    await docRef.set({
      'sessionId': sessionId,
      'isActive': true,
      'endedAt': null,
      'revokedAt': null,
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await markCurrentSession(uid, sessionId);
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
    return !isActive || revokedAt != null;
  }

  Future<void> markCurrentSession(String uid, String sessionId) {
    return _firestore.collection('users').doc(uid).set({
      'currentSessionId': sessionId,
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> sessionsStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .where('isActive', isEqualTo: true)
        .orderBy('lastSeenAt', descending: true)
        .snapshots();
  }

  Future<void> revokeSession({required String uid, required String sessionId}) {
    return _firestore.collection('users').doc(uid).collection('sessions').doc(sessionId).set({
      'isActive': false,
      'endedAt': FieldValue.serverTimestamp(),
      'revokedAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> revokeCurrentSession(String uid) async {
    final sessionId = await getCurrentSessionId(uid);
    if (sessionId == null) return;
    await revokeSession(uid: uid, sessionId: sessionId);
    await clearCurrentSessionId(uid);
    _stopHeartbeat();
  }

  void _ensureAuthListener() {
    _authSubscription ??= FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) return;
      _stopHeartbeat();
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 45), (_) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _stopHeartbeat();
        return;
      }
      await updateLastSeen(user.uid);
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
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
    required String deviceId,
  }) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final metadata = await _readDeviceMetadata();
    return {
      'sessionId': sessionId,
      'deviceId': deviceId,
      'deviceName': metadata.deviceName,
      'platform': metadata.platform,
      'appVersion': '${packageInfo.version}+${packageInfo.buildNumber}',
      'osVersion': metadata.osVersion,
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
      'endedAt': null,
      'isActive': true,
      'revokedAt': null,
    };
  }

  Future<_DeviceMetadata> _readDeviceMetadata() async {
    if (kIsWeb) {
      return const _DeviceMetadata(
        deviceName: 'web browser',
        platform: 'web',
        osVersion: 'web',
      );
    }
    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      final model = info.model.trim().isEmpty ? 'android' : info.model.trim();
      return _DeviceMetadata(
        deviceName: 'android $model',
        platform: 'android',
        osVersion: info.version.release,
      );
    }
    if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      final model = info.utsname.machine.trim().isEmpty ? 'ios' : info.utsname.machine.trim();
      return _DeviceMetadata(
        deviceName: 'ios $model',
        platform: 'ios',
        osVersion: info.systemVersion,
      );
    }
    return _DeviceMetadata(
      deviceName: Platform.operatingSystem,
      platform: Platform.operatingSystem,
      osVersion: Platform.operatingSystemVersion,
    );
  }
}

class _DeviceMetadata {
  const _DeviceMetadata({
    required this.deviceName,
    required this.platform,
    required this.osVersion,
  });

  final String deviceName;
  final String platform;
  final String osVersion;
}
