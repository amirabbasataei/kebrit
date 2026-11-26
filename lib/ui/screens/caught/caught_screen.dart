/// Game over · caught (MCaught.dc.html): the looming hunter with blinking
/// eyes, two stats, a hint box and retry / levels buttons.
///
/// Animation (pure function of seconds, see [LoopClock]): `loom` 5 s
/// (translateY −5 px, scale 1.01 about the bottom centre, ease-in-out
/// alternate) and `blink` 4.5 s (scaleY 1 → .1 at 50 %, `ease`). Under
/// reduced flicker the scene rests at t = 0 (eyes open).
library;

import 'package:flutter/widgets.dart';

import '../../../data/persian.dart';
import '../../../theme/text_styles.dart';
import '../../../theme/tokens.dart';
import '../../kit/css.dart';
import '../../kit/design_frame.dart';
import '../../kit/loop_clock.dart';
import '../../kit/pill_button.dart';
import '../../kit/svg_path.dart';
import '../game/game_controller.dart';

/// 0..1 loom phase at [seconds] (0 = rest, 1 = fully risen).
double loomAmount(double seconds) {
  final u = (seconds % 5) / 5;
  return u < .5
      ? Curves.easeInOut.transform(u / .5)
      : 1 - Curves.easeInOut.transform((u - .5) / .5);
}

/// CSS `blink 4.5s infinite` scaleY at [seconds].
double blinkScale(double seconds) {
  final u = (seconds % 4.5) / 4.5;
  if (u < .46 || u >= .54) return 1;
  if (u < .5) return 1 - .9 * Curves.ease.transform((u - .46) / .04);
  return .1 + .9 * Curves.ease.transform((u - .5) / .04);
}

/// Design: 470 with a 1.5 headline line height and 18 px gaps. That stacks
/// the hint box underneath the 58 px retry button (it ends at ≈746 vs the
/// button's top at 684), so the block starts higher and is tightened (1.25 /
/// 14 px) to end above the buttons.
const _textTop = 420.0;

const _heading = Color(0xFFF6E2D6);
const _statLabel = Color(0xFFA8857A);

