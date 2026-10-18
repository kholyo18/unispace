import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/shell/chat/chat_message_info_sheet.dart';

void main() {
  types.TextMessage message(
          {types.Status? status, Map<String, dynamic>? metadata}) =>
      types.TextMessage(
          id: 'm',
          author: const types.User(id: 'sender'),
          text: 'Private message content',
          createdAt: DateTime(2026, 10, 10, 9, 15).millisecondsSinceEpoch,
          status: status,
          metadata: metadata);
  Widget app(types.Message message,
          {bool mine = true,
          String language = 'en',
          Brightness brightness = Brightness.light,
          double scale = 1}) =>
      MaterialApp(
        locale: Locale(language),
        supportedLocales: const [Locale('ar'), Locale('fr'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ThemeData(brightness: brightness),
        home: Scaffold(
            body: MediaQuery(
                data: MediaQueryData(
                    textScaler: TextScaler.linear(scale),
                    size: const Size(320, 480)),
                child: ChatMessageInfoSheet(
                    message: message,
                    senderName: 'Sender Name',
                    isMine: mine))),
      );

  testWidgets(
      'own delivery status respects failed and pending metadata before receipts',
      (tester) async {
    await tester.pumpWidget(app(message(
        status: types.Status.seen,
        metadata: {'failed': true, 'pending': true})));
    expect(find.text('Failed to send'), findsOneWidget);
    expect(find.text('Read'), findsNothing);
    await tester.pumpWidget(
        app(message(status: types.Status.seen, metadata: {'pending': true})));
    expect(find.text('Sending'), findsOneWidget);
    expect(find.text('Read'), findsNothing);
    for (final entry in {
      types.Status.sent: 'Sent',
      types.Status.delivered: 'Delivered',
      types.Status.seen: 'Read',
    }.entries) {
      await tester.pumpWidget(app(message(status: entry.key)));
      expect(find.text(entry.value), findsOneWidget);
    }
    await tester.pumpWidget(app(message()));
    expect(find.text('Unavailable'), findsOneWidget);
  });

  testWidgets(
      'incoming messages do not show own delivery claims or content previews',
      (tester) async {
    await tester.pumpWidget(app(
        message(status: types.Status.seen, metadata: {'viewOnce': true}),
        mine: false));
    expect(find.text('Message status'), findsNothing);
    expect(find.text('Read'), findsNothing);
    expect(find.text('Private message content'), findsNothing);
    expect(find.text('Sender Name'), findsOneWidget);
  });

  for (final language in ['ar', 'fr', 'en']) {
    for (final brightness in Brightness.values) {
      testWidgets(
          'localized sheet scrolls at large font: $language $brightness',
          (tester) async {
        tester.view.physicalSize = const Size(320, 480);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final file = types.FileMessage(
            id: 'file',
            author: const types.User(id: 'sender'),
            name: 'Secret name.pdf',
            size: 1536,
            uri: 'https://example.invalid/file',
            createdAt: DateTime(2026, 10, 10, 9, 15).millisecondsSinceEpoch,
            status: types.Status.delivered,
            metadata: const {'edited': true});
        await tester.pumpWidget(
            app(file, language: language, brightness: brightness, scale: 2));
        expect(
            find.text(language == 'ar'
                ? 'معلومات الرسالة'
                : language == 'fr'
                    ? 'Infos du message'
                    : 'Message info'),
            findsOneWidget);
        final sizeLabel = language == 'ar'
            ? 'حجم الملف'
            : language == 'fr'
                ? 'Taille du fichier'
                : 'File size';
        await tester.ensureVisible(find.text(sizeLabel));
        await tester.pumpAndSettle();
        expect(find.text(sizeLabel), findsOneWidget);
        expect(find.text('Secret name.pdf'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
