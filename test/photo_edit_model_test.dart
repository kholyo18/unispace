import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:image/image.dart' as im;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/shell/chat/photo_edit_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('oversize source rejected before native decoding', () async {
    final dir = await Directory.systemTemp.createTemp('photo_limit_');
    try {
      final file = File(dir.path + '/large.png');
      final handle = await file.open(mode: FileMode.write);
      try {
        await handle.truncate(maxChatPhotoSourceBytes + 1);
      } finally {
        await handle.close();
      }
      await expectLater(decodePhoto(file), throwsA(isA<PhotoSourceTooLarge>()));
    } finally {
      await dir.delete(recursive: true);
    }
  });
  test('bounded decode preserves aspect and does not upscale', () async {
    final dir = await Directory.systemTemp.createTemp('photo_bounds_');
    try {
      final file = File(dir.path + '/source.png');
      await file.writeAsBytes(im.encodePng(im.Image(width: 40, height: 10)));
      final reduced = await decodePhoto(file, maxEdge: 20);
      expect(reduced.width, 20);
      expect(reduced.height, 5);
      reduced.dispose();
      final unchanged = await decodePhoto(file, maxEdge: 100);
      expect(unchanged.width, 40);
      expect(unchanged.height, 10);
      unchanged.dispose();
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('opaque export uses JPEG with unchanged dimensions', () {
    final result = encodeChatPhotoPixels({
      'bytes': Uint8List.fromList([255, 0, 0, 255, 0, 0, 255, 255]),
      'width': 2,
      'height': 1,
      'hd': true,
    });
    expect(result['extension'], 'jpg');
    final bytes = result['bytes']! as Uint8List;
    expect(bytes.take(2), [255, 216]);
    final image = im.decodeJpg(bytes)!;
    expect(image.width, 2);
    expect(image.height, 1);
  });
  test('alpha survives export as PNG', () {
    final result = encodeChatPhotoPixels({
      'bytes': Uint8List.fromList([255, 0, 0, 80]),
      'width': 1,
      'height': 1,
      'hd': false,
    });
    expect(result['extension'], 'png');
    final image = im.decodePng(result['bytes']! as Uint8List)!;
    expect(image.getPixel(0, 0).a, 80);
  });
  Future<ui.Image> source() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 20, 10),
      Paint()..color = const Color(0xFFFF0000),
    );
    canvas.drawRect(
      const Rect.fromLTWH(20, 0, 20, 10),
      Paint()..color = const Color(0xFF0000FF),
    );
    final p = recorder.endRecording();
    final image = await p.toImage(40, 10);
    p.dispose();
    return image;
  }

  Future<ui.Image> exported(ui.Image image, PhotoEdit edit) async {
    final data = await renderPhoto(image, edit);
    final codec = await ui.instantiateImageCodec(data);
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  Future<List<int>> pixel(ui.Image image, int x, int y) async {
    final bytes = (await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!
        .buffer
        .asUint8List();
    return bytes.sublist(
      (y * image.width + x) * 4,
      (y * image.width + x) * 4 + 4,
    );
  }

  test(
    'source-resolution export preserves aspect and exact image pixels',
    () async {
      final image = await source();
      final output = await exported(image, PhotoEdit(path: 'original'));
      expect(output.width, 40);
      expect(output.height, 10);
      expect(await pixel(output, 3, 3), [255, 0, 0, 255]);
      expect(await pixel(output, 33, 3), [0, 0, 255, 255]);
      output.dispose();
      image.dispose();
    },
  );
  test(
    'clockwise rotation swaps dimensions and retains corner colors',
    () async {
      final image = await source();
      final output = await exported(
        image,
        PhotoEdit(path: 'original', turns: 1),
      );
      expect(output.width, 10);
      expect(output.height, 40);
      expect(await pixel(output, 4, 3), [255, 0, 0, 255]);
      expect(await pixel(output, 4, 33), [0, 0, 255, 255]);
      output.dispose();
      image.dispose();
    },
  );
  test('single-point stroke is visible with its own color', () async {
    final image = await source();
    final output = await exported(
      image,
      PhotoEdit(
        path: 'original',
        strokes: [
          PhotoStroke([const Offset(.5, .5)], Colors.green, 1),
        ],
      ),
    );
    expect(await pixel(output, 20, 5), [76, 175, 80, 255]);
    output.dispose();
    image.dispose();
  });
  test('source point mapping is inverse of quarter-turn rotation', () {
    expect(photoSourcePoint(const Offset(.2, .3), 0), const Offset(.2, .3));
    expect(photoSourcePoint(const Offset(.2, .3), 1), const Offset(.3, .8));
    expect(photoSourcePoint(const Offset(.2, .3), 2), const Offset(.8, .7));
    expect(photoSourcePoint(const Offset(.2, .3), 3), const Offset(.7, .2));
  });
  test('undo redo preserves crop source and discards obsolete redo branch', () {
    final history = PhotoHistory(PhotoEdit(path: 'original'));
    history.push(history.current.copy(turns: 1));
    history.push(PhotoEdit(path: 'cropped'));
    history.undo();
    expect(history.current.path, 'original');
    expect(history.current.turns, 1);
    history.redo();
    expect(history.current.path, 'cropped');
    history.undo();
    history.push(history.current.copy(filter: 1));
    expect(history.canRedo, false);
    expect(history.current.path, 'original');
  });
  test('moving text does not mutate prior undo snapshot', () {
    final history = PhotoHistory(
      PhotoEdit(
        path: 'original',
        texts: [
          const PhotoText('مرحبا 👨‍👩‍👧', Offset(.5, .5), Colors.white, .1),
        ],
      ),
    );
    history.push(
      history.current.copy(
        texts: [
          history.current.texts.first.copy(position: const Offset(.2, .3)),
        ],
      ),
    );
    history.undo();
    expect(history.current.texts.first.position, const Offset(.5, .5));
    history.redo();
    expect(history.current.texts.first.position, const Offset(.2, .3));
  });
}
