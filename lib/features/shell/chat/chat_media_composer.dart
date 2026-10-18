import 'chat_transfer_progress.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'chat_media_gallery.dart' show showChatMediaGallery;
import 'package:video_player/video_player.dart';
import 'chat_photo_editor.dart';
import 'chat_video_editor_page.dart';

String mediaText(BuildContext c, String ar, String en, String fr) =>
    switch (Localizations.localeOf(c).languageCode) {
      'ar' => ar,
      'fr' => fr,
      _ => en
    };

bool isChatVideo(File file) =>
    RegExp(r'\.(mp4|mov|m4v|3gp|webm|mkv)$', caseSensitive: false)
        .hasMatch(file.path);

class ChatMediaDraft {
  ChatMediaDraft(this.file) : video = isChatVideo(file);
  File file;
  final bool video;
  String caption = '';
  bool viewOnce = false,
      hd = false,
      sent = false,
      locked = false,
      prepared = false;
  double? progress;
  String? uploadUrl, thumbnailUrl, mediaId, queuedId;
  final generated = <File>[];
}

typedef SendMediaDraft = Future<void> Function(
    ChatMediaDraft draft, void Function(double?) progress);

/// One review path for photos, videos, camera and mixed selections. Upload is
/// explicit; failed items retain their identities and already-uploaded media.
class ChatMediaComposer extends StatefulWidget {
  const ChatMediaComposer(
      {super.key,
      required this.files,
      required this.onSend,
      this.initialCaption = '',
      this.onEnqueue,
      this.initialDrafts,
      this.onDraftsChanged,
      this.onDraftsSent});
  final List<File> files;
  final SendMediaDraft onSend;
  final FutureOr<void> Function(List<ChatMediaDraft>)? onEnqueue;
  final List<ChatMediaDraft>? initialDrafts;
  final Future<void> Function(List<ChatMediaDraft>)? onDraftsChanged;
  final Future<void> Function()? onDraftsSent;
  final String initialCaption;
  @override
  State<ChatMediaComposer> createState() => _ChatMediaComposerState();
}

class _ChatMediaComposerState extends State<ChatMediaComposer> {
  late final List<ChatMediaDraft> _drafts;
  final _caption = TextEditingController();
  int _index = 0;
  bool _sending = false,
      _editing = false,
      _handedOff = false,
      _leaving = false,
      _canLeave = false;
  Timer? _draftDebounce;
  Future<void> _draftWrites = Future.value();

  final List<File> _retiredGenerated = [];
  String? _error;
  ChatMediaDraft get current => _drafts[_index];
  bool get busy => _sending || _editing || _leaving;
  @override
  void initState() {
    super.initState();
    _drafts = widget.initialDrafts?.toList() ??
        widget.files.map(ChatMediaDraft.new).toList();
    if (_drafts.isNotEmpty) {
      if (widget.initialDrafts == null) current.caption = widget.initialCaption;
      _caption.text = current.caption;
    }
    _scheduleDraftSave();
  }

  void _scheduleDraftSave() {
    if (widget.onDraftsChanged == null || _handedOff) return;
    _draftDebounce?.cancel();
    _draftDebounce = Timer(const Duration(milliseconds: 300),
        () => unawaited(_saveDrafts().catchError((Object error) {})));
  }

  Future<void> _saveDrafts() {
    _draftDebounce?.cancel();
    if (widget.onDraftsChanged == null || _handedOff) return Future.value();
    final drafts = List<ChatMediaDraft>.unmodifiable(
        _drafts.where((draft) => !draft.sent && !draft.viewOnce));
    final next = _draftWrites.then((_) async {
      await widget.onDraftsChanged!(drafts);
    });
    _draftWrites = next.catchError((Object error) {
      if (mounted)
        setState(() => _error = mediaText(
            context,
            'تعذر حفظ المسودة. أعد المحاولة.',
            'Could not save draft. Try again.',
            'Impossible d’enregistrer le brouillon. Réessayez.'));
    });
    return next;
  }

