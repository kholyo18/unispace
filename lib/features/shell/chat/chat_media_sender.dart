import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import '../../../services/chat_message_service.dart';
import '../../../services/storage_upload_service.dart';
import '../../../services/chat_view_once_service.dart';
import '../../../services/chat_video_edit_service.dart';
import '../../../services/chat_media_format.dart';
import 'chat_media_composer.dart';
import 'chat_media_send_queue.dart';
import 'photo_edit_model.dart';

/// Owns transfer state independently of a conversation's widget lifecycle.
class ChatMediaSender {
  ChatMediaSender(
      {required this.chatId,
      required this.session,
      required this.currentSession,
      required this.outbox,
      required this.tooLarge,
      required this.tooLong,
      required this.stillOnly});
  final String chatId, session, tooLarge, tooLong, stillOnly;
  final String Function() currentSession;
  final ChatOutbox outbox;
  late ChatMediaSendQueue queue;
  bool closed = false;
  final tasks = <ChatMediaDraft, ProtectedUploadTask>{};
  final cancelled = <ChatMediaDraft>{};
  Future<void> authorize() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final doc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .get(const GetOptions(source: Source.server));
    final data = doc.data();
    if (closed ||
        currentSession() != session ||
        uid == null ||
        !(data?['memberIds'] as List? ?? []).contains(uid))
      throw StateError('Conversation unavailable');
    if (data?['adminsOnlyMessaging'] == true &&
        !(data?['adminIds'] as List? ?? []).contains(uid))
      throw StateError('Posting unavailable');
  }

  Future<bool> observed(String id) async => (await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(id)
          .get(const GetOptions(source: Source.server)))
      .exists;
  Future<void> cancel(ChatMediaDraft draft) async {
    cancelled.add(draft);
    await tasks.remove(draft)?.cancel();
  }

  void allowRetry(ChatMediaDraft draft) {
    cancelled.remove(draft);
  }

  void close() {
    closed = true;
    for (final task in tasks.values) {
      unawaited(task.cancel());
    }
    tasks.clear();
  }

  Future<void> send(
      ChatMediaDraft draft, void Function(double?) progress) async {
    try {
      await _send(draft, progress);
    } finally {
      tasks.remove(draft);
      cancelled.remove(draft);
    }
  }

  Future<void> _send(
      ChatMediaDraft draft, void Function(double?) progress) async {
    void guard() {
      if (closed || session != currentSession() || cancelled.contains(draft)) {
        throw StateError('Conversation session changed');
      }
    }

    guard();
    await authorize();
    guard();
    if (draft.queuedId != null) {
      if (await observed(draft.queuedId!)) return;
      final sent = await outbox.attempt(draft.queuedId!);
      guard();
      if (!sent && !(await observed(draft.queuedId!))) {
        throw StateError('Message send failed');
      }
      return;
    }
    final stableMessageId = queue.messageIdFor(draft);
    if (stableMessageId != null && await observed(stableMessageId)) return;
    final id = draft.mediaId ??=
        FirebaseFirestore.instance.collection('chats').doc().id;
    if (draft.uploadUrl == null) {
      if (!draft.video && !draft.prepared) {
        final prepared = await prepareChatPhoto(draft.file, hd: draft.hd);
        if (prepared.path != draft.file.path) draft.generated.add(prepared);
        guard();
        draft.file = prepared;
        draft.prepared = true;
      }
      final size = await draft.file.length();
      if (size <= 0 || size >= (draft.viewOnce ? 20 : 40) * 1024 * 1024) {
        throw MediaSendException(tooLarge);
      }
      final format = draft.video
          ? detectChatVideoFormat(draft.file.path)
          : detectChatImageFormat(
              await draft.file.readAsBytes(), draft.file.path);
      guard();
      if (draft.video && Platform.isAndroid) {
        final metadata = await const MethodChannel('unispace/video_editor')
            .invokeMapMethod<String, dynamic>(
                'metadata', {'path': draft.file.path});
        if ((metadata?['durationMs'] as num? ?? 0) > 60000) {
          throw MediaSendException(tooLong);
        }
      }
      if (draft.viewOnce) {
        if (draft.video ||
            !['image/jpeg', 'image/png', 'image/webp']
                .contains(format.contentType)) {
          throw MediaSendException(stillOnly);
        }
        await ChatViewOnceService.upload(
            chatId: chatId,
            mediaId: id,
            file: draft.file,
            contentType: format.contentType,
            progress: progress);
        draft.uploadUrl = 'private';
      } else {
        final ref = FirebaseStorage.instance.ref(
            'chats/${chatId}/${draft.video ? 'videos' : 'images'}/$id.${format.extension}');
        StreamSubscription<ProtectedUploadSnapshot>? uploadSub;
        try {
          await StorageUploadService.putFile(ref, draft.file,
              SettableMetadata(contentType: format.contentType),
              onTask: (task) {
            tasks[draft] = task;
            if (closed || cancelled.contains(draft)) unawaited(task.cancel());
            uploadSub = task.snapshotEvents.listen(
                (s) => progress(s.totalBytes > 0
                    ? s.bytesTransferred / s.totalBytes
                    : null),
                onError: (Object _) {});
          });
          guard();
          draft.uploadUrl = StorageUploadService.locator(ref);
        } finally {
          await uploadSub?.cancel();
        }
        if (draft.video && Platform.isAndroid) {
          try {
            final thumbPath =
                await const ChatVideoEditService().thumbnail(draft.file.path);
            if (thumbPath != null) {
              final thumb = File(thumbPath);
              draft.generated.add(thumb);
              final thumbRef = FirebaseStorage.instance
                  .ref('chats/${chatId}/images/${id}_thumb.jpg');
              guard();
              await StorageUploadService.putFile(
                  thumbRef, thumb, SettableMetadata(contentType: 'image/jpeg'),
                  onTask: (task) {
                tasks[draft] = task;
                if (closed || cancelled.contains(draft))
                  unawaited(task.cancel());
              });
              draft.thumbnailUrl = StorageUploadService.locator(thumbRef);
            }
          } catch (_) {
            /* A thumbnail failure must not discard an uploaded video. */
          }
        }
      }
    }
    guard();
    final size = await draft.file.length();
    final isGif =
        !draft.video && draft.file.path.toLowerCase().endsWith('.gif');
    await queue.checkpoint(draft);
    guard();
    final entry =
        outbox.enqueue(chatId: chatId, messageId: stableMessageId, message: {
      'type': draft.viewOnce
          ? 'viewOnce'
          : draft.video
              ? 'video'
              : isGif
                  ? 'gif'
                  : 'image',
      if (draft.viewOnce)
        'mediaId': id
      else if (draft.video)
        'videoUrl': draft.uploadUrl!
      else if (isGif)
        'gifUrl': draft.uploadUrl!
      else
        'imageUrl': draft.uploadUrl!,
      if (!draft.viewOnce) 'size': size,
      if (!draft.viewOnce && draft.caption.trim().isNotEmpty)
        'caption': draft.caption.trim(),
      if (!draft.viewOnce && draft.thumbnailUrl != null)
        'thumbnailUrl': draft.thumbnailUrl!,
    });
    await outbox.flush();
    draft.queuedId = entry.id;
    await queue.checkpoint(draft);
    final sent = await outbox.attempt(entry.id);
    guard();
    if (!sent && !(await observed(entry.id))) {
      throw StateError('Message send failed');
    }
    tasks.remove(draft);
  }
}
