/// Level complete (MComplete.dc.html): the glowing door with a walker's
/// silhouette, 0–3 embers, three stats, the next-level teaser and buttons.
///
/// Assumptions (PLAN Q4): «گریز ۲ از ۲» = hunters evaded = the level's hunter
/// count; «کبریت مانده» = matches left of the level's starting matches.
/// The repeat button reads «تکرار برای ۳ اخگر» until 3 embers are earned.
///
/// Animation: the door glow and the light beam "breathe" (3 s). [time] pins
/// the clock (goldens); reduced flicker rests at full opacity.
library;

import 'package:flutter/widgets.dart';

import '../../../data/levels.dart';
import '../../../data/persian.dart';
import '../../../theme/text_styles.dart';
import '../../../theme/tokens.dart';
import '../../kit/css.dart';
import '../../kit/design_frame.dart';
import '../../kit/ember_icon.dart';
import '../../kit/loop_clock.dart';
import '../../kit/pill_button.dart';
import '../../kit/stone_bg.dart';
import '../game/game_controller.dart';

/// CSS `breathe 3s ease-in-out infinite`: opacity 1 → .82 → 1.
double breatheOpacity(double seconds) {
  final u = (seconds % 3) / 3;
  final k = u < .5
      ? Curves.easeInOut.transform(u / .5)
      : 1 - Curves.easeInOut.transform((u - .5) / .5);
  return 1 - .18 * k;
}

/// «تکرار برای ۳ اخگر» (or «بازی دوباره» once all three are earned).
String repeatLabel(int embers) =>
    embers >= 3 ? 'بازی دوباره' : 'تکرار برای ${fa(3)} اخگر';

class CompleteScreen extends StatelessWidget {
  const CompleteScreen({
    super.key,
    required this.stats,
    required this.embers,
    this.onNext,
    this.onRepeat,
    this.onLevels,
    this.time,
    this.reduceFlicker,
  });

  final GameStats stats;

  /// 0..3 embers earned this run.
  final int embers;
  final VoidCallback? onNext;
  final VoidCallback? onRepeat;
  final VoidCallback? onLevels;

  /// Pins the breathing animation at this many seconds (goldens/tests).
  final double? time;
  final bool? reduceFlicker;

  static final _line = rgba(239, 227, 208, .14);

