import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/shell/chat/chat_rich_message_card.dart';

void main() {
  Future<void> mount(WidgetTester tester, Map<String, dynamic> data,
          {Future<void> Function(int)? vote,
          Future<void> Function(bool)? respond}) =>
      tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: ChatRichMessageCard(
                  data: data,
                  currentUid: 'me',
                  style: const TextStyle(),
                  onVote: vote,
                  onRespondEvent: respond))));
  final poll = <String, dynamic>{
    'type': 'poll',
    'question': 'Choose',
    'optionsJson': '["One","Two"]',
    'votes': {'me': 0, 'other': 1, 'bad': 99}
  };
  final event = <String, dynamic>{
    'type': 'event',
    'title': 'Meet',
    'startsAtMs': 1800000000000,
    'attendees': {'me': true}
  };
  testWidgets('poll counts only valid votes and sends one request at a time',
      (tester) async {
    final pending = Completer<void>();
    final votes = <int>[];
    await mount(tester, poll, vote: (index) {
      votes.add(index);
      return pending.future;
    });
    expect(find.text('2 vote(s)'), findsOneWidget);
    expect(
        tester.getSize(find.byType(ChatRichMessageCard)).height, lessThan(280));
    expect(tester.getSize(find.byKey(const ValueKey('poll-choice-0'))).height,
        greaterThanOrEqualTo(48));
    final selection = tester.widgetList<Semantics>(find.ancestor(
        of: find.byKey(const ValueKey('poll-choice-0')),
        matching: find.byType(Semantics)));
    expect(selection.any((node) => node.properties.selected == true), isTrue);
    expect(find.text('50%'), findsNWidgets(2));
    await tester.tap(find.text('Two'));
    await tester.pump();
    await tester.tap(find.text('One'));
    expect(votes, [1]);
    pending.complete();
    await tester.pumpAndSettle();
  });
  testWidgets('failed poll can be retried without changing the selection',
      (tester) async {
    int calls = 0;
    await mount(tester, poll, vote: (_) async {
      calls++;
      throw StateError('offline');
    });
    await tester.tap(find.text('Two'));
    await tester.pumpAndSettle();
    expect(find.text('Action failed. Please retry.'), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    await tester.tap(find.text('Two'));
    await tester.pumpAndSettle();
    expect(calls, 2);
  });
  testWidgets('event toggles existing attendance and reports failure',
      (tester) async {
    final responses = <bool>[];
    await mount(tester, event, respond: (going) async {
      responses.add(going);
      throw StateError('offline');
    });
    await tester.tap(find.text('Cancel attendance'));
    await tester.pumpAndSettle();
    expect(responses, [false]);
    expect(find.text('Action failed. Please retry.'), findsOneWidget);
    expect(find.text('Cancel attendance'), findsOneWidget);
  });
  testWidgets('malformed attachment is noninteractive', (tester) async {
    await mount(
        tester, {'type': 'poll', 'question': 'bad', 'optionsJson': '[1,2]'});
    expect(find.text('Invalid attachment'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);
    await mount(tester,
        {'type': 'contact', 'contactName': 'Bad', 'contactPhone': '*21*123#'});
    expect(find.text('Invalid attachment'), findsOneWidget);
  });
  testWidgets('calendar opens only after tap and missing app is visible',
      (tester) async {
    const channel = MethodChannel('unispace/attachments');
    int calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls++;
      expect(call.method, 'addEvent');
      throw PlatformException(code: 'unavailable');
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    await mount(tester, event);
    expect(calls, 0);
    await tester.tap(find.text('Add to calendar'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('Action failed. Please retry.'), findsOneWidget);
  });
  testWidgets('sent poll uses white controls and readable error feedback',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ColoredBox(
      color: Colors.teal,
      child: ChatRichMessageCard(
          data: poll,
          currentUid: 'me',
          style: const TextStyle(color: Colors.white),
          onVote: (_) async => throw StateError('offline')),
    ))));
    expect(DefaultTextStyle.of(tester.element(find.text('One'))).style.color,
        Colors.white);
    expect(
        DefaultTextStyle.of(tester.element(find.text('2 vote(s)'))).style.color,
        Colors.white);
    final optionContext = tester.element(find.byType(OutlinedButton).first);
    final buttonStyle = OutlinedButtonTheme.of(optionContext).style!;
    expect(buttonStyle.foregroundColor!.resolve({}), Colors.white);
    expect(buttonStyle.foregroundColor!.resolve({WidgetState.disabled}),
        Colors.white);
    expect(buttonStyle.side!.resolve({})!.color, Colors.white);
    final iconContext = tester.element(find.byIcon(Icons.radio_button_checked));
    expect(IconTheme.of(iconContext).color, Colors.white);
    final progressContext =
        tester.element(find.byType(LinearProgressIndicator).first);
    expect(ProgressIndicatorTheme.of(progressContext).color, Colors.white);
    await tester.tap(find.text('Two'));
    await tester.pumpAndSettle();
    final error =
        tester.widget<Text>(find.text('Action failed. Please retry.'));
    final scheme =
        Theme.of(tester.element(find.text('Action failed. Please retry.')))
            .colorScheme;
    expect(error.style!.color, scheme.onErrorContainer);
    final containers = tester.widgetList<Container>(find.ancestor(
        of: find.text('Action failed. Please retry.'),
        matching: find.byType(Container)));
    expect(
        containers.any((container) =>
            container.decoration is BoxDecoration &&
            (container.decoration as BoxDecoration).color ==
                scheme.errorContainer),
        isTrue);
  });

  testWidgets('sent event actions and details inherit white foreground',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ColoredBox(
      color: Colors.teal,
      child: ChatRichMessageCard(
          data: {...event, 'place': 'Library', 'description': 'Study'},
          currentUid: 'me',
          style: const TextStyle(color: Colors.white)),
    ))));
    for (final label in [
      'Library',
      'Study',
      '1 attending',
      'Add to calendar',
      'Cancel attendance'
    ]) {
      expect(DefaultTextStyle.of(tester.element(find.text(label))).style.color,
          Colors.white);
    }
    final buttonContext = tester.element(find.byType(TextButton).first);
    expect(TextButtonTheme.of(buttonContext).style!.iconColor!.resolve({}),
        Colors.white);
  });
  testWidgets('missing calendar gives actionable message and retains RSVP',
      (tester) async {
    const channel = MethodChannel('unispace/attachments');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'no-calendar-app');
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final responses = <bool>[];
    await mount(tester, event, respond: (value) async {
      responses.add(value);
    });
    await tester.tap(find.text('Add to calendar'));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'No compatible calendar app is installed. You can still follow this event in chat.'),
        findsOneWidget);
    expect(find.text('Action failed. Please retry.'), findsNothing);
    expect(find.text('Cancel attendance'), findsOneWidget);
    await tester.tap(find.text('Cancel attendance'));
    await tester.pumpAndSettle();
    expect(responses, [false]);
  });

  for (final locale in ['ar', 'fr', 'en']) {
    for (final brightness in Brightness.values) {
      testWidgets('rich cards fit narrow $locale $brightness layout',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(MaterialApp(
          locale: Locale(locale),
          supportedLocales: const [Locale('ar'), Locale('fr'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: ThemeData(brightness: brightness),
          home: Scaffold(
              body: SingleChildScrollView(
                  child: Column(children: [
            const ChatRichMessageCard(
              data: {
                'type': 'contact',
                'contactName':
                    'A long contact name that wraps over several lines',
                'contactPhone': '+213 555 123 456',
              },
              currentUid: 'me',
              style: TextStyle(),
            ),
            ChatRichMessageCard(
              data: {
                ...poll,
                'optionsJson':
                    '["A longer choice that wraps naturally onto several lines","Two"]'
              },
              currentUid: 'me',
              style: const TextStyle(),
              onVote: (_) async {},
            ),
          ]))),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('+213 555 123 456'), findsOneWidget);
        expect(find.text('50%'), findsNWidgets(2));
        expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      });
    }
  }

  testWidgets('contact save preserves name and phone after card redesign',
      (tester) async {
    const channel = MethodChannel('unispace/attachments');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    await mount(tester, {
      'type': 'contact',
      'contactName': 'Contact Name',
      'contactPhone': '+213 555 123 456'
    });
    expect(calls, isEmpty);
    await tester.tap(find.text('Save contact'));
    await tester.pumpAndSettle();
    expect(calls.single.method, 'saveContact');
    expect(calls.single.arguments,
        {'name': 'Contact Name', 'phone': '+213 555 123 456'});
    expect(find.text('Call'), findsOneWidget);
  });
}
