import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../services/chat_local_persistence.dart';
import 'chat_media_composer.dart';

class ChatMediaSendEntry {
  ChatMediaSendEntry(this.draft, {String? id}) : id = id ?? _newId();
  static String _newId() {
    final random = Random.secure();
    return List.generate(
            20, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
  }

  final String id;
  final ChatMediaDraft draft;
  String? persistedPath;
  bool sending = false;
  bool cancelRequested = false;
  Object? error;
  double? progress;
  int attempts = 0;
  DateTime? retryAfter;
  String? errorCode;
  bool staged = false;
}

/// Media pending transfer is encrypted before starting. Once-only media is
/// never persisted. Recovered media waits for explicit retry in the chat.
class ChatMediaSendQueue extends ChangeNotifier {
  ChatMediaSendQueue({required this.send, this.persistence, this.chatId}) {
    ready = _restore();
  }
  final SendMediaDraft send;
  final ChatLocalStorage? persistence;
  final String? chatId;
  late final Future<void> ready;
  final List<ChatMediaSendEntry> _entries = [];
  List<ChatMediaSendEntry> get entries => List.unmodifiable(_entries);
  bool _running = false, _closed = false, _restored = false;
  Future<void> _writes = Future.value();
  Object? storageError;
  String get _key => chatStorageKey('media', chatId!);
  String _blob(ChatMediaSendEntry entry) =>
      chatStorageKey('blob', '$chatId:${entry.id}');
  bool get _current => !_closed && (persistence?.isCurrent ?? true);
  String? messageIdFor(ChatMediaDraft draft) {
    for (final entry in _entries) {
      if (identical(entry.draft, draft)) return entry.id;
    }
    return null;
  }

  Future<void> _restore() async {
    if (persistence == null) {
      _restored = true;
      return;
    }
    if (chatId == null) throw ArgumentError('Chat ID required');
    final raw = await persistence!.read(_key);
    if (!_current) return;
    if (raw == null) {
      _restored = true;
      return;
    }
    final data = jsonDecode(raw);
    if (data is! Map ||
        data['version'] != 1 ||
        data['entries'] is! List ||
        (data['entries'] as List).length > 30)
      throw const FormatException('Invalid private media queue');
    for (final row in data['entries'] as List) {
      if (row is! Map || row['id'] is! String || row['extension'] is! String)
        throw const FormatException('Invalid media entry');
      if (row['viewOnce'] == true) continue;
      final file = await persistence!.restoreFile(
          chatStorageKey('blob', '$chatId:${row['id']}'),
          row['extension'] as String);
      if (!_current) return;
      if (file == null) continue;
      final draft = ChatMediaDraft(file)
        ..caption = (row['caption'] as String?) ?? ''
        ..hd = row['hd'] == true
        ..prepared = row['prepared'] == true
        ..uploadUrl = row['uploadUrl'] as String?
        ..thumbnailUrl = row['thumbnailUrl'] as String?
        ..mediaId = row['mediaId'] as String?
        ..queuedId = row['queuedId'] as String?;
      draft.generated.add(file);
      _entries.add(ChatMediaSendEntry(draft, id: row['id'] as String)
        ..persistedPath = file.path
        ..error = StateError('Attachment recovered. Retry to continue.')
        ..errorCode = row.containsKey('errorCode')
            ? row['errorCode'] as String?
            : 'interrupted'
        ..attempts =
            row['attempts'] is int ? (row['attempts'] as int).clamp(0, 5) : 0
        ..retryAfter = row['retryAfter'] is int
            ? DateTime.fromMillisecondsSinceEpoch(row['retryAfter'] as int)
            : null
        ..staged = row['staged'] == true);
    }
    _restored = true;
    if (_current) notifyListeners();
  }

  Future<void> checkpoint(ChatMediaDraft draft) async {
    if (persistence == null || draft.viewOnce) return;
    await _save();
  }

