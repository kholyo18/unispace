import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  SessionService._();

  static final SessionService instance = SessionService._();

  static const _sessionIdKey = 'auth_session_id';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<String> getOrCreateSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_sessionIdKey);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    final generated = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    await prefs.setString(_sessionIdKey, generated);
    return generated;
  }

  Future<void> initSession(String uid) async {
    final sessionId = await getOrCreateSessionId();
    final docRef = _firestore.collection('users').doc(uid).collection('sessions').doc(sessionId);
    final payload = await _buildSessionPayload(sessionId: sessionId);
    final existing = await docRef.get();
    if (existing.exists) {
      await docRef.set(payload..remove('createdAt'), SetOptions(merge: true));
    } else {
      await docRef.set(payload, SetOptions(merge: true));
    }
    await markCurrentSession(uid, sessionId);
  }

  Future<void> updateLastSeen(String uid) async {
    final sessionId = await getOrCreateSessionId();
    final docRef = _firestore.collection('users').doc(uid).collection('sessions').doc(sessionId);
    await docRef.set({
      'sessionId': sessionId,
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await markCurrentSession(uid, sessionId);
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

  Future<void> deleteSession({required String uid, required String sessionId}) {
    return _firestore.collection('users').doc(uid).collection('sessions').doc(sessionId).delete();
  }

  Future<void> deleteAllOtherSessions({required String uid, required String currentSessionId}) async {
    final snapshot = await _firestore.collection('users').doc(uid).collection('sessions').get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      if (doc.id == currentSessionId) continue;
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<Map<String, dynamic>> _buildSessionPayload({required String sessionId}) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final metadata = await _readDeviceMetadata();
    return {
      'sessionId': sessionId,
      'deviceName': metadata.deviceName,
      'platform': metadata.platform,
      'appVersion': '${packageInfo.version}+${packageInfo.buildNumber}',
      'deviceModel': metadata.deviceModel,
      'osVersion': metadata.osVersion,
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    };
  }

  Future<_DeviceMetadata> _readDeviceMetadata() async {
    if (kIsWeb) {
      return const _DeviceMetadata(
        deviceName: 'web browser',
        platform: 'web',
        deviceModel: 'web',
        osVersion: 'web',
      );
    }
    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      final model = info.model.trim().isEmpty ? 'android' : info.model.trim();
      return _DeviceMetadata(
        deviceName: 'android $model',
        platform: 'android',
        deviceModel: model,
        osVersion: info.version.release,
      );
    }
    if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      final model = info.utsname.machine.trim().isEmpty ? 'ios' : info.utsname.machine.trim();
      return _DeviceMetadata(
        deviceName: 'ios $model',
        platform: 'ios',
        deviceModel: model,
        osVersion: info.systemVersion,
      );
    }
    return _DeviceMetadata(
      deviceName: Platform.operatingSystem,
      platform: Platform.operatingSystem,
      deviceModel: Platform.operatingSystem,
      osVersion: Platform.operatingSystemVersion,
    );
  }
}

class _DeviceMetadata {
  const _DeviceMetadata({
    required this.deviceName,
    required this.platform,
    required this.deviceModel,
    required this.osVersion,
  });

  final String deviceName;
  final String platform;
  final String deviceModel;
  final String osVersion;
}
