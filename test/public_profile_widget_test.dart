import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/ui/settings/public_profile_service.dart';

void main() {
  testWidgets(
      'profile photo renders without reading a private Firebase document',
      (tester) async {
    // No Firebase app is initialized; attempting a user-document subscription would fail.
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: PublicProfilePhoto(
                userId: 'target', size: 72, radius: 36, iconSize: 32))));
    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
