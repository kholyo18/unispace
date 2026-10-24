import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/widgets/protected_avatar_image.dart';
void main() {
  testWidgets('avatar retains provider on rebuild, revalidates, and replaces identity on URL change', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    Widget page(String url) => MaterialApp(home: Scaffold(body: ProtectedAvatarImage(
      url: url, size: 48, placeholder: const Icon(Icons.person))));
    await tester.pumpWidget(page('https://example.invalid/first.png'));
    final first = tester.widget<Image>(find.byType(Image)).image;
    final firstKey = tester.widget<Image>(find.byType(Image)).key;
    await tester.pumpWidget(page('https://example.invalid/first.png'));
    expect(identical(tester.widget<Image>(find.byType(Image)).image, first), isTrue);
    await tester.pump(const Duration(seconds: 31));
    expect(identical(tester.widget<Image>(find.byType(Image)).image, first), isFalse);
    await tester.pumpWidget(page('https://example.invalid/second.png'));
    expect(tester.widget<Image>(find.byType(Image)).key, isNot(firstKey));
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('profile-authorized images do not run a duplicate refresh loop', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProtectedAvatarImage(
      url: 'https://example.invalid/profile.jpg', size: 48, revalidate: false,
      placeholder: Icon(Icons.person))));
    final provider = tester.widget<Image>(find.byType(Image)).image;
    await tester.pump(const Duration(minutes: 2));
    expect(identical(provider, tester.widget<Image>(find.byType(Image)).image), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('hidden avatars keep their image without polling', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TickerMode(enabled: false,
      child: ProtectedAvatarImage(url: 'https://example.invalid/profile.jpg', size: 48,
        placeholder: Icon(Icons.person)))));
    final provider = tester.widget<Image>(find.byType(Image)).image;
    await tester.pump(const Duration(minutes: 2));
    expect(identical(provider, tester.widget<Image>(find.byType(Image)).image), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('returning to an avatar rechecks access once', (tester) async {
    Widget page(bool visible) => MaterialApp(home: TickerMode(enabled: visible,
      child: const ProtectedAvatarImage(url: 'https://example.invalid/profile.jpg', size: 48,
        placeholder: Icon(Icons.person))));
    await tester.pumpWidget(page(true));
    final provider = tester.widget<Image>(find.byType(Image)).image;
    await tester.pumpWidget(page(false));
    expect(identical(provider, tester.widget<Image>(find.byType(Image)).image), isTrue);
    await tester.pumpWidget(page(true));
    expect(identical(provider, tester.widget<Image>(find.byType(Image)).image), isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  });

}
