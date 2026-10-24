import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/services/protected_media_service.dart';
import 'package:UniSpace/services/protected_network_image.dart';

const locator =
    'https://firebasestorage.googleapis.com/v0/b/fachub-c631c.firebasestorage.app/o/users%2Fa%2Fphoto.jpg?alt=media&token=legacy';
const signed =
    'https://storage.googleapis.com/fachub-c631c.firebasestorage.app/users/a/photo.jpg?X-Goog-Signature=grant';
Map<String, Object> grant() => {
      'url': signed,
      'expiresAt': DateTime.now().millisecondsSinceEpoch + 120000
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('default resolver allows external images before Firebase initialization', () async {
    final result = await ProtectedMediaService.instance.resolve('https://lh3.googleusercontent.com/photo');
    expect(result.url, 'https://lh3.googleusercontent.com/photo');
    await expectLater(ProtectedMediaService.instance.resolve(locator), throwsStateError);
  });
  test('coalesces in-flight only and revalidates completed authorization',
      () async {
    var calls = 0;
    var pending = Completer<Object?>();
    final service = ProtectedMediaService(
        currentUid: () => 'a',
        viewerSession: () => 'a:1',
        read: (url) {
          expect(url, locator);
          calls++;
          return pending.future;
        });
    final first = service.resolve(locator);
    final second = service.resolve(locator);
    expect(calls, 1);
    pending.complete(grant());
    expect((await first).url, signed);
    expect((await second).url, signed);
    pending = Completer<Object?>();
    final third = service.resolve(locator);
    expect(calls, 2);
    pending.complete(grant());
    await third;
  });
  test('denied authorization never falls back to legacy token and can retry',
      () async {
    var deny = true;
    final service = ProtectedMediaService(
        currentUid: () => 'a',
        viewerSession: () => 'a:1',
        read: (_) async {
          if (deny) throw StateError('permission-denied');
          return grant();
        });
    await expectLater(service.resolve(locator), throwsStateError);
    deny = false;
    expect((await service.resolve(locator)).url, signed);
  });
  test('account and session changes discard pending grants', () async {
    var uid = 'a', session = 'a:1';
    var pending = Completer<Object?>();
    final service = ProtectedMediaService(
        currentUid: () => uid,
        viewerSession: () => session,
        read: (_) => pending.future);
    var request = service.resolve(locator);
    uid = 'b';
    pending.complete(grant());
    await expectLater(request, throwsStateError);
    uid = 'a';
    pending = Completer<Object?>();
    request = service.resolve(locator);
    session = 'a:2';
    pending.complete(grant());
    await expectLater(request, throwsStateError);
  });
  test('expired and non-signed server URLs fail closed', () async {
    Object? response = {'url': signed, 'expiresAt': 0};
    final service = ProtectedMediaService(
        currentUid: () => 'a',
        viewerSession: () => 'a:1',
        read: (_) async => response);
    await expectLater(service.resolve(locator), throwsStateError);
    response = {
      'url': locator,
      'expiresAt': DateTime.now().millisecondsSinceEpoch + 120000
    };
    await expectLater(service.resolve(locator), throwsStateError);
  });
  test(
      'external HTTPS and preauthorized GCS remain compatible, insecure URLs denied',
      () async {
    final service = ProtectedMediaService(
        currentUid: () => null,
        viewerSession: () => null,
        read: (_) async => fail('No backend request expected'));
    expect(
        (await service.resolve('https://lh3.googleusercontent.com/photo')).url,
        'https://lh3.googleusercontent.com/photo');
    expect((await service.resolve(signed)).url, signed);
    await expectLater(service.resolve(locator), throwsStateError);
    await expectLater(
        service.resolve('http://example.com/photo'), throwsStateError);
  });
  test('provider authorizes again even with a warm decoded-cache key',
      () async {
    var calls = 0, deny = false;
    final service = ProtectedMediaService(
        currentUid: () => 'a',
        viewerSession: () => 'a:1',
        read: (_) async {
          calls++;
          if (deny) throw StateError('denied');
          return grant();
        });
    final provider = ProtectedNetworkImage.testing(locator, service: service);
    final key = await provider.obtainKey(ImageConfiguration.empty);
    final image = Completer<ImageInfo>();
    final cache = PaintingBinding.instance.imageCache;
    cache.putIfAbsent(key, () => OneFrameImageStreamCompleter(image.future));
    expect(cache.containsKey(key), isTrue);
    deny = true;
    await expectLater(
        provider.obtainKey(ImageConfiguration.empty), throwsStateError);
    expect(calls, 2);
    cache.evict(key);
  });
  test('same image keys cannot share cached bytes across viewer sessions',
      () async {
    var session = 'a:1';
    final service = ProtectedMediaService(
        currentUid: () => 'a',
        viewerSession: () => session,
        read: (_) async => grant());
    final provider = ProtectedNetworkImage.testing(locator, service: service);
    final first = await provider.obtainKey(ImageConfiguration.empty);
    expect(await provider.obtainKey(ImageConfiguration.empty), first);
    session = 'a:2';
    expect(await provider.obtainKey(ImageConfiguration.empty), isNot(first));
  });
}

