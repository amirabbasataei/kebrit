/// Shared pieces of the tutorial's 342×380 demo stage (MTutorial.dc.html).
///
/// ## Animation clock
///
/// Every step is a pure function of `p` ∈ [0,1) = time within the 4 s
/// `.a4` loop (`animation-timing-function: ease-in-out`, applied *per keyframe
/// interval*, which [track] reproduces). Pass `pinned: true` to freeze flames.
library;

import 'package:flutter/widgets.dart';

import '../../../theme/tokens.dart';
import '../../kit/css.dart';
import '../../kit/flame.dart';

/// Length of one tutorial loop.
const kTutorialLoop = Duration(seconds: 4);

/// Samples a CSS keyframe track at [p]: [keys] are `(fraction, value)` pairs
/// in ascending order; the value is held before the first and after the last
/// key and eased with [curve] inside each interval (CSS applies the timing
/// function per interval).
double track(double p, List<(double, double)> keys, [Curve curve = Curves.easeInOut]) {
  if (p <= keys.first.$1) return keys.first.$2;
  for (var i = 1; i < keys.length; i++) {
    final (t1, v1) = keys[i];
    if (p <= t1) {
      final (t0, v0) = keys[i - 1];
      if (t1 == t0) return v1;
      final k = curve.transform((p - t0) / (t1 - t0));
      return v0 + (v1 - v0) * k;
    }
  }
  return keys.last.$2;
}

/// The stage frame: `#2a211b` with a 20 px grid of 1 px lines
/// (`rgba(0,0,0,.3)`), clipped, drop shadow `0 24px 50px rgba(0,0,0,.6)` and
/// an inset 1 px `rgba(239,227,208,.08)` ring.
class TutorialStage extends StatelessWidget {
  const TutorialStage({super.key, required this.children});
  final List<Widget> children;

  static const width = 342.0, height = 380.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _StageShadowPainter(),
        foregroundPainter: _StageRingPainter(),
        child: ClipRect(
          child: CustomPaint(
            painter: _StageGridPainter(),
            child: Stack(clipBehavior: Clip.hardEdge, children: children),
          ),
        ),
      ),
    );
  }
}

class _StageShadowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    paintCssShadow(canvas, RRect.fromRectAndRadius(Offset.zero & size, Radius.zero),
        CssShadow(0, 24, 50, 0, rgba(0, 0, 0, .6)));
  }

  @override
  bool shouldRepaint(_StageShadowPainter o) => false;
}

class _StageRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      (Offset.zero & size).deflate(.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = rgba(239, 227, 208, .08),
    );
  }

  @override
  bool shouldRepaint(_StageRingPainter o) => false;
}

class _StageGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Kc.floor);
    final p = Paint()
      ..color = rgba(0, 0, 0, .3)
      ..isAntiAlias = false;
    for (var y = 0.0; y < size.height; y += 20) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), p);
    }
    for (var x = 0.0; x < size.width; x += 20) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), p);
    }
  }

  @override
  bool shouldRepaint(_StageGridPainter o) => false;
}

/// A wall slab: a `w×h` top face (165° gradient, [shade] 0–2) and the 12 px
/// front face `#2e231b` below it (the CSS `box-shadow: 0 12px 0 #2e231b`).
class Slab extends StatelessWidget {
  const Slab({
    super.key,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.shade = 0,
  });

  final double left, top, width, height;
  final int shade;

  @override
  Widget build(BuildContext context) => Positioned(
        left: left,
        top: top,
        width: width,
        height: height + 12,
        child: CustomPaint(painter: _SlabPainter(width, height, shade)),
      );
}

class _SlabPainter extends CustomPainter {
  _SlabPainter(this.w, this.h, this.shade);
  final double w, h;
  final int shade;

  @override
  void paint(Canvas canvas, Size size) {
    final top = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(Rect.fromLTWH(0, h, w, 12), Paint()..color = Kc.wallFront);
    canvas.drawRect(
      top,
      Paint()
        ..shader = cssLinear(
          deg: 165,
          box: top.size,
          colors: Kc.wallTops[shade % 3],
        ).createShader(top),
    );
  }

  @override
  bool shouldRepaint(_SlabPainter o) => o.w != w || o.h != h || o.shade != shade;
}

