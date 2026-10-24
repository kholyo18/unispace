import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:UniSpace/features/shell/chat/chat_photo_tools.dart';
import 'package:UniSpace/features/shell/chat/photo_edit_model.dart';

Future<void> openEditor(
  WidgetTester tester, {
  PhotoText? initial,
  required ValueChanged<PhotoText?> result,
  String language = 'en',
  double textScale = 1,
}) async {
  await tester.pumpWidget(MaterialApp(
    locale: Locale(language),
    supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
        body: Builder(
            builder: (context) => TextButton(
                  onPressed: () async => result(await showPhotoTextEditor(
                      context,
                      initial: initial,
                      color: Colors.orangeAccent)),
                  child: const Text('Open'),
                ))),
  ));
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('save edits content and style without moving or resizing layer',
      (tester) async {
    PhotoText? result;
    const initial = PhotoText('Before', Offset(.2, .3), Colors.white, .12,
        angle: .7, background: Colors.black);
    await openEditor(tester,
        initial: initial, result: (value) => result = value);
    await tester.enterText(
        find.byKey(const ValueKey('photo-text-input')), 'After\nSecond line');
    await tapVisible(tester, find.byKey(const ValueKey('photo-font-2')));
    await tapVisible(tester, find.byKey(const ValueKey('photo-align-right')));
    await tapVisible(
        tester, find.byKey(ValueKey('photo-color-${Colors.black.toARGB32()}')));
    await tapVisible(
        tester, find.byKey(const ValueKey('photo-text-background')));
    await tapVisible(tester, find.byKey(const ValueKey('photo-text-save')));
    expect(result!.text, 'After\nSecond line');
    expect(result!.position, initial.position);
    expect(result!.size, initial.size);
    expect(result!.angle, initial.angle);
    expect(result!.fontStyle, 2);
    expect(result!.align, TextAlign.right);
    expect(result!.color, Colors.black);
    expect(result!.background, isNull);
    expect(initial.text, 'Before');
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancel leaves original unchanged and disposes controller safely',
      (tester) async {
    PhotoText? result;
    var returned = false;
    const initial = PhotoText('Keep me', Offset(.2, .3), Colors.white, .12);
    await openEditor(tester, initial: initial, result: (value) {
      returned = true;
      result = value;
    });
    await tester.enterText(
        find.byKey(const ValueKey('photo-text-input')), 'discard');
    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();
    expect(returned, isTrue);
    expect(result, isNull);
    expect(initial.text, 'Keep me');
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'blank text cannot be committed; new text creates contrasting background',
      (tester) async {
    PhotoText? result;
    await openEditor(tester, result: (value) => result = value);
    final save = find.byKey(const ValueKey('photo-text-save'));
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    await tester.enterText(
        find.byKey(const ValueKey('photo-text-input')), '   ');
    await tester.pump();
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    await tester.enterText(
        find.byKey(const ValueKey('photo-text-input')), '  Hello  ');
    await tapVisible(
        tester, find.byKey(const ValueKey('photo-text-background')));
    await tapVisible(tester, save);
    expect(result!.text, 'Hello');
    expect(result!.position, const Offset(.5, .5));
    expect(result!.background, Colors.black);
  });

  for (final language in ['ar', 'fr']) {
    testWidgets('$language large text and keyboard fit a narrow screen',
        (tester) async {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      PhotoText? result;
      await openEditor(tester,
          language: language,
          textScale: 1.8,
          result: (value) => result = value);
      expect(find.text(language == 'ar' ? 'تعديل النص' : 'Modifier le texte'),
          findsOneWidget);
      await tester.enterText(
          find.byKey(const ValueKey('photo-text-input')), 'Hello');
      await tapVisible(tester, find.byKey(const ValueKey('photo-font-1')));
      await tapVisible(tester, find.byKey(const ValueKey('photo-text-save')));
      expect(result!.fontStyle, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('sticker picker exposes full library and returns selected emoji',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    String? result;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
      builder: (context) => TextButton(
        onPressed: () async => result = await showPhotoStickerPicker(context),
        child: const Text('Open'),
      ),
    ))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final picker = tester.widget<EmojiPicker>(find.byType(EmojiPicker));
    expect(picker.config.checkPlatformCompatibility, isFalse);
    expect(picker.config.emojiTextStyle!.fontFamily, 'NotoColorEmoji');
    expect(picker.config.bottomActionBarConfig.showSearchViewButton, isTrue);
    await tester.tap(find.text('😀').first);
    await tester.pumpAndSettle();
    expect(result, '😀');
    expect(tester.takeException(), isNull);
  });
}
