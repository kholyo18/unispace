import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/shell/chat/chat_rich_attachment_sheet.dart';

Future<void> open(WidgetTester tester, String kind,
    void Function(Map<String, dynamic>?) onResult) async {
  await tester.pumpWidget(MaterialApp(
      home: Builder(
          builder: (context) => Scaffold(
              body: TextButton(
                  onPressed: () async => onResult(
                      await showChatRichAttachmentSheet(context, kind: kind)),
                  child: const Text('Open'))))));
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(ValueKey(key)));
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

void main() {
  test('normalizes Arabic phone digits without hiding invalid characters', () {
    expect(normalizeChatContactPhone(' +٢١٣ (٧٩٨) ٣٧٦-٥٩٥ '), '+213798376595');
    expect(normalizeChatContactPhone('abc123'), 'abc123');
  });
  testWidgets('cancel returns no attachment', (tester) async {
    var completed = false;
    Map<String, dynamic>? result;
    await open(tester, 'contact', (v) {
      completed = true;
      result = v;
    });
    await tap(tester, 'attachment-cancel');
    expect(completed, isTrue);
    expect(result, isNull);
  });
  testWidgets(
      'invalid contact blocks preview and valid contact requires explicit send',
      (tester) async {
    Map<String, dynamic>? result;
    await open(tester, 'contact', (v) => result = v);
    await tester.enterText(
        find.byKey(const ValueKey('attachment-title')), 'Alice');
    await tester.enterText(find.byKey(const ValueKey('contact-phone')), 'abc');
    await tap(tester, 'attachment-review');
    expect(find.text('Enter a number with 6 to 15 digits'), findsOneWidget);
    expect(find.byKey(const ValueKey('attachment-send')), findsNothing);
    await tester.enterText(
        find.byKey(const ValueKey('contact-phone')), '+٢١٣ ٧٩٨ ٣٧٦ ٥٩٥');
    await tap(tester, 'attachment-review');
    expect(result, isNull);
    await tap(tester, 'attachment-send');
    expect(result, {
      'type': 'contact',
      'contactName': 'Alice',
      'contactPhone': '+213798376595'
    });
  });
  testWidgets('poll rejects duplicate options and preserves all choices',
      (tester) async {
    Map<String, dynamic>? result;
    await open(tester, 'poll', (v) => result = v);
    await tester.enterText(
        find.byKey(const ValueKey('attachment-title')), 'Lunch?');
    await tester.enterText(
        find.byKey(const ValueKey('poll-option-0')), 'Pizza');
    await tester.enterText(
        find.byKey(const ValueKey('poll-option-1')), ' pizza ');
    await tap(tester, 'attachment-review');
    expect(find.text('Options must be different'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('poll-option-1')), 'Rice');
    await tap(tester, 'attachment-review');
    expect(result, isNull);
    await tap(tester, 'attachment-send');
    expect(result!['question'], 'Lunch?');
    expect(jsonDecode(result!['optionsJson'] as String), ['Pizza', 'Rice']);
  });
  testWidgets('event requires future date and uses local date and time picker',
      (tester) async {
    Map<String, dynamic>? result;
    await open(tester, 'event', (v) => result = v);
    await tester.enterText(
        find.byKey(const ValueKey('attachment-title')), 'Study');
    await tap(tester, 'attachment-review');
    expect(find.text('Choose a future time within one year'), findsOneWidget);
    await tap(tester, 'event-date');
    final picker =
        tester.widget<CalendarDatePicker>(find.byType(CalendarDatePicker));
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    picker.onDateChanged(tomorrow);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tap(tester, 'attachment-review');
    expect(result, isNull);
    await tap(tester, 'attachment-send');
    expect(result!['type'], 'event');
    expect(
        DateTime.fromMillisecondsSinceEpoch(result!['startsAtMs'] as int)
            .isAfter(DateTime.now()),
        isTrue);
    expect(result!.containsKey('place'), isFalse);
  });
  testWidgets('missing native picker keeps manual form available',
      (tester) async {
    const channel = MethodChannel('unispace/attachments');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            channel, (_) async => throw PlatformException(code: 'unavailable'));
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    await open(tester, 'contact', (_) {});
    await tap(tester, 'contact-pick');
    expect(
        find.text('Contacts unavailable. Enter the name and number manually.'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('contact-phone')), findsOneWidget);
  });
  testWidgets('double confirmation returns only one result', (tester) async {
    var count = 0;
    await open(tester, 'contact', (_) => count++);
    await tester.enterText(
        find.byKey(const ValueKey('attachment-title')), 'Alice');
    await tester.enterText(
        find.byKey(const ValueKey('contact-phone')), '+213798376595');
    await tap(tester, 'attachment-review');
    final send = tester
        .widget<FilledButton>(find.byKey(const ValueKey('attachment-send')))
        .onPressed!;
    send();
    send();
    await tester.pumpAndSettle();
    expect(count, 1);
    expect(find.text('Open'), findsOneWidget);
  });
  testWidgets(
      'late contact picker result after cancellation does not touch disposed fields',
      (tester) async {
    const channel = MethodChannel('unispace/attachments');
    final pending = Completer<Map<String, dynamic>?>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) => pending.future);
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    Map<String, dynamic>? result;
    var completed = false;
    await open(tester, 'contact', (v) {
      result = v;
      completed = true;
    });
    await tap(tester, 'contact-pick');
    await tap(tester, 'attachment-cancel');
    pending.complete({'name': 'Alice', 'phone': '+213798376595'});
    await tester.pumpAndSettle();
    expect(completed, isTrue);
    expect(result, isNull);
    expect(tester.takeException(), isNull);
  });
}
