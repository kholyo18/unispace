import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as im;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:UniSpace/features/shell/chat/chat_photo_editor.dart';
import 'package:UniSpace/features/shell/chat/photo_edit_model.dart';

class _PhotoPaths extends PathProviderPlatform {
  _PhotoPaths(this.path);
  final String path;
  @override
  Future<String?> getTemporaryPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late File original;
  late List<int> originalBytes;
  late PathProviderPlatform previous;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('photo_editor_ui_');
    original = File('${directory.path}/source.png');
    final source = im.Image(width: 120, height: 80);
    im.fill(source, color: im.ColorRgb8(220, 20, 30));
    im.fillRect(source,
        x1: 60, y1: 0, x2: 119, y2: 79, color: im.ColorRgb8(10, 30, 220));
    originalBytes = im.encodePng(source);
    await original.writeAsBytes(originalBytes);
    previous = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _PhotoPaths(directory.path);
  });
  tearDown(() async {
    PathProviderPlatform.instance = previous;
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  Finder canvas() => find.byWidgetPredicate((w) =>
      w is CustomPaint && w.painter.runtimeType.toString() == '_PhotoPainter');
  PhotoEdit edit(WidgetTester tester) =>
      (tester.widget<CustomPaint>(canvas()).painter as dynamic).edit
          as PhotoEdit;
  Future<void> waitFor(WidgetTester tester, bool Function() predicate) async {
    for (var i = 0; i < 300 && !predicate(); i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(predicate(), true);
  }

  Future<void> open(WidgetTester tester,
      {String locale = 'en', ValueChanged<File?>? result}) async {
    await tester.pumpWidget(MaterialApp(
      locale: Locale(locale),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Builder(
          builder: (context) => Scaffold(
              body: TextButton(
                  onPressed: () async {
                    final file = await Navigator.of(context).push<File>(
                        MaterialPageRoute(
                            builder: (_) =>
                                ChatPhotoEditorPage(file: original)));
                    result?.call(file);
                  },
                  child: const Text('Open')))),
    ));
    await tester.tap(find.text('Open'));
    await waitFor(tester, () => canvas().evaluate().isNotEmpty);
    await tester.pumpAndSettle();
  }

  Future<void> tool(WidgetTester tester, String tooltip) async {
    final target = find.byTooltip(tooltip);
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> saveText(WidgetTester tester, String value) async {
    await tester.enterText(
        find.byKey(const ValueKey('photo-text-input')), value);
    await tester.pump();
    final done = find.widgetWithText(FilledButton, 'Done');
    await tester.ensureVisible(done);
    await tester.tap(done);
    await tester.pumpAndSettle();
  }

  testWidgets('text add edit move and history retain a single editable layer',
      (tester) async {
    await open(tester);
    await tool(tester, 'Text');
    await saveText(tester, 'Hello');
    expect(edit(tester).texts.single.text, 'Hello');
    await tool(tester, 'Text');
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('photo-text-input')))
            .controller!
            .text,
        'Hello');
    await saveText(tester, 'Edited');
    expect(edit(tester).texts.single.text, 'Edited');
    final before = edit(tester).texts.single.position;
    final center = tester.getCenter(canvas());
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(30, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(25, 15));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(edit(tester).texts.single.position, isNot(before));
    await tool(tester, 'Undo');
    expect(edit(tester).texts.single.position, before);
    await tool(tester, 'Undo');
    expect(edit(tester).texts.single.text, 'Hello');
    await tool(tester, 'Redo');
    expect(edit(tester).texts.single.text, 'Edited');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'drawing undo redo and Done export real pixels without overwriting source',
      (tester) async {
    File? result;
    await open(tester, result: (file) => result = file);
    await tool(tester, 'Draw');
    await tester.dragFrom(tester.getCenter(canvas()), const Offset(45, 0));
    await tester.pumpAndSettle();
    expect(edit(tester).strokes, hasLength(1));
    await tool(tester, 'Undo');
    expect(edit(tester).strokes, isEmpty);
    await tool(tester, 'Redo');
    expect(edit(tester).strokes, hasLength(1));
    await tool(tester, 'Rotate');
    await tester.tap(find.widgetWithText(TextButton, 'Done'));
    await waitFor(tester, () => result != null);
    await tester.pumpAndSettle();
    expect(result!.path, isNot(original.path));
    await tester.runAsync(() async {
      expect(await original.readAsBytes(), originalBytes);
      final output = im.decodeImage(await result!.readAsBytes())!;
      expect(output.width, 80);
      expect(output.height, 120);
      expect(output.getPixel(10, 10).r, greaterThan(180));
      expect(output.getPixel(10, 100).b, greaterThan(180));
    });
    expect(find.text('Open'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('narrow Arabic editor drawing and text sheet do not overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await open(tester, locale: 'ar');
    await tool(tester, 'رسم');
    expect(tester.takeException(), isNull);
    await tool(tester, 'نص');
    await tester.enterText(
        find.byKey(const ValueKey('photo-text-input')), 'مرحبا بكم');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'pinch scales and rotates selected text and undo restores transform',
      (tester) async {
    await open(tester);
    await tool(tester, 'Text');
    await saveText(tester, 'Resize me');
    final initial = edit(tester).texts.single;
    final center = tester.getCenter(canvas());
    final left =
        await tester.startGesture(center - const Offset(18, 0), pointer: 1);
    final right =
        await tester.startGesture(center + const Offset(18, 0), pointer: 2);
    await tester.pump();
    await left.moveTo(center - const Offset(24, 0));
    await right.moveTo(center + const Offset(24, 0));
    await tester.pump();
    await left.moveTo(center - const Offset(45, 15));
    await right.moveTo(center + const Offset(45, 15));
    await tester.pump();
    await left.up();
    await right.up();
    await tester.pumpAndSettle();
    expect(edit(tester).texts.single.size, greaterThan(initial.size));
    expect(edit(tester).texts.single.angle.abs(), greaterThan(.05));
    await tool(tester, 'Undo');
    expect(edit(tester).texts.single.size, initial.size);
    expect(edit(tester).texts.single.angle, initial.angle);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'reset can be undone and discard confirmation preserves or cancels edits',
      (tester) async {
    var returned = false;
    File? result;
    await open(tester, result: (file) {
      returned = true;
      result = file;
    });
    await tool(tester, 'Rotate');
    await tool(tester, 'Reset');
    expect(edit(tester).turns, 0);
    await tool(tester, 'Undo');
    expect(edit(tester).turns, 1);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Discard edits?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(edit(tester).turns, 1);
    expect(returned, false);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(returned, true);
    expect(result, isNull);
    await tester.runAsync(
        () async => expect(await original.readAsBytes(), originalBytes));
    await tester.pumpWidget(const SizedBox());
  });
}