  Future<void> _save() {
    if (persistence == null) return Future.value();
    final current = _entries.where((e) => !e.draft.viewOnce).toList();
    final next = _writes.then((_) async {
      if (!persistence!.isCurrent) throw StateError('Chat session changed');
      final rows = <Map<String, dynamic>>[];
      for (final entry in current) {
        final draft = entry.draft;
        if (entry.persistedPath != draft.file.path) {
          await persistence!.keepFile(_blob(entry), draft.file);
          entry.persistedPath = draft.file.path;
        }
        final extension = draft.file.path.split('.').last.toLowerCase();
        rows.add({
          'id': entry.id,
          'extension': RegExp(r'^[a-z0-9]{1,8}$').hasMatch(extension)
              ? extension
              : (draft.video ? 'mp4' : 'jpg'),
          'caption': draft.caption,
          'hd': draft.hd,
          'prepared': draft.prepared,
          'uploadUrl': draft.uploadUrl,
          'thumbnailUrl': draft.thumbnailUrl,
          'mediaId': draft.mediaId,
          'queuedId': draft.queuedId,
          'attempts': entry.attempts,
          'errorCode': entry.errorCode,
          'retryAfter': entry.retryAfter?.millisecondsSinceEpoch,
          'staged': entry.staged
        });
      }
      await persistence!.write(_key,
          rows.isEmpty ? null : jsonEncode({'version': 1, 'entries': rows}));
      storageError = null;
    });
    _writes = next.catchError((Object error) {
      storageError = error;
    });
    return next;
  }

  Future<void> flush() async {
    await ready;
    await _writes;
    if (storageError != null) throw StateError('Unable to save media queue');
  }

  void enqueue(List<ChatMediaDraft> drafts) {
    if (!_current || !_restored)
      throw StateError('Conversation storage not ready');
    // The composer may repeat handoff after a failed durability flush. Reuse
    // the same entry/ID instead of duplicating its already-owned attachment.
    final additions = <ChatMediaDraft>[];
    for (final draft in drafts) {
      if (draft.sent) continue;
      final existing = _entries.where((entry) =>
          identical(entry.draft, draft) ||
          draft.queuedId != null && entry.id == draft.queuedId);
      if (existing.isNotEmpty) {
        final entry = existing.first;
        if (!entry.sending) {
          entry.error = null;
          entry.attempts = 0;
          entry.retryAfter = null;
        }
      } else if (!additions.any((item) => identical(item, draft))) {
        additions.add(draft);
      }
    }
    if (_entries.length + additions.length > 30)
      throw StateError('Too many pending attachments');
    _entries.addAll(additions
        .map((draft) => ChatMediaSendEntry(draft, id: draft.queuedId)));
    if (persistence != null)
      unawaited(_save().catchError((Object error) {
        storageError = error;
      }));
    notifyListeners();
    unawaited(_pump());
  }

  void retry(ChatMediaSendEntry entry) {
    if (!_current || entry.sending || !_entries.contains(entry)) return;
    entry.error = null;
    entry.attempts = 0;
    entry.retryAfter = null;
    entry.staged = false;
    unawaited(_pump());
  }

  static bool _transient(String? code) => const [
        'unavailable',
        'deadline-exceeded',
        'aborted',
        'network-request-failed',
        'retry-limit-exceeded',
        'interrupted'
      ].contains(code);
  Future<void> retryTransient() async {
    await ready;
    if (!_current) return;
    for (final entry in _entries.toList()) {
      if (entry.staged ||
          entry.sending ||
          entry.attempts >= 5 ||
          !_transient(entry.errorCode) ||
          entry.retryAfter != null &&
              DateTime.now().isBefore(entry.retryAfter!)) continue;
      entry.error = null;
    }
    await _pump();
  }

  /// Used only by the composer-draft store: retaining a selection never sends it.
  Future<void> replaceDrafts(List<ChatMediaDraft> drafts) async {
    await ready;
    if (!_current || _running) throw StateError('Draft store unavailable');
    if (drafts.length > 30) throw StateError('Too many draft attachments');
    final previous = _entries.toList();
    _entries.clear();
    for (final draft in drafts.where((draft) => !draft.viewOnce)) {
      final matches = previous.where((entry) => identical(entry.draft, draft));
      _entries.add((matches.isEmpty ? ChatMediaSendEntry(draft) : matches.first)
        ..staged = true
        ..error = StateError('Unsent attachment draft')
        ..errorCode = null);
    }
    await _save();
    for (final old in previous.where((entry) => !_entries.contains(entry))) {
      if (persistence != null) await persistence!.write(_blob(old), null);
    }
    if (_current) notifyListeners();
  }

