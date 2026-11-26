/// Next-level transition (MTransition.dc.html): the door opens, the player
/// walks into the light, a white flood, black, the level title card and a
/// match being struck.
///
/// One 9 s timeline. In the CSS every element has its own keyframes on the
/// same 9 s `ease-in-out` loop; here each is a [track] over the percentage of
/// the loop (the timing function applies per keyframe interval, like CSS).
/// The design loops; the app plays it **once** and calls [onDone] exactly once
/// (at the end or when «رد شدن» is tapped).
///
/// Clock: live = a [Ticker]; [time] pins a frame (goldens/tests, no ticker,
/// [onDone] never fires from the clock). The timeline is not affected by
/// reduced flicker (the design only drops `bob`/`flicker` for
/// `prefers-reduced-motion`), so [reduceFlicker] only stops the walker's bob
/// and the flames.
library;

import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../../data/levels.dart';
import '../../../data/persian.dart';
import '../../../game/level.dart';
import '../../../theme/text_styles.dart';
import '../../../theme/tokens.dart';
import '../../kit/css.dart';
import '../../kit/design_frame.dart';
import '../../kit/flame.dart';
import '../../kit/flicker.dart';
import '../../kit/pill_button.dart' show ChevronIcon;
import '../tutorial/tutorial_parts.dart' show track;

/// Length of the whole transition.
const kTransitionDuration = Duration(seconds: 9);
const kTransitionSeconds = 9.0;

/// One-line flavour text under the meta line (only level 8's is in the design).
String? transitionFlavor(int levelId) => switch (levelId) {
  8 => 'آن‌ها شنیدن را یاد گرفته‌اند.',
  _ => null,
};

class TransitionScreen extends StatefulWidget {
  const TransitionScreen({
    super.key,
    required this.chapterLabel,
    required this.title,
    required this.meta,
    this.flavor,
    this.onDone,
    this.time,
    this.reduceFlicker,
    this.flickerPhase,
  });

  /// The card for [level] (the level being entered):
  /// «فصل دوم · مرحله‌ی ۸», name, «۵ کبریت · ۳ شکارچی», flavour line.
  factory TransitionScreen.forLevel(
    Level level, {
    Key? key,
    VoidCallback? onDone,
    double? time,
    bool? reduceFlicker,
    double? flickerPhase,
  }) => TransitionScreen(
    key: key,
    chapterLabel:
        '${chapters[chapterIndexOf(level.id)].label} · مرحله‌ی ${fa(level.id)}',
    title: level.name,
    meta:
        '${fa(level.startMatches)} کبریت · ${fa(level.hunterStarts.length)} شکارچی',
    flavor: transitionFlavor(level.id),
    onDone: onDone,
    time: time,
    reduceFlicker: reduceFlicker,
    flickerPhase: flickerPhase,
  );

  final String chapterLabel;
  final String title;
  final String meta;
  final String? flavor;

  /// Called exactly once: when the timeline ends or «رد شدن» is tapped.
  final VoidCallback? onDone;

  /// Pins the timeline at this many seconds (goldens/tests).
  final double? time;
  final bool? reduceFlicker;

  /// Pins the flame flicker (goldens); null = live (or neutral when [time]
  /// is pinned).
  final double? flickerPhase;

  @override
  State<TransitionScreen> createState() => _TransitionScreenState();
}

