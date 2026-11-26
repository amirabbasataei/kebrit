/// Tutorial step 1 – "برای حرکت، بکش": a finger drags the joystick and the
/// explorer walks right through a dim corridor.
library;

import 'package:flutter/widgets.dart';

import '../../kit/css.dart';
import '../../kit/svg_path.dart';
import 'tutorial_parts.dart';

class StepDrag extends StatelessWidget {
  const StepDrag({super.key, required this.p, this.pinned = false});

  /// Loop position 0..1.
  final double p;
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    final walk = track(p, const [(0, 0), (.30, 0), (.80, 120), (1, 120)]);
    // `walkr` goes back to 0 at the loop seam (CSS jumps at iteration end).
    final ring = track(p, const [(0, 0), (.12, 0), (.18, 1), (.82, 1), (.92, 0), (1, 0)]);
    final knob = track(p, const [(0, 0), (.18, 0), (.40, 26), (.80, 26), (.92, 0), (1, 0)]);
    final fx = track(p, const [(0, 0), (.10, 0), (.60, 70), (.80, 70), (.92, 70), (1, 70)]);
    final fo = track(p, const [(0, 0), (.10, 0), (.18, 1), (.60, 1), (.80, 1), (.92, 0), (1, 0)]);
    return TutorialStage(
      children: [
        const Slab(left: 0, top: 112, width: 342, height: 40),
        const Slab(left: 0, top: 236, width: 342, height: 40),
        TutorialPlayer(left: 90, top: 178, dx: walk, shadow: true),
        // radial-gradient(circle at 160px 200px, transparent 80px, rgba(6,4,3,.75) 220px)
        Positioned.fill(
          child: CustomPaint(painter: _DimPainter()),
        ),
        // Joystick ring: 64 + 2·2 border = 68 box at (110, 268).
        Positioned(
          left: 110,
          top: 268,
          width: 68,
          height: 68,
          child: Opacity(
            opacity: ring,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rgba(255, 210, 150, .06),
                border: Border.all(color: rgba(255, 210, 150, .4), width: 2),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 16 + knob,
                    top: 16,
                    width: 28,
                    height: 28,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: rgba(255, 210, 150, .4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 128 + fx,
          top: 286,
          width: 40,
          height: 48,
          child: Opacity(
            opacity: fo,
            child: const CustomPaint(painter: _FingerPainter()),
          ),
        ),
      ],
    );
  }
}

class _DimPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final g = cssRadialPx(
      box: size,
      center: const Offset(160, 200),
      stops: [
        CssStop(rgba(0, 0, 0, 0), 80),
        CssStop(rgba(6, 4, 3, .75), 220),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = g.createShader(rect));
  }

  @override
  bool shouldRepaint(_DimPainter o) => false;
}

/// The hand: svg viewBox 16×20 in a 40×48 box (`meet`: scale 2.4, centred).
class _FingerPainter extends CustomPainter {
  const _FingerPainter();

  static final _path = parseSvgPath(
    'M6 9V3a1.5 1.5 0 0 1 3 0v5V6.5a1.5 1.5 0 0 1 3 0V10v0a1.5 1.5 0 0 1 3 0v3.5c0 2.5-1 4.5-3.5 4.5S7 16 6 14L2.4 9.9a1.5 1.5 0 0 1 2.1-2.1z',
  );

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate((size.width - 16 * 2.4) / 2, 0);
    canvas.scale(2.4);
    canvas.drawPath(_path, Paint()..color = const Color(0xFFEFE3D0));
    canvas.drawPath(
      _path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF1A120D),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FingerPainter o) => false;
}
