import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'protected_media_service.dart';

@immutable
class ProtectedImageKey {
  const ProtectedImageKey(this.locator, this.scope, this.network, this.cacheKey,
      this.maxWidth, this.maxHeight,
      {this.generation});
  final String locator, scope;
  final NetworkImage network;
  final String? cacheKey;
  final String? generation;
  final int? maxWidth, maxHeight;
  @override
  bool operator ==(Object other) =>
      other is ProtectedImageKey &&
      locator == other.locator &&
      scope == other.scope &&
      generation == other.generation &&
      network.scale == other.network.scale &&
      mapEquals(network.headers, other.network.headers) &&
      cacheKey == other.cacheKey &&
      maxWidth == other.maxWidth &&
      maxHeight == other.maxHeight;
  @override
  int get hashCode => Object.hash(
      locator, scope, generation, network.scale, cacheKey, maxWidth, maxHeight);

  /// No URL, token, account ID or signature is exposed in the persisted key.
  String get diskCacheKey => sha256
      .convert(utf8.encode(jsonEncode([
        'protected-image-v1',
        scope,
        locator,
        generation,
        cacheKey,
        if (network.headers != null)
          [
            for (final name in (network.headers!.keys.toList()..sort()))
              [name, network.headers![name]]
          ],
      ])))
      .toString();
}

/// Authorization is deliberately in obtainKey, before the decoded cache lookup.
class ProtectedNetworkImage extends ImageProvider<ProtectedImageKey> {
  const ProtectedNetworkImage(this.url,
      {this.scale = 1,
      this.headers,
      this.cacheKey,
      this.maxWidth,
      this.maxHeight})
      : _service = null;
  @visibleForTesting
  const ProtectedNetworkImage.testing(this.url,
      {required ProtectedMediaService service,
      this.scale = 1,
      this.headers,
      this.cacheKey,
      this.maxWidth,
      this.maxHeight})
      : _service = service;
  final String url;
  final double scale;
  final Map<String, String>? headers;
  final String? cacheKey;
  final int? maxWidth, maxHeight;
  final ProtectedMediaService? _service;
  ProtectedMediaService get service =>
      _service ?? ProtectedMediaService.instance;

  @override
  Future<ProtectedImageKey> obtainKey(ImageConfiguration configuration) async {
    final grant = await service.resolve(url);
    if (grant.scope != service.scope) throw StateError('Media session changed');
    return ProtectedImageKey(
        url,
        grant.scope,
        NetworkImage(grant.url, scale: scale, headers: headers),
        cacheKey,
        maxWidth,
        maxHeight,
        generation: Uri.parse(grant.url).queryParameters['generation']);
  }

  @override
  ImageStreamCompleter loadImage(
      ProtectedImageKey key, ImageDecoderCallback decode) {
    return key.network.loadImage(
        key.network,
        (buffer, {getTargetSize}) =>
            _decode(key, buffer, decode, getTargetSize: getTargetSize));
  }

  Future<ui.Codec> _decode(ProtectedImageKey key, ui.ImmutableBuffer buffer,
      ImageDecoderCallback decode,
      {ui.TargetImageSizeCallback? getTargetSize}) async {
    if (key.scope != service.scope) {
      buffer.dispose();
      throw StateError('Media session changed');
    }
    final codec = await decode(buffer,
        getTargetSize: getTargetSize ??
            ((maxWidth != null || maxHeight != null)
                ? (width, height) {
                    final ratio = math.min(
                        1.0,
                        math.min(maxWidth == null ? 1.0 : maxWidth! / width,
                            maxHeight == null ? 1.0 : maxHeight! / height));
                    return ui.TargetImageSize(
                        width: math.max(1, (width * ratio).round()),
                        height: math.max(1, (height * ratio).round()));
                  }
                : null));
    if (key.scope != service.scope) {
      codec.dispose();
      throw StateError('Media session changed');
    }
    return codec;
  }
}

class ProtectedCachedNetworkImageProvider extends ProtectedNetworkImage {
  const ProtectedCachedNetworkImageProvider(super.url,
      {super.scale,
      super.headers,
      super.cacheKey,
      super.maxWidth,
      super.maxHeight})
      : _readBytes = null, _cacheManager = null;
  @visibleForTesting
  const ProtectedCachedNetworkImageProvider.testing(String url,
      {required ProtectedMediaService service,
      Future<Uint8List> Function(String url, String key)? readBytes,
      BaseCacheManager? cacheManager,
      double scale = 1,
      Map<String, String>? headers,
      String? cacheKey,
      int? maxWidth,
      int? maxHeight})
      : _readBytes = readBytes,
        _cacheManager = cacheManager,
        super.testing(url,
            service: service,
            scale: scale,
            headers: headers,
            cacheKey: cacheKey,
            maxWidth: maxWidth,
            maxHeight: maxHeight);
  final Future<Uint8List> Function(String, String)? _readBytes;
  final BaseCacheManager? _cacheManager;