class _TransitionScreenState extends State<TransitionScreen>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  double _seconds = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    if (widget.time == null) {
      _ticker = createTicker(_onTick)..start();
    }
  }

  void _onTick(Duration d) {
    final s = d.inMicroseconds / 1e6;
    if (s >= kTransitionSeconds) {
      _ticker?.stop();
      setState(() => _seconds = kTransitionSeconds);
      _finish();
    } else {
      setState(() => _seconds = s);
    }
  }

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onDone?.call();
  }

  void _skip() {
    _ticker?.stop();
    _finish();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.time ?? _seconds;
    final pct = (t / kTransitionSeconds * 100).clamp(0.0, 100.0);
    final reduce = widget.reduceFlicker ?? FlickerScope.reduceOf(context);
    final phase = widget.flickerPhase ?? (widget.time != null ? .5 : null);

    double tr(List<(double, double)> keys) => track(pct, keys);

    // --- keyframes (percent of the 9 s loop) -------------------------------
    final door = tr(const [(0, 1), (5, 1), (16, .08)]);
    final doorLight = tr(const [(0, .35), (5, .35), (16, 1)]);

    final walkY = tr(const [(0, 0), (13, 0), (30, -318), (100, -318)]);
    final walkS = tr(const [(0, 1), (13, 1), (30, .42), (100, .42)]);
    final walkO = tr(const [(0, 1), (30, 1), (33, 0), (100, 0)]);
    // `bob .45s infinite` (ease per interval): top-anchored parts rise 4 px.
    final bobU = (t % .45) / .45;
    final bob = reduce
        ? 0.0
        : -4 *
              (bobU < .5
                  ? Curves.ease.transform(bobU / .5)
                  : 1 - Curves.ease.transform((bobU - .5) / .5));

    final flood = tr(const [
      (0, 0),
      (25, 0),
      (34, 1),
      (40, 1),
      (47, 0),
      (100, 0),
    ]);
    final black = tr(const [(0, 0), (38, 0), (45, 1), (93, 1), (100, 0)]);
    final glow = tr(const [
      (0, 0),
      (65, 0),
      (68, 1),
      (72, .75),
      (85, .75),
      (91, 0),
      (100, 0),
    ]);

    final lvlO = tr(const [
      (0, 0),
      (46, 0),
      (52, 1),
      (84, 1),
      (90, 0),
      (100, 0),
    ]);
    final lvlY = tr(const [(0, 10), (46, 10), (52, 0), (100, 0)]);
    final ttlO = tr(const [
      (0, 0),
      (50, 0),
      (57, 1),
      (84, 1),
      (90, 0),
      (100, 0),
    ]);
    final ttlY = tr(const [(0, 14), (50, 14), (57, 0), (100, 0)]);
    final metaO = tr(const [
      (0, 0),
      (56, 0),
      (62, 1),
      (84, 1),
      (90, 0),
      (100, 0),
    ]);

    final stickO = tr(const [
      (0, 0),
      (65, 0),
      (67, 1),
      (86, 1),
      (90, 0),
      (100, 0),
    ]);
    final strikeO = stickO;
    final strikeS = tr(const [
      (0, .2),
      (65, .2),
      (67, 1.7),
      (71, 1),
      (86, 1),
      (90, .6),
      (100, .6),
    ]);

    ({double o, double x, double y}) spark(double end, double dx, double dy) =>
        (
          o: tr([(0, 0), (65, 0), (66, 1), (end, 0), (100, 0)]),
          x: tr([(0, 0), (65, 0), (end, dx), (100, dx)]),
          y: tr([(0, 0), (65, 0), (end, dy), (100, dy)]),
        );
    final s1 = spark(71, -46, -30);
    final s2 = spark(71, 40, -40);
    final s3 = spark(72, 10, -58);

    return DesignFrame(
      children: [
        // z1: the cellar
        const Positioned.fill(child: CustomPaint(painter: _CellarPainter())),
        Positioned(
          left: 0,
          top: 410,
          width: 390,
          height: 434,
          child: Opacity(
            opacity: doorLight,
            child: ClipPath(
              clipper: const PolygonClipper([
                Offset(.32, 0),
                Offset(.68, 0),
                Offset(1, 1),
                Offset(0, 1),
              ]),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x66FFBE6E), Color(0x00FFAA5A)],
                    stops: [0, .9],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 113,
          top: 168,
          width: 164,
          height: 242,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFF120D0A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(82)),
              boxShadow: [
                BoxShadow(color: Color(0xFF2A2019), spreadRadius: 16),
                BoxShadow(color: Color(0xFF4D3D30), spreadRadius: 14),
              ],
            ),
          ),
        ),
        Positioned(
          left: 125,
          top: 180,
          width: 140,
          height: 230,
          child: Opacity(
            opacity: doorLight,
            child: const CustomPaint(painter: _DoorGlowPainter()),
          ),
        ),
        Positioned(
          left: 125,
          top: 180,
          width: 140,
          height: 230,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(70)),
            child: Transform.scale(
              scaleX: door,
              scaleY: 1,
              alignment: Alignment.centerLeft,
              child: const CustomPaint(painter: _DoorLeafPainter()),
            ),
          ),
        ),
        Positioned(
          left: 165,
          top: 640,
          width: 60,
          height: 88,
          child: Opacity(
            opacity: walkO,
            child: Transform.translate(
              offset: Offset(0, walkY),
              child: Transform.scale(
                scale: walkS,
                alignment: Alignment.bottomCenter,
                child: _Walker(bob: bob, reduce: reduce, phase: phase),
              ),
            ),
          ),
        ),

        // z2: white flood, z3: black
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: flood,
              child: const CustomPaint(painter: _FloodPainter()),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: black,
              child: const ColoredBox(color: Kc.page),
            ),
          ),
        ),

        // z4: warm glow under the match
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: glow,
              child: const CustomPaint(painter: _MatchGlowPainter()),
            ),
          ),
        ),

        // z5: title card
        Positioned(
          left: 24,
          right: 24,
          top: 230,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: lvlO,
                child: Transform.translate(
                  offset: Offset(0, lvlY),
                  child: Text(
                    widget.chapterLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: KFonts.ui,
                      fontSize: 11,
                      color: Kc.muted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Opacity(
                opacity: ttlO,
                child: Transform.translate(
                  offset: Offset(0, ttlY),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: KFonts.serif,
                        fontSize: 64,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                        color: Color(0xFFF6EAD6),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14 + 8),
              Opacity(
                opacity: metaO,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.meta,
                      textAlign: TextAlign.center,
                      style: _metaStyle,
                    ),
                    if (widget.flavor != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.flavor!,
                        textAlign: TextAlign.center,
                        style: _metaStyle,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // z5: the match being struck
        Positioned(
          left: 175,
          top: 500,
          width: 40,
          height: 140,
          child: ExcludeSemantics(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 17,
                  top: 48,
                  width: 6,
                  height: 90,
                  child: Opacity(
                    opacity: stickO,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFE9CD9C), Color(0xFFC9A874)],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 13,
                  top: 38,
                  width: 14,
                  height: 16,
                  child: Opacity(
                    opacity: stickO,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFF3A120C),
                        borderRadius: BorderRadius.all(Radius.elliptical(7, 8)),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: -4,
                  width: 24,
                  height: 48,
                  child: Opacity(
                    opacity: strikeO,
                    child: Transform.scale(
                      scale: strikeS,
                      alignment: Alignment.bottomCenter,
                      child: Flame(
                        style: _strikeFlame,
                        reduceFlicker: reduce,
                        phase: phase,
                      ),
                    ),
                  ),
                ),
                for (final (s, left, top, size, color) in [
                  (s1, 18.0, 36.0, 3.0, const Color(0xFFFFD27A)),
                  (s2, 20.0, 36.0, 3.0, const Color(0xFFFFB45A)),
                  (s3, 19.0, 34.0, 2.0, const Color(0xFFFFF1B8)),
                ])
                  Positioned(
                    left: left + s.x,
                    top: top + s.y,
                    width: size,
                    height: size,
                    child: Opacity(
                      opacity: s.o,
                      child: ColoredBox(color: color),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // z6: skip
        Positioned(
          left: 24,
          bottom: 40,
          child: Semantics(
            button: true,
            label: 'رد شدن',
            excludeSemantics: true,
            onTap: _skip,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _skip,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: rgba(239, 227, 208, .22)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'رد شدن',
                      style: TextStyle(
                        fontFamily: KFonts.ui,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Kc.muted,
                      ),
                    ),
                    SizedBox(width: 8),
                    ChevronIcon(size: 12, color: Kc.muted),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

const _metaStyle = TextStyle(
  fontFamily: KFonts.serif,
  fontSize: 20,
  color: Kc.serifSub,
);

/// `.strike` flame: 24×48, `radial-gradient(circle at 50% 74%, …)`,
/// `0 0 40px 16px rgba(255,150,50,.5)`, `flicker .4s`.
final _strikeFlame = FlameStyle(
  width: 24,
  height: 48,
  center: const Offset(.5, .74),
  stops: [
    const CssStop(Color(0xFFFFFBE0), 0),
    const CssStop(Color(0xFFFFE08A), .25),
    const CssStop(Color(0xFFFFA13D), .55),
    CssStop(rgba(255, 100, 20, .9), .85),
  ],
  glow: CssShadow(0, 0, 40, 16, rgba(255, 150, 50, .5)),
  rotateDeg: 3,
  scaleX: .07,
  scaleY: .15,
  duration: const Duration(milliseconds: 400),
);

/// The walker's flame: 16×24, `0 0 22px 8px rgba(255,150,50,.5)`.
final _walkerFlame = FlameStyle(
  width: 16,
  height: 24,
  center: const Offset(.5, .7),
  stops: const [
    CssStop(Color(0xFFFFF6C2), 0),
    CssStop(Color(0xFFFFB347), .45),
    CssStop(Color(0xFFFF7417), 1),
  ],
  glow: CssShadow(0, 0, 22, 8, rgba(255, 150, 50, .5)),
  rotateDeg: 3,
  scaleX: .07,
  scaleY: .15,
  duration: const Duration(milliseconds: 400),
);

/// The 60×88 walking figure. [bob] (0..-4) lifts the parts anchored to the
/// top (head, match, flame) while the body and shadow stay put (CSS `bob`
/// animates `margin-top` of an `inset: 0` box).
class _Walker extends StatelessWidget {
  const _Walker({required this.bob, required this.reduce, required this.phase});
  final double bob;
  final bool reduce;
  final double? phase;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 4,
          top: 74,
          width: 52,
          height: 14,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: rgba(0, 0, 0, .5),
              borderRadius: const BorderRadius.all(Radius.elliptical(26, 7)),
            ),
          ),
        ),
        const Positioned(
          left: 10,
          top: 30,
          width: 40,
          height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF9A8268), Color(0xFF6B5744)],
              ),
            ),
          ),
        ),
        Positioned(
          left: 14,
          top: 12 + bob,
          width: 32,
          height: 32,
          child: const CustomPaint(painter: _HeadPainter()),
        ),
        Positioned(
          left: 48,
          top: 26 + bob,
          width: 5,
          height: 26,
          child: Transform.rotate(
            angle: 14 * math.pi / 180,
            child: const ColoredBox(color: Kc.matchStick),
          ),
        ),
        Positioned(
          left: 44,
          top: 4 + bob,
          width: 16,
          height: 24,
          child: Flame(
            style: _walkerFlame,
            reduceFlicker: reduce,
            phase: phase,
          ),
        ),
      ],
    );
  }
}

