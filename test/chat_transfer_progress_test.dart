import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/shell/chat/chat_transfer_progress.dart';

void main() {
  testWidgets('known progress and cancellation, unknown totals hide percentage',
      (tester) async {
    var cancelled = false;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ChatTransferProgress(
                label: 'Downloading',
                detail: 'file.mp4',
                progress: .42,
                onCancel: () => cancelled = true))));
    expect(find.text('42%'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    expect(cancelled, isTrue);
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: ChatTransferProgress(label: 'Preparing media'))));
    expect(find.text('42%'), findsNothing);
    expect(
        tester
            .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator))
            .value,
        isNull);
  });
}
