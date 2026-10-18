import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../ui/settings/public_profile_service.dart';

/// Documents use short-lived, exact-object signed capabilities. Storage rules
/// remain closed for arbitrary file writes; no permanent download token is used.
class ChatDocumentService {
  static FirebaseFunctions get _functions => FirebaseFunctions.instanceFor(region: 'europe-west1');
  static String _session() => '${FirebaseAuth.instance.currentUser?.uid}:${PublicProfileService.viewerSession}';
  static void _guard(String session) {
    if (FirebaseAuth.instance.currentUser == null || session != _session()) {
      throw StateError('The account changed.');
    }
  }
  static Uri _signedUri(Object? value) {
    final uri = Uri.tryParse(value is String ? value : '');
    if (uri == null || uri.scheme != 'https' || uri.userInfo.isNotEmpty ||
        !(uri.host == 'storage.googleapis.com' || uri.host.endsWith('.storage.googleapis.com'))) {
      throw const FormatException('Invalid attachment URL');
    }
    return uri;
  }
  static Future<String> upload({required String path, required Uint8List bytes}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final session = _session();
    if (uid == null || bytes.isEmpty || bytes.length > 20 * 1024 * 1024) {
      throw StateError('Invalid document or session.');
    }
    final result = (await _functions.httpsCallable('prepareChatDocumentUpload').call<Map<String,dynamic>>({
      'expectedUid':uid,'path':path,'contentType':'application/octet-stream','size':bytes.length,
    })).data;
    _guard(session);
    if (result['path'] != path || result['size'] != bytes.length || result['uid'] != uid || result['fileUrl'] is! String) {
      throw const FormatException('Invalid upload confirmation');
    }
    final target = _signedUri(result['uploadUrl']);
    final client = HttpClient()..connectionTimeout = const Duration(seconds:20);
    try {
      final request = await client.putUrl(target);
      request.contentLength = bytes.length;
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/octet-stream');
      request.headers.set('x-goog-if-generation-match', '0');
      _guard(session);
      request.add(bytes);
      final response = await request.close().timeout(const Duration(minutes:2));
      await response.drain<void>();
      if (response.statusCode < 200 || response.statusCode >= 300) throw HttpException('Document upload failed (${response.statusCode})');
      _guard(session);
      return result['fileUrl'] as String;
    } finally { client.close(force:true); }
  }
  static Future<String> downloadUrl({required String chatId, required String messageId}) async {
    final session = _session();
    _guard(session);
    final result = (await _functions.httpsCallable('readChatDocumentDownload').call<Map<String,dynamic>>({'chatId':chatId,'messageId':messageId})).data;
    _guard(session);
    return _signedUri(result['url']).toString();
  }
}
