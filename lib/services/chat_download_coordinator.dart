import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'attachment_download.dart';
import 'chat_attachment_input.dart' show chatDocumentMaxBytes;
import 'chat_document_service.dart';

enum ChatDownloadStatus { downloading, complete, failed, cancelled }

class ChatDownloadSource {
  const ChatDownloadSource(this.url,
      {this.maxBytes = 40 * 1024 * 1024, this.expectedBytes});
  final Uri url;
  final int maxBytes;
  final int? expectedBytes;
}

class ChatDownloadJob {
  ChatDownloadJob(this.id, this.scope, this.session, this.chatId,
      this.messageId, this.name, this.current);
  final String id, scope, session, chatId, messageId, name;
  final bool Function() current;
  ChatDownloadStatus status = ChatDownloadStatus.downloading;
  double? progress;
  File? file;
  Object? error;
  HttpClient? _client;
  Future<File>? _pending;
  bool _cancelled = false;
}

typedef ChatDownloadResolver = Future<ChatDownloadSource> Function(
    String chatId, String messageId);
final chatDownloads = ChatDownloadCoordinator();

/// Owns only fresh temporary download directories, never drafts or queued sends.
class ChatDownloadCoordinator extends ChangeNotifier {
  ChatDownloadCoordinator(
      {ChatDownloadResolver? resolve,
      Future<Directory> Function()? temporaryDirectory})
      : _resolve = resolve ?? _resolveServer,
        _directory = temporaryDirectory ?? getTemporaryDirectory;
  final ChatDownloadResolver _resolve;
  final Future<Directory> Function() _directory;
  final Map<String, ChatDownloadJob> _jobs = {};
  List<ChatDownloadJob> get jobs => List.unmodifiable(_jobs.values);
  bool get active =>
      _jobs.values.any((j) => j.status == ChatDownloadStatus.downloading);
  static Future<ChatDownloadSource> _resolveServer(
      String chatId, String messageId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Sign in required');
    final ref = FirebaseFirestore.instance.collection('chats').doc(chatId);
    final chat =
        (await ref.get(const GetOptions(source: Source.server))).data();
    if (!(chat?['memberIds'] as List? ?? []).contains(uid) ||
        chat?['deletedBy_$uid'] == true)
      throw StateError('Conversation unavailable');
    final data = (await ref
            .collection('messages')
            .doc(messageId)
            .get(const GetOptions(source: Source.server)))
        .data();
    if (data == null ||
        data['deleted'] == true ||
        data['isDeleted'] == true ||
        data['deletedAt'] != null ||
        data['viewOnce'] == true) throw StateError('Attachment unavailable');
    final hidden = data['hiddenBy'];
    final cleared =
        chat?['clearedAt'] is Map ? (chat!['clearedAt'] as Map)[uid] : null;
    final created = data['createdAt'];
    if ((hidden is Map && hidden[uid] == true) ||
        (hidden is List && hidden.contains(uid)) ||
        data['deletedForEveryone'] == true ||
        (cleared != null &&
            (cleared is! Timestamp ||
                created is! Timestamp ||
                !created.toDate().isAfter(cleared.toDate())))) {
      throw StateError('Attachment unavailable');
    }
    final type = data['type'];
    final field = switch (type) {
      'image' => 'imageUrl',
      'gif' => 'gifUrl',
      'video' => 'videoUrl',
      'audio' => 'audioUrl',
      'file' => 'fileUrl',
      _ => ''
    };
    if (field.isEmpty) throw StateError('Attachment unavailable');
    final raw = type == 'file'
        ? await ChatDocumentService.downloadUrl(
            chatId: chatId, messageId: messageId)
        : data[field];
    final uri = Uri.tryParse(raw is String ? raw : '');
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        !(uri.host == 'firebasestorage.googleapis.com' ||
            uri.host == 'storage.googleapis.com' ||
            uri.host.endsWith('.storage.googleapis.com')))
      throw const FormatException('Invalid media URL');
    final maxBytes = type == 'file' ? chatDocumentMaxBytes : 40 * 1024 * 1024;
    final size = data['size'];
    if (size != null &&
        (size is! num ||
            !size.isFinite ||
            size <= 0 ||
            size > maxBytes ||
            size != size.toInt())) {
      throw const FormatException('Invalid attachment size');
    }
    return ChatDownloadSource(uri,
        maxBytes: maxBytes, expectedBytes: (size as num?)?.toInt());
  }

  Future<File> start(
      {required String scope,
      required String session,
      required String chatId,
      required String messageId,
      required String name,
      required bool Function() isCurrentSession}) {
    final id = '$scope/$messageId';
    final previous = _jobs[id];
    if (previous?._pending != null) return previous!._pending!;
    if (!isCurrentSession() || session.isEmpty)
      return Future.error(StateError('Session changed'));
    if (_jobs.values
                .where((j) => j.status == ChatDownloadStatus.downloading)
                .length >=
            2 ||
        (_jobs.length >= 24 && previous == null))
      return Future.error(StateError('Download queue is full'));
    final job = ChatDownloadJob(
        id, scope, session, chatId, messageId, name, isCurrentSession);
    _jobs[id] = job;
    job._pending = _run(job, previous?.file);
    return job._pending!;
  }

  Future<File> retry(String id) {
    final job = _jobs[id];
    if (job == null) return Future.error(StateError('Download unavailable'));
    return start(
        scope: job.scope,
        session: job.session,
        chatId: job.chatId,
        messageId: job.messageId,
        name: job.name,
        isCurrentSession: job.current);
  }

  void _guard(ChatDownloadJob job) {
    if (job._cancelled || !job.current() || !identical(_jobs[job.id], job))
      throw StateError('Download cancelled');
  }

  Future<void> _delete(File? file) async {
    if (file != null && await file.parent.exists())
      await file.parent.delete(recursive: true);
  }

  Future<File> _run(ChatDownloadJob job, File? previous) async {
    File? saved;
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    job._client = client;
    final timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!job.current() || job._cancelled) client.close(force: true);
    });
    notifyListeners();
    try {
      await _delete(previous);
      _guard(job);
      final source = await _resolve(job.chatId, job.messageId);
      _guard(job);
      final request = await client.getUrl(source.url);
      request.followRedirects = false;
      final response =
          await request.close().timeout(const Duration(seconds: 45));
      if (response.statusCode != 200 ||
          response.contentLength > source.maxBytes)
        throw const HttpException('Download unavailable');
      final total = response.contentLength > 0 ? response.contentLength : null;
      saved = await streamDownloadedAttachment(
          await _directory(), job.name, response,
          maxBytes: source.maxBytes,
          expectedBytes: source.expectedBytes ?? total, onProgress: (bytes) {
        _guard(job);
        final progress = total == null ? null : bytes / total;
        if (progress != null &&
            (job.progress == null ||
                (progress * 100).floor() != (job.progress! * 100).floor())) {
          job.progress = progress;
          notifyListeners();
        }
      });
      _guard(job);
      await _resolve(job.chatId, job.messageId);
      _guard(job);
      job.file = saved;
      job.status = ChatDownloadStatus.complete;
      return saved;
    } catch (error) {
      await _delete(saved);
      job.error = error;
      job.status = job._cancelled || !job.current()
          ? ChatDownloadStatus.cancelled
          : ChatDownloadStatus.failed;
      rethrow;
    } finally {
      timer.cancel();
      client.close(force: true);
      job._client = null;
      job._pending = null;
      notifyListeners();
    }
  }

  void cancel(String id) {
    final job = _jobs[id];
    if (job == null) return;
    job._cancelled = true;
    job._client?.close(force: true);
    job.status = ChatDownloadStatus.cancelled;
    notifyListeners();
  }

  Future<void> revokeScope(String scope) async {
    for (final job in jobs.where((j) => j.scope == scope)) {
      cancel(job.id);
      _jobs.remove(job.id);
      try {
        await job._pending;
      } catch (_) {}
      await _delete(job.file);
    }
    notifyListeners();
  }

  Future<void> dismiss(String id) async {
    final job = _jobs[id];
    if (job == null || job.status == ChatDownloadStatus.downloading) return;
    _jobs.remove(id);
    await _delete(job.file);
    notifyListeners();
  }

  Future<void> clear() async {
    for (final scope in jobs.map((j) => j.scope).toSet()) {
      await revokeScope(scope);
    }
  }
}
