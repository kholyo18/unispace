import '../../../services/protected_media_service.dart';
import '../../../services/protected_network_image.dart';
import 'dart:async';
import 'dart:typed_data';
import '../../../services/chat_media_policy.dart';
import 'chat_policy_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../l10n/shell_strings.dart';
import '../../../services/video_playback_source.dart';

String _label(BuildContext c, String ar, String en, String fr) =>
    switch (Localizations.localeOf(c).languageCode) {
      'ar' => ar,
      'fr' => fr,
      _ => en
    };

/// Never downloads a video or creates a player just to show a conversation row.
class ChatVideoThumbnail extends StatelessWidget {
  const ChatVideoThumbnail(
      {super.key,
      required this.url,
      this.thumbnailUrl,
      this.scope,
      this.authorized});
  final String url;
  final String? thumbnailUrl;
  final String? scope;
  final bool Function()? authorized;
  @override
  Widget build(BuildContext context) => Semantics(
      label: _label(context, 'فيديو', 'Video', 'Vidéo'),
      child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
              width: 200,
              height: 240,
              child: Stack(fit: StackFit.expand, children: [
                const ColoredBox(color: Colors.black87),
                if (thumbnailUrl?.isNotEmpty == true)
                  if (scope != null && authorized != null)
                    ChatPolicyImage(
                        source: thumbnailUrl!,
                        scope: scope!,
                        authorized: authorized!,
                        width: 200,
                        height: 240)
                  else
                    ProtectedImage.network(thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                const Center(
                    child: Icon(Icons.play_circle_fill_rounded,
                        color: Colors.white, size: 54)),
              ]))));
}

/// Chat URL-only APIs cannot satisfy the fresh authorization contract of the
/// post-media disk cache. Stream on demand; do not persist URLs or cached bytes.
class ChatVideoViewer extends StatefulWidget {
  const ChatVideoViewer({super.key, required this.url, this.controllerFactory});
  final String url;
  @visibleForTesting
  final VideoPlayerController Function(String)? controllerFactory;
  @override
  State<ChatVideoViewer> createState() => _ChatVideoViewerState();
}

class _ChatVideoViewerState extends State<ChatVideoViewer>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  String? _playbackScope;
  bool get _samePlaybackSession => _playbackScope == null ||
      _playbackScope == ProtectedMediaService.instance.scope;
  bool _failed = false, _foreground = true;
  int _attempt = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  @override
  void didUpdateWidget(ChatVideoViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) unawaited(_load());
  }

  void _release() {
    final c = _controller;
    _controller = null;
    if (c != null) {
      c.removeListener(_tick);
      unawaited(c.dispose());
    }
  }

  bool _current(VideoPlayerController c, int attempt) =>
      mounted && identical(_controller, c) && attempt == _attempt && _samePlaybackSession;
  Future<void> _load() async {
    final attempt = ++_attempt;
    _release();
    setState(() => _failed = false);
    try {
      final factory = widget.controllerFactory;
      final grant = factory == null
          ? await ProtectedMediaService.instance.resolve(widget.url) : null;
      if (!(mounted && attempt == _attempt)) return;
      _playbackScope = grant?.scope;
      final c = factory != null ? factory(widget.url)
          : VideoPlayerController.networkUrl(Uri.parse(grant!.url));
      _controller = c;
      c.addListener(_tick);
      await initializeVideoPlayback(c);
      if (grant != null && grant.scope != ProtectedMediaService.instance.scope) {
        throw StateError('Media session changed');
      }
      if (!_current(c, attempt)) return;
      await c.setVolume(1);
      if (!_current(c, attempt)) return;
      await startVisibleVideo(c, () => _current(c, attempt) && _foreground);
      if (_current(c, attempt)) setState(() {});
    } catch (_) {
      if (!mounted || attempt != _attempt) return;
      _release();
      setState(() => _failed = true);
    }
  }

  void _tick() {
    if (mounted) {
      setState(() {
        if (_controller?.value.hasError == true) _failed = true;
      });
    }
  }

  Future<void> _toggle() async {
    final c = _controller;
    if (c == null) return;
    try {
      if (c.value.isPlaying) {
        await c.pause();
      } else {
        if (c.value.position >= c.value.duration) await c.seekTo(Duration.zero);
        await startVisibleVideo(
            c, () => mounted && identical(_controller, c) && _foreground && _samePlaybackSession);
      }
    } catch (_) {
      if (mounted && identical(_controller, c)) setState(() => _failed = true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) unawaited(_pause());
  }

  Future<void> _pause() async {
    try {
      await _controller?.pause();
    } catch (_) {/* Navigation must stay usable. */}
  }

  @override
  void dispose() {
    ++_attempt;
    WidgetsBinding.instance.removeObserver(this);
    _release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white)),
        body: Center(
            child: _failed
                ? _MediaFailure(
                    message: _label(
                        context,
                        'تعذر تحميل الفيديو',
                        'Could not load the video',
                        'Impossible de charger la vidéo'),
                    onRetry: () => unawaited(_load()))
                : c == null || !c.value.isInitialized
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Flexible(
                                child: AspectRatio(
                                    aspectRatio: c.value.aspectRatio,
                                    child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          GestureDetector(
                                              onTap: _toggle,
                                              child: VideoPlayer(c)),
                                          if (c.value.isBuffering)
                                            const CircularProgressIndicator(
                                                color: Colors.white)
                                        ]))),
                            VideoProgressIndicator(c,
                                allowScrubbing: true,
                                padding: const EdgeInsets.all(16)),
                            IconButton(
                                onPressed: _toggle,
                                tooltip: c.value.isPlaying
                                    ? shellText(context, 'إيقاف مؤقت')
                                    : _label(context, 'تشغيل', 'Play', 'Lire'),
                                icon: Icon(
                                    c.value.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 40)),
                          ])));
  }
}

