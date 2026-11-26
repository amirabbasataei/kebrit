/// "چرا کبریت؟" (MBenefits.dc.html): the first-launch page. Hero with a lit
/// match, the see → remember → decide diagram, eight benefit cards, the
/// disclaimer (verbatim from the design, Q11) and two CTAs.
///
/// Callbacks only (routing is Phase 11): [onPlay] = «کبریت را روشن کن»,
/// [onTutorial] = «اول آموزش را ببینم».
library;

import 'package:flutter/widgets.dart';

import '../../../data/persian.dart';
import '../../../theme/text_styles.dart';
import '../../../theme/tokens.dart';
import '../../kit/css.dart';
import '../../kit/dashed.dart';
import '../../kit/flame.dart';
import '../../kit/pill_button.dart';
import '../../kit/stone_bg.dart';
import '../../kit/svg_path.dart';
import 'benefit_items.dart';

class BenefitsScreen extends StatelessWidget {
  const BenefitsScreen({
    super.key,
    this.onPlay,
    this.onTutorial,
    this.controller,
    this.flamePhase,
    this.reduceFlicker,
  });

  final VoidCallback? onPlay;
  final VoidCallback? onTutorial;
  final ScrollController? controller;

  /// Pins the hero flame at this 0..1 pose (goldens). Null = flicker live.
  final double? flamePhase;
  final bool? reduceFlicker;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Kc.page,
      child: SingleChildScrollView(
        controller: controller,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Kc.designWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Hero(flamePhase: flamePhase, reduceFlicker: reduceFlicker),
                const _Steps(),
                const _ItemsHeader(),
                for (final (i, it) in benefitItems.indexed)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: _BenefitCard(item: it, number: i + 1),
                  ),
                _Footer(onPlay: onPlay, onTutorial: onTutorial),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── hero ────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({this.flamePhase, this.reduceFlicker});
  final double? flamePhase;
  final bool? reduceFlicker;

  /// `.flame`: 24×44, scale(1.07,1.15) rotate ±3° over .4 s alternate, glow
  /// `0 0 30px 14px rgba(255,150,50,.4)`.
  static final _flame = FlameStyle(
    width: 24,
    height: 44,
    center: const Offset(.5, .74),
    stops: FlameStyle.title.stops,
    glow: CssShadow(0, 0, 30, 14, rgba(255, 150, 50, .4)),
    rotateDeg: 3,
    scaleX: .07,
    scaleY: .15,
    duration: const Duration(milliseconds: 400),
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 430,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          const Positioned.fill(child: StoneBackground()),
          Positioned.fill(child: CustomPaint(painter: _HeroVignette())),
          // The match: 18×80 box, centred, top 92.
          Positioned(
            left: 0,
            right: 0,
            top: 92,
            height: 80,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 80,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 6,
                      top: 26,
                      width: 6,
                      height: 54,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Color(0xFFE9CD9C), Color(0xFFC9A874)],
                          ),
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 3,
                      top: 18,
                      width: 12,
                      height: 14,
                      child: CustomPaint(painter: _FlatHeadPainter()),
                    ),
                    Positioned(
                      left: -3,
                      top: -16,
                      child: Flame(
                        style: _flame,
                        phase: flamePhase,
                        reduceFlicker: reduceFlicker,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            top: 210,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('چرا کبریت؟', style: KText.eyebrow),
                const SizedBox(height: 12),
                Text(
                  'بازی‌ای در تاریکی،\nکه ذهن را روشن می‌کند',
                  textAlign: TextAlign.center,
                  style: KText.h2Serif.copyWith(
                    fontSize: 30,
                    color: const Color(0xFFF6EAD6),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'چند ثانیه نور، یک عمر فکر. هر اتاق کبریت معمایی است برای چشم، حافظه و تصمیم‌گیری — و تمرینی برای آرام ماندن در دل تاریکی.',
                  textAlign: TextAlign.center,
                  style: KText.body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `radial-gradient(circle at 195px 120px, rgba(255,170,90,.16) 0, rgba(0,0,0,0)
/// 60px, rgba(8,5,3,.7) 230px, #0a0706 420px)`.
class _HeroVignette extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final g = cssRadialPx(
      box: size,
      center: Offset(size.width / 2, 120),
      stops: [
        CssStop(rgba(255, 170, 90, .16), 0),
        CssStop(rgba(0, 0, 0, 0), 60),
        CssStop(rgba(8, 5, 3, .7), 230),
        const CssStop(Kc.page, 420),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = g.createShader(rect));
  }

  @override
  bool shouldRepaint(_HeroVignette o) => false;
}

/// Hero match head: plain `#5a160d`, `border-radius: 50% 50% 45% 45%`.
class _FlatHeadPainter extends CustomPainter {
  const _FlatHeadPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      pctRRect(Offset.zero & size, bottomH: .45, bottomV: .45),
      Paint()..color = const Color(0xFF5A160D),
    );
  }

  @override
  bool shouldRepaint(_FlatHeadPainter o) => false;
}

// ── see / remember / decide ─────────────────────────────────────────────

class _Steps extends StatelessWidget {
  const _Steps();

  @override
  Widget build(BuildContext context) {
    const dash = Color(0x59FFB45A); // rgba(255,180,90,.35)
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, s) in benefitSteps.indexed) ...[
                if (i > 0)
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 29),
                      child: DashedLine(color: dash, width: 2),
                    ),
                  ),
                _StepColumn(step: s, first: i == 0),
              ],
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'هر شعله، یک چرخه‌ی کامل تمرین ذهنی است.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: KFonts.serif,
              fontSize: 16,
              height: 1.8,
              color: Kc.serifSub,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepColumn extends StatelessWidget {
  const _StepColumn({required this.step, required this.first});
  final BenefitStep step;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: first
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: cssRadialFarthestCorner(
                      box: const Size(60, 60),
                      center: const Offset(30, 30),
                      stops: const [
                        CssStop(Color(0xFFFFE3AC), 0),
                        CssStop(Kc.flameDeep, .7),
                      ],
                    ),
                    boxShadow: cssBoxShadows([
                      CssShadow(0, 0, 22, 0, rgba(255, 150, 50, .5)),
                    ]),
                  )
                : BoxDecoration(
                    shape: BoxShape.circle,
                    color: Kc.radialInner,
                    // inset 0 0 0 2px rgba(255,180,90,.45)
                    border: Border.all(
                      color: rgba(255, 180, 90, .45),
                      width: 2,
                    ),
                  ),
            child: SvgIcon(
              step.icon,
              size: 26,
              strokeWidth: first ? 2 : 1.8,
              color: first ? const Color(0xFF2A1608) : Kc.flame,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: KFonts.ui,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Kc.text,
            ),
          ),
          const SizedBox(height: 10),
          Text(step.caption, textAlign: TextAlign.center, style: KText.small),
        ],
      ),
    );
  }
}

