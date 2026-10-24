import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_links.dart';

class ReleasePolicy {
  const ReleasePolicy({required this.enabled, required this.minimumBuild});
  final bool enabled;
  final int minimumBuild;

  factory ReleasePolicy.fromMap(Map<String, dynamic> data) {
    final minimum = data['minimumBuild'];
    if (data['enabled'] is! bool ||
        minimum is! int ||
        minimum < 1 ||
        data['storeUrl'] != AppLinks.storeUrl) {
      throw const FormatException('Invalid release policy');
    }
    return ReleasePolicy(
        enabled: data['enabled'] as bool, minimumBuild: minimum);
  }

  bool allows(int build) => !enabled || build >= minimumBuild;

  static Future<ReleasePolicy> fetch() async {
    final client = http.Client();
    try {
      return await fetchFrom(client,
          projectId: Firebase.app().options.projectId);
    } finally {
      client.close();
    }
  }

  /// This endpoint deliberately exposes only public version metadata. Avoid
  /// waiting for Auth/App Check tokens before the sign-in screen can mount.
  /// Authenticated media and session requests still use the Firebase SDK.
  static Future<ReleasePolicy> fetchFrom(http.Client client,
      {required String projectId}) async {
    if (!RegExp(r'^[a-z][a-z0-9-]+$').hasMatch(projectId)) {
      throw const FormatException('Invalid Firebase project');
    }
    final request = http.Request(
        'POST',
        Uri.https(
            'europe-west1-$projectId.cloudfunctions.net', '/readReleasePolicy'))
      ..followRedirects = false
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({'data': <String, dynamic>{}});
    final response = await (() async =>
            http.Response.fromStream(await client.send(request)))()
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw FirebaseFunctionsException(message: 'Release service unavailable',
          code: switch (response.statusCode) {
        404 => 'not-found',
        401 => 'unauthenticated',
        403 => 'permission-denied',
        _ => 'unavailable',
      });
    }
    final data = jsonDecode(response.body);
    if (data is! Map || data['result'] is! Map) {
      throw const FormatException('Invalid release response');
    }
    return ReleasePolicy.fromMap(
        Map<String, dynamic>.from(data['result'] as Map));
  }

  static Future<int> installedBuild() async {
    final raw = (await PackageInfo.fromPlatform()).buildNumber;
    final build = int.tryParse(raw);
    if (!RegExp(r'^[0-9]+$').hasMatch(raw) || build == null || build < 1) {
      throw const FormatException('Invalid installed build');
    }
    return build;
  }

  static Future<bool> openStore() => launchUrl(Uri.parse(AppLinks.storeUrl),
      mode: LaunchMode.externalApplication);
}


