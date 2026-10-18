import '../../../services/chat_download_coordinator.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/chat_local_persistence.dart';
import '../../../services/chat_message_service.dart';
import 'chat_media_composer.dart';
import 'chat_media_send_queue.dart';
import 'chat_media_sender.dart';

final chatTransfers = ChatTransferCenter();

class ChatTransferJob {
  ChatTransferJob(this.title, this.sender, this.queue);
  bool attached = true;
  final String title;
  final ChatMediaSender sender;
  final ChatMediaSendQueue queue;
}

/// Process-level ownership: leaving a route does not dispose its pending sends.
/// Durable queues recover on reopening after Android terminates the process.
class ChatTransferCenter extends ChangeNotifier {
  ChatTransferCenter() {
    chatDownloads.addListener(_changed);
  }
  final Map<String, ChatTransferJob> _jobs = {};
  List<ChatTransferJob> get jobs => List.unmodifiable(_jobs.values);
  Timer? _timer;
  bool _retrying = false, _nativeActive = false;
  String? _session;
  ChatMediaSendQueue obtain(
      {required String chatId,
      required String title,
      required String session,
      required String Function() currentSession,
      required ChatOutbox outbox,
      ChatLocalStorage? persistence,
      required String tooLarge,
      required String tooLong,
      required String stillOnly}) {
    if (_session != session) clear();
    _session = session;
    final existing = _jobs[chatId];
    if (existing != null) {
      existing.attached = true;
      return existing.queue;
    }
    final sender = ChatMediaSender(
        chatId: chatId,
        session: session,
        currentSession: currentSession,
        outbox: outbox,
        tooLarge: tooLarge,
        tooLong: tooLong,
        stillOnly: stillOnly);
    final queue = ChatMediaSendQueue(
        send: sender.send, persistence: persistence, chatId: chatId);
    sender.queue = queue;
    _jobs[chatId] = ChatTransferJob(title, sender, queue);
    queue.addListener(_changed);
    outbox.changes.addListener(_changed);
    _timer ??=
        Timer.periodic(const Duration(seconds: 15), (_) => unawaited(_retry()));
    return queue;
  }

  Future<void> send(String chatId, ChatMediaDraft draft,
          void Function(double?) progress) =>
      _jobs[chatId]!.sender.send(draft, progress);
  Future<void> _retry() async {
    if (_retrying) return;
    _retrying = true;
    try {
      for (final job in jobs) {
        if (job.sender.currentSession() != job.sender.session) {
          clear();
          break;
        }
        await job.sender.outbox.retryTransient();
        await job.queue.retryTransient();
      }
    } catch (_) {/* Entries retain explicit recovery actions. */} finally {
      _retrying = false;
    }
  }

  void detach(String chatId) {
    final job = _jobs[chatId];
    if (job == null) return;
    job.attached = false;
    scheduleMicrotask(_prune);
  }

  void _prune() {
    for (final entry in _jobs.entries.toList()) {
      final job = entry.value;
      if (!job.attached &&
          job.queue.entries.isEmpty &&
          job.sender.outbox.entries
              .every((e) => e.state == ChatOutboxState.acknowledged)) {
        job.sender.outbox
            .observe(job.sender.outbox.entries.map((e) => e.id).toList());
        revoke(entry.key, revokeDownloads: false);
      }
    }
  }

  void _changed() {
    scheduleMicrotask(_prune);
    final active = chatDownloads.active ||
        jobs.any((job) =>
            job.queue.entries.any((entry) => entry.sending) ||
            job.sender.outbox.entries
                .any((entry) => entry.state == ChatOutboxState.sending));
    if (active != _nativeActive) {
      _nativeActive = active;
      if (Platform.isAndroid)
        unawaited(const MethodChannel('unispace/chat_transfers')
            .invokeMethod<void>('setActive', active)
            .catchError((Object _) {}));
    }
    notifyListeners();
  }

  Future<void> cancel(ChatTransferJob job, ChatMediaSendEntry entry) async {
    if (entry.draft.queuedId != null) return;
    job.queue.discard(entry);
    await job.sender.cancel(entry.draft);
  }

  void retry(ChatTransferJob job, ChatMediaSendEntry entry) {
    job.sender.allowRetry(entry.draft);
    job.queue.retry(entry);
  }

  void revoke(String chatId, {bool revokeDownloads = true}) {
    final job = _jobs.remove(chatId);
    if (job == null) return;
    if (revokeDownloads)
      unawaited(chatDownloads.revokeScope('${job.sender.session}/$chatId'));
    job.sender.close();
    job.sender.outbox.changes.removeListener(_changed);
    job.queue.removeListener(_changed);
    job.queue.dispose();
    _changed();
  }

  void clear() {
    unawaited(chatDownloads.clear());
    for (final id in _jobs.keys.toList()) {
      revoke(id);
    }
    _timer?.cancel();
    _timer = null;
    _session = null;
  }
}

