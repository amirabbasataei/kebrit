/// The flame shape used everywhere (MTitle hero, MGame player + strike button).
///
/// ```css
/// border-radius: 50% 50% 50% 50% / 62% 62% 38% 38%;
/// background: radial-gradient(circle at 50% 70%, #fff6c2, #ffb347 45%, #ff7417);
/// box-shadow: 0 0 14px 6px rgba(255,150,50,.55);
/// animation: flame .35s infinite alternate;      /* transform-origin 50% 100% */
/// @keyframes flame { from {scale(1,1) rotate(-4deg)}
///                    to   {scale(1.08,1.18) rotate(4deg)} }
/// ```
///
/// The widget is a `width × height` box; the glow paints outside it (no
/// clipping), so place it in a `Stack(clipBehavior: Clip.none)`. Gradients use
/// the CSS default `farthest-corner` size ([cssRadialFarthestCorner]).
///
/// Flicker: eased alternating scale + rotation about the bottom centre. It
/// stops (and rests at a neutral mid-flicker pose) when [FlickerScope] says
/// reduce flicker, when [flicker] is false, or when [phase] pins a frame.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'css.dart';
import 'flicker.dart';

/// Geometry + colours of one flame variant.
class FlameStyle {
  const FlameStyle({
    required this.width,
    required this.height,
    required this.center,
    required this.stops,
    required this.glow,
    required this.rotateDeg,
    required this.scaleX,
    required this.scaleY,
    required this.duration,
  });

  final double width, height;

  /// Gradient centre as fractions of the box.
  final Offset center;

  /// Gradient stops, `at` = fraction of the farthest-corner radius.
  final List<CssStop> stops;
  final CssShadow glow;

  /// `rotate(-r) → rotate(r)`, `scale(1,1) → scale(1+scaleX, 1+scaleY)`.
  final double rotateDeg, scaleX, scaleY;
  final Duration duration;

  /// MTitle hero flame: 40×80.
  static final title = FlameStyle(
    width: 40,
    height: 80,
    center: const Offset(.5, .74),
    stops: [
      const CssStop(Color(0xFFFFFBE0), 0),
      const CssStop(Color(0xFFFFE08A), .22),
      const CssStop(Color(0xFFFFA13D), .52),
      CssStop(rgba(255, 110, 25, .85), .78),
      CssStop(rgba(255, 90, 20, 0), 1),
    ],
    glow: CssShadow(0, 0, 44, 20, rgba(255, 150, 50, .45)),
    rotateDeg: 3,
    scaleX: .06,
    scaleY: .14,
    duration: const Duration(milliseconds: 400),
  );

  /// MGame player's flame: 8×12.
  static final player = FlameStyle(
    width: 8,
    height: 12,
    center: const Offset(.5, .7),
    stops: const [
      CssStop(Color(0xFFFFF6C2), 0),
      CssStop(Color(0xFFFFB347), .45),
      CssStop(Color(0xFFFF7417), 1),
    ],
    glow: CssShadow(0, 0, 14, 6, rgba(255, 150, 50, .55)),
    rotateDeg: 4,
    scaleX: .08,
    scaleY: .18,
    duration: const Duration(milliseconds: 350),
  );

  /// MGame strike button flame: 10×14.
  static final strikeButton = FlameStyle(
    width: 10,
    height: 14,
    center: const Offset(.5, .7),
    stops: const [
      CssStop(Color(0xFFFFF6C2), 0),
      CssStop(Color(0xFFFFB347), .45),
      CssStop(Color(0xFFFF7417), 1),
    ],
    glow: CssShadow(0, 0, 12, 4, rgba(255, 150, 50, .5)),
    rotateDeg: 4,
    scaleX: .08,
    scaleY: .18,
    duration: const Duration(milliseconds: 350),
  );

  FlameStyle sized(double w, double h) => FlameStyle(
        width: w,
        height: h,
        center: center,
        stops: stops,
        glow: glow,
        rotateDeg: rotateDeg,
        scaleX: scaleX,
        scaleY: scaleY,
        duration: duration,
      );
}

class Flame extends StatelessWidget {
  /// A flame with an explicit [style] (defaults to [FlameStyle.title]).
  const Flame({
    super.key,
    this.style,
    this.flicker = true,
    this.reduceFlicker,
    this.phase,
  }) : _preset = 0;

  const Flame.title({super.key, this.flicker = true, this.reduceFlicker, this.phase})
      : style = null,
        _preset = 0;
  const Flame.player({super.key, this.flicker = true, this.reduceFlicker, this.phase})
      : style = null,
        _preset = 1;
  const Flame.strikeButton(
      {super.key, this.flicker = true, this.reduceFlicker, this.phase})
      : style = null,
        _preset = 2;

  final FlameStyle? style;
  final int _preset;

  /// False = never flicker (static, neutral pose).
  final bool flicker;

  /// Overrides [FlickerScope] (null = inherit).
  final bool? reduceFlicker;

  /// Pins the flicker at this 0..1 phase (goldens / tests).
  final double? phase;

  FlameStyle get _style =>
      style ?? [FlameStyle.title, FlameStyle.player, FlameStyle.strikeButton][_preset];

  @override
  Widget build(BuildContext context) {
    final s = _style;
    final painter = CustomPaint(
      size: Size(s.width, s.height),
      painter: _FlamePainter(s),
    );
    return SizedBox(
      width: s.width,
      height: s.height,
      child: FlickerBuilder(
        duration: s.duration,
        reverse: true,
        phase: flicker ? phase : 0.5,
        reduce: flicker ? reduceFlicker : true,
        restPhase: .5,
        builder: (context, t, live) {
          // Live: the eased 0→1→0 CSS alternate. Static: t is the raw mix.
          final e = live ? Curves.ease.transform(t) : t;
          final sx = 1 + s.scaleX * e, sy = 1 + s.scaleY * e;
          final rot = (-s.rotateDeg + 2 * s.rotateDeg * e) * math.pi / 180;
          return Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.diagonal3Values(sx, sy, 1)..rotateZ(rot),
            child: painter,
          );
        },
      ),
    );
  }
}

class _FlamePainter extends CustomPainter {
  _FlamePainter(this.s);
  final FlameStyle s;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = pctRRect(rect, topH: .5, topV: .62, bottomH: .5, bottomV: .38);
    paintCssShadow(canvas, shape, s.glow);
    final g = cssRadialFarthestCorner(
      box: size,
      center: Offset(s.center.dx * size.width, s.center.dy * size.height),
      stops: s.stops,
    );
    canvas.drawRRect(shape, Paint()..shader = g.createShader(rect));
  }

  @override
  bool shouldRepaint(_FlamePainter o) => o.s != s;
}
