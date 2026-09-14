import 'package:cloud_functions/cloud_functions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'post_media_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Used inside the authorized pager, whose lifecycle clears access on resume,
/// account changes and local privacy/block/moderation revisions.
class AuthorizedPostImage extends StatefulWidget {
  const AuthorizedPostImage({super.key, required this.postId, required this.url,
    required this.active, this.commentId, this.fit = BoxFit.contain});
  final String postId, url;
  final bool active;
  final String? commentId;
  final BoxFit fit;
  @override
  State<AuthorizedPostImage> createState() => _AuthorizedPostImageState();
}

class _AuthorizedPostImageState extends State<AuthorizedPostImage> {
  String? _signed;
  bool _failed = false;
  int _generation = 0;
  @override
  void initState() { super.initState(); _load(); }
  @override
  void didUpdateWidget(covariant AuthorizedPostImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.postId != widget.postId || oldWidget.url != widget.url ||
        oldWidget.active != widget.active || oldWidget.commentId != widget.commentId) _load();
  }
  Future<void> _load() async {
    final generation = ++_generation;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    setState(() { _signed = null; _failed = false; });
    if (!widget.active) return;
    bool current() => mounted && generation == _generation && widget.active &&
        uid == FirebaseAuth.instance.currentUser?.uid;
    try {
      if (uid == null) throw StateError('Authentication required');
      final String url;
      if (widget.commentId == null) {
        url = await PostMediaLinks.read(widget.postId, widget.url);
      } else {
        final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
            .httpsCallable('readCommentMediaDownload').call({
              'postId': widget.postId, 'commentId': widget.commentId, 'url': widget.url,
            });
        final data = Map<String, dynamic>.from(result.data as Map);
        final signed = data['url'], expiry = data['expiresAt'];
        if (signed is! String || Uri.tryParse(signed)?.scheme != 'https' ||
            expiry is! num || expiry <= DateTime.now().millisecondsSinceEpoch) {
          throw StateError('Invalid comment media authorization');
        }
        url = signed;
      }
      if (!current()) return;
      setState(() => _signed = url);
    } catch (_) {
      if (current()) setState(() => _failed = true);
    }
  }
  Widget _retry() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Text('تعذر تحميل الصورة', style: TextStyle(color: Colors.white)),
    TextButton(onPressed: _load, child: const Text('إعادة المحاولة')),
  ]));
  @override
  void dispose() { _generation++; super.dispose(); }
  @override
  Widget build(BuildContext context) {
    if (!widget.active) return const SizedBox.shrink();
    if (_failed) return _retry();
    if (_signed == null) return const Center(child: CircularProgressIndicator());
    return CachedNetworkImage(
      key: ValueKey(_generation), imageUrl: _signed!, fit: widget.fit,
      placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
      errorWidget: (_, __, ___) => _retry(),
    );
  }
}
