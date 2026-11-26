/// Match visuals.
///
/// * [MatchIcon] – the HUD counter glyph (MGame): a 5×20 bar,
///   `linear-gradient(#c8402e 0 6px, #e0c393 6px)` (hard stop).
/// * [MatchStrikeIcon] – the 10×30 match on the strike button (MGame), with
///   an optional lit flame (10×14 at left 0, top −8).
/// * [MatchStick] – the 40×200 hero match on the title screen (MTitle): a
///   stick tilted 10° about its top, a dark head and the big flame.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../theme/tokens.dart';
import 'css.dart';
import 'flame.dart';

class MatchIcon extends StatelessWidget {
  const MatchIcon({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 5,
    height: 20,
    child: Column(
      children: [
        SizedBox(height: 6, width: 5, child: ColoredBox(color: Kc.matchHead)),
        Expanded(
          child: SizedBox(width: 5, child: ColoredBox(color: Kc.matchStick)),
        ),
      ],
    ),
  );
}

class MatchStrikeIcon extends StatelessWidget {
  const MatchStrikeIcon({
    super.key,
    this.lit = false,
    this.reduceFlicker,
    this.phase,
  });

  final bool lit;
  final bool? reduceFlicker;
  final double? phase;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 10,
      height: 30,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            left: 3,
            top: 10,
            width: 4,
            height: 20,
            child: ColoredBox(color: Kc.matchStick),
          ),
          Positioned(
            left: 1,
            top: 4,
            width: 8,
            height: 9,
            child: CustomPaint(painter: _HeadPainter(color: Kc.matchHead)),
          ),
          if (lit)
            Positioned(
              left: 0,
              top: -8,
              child: Flame.strikeButton(
                reduceFlicker: reduceFlicker,
                phase: phase,
              ),
            ),
        ],
      ),
    );
  }
}

class MatchStick extends StatelessWidget {
  const MatchStick({
    super.key,
    this.lit = true,
    this.reduceFlicker,
    this.phase,
  });

  final bool lit;
  final bool? reduceFlicker;
  final double? phase;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 200,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 4,
            top: 30,
            width: 8,
            height: 170,
            child: Transform.rotate(
              angle: 10 * math.pi / 180,
              alignment: Alignment.topCenter,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFFE9CD9C), Color(0xFFC9A874)],
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            left: -3,
            top: 16,
            width: 20,
            height: 24,
            child: CustomPaint(painter: _HeadPainter(hero: true)),
          ),
          if (lit)
            Positioned(
              left: -13,
              top: -60,
              child: Flame.title(reduceFlicker: reduceFlicker, phase: phase),
            ),
        ],
      ),
    );
  }
}

/// `border-radius: 50% 50% 45% 45%` head: flat [color], or the hero's
/// `radial-gradient(circle at 40% 35%, #6a2418, #2a0d08)`.
class _HeadPainter extends CustomPainter {
  const _HeadPainter({this.color, this.hero = false});
  final Color? color;
  final bool hero;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = pctRRect(
      rect,
      topH: .5,
      topV: .5,
      bottomH: .45,
      bottomV: .45,
    );
    final paint = Paint();
    if (hero) {
      paint.shader = cssRadialFarthestCorner(
        box: size,
        center: Offset(size.width * .4, size.height * .35),
        stops: const [
          CssStop(Color(0xFF6A2418), 0),
          CssStop(Color(0xFF2A0D08), 1),
        ],
      ).createShader(rect);
    } else {
      paint.color = color!;
    }
    canvas.drawRRect(shape, paint);
  }

  @override
  bool shouldRepaint(_HeadPainter o) => o.color != color || o.hero != hero;
}
