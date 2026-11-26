/// Splash (MSplash.dc.html): the match ignites, the logo rises, a fuse loads.
///
/// All animation is a pure function of the elapsed time [SplashScene.t]
/// (seconds), mirroring the CSS keyframes and delays:
///
/// | element | CSS | timing |
/// |---|---|---|
/// | stone + vignette `.glow` | opacity 0→1, ease-out | .9 s @ .6 s |
/// | sparks `.s1–.s4` | opacity/translate, ease-out | .45–.55 s @ .4–.46 s |
/// | flame `.ignite` | scale .15→1.5→1, opacity 0→1, ease-out | .5 s @ .5 s |
/// | flame `.flicker` | scale(1.07,1.15) rotate ±3°, ease-in-out | .4 s loop |
/// | logo `.logo` | rise (opacity, translateY 14→0), ease-out | .7 s @ 1.2 s |
/// | tagline `.tag` | rise | .7 s @ 1.8 s |
/// | `.fuse` | width 0→100 %, linear | 2.4 s @ .2 s |
/// | `.loader` | opacity 1→0, ease-in | .3 s @ 2.7 s |
/// | `.tap` | rise | .5 s @ 2.9 s |
/// | `.tapin` | opacity .9↔.4, ease-in-out | 1.8 s loop @ 3.4 s |
///
/// [SplashScreen] drives the scene with a [Ticker]; goldens/tests pin the
/// time with [SplashScreen.time]. The whole screen is the tap target
/// (`onStart`). Reduced flicker (`FlickerScope`) freezes the flame pose and
/// the tap-hint pulse, as `prefers-reduced-motion` does.
library;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../../theme/text_styles.dart';
import '../../../theme/tokens.dart';
import '../../kit/css.dart';
import '../../kit/flame.dart';
import '../../kit/flicker.dart';
import '../../kit/stone_bg.dart';

/// Seconds until every one-shot animation has finished (tap hint settled).
const kSplashSettleSeconds = 3.4;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onStart, this.time, this.reduceFlicker});

  /// Tap anywhere → Benefits (first launch) or Title.
  final VoidCallback? onStart;

  /// Pins the timeline (goldens/tests). Null = live clock.
  final Duration? time;

  /// Overrides [FlickerScope].
  final bool? reduceFlicker;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  double _t = 0;

  @override
  void initState() {
    super.initState();
    if (widget.time == null) {
      _ticker = createTicker((d) => setState(() => _t = d.inMicroseconds / 1e6))
        ..start();
    }
  }

  @override
  void didUpdateWidget(SplashScreen old) {
    super.didUpdateWidget(old);
    if (widget.time != null && _ticker != null) {
      _ticker!.dispose();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = widget.reduceFlicker ?? FlickerScope.reduceOf(context);
    // With reduced motion nothing loops: stop the clock once settled.
    if (reduce && _ticker != null && _t > kSplashSettleSeconds + .1) {
      _ticker!.stop();
    }
    final t = widget.time != null ? widget.time!.inMicroseconds / 1e6 : _t;
    return Semantics(
      button: true,
      label: 'شروع بازی',
      onTap: widget.onStart,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onStart,
        child: ColoredBox(
          color: Kc.deep,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: Kc.designWidth,
              height: Kc.designHeight,
              child: SplashScene(t: t, reduceFlicker: reduce),
            ),
          ),
        ),
      ),
    );
  }
}

/// `animation-timing-function` shortcuts.
double _ease(Curve c, double f) => c.transform(f.clamp(0.0, 1.0));

/// Fraction 0..1 of an animation with [delay] and [dur] (seconds) at [t].
double _frac(double t, double delay, double dur) =>
    ((t - delay) / dur).clamp(0.0, 1.0);

/// The 390×844 splash picture at time [t] seconds.
class SplashScene extends StatelessWidget {
  const SplashScene({super.key, required this.t, this.reduceFlicker = false});

  final double t;
  final bool reduceFlicker;

  /// `rise`: opacity 0→1 and translateY(14→0), ease-out, `both`.
  Widget _rise(double delay, double dur, Widget child) {
    final p = _ease(Curves.easeOut, _frac(t, delay, dur));
    return Opacity(
      opacity: p,
      child: Transform.translate(offset: Offset(0, 14 * (1 - p)), child: child),
    );
  }

  /// The flicker keyframes (0 %/100 % pose A, 50 % pose B), ease-in-out per
  /// half cycle. Returns the 0..1 mix between the two poses.
  double get _flickerMix {
    if (reduceFlicker) return .5;
    final x = (t / .4) % 1.0;
    final half = x < .5 ? x * 2 : 2 - x * 2;
    return Curves.easeInOut.transform(half);
  }

