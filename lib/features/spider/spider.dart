import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import '../../core/branding.dart';

enum SpiderSfx {
  weavePluck,   // نقرة نسج الشبكة
  webPluck,     // نتف الشبكة
  catchPrey,    // الإمساك بحشرة
  flee,         // الفزع
  tickleGiggle, // الدغدغة
  powerOn,      // نقرة تشغيل
  powerOff,     // نقرة إطفاء
  callName,     // النداء بالاسم
}

// ═════════════════════════════════════════════════════════════════
// المشهد الرئيسي (تجريبي — يعرض كل الميزات)
// ═════════════════════════════════════════════════════════════════

class _EmptyNotificationsScene extends StatefulWidget {
  const _EmptyNotificationsScene();

  @override
  State<_EmptyNotificationsScene> createState() =>
      _EmptyNotificationsSceneState();
}

class _EmptyNotificationsSceneState extends State<_EmptyNotificationsScene> {
  bool _screenOn = true;

  final ValueNotifier<Offset?> _pointer = ValueNotifier<Offset?>(null);
  final GlobalKey<_EmptyStateSpiderState> _spiderKey =
  GlobalKey<_EmptyStateSpiderState>();
  final GlobalKey<CrtScreenState> _crtKey = GlobalKey<CrtScreenState>();

