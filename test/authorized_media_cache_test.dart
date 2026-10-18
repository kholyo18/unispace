import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/services/authorized_media_cache.dart';

void main() {
  const a = 'https://storage.googleapis.com/bucket/photo.jpg?generation=42&X-Goog-Signature=one';
  test('renewed signature reuses bytes of the same authorized generation', () {
    expect(authorizedMediaCacheKey(a, 'alice'),
        authorizedMediaCacheKey(a.replaceAll('one', 'two'), 'alice'));
  });
  test('new object, generation and account cannot collide', () {
    final key = authorizedMediaCacheKey(a, 'alice');
    expect(key, isNot(authorizedMediaCacheKey(a.replaceAll('42', '43'), 'alice')));
    expect(key, isNot(authorizedMediaCacheKey(a.replaceAll('photo', 'other'), 'alice')));
    expect(key, isNot(authorizedMediaCacheKey(a, 'bob')));
  });
  test('unknown hosts or missing generation retain full URL identity', () {
    for (final url in [a.replaceAll('storage.googleapis.com', 'example.org'),
      a.replaceAll('generation=42&', '')]) {
      expect(authorizedMediaCacheKey(url, 'alice'),
          isNot(authorizedMediaCacheKey(url.replaceAll('one', 'two'), 'alice')));
    }
  });
}
