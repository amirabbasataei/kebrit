/// Tutorial step 4 – "در را پیدا کن": a glowing door in a stone wall, a beam of
/// light on the floor and a pile of spare matches ("+۲ کبریت").
///
/// The door and beam "breathe" (3 s ease-in-out opacity 1 ↔ .75), separate
/// from the 4 s loop: the screen passes the current [breath] opacity.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../theme/text_styles.dart';
import '../../kit/css.dart';
import 'tutorial_parts.dart';

/// `breathe`: opacity 1 → .75 → 1 over 3 s, ease-in-out per half.
double breathOpacity(double seconds) {
  final x = (seconds / 3) % 1.0;
  final half = x < .5 ? x * 2 : 2 - x * 2;
  return 1 - .25 * Curves.easeInOut.transform(half);
}

class StepDoor extends StatelessWidget {
  const StepDoor({super.key, this.breath = 1});
  final double breath;

  @override
  Widget build(BuildContext context) {
    return TutorialStage(
      children: [
        Positioned(
          left: 0,
          top: 0,
          width: 342,
          height: 200,
          child: CustomPaint(painter: _WallPainter()),
        ),
        Positioned.fill(child: CustomPaint(painter: _DoorFramePainter())),
        Positioned.fill(
          child: Opacity(opacity: breath, child: CustomPaint(painter: _DoorGlowPainter())),
        ),
        Positioned(
          left: 61,
          top: 200,
          width: 220,
          height: 180,
          child: Opacity(
            opacity: breath,
            child: ClipPath(
              clipper: const PolygonClipper([
                Offset(.3, 0),
                Offset(.7, 0),
                Offset(1, 1),
                Offset(0, 1),
              ]),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [rgba(255, 190, 110, .35), rgba(255, 170, 90, 0)],
                    stops: const [0, .9],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Pile of spare matches: 40×24 at (40, 300).
        Positioned(
          left: 40,
          top: 300,
          width: 40,
          height: 24,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _bar(2, 6, const Color(0xFFD9B98A), -12),
              _bar(4, 11, const Color(0xFFCFAE7C), 8),
              _dot(24, 2, const Color(0xFFC8402E)),
              _dot(26, 10, const Color(0xFFB8392A)),
            ],
          ),
        ),
        const Positioned(
          left: 36,
          top: 330,
          child: Text(
            '+۲ کبریت',
            style: TextStyle(fontFamily: KFonts.ui, fontSize: 11, color: Color(0xFFE0C393)),
          ),
        ),
      ],
    );
  }

  Widget _bar(double l, double t, Color c, double deg) => Positioned(
        left: l,
        top: t,
        width: 26,
        height: 3,
        child: Transform.rotate(
          angle: deg * math.pi / 180,
          child: ColoredBox(color: c),
        ),
      );

  Widget _dot(double l, double t, Color c) => Positioned(
        left: l,
        top: t,
        width: 6,
        height: 6,
        child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: c)),
      );
}

/// 342×200 wall: `#3a2d24`, 2 px horizontal joints every 40 px
/// (`rgba(0,0,0,.5)`) and 2 px vertical joints every 80 px (`.4`).
class _WallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF3A2D24));
    final h = Paint()
      ..color = rgba(0, 0, 0, .5)
      ..isAntiAlias = false;
    for (var y = 0.0; y < size.height; y += 40) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 2), h);
    }
    final v = Paint()
      ..color = rgba(0, 0, 0, .4)
      ..isAntiAlias = false;
    for (var x = 0.0; x < size.width; x += 80) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 2, size.height), v);
    }
  }

  @override
  bool shouldRepaint(_WallPainter o) => false;
}

RRect _arch(Rect r, double radius) => RRect.fromRectAndCorners(
      r,
      topLeft: Radius.circular(radius),
      topRight: Radius.circular(radius),
    );

/// Door frame: 100×140 at (121,60), top radius 50, `#120d0a` with a solid
/// 8 px `#4d3d30` ring (`box-shadow: 0 0 0 8px`).
class _DoorFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final door = _arch(const Rect.fromLTWH(121, 60, 100, 140), 50);
    paintCssShadow(canvas, door, CssShadow(0, 0, 0, 8, const Color(0xFF4D3D30)));
    canvas.drawRRect(door, Paint()..color = const Color(0xFF120D0A));
  }

  @override
  bool shouldRepaint(_DoorFramePainter o) => false;
}

/// Light behind the door: 84×132 at (129,68), top radius 42,
/// `radial-gradient(ellipse at 50% 85%, #fffaf0, #ffe3ac 30%, #ffb15a 65%,
/// #d9691c)` and glow `0 0 60px 20px rgba(255,160,70,.35)`.
class _DoorGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const rect = Rect.fromLTWH(129, 68, 84, 132);
    final shape = _arch(rect, 42);
    paintCssShadow(canvas, shape, CssShadow(0, 0, 60, 20, rgba(255, 160, 70, .35)));
    final g = cssEllipseFarthestCorner(
      box: rect.size,
      center: Offset(rect.width * .5, rect.height * .85),
      stops: const [
        CssStop(Color(0xFFFFFAF0), 0),
        CssStop(Color(0xFFFFE3AC), .3),
        CssStop(Color(0xFFFFB15A), .65),
        CssStop(Color(0xFFD9691C), 1),
      ],
    );
    canvas.drawRRect(shape, Paint()..shader = g.createShader(rect));
  }

  @override
  bool shouldRepaint(_DoorGlowPainter o) => false;
}