  void discard(ChatMediaSendEntry entry) {
    if (entry.sending) {
      entry.cancelRequested = true;
      return;
    }
    if (!_entries.remove(entry)) return;
    () async {
      try {
        await _save();
        if (persistence != null && !entry.draft.viewOnce)
          await persistence!.write(_blob(entry), null);
      } catch (error) {
        storageError = error;
      }
      await _clean(entry.draft);
    }();
    if (!_closed) notifyListeners();
  }

  Future<void> _pump() async {
    if (_running || !_current) return;
    _running = true;
    try {
      if (persistence != null) await ready;
      while (_current) {
        final candidates =
            _entries.where((entry) => entry.error == null).toList();
        if (candidates.isEmpty) break;
        final entry = candidates.first;
        entry.sending = true;
        entry.attempts++;
        entry.errorCode = 'interrupted';
        entry.progress = null;
        notifyListeners();
        try {
          if (persistence != null) await _save();
          if (!_current) break;
          await send(entry.draft, (value) {
            if (_current) {
              entry.progress = value;
              notifyListeners();
            }
          });
          entry.draft.sent = true;
          _entries.remove(entry);
          if (persistence != null && persistence!.isCurrent) {
            await _save();
            if (!entry.draft.viewOnce)
              await persistence!.write(_blob(entry), null);
          }
          await _clean(entry.draft);
        } catch (error) {
          // A queued message already belongs to the stable-ID message outbox.
          if (entry.cancelRequested ||
              entry.draft.queuedId != null ||
              _closed && persistence == null ||
              entry.draft.viewOnce && _closed) {
            _entries.remove(entry);
            if (persistence != null && persistence!.isCurrent) {
              try {
                await _save();
                if (!entry.draft.viewOnce)
                  await persistence!.write(_blob(entry), null);
              } catch (error) {
                storageError = error;
              }
            }
            await _clean(entry.draft);
          } else {
            entry.error = error;
            entry.errorCode = error is FirebaseException
                ? error.code
                : error is SocketException || error is TimeoutException
                    ? 'unavailable'
                    : null;
            entry.retryAfter = DateTime.now()
                .add(Duration(seconds: 1 << entry.attempts.clamp(0, 5)));
            if (persistence != null && persistence!.isCurrent) {
              try {
                await _save();
              } catch (error) {
                storageError = error;
              }
            }
            if (_closed) await _clean(entry.draft);
          }
        } finally {
          entry.sending = false;
          if (!_closed) notifyListeners();
        }
      }
    } catch (error) {
      storageError = error;
      for (final entry in _entries) {
        entry.error ??= error;
      }
      if (!_closed) notifyListeners();
    } finally {
      _running = false;
    }
  }

  Future<void> _clean(ChatMediaDraft draft) async {
    for (final file in draft.generated) {
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    draft.generated.clear();
  }

  @override
  void dispose() {
    if (_closed) return;
    _closed = true;
    for (final entry in _entries.where((entry) => !entry.sending)) {
      unawaited(_writes.then((_) => _clean(entry.draft)));
    }
    _entries.removeWhere((entry) => !entry.sending);
    super.dispose();
  }
}

/// Independent encrypted selection draft. Saving never schedules a transfer.
class ChatMediaDraftStore {
  ChatMediaDraftStore(
      {required ChatLocalStorage persistence, required String chatId})
      : _queue = ChatMediaSendQueue(
            persistence: persistence,
            chatId: 'composer:' + chatId,
            send: (_, __) async {});
  final ChatMediaSendQueue _queue;
  Future<void> get ready => _queue.ready;
  List<ChatMediaDraft> get drafts =>
      _queue.entries.map((entry) => entry.draft).toList(growable: false);
  Future<void> save(List<ChatMediaDraft> drafts) =>
      _queue.replaceDrafts(drafts);
  Future<void> clear() => save(const []);
  Future<void> flush() => _queue.flush();
  void dispose() => _queue.dispose();
}