// ── benefit cards ───────────────────────────────────────────────────────

class _ItemsHeader extends StatelessWidget {
  const _ItemsHeader();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 36, 24, 6),
    child: Text('آنچه ذهنت تمرین می‌کند', style: KText.h2Serif),
  );
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({required this.item, required this.number});
  final BenefitItem item;
  final int number;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CardPainter(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: rgba(255, 170, 80, .12),
              ),
              child: SvgIcon(
                item.icon,
                size: 24,
                color: Kc.flame,
                strokeWidth: 1.8,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontFamily: KFonts.ui,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF6EAD6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        fa(number).padLeft(2, '۰'),
                        style: const TextStyle(
                          fontFamily: KFonts.ui,
                          fontSize: 12,
                          color: Kc.dimmer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.body,
                    style: KText.body.copyWith(fontSize: 14, height: 1.85),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `linear-gradient(160deg, #211913, #150f0b)`, radius 16,
/// `inset 0 0 0 1px rgba(239,227,208,.08)`.
class _CardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(16));
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = cssLinear(
          deg: 160,
          box: size,
          colors: const [Color(0xFF211913), Color(0xFF150F0B)],
        ).createShader(rect),
    );
    canvas.drawRRect(
      rr.deflate(.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = rgba(239, 227, 208, .08),
    );
  }

  @override
  bool shouldRepaint(_CardPainter o) => false;
}

// ── disclaimer + CTAs ───────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({this.onPlay, this.onTutorial});
  final VoidCallback? onPlay;
  final VoidCallback? onTutorial;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashedBorderBox(
            color: rgba(239, 227, 208, .2),
            width: 1,
            radius: 14,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: const Text(
              'کبریت یک بازی است، نه ابزار درمانی. لذتش را ببر و بگذار ذهنت به چالش کشیده شود.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: KFonts.ui,
                fontSize: 13,
                height: 1.9,
                color: Color(0xFFA99279),
              ),
            ),
          ),
          const SizedBox(height: 18),
          PillButton(
            label: 'کبریت را روشن کن',
            height: 58,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            glowBlur: 26,
            onPressed: onPlay,
          ),
          const SizedBox(height: 18),
          PillButton(
            label: 'اول آموزش را ببینم',
            variant: PillVariant.text,
            height: 48,
            onPressed: onTutorial,
          ),
        ],
      ),
    );
  }
}
