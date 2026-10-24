import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../ui/settings/public_profile_service.dart';

class ProtectedMediaGrant {
  const ProtectedMediaGrant(this.url, this.scope);
  final String url;
  final String scope;
}

/// A fresh server check for each resolution. Only in-flight work is shared.
class ProtectedMediaService {
  ProtectedMediaService(
      {required this.currentUid,
      required this.viewerSession,
      required this.read,
      DateTime Function()? now})
      : now = now ?? DateTime.now;
  final String? Function() currentUid, viewerSession;
  final Future<Object?> Function(String url) read;
  final DateTime Function() now;
  final Map<(String, String), Future<ProtectedMediaGrant>> _pending = {};
  static final instance = ProtectedMediaService(
    currentUid: () =>
        Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser?.uid,
    viewerSession: () =>
        Firebase.apps.isEmpty ? null : PublicProfileService.viewerSession,
    read: (url) async => (await FirebaseFunctions.instanceFor(
                region: 'europe-west1')
            .httpsCallable('readProtectedMedia',
                options:
                    HttpsCallableOptions(timeout: const Duration(seconds: 15)))
            .call({'url': url}))
        .data,
  );
  String get scope => '${currentUid() ?? ''}|${viewerSession() ?? ''}';

  static bool isSignedGcs(Uri uri) =>
      uri.scheme == 'https' &&
      (uri.host == 'storage.googleapis.com' ||
          uri.host.endsWith('.storage.googleapis.com')) &&
      (uri.queryParameters.containsKey('X-Goog-Signature') ||
          (uri.queryParameters.containsKey('GoogleAccessId') &&
              uri.queryParameters.containsKey('Signature')));
  static bool needsAuthorization(Uri uri) =>
      uri.scheme == 'gs' ||
      uri.host == 'firebasestorage.googleapis.com' ||
      ((uri.host == 'storage.googleapis.com' ||
              uri.host.endsWith('.storage.googleapis.com')) &&
          !isSignedGcs(uri));

  Future<ProtectedMediaGrant> resolve(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.userInfo.isNotEmpty ||
        (uri.scheme != 'https' && uri.scheme != 'gs') ||
        uri.host.isEmpty) {
      throw StateError('Invalid media address');
    }
    final captured = scope;
    if (!needsAuthorization(uri)) return ProtectedMediaGrant(url, captured);
    if (currentUid() == null || viewerSession() == null) {
      throw StateError('Authentication required');
    }
    final key = (captured, url);
    final existing = _pending[key];
    if (existing != null) return existing;
    final operation = _resolve(url, captured);
    _pending[key] = operation;
    try {
      return await operation;
    } finally {
      if (identical(_pending[key], operation)) _pending.remove(key);
    }
  }

  Future<ProtectedMediaGrant> _resolve(String url, String captured) async {
    final data = await read(url);
    if (scope != captured) throw StateError('Media session changed');
    if (data is! Map || data['url'] is! String || data['expiresAt'] is! num) {
      throw StateError('Invalid media authorization');
    }
    final signed = Uri.tryParse(data['url'] as String);
    final expiry = data['expiresAt'] as num;
    if (signed == null ||
        !isSignedGcs(signed) ||
        signed.userInfo.isNotEmpty ||
        !expiry.isFinite ||
        expiry <= now().millisecondsSinceEpoch) {
      throw StateError('Invalid media authorization');
    }
    return ProtectedMediaGrant(signed.toString(), captured);
  }
}
