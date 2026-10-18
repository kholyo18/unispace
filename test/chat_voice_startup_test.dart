import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/shell/chat_page.dart';

class FakeVoiceSession extends VoiceSessionController {
  FakeVoiceSession({this.startGate});
  final Completer<bool>? startGate;
  int starts = 0, stops = 0, cancels = 0, pauses = 0, resumes = 0, previews = 0;
  @override
  Future<void> pause() async {
    pauses++;
    phase = VoicePhase.paused;
    notifyListeners();
  }

  @override
  Future<void> resume() async {
    resumes++;
    phase = VoicePhase.recording;
    notifyListeners();
  }

  @override
  Future<void> togglePreview() async {
    previews++;
  }

  @override
  Duration get elapsed => const Duration(seconds: 1);
  @override
  Future<bool> start() async {
    starts++;
    phase = VoicePhase.starting;
    notifyListeners();
    final ok = await (startGate?.future ?? Future.value(true));
    phase = ok ? VoicePhase.recording : VoicePhase.idle;
    notifyListeners();
    return ok;
  }

  @override
  Future<File?> stopForSend() async {
    if (phase != VoicePhase.recording && phase != VoicePhase.paused)
      return null;
    stops++;
    phase = VoicePhase.idle;
    notifyListeners();
    return File('test-voice.m4a');
  }

  @override
  Future<void> cancel() async {
    cancels++;
    phase = VoicePhase.idle;
    notifyListeners();
  }
}

Widget host(FakeVoiceSession session, VoidCallback sent,
        {Future<bool> Function()? before}) =>
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: PulseVoiceHost(
            session: session,
            hasText: false,
            sending: false,
            inputBar: const SizedBox(height: 40),
            onSendText: () {},
            onSendVoice: (_, duration) async {
              expect(duration, const Duration(seconds: 1));
              sent();
            },
            onBeforeStart: before,
          ),
        ),
      ),
    );

void main() {
  testWidgets('release waits for access check then previews without sending',
      (tester) async {
    final access = Completer<bool>();
    final session = FakeVoiceSession();
    var sent = 0;
    await tester
        .pumpWidget(host(session, () => sent++, before: () => access.future));
    final press = await tester
        .startGesture(tester.getCenter(find.byIcon(Icons.mic_rounded)));
    await tester.pump(const Duration(milliseconds: 250));
    await press.up();
    await tester.pump();
    expect(sent, 0);
    expect(session.starts, 0);
    access.complete(true);
    await tester.pumpAndSettle();
    expect(session.stops, 0);
    expect(session.pauses, 1);
    expect(sent, 0);
    expect(session.phase, VoicePhase.paused);
    await tester.tap(find.byKey(const ValueKey('voice-preview')));
    await tester.pumpAndSettle();
    expect(session.previews, 1);
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();
    expect(sent, 1);
  });

  testWidgets('release waits for native recorder startup', (tester) async {
    final gate = Completer<bool>();
    final session = FakeVoiceSession(startGate: gate);
    var sent = 0;
    await tester.pumpWidget(host(session, () => sent++));
    final press = await tester
        .startGesture(tester.getCenter(find.byIcon(Icons.mic_rounded)));
    await tester.pump(const Duration(milliseconds: 250));
    await press.up();
    await tester.pump();
    expect(sent, 0);
    gate.complete(true);
    await tester.pumpAndSettle();
    expect(session.pauses, 1);
    expect(sent, 0);
    expect(session.phase, VoicePhase.paused);
  });

  testWidgets('pointer cancellation during access check never starts or sends',
      (tester) async {
    final access = Completer<bool>();
    final session = FakeVoiceSession();
    var sent = 0;
    await tester
        .pumpWidget(host(session, () => sent++, before: () => access.future));
    final press = await tester
        .startGesture(tester.getCenter(find.byIcon(Icons.mic_rounded)));
    await tester.pump(const Duration(milliseconds: 250));
    await press.cancel();
    access.complete(true);
    await tester.pumpAndSettle();
    expect(session.starts, 0);
    expect(sent, 0);
    expect(session.phase, VoicePhase.idle);
  });

  testWidgets('pointer cancellation while recording discards audio',
      (tester) async {
    final session = FakeVoiceSession();
    var sent = 0;
    await tester.pumpWidget(host(session, () => sent++));
    final press = await tester
        .startGesture(tester.getCenter(find.byIcon(Icons.mic_rounded)));
    await tester.pump(const Duration(milliseconds: 250));
    await press.cancel();
    await tester.pumpAndSettle();
    expect(session.cancels, greaterThan(0));
    expect(sent, 0);
    expect(session.phase, VoicePhase.idle);
  });
  testWidgets(
      'swipe up locks; release continues; pause preview resume sends once',
      (tester) async {
    final session = FakeVoiceSession();
    var sent = 0;
    await tester.pumpWidget(host(session, () => sent++));
    final p = tester.getCenter(find.byIcon(Icons.mic_rounded));
    final press = await tester.startGesture(p);
    await tester.pump(const Duration(milliseconds: 250));
    await press.moveTo(p.translate(0, -100));
    await tester.pump();
    await press.up();
    await tester.pumpAndSettle();
    expect(session.phase, VoicePhase.recording);
    expect(sent, 0);
    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pumpAndSettle();
    expect(session.phase, VoicePhase.paused);
    await tester.tap(find.byKey(const ValueKey('voice-preview')));
    await tester.pump();
    expect(session.previews, 1);
    await tester.tap(find.byIcon(Icons.mic_rounded).hitTestable());
    await tester.pumpAndSettle();
    expect(session.resumes, 1);
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();
    expect(sent, 1);
  });

  testWidgets('swipe left discards without sending', (tester) async {
    final session = FakeVoiceSession();
    var sent = 0;
    await tester.pumpWidget(host(session, () => sent++));
    final p = tester.getCenter(find.byIcon(Icons.mic_rounded));
    final press = await tester.startGesture(p);
    await tester.pump(const Duration(milliseconds: 250));
    await press.moveTo(p.translate(-90, 0));
    await press.up();
    await tester.pumpAndSettle();
    expect(session.cancels, greaterThan(0));
    expect(sent, 0);
  });

  testWidgets('short tap retains hands-free recording', (tester) async {
    final session = FakeVoiceSession();
    await tester.pumpWidget(host(session, () {}));
    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pumpAndSettle();
    expect(session.phase, VoicePhase.recording);
    expect(session.pauses, 0);
  });
  testWidgets('background during startup pauses before it can keep recording',
      (tester) async {
    final gate = Completer<bool>();
    final session = FakeVoiceSession(startGate: gate);
    var sent = 0;
    await tester.pumpWidget(host(session, () => sent++));
    final press = await tester
        .startGesture(tester.getCenter(find.byIcon(Icons.mic_rounded)));
    await tester.pump(const Duration(milliseconds: 250));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    gate.complete(true);
    await tester.pumpAndSettle();
    expect(session.phase, VoicePhase.paused);
    expect(sent, 0);
    await press.up();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
  });
}
