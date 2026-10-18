import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'chat_local_persistence.dart';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

typedef ChatCallable = Future<Map<String, dynamic>> Function(
    String name, Map<String, dynamic> data);

class ChatOpenResult {
  const ChatOpenResult({required this.chatId, required this.status});
  final String chatId;
  final String status;
}

/// All message mutations go through the server's privacy/session checks.
class ChatMessageService {
  ChatMessageService({FirebaseFunctions? functions, FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance,
        _call = ((name, data) async {
          final response = await (functions ??
                  FirebaseFunctions.instanceFor(region: 'europe-west1'))
              .httpsCallable(name)
              .call<Map<String, dynamic>>(data);
          return response.data;
        });

  ChatMessageService.forTesting(
      {required ChatCallable call, required String? Function() currentUserId})
      : _call = call,
        _currentUserId = currentUserId,
        _auth = null;

  final FirebaseAuth? _auth;
  final ChatCallable _call;
  String? Function()? _currentUserId;
  String? get _uid => _currentUserId?.call() ?? _auth?.currentUser?.uid;

  Future<String?> _sessionIdentity() async {
    if (_auth == null) return _uid;
    final user = _auth.currentUser;
    if (user == null) return null;
    final token = await user.getIdTokenResult();
    if (_auth.currentUser?.uid != user.uid) return null;
    return '${user.uid}:${token.claims?['sid']}:${token.claims?['auth_time']}';
  }

  Future<Map<String, dynamic>> _request(
      String name, Map<String, dynamic> data) async {
    final uid = _uid;
    final session = await _sessionIdentity();
    if (uid == null || session == null || _uid != uid) {
      throw FirebaseFunctionsException(
          code: 'unauthenticated', message: 'The active account changed.');
    }
    final response = await _call(name, data);
    if (_uid != uid || await _sessionIdentity() != session) {
      throw FirebaseFunctionsException(
          code: 'unauthenticated', message: 'The active account changed.');
    }
    return response;
  }

  Future<String> sendChatMessage({
    required String chatId,
    required String messageId,
    required Map<String, dynamic> message,
  }) async {
    final result = await _request('sendChatMessage', {
      'chatId': chatId,
      'messageId': messageId,
      'message': message,
    });
    if (result['messageId'] != messageId) {
      throw FirebaseFunctionsException(
          code: 'data-loss', message: 'The server confirmation was invalid.');
    }
    return messageId;
  }

  ChatOpenResult _openResult(Map<String, dynamic> result) {
    final chatId = result['chatId'];
    final status = result['status'];
    if (chatId is! String ||
        chatId.isEmpty ||
        !['open', 'pending', 'rejected'].contains(status)) {
      throw FirebaseFunctionsException(
          code: 'data-loss', message: 'The server confirmation was invalid.');
    }
    return ChatOpenResult(chatId: chatId, status: status as String);
  }

  Future<ChatOpenResult> openChat(String peerId) async =>
      _openResult(await _request('openChat', {'peerId': peerId}));

  Future<void> voteChatPoll(
      {required String chatId,
      required String messageId,
      required int optionIndex}) async {
    await _request('voteChatPoll',
        {'chatId': chatId, 'messageId': messageId, 'optionIndex': optionIndex});
  }

  Future<void> respondChatEvent(
      {required String chatId,
      required String messageId,
      required bool attending}) async {
    await _request('respondChatEvent',
        {'chatId': chatId, 'messageId': messageId, 'attending': attending});
  }

  Future<void> mutateChatMessage({
    required String chatId,
    required String messageId,
    required String action,
    String? text,
  }) async {
    await _request('mutateChatMessage', {
      'chatId': chatId,
      'messageId': messageId,
      'action': action,
      if (text != null) 'text': text,
    });
  }

  Future<ChatOpenResult> respondChatRequest({
    required String requestId,
    required String action,
  }) async =>
      _openResult(await _request('respondChatRequest', {
        'requestId': requestId,
        'action': action,
      }));
}

enum ChatOutboxState { queued, sending, failed, acknowledged }

class ChatOutboxEntry {
  ChatOutboxEntry._(this.id, this.chatId, Map<String, dynamic> message,
      {DateTime? createdAt})
      : message = Map<String, dynamic>.unmodifiable(message),
        createdAt = createdAt ?? DateTime.now();
  final String id, chatId;
  final DateTime createdAt;
  final Map<String, dynamic> message;
  ChatOutboxState _state = ChatOutboxState.queued;
  Object? _error;
  String? _errorCode;
  int _attempts = 0;
  DateTime? _retryAfter;
  ChatOutboxState get state => _state;
  Object? get error => _error;
  bool get retryable =>
      _state == ChatOutboxState.queued ||
      (_state == ChatOutboxState.failed &&
          const ['unavailable', 'deadline-exceeded', 'aborted', 'interrupted']
              .contains(_errorCode));
}

/// A persisted stable ID is flushed before sending. Recovery never changes its
/// payload, even if the server committed before the client lost confirmation.
class ChatOutbox {
  final changes = ChangeNotifier();
  ChatOutbox({
    required this.currentSessionKey,
    required this.send,
    required this.newMessageId,
    this.onChanged,
    this.retainUntilObserved = false,
    this.persistence,
    this.persistenceKey,
  }) : _sessionKey = currentSessionKey() {
    ready = _restore();
  }
  final String Function() currentSessionKey;
  final Future<void> Function(
      String chatId, String messageId, Map<String, dynamic> message) send;
  final String Function() newMessageId;
  void Function()? onChanged;
  final bool retainUntilObserved;
  final ChatLocalStorage? persistence;
  final String? persistenceKey;
  late final Future<void> ready;
  final String _sessionKey;
  int _generation = 0;
  bool _restored = false;
  Object? _persistenceError;
  Future<void> _writes = Future.value();
  final Map<String, ChatOutboxEntry> _entries = {};
  final Map<String, Future<bool>> _running = {};

  bool get _current =>
      _sessionKey.isNotEmpty &&
      _sessionKey == currentSessionKey() &&
      (persistence?.isCurrent ?? true);
  void _syncSession() {
    if (!_current) clear();
  }

  Future<void> _restore() async {
    if (persistence == null) {
      _restored = true;
      return;
    }
    if (persistenceKey == null) throw ArgumentError('Persistence key required');
    final generation = _generation;
    final raw = await persistence!.read(persistenceKey!);
    if (!_current || generation != _generation) return;
    if (raw != null) {
      final decoded = jsonDecode(raw);
      if (decoded is! Map ||
          decoded['version'] != 1 ||
          decoded['entries'] is! List ||
          (decoded['entries'] as List).length > 256) {
        throw const FormatException('Invalid private outbox');
      }
      for (final value in decoded['entries'] as List) {
        if (value is! Map ||
            value['id'] is! String ||
            value['chatId'] is! String ||
            value['createdAt'] is! int ||
            value['message'] is! Map)
          throw const FormatException('Invalid outbox entry');
        final message = Map<String, dynamic>.from(value['message'] as Map);
        if (!_primitive(message) ||
            (value['id'] as String).isEmpty ||
            _entries.containsKey(value['id']))
          throw const FormatException('Invalid outbox payload');
        // Private once-only tickets are intentionally never retained on disk.
        if (message['type'] == 'viewOnce') continue;
        final entry = ChatOutboxEntry._(
            value['id'] as String, value['chatId'] as String, message,
            createdAt:
                DateTime.fromMillisecondsSinceEpoch(value['createdAt'] as int));
        entry._state = value['state'] == 'acknowledged'
            ? ChatOutboxState.acknowledged
            : ChatOutboxState.failed;
        entry._errorCode = value['state'] == 'failed'
            ? value['errorCode'] as String?
            : 'interrupted';
        entry._attempts = value['attempts'] is int
            ? (value['attempts'] as int).clamp(0, 5)
            : 0;
        if (value['retryAfter'] is int)
          entry._retryAfter =
              DateTime.fromMillisecondsSinceEpoch(value['retryAfter'] as int);
        _entries[entry.id] = entry;
      }
    }
    _restored = true;
    changes.notifyListeners();
    onChanged?.call();
  }

  static bool _primitive(Map<String, dynamic> message) => message.values.every(
      (v) => v is String || v is num && v.isFinite || v is bool || v == null);
  void _changed() {
    if (persistence != null && _current && _restored) {
      final generation = _generation;
      final data = jsonEncode({
        'version': 1,
        'entries': [
          for (final entry in _entries.values)
            if (entry.message['type'] != 'viewOnce')
              {
                'id': entry.id,
                'chatId': entry.chatId,
                'message': entry.message,
                'createdAt': entry.createdAt.millisecondsSinceEpoch,
                'state': entry.state.name,
                'errorCode': entry._errorCode,
                'attempts': entry._attempts,
                'retryAfter': entry._retryAfter?.millisecondsSinceEpoch,
              }
        ]
      });
      _writes = _writes.then((_) async {
        if (!_current || generation != _generation) return;
        try {
          await persistence!.write(persistenceKey!, data);
          _persistenceError = null;
        } catch (error) {
          _persistenceError = error;
        }
      });
    }
    changes.notifyListeners();
    onChanged?.call();
  }

  Future<void> flush() async {
    await ready;
    await _writes;
    if (_persistenceError != null)
      throw StateError('Unable to save pending message');
  }

  List<ChatOutboxEntry> get entries {
    _syncSession();
    return List.unmodifiable(_entries.values);
  }

  ChatOutboxEntry enqueue(
      {required String chatId,
      required Map<String, dynamic> message,
      String? messageId}) {
    _syncSession();
    if (!_current || !_restored)
      throw StateError('Chat storage/session not ready');
    if (_entries.length >= 256) throw StateError('Chat outbox is full.');
    if (!_primitive(message))
      throw ArgumentError('Message fields must be primitive values.');
    final id = messageId ?? newMessageId();
    final existing = _entries[id];
    if (existing != null &&
        messageId != null &&
        existing.chatId == chatId &&
        existing.message.length == message.length &&
        message.entries.every((item) =>
            existing.message.containsKey(item.key) &&
            existing.message[item.key] == item.value)) return existing;
    if (id.isEmpty || _entries.containsKey(id))
      throw StateError('Message ID must be unique.');
    final entry = ChatOutboxEntry._(id, chatId, message);
    _entries[id] = entry;
    _changed();
    return entry;
  }

  Future<bool> retry(String id) {
    final entry = _entries[id];
    if (entry != null && !_running.containsKey(id)) {
      entry._attempts = 0;
      entry._retryAfter = null;
    }
    return attempt(id);
  }

  /// Called on restored connectivity/resume; permanent auth/privacy failures
  /// require explicit user action. At most five automatic attempts per entry.
  Future<void> retryTransient() async {
    await ready;
    for (final entry in entries.toList()) {
      if (!_current) return;
      if (entry.retryable &&
          entry._attempts < 5 &&
          (entry._retryAfter == null ||
              !DateTime.now().isBefore(entry._retryAfter!)))
        await attempt(entry.id);
    }
  }

  Future<bool> attempt(String id) {
    _syncSession();
    final existing = _running[id];
    if (existing != null) return existing;
    final entry = _entries[id];
    if (entry == null) return Future.value(false);
    if (entry.state == ChatOutboxState.acknowledged) return Future.value(true);
    final generation = _generation, session = _sessionKey;
    final completer = Completer<bool>();
    _running[id] = completer.future;
    entry._state = ChatOutboxState.sending;
    entry._error = null;
    entry._attempts++;
    _changed();
    () async {
      var success = false;
      try {
        if (persistence != null) await flush();
        if (!_current ||
            generation != _generation ||
            session != currentSessionKey()) return;
        await send(entry.chatId, entry.id, entry.message);
        if (_current && generation == _generation) {
          if (retainUntilObserved)
            entry._state = ChatOutboxState.acknowledged;
          else
            _entries.remove(id);
          success = true;
        }
      } catch (error) {
        if (_current && generation == _generation) {
          entry._state = ChatOutboxState.failed;
          entry._error = error;
          entry._errorCode =
              error is FirebaseFunctionsException ? error.code : null;
          entry._retryAfter = DateTime.now()
              .add(Duration(seconds: 1 << entry._attempts.clamp(0, 5)));
        }
      } finally {
        _syncSession();
        if (generation == _generation) {
          _running.remove(id);
          _changed();
        }
        completer.complete(success);
      }
    }();
    return completer.future;
  }

  void observe(Iterable<String> messageIds) {
    _syncSession();
    var changed = false;
    for (final id in messageIds) {
      if (_entries.remove(id) != null) changed = true;
    }
    if (changed) _changed();
  }

  void removeFailed(String id) {
    _syncSession();
    if (_entries[id]?.state != ChatOutboxState.failed) return;
    _entries.remove(id);
    _changed();
  }

  void clear() {
    _generation++;
    _entries.clear();
    _running.clear();
    if (persistence != null &&
        persistence!.isCurrent &&
        persistenceKey != null) {
      _writes = _writes
          .then((_) => persistence!.write(persistenceKey!, null))
          .catchError((Object error) {
        _persistenceError = error;
      });
    }
  }
}

/// Reuses a conversation's failed sends when navigating away and back. A new
/// signed session invalidates every record, including requests still in flight.
class ChatOutboxStore {
  static String? _session;
  static final Map<String, ChatOutbox> _chats = {};

  static ChatOutbox forSession({
    required String chatId,
    required String Function() currentSessionKey,
    required Future<void> Function(String, String, Map<String, dynamic>) sender,
    required String Function() newMessageId,
    bool retainUntilObserved = false,
    ChatLocalStorage? persistence,
  }) {
    final session = currentSessionKey();
    if (_session != session) clear();
    _session = session;
    if (session.isEmpty) throw StateError('No active chat session.');
    final existing = _chats[chatId];
    if (existing != null) return existing;
    _chats.removeWhere((_, outbox) =>
        outbox.onChanged == null &&
        !outbox.changes.hasListeners &&
        outbox.entries.isEmpty);
    if (_chats.length >= 32) {
      throw StateError('Too many conversations with pending messages.');
    }
    final outbox = ChatOutbox(
      currentSessionKey: currentSessionKey,
      send: sender,
      newMessageId: newMessageId,
      retainUntilObserved: retainUntilObserved,
      persistence: persistence,
      persistenceKey: chatStorageKey('outbox', chatId),
    );
    _chats[chatId] = outbox;
    return outbox;
  }

  static void clear() {
    for (final outbox in _chats.values) {
      outbox.clear();
      outbox.onChanged = null;
    }
    _chats.clear();
    _session = null;
  }
}

/// Composer text remains synchronous in memory; restore/flush bridge encrypted
/// storage at route initialization and lifecycle boundaries.
class ChatDraftStore {
  static String? _session;
  static int _generation = 0;
  static final Map<String, String> _drafts = {};
  static final Map<String, ChatLocalStorage> _stores = {};
  static final Map<String, int> _revisions = {};
  static Future<void> _writes = Future.value();
  static Object? _error;
  static void _sync(String sessionKey) {
    if (_session != sessionKey) clear();
    _session = sessionKey;
  }

  static Future<void> restore(String chatId, String sessionKey,
      {required ChatLocalStorage persistence}) async {
    _sync(sessionKey);
    if (sessionKey.isEmpty || !persistence.isCurrent) return;
    final generation = _generation, revision = _revisions[chatId] ?? 0;
    _stores[chatId] = persistence;
    final raw = await persistence.read(chatStorageKey('draft', chatId));
    if (generation != _generation ||
        _session != sessionKey ||
        !persistence.isCurrent ||
        (_revisions[chatId] ?? 0) != revision) return;
    if (raw != null) {
      final value = jsonDecode(raw);
      if (value is! Map || value['version'] != 1 || value['text'] is! String)
        throw const FormatException('Invalid private draft');
      _drafts[chatId] = value['text'] as String;
    }
  }

  static String get(String chatId, String sessionKey) {
    _sync(sessionKey);
    return sessionKey.isEmpty ? '' : _drafts[chatId] ?? '';
  }

  static void put(String chatId, String sessionKey, String text) {
    _sync(sessionKey);
    if (sessionKey.isEmpty) {
      if (text.isNotEmpty) throw StateError('No active chat session.');
      return;
    }
    if (text.length > 100000) throw StateError('Draft too long');
    if (text.isEmpty)
      _drafts.remove(chatId);
    else {
      if (!_drafts.containsKey(chatId) && _drafts.length >= 128)
        throw StateError('Too many conversations with unsent drafts.');
      _drafts[chatId] = text;
    }
    _revisions[chatId] = (_revisions[chatId] ?? 0) + 1;
    final store = _stores[chatId], generation = _generation;
    if (store != null)
      _writes = _writes.then((_) async {
        if (generation != _generation || !store.isCurrent) return;
        try {
          await store.write(chatStorageKey('draft', chatId),
              text.isEmpty ? null : jsonEncode({'version': 1, 'text': text}));
          _error = null;
        } catch (error) {
          _error = error;
        }
      });
  }

  static Future<void> flush() async {
    await _writes;
    if (_error != null) throw StateError('Unable to save draft');
  }

  static void clear() {
    _generation++;
    _drafts.clear();
    _stores.clear();
    _revisions.clear();
    _session = null;
    _error = null;
  }
}
