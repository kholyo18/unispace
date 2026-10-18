import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../services/chat_video_edit_service.dart';

class ChatVideoEditorPage extends StatefulWidget {
  const ChatVideoEditorPage({super.key, required this.file});
  final File file;
  @override
  State<ChatVideoEditorPage> createState() => _ChatVideoEditorPageState();
}

class _ChatVideoEditorPageState extends State<ChatVideoEditorPage>
    with WidgetsBindingObserver {
  final _service = const ChatVideoEditService();
  late final VideoPlayerController _player;
  double _start = 0, _end = 1, _duration = 1;
  bool _ready = false,
      _muted = false,
      _exporting = false,
      _boundaryBusy = false;
  int _turns = 0;
  int _exportGeneration = 0;
  int? _progress;
  String? _error;
  Timer? _timer;
  String _t(String ar, String en, String fr) =>
      switch (Localizations.localeOf(context).languageCode) {
        'ar' => ar,
        'fr' => fr,
        _ => en,
      };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _player = VideoPlayerController.file(widget.file);
    _load();
  }

  Future<void> _load() async {
    try {
      await _player.initialize();
      if (!mounted) return;
      final duration = _player.value.duration.inMilliseconds.toDouble();
      if (duration <= 0) throw StateError('Empty video');
      _player.addListener(_boundary);
      setState(() {
        _duration = duration;
        _end = duration.clamp(1, 60000);
        _ready = true;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'load');
    }
  }

  void _boundary() {
    if (_boundaryBusy ||
        !_ready ||
        !_player.value.isPlaying ||
        _player.value.position.inMilliseconds < _end) return;
    _boundaryBusy = true;
    _player
        .pause()
        .then((_) => _player.seekTo(Duration(milliseconds: _start.round())))
        .catchError((Object _) {})
        .whenComplete(() {
      _boundaryBusy = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(_player.pause().catchError((Object _) {}));
    }
  }

  Future<void> _play() async {
    try {
      if (_player.value.isPlaying) {
        await _player.pause();
      } else {
        final position = _player.value.position.inMilliseconds;
        if (position < _start || position >= _end) {
          await _player.seekTo(Duration(milliseconds: _start.round()));
        }
        await _player.play();
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'play');
    }
  }

  Future<void> _apply() async {
    if (!_ready || _exporting) return;
    if (!Platform.isAndroid) {
      setState(() => _error = 'platform');
      return;
    }
    final generation = ++_exportGeneration;
    setState(() {
      _exporting = true;
      _error = null;
      _progress = null;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      try {
        final value = await _service.progress();
        if (mounted && _exporting && generation == _exportGeneration) {
          setState(() => _progress = value);
        }
      } catch (_) {}
    });
    try {
      await _player.pause();
      if (!mounted || generation != _exportGeneration) return;
      final result = await _service.export(
        widget.file,
        ChatVideoEdit(
          startMs: _start.round(),
          endMs: _end.round(),
          muted: _muted,
          quarterTurns: _turns,
        ),
        _duration.round(),
      );
      if (mounted && generation == _exportGeneration) {
        Navigator.of(context).pop(result);
      } else {
        try {
          await result.delete();
        } catch (_) {}
      }
    } catch (_) {
      if (mounted && _exporting && generation == _exportGeneration)
        setState(() => _error = 'export');
    } finally {
      if (generation == _exportGeneration) {
        _timer?.cancel();
        if (mounted) setState(() => _exporting = false);
      }
    }
  }

  Future<void> _cancelExport() async {
    if (!_exporting) return;
    ++_exportGeneration;
    _timer?.cancel();
    try {
      await _service.cancel();
    } catch (_) {}
    if (mounted) setState(() => _exporting = false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    if (_exporting) unawaited(_service.cancel().catchError((Object _) {}));
    _player.removeListener(_boundary);
    unawaited(_player.dispose().catchError((Object _) {}));
    super.dispose();
  }

  String _time(double ms) {
    final seconds = (ms / 1000).floor();
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_exporting,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _exporting) _cancelExport();
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: Text(_t('تعديل الفيديو', 'Edit video', 'Modifier la vidéo')),
            actions: [
              TextButton(
                onPressed: _ready && !_exporting ? _apply : null,
                child: Text(_t('تطبيق', 'Apply', 'Appliquer')),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: !_ready
                        ? (_error == null
                            ? const CircularProgressIndicator()
                            : const Icon(
                                Icons.error_outline,
                                color: Colors.white,
                              ))
                        : RotatedBox(
                            quarterTurns: _turns,
                            child: AspectRatio(
                              aspectRatio: _player.value.aspectRatio,
                              child: VideoPlayer(_player),
                            ),
                          ),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _error == 'platform'
                          ? _t(
                              'تعديل الفيديو متاح على Android حاليًا.',
                              'Video editing is currently available on Android.',
                              'La modification vidéo est disponible sur Android.',
                            )
                          : _t(
                              'تعذر معالجة الفيديو. احتفظنا بالمسودة، حاول مجددًا.',
                              'Could not process video. Your draft is kept; try again.',
                              'Impossible de traiter la vidéo. Le brouillon est conservé ; réessayez.',
                            ),
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ),
                if (_ready) ...[
                  Text(
                    '${_time(_start)} — ${_time(_end)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    _t(
                      'حدّد مقطعًا لا يتجاوز 60 ثانية',
                      'Choose a clip up to 60 seconds',
                      'Choisissez un extrait de 60 secondes maximum',
                    ),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  RangeSlider(
                    min: 0,
                    max: _duration,
                    values: RangeValues(_start, _end),
                    onChanged: _exporting
                        ? null
                        : (value) {
                            double start = value.start, end = value.end;
                            if (end - start < 100) return;
                            if (end - start > 60000) {
                              if (start != _start) {
                                end = start + 60000;
                              } else {
                                start = end - 60000;
                              }
                            }
                            setState(() {
                              _start = start;
                              _end = end;
                            });
                          },
                    onChangeEnd: (_) async {
                      try {
                        await _player.pause();
                        if (mounted)
                          await _player.seekTo(
                            Duration(milliseconds: _start.round()),
                          );
                      } catch (_) {
                        if (mounted) setState(() => _error = 'play');
                      }
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ValueListenableBuilder<VideoPlayerValue>(
                        valueListenable: _player,
                        builder: (_, value, child) => IconButton(
                          color: Colors.white,
                          tooltip: _t(
                            'تشغيل / إيقاف',
                            'Play / pause',
                            'Lire / pause',
                          ),
                          onPressed: _exporting ? null : _play,
                          icon: Icon(
                            value.isPlaying ? Icons.pause : Icons.play_arrow,
                          ),
                        ),
                      ),
                      IconButton(
                        color: Colors.white,
                        tooltip: _t('كتم الصوت', 'Mute audio', 'Couper le son'),
                        onPressed: _exporting
                            ? null
                            : () async {
                                setState(() => _muted = !_muted);
                                try {
                                  await _player.setVolume(_muted ? 0 : 1);
                                } catch (_) {
                                  if (mounted) setState(() => _error = 'play');
                                }
                              },
                        icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
                      ),
                      IconButton(
                        color: Colors.white,
                        tooltip: _t('تدوير', 'Rotate', 'Pivoter'),
                        onPressed: _exporting
                            ? null
                            : () => setState(() => _turns = (_turns + 1) % 4),
                        icon: const Icon(Icons.rotate_right),
                      ),
                    ],
                  ),
                ],
                if (_exporting) ...[
                  LinearProgressIndicator(
                    value: _progress == null ? null : _progress! / 100,
                  ),
                  TextButton(
                    onPressed: _cancelExport,
                    child: Text(
                      _t(
                        'إلغاء المعالجة',
                        'Cancel export',
                        'Annuler le traitement',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}
