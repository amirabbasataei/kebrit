/// Full-screen light layers.
///
/// * [LightOverlay] – the dark vignette with a hole of light
///   (`radial-gradient(circle at Xpx Ypx, …)` in MGame / MTitle / MPause).
///   `.lit` is MGame with a burning match, `.dark` is MGame without, `.title`
///   and `.pause` are the menu screens. Positions are in the overlay's own
///   coordinate space (pixels from its top-left), as in the CSS, so give it
///   the full screen (390×844).
/// * [WarmFlicker] – the orange glow that pulses with the flame
///   (`.flick` opacity animation, 1.3 s game / 1.6 s title).
/// * [DoorGlow] – the screen-space halo above the exit
///   (`radial-gradient(circle, rgba(255,170,80,.55), rgba(255,170,80,0) 65%)`
///   in a 100×100 box, opacity .8 dark / .25 lit).
///
/// All are `IgnorePointer`s. See `css.dart` for the gradient translation
/// (premultiplied-alpha resampling matters here: the stops fade to
/// `rgba(0,0,0,0)`).
library;

import 'package:flutter/widgets.dart';

import 'css.dart';
import 'flicker.dart';

class LightOverlay extends StatelessWidget {
  /// Custom overlay: [stops] `at` are pixels (`R` = the last one).
  const LightOverlay({super.key, required this.center, required this.stops});

  /// MGame lit: `R = 200 + 6.5·burn`; stops 0 / .3R / .72R / R.
  factory LightOverlay.lit({
    Key? key,
    required Offset center,
    required double burn,
  }) {
    final r = 200 + 6.5 * burn;
    return LightOverlay(
      key: key,
      center: center,
      stops: [
        CssStop(rgba(255, 170, 90, .10), 0),
        CssStop(rgba(0, 0, 0, 0), r * .3),
        CssStop(rgba(8, 5, 3, .55), r * .72),
        CssStop(rgba(6, 4, 3, .95), r),
      ],
    );
  }

  /// MGame dark: almost black beyond a 48 px radius.
  factory LightOverlay.dark({Key? key, required Offset center}) => LightOverlay(
    key: key,
    center: center,
    stops: [CssStop(rgba(6, 4, 3, .45), 0), CssStop(rgba(6, 4, 3, .985), 48)],
  );

  /// MTitle: `circle at 195px 210px, … 0, … 90px, … 280px, … 520px`.
  factory LightOverlay.title({Key? key}) => LightOverlay(
    key: key,
    center: const Offset(195, 210),
    stops: [
      CssStop(rgba(255, 170, 90, .10), 0),
      CssStop(rgba(0, 0, 0, 0), 90),
      CssStop(rgba(8, 5, 3, .62), 280),
      CssStop(rgba(6, 4, 3, .97), 520),
    ],
  );

  /// MPause: `circle at 75px 590px, … 0, … 300px, … 700px`.
  factory LightOverlay.pause({Key? key}) => LightOverlay(
    key: key,
    center: const Offset(75, 590),
    stops: [
      CssStop(rgba(255, 170, 90, .06), 0),
      CssStop(rgba(8, 5, 3, .70), 300),
      CssStop(rgba(6, 4, 3, .94), 700),
    ],
  );

  final Offset center;
  final List<CssStop> stops;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: SizedBox.expand(
      child: CustomPaint(painter: _OverlayPainter(center, stops)),
    ),
  );
}

class _OverlayPainter extends CustomPainter {
  _OverlayPainter(this.center, this.stops);
  final Offset center;
  final List<CssStop> stops;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final g = cssRadialPx(box: size, center: center, stops: stops);
    canvas.drawRect(rect, Paint()..shader = g.createShader(rect));
  }

  @override
  bool shouldRepaint(_OverlayPainter o) =>
      o.center != center || o.stops != stops;
}

/// Warm glow around the light source, pulsing like the flame.
class WarmFlicker extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  WarmFlicker({
    super.key,
    required this.center,
    required this.radius,
    this.alpha = .16,
    this.profile = FlickerProfile.game,
    this.phase,
    this.reduceFlicker,
  });

  /// MGame: `rgba(255,150,60,.16)` to 0 at `180 + 3·burn` px, 1.3 s flick.
  WarmFlicker.game({
    Key? key,
    required Offset center,
    required double burn,
    double? phase,
    bool? reduceFlicker,
  }) : this(
         key: key,
         center: center,
         radius: 180 + 3 * burn,
         phase: phase,
         reduceFlicker: reduceFlicker,
       );

  /// MTitle: `rgba(255,150,60,.22)` to 0 at 300 px, 1.6 s flick.
  const WarmFlicker.title({super.key, this.phase, this.reduceFlicker})
    : center = const Offset(195, 210),
      radius = 300,
      alpha = .22,
      profile = FlickerProfile.title;

  final Offset center;
  final double radius;
  final double alpha;
  final FlickerProfile profile;
  final double? phase;
  final bool? reduceFlicker;

  @override
  Widget build(BuildContext context) => FlickerOpacity(
    profile: profile,
    phase: phase,
    reduce: reduceFlicker,
    child: LightOverlay(
      center: center,
      stops: [
        CssStop(rgba(255, 150, 60, alpha), 0),
        CssStop(rgba(255, 150, 60, 0), radius),
      ],
    ),
  );
}

/// 100×100 halo above the exit door; [opacity] .8 when dark, .25 when lit.
class DoorGlow extends StatelessWidget {
  const DoorGlow({super.key, required this.opacity, this.size = 100});

  final double opacity;
  final double size;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Opacity(
      opacity: opacity,
      child: CustomPaint(size: Size.square(size), painter: _GlowPainter()),
    ),
  );
}

class _GlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final g = cssRadialFarthestCorner(
      box: size,
      center: size.center(Offset.zero),
      stops: [
        CssStop(rgba(255, 170, 80, .55), 0),
        CssStop(rgba(255, 170, 80, 0), .65),
      ],
    );
    canvas.drawOval(rect, Paint()..shader = g.createShader(rect));
  }

  @override
  bool shouldRepaint(_GlowPainter o) => false;
}
