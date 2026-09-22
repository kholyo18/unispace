import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../ui/settings/public_profile_service.dart';
import 'storage_upload_client.dart';

class StorageUploadService {
  static final _client = StorageUploadClient(
    currentUid: () => FirebaseAuth.instance.currentUser?.uid,
    sessionKey: () => PublicProfileService.viewerSession,
    invoke: (data) async {
      final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('prepareStorageUpload')
          .call<Map<String, dynamic>>(data);
      return Map<String, dynamic>.from(response.data);
    },
  );

  static SettableMetadata _metadata(SettableMetadata original, Map<String, String> grant) => SettableMetadata(
    contentType: original.contentType,
    cacheControl: original.cacheControl,
    contentDisposition: original.contentDisposition,
    contentEncoding: original.contentEncoding,
    contentLanguage: original.contentLanguage,
    customMetadata: {...?original.customMetadata, ...grant},
  );

  static Future<TaskSnapshot> putData(Reference ref, Uint8List bytes, SettableMetadata metadata) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return _client.upload(expectedUid: uid, path: ref.fullPath, bucket: ref.bucket,
      contentType: metadata.contentType ?? '', size: bytes.length,
      send: (grant) => ref.putData(bytes, _metadata(metadata, grant)));
  }

  static Future<TaskSnapshot> putFile(Reference ref, File file, SettableMetadata metadata) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final session = PublicProfileService.viewerSession;
    final size = await file.length();
    if (FirebaseAuth.instance.currentUser?.uid != uid || PublicProfileService.viewerSession != session) {
      throw StateError('تغيّر الحساب أثناء قراءة الملف.');
    }
    return _client.upload(expectedUid: uid, path: ref.fullPath, bucket: ref.bucket,
      contentType: metadata.contentType ?? '', size: size,
      send: (grant) => ref.putFile(file, _metadata(metadata, grant)));
  }
}
