import 'package:flutter/material.dart';
import 'voice_session.dart';

/// A back gesture must not silently destroy an unsent recording.
class ChatRecordingLeaveGuard extends StatefulWidget {
  const ChatRecordingLeaveGuard({super.key, required this.voice, required this.child});
  final VoiceSessionController voice;
  final Widget child;
  @override
  State<ChatRecordingLeaveGuard> createState() => _ChatRecordingLeaveGuardState();
}
class _ChatRecordingLeaveGuardState extends State<ChatRecordingLeaveGuard> {
  bool _asking = false;
  String text(String ar, String en, String fr) => switch (Localizations.localeOf(context).languageCode) { 'ar' => ar, 'fr' => fr, _ => en };
  Future<void> _leave() async {
    if (_asking || widget.voice.phase == VoicePhase.sending) return;
    _asking = true;
    try {
      if (widget.voice.live) await widget.voice.pause();
      if (!mounted) return;
      final discard = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title: Text(text('مغادرة التسجيل؟', 'Leave this recording?', 'Quitter cet enregistrement ?')),
        content: Text(text('التسجيل لم يُرسل بعد. يمكنك البقاء لمراجعته أو متابعة التسجيل.', 'Your recording has not been sent. Stay to preview or continue recording.', 'Votre enregistrement n’a pas été envoyé. Restez pour l’écouter ou le continuer.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(text('البقاء', 'Stay', 'Rester'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(text('حذف ومغادرة', 'Discard and leave', 'Supprimer et quitter'))),
        ],
      ));
      if (discard != true || !mounted) return;
      await widget.voice.cancel();
      if (!mounted) return;
      // Rebuild PopScope with the idle state before asking the route to pop.
      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) Navigator.of(context).maybePop(); });
      setState(() {});
    } finally { _asking = false; }
  }
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.voice,
    builder: (context, _) => PopScope(
      canPop: !widget.voice.recording,
      onPopInvokedWithResult: (didPop, result) { if (!didPop) _leave(); },
      child: widget.child,
    ),
  );
}
