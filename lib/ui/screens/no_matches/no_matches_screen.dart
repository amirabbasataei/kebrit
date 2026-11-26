/// Game over · out of matches (MNoMatches.dc.html): a burnt match with a dying
/// ember and rising smoke, the empty match row, stats and buttons.
///
/// Animation (pure function of seconds): `ember` 2.4 s (opacity .9 → .35 and a
/// shrinking glow, ease-in-out alternate) and three `smoke` blobs of 4 s with
/// 0 / 1.3 / 2.6 s delays (`ease-out`). As in the CSS, a delayed blob shows its
/// *un-animated* style (fully visible, un-moved) until its delay has passed.
/// Reduced flicker = the design's `prefers-reduced-motion`: blobs static at
/// opacity .25, ember at rest.
library;

import 'package:flutter/widgets.dart';

import '../../../data/persian.dart';
import '../../../theme/text_styles.dart';
import '../../../theme/tokens.dart';
import '../../kit/css.dart';
import '../../kit/design_frame.dart';
import '../../kit/flicker.dart';
import '../../kit/loop_clock.dart';
import '../../kit/pill_button.dart';
import '../game/game_controller.dart';

/// Design: 470 with a 1.5-line-height headline that wraps to two lines at
/// 44 px. That pushes the hint paragraph under the retry button, so the block
/// starts at 430, the headline is scaled down to one line and its line height
/// is 1.25.
const _textTop = 430.0;

/// Smoke blob state at [seconds] for a blob with [delay]: opacity, progress
/// along its path (0..1).
({double opacity, double p}) smokeAt(double seconds, double delay) {
  if (seconds < delay) return (opacity: 1, p: 0); // CSS: base style, no animation yet.
  final u = ((seconds - delay) % 4) / 4;
  final p = Curves.easeOut.transform(u);
  final o = u < .2
      ? .55 * Curves.easeOut.transform(u / .2)
      : .55 * (1 - Curves.easeOut.transform((u - .2) / .8));
  return (opacity: o, p: p);
}

/// 0..1 ember dimming at [seconds] (`ember 2.4s ease-in-out alternate`).
double emberAmount(double seconds) {
  final u = (seconds % 2.4) / 2.4;
  return u < .5
      ? Curves.easeInOut.transform(u / .5)
      : 1 - Curves.easeInOut.transform((u - .5) / .5);
}

class NoMatchesScreen extends StatelessWidget {
  const NoMatchesScreen({
    super.key,
    required this.stats,
    this.onRetry,
    this.onLevels,
    this.time,
    this.reduceFlicker,
  });

  final GameStats stats;
  final VoidCallback? onRetry;
  final VoidCallback? onLevels;

  /// Pins the animation clock (goldens/tests).
  final double? time;
  final bool? reduceFlicker;

