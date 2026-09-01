import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'skeleton.dart';

class LazyImage extends StatefulWidget {
  final String url;
  final double? height;
  final BoxFit fit;
  final VoidCallback? onTap;

  const LazyImage({
    super.key,
    required this.url,
    this.height,
    this.fit = BoxFit.cover,
    this.onTap,
  });

  @override
  State<LazyImage> createState() => _LazyImageState();
}

class _LazyImageState extends State<LazyImage> with AutomaticKeepAliveClientMixin {
  bool _isVisible = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return VisibilityDetector(
      key: Key(widget.url),
      onVisibilityChanged: (info) {
        final visible = info.visibleFraction > 0.2;
        if (visible != _isVisible) {
          setState(() => _isVisible = visible);
        }
      },
      child: _isVisible
          ? GestureDetector(
        onTap: widget.onTap,
        child: CachedNetworkImage(
          imageUrl: widget.url,
          height: widget.height,
          fit: widget.fit,
          placeholder: (_, __) => Skeleton(height: widget.height ?? 200),
          errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
          memCacheWidth: 600,
          memCacheHeight: 600,
        ),
      )
          : SizedBox(height: widget.height ?? 200, child: const Skeleton()),
    );
  }
}