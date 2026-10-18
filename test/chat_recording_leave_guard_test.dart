import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/shell/chat/chat_recording_leave_guard.dart';
import 'package:UniSpace/features/shell/chat/voice_session.dart';

class GuardVoice extends VoiceSessionController {
  GuardVoice() {
    phase = VoicePhase.recording;
  }
  int pauses = 0, cancellations = 0;
  @override
  Future<void> pause() async {
    pauses++;
    phase = VoicePhase.paused;
    notifyListeners();
  }

  @override
  Future<void> cancel() async {
    cancellations++;
    phase = VoicePhase.idle;
    notifyListeners();
  }
}

void main() {
  Future<void> open(WidgetTester tester, GuardVoice voice) async {
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                    body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => ChatRecordingLeaveGuard(
                              voice: voice,
                              child: Scaffold(
                                  appBar: AppBar(
                                      title: const Text('Recording route')),
                                  body: const Text('Draft is here'))))),
                  child: const Text('Open chat'),
                )))));
    await tester.tap(find.text('Open chat'));
    await tester.pumpAndSettle();
  }

  testWidgets('back pauses recording and stay preserves draft and route',
      (tester) async {
    final voice = GuardVoice();
    await open(tester, voice);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(voice.pauses, 1);
    expect(find.text('Leave this recording?'), findsOneWidget);
    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();
    expect(find.text('Recording route'), findsOneWidget);
    expect(voice.paused, true);
    expect(voice.cancellations, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    voice.dispose();
    await tester.pump();
  });
  testWidgets('discard cancels recording before navigating back',
      (tester) async {
    final voice = GuardVoice();
    await open(tester, voice);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard and leave'));
    await tester.pumpAndSettle();
    expect(voice.cancellations, 1);
    expect(voice.phase, VoicePhase.idle);
    expect(find.text('Recording route'), findsNothing);
    expect(find.text('Open chat'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    voice.dispose();
    await tester.pump();
  });
  testWidgets('idle route leaves without asking or discarding', (tester) async {
    final voice = GuardVoice()..phase = VoicePhase.idle;
    await open(tester, voice);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Leave this recording?'), findsNothing);
    expect(find.text('Open chat'), findsOneWidget);
    expect(voice.cancellations, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    voice.dispose();
    await tester.pump();
  });
}
