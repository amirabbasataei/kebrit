/// Backgrounds. CSS sources: MTitle / MComplete root div (stone wall with
/// grid lines) and MGame / MLevels root div (radial vignette).
library;

import 'package:flutter/widgets.dart';

import '../../theme/tokens.dart';
import 'css.dart';

/// The "dungeon wall" backdrop:
///
/// ```css
/// background-color: #2a211b;
/// background-image: linear-gradient(rgba(0,0,0,.55) 3px, transparent 3px),
///                   linear-gradient(90deg, rgba(0,0,0,.45) 3px, transparent 3px),
///                   linear-gradient(170deg, #3a2d24, #1e1712);
/// background-size: 100% 48px, 96px 48px, 100% 100%;
/// ```
///
/// Layers are painted bottom-up: gradient, 3 px vertical joints every 96 px
/// (full height), 3 px horizontal joints every 48 px. Lines are painted
/// without anti-aliasing so they stay crisp like CSS tiles. Tiles start at the
/// physical top-left even in RTL, as `background-position` is physical.
class StoneBackground extends StatelessWidget {
  const StoneBackground({
    super.key,
    this.baseColor = Kc.floor,
    this.gradientAngle = 170,
    this.gradientColors = const [Kc.wallTileA, Kc.wallTileB],
    this.child,
  });

  /// MComplete variant: `#241b15` base, `linear-gradient(#2e241c, #17110d)`.
  const StoneBackground.complete({super.key, this.child})
    : baseColor = const Color(0xFF241B15),
      gradientAngle = 180,
      gradientColors = const [Color(0xFF2E241C), Color(0xFF17110D)];

  final Color baseColor;
  final double gradientAngle;
  final List<Color> gradientColors;
  final Widget? child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _StonePainter(baseColor, gradientAngle, gradientColors),
    child: child ?? const SizedBox.expand(),
  );
}

class _StonePainter extends CustomPainter {
  _StonePainter(this.base, this.angle, this.colors);
  final Color base;
  final double angle;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = base);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = cssLinear(
          deg: angle,
          box: size,
          colors: colors,
        ).createShader(rect),
    );
    final v = Paint()
      ..color = rgba(0, 0, 0, .45)
      ..isAntiAlias = false;
    for (var x = 0.0; x < size.width; x += 96) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 3, size.height), v);
    }
    final h = Paint()
      ..color = rgba(0, 0, 0, .55)
      ..isAntiAlias = false;
    for (var y = 0.0; y < size.height; y += 48) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 3), h);
    }
  }

  @override
  bool shouldRepaint(_StonePainter o) =>
      o.base != base || o.angle != angle || o.colors != colors;
}

/// `radial-gradient(ellipse at X% Y%, inner 0%, outer 75%)` page vignette.
///
/// [center] is a fraction of the box (default 50 %/50 % = game, use
/// `Offset(.5, .3)` for the level select). [stopFraction] is 0.75 in both.
class RadialBackdrop extends StatelessWidget {
  const RadialBackdrop({
    super.key,
    this.center = const Offset(0.5, 0.5),
    this.inner = Kc.gameBgInner,
    this.outer = Kc.page,
    this.stopFraction = 0.75,
    this.child,
  });

  /// MLevels: `ellipse at 50% 30%, #1e1611 0%, #0a0706 75%`.
  const RadialBackdrop.levels({super.key, this.child})
    : center = const Offset(0.5, 0.3),
      inner = Kc.radialInner,
      outer = Kc.page,
      stopFraction = 0.75;

  final Offset center;
  final Color inner;
  final Color outer;
  final double stopFraction;
  final Widget? child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _BackdropPainter(center, inner, outer, stopFraction),
    child: child ?? const SizedBox.expand(),
  );
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter(this.center, this.inner, this.outer, this.stop);
  final Offset center;
  final Color inner, outer;
  final double stop;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final g = cssEllipseFarthestCorner(
      box: size,
      center: Offset(center.dx * size.width, center.dy * size.height),
      stops: [CssStop(inner, 0), CssStop(outer, stop)],
    );
    canvas.drawRect(rect, Paint()..shader = g.createShader(rect));
  }

  @override
  bool shouldRepaint(_BackdropPainter o) =>
      o.center != center ||
      o.inner != inner ||
      o.outer != outer ||
      o.stop != stop;
}