  @override
  Widget build(BuildContext context) {
    final level = Levels.byId(stats.level);
    final hasNext = stats.level < Levels.count;
    final next = hasNext ? Levels.byId(stats.level + 1) : null;
    final earned = embers.clamp(0, 3);

    const valueStyle = TextStyle(
      fontFamily: KFonts.serif,
      fontSize: 26,
      fontWeight: FontWeight.w600,
      height: 1,
      color: Kc.text,
    );

    Widget stat(String label, String value, {bool middle = false}) => Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: middle
                  ? Border(left: BorderSide(color: _line), right: BorderSide(color: _line))
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: KText.caption),
                  const SizedBox(height: 6),
                  Text(value, style: valueStyle),
                ],
              ),
            ),
          ),
        );

    return LoopClock(
      time: time,
      reduce: reduceFlicker,
      builder: (context, t) {
        final breathe = breatheOpacity(t);
        return DesignFrame(
          children: [
            const Positioned.fill(child: StoneBackground.complete()),
            Positioned.fill(child: _Vignette()),
            Positioned(
              left: 45,
              top: 300,
              width: 300,
              height: 260,
              child: Opacity(
                opacity: breathe,
                child: ClipPath(
                  clipper: const PolygonClipper([
                    Offset(.33, 0),
                    Offset(.67, 0),
                    Offset(1, 1),
                    Offset(0, 1),
                  ]),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [rgba(255, 190, 110, .32), rgba(255, 170, 90, 0)],
                        stops: const [0, .85],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 115,
              top: 92,
              width: 160,
              height: 208,
              child: CustomPaint(painter: _DoorFramePainter()),
            ),
            Positioned(
              left: 125,
              top: 102,
              width: 140,
              height: 198,
              child: Opacity(
                opacity: breathe,
                child: const CustomPaint(painter: _DoorGlowPainter()),
              ),
            ),
            const Positioned(
              left: 177,
              top: 240,
              width: 36,
              height: 60,
              child: CustomPaint(painter: _WalkerPainter()),
            ),
            Positioned(
              left: 24,
              right: 24,
              top: 330,
              child: Column(
                children: [
                  Text(
                    'مرحله‌ی ${fa(level.id)} · ${level.name}',
                    style: KText.caption.copyWith(color: const Color(0xFFE8C79A)),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'در را پیدا کردی.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: KFonts.serif,
                      fontSize: 46,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                      color: Kc.headingBright,
                      shadows: [Shadow(color: Color(0x4DFFA046), blurRadius: 30)],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    image: true,
                    label: '${fa(earned)} اخگر از ${fa(3)} به دست آمد',
                    excludeSemantics: true,
                    child: EmberRow(count: earned, size: EmberSize.large),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              top: 498,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: _line), bottom: BorderSide(color: _line)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    stat('کبریت مانده', '${fa(stats.matchesLeft)} از ${fa(stats.startMatches)}'),
                    stat('زمان', faTime(stats.elapsed), middle: true),
                    stat('گریز', '${fa(stats.hunters)} از ${fa(stats.hunters)}'),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              top: 602,
              child: Text(
                next != null
                    ? 'بعدی: ${next.name} — ${fa(next.startMatches)} کبریت، ${fa(next.hunterStarts.length)} شکارچی.'
                    : 'آخرین اتاق را هم گذراندی.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: KFonts.serif,
                  fontSize: 17,
                  color: Color(0xFFC9B393),
                ),
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
                  if (hasNext) ...[
                    PillButton(
                      label: 'اتاق بعدی',
                      height: 58,
                      glowAlpha: .35,
                      icon: const ChevronIcon(),
                      onPressed: onNext,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: PillButton(
                          label: repeatLabel(earned),
                          variant: PillVariant.outline,
                          height: 50,
                          fontSize: 14,
                          onPressed: onRepeat,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PillButton(
                          label: 'مراحل',
                          variant: PillVariant.outline,
                          height: 50,
                          fontSize: 14,
                          onPressed: onLevels,
                        ),
                      ),
                    ],
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

/// `radial-gradient(ellipse 420px 520px at 195px 190px, …)`.
class _Vignette extends StatelessWidget {
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: CustomPaint(
          painter: _VignettePainter(),
          child: const SizedBox.expand(),
        ),
      );
}

class _VignettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final g = cssEllipse(
      box: size,
      center: const Offset(195, 190),
      rx: 420,
      ry: 520,
      stops: [
        CssStop(rgba(255, 180, 100, .18), 0),
        CssStop(rgba(0, 0, 0, 0), .35),
        CssStop(rgba(8, 5, 3, .72), .70),
        CssStop(rgba(6, 4, 3, .96), 1),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = g.createShader(rect));
  }

  @override
  bool shouldRepaint(_VignettePainter o) => false;
}

/// 160×208 door hole with `0 0 0 10px #4d3d30, 0 0 0 12px #2a2019` rings.
class _DoorFramePainter extends CustomPainter {
  const _DoorFramePainter();

  RRect _arch(Rect r, double radius) => RRect.fromRectAndCorners(
        r,
        topLeft: Radius.circular(radius),
        topRight: Radius.circular(radius),
      );

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRRect(_arch(r.inflate(12), 92), Paint()..color = const Color(0xFF2A2019));
    canvas.drawRRect(_arch(r.inflate(10), 90), Paint()..color = const Color(0xFF4D3D30));
    canvas.drawRRect(_arch(r, 80), Paint()..color = const Color(0xFF120D0A));
  }

  @override
  bool shouldRepaint(_DoorFramePainter o) => false;
}

/// 140×198 light in the doorway: radial gradient + `0 0 80px 30px` glow.
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
    paintCssShadow(canvas, shape, CssShadow(0, 0, 80, 30, rgba(255, 160, 70, .35)));
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

/// 36×60 silhouette: 14 px head at (11,0), body 24×47 at (6,13).
class _WalkerPainter extends CustomPainter {
  const _WalkerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFF2A1C12);
    canvas.drawCircle(const Offset(18, 7), 7, p);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(6, 13, 24, 47),
        topLeft: const Radius.circular(12),
        topRight: const Radius.circular(12),
        bottomLeft: const Radius.circular(3),
        bottomRight: const Radius.circular(3),
      ),
      p,
    );
  }

  @override
  bool shouldRepaint(_WalkerPainter o) => false;
}
