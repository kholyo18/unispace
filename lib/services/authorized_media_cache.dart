import 'dart:convert';
import 'package:crypto/crypto.dart';

/// A byte-cache identity, never an authorization decision. Call only AFTER a
/// fresh server authorization; include the immutable Storage object generation.
String authorizedMediaCacheKey(String signedUrl, String viewer) {
  final uri = Uri.tryParse(signedUrl);
  final generation = uri?.queryParameters['generation'];
  final storageHost = uri?.host == 'storage.googleapis.com' ||
      (uri?.host.endsWith('.storage.googleapis.com') ?? false);
  final identity = uri?.scheme == 'https' && storageHost &&
          generation != null && RegExp(r'^\d+$').hasMatch(generation)
      ? '${uri!.origin}${uri.path}?generation=$generation'
      : signedUrl;
  return sha256.convert(utf8.encode(jsonEncode([viewer, identity]))).toString();
}
