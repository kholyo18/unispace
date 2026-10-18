import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as im;
import 'package:path_provider/path_provider.dart';

class PhotoStroke {
  PhotoStroke(this.points, this.color, this.width);
  final List<Offset> points;
  final Color color;
  final double width;
}

class PhotoText {
  const PhotoText(this.text, this.position, this.color, this.size);
  final String text;
  final Offset position;
  final Color color;
  final double size;
  PhotoText copy({Offset? position, double? size}) =>
      PhotoText(text, position ?? this.position, color, size ?? this.size);
}

class PhotoEdit {
  PhotoEdit({
    required this.path,
    this.turns = 0,
    this.filter = 0,
    List<PhotoStroke>? strokes,
    List<PhotoText>? texts,
  })  : strokes = strokes ?? [],
        texts = texts ?? [];
  final String path;
  final int turns, filter;
  final List<PhotoStroke> strokes;
  final List<PhotoText> texts;
  PhotoEdit copy({
    int? turns,
    int? filter,
    List<PhotoStroke>? strokes,
    List<PhotoText>? texts,
  }) =>
      PhotoEdit(
        path: path,
        turns: turns ?? this.turns,
        filter: filter ?? this.filter,
        strokes: strokes ?? this.strokes,
        texts: texts ?? this.texts,
      );
  bool get hasOverlays =>
      turns != 0 || filter != 0 || strokes.isNotEmpty || texts.isNotEmpty;
}

class PhotoHistory {
  PhotoHistory(PhotoEdit initial) : _states = [initial];
  final List<PhotoEdit> _states;
  int _index = 0;
  PhotoEdit get current => _states[_index];
  bool get canUndo => _index > 0;
  bool get canRedo => _index < _states.length - 1;
  void push(PhotoEdit edit) {
    _states.removeRange(_index + 1, _states.length);
    _states.add(edit);
    _index++;
  }

  void undo() {
    if (canUndo) _index--;
  }

  void redo() {
    if (canRedo) _index++;
  }
}

const maxChatPhotoSourceBytes = 80 * 1024 * 1024;

class PhotoSourceTooLarge implements Exception {
  const PhotoSourceTooLarge();
  @override
  String toString() => 'Photo source exceeds 80 MiB';
}

Future<ui.Image> decodePhoto(File file, {int maxEdge = 2560}) async {
  if (maxEdge <= 0) throw ArgumentError.value(maxEdge, 'maxEdge');
  final handle = await file.open();
  late Uint8List bytes;
  try {
    final length = await handle.length();
    if (length > maxChatPhotoSourceBytes) throw const PhotoSourceTooLarge();
    // Read at most the checked size, even if another process grows the file.
    bytes = await handle.read(length);
  } finally {
    await handle.close();
  }
  ui.ImmutableBuffer? buffer;
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  try {
    buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    final scale = math.min(
      1.0,
      maxEdge / math.max(descriptor.width, descriptor.height),
    );
    codec = await descriptor.instantiateCodec(
      targetWidth: math.max(1, (descriptor.width * scale).round()),
      targetHeight: math.max(1, (descriptor.height * scale).round()),
    );
    return (await codec.getNextFrame()).image;
  } finally {
    codec?.dispose();
    descriptor?.dispose();
    buffer?.dispose();
  }
}

Size photoSize(ui.Image image, PhotoEdit edit) => edit.turns.isOdd
    ? Size(image.height.toDouble(), image.width.toDouble())
    : Size(image.width.toDouble(), image.height.toDouble());
Offset photoSourcePoint(Offset display, int turns) {
  switch (turns % 4) {
    case 1:
      return Offset(display.dy, 1 - display.dx);
    case 2:
      return Offset(1 - display.dx, 1 - display.dy);
    case 3:
      return Offset(1 - display.dy, display.dx);
    default:
      return display;
  }
}