  Widget _spark(
    double left,
    double top,
    double size,
    Color color,
    double delay,
    double dur,
    double dx,
    double dy,
  ) {
    final f = _frac(t, delay, dur);
    if (t < delay || f >= 1) return const SizedBox.shrink();
    final opacity = f < .1
        ? _ease(Curves.easeOut, f / .1)
        : 1 - _ease(Curves.easeOut, (f - .1) / .9);
    final move = _ease(Curves.easeOut, f);
    return Positioned(
      left: left + dx * move,
      top: top + dy * move,
      width: size,
      height: size,
      child: Opacity(
        opacity: opacity,
        child: ColoredBox(color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glow = _ease(Curves.easeOut, _frac(t, .6, .9));

    // `.ignite`: opacity + scale keyframes at 0 / 45 % / 100 %.
    final ig = _frac(t, .5, .5);
    final igOpacity = ig < .45 ? _ease(Curves.easeOut, ig / .45) : 1.0;
    final igScale = ig < .45
        ? .15 + (1.5 - .15) * _ease(Curves.easeOut, ig / .45)
        : 1.5 - .5 * _ease(Curves.easeOut, (ig - .45) / .55);

    // `.loader` fade and `.fuse` growth.
    final loaderOpacity = 1 - _ease(Curves.easeIn, _frac(t, 2.7, .3));
    final fuse = _frac(t, .2, 2.4);

    // `.tapin` pulse starts at 3.4 s (no fill before); static when reduced.
    var tapOpacity = 1.0;
    if (!reduceFlicker && t >= 3.4) {
      final x = ((t - 3.4) / 1.8) % 1.0;
      final half = x < .5 ? x * 2 : 2 - x * 2;
      tapOpacity = .9 - .5 * Curves.easeInOut.transform(half);
    }

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // Stone wall + vignette fade in together (two `.glow` layers).
        Positioned.fill(
          child: Opacity(opacity: glow, child: const StoneBackground()),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: glow,
            child: CustomPaint(painter: _VignettePainter()),
          ),
        ),

        // The match: 40×230 box at (175, 250).
        Positioned(
          left: 175,
          top: 250,
          width: 40,
          height: 230,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 16,
                top: 58,
                width: 8,
                height: 170,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFFE9CD9C), Color(0xFFC9A874)],
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 10,
                top: 42,
                width: 20,
                height: 24,
                child: CustomPaint(painter: _MatchHeadPainter()),
              ),
              Positioned(
                left: 0,
                top: -28,
                width: 40,
                height: 80,
                child: Opacity(
                  opacity: igOpacity,
                  child: Transform.scale(
                    scale: igScale,
                    alignment: Alignment.bottomCenter,
                    child: Flame(style: _flameStyle, phase: _flickerMix),
                  ),
                ),
              ),
              _spark(19, 46, 3, const Color(0xFFFFD27A), .4, .45, -40, -34),
              _spark(21, 46, 3, const Color(0xFFFFB45A), .42, .5, 36, -44),
              _spark(20, 44, 2, const Color(0xFFFFF1B8), .4, .55, 6, -60),
              _spark(18, 45, 2, const Color(0xFFFFD27A), .46, .5, -18, -56),
            ],
          ),
        ),

        // Logo + tagline.
        Positioned(
          left: 24,
          right: 24,
          top: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _rise(
                1.2,
                .7,
                const Text(
                  'کبریت',
                  style: KText.logoSplash,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 6),
              _rise(
                1.8,
                .7,
                const Text(
                  'هر شعله، هم راه است و هم خطر.',
                  style: KText.tagline,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),

        // Fuse loader: 200×2 at the bottom, the fuse grows from the right.
        Positioned(
          left: 95,
          right: 95,
          bottom: 96,
          height: 2,
          child: Opacity(
            opacity: loaderOpacity,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned.fill(
                  child: ColoredBox(color: Color(0x1AEFE3D0)),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 200 * fuse,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [Kc.flameLight, Kc.flameHot],
                      ),
                      boxShadow: cssBoxShadows([
                        CssShadow(0, 0, 8, 0, rgba(255, 150, 50, .8)),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // "Tap to start" hint and studio placeholder.
        Positioned(
          left: 0,
          right: 0,
          bottom: 84,
          child: _rise(
            2.9,
            .5,
            Opacity(
              opacity: tapOpacity,
              child: const Text(
                'برای شروع، صفحه را لمس کن',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: KFonts.ui,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Kc.muted,
                ),
              ),
            ),
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 40,
          child: Text(
            '[نام استودیو]',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: KFonts.ui,
              fontSize: 12,
              color: Color(0xFF8C7864),
            ),
          ),
        ),
      ],
    );
  }
}

/// `.flicker` flame: 40×80, scale(1.07,1.15) rotate ±3° (the glow is the
/// splash's 44 px / 20 px spread).
final _flameStyle = FlameStyle(
  width: 40,
  height: 80,
  center: const Offset(.5, .74),
  stops: FlameStyle.title.stops,
  glow: FlameStyle.title.glow,
  rotateDeg: 3,
  scaleX: .07,
  scaleY: .15,
  duration: const Duration(milliseconds: 400),
);

/// `radial-gradient(circle at 195px 300px, rgba(255,170,90,.14) 0, rgba(0,0,0,0)
/// 70px, rgba(8,5,3,.7) 250px, #070504 470px)`.
class _VignettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final g = cssRadialPx(
      box: size,
      center: const Offset(195, 300),
      stops: [
        CssStop(rgba(255, 170, 90, .14), 0),
        CssStop(rgba(0, 0, 0, 0), 70),
        CssStop(rgba(8, 5, 3, .7), 250),
        const CssStop(Kc.deep, 470),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = g.createShader(rect));
  }

  @override
  bool shouldRepaint(_VignettePainter o) => false;
}

/// Match head: 20×24, `border-radius: 50% 50% 45% 45%`,
/// `radial-gradient(circle at 40% 35%, #c8402e, #5a160d)`.
class _MatchHeadPainter extends CustomPainter {
  const _MatchHeadPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = pctRRect(rect, bottomH: .45, bottomV: .45);
    final g = cssRadialFarthestCorner(
      box: size,
      center: Offset(size.width * .4, size.height * .35),
      stops: const [CssStop(Kc.ember, 0), CssStop(Color(0xFF5A160D), 1)],
    );
    canvas.drawRRect(shape, Paint()..shader = g.createShader(rect));
  }

  @override
  bool shouldRepaint(_MatchHeadPainter o) => false;
}
