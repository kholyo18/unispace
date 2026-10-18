import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';
import 'authorized_media_cache.dart';
import 'video_playback_source.dart';
import 'performance_probe.dart';

/// Stores bytes only. Every caller must obtain a fresh authorized URL before
/// looking up a file, and recheck access before exposing a prepared controller.
class AuthorizedVideoByteCache {
  AuthorizedVideoByteCache(
      {required this.lookup,
      required this.store,
      required this.download,
      this.maxDownloads = 1,
      this.maxBytes = 24 * 1024 * 1024});

  final Future<File?> Function(String key) lookup;
  final Future<void> Function(String key, Uint8List bytes) store;
  final Future<Uint8List?> Function(Uri url, int maxBytes) download;
  final int maxDownloads, maxBytes;
  final Map<String, Future<void>> _pending = {};

  String? _key(String source, String viewer) {
    final uri = Uri.tryParse(source);
    if (viewer.isEmpty ||
        uri?.scheme != 'https' ||
        !(uri!.host == 'storage.googleapis.com' ||
            uri.host.endsWith('.storage.googleapis.com')) ||
        !RegExp(r'^\d+$').hasMatch(uri.queryParameters['generation'] ?? '')) {
      return null;
    }
    return authorizedMediaCacheKey(source, viewer);
  }

  Future<File?> read(String source, String viewer) async {
    final key = _key(source, viewer);
    if (key == null) return null;
    try {
      final file = await lookup(key);
      return file != null && await file.exists() ? file : null;
    } catch (_) {
      return null;
    } // A broken disk cache must not stop streaming.
  }

  Future<void> warm(String source, String viewer) {
    final key = _key(source, viewer);
    if (key == null) return Future.value();
    final existing = _pending[key];
    if (existing != null) return existing;
    // Do not build an unbounded background queue during rapid swipes.
    if (_pending.length >= maxDownloads) return Future.value();
    final done = Completer<void>();
    _pending[key] = done.future;
    () async {
      try {
        if (await read(source, viewer) != null) return;
        final bytes = await download(Uri.parse(source), maxBytes);
        if (bytes != null && bytes.isNotEmpty && bytes.length <= maxBytes) {
          await store(key, bytes);
        }
      } catch (_) {
        // Optional byte warming never changes playback or its authorization.
      } finally {
        _pending.remove(key);
        done.complete();
      }
    }();
    return done.future;
  }
}

Future<Uint8List?> _downloadBounded(Uri uri, int maxBytes) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
  final timer =
      Timer(const Duration(seconds: 45), () => client.close(force: true));
  try {
    final request = await client.getUrl(uri);
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok ||
        response.contentLength > maxBytes) {
      return null;
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response.timeout(const Duration(seconds: 10))) {
      if (bytes.length + chunk.length > maxBytes) return null;
      bytes.add(chunk);
    }
    return bytes.takeBytes();
  } finally {
    timer.cancel();
    client.close(force: true);
  }
}

final _files = CacheManager(Config('authorizedVideoBytesV1',
    stalePeriod: const Duration(days: 3), maxNrOfCacheObjects: 8));
final _bytes = AuthorizedVideoByteCache(
  lookup: (key) async => (await _files.getFileFromCache(key))?.file,
  store: (key, bytes) async {
    // No signed URL/token is persisted in the cache index.
    await _files.putFile(key, bytes,
        key: key, fileExtension: 'mp4', maxAge: const Duration(days: 3));
  },
  download: _downloadBounded,
);

Future<VideoPlayerController> createAuthorizedCachedVideo(
    String signedUrl, String viewer) async {
  final watch = Stopwatch()..start();
  final file = await _bytes.read(signedUrl, viewer);
  PerformanceProbe.elapsed(
      file == null ? 'video_disk_cache_miss' : 'video_disk_cache_hit', watch);
  return createVideoPlaybackController(file?.path ?? signedUrl);
}

/// Call unawaited AFTER native buffering succeeds, never on the startup path.
Future<void> cacheAuthorizedVideo(String signedUrl, String viewer) =>
    _bytes.warm(signedUrl, viewer);

/// A corrupt local file must not make every authorized retry fail again.
Future<void> forgetAuthorizedVideo(String signedUrl, String viewer) async {
  final key = _bytes._key(signedUrl, viewer);
  if (key == null) return;
  try {
    await _files.removeFile(key);
  } catch (_) {
    // The caller can still fall back to the freshly authorized network source.
  }
}