class CaughtScreen extends StatelessWidget {
  const CaughtScreen({
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
    Widget stat(String label, String value) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: KText.caption.copyWith(color: _statLabel)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: KFonts.serif,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: _heading,
          ),
        ),
      ],
    );

    return LoopClock(
      time: time,
      reduce: reduceFlicker,
      builder: (context, t) {
        final k = loomAmount(t);
        final blink = blinkScale(t);
        return DesignFrame(
          children: [
            Positioned.fill(child: _Backdrop()),
            Positioned(
              left: 35,
              top: 40,
              width: 320,
              height: 420,
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.translationValues(0, -5 * k, 0)
                  ..scaleByDouble(1 + .01 * k, 1 + .01 * k, 1, 1),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned(
                      left: 50,
                      top: 0,
                      width: 220,
                      height: 440,
                      child: CustomPaint(painter: _HeadPainter()),
                    ),
                    const Positioned(
                      left: 0,
                      top: 170,
                      width: 320,
                      height: 300,
                      child: CustomPaint(painter: _ShouldersPainter()),
                    ),
                    for (final x in const [106.0, 180.0])
                      Positioned(
                        left: x,
                        top: 110,
                        width: 34,
                        height: 14,
                        child: Transform.scale(
                          scaleY: blink,
                          child: const CustomPaint(painter: _EyePainter()),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 340,
              height: 160,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [rgba(7, 4, 4, 0), Kc.caught],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              top: _textTop,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'گیر افتادی · مرحله‌ی ${fa(stats.level)}',
                    style: KText.caption.copyWith(color: Kc.dangerSoft),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'نورت را دنبال کردند.',
                    style: TextStyle(
                      fontFamily: KFonts.serif,
                      fontSize: 44,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                      color: _heading,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      stat(
                        'کبریت‌های زده‌شده',
                        '${fa(stats.matchesStruck)} از ${fa(stats.startMatches)}',
                      ),
                      const SizedBox(width: 32),
                      stat(
                        'فاصله تا در',
                        stats.stepsToDoor == null
                            ? '—'
                            : '${fa(stats.stepsToDoor!)} قدم',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const _HintBox(
                    'شکارچی‌ها فقط وقتی شعله روشن است حرکت می‌کنند. کبریت بزن، چند پیچ بعدی را به خاطر بسپار و بگذار خاموش شود.',
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

/// `radial-gradient(ellipse at 50% 28%, #3a120c 0%, #160807 45%, #070404 80%)`.
class _Backdrop extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _BackdropPainter(), child: const SizedBox.expand());
}

class _BackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final g = cssEllipseFarthestCorner(
      box: size,
      center: Offset(size.width * .5, size.height * .28),
      stops: const [
        CssStop(Color(0xFF3A120C), 0),
        CssStop(Color(0xFF160807), .45),
        CssStop(Kc.caught, .80),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = g.createShader(rect));
  }

  @override
  bool shouldRepaint(_BackdropPainter o) => false;
}

/// 220×440 head/torso: `#1a0f0c → #050303 70 %`, `0 0 90px 24px` red glow and
/// an `inset 0 2px 0` rim light.
class _HeadPainter extends CustomPainter {
  const _HeadPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = RRect.fromRectAndCorners(
      rect,
      topLeft: const Radius.circular(110),
      topRight: const Radius.circular(110),
      bottomLeft: const Radius.circular(20),
      bottomRight: const Radius.circular(20),
    );
    paintCssShadow(
      canvas,
      shape,
      CssShadow(0, 0, 90, 24, rgba(120, 20, 10, .35)),
    );
    canvas.drawRRect(shape, Paint()..color = rgba(255, 120, 90, .12));
    canvas.save();
    canvas.clipRRect(shape);
    canvas.drawRRect(
      shape.shift(const Offset(0, 2)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0F0C), Color(0xFF050303)],
          stops: [0, .7],
        ).createShader(rect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HeadPainter o) => false;
}

/// 320×300 shoulders: `#120a08 → #040202 60 %`.
class _ShouldersPainter extends CustomPainter {
  const _ShouldersPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = RRect.fromRectAndCorners(
      rect,
      topLeft: const Radius.circular(160),
      topRight: const Radius.circular(160),
    );
    canvas.drawRRect(
      shape,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF120A08), Color(0xFF040202)],
          stops: [0, .6],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_ShouldersPainter o) => false;
}

/// 34×14 eye: `radial-gradient(circle, #fff0d0, #ff5a2e 45%, #c41e10)` with
/// `0 0 24px 8px rgba(255,70,30,.7)`.
class _EyePainter extends CustomPainter {
  const _EyePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = RRect.fromRectXY(rect, size.width / 2, size.height / 2);
    paintCssShadow(
      canvas,
      shape,
      CssShadow(0, 0, 24, 8, rgba(255, 70, 30, .7)),
    );
    final g = cssRadialFarthestCorner(
      box: size,
      center: size.center(Offset.zero),
      stops: const [
        CssStop(Color(0xFFFFF0D0), 0),
        CssStop(Color(0xFFFF5A2E), .45),
        CssStop(Color(0xFFC41E10), 1),
      ],
    );
    canvas.drawRRect(shape, Paint()..shader = g.createShader(rect));
  }

  @override
  bool shouldRepaint(_EyePainter o) => false;
}

/// Flame icon + hint text in a thin red-tinted box.
class _HintBox extends StatelessWidget {
  const _HintBox(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: rgba(40, 12, 8, .5),
      border: Border.all(color: rgba(255, 140, 110, .18)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: SizedBox(
              width: 14,
              height: 18,
              child: CustomPaint(painter: _FlameIconPainter()),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: KFonts.ui,
                fontSize: 14,
                height: 1.45,
                color: Color(0xFFE2C9B8),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// `viewBox 0 0 18 24`, stroke #ffb45a 1.8, round joins, shown at 14×18
/// (uniform "meet" scale .75, centred).
class _FlameIconPainter extends CustomPainter {
  const _FlameIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.height / 24 < size.width / 18
        ? size.height / 24
        : size.width / 18;
    canvas.save();
    canvas.translate((size.width - 18 * s) / 2, (size.height - 24 * s) / 2);
    canvas.scale(s);
    canvas.drawPath(
      parseSvgPath(
        'M9 2c1.5 3.5 6 6 6 11a6 6 0 0 1-12 0c0-3 2-4.5 3-7 1 1.5 1.5 2.5 1.5 4C9.5 8 10 5 9 2z',
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round
        ..color = Kc.flame,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FlameIconPainter o) => false;
}
