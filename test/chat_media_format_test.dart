import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/services/chat_media_format.dart';

List<int> ftyp(String major, [List<String> compatible = const []]) => [
      0, 0, 0, 16 + compatible.length * 4,
      ...'ftyp'.codeUnits,
      ...major.codeUnits,
      0, 0, 0, 0,
      for (final brand in compatible) ...brand.codeUnits,
    ];

void main() {
  test('image signatures override misleading filename extensions', () {
    final signatures = <List<int>, (String, String)>{
      [0x89, 0x50, 0x4e, 0x47, 13, 10, 26, 10]: ('png', 'image/png'),
      'GIF87a'.codeUnits: ('gif', 'image/gif'),
      'GIF89a'.codeUnits: ('gif', 'image/gif'),
      [0xff, 0xd8, 0xff]: ('jpg', 'image/jpeg'),
      [...'RIFF'.codeUnits, 0, 0, 0, 0, ...'WEBP'.codeUnits]: ('webp', 'image/webp'),
      'BM'.codeUnits: ('bmp', 'image/bmp'),
      ftyp('heic'): ('heic', 'image/heic'),
      ftyp('heix'): ('heic', 'image/heic'),
      ftyp('mif1'): ('heif', 'image/heif'),
      ftyp('msf1'): ('heif', 'image/heif'),
      ftyp('avif'): ('avif', 'image/avif'),
      ftyp('avis'): ('avif', 'image/avif'),
      ftyp('mif1', ['heic']): ('heic', 'image/heic'),
      ftyp('mif1', ['avif']): ('avif', 'image/avif'),
    };
    for (final item in signatures.entries) {
      final format = detectChatImageFormat(item.key, 'wrong.jpeg');
      expect(format.extension, item.value.$1);
      expect(format.contentType, item.value.$2);
      expect(format.isGif, item.value.$1 == 'gif');
    }
  });

  test('only recognized image extensions provide a fallback', () {
    for (final extension in ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif', 'avif']) {
      final format = detectChatImageFormat([], 'C:\\photos\\picked.${extension.toUpperCase()}');
      expect(format.extension, extension == 'jpeg' ? 'jpg' : extension);
    }
    expect(() => detectChatImageFormat([], '/folder.png/unknown'), throwsFormatException);
    expect(() => detectChatImageFormat([0, 1, 2], 'unknown.bin'), throwsFormatException);
    expect(() => detectChatImageFormat('GIF89'.codeUnits, 'unknown'), throwsFormatException);
    expect(() => detectChatImageFormat(ftyp('mp42'), 'video.mp4'), throwsFormatException);
  });

  test('ftyp minor version and data after the box are not image brands', () {
    final version = ftyp('mp42');
    version.setRange(12, 16, 'avif'.codeUnits);
    expect(() => detectChatImageFormat(version, 'unknown'), throwsFormatException);
    expect(() => detectChatImageFormat([...ftyp('mp42'), ...'avif'.codeUnits], 'unknown'), throwsFormatException);
  });

  test('video extensions preserve each supported MIME', () {
    const formats = {
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'm4v': 'video/x-m4v',
      'webm': 'video/webm',
      'mkv': 'video/x-matroska',
      '3gp': 'video/3gpp',
    };
    for (final entry in formats.entries) {
      final format = detectChatVideoFormat('/camera/recording.${entry.key.toUpperCase()}');
      expect(format.extension, entry.key);
      expect(format.contentType, entry.value);
      expect(format.isGif, isFalse);
    }
    expect(() => detectChatVideoFormat('/directory.mp4/unknown'), throwsFormatException);
    expect(() => detectChatVideoFormat('video.avi'), throwsFormatException);
    expect(() => detectChatVideoFormat('video'), throwsFormatException);
  });
}
