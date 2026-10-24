import 'package:UniSpace/services/protected_network_image.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/ui/settings/public_profile_service.dart';

void main() {
  Widget photo(Stream<Map<String, dynamic>> stream, {String userId = 'target'}) =>
      MaterialApp(home: Scaffold(body: PublicProfilePhoto(
        userId: userId, size: 72, radius: 36, iconSize: 32,
        fallbackUrl: 'https://example.test/stored-private-photo.jpg',
        profileStream: stream,
      )));

  testWidgets('pending and denied profiles never render stored fallback URLs', (tester) async {
    final profiles = StreamController<Map<String, dynamic>>();
    addTearDown(profiles.close);
    await tester.pumpWidget(photo(profiles.stream));
    expect(find.byType(Image), findsNothing);
    profiles.addError(StateError('Profile access denied'));
    await tester.pump();
    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('authorized photo disappears when access is subsequently denied', (tester) async {
    final profiles = StreamController<Map<String, dynamic>>();
    addTearDown(profiles.close);
    await tester.pumpWidget(photo(profiles.stream));
    profiles.add({'profileImageUrl': 'https://example.test/authorized-photo.jpg'});
    await tester.pump();
    final rendered = tester.widget<Image>(find.byType(Image));
    expect((rendered.image as ProtectedNetworkImage).url, 'https://example.test/authorized-photo.jpg');
    profiles.addError(StateError('Profile access revoked'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('changing target does not show the prior authorized photo', (tester) async {
    final first = StreamController<Map<String, dynamic>>();
    final second = StreamController<Map<String, dynamic>>();
    addTearDown(first.close);
    addTearDown(second.close);
    await tester.pumpWidget(photo(first.stream));
    first.add({'profileImageUrl': 'https://example.test/authorized-photo.jpg'});
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    await tester.pumpWidget(photo(second.stream, userId: 'other'));
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('same target refresh keeps mounted image until a new result or denial', (tester) async {
    final first = StreamController<Map<String, dynamic>>();
    final refresh = StreamController<Map<String, dynamic>>();
    addTearDown(first.close);
    addTearDown(refresh.close);
    await tester.pumpWidget(photo(first.stream));
    first.add({'profileImageUrl': 'https://example.test/authorized-photo.jpg'});
    await tester.pump();
    final initial = tester.widget<Image>(find.byType(Image)).image;
    await tester.pumpWidget(photo(refresh.stream));
    expect(tester.widget<Image>(find.byType(Image)).image, same(initial));
    refresh.add({'profileImageUrl': 'https://example.test/authorized-photo.jpg'});
    await tester.pump();
    expect(tester.widget<Image>(find.byType(Image)).image, same(initial));
    refresh.addError(StateError('denied'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('missing authorized photo never uses stored fallback', (tester) async {
    await tester.pumpWidget(photo(Stream.value({'displayName': 'Visible identity'})));
    await tester.pump();
    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.person), findsOneWidget);
  });
}
