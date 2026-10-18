import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

abstract class ChatLocalStorage {
  bool get isCurrent;
  Future<String?> read(String key);
  Future<void> write(String key, String? value);
  Future<void> keepFile(String key, File file);
  Future<File?> restoreFile(String key, String extension);
  Future<void> purge();
}

String chatStorageKey(String kind, String id) =>
    '${kind}_${sha256.convert(utf8.encode(id))}';

/// Supply UID:signed SID:auth_time, never a process-local viewer generation.
/// The native adapter encrypts metadata and media under Android Keystore.
class ChatLocalPersistence implements ChatLocalStorage {
  static ChatLocalPersistence? _active;
  static Future<void> purgeActive() async {
    final previous = _active;
    if (previous == null) return;
    _active = null;
    await previous.purge();
  }

  ChatLocalPersistence._(this.sessionKey, this.currentSessionKey, this._channel)
      : _scope = sha256.convert(utf8.encode(sessionKey)).toString();
  final String sessionKey;
  final String Function() currentSessionKey;
  final MethodChannel _channel;
  final String _scope;
  static Future<ChatLocalPersistence> open(
      {required String sessionKey,
      required String Function() currentSessionKey,
      MethodChannel channel =
          const MethodChannel('unispace/chat_local_store')}) async {
    if (sessionKey.isEmpty || sessionKey != currentSessionKey())
      throw StateError('Chat session changed');
    final store =
        ChatLocalPersistence._(sessionKey, currentSessionKey, channel);
    await channel.invokeMethod<void>('activate', {'scope': store._scope});
    store._check();
    _active = store;
    return store;
  }

  @override
  bool get isCurrent =>
      sessionKey.isNotEmpty && currentSessionKey() == sessionKey;
  void _check() {
    if (!isCurrent) throw StateError('Chat session changed');
  }

  Future<T?> _call<T>(String operation, String key,
      [Map<String, Object?> extra = const {}]) async {
    _check();
    final result = await _channel
        .invokeMethod<T>(operation, {'scope': _scope, 'key': key, ...extra});
    _check();
    return result;
  }

  @override
  Future<String?> read(String key) => _call<String>('read', key);
  @override
  Future<void> write(String key, String? value) async {
    await _call<void>(value == null ? 'delete' : 'write', key,
        {if (value != null) 'value': value});
  }

  @override
  Future<void> keepFile(String key, File file) async {
    await _call<void>('keepFile', key, {'path': file.path});
  }

  @override
  Future<File?> restoreFile(String key, String extension) async {
    final path =
        await _call<String>('restoreFile', key, {'extension': extension});
    return path == null ? null : File(path);
  }

  @override
  Future<void> purge() async {
    // Sign-out may already have invalidated the Dart session. Native purge is
    // conditional on this scope, so it cannot delete a newer account's files.
    await _channel.invokeMethod<void>('purge', {'scope': _scope});
  }
}
