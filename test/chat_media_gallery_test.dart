import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:UniSpace/features/shell/chat/chat_media_gallery.dart';

class Gallery extends ChatGallerySource {
  PermissionState permission = PermissionState.authorized;
  int reads = 0, settingsCalls = 0, limitedCalls = 0, fileCalls = 0;
  bool fail = false, missing = false;
  Completer<File?>? pending;
  @override
  Future<PermissionState> access() async => permission;
  @override
  Future<List<AssetEntity>> page(int page) async {
    reads++;
    if (fail) throw StateError('unavailable');
    return [
      AssetEntity(id: 'image', typeInt: 1, width: 100, height: 100),
      AssetEntity(
          id: 'video', typeInt: 2, width: 100, height: 100, duration: 65)
    ];
  }

  @override
  Future<Uint8List?> thumbnail(AssetEntity asset) async => null;
  @override
  Future<File?> file(AssetEntity asset) async {
    fileCalls++;
    if (pending != null) return pending!.future;
    return missing
        ? null
        : File('/${asset.id}.${asset.typeInt == 2 ? 'mp4' : 'jpg'}');
  }

  @override
  Future<void> settings() async {
    settingsCalls++;
  }

  @override
  Future<void> limited() async {
    limitedCalls++;
  }
}

void main() {
  Future<void> show(WidgetTester tester, Gallery source,
      {Future<void> Function(List<File>)? selected,
      VoidCallback? camera,
      int maxSelection = 30}) async {
    await tester.pumpWidget(MaterialApp(
        theme: const bool.fromEnvironment('GALLERY_DARK_TEST')
            ? ThemeData.dark()
            : ThemeData.light(),
        home: Scaffold(
            body: ChatMediaGallery(
          source: source,
          maxSelection: maxSelection,
          header: const Text('Attachment actions'),
          onCamera: camera ?? () {},
          onSelected: selected ?? (_) async {},
        ))));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'media below actions and camera first; no file loaded before Next',
      (tester) async {
    final source = Gallery();
    var camera = 0;
    List<File>? files;
    await show(tester, source,
        camera: () => camera++,
        selected: (value) async {
          files = value;
        });
    expect(tester.getTopLeft(find.byKey(const ValueKey('image'))).dy,
        greaterThan(tester.getTopLeft(find.text('Attachment actions')).dy));
    await tester.tap(find.byKey(const ValueKey('gallery-camera')));
    expect(camera, 1);
    expect(find.text('▶ 1:05'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('video')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('image')));
    await tester.pump();
    expect(source.fileCalls, 0);
    expect(files, isNull);
    await tester.tap(find.text('Next (2)'));
    await tester.pumpAndSettle();
    expect(files!.map((f) => f.path), ['/video.mp4', '/image.jpg']);
  });
  testWidgets('wallpaper selection replaces previous item and returns one file',
      (tester) async {
    List<File>? files;
    await show(tester, Gallery(), maxSelection: 1, selected: (value) async {
      files = value;
    });
    await tester.tap(find.byKey(const ValueKey('image')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('video')));
    await tester.pump();
    expect(find.text('Next (1)'), findsOneWidget);
    expect(find.text('Next (2)'), findsNothing);
    await tester.tap(find.text('Next (1)'));
    await tester.pumpAndSettle();
    expect(files!.map((f) => f.path), ['/video.mp4']);
  });
  testWidgets('deselecting all hides review action', (tester) async {
    await show(tester, Gallery());
    await tester.tap(find.byKey(const ValueKey('image')));
    await tester.pump();
    expect(find.text('Next (1)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('image')));
    await tester.pump();
    expect(find.text('Next (1)'), findsNothing);
  });
  testWidgets('denied access does not query media and keeps camera available',
      (tester) async {
    final source = Gallery()..permission = PermissionState.denied;
    await show(tester, source);
    expect(source.reads, 0);
    expect(find.byKey(const ValueKey('gallery-camera')), findsOneWidget);
    await tester.tap(find.text('Open settings'));
    await tester.pump();
    expect(source.settingsCalls, 1);
  });
  testWidgets('limited access shows accessible items and management',
      (tester) async {
    final source = Gallery()..permission = PermissionState.limited;
    await show(tester, source);
    expect(find.byKey(const ValueKey('image')), findsOneWidget);
    await tester.tap(find.text('Manage access'));
    await tester.pumpAndSettle();
    expect(source.limitedCalls, 1);
    expect(source.reads, 2);
  });
  testWidgets('load failure retries without leaving gallery', (tester) async {
    final source = Gallery()..fail = true;
    await show(tester, source);
    source.fail = false;
    await tester.tap(find.text('Gallery unavailable. Retry'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('image')), findsOneWidget);
  });
  testWidgets('missing media never sends a partial selection', (tester) async {
    final source = Gallery()..missing = true;
    var sent = 0;
    await show(tester, source, selected: (_) async {
      sent++;
    });
    await tester.tap(find.byKey(const ValueKey('image')));
    await tester.pump();
    await tester.tap(find.text('Next (1)'));
    await tester.pumpAndSettle();
    expect(sent, 0);
    expect(find.text('Could not prepare selected media. Try again.'),
        findsOneWidget);
    expect(find.text('Next (1)'), findsOneWidget);
  });
  testWidgets('closing during preparation never invokes selection callback',
      (tester) async {
    final source = Gallery()..pending = Completer<File?>();
    var sent = 0;
    await show(tester, source, selected: (_) async {
      sent++;
    });
    await tester.tap(find.byKey(const ValueKey('image')));
    await tester.pump();
    await tester.tap(find.text('Next (1)'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    source.pending!.complete(File('/image.jpg'));
    await tester.pump();
    expect(sent, 0);
    expect(tester.takeException(), isNull);
  });
}
