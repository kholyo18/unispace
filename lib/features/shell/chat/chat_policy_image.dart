import '../../../services/protected_network_image.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../services/chat_media_policy.dart';

class ChatPolicyImage extends StatefulWidget {
  const ChatPolicyImage(
      {super.key,
      required this.source,
      required this.scope,
      required this.authorized,
      this.width = 200,
      this.height = 200,
      this.fit = BoxFit.cover,
      this.onTap,
      this.cache,
      this.policy});
  final String source, scope;
  final bool Function() authorized;
  final double width, height;
  final BoxFit fit;
  final VoidCallback? onTap;
  @visibleForTesting
  final ChatImageMemoryCache? cache;
  @visibleForTesting
  final ChatMediaPolicy? policy;
  @override
  State<ChatPolicyImage> createState() => _ChatPolicyImageState();
}

class _ChatPolicyImageState extends State<ChatPolicyImage> {
  Uint8List? _bytes;
  bool _loading = false;
  bool _networkFallback = false;
  int _generation = 0;
  bool _wasAuthorized = false;
  ChatImageMemoryCache get _cache => widget.cache ?? chatImageMemoryCache;
  ChatMediaPolicy get _policy => widget.policy ?? chatMediaPolicy;
  @override
  void initState() {
    super.initState();
    _wasAuthorized = widget.authorized();
    _load(false);
  }

  @override
  void didUpdateWidget(ChatPolicyImage old) {
    super.didUpdateWidget(old);
    final authorized = widget.authorized();
    final authorizationChanged = authorized != _wasAuthorized;
    _wasAuthorized = authorized;
    if (authorizationChanged ||
        old.source != widget.source ||
        old.scope != widget.scope ||
        !widget.authorized()) {
      ++_generation;
      _bytes = null;
      _networkFallback = false;
      _loading = false;
      _load(false);
    }
  }

  Future<void> _load(bool manual) async {
    if (_loading || !widget.authorized()) return;
    final generation = ++_generation;
    final cached =
        _cache.peek(widget.scope, widget.source, authorized: widget.authorized);
    if (cached != null) {
      if (mounted) setState(() => _bytes = cached);
      return;
    }
    if (!manual && !await _policy.allowsAutomatic()) return;
    if (!mounted || generation != _generation || !widget.authorized()) return;
    setState(() => _loading = true);
    final bytes = await _cache.read(widget.scope, widget.source,
        authorized: widget.authorized);
    if (!mounted || generation != _generation) return;
    setState(() {
      _bytes = widget.authorized() ? bytes : null;
      _networkFallback = manual && bytes == null && widget.authorized();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final label = lang == 'ar'
        ? 'اضغط لتحميل الصورة'
        : lang == 'fr'
            ? 'Appuyer pour charger l’image'
            : 'Tap to load image';
    if (_networkFallback && widget.authorized()) {
      return SizedBox(
          width: widget.width,
          height: widget.height,
          child: GestureDetector(
              onTap: widget.onTap,
              child: ProtectedImage.network(
                widget.source,
                fit: widget.fit,
                cacheWidth: 720,
                errorBuilder: (_, __, ___) => InkWell(
                    onTap: () {
                      setState(() => _networkFallback = false);
                      _load(true);
                    },
                    child: Center(
                        child: Text(label, textAlign: TextAlign.center))),
              )));
    }
    return SizedBox(
        width: widget.width,
        height: widget.height,
        child: _bytes == null
            ? InkWell(
                onTap: _loading ? null : () => _load(true),
                child: Center(
                    child: _loading
                        ? (MediaQuery.disableAnimationsOf(context)
                            ? const Icon(Icons.hourglass_empty)
                            : const CircularProgressIndicator())
                        : Column(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.download),
                            Text(label, textAlign: TextAlign.center)
                          ])))
            : GestureDetector(
                onTap: widget.onTap,
                child: Image.memory(_bytes!,
                    fit: widget.fit,
                    cacheWidth: 720,
                    errorBuilder: (_, __, ___) => InkWell(
                        onTap: () {
                          _cache.clearScope(widget.scope);
                          setState(() => _bytes = null);
                          _load(true);
                        },
                        child: Center(
                            child:
                                Text(label, textAlign: TextAlign.center))))));
  }
}