class ChatImageViewer extends StatefulWidget {
  const ChatImageViewer(
      {super.key, required this.url, this.scope, this.authorized, this.cache});
  final String url;
  final String? scope;
  final bool Function()? authorized;
  @visibleForTesting
  final ChatImageMemoryCache? cache;
  @override
  State<ChatImageViewer> createState() => _ChatImageViewerState();
}

class _ChatImageViewerState extends State<ChatImageViewer> {
  int _attempt = 0;
  Uint8List? _bytes;
  bool _loading = false, _revoked = false;
  Timer? _accessTimer;
  ChatImageMemoryCache get _cache => widget.cache ?? chatImageMemoryCache;
  bool get _allowed => !_revoked && (widget.authorized?.call() ?? true);
  bool get _scoped =>
      widget.scope?.isNotEmpty == true && widget.authorized != null;
  @override
  void initState() {
    super.initState();
    _load();
    // The pushed route does not rebuild when the conversation below is revoked.
    _accessTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (mounted && !_revoked && !(widget.authorized?.call() ?? true)) {
        _revoke();
      }
    });
  }

  void _revoke() {
    _attempt++;
    if (_scoped) _cache.clearScope(widget.scope!);
    final bytes = _bytes;
    if (bytes != null) unawaited(MemoryImage(bytes).evict());
    unawaited(ProtectedNetworkImage(widget.url).evict().catchError((Object _) => false));
    setState(() {
      _bytes = null;
      _loading = false;
      _revoked = true;
    });
  }

  Future<void> _load() async {
    if (!_allowed) {
      _revoked = true;
      return;
    }
    if (!_scoped) return;
    final attempt = ++_attempt;
    final cached =
        _cache.peek(widget.scope!, widget.url, authorized: () => _allowed);
    if (cached != null) {
      _bytes = cached;
      return;
    }
    _loading = true;
    final bytes = await _cache.read(widget.scope!, widget.url,
        authorized: () => _allowed);
    if (!mounted || attempt != _attempt) return;
    if (!_allowed) {
      _revoke();
      return;
    }
    setState(() {
      _bytes = bytes;
      _loading = false;
    });
    // Large images exceed the optional cache cap but remain viewable on demand.
  }

  @override
  void didUpdateWidget(ChatImageViewer old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url || old.scope != widget.scope) {
      _attempt++;
      _bytes = null;
      _loading = false;
      _revoked = false;
      _load();
    } else if (!_allowed && !_revoked) {
      _revoke();
    }
  }

  Future<void> _retry() async {
    if (!_allowed) return;
    if (_scoped) _cache.clearScope(widget.scope!);
    final bytes = _bytes;
    if (bytes != null) await MemoryImage(bytes).evict();
    try { await ProtectedNetworkImage(widget.url).evict(); } catch (_) {}
    if (!mounted) return;
    setState(() {
      _bytes = null;
      _attempt++;
    });
    await _load();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _attempt++;
    _accessTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white)),
        body: Center(
            child: !_allowed
                ? Text(
                    _label(
                        context,
                        'لم يعد هذا المحتوى متاحًا',
                        'This media is no longer available',
                        'Ce média n’est plus disponible'),
                    style: const TextStyle(color: Colors.white))
                : _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : InteractiveViewer(
                        child: _bytes != null
                            ? Image.memory(_bytes!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => _MediaFailure(
                                    message:
                                        shellText(context, 'تعذر تحميل الصورة'),
                                    onRetry: () => unawaited(_retry())))
                            : ProtectedImage.network(widget.url,
                                key: ValueKey('${widget.url}:$_attempt'),
                                fit: BoxFit.contain,
                                loadingBuilder: (_, child, progress) => progress == null
                                    ? child
                                    : const CircularProgressIndicator(
                                        color: Colors.white),
                                errorBuilder: (_, __, ___) => _MediaFailure(
                                    message: shellText(context, 'تعذر تحميل الصورة'),
                                    onRetry: () => unawaited(_retry()))))),
      );
}

class _MediaFailure extends StatelessWidget {
  const _MediaFailure({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        Text(message, style: const TextStyle(color: Colors.white)),
        TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(shellText(context, 'إعادة المحاولة'))),
      ]);
}
