import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/shell/chat/chat_group_pages.dart';

void main() {
  for (final row in [
    ('en', 'Rename group', 'Save'),
    ('ar', 'تغيير اسم المجموعة', 'حفظ'),
    ('fr', 'Renommer le groupe', 'Enregistrer')
  ]) {
    testWidgets(
        'group rename dialog supports ${row.$1} and disposes after closing',
        (tester) async {
      String? result;
      await tester.pumpWidget(MaterialApp(
          locale: Locale(row.$1),
          supportedLocales: const [Locale('en'), Locale('ar'), Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Builder(
              builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () async {
                        result = await showDialog<String>(
                            context: context,
                            builder: (_) =>
                                const ChatGroupNameDialog(name: 'Original'));
                      },
                      child: const Text('open'))))));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text(row.$2), findsOneWidget);
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull);
      await tester.enterText(find.byType(TextField), ' New name ');
      await tester.pump();
      await tester.tap(find.text(row.$3));
      await tester.pumpAndSettle();
      expect(result, 'New name');
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('creation form scrolls with keyboard on a small viewport',
      (tester) async {
    tester.view.physicalSize = const Size(360, 600);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    var submitted = false;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            appBar: AppBar(title: const Text('New group')),
            body: ChatGroupFormLayout(children: [
              const Padding(
                  padding: EdgeInsets.all(16),
                  child: TextField(
                      maxLength: 80,
                      decoration: InputDecoration(labelText: 'Group name'))),
              const Text('Joining gives access to existing group messages.'),
              const SizedBox(
                  height: 48, child: Chip(label: Text('Selected contact'))),
              const SizedBox(
                  height: 320, child: Center(child: Text('Contacts'))),
              FilledButton(
                  onPressed: () => submitted = true,
                  child: const Text('Create group')),
            ]))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Create group'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Create group'));
    await tester.pump();
    expect(submitted, isTrue);
    expect(tester.takeException(), isNull);
  });
}