/// The player: 24×36 at ([left],[top]); [flame] is placed at (17,−1).
class TutorialPlayer extends StatelessWidget {
  const TutorialPlayer({
    super.key,
    required this.left,
    required this.top,
    this.shadow = false,
    this.flame,
    this.dx = 0,
  });

  final double left, top;
  final bool shadow;
  final Widget? flame;

  /// translateX of the whole figure.
  final double dx;

  @override
  Widget build(BuildContext context) => Positioned(
        left: left + dx,
        top: top,
        width: 24,
        height: 36,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: CustomPaint(painter: _PlayerPainter(shadow))),
            if (flame != null) Positioned(left: 17, top: -1, child: flame!),
          ],
        ),
      );
}

/// Player flame 8×12 (`Flame.player`), pinned to the neutral pose in goldens.
Widget playerFlame({required bool pinned}) =>
    Flame.player(phase: pinned ? .5 : null);

class _PlayerPainter extends CustomPainter {
  _PlayerPainter(this.shadow);
  final bool shadow;

  @override
  void paint(Canvas canvas, Size size) {
    if (shadow) {
      canvas.drawOval(
        const Rect.fromLTWH(2, 30, 20, 6),
        Paint()..color = rgba(0, 0, 0, .5),
      );
    }
    // Body: left 4, bottom 2, 16×21, radius 8 8 5 5, vertical gradient.
    final body = Rect.fromLTWH(4, 36 - 2 - 21, 16, 21);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        body,
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(8),
        bottomLeft: const Radius.circular(5),
        bottomRight: const Radius.circular(5),
      ),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9A8268), Color(0xFF6B5744)],
        ).createShader(body),
    );
    // Head: 14×14 circle, `inset 0 -4px 0 #3a2c20` = dark crescent below.
    const head = Rect.fromLTWH(5, 5, 14, 14);
    canvas.save();
    canvas.clipPath(Path()..addOval(head));
    canvas.drawRect(head, Paint()..color = const Color(0xFF3A2C20));
    canvas.drawOval(head.shift(const Offset(0, -4)), Paint()..color = const Color(0xFF7A6550));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PlayerPainter o) => o.shadow != shadow;
}

/// The hunter: 26×40 with two eyes whose glow is [eyes] (0 dormant … 1 lit).
class TutorialHunter extends StatelessWidget {
  const TutorialHunter({
    super.key,
    required this.left,
    required this.top,
    required this.eyes,
    this.dx = 0,
  });

  final double left, top, eyes, dx;

  @override
  Widget build(BuildContext context) => Positioned(
        left: left + dx,
        top: top,
        width: 26,
        height: 40,
        child: CustomPaint(
          painter: HunterPainter(eyes),
          // Glow extends beyond the box.
          size: const Size(26, 40),
        ),
      );
}

/// Hunter silhouette shared with the caught screen later.
class HunterPainter extends CustomPainter {
  HunterPainter(this.eyes);
  final double eyes;

  @override
  void paint(Canvas canvas, Size size) {
    // Body: left 2, bottom 2, 22×34, radius 11 11 4 4.
    final bodyRect = Rect.fromLTWH(2, 40 - 2 - 34, 22, 34);
    final body = RRect.fromRectAndCorners(
      bodyRect,
      topLeft: const Radius.circular(11),
      topRight: const Radius.circular(11),
      bottomLeft: const Radius.circular(4),
      bottomRight: const Radius.circular(4),
    );
    // `inset 0 1px 0 rgba(255,210,170,.14)`: highlight rim along the top.
    canvas.drawRRect(body, Paint()..color = rgba(255, 210, 170, .14));
    canvas.save();
    canvas.clipRRect(body);
    canvas.drawRRect(
      body.shift(const Offset(0, 1)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF30251F), Color(0xFF110C09)],
        ).createShader(bodyRect),
    );
    canvas.restore();

    final color = Color.lerp(Kc.eyesDormant, Kc.eyesLit, eyes)!;
    for (final x in const [7.0, 15.0]) {
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(x, 12, 4, 3), const Radius.circular(2));
      if (eyes > 0) {
        paintCssShadow(canvas, r, CssShadow(0, 0, 7 * eyes, 2 * eyes, rgba(255, 80, 40, .8 * eyes)));
      }
      canvas.drawRRect(r, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(HunterPainter o) => o.eyes != eyes;
}
