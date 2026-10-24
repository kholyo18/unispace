import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/services/protected_media_service.dart';
import 'package:UniSpace/services/protected_network_image.dart';

const source = 'https://firebasestorage.googleapis.com/v0/b/bucket/o/photo?token=old';
Map<String, Object> grant(String generation) => {
  'url': 'https://storage.googleapis.com/bucket/photo?generation=' + generation + '&X-Goog-Signature=short-lived',
  'expiresAt': DateTime.now().millisecondsSinceEpoch + 120000,
};
Future<void> decode(ProtectedCachedNetworkImageProvider provider, ProtectedImageKey key) async {
  final done = Completer<void>();
  final stream = provider.loadImage(key, (buffer, {getTargetSize}) =>
      ui.instantiateImageCodecWithSize(buffer, getTargetSize: getTargetSize));
  late ImageStreamListener listener;
  listener = ImageStreamListener((image, _) { image.dispose(); done.complete(); },
      onError: (Object error, StackTrace? stack) => done.completeError(error, stack));
  stream.addListener(listener);
  try { await done.future; } finally { stream.removeListener(listener); }
}

class _DiskCache extends Fake implements BaseCacheManager {
  final files = <String, FileInfo>{};
  final fs = MemoryFileSystem();
  int downloads = 0;
  late List<int> bytes;
  @override
  Future<FileInfo?> getFileFromCache(String key, {bool ignoreMemCache = false}) async => files[key];
  @override
  Future<File> getSingleFile(String url, {String? key, Map<String, String>? headers}) async {
    final existing = files[key];
    if (existing != null && existing.validTill.isAfter(DateTime.now())) return existing.file;
    downloads++;
    final file = fs.file('/image-$downloads')..writeAsBytesSync(bytes);
    files[key!] = FileInfo(file, FileSource.Cache,
        DateTime.now().subtract(const Duration(days: 1)), url);
    return file;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('expired immutable disk bytes survive widget recreation; changed generation downloads', () async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawColor(Colors.red, BlendMode.src);
    final picture = recorder.endRecording();
    final image = await picture.toImage(1, 1);
    final cache = _DiskCache()..bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
    image.dispose(); picture.dispose();
    var version = '1', session = 'a:1';
    var denied = false, authorizations = 0;
    final service = ProtectedMediaService(currentUid: () => 'a', viewerSession: () => session,
      read: (_) async {
        authorizations++;
        if (denied) throw StateError('denied');
        return grant(version);
      });
    Future<void> display() async {
      final provider = ProtectedCachedNetworkImageProvider.testing(source,
          service: service, cacheManager: cache);
      await decode(provider, await provider.obtainKey(ImageConfiguration.empty));
    }
    await display();
    await display();
    expect(cache.downloads, 1);
    expect(authorizations, 2);
    version = '2';
    await display();
    expect(cache.downloads, 2);
    await cache.files.values.last.file.delete();
    await display();
    expect(cache.downloads, 3);
    session = 'a:2';
    await display();
    expect(cache.downloads, 4);
    denied = true;
    await expectLater(display(), throwsStateError);
    expect(cache.downloads, 4);
  });
  test('generation and viewer session invalidate opaque cache keys', () async {
    var version = '1', session = 'a:1';
    final service = ProtectedMediaService(currentUid: () => 'a', viewerSession: () => session,
      read: (_) async => grant(version));
    final provider = ProtectedNetworkImage.testing(source, service: service, cacheKey: 'explicit');
    final first = await provider.obtainKey(ImageConfiguration.empty);
    expect(first.diskCacheKey, matches(RegExp(r'^[a-f0-9]{64}$')));
    expect(first.diskCacheKey, isNot(contains('token')));
    version = '2'; final second = await provider.obtainKey(ImageConfiguration.empty);
    expect(second, isNot(first)); expect(second.diskCacheKey, isNot(first.diskCacheKey));
    session = 'a:2'; final third = await provider.obtainKey(ImageConfiguration.empty);
    expect(third.diskCacheKey, isNot(second.diskCacheKey));
  });
  test('cached bytes reused only after fresh authorization and denial reads no disk', () async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawColor(Colors.red, BlendMode.src);
    final picture = recorder.endRecording();
    final image = await picture.toImage(1, 1);
    final data = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
    image.dispose(); picture.dispose();
    var authorizations = 0, reads = 0, downloads = 0, denied = false;
    final diskKeys = <String>{};
    final service = ProtectedMediaService(currentUid: () => 'a', viewerSession: () => 'a:1',
      read: (_) async { authorizations++; if (denied) throw StateError('denied'); return grant('1'); });
    final provider = ProtectedCachedNetworkImageProvider.testing(source, service: service,
      readBytes: (url, key) async { reads++; if (diskKeys.add(key)) downloads++; return data; });
    await decode(provider, await provider.obtainKey(ImageConfiguration.empty));
    await decode(provider, await provider.obtainKey(ImageConfiguration.empty));
    expect(authorizations, 2); expect(reads, 2); expect(downloads, 1);
    denied = true;
    await expectLater(provider.obtainKey(ImageConfiguration.empty), throwsStateError);
    expect(reads, 2); expect(authorizations, 3);
  });
}
