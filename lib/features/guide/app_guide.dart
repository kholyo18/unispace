import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'guide_strings.dart';

class GuideStep {
  const GuideStep(this.target, this.copy);
  final String target;
  final String copy;
}

/// Page-local walkthrough. Never activates the highlighted control itself.
class AppGuide extends StatefulWidget {
  const AppGuide(
      {super.key,
      required this.id,
      required this.steps,
      required this.child,
      this.autoStart = true});
  final String id;
  final List<GuideStep> steps;
  final Widget child;
  final bool autoStart;
  @override
  State<AppGuide> createState() => _AppGuideState();
}

class _AppGuideState extends State<AppGuide> {
  final _surface = GlobalKey();
  final _targets = <String, GlobalKey>{};
  bool _active = false;
  bool _started = false;
  bool _shown = false;
  int _index = 0;
  int _generation = 0;
  Rect? _rect;
  (Size, EdgeInsets, EdgeInsets)? _lastMetrics;

  String get _preference => 'app_guide_v1_${widget.id}';
  GlobalKey keyFor(String id) => _targets.putIfAbsent(id, GlobalKey.new);

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoStart());
    }
  }

  Future<void> _autoStart() async {
    bool seen = false;
    try {
      seen =
          (await SharedPreferences.getInstance()).getBool(_preference) ?? false;
    } catch (_) {/* A preferences failure must not block the application. */}
    if (!mounted ||
        seen ||
        _started ||
        ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    start();
  }

  void start() {
    if (!mounted || _active || widget.steps.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _started = true;
    _shown = false;
    setState(() {
      _active = true;
      _rect = null;
    });
    unawaited(_show(0));
  }

  Future<void> _show(int index, {int direction = 1}) async {
    final generation = ++_generation;
    // Wait until targets are laid out, including after keyboard dismissal.
    await WidgetsBinding.instance.endOfFrame;
    while (mounted &&
        _active &&
        generation == _generation &&
        index >= 0 &&
        index < widget.steps.length) {
      final target = _targets[widget.steps[index].target]?.currentContext;
      if (target != null && target.mounted) {
        await Scrollable.ensureVisible(target,
            duration: const Duration(milliseconds: 180), alignment: .5);
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted || !_active || generation != _generation) return;
        if (!target.mounted) {
          index += direction;
          continue;
        }
        final box = target.findRenderObject();
        final surface = _surface.currentContext?.findRenderObject();
        if (box is RenderBox &&
            box.attached &&
            box.hasSize &&
            surface is RenderBox &&
            surface.hasSize) {
          final bounds =
              (box.localToGlobal(Offset.zero, ancestor: surface) & box.size)
                  .inflate(5)
                  .intersect(Offset.zero & surface.size);
          if (!bounds.isEmpty) {
            setState(() {
              _index = index;
              _rect = bounds;
              _shown = true;
            });
            return;
          }
        }
      }
      // Optional/conditional controls may not exist on this page state.
      index += direction;
    }
    if (mounted && generation == _generation && direction > 0) _finish();
  }

  void _finish() {
    if (!mounted) return;
    _generation++;
    final remember = _shown;
    setState(() {
      _active = false;
      _rect = null;
    });
    if (remember) unawaited(_remember());
  }

  Future<void> _remember() async {
    try {
      await (await SharedPreferences.getInstance()).setBool(_preference, true);
    } catch (_) {/* Replay remains available even when persistence fails. */}
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final metrics = (media.size, media.padding, media.viewInsets);
    if (_lastMetrics != metrics) {
      _lastMetrics = metrics;
      if (_active) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _active) unawaited(_show(_index));
        });
      }
    }
    return _GuideScope(
        state: this,
        child: PopScope(
          canPop: !_active,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && _active) _finish();
          },
          child: Stack(key: _surface, fit: StackFit.expand, children: [
            ExcludeFocus(
                excluding: _active,
                child:
                    ExcludeSemantics(excluding: _active, child: widget.child)),
            if (_active) ...[
              const Positioned.fill(
                  child: ModalBarrier(
                      dismissible: false, color: Colors.transparent)),
              Positioned.fill(
                  child: IgnorePointer(
                      child: CustomPaint(
                painter: GuideScrimPainter(_rect),
              ))),
              if (_rect != null) _card(context, _rect!),
            ],
          ]),
        ));
  }

  Widget _card(BuildContext context, Rect rect) {
    final box = _surface.currentContext!.findRenderObject() as RenderBox;
    final media = MediaQuery.of(context);
    final safeTop = media.padding.top + 12;
    final safeBottom =
        math.max(media.padding.bottom, media.viewInsets.bottom) + 12;
    final above = math.max(0.0, rect.top - safeTop - 12);
    final below =
        math.max(0.0, box.size.height - safeBottom - rect.bottom - 12);
    final placeBelow = below >= above;
    final maxHeight = math.max(1.0, placeBelow ? below : above);
    final copy = guideCopy(context, widget.steps[_index].copy);
    return Positioned(
      left: 16,
      right: 16,
      top: placeBelow ? rect.bottom + 12 : null,
      bottom: placeBelow ? null : box.size.height - rect.top + 12,
      child: Semantics(
          container: true,
          liveRegion: true,
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).colorScheme.surface,
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Directionality(
                  textDirection:
                      Localizations.localeOf(context).languageCode == 'ar'
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${_index + 1} / ${widget.steps.length}',
                            style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 6),
                        Text(copy.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(copy.body,
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        Wrap(spacing: 8, runSpacing: 4, children: [
                          TextButton(
                              onPressed: _finish,
                              child: Text(guideLabel(context, 'skip'))),
                          if (_index > 0)
                            TextButton(
                                onPressed: () =>
                                    unawaited(_show(_index - 1, direction: -1)),
                                child: Text(guideLabel(context, 'back'))),
                          FilledButton(
                              autofocus: true,
                              onPressed: () => _index + 1 == widget.steps.length
                                  ? _finish()
                                  : unawaited(_show(_index + 1)),
                              child: Text(guideLabel(
                                  context,
                                  _index + 1 == widget.steps.length
                                      ? 'done'
                                      : 'next'))),
                        ]),
                      ]),
                ),
              ),
            ),
          )),
    );
  }
}

class _GuideScope extends InheritedWidget {
  const _GuideScope({required this.state, required super.child});
  final _AppGuideState state;
  @override
  bool updateShouldNotify(_GuideScope oldWidget) => state != oldWidget.state;
}

class GuideTarget extends StatelessWidget {
  const GuideTarget({super.key, required this.id, required this.child});
  final String id;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final state =
        context.dependOnInheritedWidgetOfExactType<_GuideScope>()?.state;
    return state == null
        ? child
        : KeyedSubtree(key: state.keyFor(id), child: child);
  }
}

class GuideHelpButton extends StatelessWidget {
  const GuideHelpButton({super.key});
  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: guideLabel(context, 'help'),
        icon: const Icon(Icons.help_outline_rounded),
        onPressed: context
            .dependOnInheritedWidgetOfExactType<_GuideScope>()
            ?.state
            .start,
      );
}

/// The cutout stays transparent; the modal barrier still blocks accidental taps.
class GuideScrimPainter extends CustomPainter {
  const GuideScrimPainter(this.target);
  final Rect? target;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    if (target != null) {
      path.addRRect(
          RRect.fromRectAndRadius(target!, const Radius.circular(12)));
    }
    canvas.drawPath(path, Paint()..color = const Color(0xB3000000));
    if (target != null) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(target!, const Radius.circular(12)),
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(GuideScrimPainter oldDelegate) =>
      target != oldDelegate.target;
}