/// 32 px circle `#7a6550` with `inset 0 10px 0 #3a2c20` (the top cap).
class _HeadPainter extends CustomPainter {
  const _HeadPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final disc = Path()..addOval(rect);
    canvas.drawPath(disc, Paint()..color = const Color(0xFF7A6550));
    final cap = Path.combine(
      PathOperation.difference,
      disc,
      Path()..addOval(rect.shift(const Offset(0, 10))),
    );
    canvas.drawPath(cap, Paint()..color = const Color(0xFF3A2C20));
  }

  @override
  bool shouldRepaint(_HeadPainter o) => false;
}

/// Wall (`#241b15` + 48 px rows / 96 px joints over `#2e241c → #17110d`) and
/// the floor from y = 410 (`#1e1712`, 2 px lines every 40 px).
class _CellarPainter extends CustomPainter {
  const _CellarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final all = Offset.zero & size;
    canvas.drawRect(
      all,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2E241C), Color(0xFF17110D)],
        ).createShader(all),
    );
    final h = Paint()..color = rgba(0, 0, 0, .55);
    final v = Paint()..color = rgba(0, 0, 0, .45);
    for (var y = 0.0; y < size.height; y += 48) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 3), h);
      for (var x = 0.0; x < size.width; x += 96) {
        canvas.drawRect(Rect.fromLTWH(x, y, 3, 48), v);
      }
    }
    canvas.drawRect(
      Rect.fromLTRB(0, 410, size.width, size.height),
      Paint()..color = const Color(0xFF1E1712),
    );
    final f = Paint()..color = rgba(0, 0, 0, .35);
    for (var y = 410.0; y < size.height; y += 40) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 2), f);
    }
  }

  @override
  bool shouldRepaint(_CellarPainter o) => false;
}

