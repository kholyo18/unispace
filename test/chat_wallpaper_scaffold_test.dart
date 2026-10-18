import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/shell/chat/chat_wallpaper_scaffold.dart';

void main() {
  testWidgets('one wallpaper paints behind app bar without covering message content', (tester) async {
    tester.view.physicalSize = const Size(320,640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(home: RepaintBoundary(key: key,
      child: ChatWallpaperScaffold(decoration: const BoxDecoration(color: Color(0xFFFF0000)),
        appBar: AppBar(backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent, elevation: 0),
        body: const Align(alignment: Alignment.topCenter, child: Text('First message'))))));
    await tester.pumpAndSettle();
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await tester.runAsync(() => boundary.toImage());
    final bytes = await tester.runAsync(() => image!.toByteData(format: ui.ImageByteFormat.rawRgba));
    expect(bytes!.getUint8((2*320+2)*4),255);
    expect(bytes.getUint8((2*320+2)*4+1),0);
    expect(bytes.getUint8((100*320+2)*4),255);
    expect(bytes.getUint8((100*320+2)*4+1),0);
    expect(tester.getTopLeft(find.text('First message')).dy, greaterThanOrEqualTo(kToolbarHeight));
    image!.dispose();
  });
}
