import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../ui/settings/public_profile_service.dart';
import 'signed_upload_task.dart';
export 'signed_upload_task.dart'
    show ProtectedUploadTask, ProtectedUploadSnapshot;

class ProtectedUploadResult {
  const ProtectedUploadResult({required this.url, required this.ref});
  final String url;
  final Reference ref;
}

class StorageUploadService {
  static final _client = ProtectedUploadCoordinator(
    currentUid: () => FirebaseAuth.instance.currentUser?.uid,
    sessionKey: () => PublicProfileService.viewerSession,
    invoke: (method, data) async {
      final response =
          await FirebaseFunctions.instanceFor(region: 'europe-west1')
              .httpsCallable(method)
              .call<Map<String, dynamic>>(data);
      return Map<String, dynamic>.from(response.data);
    },
  );

  /// A canonical identifier, never a permanent download bearer token.
  static String locator(Reference ref) =>
      ProtectedUploadCoordinator.locator(ref.bucket, ref.fullPath);

  static Future<ProtectedUploadResult> putData(
      Reference ref, Uint8List bytes, SettableMetadata metadata,
      {void Function(ProtectedUploadTask)? onTask}) async {
    final receipt = await _client.upload(
        path: ref.fullPath,
        bucket: ref.bucket,
        contentType: metadata.contentType ?? '',
        size: bytes.length,
        source: () => Stream.value(bytes),
        onTask: onTask);
    return ProtectedUploadResult(url: receipt['url'] as String, ref: ref);
  }

  static Future<ProtectedUploadResult> putFile(
      Reference ref, File file, SettableMetadata metadata,
      {void Function(ProtectedUploadTask)? onTask}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final session = PublicProfileService.viewerSession;
    final size = await file.length();
    if (FirebaseAuth.instance.currentUser?.uid != uid ||
        PublicProfileService.viewerSession != session) {
      throw StateError('Account changed while reading the upload file.');
    }
    final receipt = await _client.upload(
        path: ref.fullPath,
        bucket: ref.bucket,
        contentType: metadata.contentType ?? '',
        size: size,
        source: file.openRead,
        onTask: onTask);
    return ProtectedUploadResult(url: receipt['url'] as String, ref: ref);
  }
}
