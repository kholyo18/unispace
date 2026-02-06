import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  SessionService._();

  static final SessionService instance = SessionService._();

  static const _deviceIdKey = 'auth_device_id';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

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
    final deviceId = await getOrCreateDeviceId();
    return '${uid}_$deviceId';
  }

  Future<void> initSession(String uid) async {
    final deviceId = await getOrCreateDeviceId();
    final sessionId = await getOrCreateSessionId(uid);
    final docRef = _firestore.collection('users').doc(uid).collection('sessions').doc(sessionId);
    final payload = await _buildSessionPayload(sessionId: sessionId, deviceId: deviceId);
    final existing = await docRef.get();
    if (existing.exists) {
      payload.remove('createdAt');
    }
    await docRef.set(
      payload,
      SetOptions(merge: true),
    );
    await markCurrentSession(uid, sessionId);
  }

  Future<void> updateLastSeen(String uid) async {
    final sessionId = await getOrCreateSessionId(uid);
    final docRef = _firestore.collection('users').doc(uid).collection('sessions').doc(sessionId);
    await docRef.set({
      'sessionId': sessionId,
      'isActive': true,
      'revokedAt': null,
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await markCurrentSession(uid, sessionId);
  }

  Future<bool> isCurrentSessionRevoked(String uid) async {
    final sessionId = await getOrCreateSessionId(uid);
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
        .orderBy('lastSeenAt', descending: true)
        .snapshots();
  }

  Future<void> revokeSession({required String uid, required String sessionId}) {
    return _firestore.collection('users').doc(uid).collection('sessions').doc(sessionId).set({
      'isActive': false,
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
        'revokedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> revokeCurrentSession(String uid) async {
    final sessionId = await getOrCreateSessionId(uid);
    await revokeSession(uid: uid, sessionId: sessionId);
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
