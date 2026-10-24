import 'protected_media_service.dart';
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preference applies to ordinary chat image/thumbnail background loads only.
/// A manual tap always remains possible. It never authorizes access to media.
class ChatMediaPolicy extends ChangeNotifier {
  bool wifi = true, mobile = true;
  int cacheMiB = 24;
  bool _loaded = false;
  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    wifi = prefs.getBool('chat_media_wifi_v1') ?? true;
    mobile = prefs.getBool('chat_media_mobile_v1') ?? true;
    final storedLimit = prefs.getInt('chat_media_cache_mib_v1') ?? 24;
    cacheMiB = [8, 24, 48].contains(storedLimit) ? storedLimit : 24;
    chatImageMemoryCache.resize(cacheMiB * 1024 * 1024);
    _loaded = true;
    notifyListeners();
  }

  Future<void> save(
      {required bool wifi, required bool mobile, int? cacheMiB}) async {
    final limit = cacheMiB ?? this.cacheMiB;
    if (![8, 24, 48].contains(limit)) throw ArgumentError.value(limit);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('chat_media_wifi_v1', wifi);
    await prefs.setBool('chat_media_mobile_v1', mobile);
    await prefs.setInt('chat_media_cache_mib_v1', limit);
    this.cacheMiB = limit;
    chatImageMemoryCache.resize(limit * 1024 * 1024);
    this.wifi = wifi;
    this.mobile = mobile;
    _loaded = true;
    notifyListeners();
  }

  bool permits(List<ConnectivityResult> transports) {
    // If a mobile transport is also present use the more conservative policy.
    if (transports.contains(ConnectivityResult.mobile)) return mobile;
    if (transports.contains(ConnectivityResult.wifi) ||
        transports.contains(ConnectivityResult.ethernet)) return wifi;
    return false;
  }

  Future<bool> allowsAutomatic() async {
    try {
      await load();
      return permits(await Connectivity().checkConnectivity());
    } catch (_) {
      return false;
    }
  }
}

final chatMediaPolicy = ChatMediaPolicy();

/// Session-only bytes, no persistent URLs/files. Caller must recheck membership
/// on EVERY read and clear the session namespace on revocation/logout.
class ChatImageMemoryCache extends ChangeNotifier {
  ChatImageMemoryCache(
      {this.maxBytes = 24 * 1024 * 1024,
      this.maxEntryBytes = 8 * 1024 * 1024,
      this.maxEntries = 32,
      this.maxConcurrent = 2,
      Future<Uint8List> Function(Uri, int)? download})
      : _download = download ?? _fetch;
  int maxBytes;
  final int maxEntryBytes, maxEntries, maxConcurrent;
  final Future<Uint8List> Function(Uri, int) _download;
  final _entries = LinkedHashMap<String, Uint8List>();
  final _pending = <String, Future<Uint8List?>>{};
  int _bytes = 0, _generation = 0;
  int get sizeBytes => _bytes;
  String _key(String scope, String source) => '$scope\n$source';
  Uint8List? peek(String scope, String source,
      {required bool Function() authorized}) {
    if (scope.isEmpty || !authorized()) return null;
    final key = _key(scope, source);
    final bytes = _entries.remove(key);
    if (bytes != null) _entries[key] = bytes;
    return bytes;
  }

  Future<Uint8List?> read(String scope, String source,
      {required bool Function() authorized, bool viewOnce = false}) async {
    if (scope.isEmpty || viewOnce || !authorized()) return null;
    final key = _key(scope, source);
    final existing = _entries.remove(key);
    if (existing != null) {
      _entries[key] = existing;
      return existing;
    }
    final uri = Uri.tryParse(source);
    if (uri?.scheme != 'https' ||
        !(uri!.host == 'firebasestorage.googleapis.com' ||
            uri.host == 'storage.googleapis.com' ||
            uri.host.endsWith('.storage.googleapis.com'))) return null;
    if (_pending.containsKey(key)) {
      final result = await _pending[key];
      return authorized() ? result : null;
    }
    if (_pending.length >= maxConcurrent) return null;
    final generation = _generation;
    final future = () async {
      try {
        final data = await _download(uri, maxEntryBytes);
        if (generation != _generation ||
            !authorized() ||
            data.isEmpty ||
            data.length > maxEntryBytes ||
            data.length > maxBytes) return null;
        while (_entries.isNotEmpty &&
            (_bytes + data.length > maxBytes ||
                _entries.length >= maxEntries)) {
          _bytes -= _entries.remove(_entries.keys.first)!.length;
        }
        _entries[key] = data;
        _bytes += data.length;
        notifyListeners();
        return data;
      } catch (_) {
        return null;
      }
    }();
    _pending[key] = future;
    try {
      return await future;
    } finally {
      _pending.remove(key);
    }
  }

