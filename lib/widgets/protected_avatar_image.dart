import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../services/protected_media_service.dart';
import '../services/protected_network_image.dart';

/// Retains the resolved image across parent rebuilds, with bounded revalidation.
class ProtectedAvatarImage extends StatefulWidget {
  const ProtectedAvatarImage({super.key, required this.url, required this.size,
    required this.placeholder, this.revalidate = true});
  final bool revalidate;
  final String url;
  final double size;
  final Widget placeholder;
  @override
  State<ProtectedAvatarImage> createState() => _ProtectedAvatarImageState();
}
class _ProtectedAvatarImageState extends State<ProtectedAvatarImage> with WidgetsBindingObserver {
  bool? _visible;
  ImageProvider? _provider;
  (String, String, int)? _identity;
  Timer? _refresh;
  StreamSubscription<User?>? _auth;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh = Timer.periodic(const Duration(seconds: 30), (_) {
      if (widget.revalidate && mounted && TickerMode.of(context) &&
          ModalRoute.of(context)?.isCurrent != false &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) _invalidate();
    });
    if (Firebase.apps.isNotEmpty) {
      _auth = FirebaseAuth.instance.authStateChanges().listen((_) => _invalidate());
    }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.revalidate && state == AppLifecycleState.resumed) _invalidate();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.of(context) && ModalRoute.of(context)?.isCurrent != false;
    if (_visible == false && visible && widget.revalidate) _provider = null;
    _visible = visible;
  }
  void _invalidate() {
    if (mounted) setState(() => _provider = null);
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refresh?.cancel();
    _auth?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final scope = ProtectedMediaService.instance.scope;
    final size = (widget.size * MediaQuery.devicePixelRatioOf(context)).ceil();
    final identity = (widget.url, scope, size);
    if (_identity != identity || _provider == null) {
      _identity = identity;
      _provider = ProtectedCachedNetworkImageProvider(widget.url,
        maxWidth: size, maxHeight: size);
    }
    return Image(key: ValueKey(identity), image: _provider!, fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => widget.placeholder);
  }
}