  @override
  Widget build(BuildContext context) {
    final reduce = reduceFlicker ?? FlickerScope.reduceOf(context);
    final steps = stats.stepsToDoor;
    final status = '${fa(stats.matchesLeft)} از ${fa(stats.startMatches)} باقی مانده'
        '${steps == null ? '' : ' · در ${fa(steps)} قدم دورتر بود'}';

    return LoopClock(
      time: time,
      reduce: reduce,
      builder: (context, t) {
        const blobs = [
          (dx: -22.0, left: 22.0, size: 36.0, alpha: .35, delay: 0.0),
          (dx: 18.0, left: 24.0, size: 32.0, alpha: .30, delay: 1.3),
          (dx: -6.0, left: 20.0, size: 40.0, alpha: .30, delay: 2.6),
        ];
        return DesignFrame(
          children: [
            Positioned.fill(child: _Backdrop()),
            Positioned(
              left: 155,
              top: 110,
              width: 80,
              height: 320,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final b in blobs)
                    () {
                      final s = reduce ? (opacity: .25, p: 0.0) : smokeAt(t, b.delay);
                      return Positioned(
                        left: b.left + b.dx * s.p,
                        top: 120 - 150 * s.p,
                        width: b.size,
                        height: b.size,
                        child: Opacity(
                          opacity: s.opacity,
                          child: Transform.scale(
                            scale: .6 + 1.2 * s.p,
                            child: CustomPaint(painter: _SmokePainter(b.alpha)),
                          ),
                        ),
                      );
                    }(),
                  Positioned(
                    left: 34,
                    top: 168,
                    width: 12,
                    height: 150,
                    child: Transform.rotate(
                      angle: -8 * 3.141592653589793 / 180,
                      alignment: Alignment.topCenter,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF141010),
                              Color(0xFF141010),
                              Color(0xFF3B2C22),
                              Color(0xFF3B2C22),
                              Color(0xFFC9A874),
                              Color(0xFFA98A5E),
                            ],
                            stops: [0, 30 / 150, 30 / 150, 46 / 150, 62 / 150, 1],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 36,
                    top: 160,
                    width: 9,
                    height: 10,
                    child: CustomPaint(
                      painter: _EmberPainter(reduce ? 0 : emberAmount(t)),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              top: _textTop,
              child: Column(
                children: [
                  Text(
                    'گم در تاریکی · مرحله‌ی ${fa(stats.level)}',
                    style: KText.caption.copyWith(color: Kc.dim),
                  ),
                  const SizedBox(height: 14),
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'آخرین شعله هم خاموش شد.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: KFonts.serif,
                        fontSize: 44,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        color: Color(0xFFE8DCCB),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Semantics(
                    image: true,
                    label: 'هر ${fa(stats.startMatches)} کبریت مصرف شد',
                    excludeSemantics: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < stats.startMatches; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          const _BurntMatch(),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: KFonts.ui,
                      fontSize: 14,
                      color: Kc.dim,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'بسته‌های کبریت در بن‌بست‌ها پنهان‌اند. شعله‌ای کوتاه برای پیدا کردنشان می‌تواند اتاق را نجات دهد.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: KFonts.serif,
                      fontSize: 18,
                      height: 1.35,
                      color: Color(0xFFC9B393),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 40,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PillButton(
                    label: 'دوباره تلاش کن',
                    height: 58,
                    glowAlpha: .3,
                    onPressed: onRetry,
                  ),
                  const SizedBox(height: 12),
                  PillButton(
                    label: 'مراحل',
                    variant: PillVariant.outline,
                    height: 50,
                    fontSize: 14,
                    onPressed: onLevels,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// `radial-gradient(circle at 195px 280px, #17110d 0%, #070505 60%)`.
class _Backdrop extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _BackdropPainter(),
        child: const SizedBox.expand(),
      );
}

class _BackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final g = cssRadialFarthestCorner(
      box: size,
      center: const Offset(195, 280),
      stops: const [
        CssStop(Color(0xFF17110D), 0),
        CssStop(Color(0xFF070505), .60),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = g.createShader(rect));
  }

  @override
  bool shouldRepaint(_BackdropPainter o) => false;
}

/// `radial-gradient(circle, rgba(190,175,160,a), rgba(190,175,160,0) 70%)`.
class _SmokePainter extends CustomPainter {
  const _SmokePainter(this.alpha);
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final g = cssRadialFarthestCorner(
      box: size,
      center: size.center(Offset.zero),
      stops: [
        CssStop(rgba(190, 175, 160, alpha), 0),
        CssStop(rgba(190, 175, 160, 0), .70),
      ],
    );
    canvas.drawOval(rect, Paint()..shader = g.createShader(rect));
  }

  @override
  bool shouldRepaint(_SmokePainter o) => o.alpha != alpha;
}

/// 9×10 ember at the match tip; [dim] 0 = bright, 1 = faded
/// (opacity .9 → .35, `0 0 14px 4px .55` → `0 0 6px 1px .25`).
class _EmberPainter extends CustomPainter {
  const _EmberPainter(this.dim);
  final double dim;

  double _l(double a, double b) => a + (b - a) * dim;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = RRect.fromRectXY(rect, size.width / 2, size.height / 2);
    canvas.saveLayer(
      rect.inflate(30),
      Paint()..color = const Color(0xFF000000).withValues(alpha: _l(.9, .35)),
    );
    paintCssShadow(
      canvas,
      shape,
      CssShadow(0, 0, _l(14, 6), _l(4, 1), rgba(255, 90, 30, _l(.55, .25))),
    );
    canvas.drawRRect(shape, Paint()..color = const Color(0xFFFF5A1E));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EmberPainter o) => o.dim != dim;
}

/// 5×24 spent match: `linear-gradient(#141010 0 8px, rgba(224,195,147,.25) 8px)`.
class _BurntMatch extends StatelessWidget {
  const _BurntMatch();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF141010),
              const Color(0xFF141010),
              rgba(224, 195, 147, .25),
              rgba(224, 195, 147, .25),
            ],
            stops: const [0, 8 / 24, 8 / 24, 1],
          ),
        ),
        child: const SizedBox(width: 5, height: 24),
      );
}
