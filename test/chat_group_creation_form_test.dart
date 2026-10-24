import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/shell/chat/chat_group_creation_form.dart';
import 'package:UniSpace/features/shell/chat/new_conversation_page.dart';

void main() {
  const alice = ChatContact(id: 'a', name: 'Alice', username: 'alice');
  const bob = ChatContact(id: 'b', name: 'Bob', username: 'bob');
  Future<void> mount(WidgetTester tester,
      {String locale = 'en',
      Brightness brightness = Brightness.light,
      double scale = 1,
      bool locked = false,
      bool busy = false,
      VoidCallback? create,
      Map<String, ChatContact>? selection,
      TextEditingController? name}) async {
    final search = ChatContactSearchController(
        currentUserId: () => 'me',
        debounce: Duration.zero,
        search: (query) async =>
            ChatContactSearchResult(query == 'bob' ? [bob] : [alice, bob]));
    final controller = name ?? TextEditingController();
    final selected = selection ?? <String, ChatContact>{};
    addTearDown(search.dispose);
    if (name == null) addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
        locale: Locale(locale),
        supportedLocales: const [Locale('en'), Locale('ar'), Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ThemeData(brightness: brightness),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!),
        home: StatefulBuilder(
            builder: (context, setState) => ChatGroupCreationForm(
                search: search,
                nameController: controller,
                selected: selected,
                onToggle: (person) => setState(() {
                      if (selected.containsKey(person.id)) {
                        selected.remove(person.id);
                      } else {
                        selected[person.id] = person;
                      }
                    }),
                suggestions: const Center(child: Text('Recent contacts')),
                onCreate: create ?? () {},
                locked: locked,
                busy: busy,
                retry: locked,
                status: const Text('Pending invitations')))));
  }

  testWidgets(
      'multi-select persists across searches, removal and clear stay on screen',
      (tester) async {
    final selected = <String, ChatContact>{};
    await mount(tester, selection: selected);
    await tester.enterText(find.byType(TextField), 'ali');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('group-person-a')));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'bob');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('group-person-b')));
    await tester.pump();
    expect(selected.keys, containsAll(['a', 'b']));
    expect(find.byType(InputChip), findsNWidgets(2));
    await tester.tap(find.byTooltip('Remove selection: Alice'));
    await tester.pump();
    expect(selected.keys, ['b']);
    expect(find.byType(ChatGroupCreationForm), findsOneWidget);
    await tester.tap(find.widgetWithIcon(IconButton, Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Recent contacts'), findsOneWidget);
    expect(selected.keys, ['b']);
  });
  testWidgets('optional name dialog saves, clears and disposes after animation',
      (tester) async {
    final name = TextEditingController();
    addTearDown(name.dispose);
    await mount(tester, name: name);
    await tester.tap(find.byTooltip('Group details'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.descendant(
            of: find.byType(AlertDialog), matching: find.byType(TextField)),
        ' Study friends ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(name.text, 'Study friends');
    expect(find.text('Study friends'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Group details'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.descendant(
            of: find.byType(AlertDialog), matching: find.byType(TextField)),
        '');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(name.text, isEmpty);
  });
  testWidgets('busy submission cannot be duplicated or selection edited',
      (tester) async {
    var count = 0;
    await mount(tester,
        locked: true,
        busy: true,
        selection: {'a': alice},
        create: () => count++);
    expect(find.byType(TextField), findsNothing);
    expect(tester.widget<InputChip>(find.byType(InputChip)).onDeleted, isNull);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    expect(count, 0);
  });
  for (final lang in ['ar', 'en', 'fr']) {
    for (final brightness in Brightness.values) {
      testWidgets(
          '$lang $brightness keyboard and large text keep create reachable',
          (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        await mount(tester,
            locale: lang,
            brightness: brightness,
            scale: 1.6,
            selection: {'a': alice});
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(tester.getBottomRight(find.byType(FilledButton)).dy,
            lessThanOrEqualTo(360));
      });
    }
  }
}