  Future<void> _leave() async {
    if (busy) return;
    setState(() => _leaving = true);
    try {
      if (_handedOff)
        await widget.onDraftsSent?.call();
      else
        await _saveDrafts();
      if (!mounted) return;
      setState(() => _canLeave = true);
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _leaving = false);
    }
  }

  void _select(int index) {
    if (busy) return;
    setState(() {
      _index = index;
      _caption.text = current.caption;
      _error = null;
    });
  }

  Future<void> _edit() async {
    if (busy || current.locked) return;
    final draft = current;
    setState(() => _editing = true);
    try {
      final file = await Navigator.of(context).push<File>(MaterialPageRoute(
          builder: (_) => draft.video
              ? ChatVideoEditorPage(file: draft.file)
              : ChatPhotoEditorPage(file: draft.file, hd: true)));
      if (file != null && file.path != draft.file.path) {
        draft.file = file;
        draft.generated.add(file);
        draft.prepared = false;
        _scheduleDraftSave();
      }
    } catch (_) {
      if (mounted)
        _error = mediaText(
            context,
            'تعذر تعديل الوسائط. حاول مجددًا.',
            'Could not edit media. Try again.',
            'Impossible de modifier le média. Réessayez.');
    } finally {
      if (mounted) setState(() => _editing = false);
    }
  }

  Future<void> _add() async {
    if (busy) return;
    try {
      final files = await showChatMediaGallery(context);
      if (!mounted || files == null) return;
      setState(() => _drafts
          .addAll(files.take(30 - _drafts.length).map(ChatMediaDraft.new)));
      _scheduleDraftSave();
    } catch (_) {
      if (mounted)
        setState(() => _error = mediaText(context, 'تعذر فتح المعرض',
            'Could not open gallery', 'Impossible d’ouvrir la galerie'));
    }
  }

  Future<void> _send() async {
    if (busy || _handedOff || _drafts.isEmpty) return;
    if (widget.onEnqueue != null) {
      setState(() => _sending = true);
      try {
        await _saveDrafts();
        await widget.onEnqueue!(List.unmodifiable(_drafts));
        _handedOff = true;
        _draftDebounce?.cancel();
        await widget.onDraftsSent?.call();
        if (!mounted) return;
        _canLeave = true;
        Navigator.of(context).pop(true);
      } catch (_) {
        _sending = false;
        setState(() => _error = mediaText(context, 'تعذر الإرسال. حاول مجددًا.',
            'Could not send. Try again.', 'Envoi impossible. Réessayez.'));
      }
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      for (final draft in _drafts.where((d) => !d.sent)) {
        setState(() {
          _index = _drafts.indexOf(draft);
          _caption.text = draft.caption;
          draft.locked = true;
          draft.progress = null;
        });
        await widget.onSend(draft, (value) {
          if (mounted) setState(() => draft.progress = value);
        });
        draft.sent = true;
        if (mounted) setState(() {});
      }
      await widget.onDraftsSent?.call();
      _draftDebounce?.cancel();
      _canLeave = true;
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      for (final draft in _drafts) {
        if (draft.uploadUrl == null && draft.queuedId == null)
          draft.locked = false;
      }
      if (mounted)
        setState(() => _error = error is MediaSendException
            ? error.message
            : mediaText(
                context,
                'تعذر الإرسال. أعد المحاولة؛ لن تتكرر العناصر المرسلة.',
                'Send failed. Retry; sent items will not be duplicated.',
                'Échec de l’envoi. Réessayez ; les éléments envoyés ne seront pas dupliqués.'));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _draftDebounce?.cancel();
    _caption.dispose();
    // If a parent removes the route directly, flush before retiring edited files.
    final saved = _handedOff ? Future<void>.value() : _saveDrafts();
    unawaited(saved.then((_) async {
      for (final file in _retiredGenerated) {
        await _delete(file);
      }
      if (!_handedOff)
        for (final draft in _drafts.where((draft) =>
            widget.onDraftsChanged == null || draft.viewOnce || draft.sent)) {
          for (final file in draft.generated) {
            await _delete(file);
          }
        }
    }).catchError((Object error) {}));
    super.dispose();
  }

  Future<void> _delete(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_drafts.isEmpty) return const Scaffold(body: SizedBox.shrink());
    final d = current;
    return PopScope(
        canPop: !busy && (widget.onDraftsChanged == null || _canLeave),
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !busy) unawaited(_leave());
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: Text('${_index + 1}/${_drafts.length}'),
              actions: [
                if (!d.video)
                  TextButton(
                      onPressed: busy || d.locked
                          ? null
                          : () => setState(() {
                                d.hd = !d.hd;
                                d.prepared = false;
                                _scheduleDraftSave();
                              }),
                      child: Text(d.hd ? 'HD' : 'SD',
                          style: TextStyle(
                              color:
                                  d.hd ? Colors.greenAccent : Colors.white))),
                IconButton(
                    key: const ValueKey('media-edit'),
                    tooltip: mediaText(context, 'تعديل', 'Edit', 'Modifier'),
                    onPressed: busy || d.locked ? null : _edit,
                    icon: const Icon(Icons.edit_outlined)),
                IconButton(
                    tooltip: mediaText(context, 'إزالة', 'Remove', 'Retirer'),
                    onPressed: busy || d.sent
                        ? null
                        : () {
                            final removed = _drafts[_index];
                            for (final f in removed.generated) {
                              _retiredGenerated.add(f);
                            }
                            setState(() {
                              _drafts.removeAt(_index);
                              _scheduleDraftSave();
                              if (_drafts.isEmpty) {
                                unawaited(_leave());
                                return;
                              }
                              _index = _index.clamp(0, _drafts.length - 1);
                              _caption.text = current.caption;
                            });
                          },
                    icon: const Icon(Icons.delete_outline)),
              ]),
          body: SafeArea(
              child: Column(children: [
            Expanded(
                child: _editing
                    ? const SizedBox.shrink()
                    : d.video
                        ? _DraftVideo(key: ValueKey(d.file.path), file: d.file)
                        : InteractiveViewer(
                            child: Center(
                                child: Image.file(d.file,
                                    fit: BoxFit.contain,
                                    cacheWidth: d.hd ? 1600 : 1000,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.broken_image,
                                        color: Colors.white,
                                        size: 50))))),
            if (_error != null)
              Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.redAccent))),
            if (_sending)
              ChatTransferProgress(
                label: current.uploadUrl != null || current.progress == 1
                    ? mediaText(context, 'جارٍ إتمام الإرسال', 'Finishing send',
                        'Finalisation de l’envoi')
                    : current.progress == null
                        ? mediaText(context, 'جارٍ تجهيز الوسائط',
                            'Preparing media', 'Préparation du média')
                        : mediaText(context, 'جارٍ الإرسال', 'Sending',
                            'Envoi en cours'),
                detail: '${_index + 1} / ${_drafts.length}',
                progress: current.uploadUrl != null || current.progress == 1
                    ? null
                    : current.progress,
              ),
            SizedBox(
                height: 68,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  for (var i = 0; i < _drafts.length; i++)
                    GestureDetector(
                        onTap: () => _select(i),
                        child: Container(
                            width: 60,
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: i == _index
                                        ? Colors.greenAccent
                                        : Colors.white30,
                                    width: 2)),
                            child: Stack(fit: StackFit.expand, children: [
                              _drafts[i].video
                                  ? const Icon(Icons.videocam,
                                      color: Colors.white)
                                  : Image.file(_drafts[i].file,
                                      fit: BoxFit.cover,
                                      cacheWidth: 120,
                                      errorBuilder: (_, __, ___) => const Icon(
                                          Icons.broken_image,
                                          color: Colors.white)),
                              if (_drafts[i].sent)
                                const Icon(Icons.check_circle,
                                    color: Colors.greenAccent),
                              if (_drafts[i].viewOnce)
                                const Align(
                                    alignment: Alignment.bottomRight,
                                    child: Icon(Icons.looks_one_outlined,
                                        color: Colors.white, size: 20)),
                            ]))),
                  if (_drafts.length < 30)
                    IconButton(
                        onPressed: busy ? null : _add,
                        icon: const Icon(Icons.add, color: Colors.white)),
                ])),
            if (d.viewOnce)
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                      mediaText(
                          context,
                          'صورة لمرة واحدة: لا تظهر معاينتها في المحادثة، ولا يمكنك فتحها بعد إرسالها.',
                          'View once: no chat preview, and you cannot reopen it after sending.',
                          'Vue unique : aucun aperçu dans la discussion et aucune réouverture après envoi.'),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12))),
            Padding(
                padding: const EdgeInsets.all(10),
                child: Row(children: [
                  Expanded(
                      child: TextField(
                          controller: _caption,
                          enabled: !busy && !d.locked && !d.viewOnce,
                          maxLength: 1000,
                          maxLines: 2,
                          minLines: 1,
                          onChanged: (v) {
                            d.caption = v;
                            _scheduleDraftSave();
                          },
                          style: const TextStyle(
                              color: Colors.white,
                              fontFamilyFallback: ['NotoColorEmoji']),
                          decoration: InputDecoration(
                              counterText: '',
                              hintText: mediaText(context, 'إضافة تعليق…',
                                  'Add a caption…', 'Ajouter une légende…'),
                              hintStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.white12,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24))))),
                  if (!d.video)
                    IconButton(
                        key: const ValueKey('media-view-once'),
                        tooltip: mediaText(context, 'العرض مرة واحدة',
                            'View once', 'Vue unique'),
                        onPressed: busy || d.locked || !Platform.isAndroid
                            ? null
                            : () => setState(() {
                                  d.viewOnce = !d.viewOnce;
                                  _scheduleDraftSave();
                                }),
                        icon: Icon(Icons.looks_one_outlined,
                            color: d.viewOnce
                                ? Colors.greenAccent
                                : Colors.white)),
                  IconButton(
                      key: const ValueKey('media-send'),
                      tooltip: mediaText(context, 'إرسال', 'Send', 'Envoyer'),
                      onPressed: busy ? null : _send,
                      icon: busy
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send, color: Colors.greenAccent)),
                ])),
          ])),
        ));
  }
}

