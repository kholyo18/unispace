import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/shell/chat/chat_nickname_sheet.dart';
import 'package:UniSpace/features/shell/chat/chat_profile_avatar.dart';

void main() {
  testWidgets(
      'nickname submission survives route closing animation and preserves parent',
      (tester) async {
    String? result;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                    body: TextButton(
                  child: const Text('open'),
                  onPressed: () async {
                    result = await showModalBottomSheet<String>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const ChatNicknameSheet(
                            initialName: 'Old', peerName: 'Peer'));
                  },
                )))));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  New name  ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(result, 'New name');
    expect(find.text('open'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('nickname sheet fits a small screen with keyboard and large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(
                size: Size(320, 500),
                viewInsets: EdgeInsets.only(bottom: 260),
                textScaler: TextScaler.linear(1.6)),
            child: const Scaffold(
                body: ChatNicknameSheet(initialName: '', peerName: 'Peer')))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('avatar uses supplied photo and falls back when loading fails',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: ChatProfileAvatar(
                name: 'Sara',
                photoUrl: 'https://example.invalid/avatar.jpg'))));
    expect(find.byType(Image), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('S'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