  void _sfx(SpiderSfx s) {
    // TODO: اربطي أصواتك هنا (audioplayers / assets).
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: CrtScreen(
        key: _crtKey,
        on: _screenOn,
        screenHeight: 210,
        pointerBus: _pointer,
        onSfx: _sfx,
        onPowerToggle: () => setState(() => _screenOn = !_screenOn),
        child: EmptyStateSpider(

          key: _spiderKey,
          height: 210,
          accent: AppTeal.main,
          backgroundLabel: 'Nothing to show...',
          spiderName: 'عنكبوتي',
          pointerBus: _pointer,
          onSfx: _sfx,
          screenOn: _screenOn,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// الشاشة: CRT + دورة الطاقة + الإيقاظ بالإشعار + لمس الزجاج المظلم
// ═════════════════════════════════════════════════════════════════

enum CrtPowerStage { on, flickerOff, collapse, dark, reveal, flickerOn }

class CrtScreen extends StatefulWidget {
  final bool on;
  final double screenHeight;
  final Widget child;
  final ValueNotifier<Offset?>? pointerBus;
  final ValueChanged<SpiderSfx>? onSfx;
  final VoidCallback? onPowerToggle;

  const CrtScreen({
    super.key,
    required this.on,
    required this.screenHeight,
    required this.child,
    this.pointerBus,
    this.onSfx,
    this.onPowerToggle,
  });

  @override
  State<CrtScreen> createState() => CrtScreenState();
}

class CrtScreenState extends State<CrtScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _t = 0;
  CrtPowerStage _stage = CrtPowerStage.on;
  final ValueNotifier<int> _repaint = ValueNotifier<int>(0);
  final Random _rng = Random(7);

  double _flickerNoise = 1.0;
  double _nextFlickerStep = 0;

  /// وقت (بثوانٍ داخل مرحلة reveal) آخر لمسة على الزجاج المظلم.
  double _glassTouchAt = -999;

  static const _stageDurations = {
    CrtPowerStage.on: double.infinity,
    CrtPowerStage.flickerOff: 0.95,
    CrtPowerStage.collapse: 0.5,
    CrtPowerStage.dark: 1.0,
    CrtPowerStage.reveal: double.infinity,
    CrtPowerStage.flickerOn: 0.75,
  };

  @override
  void initState() {
    super.initState();
    _stage = widget.on ? CrtPowerStage.on : CrtPowerStage.reveal;
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didUpdateWidget(CrtScreen old) {
    super.didUpdateWidget(old);
    if (old.on != widget.on) {
      _t = 0;
      _stage =
      widget.on ? CrtPowerStage.flickerOn : CrtPowerStage.flickerOff;
    }
  }

  void _onTick(Duration elapsed) {
    _t += 1 / 60;
    _nextFlickerStep -= 1 / 60;
    if (_nextFlickerStep <= 0) {
      _nextFlickerStep = 0.03 + _rng.nextDouble() * 0.06;
      _flickerNoise = 0.55 + _rng.nextDouble() * 0.45;
    }
    final d = _stageDurations[_stage]!;
    if (_t >= d) {
      switch (_stage) {
        case CrtPowerStage.flickerOff:
          _stage = CrtPowerStage.collapse;
          break;
        case CrtPowerStage.collapse:
          _stage = CrtPowerStage.dark;
          break;
        case CrtPowerStage.dark:
          _stage = CrtPowerStage.reveal;
          break;
        case CrtPowerStage.flickerOn:
          _stage = CrtPowerStage.on;
          break;
        case CrtPowerStage.on:
        case CrtPowerStage.reveal:
          break;
      }
      _t = 0;
    }
    _repaint.value++;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  /// ═════════════════════════════════════════════════════════════
  /// واجهة عامة: أيقظ الشاشة من الظلام عند وصول إشعار.
  /// الشاشة ترتج وتشتغل، ثم تعود reveal لو بقيت مطفأة منطقيًا.
  /// ═════════════════════════════════════════════════════════════
  void powerOn({bool notify = true}) {
    if (_stage == CrtPowerStage.on) return;
    _t = 0;
    _stage = CrtPowerStage.flickerOn;
    if (notify) widget.onSfx?.call(SpiderSfx.powerOn);
    HapticFeedback.selectionClick();
  }

  void powerOff({bool notify = true}) {
    if (_stage != CrtPowerStage.on) return;
    _t = 0;
    _stage = CrtPowerStage.flickerOff;
    if (notify) widget.onSfx?.call(SpiderSfx.powerOff);
  }

  double get _sceneOpacity {
    switch (_stage) {
      case CrtPowerStage.on:
        return 1;
      case CrtPowerStage.flickerOff:
        final decay = (1 - _t / _stageDurations[_stage]!).clamp(0.0, 1.0);
        return (decay * _flickerNoise).clamp(0.0, 1.0);
      case CrtPowerStage.collapse:
      case CrtPowerStage.dark:
      case CrtPowerStage.reveal:
        return 0;
      case CrtPowerStage.flickerOn:
        return (_t / _stageDurations[_stage]!).clamp(0.0, 1.0) * _flickerNoise;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: widget.screenHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0xFF171310),
              border: Border.all(color: const Color(0xFF0A0806), width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Listener(
                // التقاط لمس الزجاج في الظلام (يمر عبر أسلاف الـ Stack).
                onPointerDown: (_) {
                  if (_stage == CrtPowerStage.reveal) {
                    _glassTouchAt = _t;
                    HapticFeedback.mediumImpact();
                  }
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 60),
                      opacity: _sceneOpacity,
                      child: widget.child,
                    ),
                    if (_stage == CrtPowerStage.reveal ||
                        _stage == CrtPowerStage.dark)
                      IgnorePointer(
                        child: CustomPaint(
                          painter: _DarkRevealPainter(
                            t: _stage == CrtPowerStage.dark ? 0.0 : _t,
                            gaze: widget.pointerBus?.value,
                            touchT: _glassTouchAt,
                            repaint: _repaint,
                          ),
                        ),
                      ),
                    IgnorePointer(
                      child: CustomPaint(
                        painter: _CrtOverlayPainter(
                          stage: _stage,
                          stageT: _t,
                          flickerNoise: _flickerNoise,
                          repaint: _repaint,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: _PowerButton(
                        on: widget.on,
                        onTap: widget.onPowerToggle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PowerButton extends StatelessWidget {
  final bool on;
  final VoidCallback? onTap;
  const _PowerButton({required this.on, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: on ? 'إطفاء شاشة التلفاز' : 'تشغيل شاشة التلفاز',
      child: Tooltip(
        message: on ? 'إطفاء الشاشة' : 'تشغيل الشاشة',
        child: IconButton(
          onPressed: onTap,
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            backgroundColor: Colors.black.withValues(alpha: 0.35),
            foregroundColor: on ? const Color(0xFFFFDFA0) : Colors.white70,
          ),
          icon: Icon(
            on ? Icons.power_settings_new_rounded : Icons.tv_rounded,
            size: 18,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// مشهد العنكبوت التفاعلي
// ═════════════════════════════════════════════════════════════════

class EmptyStateSpider extends StatefulWidget {
  final double height;
  final Color accent;
  final String? message;
  final String? backgroundLabel;
  final int? seed;
  final bool screenOn;

  /// اسم العنكبوت — عند النداء بالاسم (callByName) يلتفت ويلوّح.
  final String? spiderName;

  final ValueNotifier<Offset?>? pointerBus;
  final ValueChanged<SpiderSfx>? onSfx;

  const EmptyStateSpider({
    super.key,
    this.height = 160,
    required this.accent,
    this.message,
    this.seed,
    this.backgroundLabel,
    this.screenOn = true,
    this.spiderName,
    this.pointerBus,
    this.onSfx,
  });

  @override
  State<EmptyStateSpider> createState() => _EmptyStateSpiderState();
}

class _EmptyStateSpiderState extends State<EmptyStateSpider>
    with SingleTickerProviderStateMixin {
  late final SpiderEngine _engine = SpiderEngine(
    seed: widget.seed,
    name: widget.spiderName,
  )..onSfx = widget.onSfx;
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  final ValueNotifier<int> _repaint = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    _engine.update(dt);
    _repaint.value++;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  // ── الواجهة العامة ──

  /// إشعار جديد = حشرة طائرة وامضة يصطادها العنكبوت.
  void spawnNotificationPrey({Color? glow}) =>
      _engine.injectNotificationPrey(glow: glow);

  /// إطعام يدوي — نفس الحشرة لكن العنكبوت يقرر حسب مزاجه.
  void feedManually({Color? glow}) =>
      _engine.injectNotificationPrey(glow: glow, force: true);

  /// النداء بالاسم: يلتفت نحو المشاهد ويلوّح بفرح.
  void callByName() => _engine.callByName();

  /// وضع التصوير: يتجمد وينظر للعداء ويبتسم.
  void poseForPhoto() => _engine.poseForPhoto();

  /// اهتزاز الجهاز (اربطها بـ sensors_plus AccelerometerEvent).
  void onDeviceShake() => _engine.onDeviceShake();

  /// عدد الفرائس المخزنة = شارة الإشعارات غير المقروءة.
  int get storedPreyCount => _engine.pantry.length;

  /// المزاج الحالي 0..1 (يمكن عرضه كسعادة الشخصية).
  double get mood => _engine.mood;

  SpiderPalette _palette(BuildContext context) {
    return  SpiderPalette(
      body: Color(0xFFE8863A),
      bodyLight: Color(0xFFF6B06A),
      bodyDark: Color(0xFFB05E1F),
      accent: AppTeal.main,
      eyeWhite: Color(0xFFFDF8EF),
      pupil: Color(0xFF1B1410),
      silk: Color(0xFFEBDDBF),
      shadow: Color(0xFF2A1608),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _palette(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 162,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.backgroundLabel != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Text(
                        widget.backgroundLabel!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color:
                          const Color(0xFFF2C98A).withValues(alpha: 0.10),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              LayoutBuilder(builder: (context, constraints) {
                final size =
                Size(constraints.maxWidth, constraints.maxHeight);
                _engine.resize(size);
                return SpiderGestureLayer(
                  engine: _engine,
                  pointerBus: widget.pointerBus,
                  child: CustomPaint(
                    size: size,
                    painter: SpiderPainter(
                      e: _engine,
                      palette: palette,
                      repaint: _repaint,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.message!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// طبقة الإيماءات (+ Haptics)
// ═════════════════════════════════════════════════════════════════

class SpiderGestureLayer extends StatefulWidget {
  final SpiderEngine engine;
  final Widget child;
  final ValueNotifier<Offset?>? pointerBus;

  const SpiderGestureLayer({
    super.key,
    required this.engine,
    required this.child,
    this.pointerBus,
  });

  @override
  State<SpiderGestureLayer> createState() => _SpiderGestureLayerState();
}

class _SpiderGestureLayerState extends State<SpiderGestureLayer> {
  Offset? _downPos;
  bool _grabArmed = false;
  bool _isDragging = false;

  static const double _grabSlop = 8;

  void _publish(Offset? p) => widget.pointerBus?.value = p;

  void _handleDown(PointerDownEvent e) {
    _downPos = e.localPosition;
    _isDragging = false;
    _grabArmed = widget.engine.canGrabAt(e.localPosition);
    if (_grabArmed) {
      widget.engine.armGrab(e.localPosition);
      HapticFeedback.selectionClick();
    }
    _publish(e.localPosition);
  }

  void _handleMove(PointerMoveEvent e) {
    if (_grabArmed && !_isDragging) {
      final moved =
          (e.localPosition - (_downPos ?? e.localPosition)).distance;
      if (moved > _grabSlop) {
        _isDragging = true;
        HapticFeedback.lightImpact();
        widget.engine.onLongPressStart(_downPos ?? e.localPosition);
      }
    }
    widget.engine.onPointerMove(e.localPosition);
    _publish(e.localPosition);
  }

  void _handleUp(PointerUpEvent e) {
    if (_isDragging) {
      widget.engine.onPointerUp();
    } else {
      widget.engine.onTap(_downPos ?? e.localPosition);
      widget.engine.onPointerUp();
    }
    widget.engine.disarmGrab();
    _grabArmed = false;
    _isDragging = false;
    _downPos = null;
    _publish(null);
  }

  void _handleCancel(PointerCancelEvent e) {
    widget.engine.onPointerUp();
    widget.engine.disarmGrab();
    _grabArmed = false;
    _isDragging = false;
    _downPos = null;
    _publish(null);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (_) {},
      onVerticalDragUpdate: (_) {},
      onVerticalDragEnd: (_) {},
      onHorizontalDragStart: (_) {},
      onHorizontalDragUpdate: (_) {},
      onHorizontalDragEnd: (_) {},
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _handleDown,
        onPointerHover: (event) {
          if (event.kind == PointerDeviceKind.mouse) {
            widget.engine.onPointerMove(event.localPosition);
            _publish(event.localPosition);
          }
        },
        onPointerMove: _handleMove,
        onPointerUp: _handleUp,
        onPointerCancel: _handleCancel,
        child: widget.child,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// المشي الواقعي
// ═════════════════════════════════════════════════════════════════

class LegState {
  final Offset restLocal;
  Offset foot;
  Offset stepFrom;
  Offset stepTo;
  double stepT;
  final int group;

  LegState(this.restLocal, this.foot, this.group)
      : stepFrom = foot,
        stepTo = foot,
        stepT = 1;

  bool get stepping => stepT < 1;

  Offset get visualFoot {
    if (!stepping) return foot;
    final t = Curves.easeInOutSine.transform(stepT);
    return Offset.lerp(stepFrom, stepTo, t)!;
  }
}

/// حشرة طائرة حرة (إشعار/إطعام يدوي).
class FreeInsect {
  Offset pos;
  Offset vel;
  final Color glow;
  final double wingPhase;
  double bornAt;
  final bool forced; // إطعام يدوي: يلاحقها فورًا مهما كان مزاجه.

  FreeInsect({
    required this.pos,
    required this.vel,
    this.glow = const Color(0xFF35C7CC),
    this.forced = false,
  })  : wingPhase = Random().nextDouble() * pi * 2,
        bornAt = 0;

  void update(
      double dt, double time, Size bounds, _SmoothNoise nx, _SmoothNoise ny) {
    bornAt += dt;
    final toCenter = Offset(bounds.width / 2, bounds.height * 0.35) - pos;
    final pull = toCenter / max(toCenter.distance, 1) * 26;
    final wander = Offset(nx.value(time * 1.4), ny.value(time * 1.2)) * 46;
    vel = Offset.lerp(vel, pull + wander, dt * 1.6)!;
    final speed = vel.distance;
    if (speed > 70) vel = vel / speed * 70;
    pos += vel * dt;
    if (pos.dx < 12 || pos.dx > bounds.width - 12) {
      vel = Offset(-vel.dx, vel.dy);
      pos = Offset(pos.dx.clamp(12.0, bounds.width - 12), pos.dy);
    }
    if (pos.dy < 12 || pos.dy > bounds.height - 12) {
      vel = Offset(vel.dx, -vel.dy);
      pos = Offset(pos.dx, pos.dy.clamp(12.0, bounds.height - 12));
    }
  }
}

// ═════════════════════════════════════════════════════════════════
// المحرك السلوكي الموسع
// ═════════════════════════════════════════════════════════════════

enum Surface { free, wallLeft, wallRight, ceiling }

class Sparkle {
  Offset pos;
  Offset vel;
  double life;
  final double maxLife;
  final bool heart;
  Sparkle(this.pos, this.vel, this.maxLife, this.heart) : life = maxLife;
}

class _SmoothNoise {
  final double a, b, c;
  _SmoothNoise(Random rng)
      : a = rng.nextDouble() * 100,
        b = rng.nextDouble() * 100,
        c = rng.nextDouble() * 100;

  double value(double t) => (sin(t * 0.7 + a) * 0.5 +
      sin(t * 1.31 + b) * 0.32 +
      sin(t * 2.17 + c) * 0.18);
}

class SpiderEngine {
  SpiderEngine({int? seed, String? name})
      : rng = Random(seed),
        _noiseX = _SmoothNoise(Random(seed == null ? null : seed + 1)),
        _noiseY = _SmoothNoise(Random(seed == null ? null : seed + 2)) {
    personality = SpiderPersonality.random(rng);
    table = BehaviorTable(personality, rng);
    webField = WebField(rng, maxWebs: personality.maxWebs);
    this.name = name;
  }

  final Random rng;
  late final SpiderPersonality personality;
  late final BehaviorTable table;
  late final WebField webField;

  /// رد نداء الأحداث الصوتية.
  void Function(SpiderSfx)? onSfx;

  /// اسم العنكبوت (للنداء).
  String? name;

  bool _grabPrimed = false;
  bool canGrabAt(Offset p) => (p - pos).distance <= bodyRadius * 3.6;
  final _SmoothNoise _noiseX;
  final _SmoothNoise _noiseY;

  Size size = Size.zero;
  double time = 0;

  // ── حالة ──
  SpiderState state = SpiderState.idleWatch;
  double stateTime = 0;
  double stateDuration = 2;

  // ── حركة ──
  Offset pos = Offset.zero;
  Offset vel = Offset.zero;
  Offset target = Offset.zero;
  Surface surface = Surface.free;
  double heading = 0;
  double bodyTilt = 0;
  double walkPhase = 0;
  double pauseTimer = 0;
  double scale = 1.0;

  // ── مشي واقعي ──
  final List<LegState> legs = [];

  // ── تشوّه وحركة ثانوية ──
  double squash = 1.0;
  double squashVel = 0;
  double breath = 0;
  Offset abdomenLag = Offset.zero;
  double legSettle = 0;
  double kickPhase = 0; // رفسة الرجل الخلفية (دغدغة)

  // ── الوجه ──
  double eyeClose = 0;
  double _nextBlinkIn = 1.5;
  double brow = 0;
  double mouthOpen = 0;
  Offset gaze = Offset.zero;

  // ── التدلي ──
  bool dangling = false;
  Offset? threadAnchor;
  double pendulum = 0;
  double pendulumVel = 0;

  // ── الصيد ──
  SpiderWeb? weavingWeb;
  SpiderWeb? focusWeb;
  Prey? targetPrey;
  Prey? heldPrey;
  FreeInsect? targetInsect;
  final List<FreeInsect> freeInsects = [];

  /// مخزن الفريسة (الإشعارات غير المقروءة) — ركن ثابت.
  final List<Prey> pantry = [];

  // ── مزاج وذاكرة ──

  /// 0 كئيب .. 1 سعيد. يتحسن بالتربيت اللطيف ويسوء بالإزعاج.
  double mood = 0.6;
  Offset? patSpot; // مكان التربيت المتكرر الذي تعلّمه
  int _patCount = 0;
  Offset? _lastPatAt;

  // ── دغدغة ──
  double _tickle = 0;
  Offset? _prevPointer;

  // ── مطر وكاميو ──
  double rainT = -1; // >0 يعني تمطر، عدّاد تنازلي
  double nextRainIn = 60 + Random().nextDouble() * 120;
  double cameoT = -1; // >0 يعني العنكبوت العابر ظاهر
  double nextCameoIn = 420 + Random().nextDouble() * 480;
  bool cameoFromLeft = true;

  // ── تفاعل المستخدم ──
  Offset? pointer;
  Offset lastTouch = Offset.zero;
  double sinceLastInteraction = 0;
  double gentleTouchScore = 0;
  bool carriedByUser = false;

  final List<Sparkle> sparkles = [];

  // ── دورة النهار والليل (ساعة الجهاز الحقيقية) ──
  static double get clockHour {
    final now = DateTime.now();
    return now.hour + now.minute / 60.0;
  }

  /// فجر 5-7، نهار 7-17، غروب 17-19، ليل 19-5.
  static DayPhase get dayPhase {
    final h = clockHour;
    if (h >= 5 && h < 7) return DayPhase.dawn;
    if (h >= 7 && h < 17) return DayPhase.day;
    if (h >= 17 && h < 19) return DayPhase.dusk;
    return DayPhase.night;
  }

  bool get isNight => dayPhase == DayPhase.night;
  bool get raining => rainT > 0;
  bool get cameoVisible => cameoT > 0;

  /// نبض القلب — نبضتان متتاليتان (lub-dub).
  double get heartBeat {
    final b = pow(max(0, sin(time * 3.4)), 6) +
        0.6 * pow(max(0, sin(time * 3.4 + 0.45)), 6);
    return (b as double).clamp(0.0, 1.0);
  }

  /// قرب العنكبوت من "الزجاج" (جهة المشاهد) — يفعّل نبض القلب.
  bool get nearGlass =>
      (pos - Offset(size.width / 2, size.height * 0.72)).distance <
          size.shortestSide * 0.38;

  void armGrab(Offset p) {
    lastTouch = p;
    sinceLastInteraction = 0;
    pointer = p;
    _grabPrimed = true;
  }

  void disarmGrab() {
    _grabPrimed = false;
  }

  void resize(Size s) {
    final first = size == Size.zero;
    size = s;
    scale = (s.shortestSide / 260).clamp(0.6, 1.6);
    if (first) {
      pos = Offset(s.width * 0.35, s.height * 0.62);
      target = pos;
      gaze = Offset(s.width / 2, s.height / 2);
      _initLegs();
      _enter(SpiderState.idleWatch);
    }
    pos = _clampToBounds(pos);
  }

  void _initLegs() {
    legs.clear();
    for (var i = 0; i < 8; i++) {
      final side = i < 4 ? -1.0 : 1.0;
      final idx = i % 4;
      final rest = Offset(
        side * bodyRadius * (1.5 + 0.35 * sin(-0.7 + idx * 0.5)),
        -bodyRadius * 0.1 +
            idx * bodyRadius * 0.62 -
            bodyRadius * 0.9 * sin(-0.7 + idx * 0.5) * 0.35,
      );
      legs.add(LegState(rest, pos + rest, i % 2));
    }
  }

  double get bodyRadius => 13.0 * scale;
  double get padding => bodyRadius * 2.2;

  /// ركن المخزن (أسفل يمين الشاشة).
  Offset get pantryCorner =>
      Offset(size.width - padding, size.height - padding);

  Offset _clampToBounds(Offset p) => Offset(
    p.dx.clamp(padding, max(padding, size.width - padding)),
    p.dy.clamp(padding, max(padding, size.height - padding)),
  );

  /// حقن إشعار/إطعام كحشرة طائرة وامضة من حافة عشوائية.
  void injectNotificationPrey({Color? glow, bool force = false}) {
    if (size == Size.zero) return;
    final fromLeft = rng.nextBool();
    freeInsects.add(FreeInsect(
      pos: Offset(
        fromLeft ? -10 : size.width + 10,
        size.height * (0.15 + rng.nextDouble() * 0.4),
      ),
      vel: Offset(fromLeft ? 60 : -60, (rng.nextDouble() - 0.5) * 20),
      glow: glow ?? const Color(0xFF35C7CC),
      forced: force,
    ));
    if (freeInsects.length > 3) freeInsects.removeAt(0);

    // إطعام قسري: يلاحق فورًا مهما كان مزاجه.
    if (force && targetInsect == null && freeInsects.isNotEmpty) {
      targetInsect = freeInsects.last;
      _enter(SpiderState.stalkFly);
    }
  }

  /// النداء بالاسم: يلتفت للمشاهد ويلوّح بفرح + قلوب.
  void callByName() {
    sinceLastInteraction = 0;
    gaze = Offset(size.width / 2, size.height);
    mood = (mood + 0.08).clamp(0.0, 1.0);
    onSfx?.call(SpiderSfx.callName);
    _enter(SpiderState.wave);
    stateDuration = 2.2;
    for (var i = 0; i < 4; i++) {
      sparkles.add(Sparkle(
        pos + Offset((rng.nextDouble() - 0.5) * 30, -bodyRadius),
        Offset((rng.nextDouble() - 0.5) * 14, -26 - rng.nextDouble() * 18),
        1.1 + rng.nextDouble() * 0.5,
        true,
      ));
    }
  }

  /// وضع التصوير: تجمّد وابتسامة ونظر للعداء.
  void poseForPhoto() {
    sinceLastInteraction = 0;
    _enter(SpiderState.photo);
  }

  /// اهتزاز الجهاز: يتشبث بالأرض وينكمش (اربطها بـ sensors_plus).
  void onDeviceShake() {
    if (state == SpiderState.carried) return;
    sinceLastInteraction = 0;
    _enter(SpiderState.clinging);
    HapticFeedback.heavyImpact();
  }

  void update(double dt) {
    if (size == Size.zero) return;
    dt = dt.clamp(0.0, 0.05);
    time += dt;
    stateTime += dt;
    sinceLastInteraction += dt;
    gentleTouchScore = max(0, gentleTouchScore - dt * 0.35);

    _updateWeather(dt);
    webField.update(dt);
    _updateInsects(dt);
    _updateGait(dt);
    _updateFace(dt);
    _updateSecondaryMotion(dt);
    _updateTickle(dt);
    _updateSparkles(dt);
    _reactToPointer();

    _feedCheckTimer -= dt;
    if (_feedCheckTimer <= 0) {
      _feedCheckTimer = 2.0 + rng.nextDouble() * 2.5;
      _maybeStartFeeding();
    }
    switch (state) {
      case SpiderState.wander:
        _tickWander(dt);
        break;
      case SpiderState.idleWatch:
        _tickIdle(dt);
        break;
      case SpiderState.sleep:
        _tickSleep(dt);
        break;
      case SpiderState.stretch:
        _tickStretch(dt);
        break;
      case SpiderState.wave:
        _tickWave(dt);
        break;
      case SpiderState.dangle:
        _tickDangle(dt);
        break;
      case SpiderState.weave:
        _tickWeave(dt);
        break;
      case SpiderState.groom:
        _tickGroom(dt);
        break;
      case SpiderState.flee:
        _tickFlee(dt);
        break;
      case SpiderState.curious:
        _tickCurious(dt);
        break;
      case SpiderState.hide:
        _tickHide(dt);
        break;
      case SpiderState.spin:
        _tickSpin(dt);
        break;
      case SpiderState.hop:
        _tickHop(dt);
        break;
      case SpiderState.stalk:
        _tickStalk(dt);
        break;
      case SpiderState.stalkFly:
        _tickStalkFly(dt);
        break;
      case SpiderState.pounce:
        _tickPounce(dt);
        break;
      case SpiderState.wrapPrey:
        _tickWrap(dt);
        break;
      case SpiderState.stashPrey:
        _tickStash(dt);
        break;
      case SpiderState.pluckWeb:
        _tickPluck(dt);
        break;
      case SpiderState.peek:
        _tickPeek(dt);
        break;
      case SpiderState.restOnWeb:
        _tickRestOnWeb(dt);
        break;
      case SpiderState.happy:
        _tickHappy(dt);
        break;
      case SpiderState.carried:
        _tickCarried(dt);
        break;
      case SpiderState.dismantle:
        _tickDismantle(dt);
        break;
      case SpiderState.watchRain:
        _tickWatchRain(dt);
        break;
      case SpiderState.awaitPat:
        _tickAwaitPat(dt);
        break;
      case SpiderState.tickled:
        _tickTickled(dt);
        break;
      case SpiderState.photo:
        _tickPhoto(dt);
        break;
      case SpiderState.clinging:
        _tickClinging(dt);
        break;
    }

    if (sinceLastInteraction > 16 &&
        (state == SpiderState.idleWatch || state == SpiderState.wander)) {
      gaze = lastTouch == Offset.zero
          ? Offset(size.width / 2, size.height / 2)
          : lastTouch;
      _enter(SpiderState.wave);
      sinceLastInteraction = 0;
    }

    if (stateTime >= stateDuration) _chooseNext();
    pos = _clampToBounds(pos);
  }

  // ── الطقس: مطر عابر + عنكبوت عابر نادر جدًا ──
  void _updateWeather(double dt) {
    if (rainT > 0) {
      rainT -= dt;
    } else {
      nextRainIn -= dt;
      if (nextRainIn <= 0) {
        rainT = 14 + rng.nextDouble() * 10;
        nextRainIn = 90 + rng.nextDouble() * 150;
      }
    }

    if (cameoT > 0) {
      cameoT -= dt;
    } else {
      nextCameoIn -= dt;
      if (nextCameoIn <= 0) {
        cameoT = 6; // يعبر خلال 6 ثوانٍ ولا يعود
        cameoFromLeft = rng.nextBool();
        nextCameoIn = 480 + rng.nextDouble() * 600; // كل ~8-18 دقيقة
      }
    }
  }

  void _updateInsects(double dt) {
    freeInsects.removeWhere((i) => i.bornAt > 45);
    for (final i in freeInsects) {
      i.update(dt, time, size, _noiseX, _noiseY);
    }
    if (targetInsect == null &&
        freeInsects.isNotEmpty &&
        (state == SpiderState.wander ||
            state == SpiderState.idleWatch ||
            state == SpiderState.restOnWeb)) {
      // مزاج منخفض → قد يتجاهل الحشرة (ليست يدوية).
      final ignoreChance = (1 - mood) * 0.7;
      final anyForced = freeInsects.any((i) => i.forced);
      if (anyForced || rng.nextDouble() > ignoreChance) {
        if (rng.nextDouble() <
            dt * (0.25 + personality.preyNoticeChance)) {
          final nearest = _nearestInsect();
          if (nearest != null &&
              (nearest.pos - pos).distance < size.longestSide) {
            targetInsect = nearest;
            _enter(SpiderState.stalkFly);
          }
        }
      }
    }
  }

  FreeInsect? _nearestInsect() {
    FreeInsect? best;
    var bestD = double.infinity;
    for (final i in freeInsects) {
      final d = (i.pos - pos).distance;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  // ── المشي ──
  void _updateGait(double dt) {
    if (legs.isEmpty) return;

    // أثناء التدلي/الحمل: الأرجل تتدلى وتتمايل.
    if (dangling || state == SpiderState.carried) {
      for (var i = 0; i < legs.length; i++) {
        final l = legs[i];
        final dangleTarget = pos +
            Offset(
              l.restLocal.dx * 0.55,
              bodyRadius * 1.1 + l.restLocal.dy * 0.25,
            ) +
            Offset(sin(time * 3 + i * 1.1) * 1.6, 0);
        l.foot = Offset.lerp(l.foot, dangleTarget, dt * 6)!;
        l.stepT = 1;
        l.stepFrom = l.foot;
        l.stepTo = l.foot;
      }
      return;
    }

    // التشبث بالأرض (اهتزاز الجهاز): كل الأقدام تنجذب قرب الجسم.
    if (state == SpiderState.clinging) {
      for (var i = 0; i < legs.length; i++) {
        final l = legs[i];
        final t = pos + l.restLocal * 0.45;
        l.foot = Offset.lerp(l.foot, t, dt * 10)!;
        l.stepT = 1;
        l.stepFrom = l.foot;
        l.stepTo = l.foot;
      }
      return;
    }

    // التلويح: الرجلان الأماميتان ترتفعان وتلوّحان.
    if (state == SpiderState.wave || state == SpiderState.awaitPat) {
      final freq = state == SpiderState.wave ? 10.0 : 3.0;
      final raise = state == SpiderState.wave ? 1.0 : 0.6;
      for (var i = 0; i < legs.length; i++) {
        final l = legs[i];
        final side = i < 4 ? -1.0 : 1.0;
        final idx = i % 4;
        Offset t;
        if (idx == 0) {
          final swing = sin(time * freq) * 0.5;
          t = pos +
              Offset(
                side * bodyRadius * (1.3 + swing * 0.25),
                -bodyRadius * (0.6 + raise * (0.55 + swing * 0.45)),
              );
        } else {
          t = pos + Offset(l.restLocal.dx * 0.85, l.restLocal.dy * 0.85);
        }
        l.foot = Offset.lerp(l.foot, t, dt * 8)!;
        l.stepT = 1;
        l.stepFrom = l.foot;
        l.stepTo = l.foot;
      }
      return;
    }

    // الدغدغة: الرجلان الخلفيتان ترفسان.
    if (state == SpiderState.tickled) {
      kickPhase += dt * 16;
      for (var i = 0; i < legs.length; i++) {
        final l = legs[i];
        final side = i < 4 ? -1.0 : 1.0;
        final idx = i % 4;
        Offset t;
        if (idx == 3) {
          final kick = max(0, sin(kickPhase + (i % 2) * pi));
          t = pos +
              Offset(
                side * bodyRadius * (1.7 + kick * 0.5),
                -bodyRadius * 0.2 - kick * bodyRadius * 1.1,
              );
        } else {
          t = pos + Offset(l.restLocal.dx * 0.8, l.restLocal.dy * 0.8);
        }
        l.foot = Offset.lerp(l.foot, t, dt * 12)!;
        l.stepT = 1;
        l.stepFrom = l.foot;
        l.stepTo = l.foot;
      }
      return;
    }

    final cosH = cos(heading), sinH = sin(heading);
    Offset toWorld(Offset local) => Offset(local.dx * cosH - local.dy * sinH,
        local.dx * sinH + local.dy * cosH) +
        pos;

    final speed = vel.distance;
    final stepThreshold = bodyRadius * (speed > 4 ? 0.85 : 1.15);
    final stepDuration = (0.16 - (speed / 400)).clamp(0.08, 0.16);

    for (var i = 0; i < legs.length; i++) {
      final l = legs[i];
      if (l.stepping) {
        l.stepT += dt / stepDuration;
        if (l.stepT >= 1) {
          l.stepT = 1;
          l.foot = l.stepTo;
        }
        continue;
      }
      final lead = vel * 0.22;
      final ideal = toWorld(l.restLocal) + lead;
      if ((ideal - l.foot).distance > stepThreshold) {
        final groupBusy = legs.any((o) => o.group == l.group && o.stepping);
        final neighborBusy = (i > 0 && legs[i - 1].stepping) ||
            (i < legs.length - 1 && legs[i + 1].stepping);
        if (!groupBusy && !neighborBusy) {
          l.stepFrom = l.foot;
          l.stepTo = ideal + vel * 0.10;
          l.stepT = 0;
        }
      } else if (speed < 2) {
        l.foot = Offset.lerp(l.foot, ideal, dt * 2)!;
      }
    }
  }

  void _enter(SpiderState s) {
    if (s != SpiderState.dangle && s != SpiderState.carried) {
      dangling = false;
      threadAnchor = null;
      pendulum = 0;
      pendulumVel = 0;
    }
    if (s != SpiderState.weave) {
      if (weavingWeb != null && !weavingWeb!.isComplete) {
        webField.webs.remove(weavingWeb);
      }
      weavingWeb = null;
    }
    if (s != SpiderState.stalk &&
        s != SpiderState.stalkFly &&
        s != SpiderState.pounce &&
        s != SpiderState.wrapPrey) {
      targetPrey = null;
      if (s != SpiderState.stalkFly) targetInsect = null;
    }
    if (s != SpiderState.hide && s != SpiderState.peek) surface = Surface.free;

    state = s;
    stateTime = 0;
    stateDuration = table.duration(s);

    switch (s) {
      case SpiderState.wander:
        _pickWanderTarget();
        brow = 0;
        mouthOpen = 0;
        break;
      case SpiderState.dangle:
        threadAnchor = Offset(pos.dx, padding * 0.3);
        dangling = true;
        pendulumVel = (rng.nextDouble() - 0.5) * 1.6;
        break;
      case SpiderState.weave:
        _beginWeave();
        onSfx?.call(SpiderSfx.weavePluck);
        break;
      case SpiderState.stalk:
        _beginStalk();
        break;
      case SpiderState.pounce:
        squashVel = -6;
        break;
      case SpiderState.hop:
        squashVel = -5;
        break;
      case SpiderState.hide:
        target = _nearestCorner();
        break;
      case SpiderState.peek:
        mouthOpen = 0.25;
        break;
      case SpiderState.restOnWeb:
        final w = webField.nearestCompleteWeb(pos);
        if (w != null) target = w.center;
        break;
      case SpiderState.pluckWeb:
        focusWeb = webField.nearestCompleteWeb(pos);
        if (focusWeb != null) {
          target = focusWeb!.center +
              Offset(cos(rng.nextDouble() * pi * 2),
                  sin(rng.nextDouble() * pi * 2)) *
                  focusWeb!.radius *
                  0.7;
        }
        break;
      case SpiderState.happy:
        brow = 1;
        eyeClose = 0.55;
        mood = (mood + 0.06).clamp(0.0, 1.0);
        break;
      case SpiderState.carried:
        mouthOpen = 1;
        dangling = true;
        threadAnchor = pointer;
        mood = (mood - 0.01).clamp(0.0, 1.0);
        break;
      case SpiderState.dismantle:
        final w = _oldestFrayedWeb;
        target = w?.center ?? pos;
        break;
      case SpiderState.watchRain:
        target = Offset(size.width / 2, size.height * 0.68);
        break;
      case SpiderState.awaitPat:
        target = patSpot ?? pos;
        break;
      case SpiderState.flee:
        mood = (mood - 0.03).clamp(0.0, 1.0);
        onSfx?.call(SpiderSfx.flee);
        break;
      case SpiderState.tickled:
        onSfx?.call(SpiderSfx.tickleGiggle);
        break;
      default:
        break;
    }
  }

  /// أقدم شبكة متقادمة (أكثر من 45 ثانية مكتملة).
  SpiderWeb? get _oldestFrayedWeb {
    SpiderWeb? best;
    var bestAge = 45.0;
    for (final w in webField.webs) {
      if (w.isComplete && w.ageSinceComplete > bestAge) {
        bestAge = w.ageSinceComplete;
        best = w;
      }
    }
    return best;
  }

  void _chooseNext() {
    switch (state) {
      case SpiderState.sleep:
        _enter(SpiderState.stretch);
        return;
      case SpiderState.stalk:
        if (targetPrey != null) {
          _enter(SpiderState.wrapPrey);
          return;
        }
        break;
      case SpiderState.stalkFly:
        if (targetInsect != null) return;
        break;
      case SpiderState.wrapPrey:
        if (rng.nextDouble() < 0.35 + personality.industriousness * 0.4) {
          heldPrey = targetPrey;
          heldPrey?.carriedBySpider = true;
          _enter(SpiderState.stashPrey);
          return;
        }
        break;
      case SpiderState.hide:
        if (rng.nextDouble() < 0.7) {
          _enter(SpiderState.peek);
          return;
        }
        break;
      case SpiderState.weave:
        if (rng.nextDouble() < 0.45 + personality.sleepiness * 0.3) {
          _enter(SpiderState.restOnWeb);
          return;
        }
        break;
      case SpiderState.carried:
        return;
      default:
        break;
    }

    final prevWeb = webField.webWithFreePrey(pos);
    final ctx = BehaviorContext(
      hasWeb: webField.webs.any((w) => w.isComplete),
      hasFreePrey: prevWeb != null,
      hasFlyingPrey: freeInsects.isNotEmpty,
      holdsPrey: heldPrey != null,
      recentlyTouched: sinceLastInteraction < 5,
      canWeaveNow: webField.canWeave,
      onOwnWeb: webField.webAt(pos) != null,
      isNight: isNight,
      mood: mood,
      raining: raining,
      hasFrayedWeb: _oldestFrayedWeb != null,
      knowsPatSpot: patSpot != null,
    );
    _enter(table.pick(ctx));
  }

  void _pickWanderTarget() {
    for (var i = 0; i < 40; i++) {
      final t = Offset(
        padding + rng.nextDouble() * (size.width - padding * 2),
        padding + rng.nextDouble() * (size.height - padding * 2),
      );
      final center = Offset(size.width / 2, size.height / 2);
      if ((t - center).distance < size.shortestSide * 0.12 &&
          rng.nextDouble() < 0.8) continue;
      if (webField.blocks(t)) continue;
      if ((t - pos).distance < size.shortestSide * 0.2) continue;
      target = t;
      return;
    }
    target = _clampToBounds(Offset(
      padding + rng.nextDouble() * (size.width - padding * 2),
      padding + rng.nextDouble() * (size.height - padding * 2),
    ));
  }

  Offset _nearestCorner() {
    final corners = [
      Offset(padding, padding),
      Offset(size.width - padding, padding),
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
    ];
    corners.sort((a, b) => (a - pos).distance.compareTo((b - pos).distance));
    return corners.first;
  }

  bool _stepToward(Offset goal, double dt,
      {double speedScale = 1.0, bool organic = true}) {
    final toGoal = goal - pos;
    final dist = toGoal.distance;
    if (dist < 3) {
      vel = Offset.lerp(vel, Offset.zero, dt * 8)!;
      legSettle = min(1, legSettle + dt * 4);
      return true;
    }

    if (organic) {
      if (pauseTimer > 0) {
        pauseTimer -= dt;
        vel = Offset.lerp(vel, Offset.zero, dt * 8)!;
        legSettle = min(1, legSettle + dt * 3);
        gaze = pos + Offset(cos(time * 1.3) * 40, sin(time * 0.9) * 24);
        return false;
      }
      if (rng.nextDouble() < dt * 0.25) {
        pauseTimer = 0.4 + rng.nextDouble() * 1.1;
      }
    }

    var dir = toGoal / dist;
    if (organic) {
      final n = _noiseX.value(time * 0.6);
      final perp = Offset(-dir.dy, dir.dx);
      dir = (dir + perp * n * 0.45);
      final l = dir.distance;
      if (l > 0) dir = dir / l;
      final ahead = pos + dir * (bodyRadius * 3);
      if (webField.blocks(ahead)) {
        final perp2 = Offset(-dir.dy, dir.dx);
        dir = (dir + perp2 * 1.2);
        final l2 = dir.distance;
        if (l2 > 0) dir = dir / l2;
      }
    }

    final startEase = (stateTime / 0.5).clamp(0.25, 1.0);
    final arriveEase = (dist / 60).clamp(0.25, 1.0);
    final speed =
        personality.baseSpeed * scale * speedScale * startEase * arriveEase;

    vel = Offset.lerp(vel, dir * speed, dt * 6)!;
    pos += vel * dt;
    if (vel.distance > 1) {
      heading = atan2(vel.dy, vel.dx);
      walkPhase += vel.distance * dt * 0.35;
      legSettle = max(0, legSettle - dt * 5);
      gaze = pos + Offset(cos(heading), sin(heading)) * 50;
    }
    return false;
  }

  void _tickWander(double dt) {
    if (_stepToward(target, dt)) {
      final w = webField.webWithFreePrey(pos);
      if (w != null && rng.nextDouble() < personality.preyNoticeChance) {
        _enter(SpiderState.stalk);
        return;
      }
      _pickWanderTarget();
    }
  }

  void _tickIdle(double dt) {
    vel = Offset.lerp(vel, Offset.zero, dt * 8)!;
    legSettle = min(1, legSettle + dt * 3);
    if (rng.nextDouble() < dt * 0.6) {
      gaze = Offset(
        padding + rng.nextDouble() * (size.width - padding * 2),
        padding + rng.nextDouble() * (size.height - padding * 2),
      );
    }
  }

  void _tickSleep(double dt) {
    vel = Offset.zero;
    eyeClose = min(1, eyeClose + dt * 0.8);
    brow = lerpDouble(brow, -0.15, dt * 2)!;
    mouthOpen = 0;
  }

  void _tickStretch(double dt) {
    eyeClose = max(0, eyeClose - dt * 2);
    final t = (stateTime / stateDuration).clamp(0.0, 1.0);
    squash = 1 + sin(t * pi) * 0.28;
    brow = sin(t * pi) * 0.8;
  }

  void _tickWave(double dt) {
    vel = Offset.lerp(vel, Offset.zero, dt * 10)!;
    brow = 0.7;
    mouthOpen = 0.15;
    gaze = pointer ??
        (lastTouch == Offset.zero
            ? Offset(size.width / 2, size.height / 2)
            : lastTouch);
  }

  void _tickDangle(double dt) {
    final anchor = threadAnchor ?? Offset(pos.dx, padding * 0.3);
    threadAnchor = anchor;
    final t = (stateTime / stateDuration).clamp(0.0, 1.0);
    final len =
        (size.height * 0.45) * sin(t * pi).clamp(0.05, 1.0) + bodyRadius * 2;
    pendulumVel += -pendulum * 3.2 * dt;
    pendulumVel *= (1 - dt * 0.6);
    pendulum += pendulumVel * dt;
    pos = anchor + Offset(sin(pendulum) * len, cos(pendulum) * len);
    bodyTilt = pendulum;
    gaze = pos + const Offset(0, 40);
  }

  void _beginWeave() {
    final site = webField.chooseWeaveSite(size);
    if (site == null || !webField.canWeave) {
      _enter(SpiderState.wander);
      return;
    }
    target = site.anchor;
    weavingWeb = null;
    _pendingWeave = _PendingWeave(site.type, site.anchor, site.size);
  }

  _PendingWeave? _pendingWeave;

  Offset _weaveStandPoint(WebType type, Offset center) {
    if (type != WebType.corner) return center;
    final dx = center.dx < size.width / 2 ? 1.0 : -1.0;
    final dy = center.dy < size.height / 2 ? 1.0 : -1.0;
    final inward = Offset(dx, dy);
    return center + inward / inward.distance * (bodyRadius * 1.6);
  }

  void _tickWeave(double dt) {
    final pending = _pendingWeave;
    if (weavingWeb == null) {
      if (pending == null) {
        _enter(SpiderState.wander);
        return;
      }
      final standPoint = _weaveStandPoint(pending.type, pending.center);
      if (_stepToward(standPoint, dt, speedScale: 1.15)) {
        weavingWeb = webField.startWeave(
          type: pending.type,
          center: pending.center,
          radius: pending.radius,
          radials: pending.type == WebType.corner
              ? 3 + rng.nextInt(3)
              : personality.webRadials,
          rings: personality.webRings,
          containerSize: size,
        );

        _pendingWeyWeaveNull();
        stateTime = 0;
      }
      return;
    }
    final standPoint = _weaveStandPoint(weavingWeb!.type, weavingWeb!.center);
    pos = Offset.lerp(pos, standPoint, dt * 6)!;
    brow = -0.3;
    final w = weavingWeb!;
    w.progress = (stateTime / stateDuration).clamp(0.0, 1.0);
    walkPhase += dt * 6;
    gaze =
        w.center + Offset(cos(time * 3) * w.radius, sin(time * 3) * w.radius);
  }

  void _pendingWeyWeaveNull() => _pendingWeave = null;

  void _tickGroom(double dt) {
    final w = webField.nearestCompleteWeb(pos);
    if (w == null) {
      _enter(SpiderState.wander);
      return;
    }
    if (_stepToward(w.center, dt, speedScale: 0.9)) {
      walkPhase += dt * 7;
      brow = -0.2;
      if (rng.nextDouble() < dt * 1.5) {
        w.pluck();
        onSfx?.call(SpiderSfx.webPluck);
      }
    }
  }

  void _tickFlee(double dt) {
    final from = pointer ?? lastTouch;
    var dir = pos - from;
    if (dir.distance < 0.01) dir = const Offset(1, 0);
    dir = dir / dir.distance;
    if (stateTime < dt && rng.nextDouble() < 0.35) {
      surface = pos.dx < size.width / 2 ? Surface.wallLeft : Surface.wallRight;
    }
    final speed = personality.fleeSpeed * scale;
    vel = Offset.lerp(vel, dir * speed, dt * 10)!;
    pos += vel * dt;
    heading = atan2(vel.dy, vel.dx);
    walkPhase += vel.distance * dt * 0.5;
    eyeClose = 0;
    brow = -0.9;
    mouthOpen = 0.8;
    gaze = from;
  }

  void _tickCurious(double dt) {
    final goal = lastTouch == Offset.zero
        ? Offset(size.width / 2, size.height / 2)
        : lastTouch;
    brow = 0.4;
    mouthOpen = 0.35;
    gaze = goal;
    _stepToward(_clampToBounds(goal), dt, speedScale: 0.85);
  }

  void _tickHide(double dt) {
    brow = -0.5;
    if (_stepToward(target, dt, speedScale: 1.3, organic: false)) {
      squash = lerpDouble(squash, 0.82, dt * 4)!;
      eyeClose = min(0.6, eyeClose + dt);
    }
  }

  void _tickPeek(double dt) {
    final t = (stateTime / stateDuration).clamp(0.0, 1.0);
    eyeClose = max(0, 0.5 - t);
    final corner = _nearestCorner();
    pos = Offset.lerp(
        corner,
        corner + (Offset(size.width / 2, size.height / 2) - corner) * 0.18,
        t)!;
    brow = 0.3;
  }

  void _tickSpin(double dt) {
    bodyTilt += dt * 12;
    brow = 0.6;
    mouthOpen = 0.3;
    vel = Offset.zero;
  }

  void _tickHop(double dt) {
    final t = (stateTime / stateDuration).clamp(0.0, 1.0);
    if (t < 0.25) {
      squash = lerpDouble(squash, 0.78, dt * 12)!;
    } else {
      final j = sin((t - 0.25) / 0.75 * pi);
      squash = 1 + j * 0.3;
      pos = Offset(pos.dx + cos(heading) * 40 * dt, pos.dy - j * 1.2);
    }
  }

  void _beginStalk() {
    final w = webField.webWithFreePrey(pos);
    targetPrey = w?.firstFreePrey;
    focusWeb = w;
    if (targetPrey == null) _enter(SpiderState.wander);
  }

  void _tickStalk(double dt) {
    final prey = targetPrey;
    if (prey == null || !prey.isFree) {
      _enter(SpiderState.wander);
      return;
    }
    brow = -1;
    mouthOpen = 0;
    gaze = prey.position;

    final standOffset = Offset(0, -bodyRadius * 1.1);
    final approachTarget = prey.position + standOffset;
    final d = (approachTarget - pos).distance;
    final slow = (d / 90).clamp(0.25, 0.8);
    final arrived =
    _stepToward(approachTarget, dt, speedScale: slow, organic: false);

    if (arrived || d < bodyRadius * 1.6) {
      _enter(SpiderState.wrapPrey);
    }
  }

  void _tickStalkFly(double dt) {
    final insect = targetInsect;
    if (insect == null || !freeInsects.contains(insect)) {
      targetInsect = null;
      _enter(SpiderState.wander);
      return;
    }
    brow = -0.8;
    mouthOpen = 0.15;
    gaze = insect.pos;

    final d = (insect.pos - pos).distance;
    final speedScale = d < bodyRadius * 6 ? 1.6 : 0.95;
    _stepToward(insect.pos, dt, speedScale: speedScale, organic: false);

    if (d < bodyRadius * 1.4) {
      freeInsects.remove(insect);
      targetInsect = null;
      squashVel = -5;
      brow = 0.6;
      mouthOpen = 0.6;
      onSfx?.call(SpiderSfx.catchPrey);
      heldPrey = Prey(
        position: insect.pos,
        phase: PreyPhase.cocoon,
        wrapProgress: 1,
      )..carriedBySpider = true;
      _enter(SpiderState.stashPrey);
      stateDuration = 3.2;
    } else if (stateTime > stateDuration) {
      targetInsect = null;
      _enter(SpiderState.idleWatch);
    }
  }

  void _tickPounce(double dt) {
    final prey = targetPrey;
    if (prey == null) {
      _enter(SpiderState.wander);
      return;
    }
    final t = (stateTime / stateDuration).clamp(0.0, 1.0);
    if (t < 0.35) {
      squash = lerpDouble(squash, 0.75, dt * 14)!;
      brow = -1;
      final standOffset = Offset(0, -bodyRadius * 0.9);
      pos = Offset.lerp(pos, prey.position + standOffset, dt * 4)!;
    } else {
      squash = lerpDouble(squash, 1.22, dt * 12)!;
      pos = Offset.lerp(pos, prey.position, dt * 9)!;
      mouthOpen = 0.7;
      if ((prey.position - pos).distance < 4) {
        squash = 0.7;
        _consumePrey(prey);
        _enter(SpiderState.idleWatch);
      }
    }
  }

  void _consumePrey(Prey prey) {
    for (final w in webField.webs) {
      w.prey.remove(prey);
    }
    pantry.remove(prey);
    targetPrey = null;
    focusWeb = null;
    brow = 0.3;
    mouthOpen = 0;
  }

  double _feedCheckTimer = 2.0;

  void _maybeStartFeeding() {
    if (state != SpiderState.wander &&
        state != SpiderState.idleWatch &&
        state != SpiderState.groom) return;
    if (targetPrey != null) return;

    // المخزن أولًا (أكل الإشعارات "المقروءة" لاحقًا).
    for (final p in pantry) {
      if (p.timeSinceCocoon > p.eatDelay) {
        if (rng.nextDouble() < 0.2 + mood * 0.3) {
          targetPrey = p;
          _enter(SpiderState.pounce);
        }
        return;
      }
    }
    for (final w in webField.webs) {
      for (final p in w.prey) {
        if (p.phase == PreyPhase.cocoon &&
            !p.carriedBySpider &&
            p.timeSinceCocoon > p.eatDelay) {
          final chance = 0.15 + personality.industriousness * 0.5;
          if (rng.nextDouble() < chance) {
            targetPrey = p;
            focusWeb = w;
            _enter(SpiderState.pounce);
          }
          return;
        }
      }
    }
  }

  void _tickWrap(double dt) {
    final prey = targetPrey;
    if (prey == null) {
      _enter(SpiderState.wander);
      return;
    }
    if (prey.phase == PreyPhase.stuck) prey.phase = PreyPhase.wrapping;

    final holdOffset = Offset(0, -bodyRadius * 0.9);
    pos = Offset.lerp(pos, prey.position + holdOffset, dt * 8)!;
    bodyTilt = lerpDouble(bodyTilt, 0, dt * 6)!;
    walkPhase += dt * 16;
    brow = -0.6;
    mouthOpen = 0;
    gaze = prey.position;
    if (prey.phase == PreyPhase.cocoon && stateTime > 0.6) _chooseNext();
  }

  void _tickStash(double dt) {
    final prey = heldPrey;
    if (prey == null) {
      _enter(SpiderState.wander);
      return;
    }
    final corner = pantryCorner;
    final reached = _stepToward(corner, dt, speedScale: 0.7, organic: false);
    prey.position = pos + const Offset(0, 10);
    if (reached) {
      prey.carriedBySpider = false;
      prey.position = corner + Offset(
        -pantry.length * 6.0, // تراكم بصري جانبي
        -pantry.length * 3.0,
      );
      pantry.add(prey);
      heldPrey = null;
      _enter(SpiderState.idleWatch);
    }
  }

  void _tickPluck(double dt) {
    final w = focusWeb;
    if (w == null) {
      _enter(SpiderState.wander);
      return;
    }
    if (_stepToward(target, dt, speedScale: 0.9)) {
      brow = -0.4;
      gaze = w.center;
      if (w.ripple < 0.2 && rng.nextDouble() < dt * 2.5) {
        w.pluck();
        onSfx?.call(SpiderSfx.webPluck);
      }
    }
  }

  void _tickRestOnWeb(double dt) {
    final w = webField.nearestCompleteWeb(pos);
    if (w == null) {
      _enter(SpiderState.idleWatch);
      return;
    }
    if (_stepToward(w.center, dt, speedScale: 0.8)) {
      eyeClose = min(0.45, eyeClose + dt * 0.5);
      brow = 0.1;
    }
  }

  void _tickHappy(double dt) {
    vel = Offset.zero;
    eyeClose = 0.55;
    brow = 1;
    mouthOpen = 0.1;
    abdomenLag = Offset(sin(time * 9) * 2.2, 0);
    if (rng.nextDouble() < dt * 9) {
      sparkles.add(Sparkle(
        pos + Offset((rng.nextDouble() - 0.5) * 24, -bodyRadius),
        Offset((rng.nextDouble() - 0.5) * 18, -20 - rng.nextDouble() * 22),
        0.9 + rng.nextDouble() * 0.5,
        rng.nextDouble() < 0.35,
      ));
    }
  }

  void _tickCarried(double dt) {
    final finger = pointer;
    if (finger == null) {
      _release();
      return;
    }
    threadAnchor = finger;
    dangling = true;
    final restLen = bodyRadius * 3.4;
    final desired = finger + Offset(0, restLen);
    pos = Offset.lerp(pos, desired, dt * 9)!;
    mouthOpen = 1;
    eyeClose = 0;
    brow = 0.9;
    gaze = finger;
    bodyTilt = sin(time * 5) * 0.12;
  }

  void _release() {
    carriedByUser = false;
    dangling = false;
    threadAnchor = null;
    squashVel = -8;
    bodyTilt = 0.35;
    _enter(SpiderState.idleWatch);
    stateDuration = 1.4;
  }

  // ── الحالات الجديدة ──

  /// تفكيك شبكة متقادمة وإعادة النسج مكانها.
  void _tickDismantle(double dt) {
    final w = _oldestFrayedWeb;
    if (w == null) {
      _enter(SpiderState.wander);
      return;
    }
    brow = -0.3;
    if (_stepToward(w.center, dt, speedScale: 1.1)) {
      // نتف متكرر ثم إزالة.
      walkPhase += dt * 12;
      if (w.ripple < 0.3) w.pluck();
      if (stateTime > 1.6) {
        webField.webs.remove(w);
        webField.weaveCooldown = 0; // سماح فوري بإعادة النسج
        onSfx?.call(SpiderSfx.webPluck);
        _enter(SpiderState.weave);
      }
    }
  }

  /// الجلوس لمشاهدة المطر.
  void _tickWatchRain(double dt) {
    if (!raining) {
      _enter(SpiderState.idleWatch);
      return;
    }
    if (_stepToward(target, dt, speedScale: 0.8)) {
      vel = Offset.zero;
      brow = 0.25;
      gaze = pos + Offset(sin(time * 0.5) * 26, -60); // ينظر للمطر فوق
    }
  }

  /// الانتظار في مكان التربيت المتعلَّم.
  void _tickAwaitPat(double dt) {
    final spot = patSpot;
    if (spot == null) {
      _enter(SpiderState.idleWatch);
      return;
    }
    if (_stepToward(spot, dt, speedScale: 0.9)) {
      vel = Offset.zero;
      brow = 0.5;
      gaze = pointer ?? Offset(size.width / 2, size.height / 2);
    }
  }

  void _tickTickled(double dt) {
    vel = Offset.zero;
    squash = lerpDouble(squash, 0.88, dt * 10)!;
    brow = 0.8;
    mouthOpen = 0.4;
    gaze = pointer ?? pos;
    if (rng.nextDouble() < dt * 7) {
      sparkles.add(Sparkle(
        pos + Offset((rng.nextDouble() - 0.5) * 26, -bodyRadius * 0.5),
        Offset((rng.nextDouble() - 0.5) * 20, -16 - rng.nextDouble() * 14),
        0.5 + rng.nextDouble() * 0.3,
        false,
      ));
    }
  }

  void _tickPhoto(double dt) {
    vel = Offset.zero;
    brow = 1;
    mouthOpen = 0.12;
    eyeClose = max(0, eyeClose - dt * 6); // عينان مفتوحتان تمامًا
    gaze = Offset(size.width / 2, size.height * 1.2); // ينظر للعداء
    if (rng.nextDouble() < dt * 3) {
      sparkles.add(Sparkle(
        pos + Offset((rng.nextDouble() - 0.5) * 34, -bodyRadius * 1.4),
        const Offset(0, -8),
        0.6,
        false,
      ));
    }
  }

  void _tickClinging(double dt) {
    vel = Offset.zero;
    squash = lerpDouble(squash, 0.85, dt * 12)!;
    eyeClose = 0;
    brow = -0.6;
    gaze = Offset(size.width / 2, size.height / 2);
  }

  void _updateSecondaryMotion(double dt) {
    breath += dt * (state == SpiderState.sleep ? 1.4 : 2.6);
    final springTarget = 1.0;
    squashVel += (springTarget - squash) * 90 * dt;
    squashVel *= (1 - dt * 6);
    squash += squashVel * dt;
    squash = squash.clamp(0.65, 1.35);

    abdomenLag = Offset.lerp(abdomenLag, -vel * 0.03, dt * 7)!;

    if (state != SpiderState.spin &&
        state != SpiderState.wrapPrey &&
        !dangling) {
      bodyTilt = lerpDouble(bodyTilt, _surfaceTilt(), dt * 6)!;
    }
  }

  double _surfaceTilt() {
    switch (surface) {
      case Surface.wallLeft:
        return pi / 2;
      case Surface.wallRight:
        return -pi / 2;
      case Surface.ceiling:
        return pi;
      case Surface.free:
        return 0;
    }
  }

  void _updateFace(double dt) {
    if (state != SpiderState.sleep &&
        state != SpiderState.happy &&
        state != SpiderState.photo) {
      _nextBlinkIn -= dt;
      if (_nextBlinkIn <= 0) {
        _nextBlinkIn = 1.2 + rng.nextDouble() * 4.2;
        eyeClose = 1;
      }
      eyeClose = max(0, eyeClose - dt * 6);
    }
    mouthOpen = mouthOpen.clamp(0.0, 1.0);
  }

  // ── الدغدغة: تمرير بطيء متكرر فوق البطن ──
  void _updateTickle(double dt) {
    final p = pointer;
    if (p == null || carriedByUser || dangling || _grabPrimed) {
      _tickle = max(0, _tickle - dt * 2);
      _prevPointer = p;
      return;
    }
    final overAbdomen = (p - (pos + Offset(0, bodyRadius * 0.3))).distance <
        bodyRadius * 1.5;
    if (overAbdomen && _prevPointer != null) {
      final speed = (p - _prevPointer!).distance / max(dt, 0.001);
      if (speed < 45) {
        _tickle += dt;
        if (_tickle > 1.1 && state != SpiderState.tickled) {
          _tickle = 0;
          sinceLastInteraction = 0;
          mood = (mood + 0.03).clamp(0.0, 1.0);
          _enter(SpiderState.tickled);
        }
      } else {
        _tickle = max(0, _tickle - dt);
      }
    } else {
      _tickle = max(0, _tickle - dt * 1.5);
    }
    _prevPointer = p;
  }

  void _updateSparkles(double dt) {
    for (final s in sparkles) {
      s.life -= dt;
      s.pos += s.vel * dt;
      s.vel = Offset(s.vel.dx * (1 - dt * 1.2), s.vel.dy + 14 * dt);
    }
    sparkles.removeWhere((s) => s.life <= 0);
    if (sparkles.length > 40) sparkles.removeRange(0, sparkles.length - 40);
  }

  bool _pointerWasNear = false;

  void _reactToPointer() {
    final finger = pointer;
    if (finger == null ||
        state == SpiderState.carried ||
        state == SpiderState.happy ||
        _grabPrimed) {
      _pointerWasNear = false;
      return;
    }
    final d = (finger - pos).distance;
    final isNear = d < personality.alertRadius;
    if (!isNear) {
      _pointerWasNear = false;
      return;
    }
    if (_pointerWasNear) return;
    _pointerWasNear = true;

    if (state != SpiderState.flee) {
      final shynessEff =
          personality.shyness * (1.3 - mood * 0.6); // مزاج عالٍ = أقل خجلًا
      final wantsFlee = rng.nextDouble() < shynessEff * 0.55 + 0.05;
      if (wantsFlee) {
        _enter(SpiderState.flee);
      } else {
        gaze = finger;
      }
    }
  }

  bool hitTest(Offset p) => (p - pos).distance <= bodyRadius * 2.2;

  void onTap(Offset p) {
    lastTouch = p;
    sinceLastInteraction = 0;
    gaze = p;

    for (final w in webField.webs) {
      final prey = w.preyAt(p);
      if (prey != null) {
        prey.poke();
        w.pluck();
        targetPrey = prey.isFree ? prey : null;
        brow = -1;
        gaze = prey.position;
        return;
      }
    }

    if (hitTest(p)) {
      gentleTouchScore += 1;
      _recordPat(p);
      if (gentleTouchScore >= 2.2) {
        _enter(SpiderState.happy);
        return;
      }
      _reactToDirectTap();
      return;
    }

    // تربيت في المكان المتعلَّم → فرح فوري.
    if (patSpot != null && (p - patSpot!).distance < 30) {
      mood = (mood + 0.1).clamp(0.0, 1.0);
      _enter(SpiderState.happy);
      return;
    }

    final web = webField.webAt(p);
    if (web != null) {
      web.pluck();
      focusWeb = web;
      if (rng.nextDouble() < 0.6) _enter(SpiderState.pluckWeb);
      return;
    }

    if ((p - pos).distance < personality.alertRadius * 2.4) {
      _enter(SpiderState.curious);
    }
  }

  /// تعلّم نمط التربيت: 3 نقرات لطيفة قريبة من نفس المكان.
  void _recordPat(Offset p) {
    if (_lastPatAt != null && (_lastPatAt! - p).distance < 28) {
      _patCount++;
    } else {
      _patCount = 1;
    }
    _lastPatAt = p;
    if (_patCount >= 3) {
      patSpot = p;
      mood = (mood + 0.05).clamp(0.0, 1.0);
    }
  }

  void _reactToDirectTap() {
    final moodBoost = mood * 0.5;
    final options = <SpiderState, double>{
      SpiderState.wave: 1 + (personality.friendliness + moodBoost) * 4,
      SpiderState.hop: 1 + (1 - personality.sleepiness) * 3,
      SpiderState.spin: 1 + personality.friendliness * 2,
      SpiderState.flee: 0.5 + personality.shyness * (1.3 - mood) * 3.5,
      SpiderState.hide: personality.shyness * (1.2 - mood) * 2,
    };
    final total = options.values.fold<double>(0, (a, b) => a + b);
    var r = rng.nextDouble() * total;
    for (final e in options.entries) {
      r -= e.value;
      if (r <= 0) {
        _enter(e.key);
        return;
      }
    }
    _enter(SpiderState.wave);
  }

  void onLongPressStart(Offset p) {
    lastTouch = p;
    sinceLastInteraction = 0;
    pointer = p;
    carriedByUser = true;
    _enter(SpiderState.carried);
  }

  void onPointerMove(Offset p) {
    pointer = p;
    lastTouch = p;
    sinceLastInteraction = 0;
  }

  void onPointerUp() {
    pointer = null;
    _grabPrimed = false;
    if (state == SpiderState.carried) _release();
  }

  void huntDangle() {
    threadAnchor = Offset(lastTouch.dx, padding * 0.3);
    _enter(SpiderState.dangle);
    stateDuration = 2.6;
  }
}

/// أطوار اليوم (من ساعة الجهاز).
enum DayPhase { dawn, day, dusk, night }

// ═════════════════════════════════════════════════════════════════
// بيانات الشباك والفرائس والشخصية
// ═════════════════════════════════════════════════════════════════

enum WebType { orb, corner }

class _PendingWeave {
  final WebType type;
  final Offset center;
  final double radius;
  const _PendingWeave(this.type, this.center, this.radius);
}

class SpiderPersonality {
  final double sleepiness;
  final double friendliness;
  final double shyness;
  final double industriousness;

  const SpiderPersonality({
    required this.sleepiness,
    required this.friendliness,
    required this.shyness,
    required this.industriousness,
  });

  factory SpiderPersonality.random(Random rng) {
    double trait() {
      final a = rng.nextDouble();
      final b = rng.nextDouble();
      return (a * 0.65 + b * 0.35).clamp(0.0, 1.0);
    }

    return SpiderPersonality(
      sleepiness: trait(),
      friendliness: trait(),
      shyness: trait(),
      industriousness: trait(),
    );
  }

  double get baseSpeed => 22.0 + (1.0 - sleepiness) * 26.0;
  double get fleeSpeed => 120.0 + shyness * 140.0;
  double get alertRadius => 46.0 + shyness * 54.0;
  int get maxWebs => 5 + (industriousness * 3).round();
  int get webRadials => 8 + (industriousness * 6).round();
  int get webRings => 3 + (industriousness * 4).round();
  double get webRadiusFactor => 0.13 + industriousness * 0.10;
  double get preyNoticeChance => 0.15 + industriousness * 0.75;

  @override
  String toString() =>
      'SpiderPersonality(sleep: ${sleepiness.toStringAsFixed(2)}, '
          'friend: ${friendliness.toStringAsFixed(2)}, '
          'shy: ${shyness.toStringAsFixed(2)}, '
          'work: ${industriousness.toStringAsFixed(2)})';
}

enum SpiderState {
  wander,
  idleWatch,
  sleep,
  stretch,
  wave,
  dangle,
  weave,
  groom,
  flee,
  curious,
  hide,
  spin,
  hop,
  stalk,
  stalkFly,
  pounce,
  wrapPrey,
  stashPrey,
  pluckWeb,
  peek,
  restOnWeb,
  happy,
  carried,
  // ── الحالات الجديدة v3 ──
  dismantle,  // تفكيك شبكة متقادمة
  watchRain,  // مشاهدة المطر
  awaitPat,   // انتظار التربيت في المكان المتعلَّم
  tickled,    // دغدغة
  photo,      // وضع التصوير
  clinging,   // تشبث بالأرض (اهتزاز الجهاز)
}

class BehaviorContext {
  final bool hasWeb;
  final bool hasFreePrey;
  final bool hasFlyingPrey;
  final bool holdsPrey;
  final bool recentlyTouched;
  final bool canWeaveNow;
  final bool onOwnWeb;
  final bool isNight;
  final bool raining;
  final bool hasFrayedWeb;
  final bool knowsPatSpot;
  final double mood;

  const BehaviorContext({
    this.hasWeb = false,
    this.hasFreePrey = false,
    this.hasFlyingPrey = false,
    this.holdsPrey = false,
    this.recentlyTouched = false,
    this.canWeaveNow = false,
    this.onOwnWeb = false,
    this.isNight = false,
    this.raining = false,
    this.hasFrayedWeb = false,
    this.knowsPatSpot = false,
    this.mood = 0.5,
  });
}

class BehaviorTable {
  final SpiderPersonality p;
  final Random rng;

  BehaviorTable(this.p, this.rng);

  Map<SpiderState, double> weights(BehaviorContext c) {
    final w = <SpiderState, double>{
      SpiderState.wander: 26.0 + (1 - p.sleepiness) * 18,
      SpiderState.idleWatch: 14.0 + p.sleepiness * 8,
      SpiderState.sleep: 3.0 + p.sleepiness * 22,
      SpiderState.wave: 2.0 + p.friendliness * 12 + c.mood * 8,
      SpiderState.dangle: 4.0 + (1 - p.shyness) * 6,
      SpiderState.groom: c.hasWeb ? 4.0 + p.industriousness * 8 : 0.0,
      SpiderState.hide: 1.0 + p.shyness * 9 * (1.3 - c.mood),
      SpiderState.spin: 2.0 + p.friendliness * 4,
      SpiderState.hop: 3.0 + (1 - p.sleepiness) * 7,
      SpiderState.weave: c.canWeaveNow && !c.isNight
          ? 6.0 + p.industriousness * 26
          : 0.0,
      SpiderState.pluckWeb: c.hasWeb ? 3.0 + p.industriousness * 9 : 0.0,
      SpiderState.restOnWeb: c.hasWeb ? 3.0 + p.sleepiness * 10 : 0.0,
      SpiderState.stalk: c.hasFreePrey && !c.isNight
          ? 8.0 + p.industriousness * 30
          : 0.0,
      SpiderState.stalkFly: c.hasFlyingPrey
          ? 10.0 + p.industriousness * 34 + c.mood * 8
          : 0.0,
      SpiderState.stashPrey: c.holdsPrey ? 10.0 + p.industriousness * 14 : 0.0,
      SpiderState.curious: c.recentlyTouched ? 6.0 + p.friendliness * 16 : 0.0,
      // ── v3 ──
      SpiderState.dismantle: c.hasFrayedWeb ? 8.0 + p.industriousness * 16 : 0.0,
      SpiderState.watchRain:
      c.raining ? 14.0 + (1 - p.industriousness) * 10 : 0.0,
      SpiderState.awaitPat:
      c.knowsPatSpot && !c.recentlyTouched ? 10.0 + c.mood * 10 : 0.0,
    };

    // ليلًا: نوم أكثر، حركة أقل.
    if (c.isNight) {
      w[SpiderState.sleep] = (w[SpiderState.sleep] ?? 0) * 2.2;
      w[SpiderState.wander] = (w[SpiderState.wander] ?? 0) * 0.4;
    }
    if (c.recentlyTouched) {
      w[SpiderState.sleep] = (w[SpiderState.sleep] ?? 0) * 0.2;
    }
    w.removeWhere((_, value) => value <= 0);
    return w;
  }

  SpiderState pick(BehaviorContext c) {
    final w = weights(c);
    if (w.isEmpty) return SpiderState.idleWatch;
    final total = w.values.fold<double>(0, (a, b) => a + b);
    var r = rng.nextDouble() * total;
    for (final entry in w.entries) {
      r -= entry.value;
      if (r <= 0) return entry.key;
    }
    return w.keys.last;
  }

  double duration(SpiderState s) {
    double range(double a, double b) => a + rng.nextDouble() * (b - a);
    switch (s) {
      case SpiderState.wander:
        return range(2.5, 6.0);
      case SpiderState.idleWatch:
        return range(1.6, 4.5) * (0.7 + p.sleepiness * 0.9);
      case SpiderState.sleep:
        return range(6.0, 14.0) * (0.6 + p.sleepiness);
      case SpiderState.stretch:
        return range(1.1, 1.8);
      case SpiderState.wave:
        return range(1.4, 2.6);
      case SpiderState.dangle:
        return range(3.5, 7.0);
      case SpiderState.weave:
        return range(6.0, 9.0) * (0.8 + p.industriousness * 0.6);
      case SpiderState.groom:
        return range(2.5, 4.5);
      case SpiderState.flee:
        return range(0.6, 1.2) * (0.5 + p.shyness);
      case SpiderState.curious:
        return range(2.0, 4.0);
      case SpiderState.hide:
        return range(2.5, 5.5) * (0.7 + p.shyness * 0.8);
      case SpiderState.spin:
        return range(0.7, 1.2);
      case SpiderState.hop:
        return range(0.7, 1.1);
      case SpiderState.stalk:
        return range(2.5, 5.0);
      case SpiderState.stalkFly:
        return range(4.0, 7.0);
      case SpiderState.pounce:
        return range(0.55, 0.9);
      case SpiderState.wrapPrey:
        return range(2.2, 3.6);
      case SpiderState.stashPrey:
        return range(3.0, 5.5);
      case SpiderState.pluckWeb:
        return range(1.8, 3.2);
      case SpiderState.peek:
        return range(0.9, 1.6);
      case SpiderState.restOnWeb:
        return range(4.0, 9.0);
      case SpiderState.happy:
        return range(2.2, 3.8);
      case SpiderState.carried:
        return 9999;
    // ── v3 ──
      case SpiderState.dismantle:
        return range(4.0, 6.5);
      case SpiderState.watchRain:
        return range(5.0, 9.0);
      case SpiderState.awaitPat:
        return range(3.5, 6.0);
      case SpiderState.tickled:
        return range(1.2, 1.8);
      case SpiderState.photo:
        return range(1.8, 2.6);
      case SpiderState.clinging:
        return range(1.2, 2.0);
    }
  }
}

class Prey {
  Offset position;
  PreyPhase phase;
  double wrapProgress;
  double jiggle;
  double flutterPhase;
  bool carriedBySpider;
  double timeSinceCocoon = 0;
  final double eatDelay;

  Prey({
    required this.position,
    this.phase = PreyPhase.stuck,
    this.wrapProgress = 0,
    this.jiggle = 1,
    double? flutterPhase,
    this.carriedBySpider = false,
  })  : flutterPhase = flutterPhase ?? Random().nextDouble() * pi * 2,
        eatDelay = 5 + Random().nextDouble() * 9;

  bool get isFree => phase == PreyPhase.stuck;

  void update(double dt) {
    flutterPhase += dt * (phase == PreyPhase.stuck ? 9.0 : 1.5);
    jiggle = max(0, jiggle - dt * 1.4);
    if (phase == PreyPhase.wrapping) {
      wrapProgress = (wrapProgress + dt * 0.42).clamp(0.0, 1.0);
      if (wrapProgress >= 1.0) phase = PreyPhase.cocoon;
    }
    if (phase == PreyPhase.cocoon) {
      timeSinceCocoon += dt;
    }
  }

  void poke() => jiggle = 1.0;

  Offset get shake {
    if (jiggle <= 0) return Offset.zero;
    final a = jiggle * 2.2;
    return Offset(
        sin(flutterPhase * 3.1) * a, cos(flutterPhase * 2.3) * a * 0.7);
  }
}

class SpiderWeb {
  final WebType type;
  final Offset center;
  final double radius;
  final int radials;
  final int rings;
  final double cornerStartAngle;
  final double cornerSweep;
  final List<double> strandLengths;

  double progress;
  double ageSinceComplete;
  double ripple;
  double ripplePhase;
  double nextPreyIn;

  final List<Prey> prey = [];

  /// التقادم: بعد 45 ثانية تبدأ الخيوط بالتمزق بصريًا.
  bool get isFrayed => isComplete && ageSinceComplete > 45;

  /// هاش ثابت لكل خيط — يقرر أي المقاطع "ممزقة".
  int strandHash(int i) =>
      (i * 374761393 + center.dx.round() * 668265263) & 0x7fffffff;

  SpiderWeb({
    required this.type,
    required this.center,
    required this.radius,
    required this.radials,
    required this.rings,
    this.cornerStartAngle = 0,
    this.cornerSweep = pi / 2,
    List<double>? strandLengths,
    this.progress = 0,
    this.ageSinceComplete = 0,
    this.ripple = 0,
    this.ripplePhase = 0,
    this.nextPreyIn = -1,
  }) : strandLengths = strandLengths ?? List.filled(radials, 1.0);

  bool get isComplete => progress >= 1.0;

  void pluck() {
    ripple = 1.0;
    ripplePhase = 0;
  }

  void update(double dt, Random rng, {int maxPrey = 3}) {
    if (isComplete) {
      ageSinceComplete += dt;
      if (nextPreyIn < 0 && prey.length < maxPrey) {
        nextPreyIn = 6 + rng.nextDouble() * 14;
      } else if (nextPreyIn > 0) {
        nextPreyIn -= dt;
        if (nextPreyIn <= 0) {
          _spawnPrey(rng);
          nextPreyIn = prey.length < maxPrey ? 14 + rng.nextDouble() * 18 : -1;
        }
      }
    }
    ripple = max(0, ripple - dt * 0.9);
    ripplePhase += dt * 11;
    for (final p in prey) {
      p.update(dt);
    }
  }

  void _spawnPrey(Random rng) {
    final Offset pos;
    if (type == WebType.corner && radials > 1) {
      final i = rng.nextInt(radials - 1);
      final t = 0.35 + rng.nextDouble() * 0.5;
      final a1 = cornerStartAngle + cornerSweep * (i / (radials - 1));
      final a2 = cornerStartAngle + cornerSweep * ((i + 1) / (radials - 1));
      final p1 = center +
          Offset(cos(a1), sin(a1)) * (radius * strandLengths[i] * t);
      final p2 = center +
          Offset(cos(a2), sin(a2)) * (radius * strandLengths[i + 1] * t);
      pos = Offset.lerp(p1, p2, rng.nextDouble())!;
    } else {
      final a = rng.nextDouble() * pi * 2;
      final r = radius * (0.35 + rng.nextDouble() * 0.5);
      pos = center + Offset(cos(a) * r, sin(a) * r);
    }
    prey.add(Prey(position: pos));
    pluck();
  }

  Prey? get firstFreePrey {
    for (final p in prey) {
      if (p.isFree) return p;
    }
    return null;
  }

  Prey? preyAt(Offset point, {double tolerance = 18}) {
    for (final p in prey) {
      if ((p.position - point).distance <= tolerance) return p;
    }
    return null;
  }
}

class WebField {
  final List<SpiderWeb> webs = [];
  final Random rng;
  final int maxWebs;

  double weaveCooldown;

  WebField(this.rng, {required this.maxWebs})
      : weaveCooldown = 2 + rng.nextDouble() * 3;

  bool get hasWeaveInProgress => webs.any((w) => !w.isComplete);
  bool get canWeave => weaveCooldown <= 0 && !hasWeaveInProgress;

  void update(double dt) {
    if (weaveCooldown > 0) weaveCooldown -= dt;
    for (final w in webs) {
      w.update(dt, rng);
    }
  }

  bool _allowOverlap() => rng.nextDouble() < 0.22;

  ({WebType type, Offset anchor, double size})? chooseWeaveSite(Size size) {
    final wantsCorner = rng.nextDouble() < 0.55;
    final first = wantsCorner ? _findCornerSite(size) : _findOrbSite(size);
    if (first != null) return first;
    return wantsCorner ? _findOrbSite(size) : _findCornerSite(size);
  }

  ({WebType type, Offset anchor, double size})? _findCornerSite(Size size) {
    final base = min(size.width, size.height);
    final corners = [
      Offset(0, 0),
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];
    final order = List<int>.generate(4, (i) => i)..shuffle(rng);
    final allowOverlap = _allowOverlap();
    for (final idx in order) {
      final corner = corners[idx];
      final fanRadius = (base * (0.08 + rng.nextDouble() * 0.34))
          .clamp(base * 0.08, base * 0.42);
      final spacingFactor = allowOverlap ? 0.45 : 1.05;
      final tooClose = webs.any((w) =>
      (w.center - corner).distance <
          (fanRadius + w.radius) * spacingFactor);
      if (!tooClose) {
        return (type: WebType.corner, anchor: corner, size: fanRadius);
      }
    }
    return null;
  }

  ({WebType type, Offset anchor, double size})? _findOrbSite(Size size) {
    final base = min(size.width, size.height);
    final pad = base * 0.10;
    final allowOverlap = _allowOverlap();
    for (var attempt = 0; attempt < 40; attempt++) {
      final candidate = Offset(
        pad + rng.nextDouble() * (size.width - pad * 2),
        pad + rng.nextDouble() * (size.height - pad * 2),
      );
      final radius = (base * (0.05 + rng.nextDouble() * 0.33))
          .clamp(base * 0.05, base * 0.38);
      final spacingFactor = allowOverlap ? 0.5 : 1.1;
      final tooClose = webs.any((w) =>
      (w.center - candidate).distance <
          (radius + w.radius) * spacingFactor);
      if (!tooClose) {
        return (type: WebType.orb, anchor: candidate, size: radius);
      }
    }
    return null;
  }

  SpiderWeb startWeave({
    required WebType type,
    required Offset center,
    required double radius,
    required int radials,
    required int rings,
    required Size containerSize,
  }) {
    late final SpiderWeb web;
    if (type == WebType.corner) {
      final isLeft = center.dx < containerSize.width / 2;
      final isTop = center.dy < containerSize.height / 2;
      double startAngle;
      const sweep = pi / 2;
      if (isTop && isLeft) {
        startAngle = 0;
      } else if (!isTop && isLeft) {
        startAngle = -pi / 2;
      } else if (isTop && !isLeft) {
        startAngle = pi / 2;
      } else {
        startAngle = pi;
      }
      final lengths =
      List<double>.generate(radials, (_) => 0.55 + rng.nextDouble() * 0.45);
      web = SpiderWeb(
        type: WebType.corner,
        center: center,
        radius: radius,
        radials: radials,
        rings: rings,
        cornerStartAngle: startAngle,
        cornerSweep: sweep,
        strandLengths: lengths,
      );
    } else {
      web = SpiderWeb(
          type: WebType.orb,
          center: center,
          radius: radius,
          radials: radials,
          rings: rings);
    }
    webs.add(web);
    weaveCooldown = 4 + rng.nextDouble() * 5;
    _trim();
    return web;
  }

  void _trim() {
    while (webs.length > maxWebs) {
      webs.removeAt(0);
    }
  }

  SpiderWeb? nearestCompleteWeb(Offset from) {
    SpiderWeb? best;
    var bestD = double.infinity;
    for (final w in webs) {
      if (!w.isComplete) continue;
      final d = (w.center - from).distance;
      if (d < bestD) {
        bestD = d;
        best = w;
      }
    }
    return best;
  }

  SpiderWeb? webWithFreePrey(Offset from) {
    SpiderWeb? best;
    var bestD = double.infinity;
    for (final w in webs) {
      if (w.firstFreePrey == null) continue;
      final d = (w.center - from).distance;
      if (d < bestD) {
        bestD = d;
        best = w;
      }
    }
    return best;
  }

  SpiderWeb? webAt(Offset point) {
    for (final w in webs.reversed) {
      if (w.isComplete && (w.center - point).distance <= w.radius) return w;
    }
    return null;
  }

  bool blocks(Offset point, {double margin = 4}) {
    for (final w in webs) {
      if (!w.isComplete) continue;
      if ((w.center - point).distance < w.radius - margin) return true;
    }
    return false;
  }
}

enum PreyPhase { stuck, wrapping, cocoon }

class SpiderPalette {
  final Color body;
  final Color bodyLight;
  final Color bodyDark;
  final Color accent;
  final Color eyeWhite;
  final Color pupil;
  final Color silk;
  final Color shadow;

  const SpiderPalette({
    required this.body,
    required this.bodyLight,
    required this.bodyDark,
    required this.accent,
    required this.eyeWhite,
    required this.pupil,
    required this.silk,
    required this.shadow,
  });
}

// ═════════════════════════════════════════════════════════════════
// الرسّام
// ═════════════════════════════════════════════════════════════════

class SpiderPainter extends CustomPainter {
  final SpiderEngine e;
  final SpiderPalette palette;

  SpiderPainter({required this.e, required this.palette, Listenable? repaint})
      : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    _paintInterior(canvas, size);
    _paintCameo(canvas, size);
    _paintRain(canvas, size);
    _paintCornerCobwebs(canvas, size);
    for (final web in e.webField.webs) {
      _paintWeb(canvas, web);
    }
    _paintPantry(canvas);
    _paintFreeInsects(canvas);
    _paintDust(canvas, size);
    _paintThread(canvas);
    _paintShadow(canvas);
    _paintSpider(canvas);
    _paintSparkles(canvas);
  }

  // ── الداخل حسب طور اليوم ──
  void _paintInterior(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final Color top, mid, bottom;
    double glowA;
    switch (SpiderEngine.dayPhase) {
      case DayPhase.dawn:
        top = const Color(0xFF4A3524);
        mid = const Color(0xFF3A2A1A);
        bottom = const Color(0xFF26170C);
        glowA = 0.22;
        break;
      case DayPhase.day:
        top = const Color(0xFF2B1D10);
        mid = const Color(0xFF3A2817);
        bottom = const Color(0xFF241708);
        glowA = 0.34;
        break;
      case DayPhase.dusk:
        top = const Color(0xFF40251A);
        mid = const Color(0xFF332012);
        bottom = const Color(0xFF20130A);
        glowA = 0.26;
        break;
      case DayPhase.night:
        top = const Color(0xFF14100C);
        mid = const Color(0xFF1A140E);
        bottom = const Color(0xFF100B07);
        glowA = 0.08;
        break;
    }

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, mid, bottom],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect),
    );

    final glow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -1.1),
        radius: 1.35,
        colors: [
          const Color(0xFFFFDFA0).withValues(alpha: glowA),
          const Color(0xFFC97B33).withValues(alpha: glowA * 0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, glow);

    final floorY = size.height * 0.78;
    canvas.drawLine(
      Offset(0, floorY),
      Offset(size.width, floorY),
      Paint()
        ..color = const Color(0xFF6B4A26).withValues(alpha: 0.35)
        ..strokeWidth = 1,
    );
  }

  // ── العنكبوت العابر النادر: ظل أسود يعبر خلف حجاب ──
  void _paintCameo(Canvas canvas, Size size) {
    if (!e.cameoVisible) return;
    final progress = 1 - (e.cameoT / 6.0).clamp(0.0, 1.0);
    final x = e.cameoFromLeft
        ? -40 + progress * (size.width + 80)
        : size.width + 40 - progress * (size.width + 80);
    final y = size.height * 0.3 + sin(progress * pi * 3) * 8;

    // حجاب رمادي خفيف — يعطي إحساس "خلف الشاشة".
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF1A1611).withValues(alpha: 0.25),
    );

    final dark = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    final r = size.shortestSide * 0.045;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: r * 2, height: r * 1.6),
      dark,
    );
    final legP = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final ly = y - r * 0.5 + i * r * 0.35;
      final swing = sin(e.time * 10 + i) * 2;
      canvas.drawLine(Offset(x - r, ly), Offset(x - r * 2, ly - 3 + swing), legP);
      canvas.drawLine(Offset(x + r, ly), Offset(x + r * 2, ly - 3 - swing), legP);
    }
  }

  // ── المطر: خطوط مائلة خافتة خلف الزجاج ──
  void _paintRain(Canvas canvas, Size size) {
    if (!e.raining) return;
    final paint = Paint()
      ..color = const Color(0xFFCFE0EE).withValues(alpha: 0.18)
      ..strokeWidth = 1;
    for (var i = 0; i < 34; i++) {
      final seed = i * 53.7;
      final x = ((sin(seed) * 0.5 + 0.5) * size.width + e.time * 14) %
          size.width;
      final speed = 130 + (i % 5) * 26;
      final y = ((sin(seed * 1.3) * 0.5 + 0.5) * size.height +
          e.time * speed) %
          size.height;
      canvas.drawLine(
        Offset(x, y),
        Offset(x - 2.5, y + 11),
        paint,
      );
    }
    // تعتيم مطري خفيف.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0E141B).withValues(alpha: 0.10),
    );
  }

  void _paintCornerCobwebs(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = palette.silk.withValues(alpha: 0.22);

    void cornerFan(Offset c, double dirX, double dirY, double len) {
      for (var i = 0; i <= 3; i++) {
        final a = atan2(dirY, dirX) + (i - 1.5) * 0.28;
        canvas.drawLine(
          c,
          c + Offset(cos(a), sin(a)) * len * (0.7 + 0.3 * sin(i * 2.3)),
          paint,
        );
      }
      for (var r = 1; r <= 2; r++) {
        final path = Path();
        for (var i = 0; i <= 3; i++) {
          final a = atan2(dirY, dirX) + (i - 1.5) * 0.28;
          final rr = len * 0.45 * r;
          final p = c + Offset(cos(a), sin(a)) * rr;
          if (i == 0) {
            path.moveTo(p.dx, p.dy);
          } else {
            path.quadraticBezierTo(
                (p.dx + c.dx * 0.12), (p.dy + c.dy * 0.12), p.dx, p.dy);
          }
        }
        canvas.drawPath(path, paint);
      }
    }

    cornerFan(Offset.zero, 1, 1, size.shortestSide * 0.22);
    cornerFan(Offset(size.width, 0), -1, 1, size.shortestSide * 0.18);
    cornerFan(Offset(0, size.height), 1, -1, size.shortestSide * 0.16);
  }

  // ── مخزن الفريسة + شارة العدد (الإشعارات غير المقروءة) ──
  void _paintPantry(Canvas canvas) {
    if (e.pantry.isEmpty) return;
    final corner = e.pantryCorner;

    // عناقيد الشرنقة متراكمة في الركن.
    for (var i = 0; i < e.pantry.length; i++) {
      final p = e.pantry[i];
      final at = corner + Offset(-i * 7.0, -i * 3.5) + p.shake * 0.3;
      final r = 4.5 * e.scale;
      canvas.drawOval(
        Rect.fromCenter(center: at, width: r * 2, height: r * 2.8),
        Paint()..color = palette.silk.withValues(alpha: 0.75),
      );
    }

    // شارة عدّ صغيرة كجرس إشعارات.
    final badgeC = corner + const Offset(-4, -2);
    canvas.drawCircle(
      badgeC,
      8,
      Paint()..color =  AppTeal.main.withValues(alpha: 0.9),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: e.pantry.length > 9 ? '9+' : '${e.pantry.length}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, badgeC - Offset(tp.width / 2, tp.height / 2));
  }

  void _paintFreeInsects(Canvas canvas) {
    for (final insect in e.freeInsects) {
      final p = insect.pos;
      final flutter = sin(e.time * 26 + insect.wingPhase);
      final wingPaint = Paint()..color = Colors.white.withValues(alpha: 0.55);

      canvas.drawCircle(
        p,
        9,
        Paint()
          ..color = insect.glow.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      for (final sign in [-1.0, 1.0]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: p + Offset(sign * 3.5, -1 + flutter * 1.2),
            width: 7,
            height: 3 + flutter.abs() * 3,
          ),
          wingPaint,
        );
      }
      canvas.drawOval(
        Rect.fromCenter(center: p, width: 4.5, height: 3),
        Paint()..color = insect.glow.withValues(alpha: 0.95),
      );
      canvas.drawCircle(
        p + const Offset(1.2, -0.5),
        0.8,
        Paint()..color = Colors.white,
      );
    }
  }

  void _paintDust(Canvas canvas, Size size) {
    for (var i = 0; i < 14; i++) {
      final seedA = i * 12.9898;
      final x =
          (sin(seedA) * 0.5 + 0.5) * size.width + sin(e.time * 0.3 + i) * 6;
      final y = ((sin(seedA * 1.7) * 0.5 + 0.5) * size.height +
          sin(e.time * 0.22 + i * 1.3) * 8) %
          size.height;
      final tw = 0.5 + 0.5 * sin(e.time * 1.7 + i * 2.1);
      canvas.drawCircle(
        Offset(x, y),
        0.7 + tw * 0.5,
        Paint()
          ..color =
          const Color(0xFFFFE9C4).withValues(alpha: 0.18 + tw * 0.3),
      );
    }
  }

  void _paintWeb(Canvas canvas, SpiderWeb web) {
    if (web.type == WebType.corner) {
      _paintCornerWeb(canvas, web);
    } else {
      _paintOrbWeb(canvas, web);
    }
    for (final prey in web.prey) {
      if (!prey.carriedBySpider) _paintPrey(canvas, prey);
    }
  }

  /// خيط مقطوع؟ الشباك المتقادمة تفقد مقاطع عشوائية ثابتة.
  bool _strandBroken(SpiderWeb web, int i, int salt) {
    if (!web.isFrayed) return false;
    return ((web.strandHash(i) + salt * 2654435761) & 0x7fffffff) % 5 == 0;
  }

  void _paintOrbWeb(Canvas canvas, SpiderWeb web) {
    final progress = web.progress;
    if (progress <= 0.01) return;
    final strokeBase = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round
      ..color = palette.silk
          .withValues(alpha: web.isFrayed ? 0.35 : 0.55);

    double rippleOffset(double angle, double radius) {
      if (web.ripple <= 0) return 0;
      return sin(web.ripplePhase - radius * 0.12) * web.ripple * 2.6;
    }

    final radialProgress = (progress / 0.45).clamp(0.0, 1.0);
    final radialsVisible = (web.radials * radialProgress).ceil();
    for (var i = 0; i < radialsVisible; i++) {
      if (_strandBroken(web, i, 1)) continue; // خيط شعاعي ممزق
      final a = i * 2 * pi / web.radials;
      final end = web.center +
          Offset(cos(a), sin(a)) * (web.radius + rippleOffset(a, web.radius));
      canvas.drawLine(web.center, end, strokeBase);
    }

    final ringProgress = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
    for (var r = 1; r <= web.rings; r++) {
      final ringT = r / web.rings;
      if (ringT > ringProgress + 0.001) continue;
      final radius = web.radius * (0.25 + 0.75 * ringT);
      final path = Path();
      var started = false;
      for (var i = 0; i <= web.radials; i++) {
        final broken = _strandBroken(web, i % web.radials, 2 + r);
        final a = i * 2 * pi / web.radials;
        final rr = radius + rippleOffset(a, radius);
        final p = web.center + Offset(cos(a) * rr, sin(a) * rr);
        if (broken || !started && broken) {
          started = false;
          continue;
        }
        if (!started) {
          path.moveTo(p.dx, p.dy);
          started = true;
        } else {
          final aMid = a - pi / web.radials;
          final mid =
              web.center + Offset(cos(aMid), sin(aMid)) * (rr * 0.93);
          path.quadraticBezierTo(mid.dx, mid.dy, p.dx, p.dy);
        }
      }
      canvas.drawPath(path, strokeBase);
    }
  }

  void _paintCornerWeb(Canvas canvas, SpiderWeb web) {
    final progress = web.progress;
    if (progress <= 0.01) return;
    final strokeBase = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round
      ..color = palette.silk
          .withValues(alpha: web.isFrayed ? 0.35 : 0.55);

    double rippleOffset(double t) {
      if (web.ripple <= 0) return 0;
      return sin(web.ripplePhase - t * 6) * web.ripple * 2.2;
    }

    final n = web.radials;
    List<double> angles() => List.generate(
        n, (i) => web.cornerStartAngle + web.cornerSweep * (i / (n - 1)));
    final a = angles();

    Offset strandPoint(int i, double growT) {
      final len = web.radius * web.strandLengths[i] * growT;
      return web.center + Offset(cos(a[i]), sin(a[i])) * len;
    }

    final strandProgress = (progress / 0.4).clamp(0.0, 1.0);
    final strandsVisible = (n * strandProgress).ceil().clamp(0, n);
    for (var i = 0; i < strandsVisible; i++) {
      if (_strandBroken(web, i, 1)) continue;
      final grow = (strandProgress * n - i).clamp(0.0, 1.0);
      canvas.drawLine(web.center, strandPoint(i, grow), strokeBase);
    }
    if (strandsVisible < n) return;

    final archProgress = ((progress - 0.35) / 0.65).clamp(0.0, 1.0);
    for (var r = 1; r <= web.rings; r++) {
      final ringT = r / web.rings;
      final revealT = 1 - ringT;
      if (revealT > archProgress + 0.001) continue;

      final path = Path();
      var started = false;
      for (var i = 0; i < n; i++) {
        final broken = _strandBroken(web, i, 2 + r);
        final clamped = ringT.clamp(0.15, 1.0);
        final p = strandPoint(i, clamped) + Offset(0, rippleOffset(ringT));
        if (broken) {
          started = false;
          continue;
        }
        if (!started) {
          path.moveTo(p.dx, p.dy);
          started = true;
        } else {
          final prev = strandPoint(i - 1, clamped);
          final rawMid = Offset.lerp(prev, p, 0.5)!;
          final mid = rawMid + (web.center - rawMid) * 0.12;
          path.quadraticBezierTo(mid.dx, mid.dy, p.dx, p.dy);
        }
      }
      canvas.drawPath(path, strokeBase);
    }
  }

  void _paintPrey(Canvas canvas, Prey prey) {
    final p = prey.position + prey.shake;
    final r = 4.5 * e.scale;
    switch (prey.phase) {
      case PreyPhase.stuck:
        canvas.drawOval(
          Rect.fromCenter(center: p, width: r * 1.6, height: r * 1.1),
          Paint()..color = const Color(0xFF3B2B1A).withValues(alpha: 0.95),
        );
        final flap = sin(prey.flutterPhase) * 0.6 + 0.9;
        for (final sign in [-1.0, 1.0]) {
          canvas.drawOval(
            Rect.fromCenter(
              center: p + Offset(sign * r * 0.9, -r * 0.4),
              width: r * 1.5,
              height: r * flap,
            ),
            Paint()..color = palette.silk.withValues(alpha: 0.55),
          );
        }
        break;
      case PreyPhase.wrapping:
      case PreyPhase.cocoon:
        final t = prey.phase == PreyPhase.cocoon ? 1.0 : prey.wrapProgress;
        final rect = Rect.fromCenter(center: p, width: r * 2.0, height: r * 2.9);
        canvas.drawOval(
          rect,
          Paint()..color = palette.silk.withValues(alpha: 0.35 + t * 0.5),
        );
        final band = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = palette.silk.withValues(alpha: 0.9);
        final bands = (t * 6).floor();
        for (var i = 0; i < bands; i++) {
          final y = rect.top + rect.height * (i + 0.7) / 6.5;
          canvas.drawLine(
            Offset(rect.left + 0.6, y),
            Offset(rect.right - 0.6, y + sin(i * 1.7) * 0.8),
            band,
          );
        }
        break;
    }
  }

  // ── فيزياء الخيط: تمدد وترهل وتمايل ──
  void _paintThread(Canvas canvas) {
    if (!e.dangling || e.threadAnchor == null) return;
    final a = e.threadAnchor!;
    final dist = (a - e.pos).distance;

    // نسبة التمدد: كلما زادت المسافة عن الراحة يشتد الخيط ويستقيم.
    final stretch = (dist / 120.0).clamp(0.0, 2.0);
    final sag = max(0.0, 1 - stretch) * 16; // ترهل عند الارتخاء
    final swing = sin(e.time * 2.2) * (1 - stretch * 0.5).clamp(0.0, 1.0) * 4;

    final mid = Offset(
      (a.dx + e.pos.dx) / 2 + swing,
      (a.dy + e.pos.dy) / 2 + sag,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
    // مشدود أكثر = أرفع وأفتح.
      ..strokeWidth = (1.2 - stretch * 0.4).clamp(0.6, 1.2)
      ..color = palette.silk
          .withValues(alpha: 0.5 + stretch * 0.35);

    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, e.pos.dx, e.pos.dy);
    canvas.drawPath(path, paint);
  }

  void _paintShadow(Canvas canvas) {
    if (e.dangling) return;
    final r = e.bodyRadius;
    final squash = e.squash;
    final w = r * 2.4 / squash;
    final h = r * 0.55 * squash;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(e.pos.dx, e.pos.dy + r * 1.45), width: w, height: h),
      Paint()
        ..color = palette.shadow.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  void _paintSpider(Canvas canvas) {
    canvas.save();
    canvas.translate(e.pos.dx, e.pos.dy);
    canvas.rotate(e.bodyTilt);

    final r = e.bodyRadius;
    final breathScale = 1 + sin(e.breath) * 0.035;
    final squash = e.squash;

    _paintLegs(canvas, r, squash);

    final abdomenCenter = Offset(e.abdomenLag.dx, r * 0.35 + e.abdomenLag.dy);
    final abdomenA = r * 1.08 * breathScale / squash;
    final abdomenB = r * 1.0 * breathScale * squash;
    _FurPainter.paint(
      canvas,
      center: abdomenCenter,
      a: abdomenA,
      b: abdomenB,
      time: e.time,
      palette: palette,
      furSeed: 3,
    );

    final headCenter = Offset(0, -r * 0.85);
    final headR = r * 0.8 * squash;
    _FurPainter.paint(
      canvas,
      center: headCenter,
      a: headR,
      b: headR * 0.92,
      time: e.time + 2.7,
      palette: palette,
      furSeed: 11,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: headCenter + const Offset(0, 1.5),
        width: headR * 1.5,
        height: headR * 1.35,
      ),
      Paint()..color = const Color(0xFFF6E7CD),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: abdomenCenter + Offset(-r * 0.45, -r * 0.35),
        width: r * 0.7,
        height: r * 0.45,
      ),
      Paint()..color = palette.bodyLight.withValues(alpha: 0.4),
    );

    // ── نبض القلب: وميض وردي تحت البطن عند الاقتراب من الزجاج ──
    if (e.nearGlass || e.state == SpiderState.photo) {
      final beat = e.heartBeat;
      if (beat > 0.05) {
        canvas.drawCircle(
          abdomenCenter + Offset(0, abdomenB * 0.55),
          r * (0.18 + beat * 0.16),
          Paint()
            ..color = const Color(0xFFFF6B81).withValues(alpha: 0.45 * beat)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }
    }

    final gazeLocal = _rotate(e.gaze - e.pos, -e.bodyTilt) - headCenter;
    FaceLayer.paint(
      canvas,
      head: headCenter,
      headRadius: headR,
      gazeLocal: gazeLocal,
      eyeClose: e.eyeClose,
      brow: e.brow,
      mouthOpen: e.mouthOpen,
      palette: palette,
    );

    if (e.state == SpiderState.sleep) {
      FaceLayer.paintSleepZs(canvas, headCenter, headR, e.time, palette);
    }

    canvas.restore();
  }

  void _paintLegs(Canvas canvas, double r, double squash) {
    if (e.legs.isEmpty) return;

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(2.6, r * 0.26)
      ..strokeCap = StrokeCap.round
      ..color = palette.bodyDark;

    final fur = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.6, r * 0.16)
      ..strokeCap = StrokeCap.round
      ..color = palette.body;

    final hair = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = palette.bodyDark.withValues(alpha: 0.8);

    final cosT = cos(-e.bodyTilt), sinT = sin(-e.bodyTilt);
    Offset toCanvas(Offset local) => Offset(
      local.dx * cosT - local.dy * sinT + e.pos.dx,
      local.dx * sinT + local.dy * cosT + e.pos.dy,
    );

    final upper = r * 1.05;
    final lower = r * 1.25;
    final wrapping = e.state == SpiderState.wrapPrey;

    for (var i = 0; i < e.legs.length; i++) {
      final leg = e.legs[i];
      final side = i < 4 ? -1.0 : 1.0;
      final idx = i % 4;

      Offset footCanvas;
      if (wrapping) {
        final wPhase = e.walkPhase * 3 + idx * 0.9 + (i.isEven ? 0 : pi * 0.5);
        footCanvas =
            toCanvas(leg.restLocal * 0.7) + Offset(0, sin(wPhase) * r * 0.25);
      } else {
        footCanvas = leg.visualFoot;
        if (leg.stepping) {
          final lift = sin(leg.stepT * pi) * r * 0.45;
          footCanvas = Offset(footCanvas.dx, footCanvas.dy - lift);
        }
      }

      final shoulderLocal = Offset(side * r * 0.5, -r * 0.35 + idx * r * 0.32);
      final shoulder = toCanvas(shoulderLocal);

      var delta = footCanvas - shoulder;
      var d = delta.distance.clamp(1.0, upper + lower - 0.5);
      if (delta.distance > 0.01) delta = delta / delta.distance * d;
      final baseAng = atan2(delta.dy, delta.dx);
      final a1 = acos(
          ((upper * upper + d * d - lower * lower) / (2 * upper * d))
              .clamp(-1.0, 1.0));
      final bendUp = e.surface == Surface.free ? -1.0 : side;
      final kneeAng = baseAng + bendUp * a1;
      final knee = shoulder + Offset(cos(kneeAng), sin(kneeAng)) * upper;
      final foot = shoulder + delta;

      canvas.drawLine(shoulder, knee, outline);
      canvas.drawLine(knee, foot, outline);
      canvas.drawLine(shoulder, knee, fur);
      canvas.drawLine(knee, foot, fur);

      for (var h = 1; h <= 2; h++) {
        final t = h / 3.0;
        final p1 = Offset.lerp(shoulder, knee, t)!;
        final p2 = Offset.lerp(knee, foot, t)!;
        final wob = sin(e.time * 3 + i * 1.7 + h) * 0.35;
        canvas.drawLine(p1, p1 + Offset(-1.8 + wob, -2.2), hair);
        canvas.drawLine(p2, p2 + Offset(-1.8 - wob, -2.0), hair);
      }
    }
  }

  void _paintSparkles(Canvas canvas) {
    for (final s in e.sparkles) {
      final t = (s.life / s.maxLife).clamp(0.0, 1.0);
      final paint = Paint()..color = palette.accent.withValues(alpha: t);
      if (s.heart) {
        final size = 3.2 * e.scale * t;
        final path = Path()
          ..moveTo(s.pos.dx, s.pos.dy + size)
          ..cubicTo(s.pos.dx - size * 1.6, s.pos.dy - size * 0.4,
              s.pos.dx - size * 0.4, s.pos.dy - size * 1.5, s.pos.dx, s.pos.dy - size * 0.5)
          ..cubicTo(s.pos.dx + size * 0.4, s.pos.dy - size * 1.5,
              s.pos.dx + size * 1.6, s.pos.dy - size * 0.4, s.pos.dx, s.pos.dy + size);
        canvas.drawPath(path, paint);
      } else {
        canvas.drawCircle(s.pos, 1.8 * e.scale * t, paint);
      }
    }
  }

  Offset _rotate(Offset v, double a) {
    final c = cos(a), s = sin(a);
    return Offset(v.dx * c - v.dy * s, v.dx * s + v.dy * c);
  }

  @override
  bool shouldRepaint(covariant SpiderPainter oldDelegate) => false;
}

class _FurPainter {
  static void paint(
      Canvas canvas, {
        required Offset center,
        required double a,
        required double b,
        required double time,
        required SpiderPalette palette,
        required int furSeed,
      }) {
    final rect = Rect.fromCenter(center: center, width: a * 2, height: b * 2);
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.22, -0.28),
        radius: 0.9,
        colors: [
          palette.bodyLight,
          palette.body,
          palette.bodyDark,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);

    final spikes = 34;
    final spikePaint = Paint()..color = palette.bodyDark.withValues(alpha: 0.85);
    final spikePath = Path();
    for (var i = 0; i < spikes; i++) {
      final t0 = i / spikes * 2 * pi;
      final t1 = (i + 1) / spikes * 2 * pi;
      final tm = (t0 + t1) / 2;
      final wob = sin(tm * 5 + furSeed + time * 1.1) * 0.05;
      final len = 1.13 + 0.09 * sin(tm * 9 + furSeed * 2.3) + wob;
      final p0 = center + Offset(cos(t0) * a, sin(t0) * b);
      final p1 = center + Offset(cos(t1) * a, sin(t1) * b);
      final tip = center + Offset(cos(tm) * a * len, sin(tm) * b * len);
      spikePath.moveTo(p0.dx, p0.dy);
      spikePath.lineTo(tip.dx, tip.dy);
      spikePath.lineTo(p1.dx, p1.dy);
      spikePath.close();
    }
    canvas.drawPath(spikePath, spikePaint);

    canvas.drawOval(rect, bodyPaint);

    final grain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = palette.bodyDark.withValues(alpha: 0.25);
    for (var i = 0; i < 5; i++) {
      final yy = rect.top + rect.height * (0.2 + i * 0.15);
      final path = Path()
        ..moveTo(rect.center.dx - a * 0.5, yy)
        ..quadraticBezierTo(rect.center.dx, yy + 2, rect.center.dx + a * 0.5, yy);
      canvas.drawPath(path, grain);
    }
  }
}

// ═════════════════════════════════════════════════════════════════
// الوجه
// ═════════════════════════════════════════════════════════════════

class FaceLayer {
  static void paint(
      Canvas canvas, {
        required Offset head,
        required double headRadius,
        required Offset gazeLocal,
        required double eyeClose,
        required double brow,
        required double mouthOpen,
        required SpiderPalette palette,
      }) {
    final eyeR = headRadius * 0.38;
    final eyeDx = headRadius * 0.42;
    final eyeY = head.dy - headRadius * 0.12;
    final leftEye = Offset(head.dx - eyeDx, eyeY);
    final rightEye = Offset(head.dx + eyeDx, eyeY);

    var look = gazeLocal;
    final len = look.distance;
    if (len > 1) look = look / len;
    final pupilShift = look * eyeR * 0.38;

    _eye(canvas, leftEye, eyeR, pupilShift, eyeClose, palette);
    _eye(canvas, rightEye, eyeR, pupilShift, eyeClose, palette);

    _brows(canvas, leftEye, rightEye, eyeR, brow, palette);
    _mouth(canvas, Offset(head.dx, head.dy + headRadius * 0.52), headRadius,
        mouthOpen, palette);
  }

  static void _eye(Canvas canvas, Offset c, double r, Offset shift,
      double close, SpiderPalette palette) {
    final openness = (1 - close).clamp(0.0, 1.0);
    if (openness < 0.06) {
      final p = Paint()
        ..color = palette.pupil
        ..strokeWidth = r * 0.28
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
          Offset(c.dx - r * 0.8, c.dy), Offset(c.dx + r * 0.8, c.dy), p);
      return;
    }
    canvas.save();
    final clip =
    Rect.fromCenter(center: c, width: r * 2.2, height: r * 2 * openness);
    canvas.clipRRect(RRect.fromRectAndRadius(clip, Radius.circular(r)));
    canvas.drawCircle(c, r, Paint()..color = palette.eyeWhite);
    canvas.drawCircle(
      c + Offset(0, r * 0.45),
      r * 0.8,
      Paint()
        ..color = const Color(0xFFC9BBA4).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawCircle(c + shift, r * 0.52, Paint()..color = palette.pupil);
    canvas.drawCircle(
      c + shift + Offset(-r * 0.2, -r * 0.22),
      r * 0.2,
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );
    canvas.drawCircle(
      c + shift + Offset(r * 0.18, r * 0.24),
      r * 0.1,
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
    canvas.restore();
  }

  static void _brows(Canvas canvas, Offset left, Offset right, double eyeR,
      double brow, SpiderPalette palette) {
    final paint = Paint()
      ..color = const Color(0xFF7A431A)
      ..strokeWidth = eyeR * 0.36
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final lift = brow * eyeR * 0.55;
    final tilt = brow < 0 ? -brow * eyeR * 0.5 : 0.0;

    void drawBrow(Offset eye, int sign) {
      final y = eye.dy - eyeR * 1.35 - lift;
      final path = Path()
        ..moveTo(eye.dx - eyeR * 0.85 * sign, y + tilt)
        ..quadraticBezierTo(eye.dx, y - eyeR * 0.35,
            eye.dx + eyeR * 0.85 * sign, y - tilt * 0.2);
      canvas.drawPath(path, paint);
    }

    drawBrow(left, 1);
    drawBrow(right, -1);
  }

  static void _mouth(Canvas canvas, Offset c, double headRadius, double open,
      SpiderPalette palette) {
    final paint = Paint()
      ..color = const Color(0xFF7A431A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = headRadius * 0.11
      ..strokeCap = StrokeCap.round;

    if (open > 0.55) {
      final r = headRadius * (0.14 + open * 0.18);
      canvas.drawOval(
        Rect.fromCenter(center: c, width: r * 1.6, height: r * 2),
        Paint()..color = const Color(0xFF5C3012),
      );
      return;
    }
    final w = headRadius * 0.62;
    final depth = headRadius * (0.22 - open * 0.18);
    final path = Path()
      ..moveTo(c.dx - w / 2, c.dy)
      ..quadraticBezierTo(c.dx, c.dy + depth, c.dx + w / 2, c.dy);
    canvas.drawPath(path, paint);
  }

  static void paintSleepZs(
      Canvas canvas, Offset head, double r, double t, SpiderPalette palette) {
    for (var i = 0; i < 3; i++) {
      final phase = (t * 0.55 + i * 0.33) % 1.0;
      final size = r * (0.5 + i * 0.18);
      final p =
          head + Offset(r * 1.2 + phase * r * 1.4, -r * 1.2 - phase * r * 2.4);
      final paint = Paint()
        ..color = const Color(0xFFF2C98A).withValues(alpha: (1 - phase) * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.12
        ..strokeCap = StrokeCap.round;
      final path = Path()
        ..moveTo(p.dx - size / 2, p.dy - size / 2)
        ..lineTo(p.dx + size / 2, p.dy - size / 2)
        ..lineTo(p.dx - size / 2, p.dy + size / 2)
        ..lineTo(p.dx + size / 2, p.dy + size / 2);
      canvas.drawPath(path, paint);
    }
  }
}

// ═════════════════════════════════════════════════════════════════
// طبقة CRT
// ═════════════════════════════════════════════════════════════════

class _CrtOverlayPainter extends CustomPainter {
  final CrtPowerStage stage;
  final double stageT;
  final double flickerNoise;

  _CrtOverlayPainter({
    required this.stage,
    required this.stageT,
    required this.flickerNoise,
    Listenable? repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rng = Random(31);

    if (stage == CrtPowerStage.on ||
        stage == CrtPowerStage.flickerOff ||
        stage == CrtPowerStage.flickerOn) {
      final scanPaint = Paint()..color = Colors.black.withValues(alpha: 0.16);
      for (var y = 0.0; y < size.height; y += 3) {
        canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1.2), scanPaint);
      }

      final bandY = (stageT * 28) % (size.height + 60) - 30;
      canvas.drawRect(
        Rect.fromLTWH(0, bandY, size.width, 22),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.05)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      final staticPulse = sin(stageT * 1.9 + 4) > 0.93 ||
          (stage == CrtPowerStage.flickerOff && rng.nextDouble() < 0.5);
      if (staticPulse) {
        final noisePaint = Paint()..color = Colors.white.withValues(alpha: 0.10);
        for (var i = 0; i < 90; i++) {
          canvas.drawRect(
            Rect.fromLTWH(
              rng.nextDouble() * size.width,
              rng.nextDouble() * size.height,
              2 + rng.nextDouble() * 5,
              1.2,
            ),
            noisePaint,
          );
        }
      }

      canvas.drawRect(
        rect,
        Paint()
          ..color =
          Colors.amber.withValues(alpha: 0.03 + flickerNoise * 0.03)
          ..blendMode = BlendMode.plus,
      );
    }

    if (stage == CrtPowerStage.collapse) {
      canvas.drawRect(rect, Paint()..color = const Color(0xFF050403));
      final t = stageT.clamp(0.0, 1.0);
      final lineH = (1 - t) * size.height * 0.8;
      final lineW = size.width * (1 - (t * t).clamp(0.0, 0.999));
      final linePaint = Paint()
        ..color = const Color(0xFFFFF3D6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: lineW,
          height: max(2.0, lineH),
        ),
        linePaint,
      );
    }

    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.85,
          colors: [
            Colors.transparent,
            Colors.black
                .withValues(alpha: stage == CrtPowerStage.on ? 0.22 : 0.5),
          ],
          stops: const [0.55, 1.0],
        ).createShader(rect),
    );

    final glass = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..blendMode = BlendMode.plus;
    final glassPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.5, 0)
      ..lineTo(0, size.height * 0.7)
      ..close();
    canvas.drawPath(glassPath, glass);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 7),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(covariant _CrtOverlayPainter oldDelegate) => true;
}

// ═════════════════════════════════════════════════════════════════
// الظلام: عينان تتبعان المؤشر + لمس الزجاج → قفزة وابتسامة خجولة
// ═════════════════════════════════════════════════════════════════

class _DarkRevealPainter extends CustomPainter {
  final double t;
  final Offset? gaze;

  /// وقت آخر لمسة على الزجاج داخل مرحلة reveal (-999 = لا لمس بعد).
  final double touchT;

  _DarkRevealPainter({
    required this.t,
    this.gaze,
    this.touchT = -999,
    Listenable? repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = const Color(0xFF060404));

    final center = Offset(size.width / 2, size.height / 2);
    final baseR = size.shortestSide * 0.16;

    final glintA = ((t - 1.2) / 1.0).clamp(0.0, 1.0);
    final faceA = ((t - 2.2) / 2.3).clamp(0.0, 1.0);

    // لمس الزجاج: نبضة قفزة (0..1 تخبو خلال 0.6 ثانية).
    final sinceTouch = t - touchT;
    final jump = (sinceTouch >= 0 && sinceTouch < 0.6)
        ? (1 - sinceTouch / 0.6) * (1 + 0.5 * sin(sinceTouch * 30) *
        (1 - sinceTouch / 0.6))
        : 0.0;
    // بعد القفزة: ابتسامة خجولة + تلويح خفيف لثانيتين.
    final shy = (sinceTouch >= 0.25 && sinceTouch < 2.6) ? 1.0 : 0.0;

    final push = 1.0 +
        faceA * 0.55 +
        (t > 4.5 ? sin(t * 0.5) * 0.02 : 0.0) +
        jump * 0.45;

    Offset lookDir = Offset.zero;
    if (gaze != null) {
      final toPointer = gaze! - center;
      final d = toPointer.distance;
      if (d > 1) lookDir = toPointer / d;
    } else if (t > 4.5) {
      lookDir = Offset(sin(t * 0.35) * 0.3, 0);
    }

    if (glintA > 0) {
      final eyeDx = baseR * 0.55;
      final glintPaint = Paint()
        ..color = Color.fromRGBO(255, 240, 210, glintA * 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
      canvas.drawCircle(
          Offset(center.dx - eyeDx, center.dy - baseR * 0.1) +
              lookDir * baseR * 0.12,
          2.2,
          glintPaint);
      canvas.drawCircle(
          Offset(center.dx + eyeDx, center.dy - baseR * 0.1) +
              lookDir * baseR * 0.12,
          2.2,
          glintPaint);
    }

    if (faceA > 0) {
      canvas.save();
      canvas.translate(center.dx, center.dy + (1 - faceA) * 10);
      canvas.scale(push);

      final pal = SpiderPalette(
        body: const Color(0xFF3E2410),
        bodyLight: const Color(0xFF573118),
        bodyDark: const Color(0xFF241304),
        accent:  AppTeal.main,
        eyeWhite: const Color(0xFFCFC2AB),
        pupil: const Color(0xFF0A0605),
        silk: const Color(0xFFEBDDBF),
        shadow: const Color(0xFF000000),
      );

      final headR = baseR * 0.95;
      final head = Offset.zero;

      canvas.drawCircle(
        head,
        headR * 2.1,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.5 * faceA)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );

      _FurPainter.paint(
        canvas,
        center: head,
        a: headR,
        b: headR * 0.92,
        time: t,
        palette: pal,
        furSeed: 5,
      );

      canvas.drawOval(
        Rect.fromCenter(
          center: head,
          width: headR * 1.5,
          height: headR * 1.35,
        ),
        Paint()..color = Color.fromRGBO(120, 96, 68, faceA),
      );

      final eyeR = headR * 0.34;
      final eyeDx = headR * 0.44;
      final eyeY = head.dy - headR * 0.12;
      final shift = lookDir * eyeR * 0.4;

      for (final sign in [-1.0, 1.0]) {
        final c = Offset(head.dx + sign * eyeDx, eyeY);
        canvas.drawCircle(c, eyeR,
            Paint()..color = pal.eyeWhite.withValues(alpha: 0.5 * faceA));
        canvas.drawCircle(c + shift, eyeR * 0.55, Paint()..color = pal.pupil);
        canvas.drawCircle(
          c + shift + Offset(-eyeR * 0.2, -eyeR * 0.22),
          eyeR * 0.2,
          Paint()..color = const Color(0xFFFFF0D0).withValues(alpha: faceA),
        );
      }

      final browPaint = Paint()
        ..color = Color.fromRGBO(40, 22, 8, faceA)
        ..strokeWidth = eyeR * 0.38
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (final sign in [-1.0, 1.0]) {
        final c = Offset(head.dx + sign * eyeDx, eyeY);
        final y = c.dy - eyeR * 1.5;
        final path = Path()
          ..moveTo(c.dx - eyeR * 0.85 * sign, y + eyeR * 0.4)
          ..quadraticBezierTo(
              c.dx, y, c.dx + eyeR * 0.85 * sign, y - eyeR * 0.1);
        canvas.drawPath(path, browPaint);
      }

      // الفم: خط جامد، أو ابتسامة خجولة بعد لمس الزجاج.
      final mouthPaint = Paint()
        ..color = Color.fromRGBO(30, 16, 6, faceA)
        ..strokeWidth = headR * 0.1
        ..strokeCap = StrokeCap.round;
      if (shy > 0) {
        final w = headR * 0.55;
        final path = Path()
          ..moveTo(head.dx - w / 2, head.dy + headR * 0.45)
          ..quadraticBezierTo(head.dx, head.dy + headR * 0.75,
              head.dx + w / 2, head.dy + headR * 0.45);
        canvas.drawPath(path, mouthPaint);
      } else {
        canvas.drawLine(
          Offset(head.dx - headR * 0.25, head.dy + headR * 0.5),
          Offset(head.dx + headR * 0.25, head.dy + headR * 0.5),
          mouthPaint,
        );
      }

      // تلويح خجول: ظل رجل رقيقة من أسفل الوجه.
      if (shy > 0) {
        final wave = sin(t * 9) * 0.4;
        final legPaint = Paint()
          ..color = Color.fromRGBO(46, 27, 11, faceA)
          ..strokeWidth = headR * 0.14
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(head.dx + headR * 0.9, head.dy + headR * 0.9),
          Offset(head.dx + headR * (1.7 + wave * 0.3),
              head.dy + headR * (0.3 - wave * 0.6)),
          legPaint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _DarkRevealPainter oldDelegate) => true;
}