/// The lit doorway: `radial-gradient(ellipse at 50% 85%, #fffaf0 0, #ffe3ac 30%,
/// #ffb15a 65%, #d9691c 100%)` + `0 0 110px 36px rgba(255,160,70,.35)`.
class _DoorGlowPainter extends CustomPainter {
  const _DoorGlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = RRect.fromRectAndCorners(
      rect,
      topLeft: const Radius.circular(70),
      topRight: const Radius.circular(70),
    );
    paintCssShadow(
      canvas,
      shape,
      CssShadow(0, 0, 110, 36, rgba(255, 160, 70, .35)),
    );
    final g = cssEllipseFarthestCorner(
      box: size,
      center: Offset(size.width * .5, size.height * .85),
      stops: const [
        CssStop(Color(0xFFFFFAF0), 0),
        CssStop(Color(0xFFFFE3AC), .30),
        CssStop(Color(0xFFFFB15A), .65),
        CssStop(Color(0xFFD9691C), 1),
      ],
    );
    canvas.drawRRect(shape, Paint()..shader = g.createShader(rect));
  }

  @override
  bool shouldRepaint(_DoorGlowPainter o) => false;
}

/// Door leaf: `#5a3a22`, 2 px dark boards every 40 px over
/// `linear-gradient(90deg, #6b4529, #4a2f1b)`, brass knob at right 16 / top 130.
class _DoorLeafPainter extends CustomPainter {
  const _DoorLeafPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = const Color(0xFF5A3A22));
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF6B4529), Color(0xFF4A2F1B)],
        ).createShader(rect),
    );
    final board = Paint()..color = rgba(0, 0, 0, .35);
    for (var x = 0.0; x < size.width; x += 40) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 2, size.height), board);
    }
    canvas.drawCircle(
      Offset(size.width - 16 - 5, 130 + 5),
      5,
      Paint()..color = const Color(0xFFC9A25F),
    );
  }

  @override
  bool shouldRepaint(_DoorLeafPainter o) => false;
}

/// `radial-gradient(circle at 195px 300px, #fffdf6 0%, #ffe9c2 45%, #ffc27a 100%)`.
class _FloodPainter extends CustomPainter {
  const _FloodPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final g = cssRadialFarthestCorner(
      box: size,
      center: const Offset(195, 300),
      stops: const [
        CssStop(Color(0xFFFFFDF6), 0),
        CssStop(Color(0xFFFFE9C2), .45),
        CssStop(Color(0xFFFFC27A), 1),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = g.createShader(rect));
  }

  @override
  bool shouldRepaint(_FloodPainter o) => false;
}

/// `radial-gradient(circle at 195px 560px, rgba(255,150,60,.3) 0, rgba(255,150,60,0) 300px)`.
class _MatchGlowPainter extends CustomPainter {
  const _MatchGlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final g = cssRadialPx(
      box: size,
      center: const Offset(195, 560),
      stops: [
        CssStop(rgba(255, 150, 60, .3), 0),
        CssStop(rgba(255, 150, 60, 0), 300),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = g.createShader(rect));
  }

  @override
  bool shouldRepaint(_MatchGlowPainter o) => false;
}
