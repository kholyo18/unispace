import 'dart:async';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:UniSpace/services/chat_media_policy.dart';
import 'package:UniSpace/services/chat_audio_coordinator.dart';

void main() {
  const a = 'https://firebasestorage.googleapis.com/v0/b/test/o/a';
  const b = 'https://firebasestorage.googleapis.com/v0/b/test/o/b';
  const c = 'https://firebasestorage.googleapis.com/v0/b/test/o/c';
  test('cache is bounded, session separated and access rechecked on hit',
      () async {
    int loads = 0;
    bool allowed = true;
    final cache = ChatImageMemoryCache(
        maxBytes: 8,
        maxEntryBytes: 4,
        maxEntries: 2,
        download: (_, __) async {
          loads++;
          return Uint8List(4);
        });
    await cache.read('one', a, authorized: () => allowed);
    await cache.read('one', b, authorized: () => allowed);
    expect(cache.sizeBytes, 8);
    expect(cache.peek('one', a, authorized: () => allowed), isNotNull);
    await cache.read('one', c, authorized: () => allowed);
    expect(cache.peek('one', b, authorized: () => allowed), isNull);
    expect(cache.peek('two', a, authorized: () => allowed), isNull);
    allowed = false;
    expect(await cache.read('one', a, authorized: () => allowed), isNull);
    expect(loads, 3);
    cache.clearScope('one');
    expect(cache.sizeBytes, 0);
  });
  test('view-once, disallowed URLs and revoked pending loads never cache',
      () async {
    final pending = Completer<Uint8List>();
    int loads = 0;
    final cache = ChatImageMemoryCache(download: (_, __) {
      loads++;
      return pending.future;
    });
    expect(await cache.read('one', a, authorized: () => true, viewOnce: true),
        isNull);
    expect(
        await cache.read('one', 'https://evil.invalid/a',
            authorized: () => true),
        isNull);
    final result = cache.read('one', a, authorized: () => true);
    cache.clear();
    pending.complete(Uint8List(4));
    expect(await result, isNull);
    expect(cache.sizeBytes, 0);
    expect(loads, 1);
  });
  test('download count and individual byte size are bounded', () async {
    final pending = Completer<Uint8List>();
    int loads = 0;
    final cache = ChatImageMemoryCache(
        maxConcurrent: 1,
        maxEntryBytes: 4,
        download: (_, __) {
          loads++;
          return pending.future;
        });
    final first = cache.read('one', a, authorized: () => true);
    expect(await cache.read('one', b, authorized: () => true), isNull);
    pending.complete(Uint8List(5));
    expect(await first, isNull);
    expect(cache.sizeBytes, 0);
    expect(loads, 1);
  });
  test('network policy conservative for mobile and unknown transport', () {
    final policy = ChatMediaPolicy();
    expect(policy.mobile, true);
    policy.mobile = false;
    expect(policy.permits([ConnectivityResult.wifi]), true);
    expect(policy.permits([ConnectivityResult.mobile]), false);
    expect(policy.permits([ConnectivityResult.wifi, ConnectivityResult.mobile]),
        false);
    expect(policy.permits([ConnectivityResult.none]), false);
    policy.mobile = true;
    expect(policy.permits([ConnectivityResult.mobile]), true);
  });
  test('audio pauses previous before starting next and stop releases it',
      () async {
    final coordinator = ChatAudioCoordinator();
    final log = <String>[];
    await coordinator.play('a',
        start: () async {
          log.add('play a');
        },
        pause: () async {
          log.add('pause a');
        },
        valid: () => true);
    await coordinator.play('b',
        start: () async {
          log.add('play b');
        },
        pause: () async {
          log.add('pause b');
        },
        valid: () => true);
    await coordinator.stop();
    expect(log, ['play a', 'pause a', 'play b', 'pause b']);
  });
  test(
      'audio pause failure prevents overlap and obsolete queued play is skipped',
      () async {
    final coordinator = ChatAudioCoordinator();
    int starts = 0;
    await coordinator.play('a',
        start: () async {},
        pause: () async {
          throw StateError('pause failed');
        },
        valid: () => true);
    await expectLater(
        coordinator.play('b',
            start: () async {
              starts++;
            },
            pause: () async {},
            valid: () => true),
        throwsStateError);
    expect(starts, 0);
    coordinator.release('a');
    final obsolete = coordinator.play('b',
        start: () async {
          starts++;
        },
        pause: () async {},
        valid: () => true);
    final latest = coordinator.play('c',
        start: () async {
          starts += 10;
        },
        pause: () async {},
        valid: () => true);
    await Future.wait([obsolete, latest]);
    expect(starts, 10);
  });
  test('cache resizing evicts least recent bytes immediately', () async {
    final cache = ChatImageMemoryCache(
        maxBytes: 8, maxEntryBytes: 4, download: (_, __) async => Uint8List(4));
    await cache.read('one', a, authorized: () => true);
    await cache.read('one', b, authorized: () => true);
    cache.resize(4);
    expect(cache.sizeBytes, 4);
    expect(cache.peek('one', a, authorized: () => true), isNull);
    expect(cache.peek('one', b, authorized: () => true), isNotNull);
  });
  test('media preferences persist real supported limits and mobile choice',
      () async {
    SharedPreferences.setMockInitialValues({});
    final policy = ChatMediaPolicy();
    await policy.load();
    expect(policy.mobile, true);
    expect(policy.cacheMiB, 24);
    await policy.save(wifi: true, mobile: false, cacheMiB: 48);
    final restored = ChatMediaPolicy();
    await restored.load();
    expect(restored.mobile, false);
    expect(restored.cacheMiB, 48);
    expect(chatImageMemoryCache.maxBytes, 48 * 1024 * 1024);
    await expectLater(policy.save(wifi: true, mobile: true, cacheMiB: 999),
        throwsArgumentError);
    chatImageMemoryCache.clear();
    chatImageMemoryCache.resize(24 * 1024 * 1024);
  });
}