class MediaSendException implements Exception {
  const MediaSendException(this.message);
  final String message;
}

class _DraftVideo extends StatefulWidget {
  const _DraftVideo({super.key, required this.file});
  final File file;
  @override
  State<_DraftVideo> createState() => _DraftVideoState();
}

class _DraftVideoState extends State<_DraftVideo> with WidgetsBindingObserver {
  late final VideoPlayerController _player;
  bool _ready = false, _error = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _player = VideoPlayerController.file(widget.file);
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      await _player.initialize();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s != AppLifecycleState.resumed) unawaited(_pause());
  }

  Future<void> _pause() async {
    try {
      await _player.pause();
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => _error
      ? const Icon(Icons.error_outline, color: Colors.white)
      : !_ready
          ? const Center(child: CircularProgressIndicator())
          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Flexible(
                  child: AspectRatio(
                      aspectRatio: _player.value.aspectRatio,
                      child: VideoPlayer(_player))),
              VideoProgressIndicator(_player, allowScrubbing: true),
              IconButton(
                  onPressed: () async {
                    try {
                      if (_player.value.isPlaying) {
                        await _player.pause();
                      } else {
                        await _player.play();
                      }
                      if (mounted) setState(() {});
                    } catch (_) {
                      if (mounted) setState(() => _error = true);
                    }
                  },
                  icon: Icon(
                      _player.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white)),
            ]);
}
