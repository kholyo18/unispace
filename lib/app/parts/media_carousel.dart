part of '../../main.dart';

class _MediaCarousel extends StatefulWidget {
  const _MediaCarousel({
    required this.slides,
    this.autoHeightFlags, // NEW: true = ارتفاع مرن (صورة/فيديو خارج البول)، false/null = ثابت 250
  });

  final List<Widget> slides;
  final List<bool>? autoHeightFlags;

  static const double _fixedHeight = 250;

  @override
  State<_MediaCarousel> createState() => _MediaCarouselState();
}

class _MediaCarouselState extends State<_MediaCarousel> {
  int _current = 0;
  late final PageController _ctrl;

  // NEW: نخزّن الارتفاع المقاس لكل شريحة auto-height بعد قياسها فعليًا
  final Map<int, double> _measuredHeights = {};

  @override
  void initState() {
    super.initState();
    _ctrl = PageController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool _isAutoHeight(int index) {
    if (widget.autoHeightFlags == null) return false;
    if (index >= widget.autoHeightFlags!.length) return false;
    return widget.autoHeightFlags![index];
  }

  void _reportHeight(int index, double height) {
    if (_measuredHeights[index] == height) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _measuredHeights[index] = height);
    });
  }

  double get _currentHeight {
    if (!_isAutoHeight(_current)) return _MediaCarousel._fixedHeight;
    // NEW: أثناء انتظار القياس الأول، نبدأ بنفس الارتفاع الثابت لتفادي "قفزة" كبيرة
    return _measuredHeights[_current] ?? _MediaCarousel._fixedHeight;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: _currentHeight,
          child: PageView.builder(
            controller: _ctrl,
            allowImplicitScrolling: true,
            itemCount: widget.slides.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) {
              final child = Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: widget.slides[i],
              );

              if (!_isAutoHeight(i)) {
                // FIX: بحالها كيف قبل — ارتفاع ثابت 250
                return child;
              }

              // NEW: نلف الشريحة بودجة قياس باش ناخدو ارتفاعها الطبيعي
              return _MeasuredSlide(
                onHeightMeasured: (h) => _reportHeight(i, h),
                child: child,
              );
            },
          ),
        ),
        if (widget.slides.length > 1) ...[
          const SizedBox(height: 8),
           // يجبر الصف على أخذ كامل العرض
             Center(
              child: _SlideDotsIndicator(
                count: widget.slides.length,
                currentIndex: _current,
                maxWidth: 200,
              ),
            ),

        ],
      ],
    );
  }
}

class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({required this.onChange, required Widget child})
      : super(child: child);

  final ValueChanged<Size> onChange;

  @override
  _MeasureSizeRenderObject createRenderObject(BuildContext context) {
    return _MeasureSizeRenderObject(onChange);
  }

  @override
  void updateRenderObject(
      BuildContext context, _MeasureSizeRenderObject renderObject) {
    renderObject.onChange = onChange;
  }
}

class _MeasureSizeRenderObject extends RenderProxyBox {
  _MeasureSizeRenderObject(this.onChange);

  ValueChanged<Size> onChange;
  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child?.size;
    if (newSize != null && newSize != _oldSize) {
      _oldSize = newSize;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onChange(newSize);
      });
    }
  }
}

class _MeasuredSlide extends StatelessWidget {
  const _MeasuredSlide({required this.child, required this.onHeightMeasured});

  final Widget child;
  final ValueChanged<double> onHeightMeasured;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: _MeasureSize(
        onChange: (size) => onHeightMeasured(size.height),
        child: child,
      ),
    );
  }
}

// NEW: فيديو خارج البول — بعرض كامل، الارتفاع محسوب من النسبة الحقيقية
// ديال الفيديو (بحال الصور)، بدل ارتفاع ثابت مقصوص.
