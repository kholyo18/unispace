part of '../../main.dart';

class _AutoSizeImage extends StatefulWidget {
  const _AutoSizeImage({
    required this.path,
    required this.isNetwork,
    this.maxHeight = 480,
    this.onTap,
    this.postId,
  });

  final String path;
  final String? postId;
  final bool isNetwork;
  final double maxHeight;
  final VoidCallback? onTap;

  @override
  State<_AutoSizeImage> createState() => _AutoSizeImageState();
}

class _AutoSizeImageState extends State<_AutoSizeImage> with WidgetsBindingObserver {
  String? _signedPath;
  bool _failed = false, _foreground = true;
  int _generation = 0;
  StreamSubscription<User?>? _auth;
  String? _viewer;
  bool get _protected => widget.postId != null;
  void _detachImage() {
    if (_stream != null && _listener != null) _stream!.removeListener(_listener!);
    _stream = null;
    _listener = null;
  }
  Future<void> _reload() async {
    if (!mounted) return;
    final generation = ++_generation;
    _detachImage();
    setState(() { _signedPath = null; _aspectRatio = null; _failed = false; });
    if (!_protected) { _resolveDimensions(); return; }
    if (!_foreground) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    try {
      if (uid == null) throw StateError('Authentication required');
      final url = await PostMediaLinks.read(widget.postId!, widget.path);
      if (!mounted || generation != _generation || uid != FirebaseAuth.instance.currentUser?.uid) return;
      _signedPath = url;
      _resolveDimensions();
    } catch (_) {
      if (mounted && generation == _generation) setState(() => _failed = true);
    }
  }
  void _invalidate() { if (_protected) _reload(); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _invalidate();
  }
  @override
  void didUpdateWidget(covariant _AutoSizeImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path || oldWidget.postId != widget.postId ||
        oldWidget.isNetwork != widget.isNetwork) _reload();
  }
  double? _aspectRatio;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void initState() {
    super.initState();
    _viewer = FirebaseAuth.instance.currentUser?.uid;
    WidgetsBinding.instance.addObserver(this);
    blockedListRevision.addListener(_invalidate);
    moderationRevision.addListener(_invalidate);
    authorProfileRevision.addListener(_invalidate);
    _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user?.uid != _viewer) { _viewer = user?.uid; _invalidate(); }
    });
    _reload();
  }

  String? get _imageCacheKey => _protected && _signedPath != null
      ? authorizedMediaCacheKey(_signedPath!, _viewer ?? '')
      : null;

  ImageProvider get _provider {
    if (widget.isNetwork) return ResizeImage.resizeIfNeeded(
          900,
          null,
          ProtectedCachedNetworkImageProvider(_protected ? _signedPath! : widget.path,
              cacheKey: _imageCacheKey));
    if (widget.path.startsWith('assets/')) return AssetImage(widget.path);
    return FileImage(File(widget.path));
  }

  void _resolveDimensions() {
    final generation = _generation;
    final stream = _provider.resolve(const ImageConfiguration());
    final listener = ImageStreamListener((info, _) {
      if (!mounted || generation != _generation) return;
      final w = info.image.width.toDouble();
      final h = info.image.height.toDouble();
      if (h > 0) {
        setState(() => _aspectRatio = w / h);
      }
    }, onError: (error, stack) {
      if (_protected && mounted && generation == _generation) setState(() => _failed = true);
    });
    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  @override
  void dispose() {
    _generation++;
    _auth?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    blockedListRevision.removeListener(_invalidate);
    moderationRevision.removeListener(_invalidate);
    authorProfileRevision.removeListener(_invalidate);
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    super.dispose();
  }

  Widget _buildImage(BoxFit fit) {
    if (widget.isNetwork) {
      // FIX: CachedNetworkImage بدل Image.network — كتحفظ الصورة فالقرص،
      // فالمرة الثانية (بعد الرجوع/إعادة البناء) كتبان فورية بلا تحميل جديد
      return ProtectedCachedNetworkImage(
        imageUrl: _protected ? _signedPath! : widget.path,
        cacheKey: _imageCacheKey,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        memCacheWidth: 900, // NEW: كيصغر الصورة فالذاكرة، كيسرع الرسم ويوفر RAM
        errorWidget: (_, __, ___) => _errorBox(),
      );
    }
    if (widget.path.startsWith('assets/')) {
      return Image.asset(widget.path, fit: fit, width: double.infinity, height: double.infinity);
    }
    final file = File(widget.path);
    if (!file.existsSync()) return _errorBox();
    return Image.file(file, fit: fit, width: double.infinity, height: double.infinity);
  }

  Widget _errorBox() {
    if (_protected) return SizedBox(height: 180, child: Center(child: Column(
      mainAxisSize: MainAxisSize.min, children: [
         Text(mainText(context, "تعذر تحميل الصورة")),
        TextButton(onPressed: _reload, child:  Text(mainText(context, "إعادة المحاولة"))),
      ],
    )));
    return Container(
      color: UniSpaceColors.ivory,
      height: 180,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_rounded, size: 38, color: UniSpaceColors.lightMuted),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_protected && !_foreground) return const SizedBox(height: 220);
    if (_failed) return _errorBox();
    if (_aspectRatio == null) {
      // NEW: أثناء انتظار القياس، ارتفاع معقول ثابت
      content = const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    } else {
      // NEW: LayoutBuilder باش ناخدو العرض الحقيقي المتاح، ونحسبو الارتفاع يدويًا
      content = LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final naturalHeight = width / _aspectRatio!;
          // FIX: العرض دايمًا كامل — الارتفاع فقط هو اللي كيتحدد بحد أقصى
          final displayHeight =
          naturalHeight > widget.maxHeight ? widget.maxHeight : naturalHeight;
          // NEW: إذا الارتفاع الطبيعي أكبر من الحد الأقصى، نقصو (cover) بدل نصغرو العرض
          final fit = naturalHeight > widget.maxHeight
              ? BoxFit.cover
              : BoxFit.contain;

          return SizedBox(
            width: width,
            height: displayHeight,
            child: _buildImage(fit),
          );
        },
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: content,
      ),
    );
  }
}

