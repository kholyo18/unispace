import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/services/authorized_video_cache.dart';

const first =
    'https://storage.googleapis.com/bucket/video.mp4?generation=42&X-Goog-Signature=one';
const renewed =
    'https://storage.googleapis.com/bucket/video.mp4?generation=42&X-Goog-Signature=two';
void main() {
  test(
      'renewed signature reuses bytes, but viewer and generation remain isolated',
      () async {
    final dir = await Directory.systemTemp.createTemp('authorized-video-test');
    addTearDown(() => dir.delete(recursive: true));
    final files = <String, File>{};
    var downloads = 0;
    final cache = AuthorizedVideoByteCache(
      lookup: (key) async => files[key],
      store: (key, bytes) async {
        files[key] = await File('${dir.path}/$key').writeAsBytes(bytes);
      },
      download: (_, __) async {
        downloads++;
        return Uint8List.fromList([1, 2, 3]);
      },
    );
    await cache.warm(first, 'viewer');
    expect(await cache.read(renewed, 'viewer'), isNotNull);
    await cache.warm(renewed, 'viewer');
    expect(downloads, 1);
    expect(await cache.read(renewed, 'other'), isNull);
    expect(
        await cache.read(renewed.replaceFirst('42', '43'), 'viewer'), isNull);
    expect(files.keys.single.contains('Signature'), isFalse);
  });
  test('disk miss returns immediately while optional download is pending',
      () async {
    final pending = Completer<Uint8List?>();
    var downloads = 0, stores = 0;
    final cache = AuthorizedVideoByteCache(
        lookup: (_) async => null,
        store: (_, __) async {
          stores++;
        },
        download: (_, __) {
          downloads++;
          return pending.future;
        });
    final warm = cache.warm(first, 'viewer');
    expect(await cache.read(first, 'viewer'), isNull);
    final duplicate = cache.warm(renewed, 'viewer');
    expect(identical(warm, duplicate), isTrue);
    expect(downloads, 1);
    pending.complete(Uint8List.fromList([1]));
    await warm;
    expect(stores, 1);
  });
  test(
      'rapid swipes bound transfers and oversized or failed bytes are never stored',
      () async {
    final pending = Completer<Uint8List?>();
    var downloads = 0, stores = 0;
    final cache = AuthorizedVideoByteCache(
        maxDownloads: 1,
        maxBytes: 2,
        lookup: (_) async => null,
        store: (_, __) async {
          stores++;
        },
        download: (_, __) {
          downloads++;
          return pending.future;
        });
    final warm = cache.warm(first, 'viewer');
    await cache.warm(first.replaceFirst('42', '43'), 'viewer');
    expect(downloads, 1);
    pending.complete(Uint8List.fromList([1, 2, 3]));
    await warm;
    expect(stores, 0);
    await cache.warm(first.replaceFirst('42', '44'), 'viewer');
    expect(downloads, 2);
  });
  test(
      'invalid identities do not touch disk or network; disk errors fail back to streaming',
      () async {
    var lookups = 0, downloads = 0;
    final cache = AuthorizedVideoByteCache(
        lookup: (_) async {
          lookups++;
          throw StateError('disk');
        },
        store: (_, __) async {},
        download: (_, __) async {
          downloads++;
          throw StateError('network');
        });
    await cache.warm(first, '');
    await cache.warm('https://example.com/video', 'viewer');
    expect(lookups, 0);
    expect(downloads, 0);
    expect(await cache.read(first, 'viewer'), isNull);
    await cache.warm(first, 'viewer');
    await cache.warm(first, 'viewer');
    expect(downloads, 2); // A failed warm does not poison later retries.
  });
}