  List<ChatCachedImageInfo> describeScope(String scope,
      {required bool Function() authorized}) {
    if (scope.isEmpty || !authorized()) return const [];
    final result = <ChatCachedImageInfo>[];
    for (final entry in _entries.entries) {
      if (!entry.key.startsWith('$scope\n')) continue;
      final source = entry.key.substring(scope.length + 1);
      final uri = Uri.tryParse(source);
      String name = 'Image';
      if (uri != null && uri.pathSegments.isNotEmpty) {
        try {
          name = Uri.decodeComponent(uri.pathSegments.last).split('/').last;
        } catch (_) {}
      }
      name = name.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
      if (name.length > 100) name = name.substring(0, 100);
      result.add(ChatCachedImageInfo(
          id: sha256.convert(utf8.encode(entry.key)).toString(),
          name: name,
          bytes: entry.value.length));
    }
    result.sort((a, b) => b.bytes.compareTo(a.bytes));
    return List.unmodifiable(result);
  }

  int removeScopedEntry(String scope, String id,
      {required bool Function() authorized,
      void Function(Uint8List)? onRemoved}) {
    if (scope.isEmpty || !authorized()) return 0;
    for (final key in _entries.keys.toList()) {
      if (key.startsWith('$scope\n') &&
          sha256.convert(utf8.encode(key)).toString() == id) {
        ++_generation;
        final removed = _entries.remove(key)!;
        final size = removed.length;
        onRemoved?.call(removed);
        _bytes -= size;
        notifyListeners();
        return size;
      }
    }
    return 0;
  }

  void resize(int bytes) {
    if (bytes <= 0) throw ArgumentError.value(bytes);
    maxBytes = bytes;
    while (_entries.isNotEmpty && _bytes > maxBytes) {
      _bytes -= _entries.remove(_entries.keys.first)!.length;
    }
    notifyListeners();
  }

  void clear() {
    ++_generation;
    _entries.clear();
    _bytes = 0;
    notifyListeners();
  }

  void clearScope(String scope, {void Function(Uint8List)? onRemoved}) {
    ++_generation;
    for (final key
        in _entries.keys.where((key) => key.startsWith('$scope\n')).toList()) {
      final removed = _entries.remove(key)!;
      _bytes -= removed.length;
      onRemoved?.call(removed);
    }
    notifyListeners();
  }

  static Future<Uint8List> _fetch(Uri uri, int limit) async {
    final service = ProtectedMediaService.instance;
    final grant = await service.resolve(uri.toString());
    void guard() {
      if (grant.scope != service.scope) throw StateError('Media session changed');
    }
    guard();
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    final timer =
        Timer(const Duration(seconds: 25), () => client.close(force: true));
    try {
      final request = await client.getUrl(Uri.parse(grant.url));
      guard();
      request.followRedirects = false;
      final response = await request.close();
      guard();
      if (response.statusCode != 200 || response.contentLength > limit)
        throw StateError('media unavailable');
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in response) {
        guard();
        if (bytes.length + chunk.length > limit)
          throw StateError('media too large');
        bytes.add(chunk);
      }
      guard();
      return bytes.takeBytes();
    } finally {
      timer.cancel();
      client.close(force: true);
    }
  }
}

final chatImageMemoryCache = ChatImageMemoryCache();

class ChatMediaPrefetchItem {
  const ChatMediaPrefetchItem({required this.source, required this.viewOnce});
  final String source;
  final bool viewOnce;
}

/// Only call after an authorized server snapshot; never use view-once sources.
Future<void> prefetchChatImages(
    {required String scope,
    required Iterable<ChatMediaPrefetchItem> items,
    required bool Function() authorized}) async {
  if (!authorized() ||
      !await chatMediaPolicy.allowsAutomatic() ||
      !authorized()) return;
  final ordinary =
      items.where((item) => !item.viewOnce && item.source.isNotEmpty).take(2);
  await Future.wait(ordinary.map((item) =>
      chatImageMemoryCache.read(scope, item.source, authorized: authorized)));
}

class ChatCachedImageInfo {
  const ChatCachedImageInfo(
      {required this.id, required this.name, required this.bytes});
  final String id, name;
  final int bytes;
}