class ChatTransferCenterPage extends StatelessWidget {
  const ChatTransferCenterPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(mediaText(context, 'النقل والتنزيلات',
                'Transfers and downloads', 'Transferts et téléchargements'))),
        body: AnimatedBuilder(
            animation: chatTransfers,
            builder: (context, _) {
              final rows = <Widget>[];
              for (final job in chatTransfers.jobs) {
                if (job.sender.currentSession() != job.sender.session) continue;
                for (final entry in job.queue.entries) {
                  rows.add(Card(
                      child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(job.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(entry.draft.video
                                        ? Icons.videocam_outlined
                                        : Icons.image_outlined),
                                    title: Text(entry.error != null
                                        ? mediaText(context, 'تعذر الإرسال',
                                            'Send failed', 'Échec de l’envoi')
                                        : mediaText(context, 'جارٍ الإرسال',
                                            'Sending', 'Envoi en cours')),
                                    trailing: Wrap(children: [
                                      if (entry.error != null)
                                        IconButton(
                                            tooltip: mediaText(
                                                context,
                                                'إعادة المحاولة',
                                                'Retry',
                                                'Réessayer'),
                                            icon: const Icon(Icons.refresh),
                                            onPressed: () => chatTransfers
                                                .retry(job, entry)),
                                      IconButton(
                                          tooltip: mediaText(context, 'إلغاء',
                                              'Cancel', 'Annuler'),
                                          icon: const Icon(Icons.close),
                                          onPressed: () => unawaited(
                                              chatTransfers.cancel(job, entry)))
                                    ])),
                                if (entry.sending)
                                  LinearProgressIndicator(
                                      value: entry.progress),
                              ]))));
                }
                for (final entry in job.sender.outbox.entries
                    .where((e) => e.state != ChatOutboxState.acknowledged)) {
                  rows.add(ListTile(
                      title: Text(job.title),
                      subtitle: Text(entry.state == ChatOutboxState.failed
                          ? mediaText(context, 'تعذر إرسال الرسالة',
                              'Message failed', 'Échec du message')
                          : mediaText(context, 'جارٍ إرسال الرسالة',
                              'Sending message', 'Envoi du message')),
                      trailing: entry.state == ChatOutboxState.failed
                          ? Wrap(children: [
                              IconButton(
                                  tooltip: mediaText(context, 'إعادة المحاولة',
                                      'Retry', 'Réessayer'),
                                  onPressed: () =>
                                      job.sender.outbox.retry(entry.id),
                                  icon: const Icon(Icons.refresh)),
                              IconButton(
                                  tooltip: mediaText(
                                      context, 'إزالة', 'Remove', 'Retirer'),
                                  onPressed: () =>
                                      job.sender.outbox.removeFailed(entry.id),
                                  icon: const Icon(Icons.close))
                            ])
                          : null));
                }
              }
              for (final job
                  in chatDownloads.jobs.where((job) => job.current())) {
                rows.add(Card(
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(job.name,
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                              if (job.status == ChatDownloadStatus.downloading)
                                LinearProgressIndicator(value: job.progress),
                              Wrap(children: [
                                if (job.status !=
                                    ChatDownloadStatus.downloading)
                                  TextButton.icon(
                                      onPressed: () async {
                                        await chatDownloads.dismiss(job.id);
                                      },
                                      icon: const Icon(Icons.delete_outline),
                                      label: Text(mediaText(
                                          context,
                                          'إزالة من التنزيلات',
                                          'Remove download',
                                          'Supprimer le téléchargement'))),
                                if (job.status ==
                                    ChatDownloadStatus.downloading)
                                  TextButton.icon(
                                      onPressed: () =>
                                          chatDownloads.cancel(job.id),
                                      icon: const Icon(Icons.close),
                                      label: Text(mediaText(context, 'إلغاء',
                                          'Cancel', 'Annuler'))),
                                if (job.status == ChatDownloadStatus.failed ||
                                    job.status == ChatDownloadStatus.cancelled)
                                  TextButton.icon(
                                      onPressed: () async {
                                        try {
                                          await chatDownloads.retry(job.id);
                                        } catch (_) {}
                                      },
                                      icon: const Icon(Icons.refresh),
                                      label: Text(mediaText(
                                          context,
                                          'إعادة المحاولة',
                                          'Retry',
                                          'Réessayer'))),
                                if (job.status == ChatDownloadStatus.complete &&
                                    job.file != null)
                                  TextButton.icon(
                                      onPressed: () async {
                                        if (job.current())
                                          await OpenFilex.open(job.file!.path);
                                      },
                                      icon: const Icon(Icons.open_in_new),
                                      label: Text(mediaText(
                                          context, 'فتح', 'Open', 'Ouvrir'))),
                              ]),
                            ]))));
              }
              if (rows.isEmpty)
                return Center(
                    child: Text(mediaText(context, 'لا توجد عمليات نقل',
                        'No transfers', 'Aucun transfert')));
              return ListView(
                  padding: const EdgeInsets.all(12), children: rows);
            }),
      );
}
