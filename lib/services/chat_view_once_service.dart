import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../ui/settings/public_profile_service.dart';

class ChatViewOnceService {
  static String _session() =>
      '${FirebaseAuth.instance.currentUser?.uid}:${PublicProfileService.viewerSession}';
  static void _guard(String session) {
    if (FirebaseAuth.instance.currentUser == null || session != _session())
      throw StateError('Session changed');
  }

  static Future<void> upload(
      {required String chatId,
      required String mediaId,
      required File file,
      required String contentType,
      void Function(double?)? progress}) async {
    final session = _session();
    _guard(session);
    final size = await file.length();
    if (size <= 0 || size > 20 * 1024 * 1024)
      throw StateError('Photo exceeds20MB');
    final result = (await FirebaseFunctions.instanceFor(region: 'europe-west1')
            .httpsCallable('prepareChatViewOnceUpload')
            .call<Map<String, dynamic>>({
      'chatId': chatId,
      'mediaId': mediaId,
      'size': size,
      'contentType': contentType
    }))
        .data;
    _guard(session);
    final target = Uri.parse(result['uploadUrl'] as String);
    if (target.scheme != 'https' ||
        target.userInfo.isNotEmpty ||
        !(target.host == 'storage.googleapis.com' ||
            target.host.endsWith('.storage.googleapis.com')))
      throw const FormatException('Invalid upload URL');
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      final request = await client.putUrl(target);
      request.followRedirects = false;
      request.contentLength = size;
      request.headers.set(HttpHeaders.contentTypeHeader, contentType);
      request.headers.set('x-goog-if-generation-match', '0');
      var sent = 0;
      await request.addStream(file.openRead().map((chunk) {
        _guard(session);
        sent += chunk.length;
        progress?.call(sent / size);
        return chunk;
      }));
      final response =
          await request.close().timeout(const Duration(minutes: 2));
      await response.drain<void>();
      if (response.statusCode == 412) {
        // A previous PUT may have succeeded while its acknowledgement was lost.
        final confirmed =
            (await FirebaseFunctions.instanceFor(region: 'europe-west1')
                    .httpsCallable('confirmChatViewOnceUpload')
                    .call<Map<String, dynamic>>(
                        {'chatId': chatId, 'mediaId': mediaId}))
                .data;
        if (confirmed['uploaded'] != true)
          throw const FormatException('Invalid upload confirmation');
      } else if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const HttpException('Photo upload failed');
      }
      _guard(session);
    } finally {
      client.close(force: true);
    }
  }

  /// Single authorized response, never a reusable download URL or disk cache.
  static Future<Uint8List> consume(
      {required String chatId, required String messageId}) async {
    final session = _session();
    _guard(session);
    final token = await FirebaseAuth.instance.currentUser!.getIdToken();
    _guard(session);
    final project = Firebase.app().options.projectId;
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      final request = await client.postUrl(Uri.https(
          'europe-west1-$project.cloudfunctions.net',
          '/consumeChatViewOncePhoto'));
      request.followRedirects = false;
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'chatId': chatId, 'messageId': messageId}));
      final response =
          await request.close().timeout(const Duration(seconds: 45));
      if (response.statusCode != 200) {
        await response.drain<void>();
        throw StateError('Photo unavailable (${response.statusCode})');
      }
      final bytes = BytesBuilder(copy: false);
      var count = 0;
      await for (final chunk in response.timeout(const Duration(seconds: 30))) {
        _guard(session);
        count += chunk.length;
        if (count > 20 * 1024 * 1024) throw StateError('Photo too large');
        bytes.add(chunk);
      }
      _guard(session);
      return bytes.takeBytes();
    } finally {
      client.close(force: true);
    }
  }
}
