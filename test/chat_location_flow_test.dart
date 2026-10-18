import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:UniSpace/features/shell/chat/chat_location_sheet.dart';
import 'package:UniSpace/features/shell/chat/chat_text_content.dart';
import 'chat_location_sheet_test.dart' show FakeLocationProvider, openSheet;

void main() {
  test('coordinate links reject unsafe, ambiguous and invalid destinations',
      () {
    for (final text in [
      'https://www.google.com/maps/search/?api=1&query=%FF',
      'https://www.google.com/maps/search/?api=1&query=%E0%A4%A',
      'https://www.google.com.evil.test/maps/search/?api=1&query=36,3',
      'https://user@www.google.com/maps/search/?api=1&query=36,3',
      'https://www.google.com:444/maps/search/?api=1&query=36,3',
      'https://www.google.com/maps/search/?api=1&query=NaN,3',
      'https://www.google.com/maps/search/?api=1&query=91,3',
      'https://www.google.com/maps/search/?api=1&query=36,181',
      'https://www.google.com/maps/search/?api=1&query=36,3&query=1,2',
      'https://www.google.com/maps/search/?api=1&query=36,3&other=1',
      'https://www.google.com/maps/search/?api=1&query=Algiers',
      'https://www.google.com/maps/search/?api=1&query=36,3#fragment',
      'See https://www.google.com/maps/search/?api=1&query=36,3',
    ]) {
      expect(ChatLocationPoint.fromMapsLink(text), isNull, reason: text);
    }
    final point = ChatLocationPoint.fromMapsLink(
        'https://www.google.com/maps/search/?api=1&query=-90%2C180');
    expect(point!.latitude, -90);
    expect(point.longitude, 180);
    expect(
        ChatLocationPoint.fromMapsLink(const ChatLocationPoint(0, 0).mapsLink)!
            .isValid,
        true);
  });

  testWidgets('a hung provider times out; late result cannot replace a retry',
      (tester) async {
    final pending = Completer<ChatLocationPoint>();
    final provider = FakeLocationProvider()..read = () => pending.future;
    await openSheet(tester, provider);
    await tester.tap(find.byKey(const ValueKey('locate')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 23));
    expect(
        find.textContaining('Finding your location timed out'), findsOneWidget);
    provider.read = () async => const ChatLocationPoint(1, 2);
    await tester.tap(find.byKey(const ValueKey('locate')));
    await tester.pumpAndSettle();
    pending.complete(const ChatLocationPoint(50, 50));
    await tester.pump();
    expect(find.text('1.000000,2.000000'), findsOneWidget);
    expect(find.text('50.000000,50.000000'), findsNothing);
  });

  testWidgets(
      'return from location settings rechecks service and permission once',
      (tester) async {
    final provider = FakeLocationProvider()..enabled = false;
    await openSheet(tester, provider);
    await tester.tap(find.byKey(const ValueKey('locate')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    provider.enabled = true;
    provider.permission = LocationPermission.whileInUse;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(provider.positions, 1);
    expect(find.byKey(const ValueKey('confirmLocation')), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(provider.positions, 1);
  });

  testWidgets(
      'accuracy is visible and failed map preview does not send or lose selection',
      (tester) async {
    final provider = FakeLocationProvider()
      ..read = () async => const ChatLocationPoint(36, 3, accuracy: 85.2);
    Uri? opened;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ChatLocationSheet(
      provider: provider,
      openMap: (uri) async {
        opened = uri;
        return false;
      },
    ))));
    await tester.tap(find.byKey(const ValueKey('locate')));
    await tester.pumpAndSettle();
    expect(find.text('Estimated accuracy: within 86 m'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('previewLocation')));
    await tester.pumpAndSettle();
    expect(opened.toString(), const ChatLocationPoint(36, 3).mapsLink);
    expect(find.text('Could not open the map. Try again.'), findsOneWidget);
    expect(find.byKey(const ValueKey('confirmLocation')), findsOneWidget);
  });

  testWidgets(
      'shared location launch failure is reported and ordinary messages remain text',
      (tester) async {
    var failed = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ChatTextContent(
      text: const ChatLocationPoint(0, 0).mapsLink,
      style: const TextStyle(),
      onLaunchLink: (_) async => false,
      onLinkFailure: () => failed++,
    ))));
    await tester.tap(find.byKey(const ValueKey('openSharedLocation')));
    await tester.pump();
    expect(failed, 1);
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: ChatTextContent(
      text: 'https://www.google.com/maps/search/?api=1&query=Algiers',
      style: TextStyle(),
    ))));
    expect(find.byKey(const ValueKey('openSharedLocation')), findsNothing);
  });
}
