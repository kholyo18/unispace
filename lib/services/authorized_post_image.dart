import 'package:UniSpace/l10n/shell_strings.dart';
import 'authorized_media_cache.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'post_media_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Used inside the authorized pager, whose lifecycle clears access on resume,
/// account changes and local privacy/block/moderation revisions.
class AuthorizedPostImage extends StatefulWidget {
  const AuthorizedPostImage(
      {super.key,
      required this.postId,
      required this.url,
      required this.active,
      this.prepare = false,
      this.policyRevision = 0,
      this.grant,
      this.commentId,
      this.fit = BoxFit.contain})
      : _readLink = null,
        _currentViewer = null,
        _imageProvider = null;

  @visibleForTesting
  const AuthorizedPostImage.testing(
      {super.key,
      required this.postId,
      required this.url,
      required this.active,
      this.prepare = false,
      this.policyRevision = 0,
      this.grant,
      this.commentId,
      this.fit = BoxFit.contain,
      required Future<String> Function() readLink,
      required String? Function() currentViewer,
      required ImageProvider Function(String, String) imageProvider})
      : _readLink = readLink,
        _currentViewer = currentViewer,
        _imageProvider = imageProvider;

  final String postId, url;
  final bool active, prepare;
  final int policyRevision;
  final PostMediaGrant? grant;
  final String? commentId;
  final BoxFit fit;
  final Future<String> Function()? _readLink;
  final String? Function()? _currentViewer;
  final ImageProvider Function(String, String)? _imageProvider;
  @override
  State<AuthorizedPostImage> createState() => _AuthorizedPostImageState();
}

class _AuthorizedPostImageState extends State<AuthorizedPostImage> {
  ImageProvider? _provider;
  String? _viewer;
  bool _authorized = false;
  bool _failed = false;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _load(useGrant: true);
  }

  @override
  void didUpdateWidget(covariant AuthorizedPostImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.grant != null && !identical(oldWidget.grant, widget.grant)) {
      _load(useGrant: true);
      return;
    }
    if (oldWidget.postId != widget.postId ||
        oldWidget.url != widget.url ||
        oldWidget.commentId != widget.commentId ||
        oldWidget.policyRevision != widget.policyRevision) {
      _provider = null;
      _load();
    } else if (oldWidget.active != widget.active ||
        oldWidget.prepare != widget.prepare) {
      if (widget.active || (widget.prepare && _provider == null)) {
        _load();
      } else {
        _generation++;
        _authorized = false;
      }
    }
  }

  String? _currentViewer() => widget._currentViewer != null
      ? widget._currentViewer!()
      : FirebaseAuth.instance.currentUser?.uid;
  Future<void> _load({bool useGrant = false}) async {
    final generation = ++_generation;
    final uid = _currentViewer();
    setState(() {
      if (_viewer != uid) _provider = null;
      _viewer = uid;
      _authorized = false;
      _failed = false;
    });
    if (!widget.active && !widget.prepare) return;
    bool current() =>
        mounted &&
        generation == _generation &&
        (widget.active || widget.prepare) &&
        uid == _currentViewer();
    try {
      if (uid == null) throw StateError('Authentication required');
      final String url;
      final bundled =
          useGrant ? widget.grant?.link(uid, widget.postId, widget.url) : null;
      if (bundled != null) {
        url = bundled;
      } else if (widget._readLink != null) {
        url = await widget._readLink!();
      } else if (widget.commentId == null) {
        url = await PostMediaLinks.read(widget.postId, widget.url);
      } else {
        final result =
            await FirebaseFunctions.instanceFor(region: 'europe-west1')
                .httpsCallable('readCommentMediaDownload')
                .call({
          'postId': widget.postId,
          'commentId': widget.commentId,
          'url': widget.url,
        });
        final data = Map<String, dynamic>.from(result.data as Map);
        final signed = data['url'], expiry = data['expiresAt'];
        if (signed is! String ||
            Uri.tryParse(signed)?.scheme != 'https' ||
            expiry is! num ||
            expiry <= DateTime.now().millisecondsSinceEpoch) {
          throw StateError('Invalid comment media authorization');
        }
        url = signed;
      }
      if (!current()) return;
      final cacheKey = authorizedMediaCacheKey(url, uid);
      final provider = widget._imageProvider?.call(url, cacheKey) ??
          ResizeImage(
            CachedNetworkImageProvider(url, cacheKey: cacheKey),
            width: 1080,
          );
      setState(() {
        _provider = provider;
        _authorized = widget.active;
      });
      // The same provider/key/resize is also kept mounted below, so preparation
      // warms exactly the bytes and decoded frame used after fresh activation.
      if (!mounted) return;
      await precacheImage(provider, context, onError: (_, __) {});
    } catch (_) {
      if (current()) setState(() => _failed = true);
    }
  }

  Widget _retry() => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(shellText(context, 'تعذر تحميل الصورة'), style: const TextStyle(color: Colors.white)),
        TextButton(onPressed: _load, child: Text(shellText(context, 'إعادة المحاولة'))),
      ]));
  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sameViewer = _viewer != null && _viewer == _currentViewer();
    final visible = widget.active && _authorized && sameViewer && !_failed;
    return Stack(fit: StackFit.passthrough, children: [
      Offstage(
        offstage: !visible,
        child: sameViewer && _provider != null
            ? Image(
                image: _provider!,
                fit: widget.fit,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const Center(child: CircularProgressIndicator()),
                errorBuilder: (_, __, ___) => _retry(),
              )
            : const SizedBox.shrink(),
      ),
      if (widget.active && !visible)
        _failed ? _retry() : const Center(child: CircularProgressIndicator()),
    ]);
  }
}