const photoFilters = <List<double>?>[
  null,
  [
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ],
  [1.1, 0, 0, 0, 0, 0, 1.02, 0, 0, 0, 0, 0, 0.9, 0, 0, 0, 0, 0, 1, 0],
];
void paintPhoto(
  Canvas canvas,
  Size output,
  ui.Image image,
  PhotoEdit edit, {
  TextDirection direction = TextDirection.ltr,
}) {
  final intrinsic = photoSize(image, edit);
  canvas.save();
  canvas.scale(
    output.width / intrinsic.width,
    output.height / intrinsic.height,
  );
  final w = image.width.toDouble(), h = image.height.toDouble();
  switch (edit.turns % 4) {
    case 1:
      canvas.translate(h, 0);
      canvas.rotate(math.pi / 2);
      break;
    case 2:
      canvas.translate(w, h);
      canvas.rotate(math.pi);
      break;
    case 3:
      canvas.translate(0, w);
      canvas.rotate(-math.pi / 2);
      break;
  }
  final paint = Paint()..filterQuality = FilterQuality.high;
  final matrix = photoFilters[edit.filter];
  if (matrix != null) paint.colorFilter = ColorFilter.matrix(matrix);
  canvas.drawImage(image, Offset.zero, paint);
  final edge = math.min(w, h);
  for (final stroke in edit.strokes) {
    if (stroke.points.isEmpty) continue;
    final p = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.width * edge
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final first = Offset(
      stroke.points.first.dx * w,
      stroke.points.first.dy * h,
    );
    if (stroke.points.length == 1) {
      canvas.drawCircle(
        first,
        p.strokeWidth / 2,
        Paint()..color = stroke.color,
      );
      continue;
    }
    final path = Path()..moveTo(first.dx, first.dy);
    for (final point in stroke.points.skip(1)) {
      path.lineTo(point.dx * w, point.dy * h);
    }
    canvas.drawPath(path, p);
  }
  for (final text in edit.texts) {
    final tp = TextPainter(
      text: TextSpan(
        text: text.text,
        style: TextStyle(
          color: text.color,
          fontSize: text.size * edge,
          fontWeight: FontWeight.w700,
          fontFamilyFallback: const ['NotoColorEmoji'],
          shadows: const [Shadow(color: Colors.black87, blurRadius: 3)],
        ),
      ),
      textDirection: direction,
      textAlign: TextAlign.center,
    )..layout(maxWidth: w * 0.95);
    tp.paint(
      canvas,
      Offset(
        (text.position.dx * w - tp.width / 2).clamp(
          0,
          math.max(0, w - tp.width),
        ),
        (text.position.dy * h - tp.height / 2).clamp(
          0,
          math.max(0, h - tp.height),
        ),
      ),
    );
    tp.dispose();
  }
  canvas.restore();
}

Future<Uint8List> renderPhoto(
  ui.Image image,
  PhotoEdit edit, {
  TextDirection direction = TextDirection.ltr,
}) async {
  final size = photoSize(image, edit);
  final recorder = ui.PictureRecorder();
  paintPhoto(Canvas(recorder), size, image, edit, direction: direction);
  final picture = recorder.endRecording();
  ui.Image? result;
  try {
    result = await picture.toImage(size.width.round(), size.height.round());
    final data = await result.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw StateError('Photo export failed');
    return data.buffer.asUint8List();
  } finally {
    result?.dispose();
    picture.dispose();
  }
}

/// Pure isolate entry point. Fully transparent or translucent pixels keep PNG.
Map<String, Object> encodeChatPhotoPixels(Map<String, Object> input) {
  final bytes = input['bytes']! as Uint8List;
  final width = input['width']! as int, height = input['height']! as int;
  var transparent = false;
  for (var i = 3; i < bytes.length; i += 4) {
    if (bytes[i] != 255) {
      transparent = true;
      break;
    }
  }
  final decoded = im.Image.fromBytes(
    width: width,
    height: height,
    bytes: bytes.buffer,
    bytesOffset: bytes.offsetInBytes,
    numChannels: 4,
  );
  return {
    'bytes': Uint8List.fromList(
      transparent
          ? im.encodePng(decoded)
          : im.encodeJpg(decoded, quality: input['hd'] == true ? 92 : 85),
    ),
    'extension': transparent ? 'png' : 'jpg',
  };
}

/// Native bounded decoding honors encoded orientation; CPU encoding runs off UI.
Future<File> prepareChatPhoto(File source, {required bool hd}) async {
  final handle = await source.open();
  late List<int> header;
  try {
    if (await handle.length() > maxChatPhotoSourceBytes)
      throw const PhotoSourceTooLarge();
    header = await handle.read(6);
  } finally {
    await handle.close();
  }
  if (header.length >= 3 &&
      header[0] == 71 &&
      header[1] == 73 &&
      header[2] == 70) return source;
  final image = await decodePhoto(source, maxEdge: hd ? 2560 : 1600);
  late Map<String, Object> result;
  try {
    final rgba = await image.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    if (rgba == null) throw StateError('Image encoding failed');
    result = await compute(encodeChatPhotoPixels, {
      'bytes': rgba.buffer.asUint8List(rgba.offsetInBytes, rgba.lengthInBytes),
      'width': image.width,
      'height': image.height,
      'hd': hd,
    });
  } finally {
    image.dispose();
  }
  final dir = await getTemporaryDirectory();
  final output = File(
    '${dir.path}/chat_ready_${DateTime.now().microsecondsSinceEpoch}.${result['extension']}',
  );
  try {
    return await output.writeAsBytes(
      result['bytes']! as Uint8List,
      flush: true,
    );
  } catch (_) {
    try {
      if (await output.exists()) await output.delete();
    } on FileSystemException {}
    rethrow;
  }
}