  @override
  ImageStreamCompleter loadImage(
          ProtectedImageKey key, ImageDecoderCallback decode) =>
      MultiFrameImageStreamCompleter(
          codec: _loadCached(key, decode), scale: scale);

  Future<ui.Codec> _loadCached(
      ProtectedImageKey key, ImageDecoderCallback decode) async {
    if (key.scope != service.scope) throw StateError('Media session changed');
    // obtainKey has already reauthorized this source, even on a disk cache hit.
    final Uint8List bytes;
    if (_readBytes != null) {
      bytes = await _readBytes(key.network.url, key.diskCacheKey);
    } else {
      final manager = _cacheManager ?? DefaultCacheManager();
      // A fresh grant pins an immutable Storage generation. Its bytes remain
      // valid even when the signed URL/HTTP cache lifetime has expired.
      // Unversioned sources must still obey normal HTTP cache freshness.
      final cached = key.generation?.isNotEmpty == true
          ? await manager.getFileFromCache(key.diskCacheKey)
          : null;
      final file = cached != null && await cached.file.exists()
          ? cached.file
          : await manager.getSingleFile(key.network.url,
              key: key.diskCacheKey, headers: headers ?? const {});
      if (key.scope != service.scope) throw StateError('Media session changed');
      bytes = await file.readAsBytes();
    }
    if (key.scope != service.scope) throw StateError('Media session changed');
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return _decode(key, buffer, decode);
  }
}

/// Fresh authorization precedes both decoded and session-scoped disk cache use.
class ProtectedCachedNetworkImage extends StatelessWidget {
  const ProtectedCachedNetworkImage(
      {super.key,
      required this.imageUrl,
      this.width,
      this.height,
      this.fit,
      this.cacheKey,
      this.memCacheWidth,
      this.memCacheHeight,
      this.httpHeaders,
      this.placeholder,
      this.errorWidget,
      this.alignment = Alignment.center,
      this.color,
      this.colorBlendMode,
      this.filterQuality = FilterQuality.low});
  final String imageUrl;
  final double? width, height;
  final BoxFit? fit;
  final String? cacheKey;
  final int? memCacheWidth, memCacheHeight;
  final Map<String, String>? httpHeaders;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, Object)? errorWidget;
  final AlignmentGeometry alignment;
  final Color? color;
  final BlendMode? colorBlendMode;
  final FilterQuality filterQuality;
  @override
  Widget build(BuildContext context) => Image(
        image: ProtectedCachedNetworkImageProvider(imageUrl,
            headers: httpHeaders,
            cacheKey: cacheKey,
            maxWidth: memCacheWidth,
            maxHeight: memCacheHeight),
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        color: color,
        colorBlendMode: colorBlendMode,
        filterQuality: filterQuality,
        frameBuilder: placeholder == null
            ? null
            : (context, child, frame, synchronous) =>
                synchronous || frame != null
                    ? child
                    : placeholder!(context, imageUrl),
        errorBuilder: (context, error, stack) =>
            errorWidget?.call(context, imageUrl, error) ??
            const Icon(Icons.broken_image_outlined),
      );
}

/// Drop-in network factory routing Image.network through authorization.
abstract final class ProtectedImage {
  static Image network(
    String src, {
    Key? key,
    double scale = 1.0,
    Map<String, String>? headers,
    ImageFrameBuilder? frameBuilder,
    ImageLoadingBuilder? loadingBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = false,
    bool isAntiAlias = false,
    FilterQuality filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
  }) =>
      Image(
        key: key,
        image: ProtectedNetworkImage(src,
            scale: scale,
            headers: headers,
            maxWidth: cacheWidth,
            maxHeight: cacheHeight),
        frameBuilder: frameBuilder,
        loadingBuilder: loadingBuilder,
        errorBuilder: errorBuilder,
        semanticLabel: semanticLabel,
        excludeFromSemantics: excludeFromSemantics,
        width: width,
        height: height,
        color: color,
        opacity: opacity,
        colorBlendMode: colorBlendMode,
        fit: fit,
        alignment: alignment,
        repeat: repeat,
        centerSlice: centerSlice,
        matchTextDirection: matchTextDirection,
        gaplessPlayback: gaplessPlayback,
        isAntiAlias: isAntiAlias,
        filterQuality: filterQuality,
      );
}
