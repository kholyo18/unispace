import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/security_audit.dart';

class SecurityAuditService {
  SecurityAuditService._();

  static final SecurityAuditService instance = SecurityAuditService._();
  static const _prefsPrefix = 'security_audit_last_password_change_';

  Future<SecurityAudit?> loadLastPasswordChange() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('securityAudit').doc('lastPasswordChange').get();
      final data = snapshot.data();
      if (data != null) return SecurityAudit.fromJson(data);
    } catch (_) {
      // Fall back to local cache when Firestore is unavailable.
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefsPrefix${user.uid}');
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return SecurityAudit.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<SecurityAudit> buildAuditRecord() async {
    final now = DateTime.now();
    final deviceInfo = await _deviceInfo();
    final packageInfo = await PackageInfo.fromPlatform();
    final networkType = await _networkType();
    final ip = await _resolvePublicIp();

    return SecurityAudit(
      timestampUtc: now.toUtc(),
      timezoneOffsetMinutes: now.timeZoneOffset.inMinutes,
      deviceManufacturer: deviceInfo.$1,
      deviceModel: deviceInfo.$2,
      deviceName: deviceInfo.$3,
      osName: deviceInfo.$4,
      osVersion: deviceInfo.$5,
      appVersion: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      ipAddress: ip,
      networkType: networkType,
      locationApprox: null,
    );
  }

  Future<void> saveLastPasswordChange(SecurityAudit audit) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    var firestoreSaved = false;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('securityAudit')
          .doc('lastPasswordChange')
          .set(audit.toJson(), SetOptions(merge: true));
      firestoreSaved = true;
    } catch (_) {
      // Keep local fallback below.
    }

    if (!firestoreSaved) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefsPrefix${user.uid}', jsonEncode(audit.toJson()));
    }
  }

  Future<(String?, String?, String?, String?, String?)> _deviceInfo() async {
    final plugin = DeviceInfoPlugin();
    try {
      if (kIsWeb) return (null, null, null, 'Web', null);
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        return (info.manufacturer, info.model, info.product, 'Android', info.version.release);
      }
      if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        return ('Apple', info.utsname.machine, info.name, 'iOS', info.systemVersion);
      }
      if (Platform.isMacOS) {
        final info = await plugin.macOsInfo;
        return ('Apple', info.model, info.computerName, 'macOS', info.osRelease);
      }
      if (Platform.isWindows) {
        final info = await plugin.windowsInfo;
        return (null, info.productName, info.computerName, 'Windows', info.displayVersion);
      }
      if (Platform.isLinux) {
        final info = await plugin.linuxInfo;
        return (null, info.name, info.prettyName, 'Linux', info.version);
      }
    } catch (_) {
      return (null, null, null, null, null);
    }
    return (null, null, null, null, null);
  }

  Future<String> _networkType() async {
    try {
      final result = await Connectivity().checkConnectivity();
      if (result.contains(ConnectivityResult.wifi)) return 'wifi';
      if (result.contains(ConnectivityResult.mobile)) return 'cellular';
    } catch (_) {
      return 'unknown';
    }
    return 'unknown';
  }

  Future<String?> _resolvePublicIp() async {
    // TEMP: fallback public endpoint until a dedicated backend endpoint is available.
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      final request = await client.getUrl(Uri.parse('https://api64.ipify.org?format=json'));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final map = jsonDecode(body) as Map<String, dynamic>;
      return map['ip'] as String?;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
