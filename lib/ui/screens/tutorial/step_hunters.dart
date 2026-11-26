/// Tutorial step 3 – "شکارچی‌ها دنبال نور می‌آیند": the hunter stands still in
/// the dark, wakes (eyes glow) when the match is lit and walks toward it.
library;

import 'package:flutter/widgets.dart';

import '../../kit/css.dart';
import 'tutorial_parts.dart';

class StepHunters extends StatelessWidget {
  const StepHunters({super.key, required this.p, this.pinned = false});
  final double p;
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    // `litc`: 0→15 % off, 20→70 % on, 80→100 % off.
    final lit = track(p, const [(0, 0), (.15, 0), (.20, 1), (.70, 1), (.80, 0), (1, 0)]);
    final chase = track(p, const [(0, 0), (.20, 0), (.70, -110), (1, -110)]);
    // `eyes` has the same keys as `litc`.
    return TutorialStage(
      children: [
        const Slab(left: 0, top: 130, width: 342, height: 40, shade: 0),
        const Slab(left: 0, top: 262, width: 342, height: 40, shade: 1),
        TutorialPlayer(
          left: 70,
          top: 196,
          flame: Opacity(opacity: lit, child: playerFlame(pinned: pinned)),
        ),
        TutorialHunter(left: 270, top: 192, dx: chase, eyes: lit),
        Positioned.fill(child: ColoredBox(color: rgba(6, 4, 3, .6))),
        Positioned.fill(
          child: Opacity(opacity: lit, child: CustomPaint(painter: _GlowPainter())),
        ),
      ],
    );
  }
}

/// `radial-gradient(circle at 86px 210px, rgba(255,160,70,.25),
/// rgba(255,160,70,0) 240px)`.
class _GlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final g = cssRadialPx(
      box: size,
      center: const Offset(86, 210),
      stops: [
        CssStop(rgba(255, 160, 70, .25), 0),
        CssStop(rgba(255, 160, 70, 0), 240),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = g.createShader(rect));
  }

  @override
  bool shouldRepaint(_GlowPainter o) => false;
}
