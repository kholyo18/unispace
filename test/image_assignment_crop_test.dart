import 'dart:io';

import 'package:UniSpace/widgets/image_assignment_crop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.hunghd.vn/image_cropper');
  late Directory directory;
  late File source;
  late File cropped;
  late List<MethodCall> calls;
  String? result;
  PlatformException? failure;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('assignment_crop_test_');
    source = File('${directory.path}/original.jpg')
      ..writeAsBytesSync([1, 2, 3]);
    cropped = File('${directory.path}/accepted.jpg')
      ..writeAsBytesSync([4, 5, 6]);
    result = cropped.path;
    failure = null;
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (failure != null) throw failure!;
      return result;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    // Delete only the test-owned temporary directory.
    directory.deleteSync(recursive: true);
  });

  Future<BuildContext> mount(WidgetTester tester,
      [String language = 'en']) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(
      locale: Locale(language),
      supportedLocales: const [Locale('ar'), Locale('en'), Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Builder(builder: (value) {
        context = value;
        return const Scaffold();
      }),
    ));
    await tester.pumpAndSettle();
    return context;
  }

  testWidgets('free crop returns accepted output and preserves the input file',
      (tester) async {
    final context = await mount(tester);
    final value =
        await tester.runAsync(() => cropImageForAssignment(context, source));
    expect(value?.path, cropped.path);
    expect(source.readAsBytesSync(), [1, 2, 3]);
    expect(calls.single.method, 'cropImage');
    final args = calls.single.arguments as Map;
    expect(args['source_path'], source.path);
    expect(args['ratio_x'], isNull);
    expect(args['ratio_y'], isNull);
    expect(args['android.lock_aspect_ratio'], false);
    expect(args['ios.aspect_ratio_lock_enabled'], false);
    expect(args['ios.reset_aspect_ratio_enabled'], true);
    expect(args['android.crop_style'], 'rectangle');
    expect(args['max_width'], 2560);
    expect(args['max_height'], 2560);
  });

  testWidgets('avatar uses circular preview and a locked square crop',
      (tester) async {
    final context = await mount(tester);
    await tester.runAsync(() =>
        cropImageForAssignment(context, source, aspectRatio: 3, circle: true));
    final args = calls.single.arguments as Map;
    expect(args['ratio_x'], 1.0);
    expect(args['ratio_y'], 1.0);
    expect(args['android.crop_style'], 'circle');
    expect(args['ios.crop_style'], 'circle');
    expect(args['android.lock_aspect_ratio'], true);
    expect(args['ios.aspect_ratio_lock_enabled'], true);
    expect(args['ios.reset_aspect_ratio_enabled'], false);
  });

  testWidgets('fixed cover crop keeps the requested aspect ratio',
      (tester) async {
    final context = await mount(tester);
    await tester.runAsync(
        () => cropImageForAssignment(context, source, aspectRatio: 16 / 9));
    final args = calls.single.arguments as Map;
    expect(args['ratio_x'], 16 / 9);
    expect(args['ratio_y'], 1.0);
    expect(args['android.crop_style'], 'rectangle');
    expect(args['android.lock_aspect_ratio'], true);
    expect(args['ios.aspect_ratio_lock_enabled'], true);
  });

  testWidgets('cancel returns null instead of assigning the unedited image',
      (tester) async {
    result = null;
    final context = await mount(tester);
    final value =
        await tester.runAsync(() => cropImageForAssignment(context, source));
    expect(value, isNull);
    expect(source.readAsBytesSync(), [1, 2, 3]);
    expect(calls, hasLength(1));
  });

  testWidgets('native failure propagates without returning a replacement',
      (tester) async {
    failure =
        PlatformException(code: 'crop_failed', message: 'Native crop failed');
    final context = await mount(tester);
    File? assigned;
    await tester.runAsync(() async {
      await expectLater(() async {
        assigned = await cropImageForAssignment(context, source);
      },
          throwsA(isA<PlatformException>()
              .having((e) => e.code, 'code', 'crop_failed')));
    });
    expect(assigned, isNull);
    expect(source.readAsBytesSync(), [1, 2, 3]);
  });

  testWidgets('invalid ratios fail before invoking the native cropper',
      (tester) async {
    final context = await mount(tester);
    for (final ratio in [0.0, -1.0, double.nan, double.infinity]) {
      await expectLater(
          cropImageForAssignment(context, source, aspectRatio: ratio),
          throwsArgumentError);
    }
    expect(calls, isEmpty);
  });

  for (final entry in {
    'ar': 'حرّك الصورة وكبّرها للقص',
    'en': 'Move and zoom to crop',
    'fr': 'Déplacer et zoomer pour recadrer',
  }.entries) {
    testWidgets('native instructions follow ${entry.key} app language',
        (tester) async {
      final context = await mount(tester, entry.key);
      await tester.runAsync(() => cropImageForAssignment(context, source));
      final args = calls.single.arguments as Map;
      expect(args['android.toolbar_title'], entry.value);
      expect(args['ios.title'], entry.value);
    });
  }
}
