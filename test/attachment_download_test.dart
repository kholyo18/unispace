import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/services/attachment_download.dart';

void main() {
  late Directory root;
  late Directory downloads;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('attachment-test-');
    downloads = await Directory('${root.path}/downloads').create();
  });
  tearDown(() async => root.delete(recursive: true));

  test('stream writes complete chunks and reports real byte progress',
      () async {
    final progress = <int>[];
    final file = await streamDownloadedAttachment(
        downloads,
        'video.mp4',
        Stream.fromIterable([
          [1, 2],
          [3, 4, 5]
        ]),
        maxBytes: 5,
        expectedBytes: 5,
        onProgress: progress.add);
    expect(await file.readAsBytes(), [1, 2, 3, 4, 5]);
    expect(progress, [2, 5]);
  });
  test('truncated oversized and interrupted streams remove partial files',
      () async {
    for (final stream in [
      Stream<List<int>>.value([1]),
      Stream<List<int>>.value([1, 2, 3, 4]),
      Stream<List<int>>.error(StateError('network'))
    ]) {
      await expectLater(
          streamDownloadedAttachment(downloads, 'file', stream,
              maxBytes: 3, expectedBytes: 3),
          throwsA(anything));
      expect(await downloads.list().toList(), isEmpty);
    }
  });
  test('cancellation from progress deletes partial download', () async {
    await expectLater(
        streamDownloadedAttachment(downloads, 'file', Stream.value([1, 2]),
            maxBytes: 3, onProgress: (_) => throw StateError('cancel')),
        throwsStateError);
    expect(await downloads.list().toList(), isEmpty);
  });
  test('remote traversal cannot overwrite a file outside downloads', () async {
    final sentinel = File('${root.path}/private.txt');
    await sentinel.writeAsString('unchanged');
    await expectLater(
        saveDownloadedAttachment(downloads, '../private.txt', [1]),
        throwsFormatException);
    expect(await sentinel.readAsString(), 'unchanged');
  });
  test('rejects path separators and unsafe portable file names', () async {
    for (final name in [
      '',
      '.',
      '..',
      if (Platform.isWindows) r'..\private.txt',
      '/private.txt',
      if (Platform.isWindows) r'C:\private.txt',
      if (Platform.isWindows) 'name:stream',
      'bad\u0000.txt',
      if (Platform.isWindows) 'tail.',
      if (Platform.isWindows) 'tail '
    ]) {
      await expectLater(
          saveDownloadedAttachment(downloads, name, [1]), throwsFormatException,
          reason: name);
    }
  });
  test('valid mobile punctuation is preserved on mobile platforms', () async {
    for (final name in [
      'Lecture: week 1.pdf',
      'Why?.pdf',
      'CON.txt',
      'notes.',
      r'back\slash.txt'
    ]) {
      final file = await saveDownloadedAttachment(downloads, name, [4]);
      expect(await file.readAsBytes(), [4]);
      expect(file.parent.parent.path, downloads.path);
    }
  }, skip: Platform.isWindows);
  test('ordinary Unicode names and bytes survive download', () async {
    final file =
        await saveDownloadedAttachment(downloads, 'ملخص الدرس.pdf', [1, 2, 3]);
    expect(await file.readAsBytes(), [1, 2, 3]);
    expect(file.uri.pathSegments.last, 'ملخص الدرس.pdf');
    expect(file.parent.parent.path, downloads.path);
  });
  test('repeated and concurrent names cannot replace previous downloads',
      () async {
    final files = await Future.wait([
      saveDownloadedAttachment(downloads, 'photo.jpg', [1]),
      saveDownloadedAttachment(downloads, 'photo.jpg', [2]),
    ]);
    expect(files[0].path, isNot(files[1].path));
    expect(await files[0].readAsBytes(), [1]);
    expect(await files[1].readAsBytes(), [2]);
  });
}
