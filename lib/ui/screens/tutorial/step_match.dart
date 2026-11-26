/// Tutorial step 2 – "کبریت بزن تا ببینی": the room is black until the strike
/// button is tapped, then the flame lights the surroundings for a moment.
library;

import 'package:flutter/widgets.dart';

import '../../../theme/tokens.dart';
import '../../kit/css.dart';
import 'tutorial_parts.dart';

class StepMatch extends StatelessWidget {
  const StepMatch({super.key, required this.p, this.pinned = false});
  final double p;
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    final unlit = track(p, const [(0, 1), (.26, 1), (.34, 0), (.78, 0), (1, 1)]);
    final litup = track(p, const [(0, 0), (.26, 0), (.34, 1), (.78, 1), (1, 0)]);
    // `flm`: opacity 0→1 (26→32 %), hold to 78 %, fade out at 100 %.
    final flmO = track(p, const [(0, 0), (.26, 0), (.32, 1), (.78, 1), (1, 0)]);
    final flmS = track(p, const [(0, .3), (.26, .3), (.32, 1), (.78, 1), (1, .4)]);
    final tap = track(p, const [(0, 1), (.20, 1), (.26, .86), (.32, 1), (1, 1)]);
    final dotO = track(p, const [(0, 0), (.18, 0), (.24, 1), (.36, 0), (1, 0)]);
    final dotS = track(p, const [(0, .4), (.18, .4), (.24, 1), (.36, 1.6), (1, 1.6)]);
    return TutorialStage(
      children: [
        const Slab(left: 40, top: 60, width: 40, height: 52, shade: 0),
        const Slab(left: 80, top: 60, width: 40, height: 52, shade: 1),
        const Slab(left: 220, top: 140, width: 40, height: 92, shade: 2),
        const Slab(left: 60, top: 220, width: 120, height: 40, shade: 0),
        TutorialPlayer(
          left: 150,
          top: 140,
          flame: Opacity(
            opacity: flmO,
            child: Transform.scale(
              scale: flmS,
              alignment: Alignment.bottomCenter,
              child: playerFlame(pinned: pinned),
            ),
          ),
        ),
        Positioned.fill(
          child: Opacity(opacity: unlit, child: ColoredBox(color: rgba(6, 4, 3, .96))),
        ),
        Positioned.fill(
          child: Opacity(opacity: litup, child: CustomPaint(painter: _LitPainter())),
        ),
        // Strike button: 72 circle at right 20 / bottom 20.
        Positioned(
          right: 20,
          bottom: 20,
          width: 72,
          height: 72,
          child: Transform.scale(
            scale: tap,
            child: const CustomPaint(painter: _StrikeButtonPainter()),
          ),
        ),
        // Tap ripple: 44 + 2·2 border at right 34 / bottom 34.
        Positioned(
          right: 34,
          bottom: 34,
          width: 48,
          height: 48,
          child: Opacity(
            opacity: dotO,
            child: Transform.scale(
              scale: dotS,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: rgba(255, 230, 190, .8), width: 2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// `radial-gradient(circle at 162px 160px, rgba(255,160,70,.15) 0,
/// rgba(6,4,3,0) 60px, rgba(6,4,3,.6) 260px)`.
class _LitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final g = cssRadialPx(
      box: size,
      center: const Offset(162, 160),
      stops: [
        CssStop(rgba(255, 160, 70, .15), 0),
        CssStop(rgba(6, 4, 3, 0), 60),
        CssStop(rgba(6, 4, 3, .6), 260),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = g.createShader(rect));
  }

  @override
  bool shouldRepaint(_LitPainter o) => false;
}

/// The 72 px strike button: flame-gradient ring (4 px), dark disc
/// (`radial-gradient(circle at 50% 40%, #3a2a1e, #1a120d)`), 10×28 match.
class _StrikeButtonPainter extends CustomPainter {
  const _StrikeButtonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawOval(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Kc.flame, Kc.flameDeep],
        ).createShader(rect),
    );
    final disc = rect.deflate(4);
    canvas.drawOval(
      disc,
      Paint()
        ..shader = cssRadialFarthestCorner(
          box: disc.size,
          center: Offset(disc.width * .5, disc.height * .4),
          stops: const [CssStop(Color(0xFF3A2A1E), 0), CssStop(Color(0xFF1A120D), 1)],
        ).createShader(disc),
    );
    // Match: 10×28 box centred in the disc.
    final o = Offset(rect.center.dx - 5, rect.center.dy - 14);
    canvas.drawRect(Rect.fromLTWH(o.dx + 3, o.dy + 10, 4, 18), Paint()..color = Kc.matchStick);
    canvas.drawRRect(
      pctRRect(Rect.fromLTWH(o.dx + 1, o.dy + 4, 8, 9), bottomH: .45, bottomV: .45),
      Paint()..color = Kc.matchHead,
    );
  }

  @override
  bool shouldRepaint(_StrikeButtonPainter o) => false;
}
