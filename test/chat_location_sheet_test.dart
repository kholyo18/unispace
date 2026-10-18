import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:UniSpace/features/shell/chat/chat_location_sheet.dart';

class FakeLocationProvider implements ChatLocationProvider {
  bool enabled = true;
  LocationPermission permission = LocationPermission.denied;
  LocationPermission requestedPermission = LocationPermission.whileInUse;
  int checks = 0,
      requests = 0,
      positions = 0,
      appSettings = 0,
      locationSettings = 0;
  Future<ChatLocationPoint> Function() read = () async =>
      const ChatLocationPoint(36.7525, 3.0420);
  @override
  Future<bool> servicesEnabled() async {
    checks++;
    return enabled;
  }

  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    return requestedPermission;
  }

  @override
  Future<ChatLocationPoint> currentPosition() {
    positions++;
    return read();
  }

  @override
  Future<bool> openAppSettings() async {
    appSettings++;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    locationSettings++;
    return true;
  }
}

Future<void> openSheet(
  WidgetTester tester,
  FakeLocationProvider provider, {
  void Function(String?)? result,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              final value = await showChatLocationSheet(
                context,
                provider: provider,
              );
              result?.call(value);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'no location access until user action; preview requires explicit confirmation',
    (tester) async {
      final provider = FakeLocationProvider();
      String? result;
      var completed = false;
      await openSheet(
        tester,
        provider,
        result: (value) {
          result = value;
          completed = true;
        },
      );
      expect(provider.checks, 0);
      expect(provider.requests, 0);
      expect(find.byKey(const ValueKey('confirmLocation')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('locate')));
      await tester.pumpAndSettle();
      expect(provider.requests, 1);
      expect(provider.positions, 1);
      expect(find.text('36.752500,3.042000'), findsOneWidget);
      expect(completed, false);
      await tester.tap(find.byKey(const ValueKey('confirmLocation')));
      await tester.pumpAndSettle();
      expect(
        result,
        'https://www.google.com/maps/search/?api=1&query=36.752500,3.042000',
      );
    },
  );

  testWidgets('denial does not read location or permit sending', (
    tester,
  ) async {
    final provider = FakeLocationProvider()
      ..requestedPermission = LocationPermission.denied;
    await openSheet(tester, provider);
    await tester.tap(find.byKey(const ValueKey('locate')));
    await tester.pumpAndSettle();
    expect(provider.positions, 0);
    expect(
      find.textContaining('Location permission was denied'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('confirmLocation')), findsNothing);
  });

  testWidgets('permanent denial uses app settings without requesting again', (
    tester,
  ) async {
    final provider = FakeLocationProvider()
      ..permission = LocationPermission.deniedForever;
    await openSheet(tester, provider);
    await tester.tap(find.byKey(const ValueKey('locate')));
    await tester.pumpAndSettle();
    expect(provider.requests, 0);
    expect(provider.positions, 0);
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(provider.appSettings, 1);
  });

  testWidgets(
    'disabled services use location settings before permission request',
    (tester) async {
      final provider = FakeLocationProvider()..enabled = false;
      await openSheet(tester, provider);
      await tester.tap(find.byKey(const ValueKey('locate')));
      await tester.pumpAndSettle();
      expect(provider.requests, 0);
      await tester.tap(find.text('Open settings'));
      await tester.pumpAndSettle();
      expect(provider.locationSettings, 1);
    },
  );

  testWidgets('timeout allows retry and never sends stale coordinates', (
    tester,
  ) async {
    final provider = FakeLocationProvider()
      ..read = () => Future.error(TimeoutException('test'));
    await openSheet(tester, provider);
    await tester.tap(find.byKey(const ValueKey('locate')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Finding your location timed out'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('confirmLocation')), findsNothing);
    provider.read = () async => const ChatLocationPoint(0, 0);
    await tester.tap(find.byKey(const ValueKey('locate')));
    await tester.pumpAndSettle();
    expect(find.text('0.000000,0.000000'), findsOneWidget);
    expect(find.byKey(const ValueKey('confirmLocation')), findsOneWidget);
  });

  testWidgets('closing during lookup discards completion without sending', (
    tester,
  ) async {
    final pending = Completer<ChatLocationPoint>();
    final provider = FakeLocationProvider()..read = () => pending.future;
    String? result;
    await openSheet(tester, provider, result: (value) => result = value);
    await tester.tap(find.byKey(const ValueKey('locate')));
    await tester.pump();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    pending.complete(const ChatLocationPoint(36, 3));
    await tester.pump();
    expect(result, isNull);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('confirmLocation')), findsNothing);
  });
}
