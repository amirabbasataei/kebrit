/// CSS → Flutter translation helpers (PLAN Phase 3).
///
/// Every visual in `design_src/mobile/*.dc.html` is inline CSS. These helpers
/// keep the translations in one place so the widgets read like the CSS.
///
/// ## Translation table
///
/// * **`radial-gradient(circle at X Y, c1 p1px, c2 p2px …)`** →
///   [cssRadialPx]. Flutter's `RadialGradient.radius` is a fraction of the
///   box's *shortest side*, so `radius = R / box.shortestSide` with
///   `R = last stop px`, and `stops = px / R`. The centre becomes an
///   `Alignment` computed from the pixel position and the box size. Colours
///   beyond the last stop clamp like CSS.
/// * **Percent stops / default size** (`circle at 50% 70%, a, b 45%, c`) →
///   [cssRadialFarthestCorner]: CSS' default size is `farthest-corner`, so
///   `R` = distance from the centre to the farthest corner and the
///   percentages are fractions of `R`.
/// * **`radial-gradient(ellipse …)`** → [cssEllipse] /
///   [cssEllipseFarthestCorner]: a circular `RadialGradient` of radius `rx`
///   plus a [GradientTransform] that squashes y by `ry / rx` about the centre.
/// * **Premultiplied alpha.** CSS interpolates gradients in premultiplied
///   space, Flutter in straight space, so `rgba(255,150,60,.2) → rgba(0,0,0,0)`
///   darkens in Flutter. [cssStops] resamples every colour segment (8 steps)
///   with premultiplied interpolation so the result matches the browser.
///   All gradient helpers here apply it.
/// * **`linear-gradient(<angle>deg, …)`** → [cssLinear]. CSS' gradient line
///   passes through the box centre and its length makes the 0 %/100 % lines
///   touch the corners (`|w·sin a| + |h·cos a|`); the result is expressed as
///   `Alignment`s that may exceed ±1.
/// * **`conic-gradient(c1 Xdeg, c2 0deg)`** → [cssConicProgress]: a
///   `SweepGradient` starting at −90° (CSS 0° is "up", Flutter 0 is "right")
///   with a hard stop at `X / 360`.
/// * **`box-shadow`** → [CssShadow] (`toBoxShadow` for decorations,
///   [paintCssShadow] for painters). CSS blur `B` is a Gaussian with
///   σ = B/2; Flutter's `BoxShadow.blurRadius` is converted to σ as
///   `r·0.57735 + 0.5`, so [cssBlurToRadius] inverts that to get the same σ.
///   `spread` maps to `spreadRadius`. *Not supported:* `inset` shadows – the
///   widgets paint them as 1–2 px edge strips instead (see `stone_wall.dart`)
///   – and CSS' "no shadow under the box" clipping (only visible on translucent
///   boxes, none in the design).
/// * **`filter: blur(Npx)`** → [CssBlur] (`ImageFiltered`, σ = N, decal edges).
/// * **`clip-path: polygon(…)`** → [PolygonClipper] (points as fractions).
/// * **`border-radius: a% b% c% d% / …`** → [pctRRect].
/// * **Border + radius on one side only** (Flutter forbids a non-uniform
///   `Border` with a `borderRadius`) is painted by `BottomSheetPanel` as a
///   DRRect.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// `rgba(r,g,b,a)`.
Color rgba(int r, int g, int b, double a) => Color.fromRGBO(r, g, b, a);

/// A colour stop. [at] is pixels for the `…Px` helpers and a 0..1 fraction
/// for everything else (see each function).
class CssStop {
  const CssStop(this.color, this.at);
  final Color color;
  final double at;
}

Color _lerpPremul(Color x, Color y, double t) {
  final a = x.a + (y.a - x.a) * t;
  if (a <= 0) return Color.from(alpha: 0, red: x.r, green: x.g, blue: x.b);
  double ch(double cx, double cy) =>
      (cx * x.a + (cy * y.a - cx * x.a) * t) / a;
  return Color.from(
    alpha: a,
    red: ch(x.r, y.r).clamp(0.0, 1.0),
    green: ch(x.g, y.g).clamp(0.0, 1.0),
    blue: ch(x.b, y.b).clamp(0.0, 1.0),
  );
}

/// Resamples [stops] (positions ascending, same unit) with premultiplied-alpha
/// interpolation. Segments between identical colours / equal positions are
/// kept as is.
List<CssStop> cssStops(List<CssStop> stops, {int steps = 8}) {
  final out = <CssStop>[];
  var prevAt = double.negativeInfinity;
  for (var i = 0; i < stops.length; i++) {
    // CSS: a stop position smaller than any previous one is raised to it.
    final at = math.max(stops[i].at, prevAt);
    final cur = CssStop(stops[i].color, at);
    if (i > 0) {
      final p = out.last;
      if (cur.at > p.at && cur.color != p.color) {
        for (var s = 1; s < steps; s++) {
          final t = s / steps;
          out.add(CssStop(_lerpPremul(p.color, cur.color, t),
              p.at + (cur.at - p.at) * t));
        }
      }
    }
    out.add(cur);
    prevAt = at;
  }
  return out;
}

Alignment _alignmentOf(Offset p, Size box) =>
    Alignment(p.dx / box.width * 2 - 1, p.dy / box.height * 2 - 1);

/// `radial-gradient(circle at [center]px, c1 p1px, … cN pNpx)`; [stops] `at`
/// are pixels. `R = stops.last.at`.
RadialGradient cssRadialPx({
  required Size box,
  required Offset center,
  required List<CssStop> stops,
}) {
  final r = stops.last.at <= 0 ? 1.0 : stops.last.at;
  final s = cssStops(stops);
  return RadialGradient(
    center: _alignmentOf(center, box),
    radius: r / box.shortestSide,
    colors: [for (final e in s) e.color],
    stops: [for (final e in s) (e.at / r).clamp(0.0, 1.0)],
  );
}

/// `radial-gradient(circle at [center]px, …)` with the default
/// `farthest-corner` size; [stops] `at` are fractions of the radius.
RadialGradient cssRadialFarthestCorner({
  required Size box,
  required Offset center,
  required List<CssStop> stops,
}) {
  final r = math.max(
    math.max(center.distance, (Offset(box.width, 0) - center).distance),
    math.max((Offset(0, box.height) - center).distance,
        (Offset(box.width, box.height) - center).distance),
  );
  return cssRadialPx(
    box: box,
    center: center,
    stops: [for (final s in stops) CssStop(s.color, s.at * r)],
  );
}

class _EllipseScale extends GradientTransform {
  const _EllipseScale(this.center, this.sy);
  final Offset center;
  final double sy;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final c = bounds.topLeft + center;
    return Matrix4.translationValues(c.dx, c.dy, 0) *
        Matrix4.diagonal3Values(1, sy, 1) *
        Matrix4.translationValues(-c.dx, -c.dy, 0);
  }
}

/// `radial-gradient(ellipse [rx]px [ry]px at [center]px, …)`; [stops] `at` are
/// fractions of the radii.
RadialGradient cssEllipse({
  required Size box,
  required Offset center,
  required double rx,
  required double ry,
  required List<CssStop> stops,
}) {
  final s = cssStops(stops);
  return RadialGradient(
    center: _alignmentOf(center, box),
    radius: rx / box.shortestSide,
    colors: [for (final e in s) e.color],
    stops: [for (final e in s) e.at.clamp(0.0, 1.0)],
    transform: _EllipseScale(center, ry / rx),
  );
}

/// `radial-gradient(ellipse at [center]px, …)` (default `farthest-corner`).
RadialGradient cssEllipseFarthestCorner({
  required Size box,
  required Offset center,
  required List<CssStop> stops,
}) {
  final fsx = math.max(center.dx, box.width - center.dx);
  final fsy = math.max(center.dy, box.height - center.dy);
  return cssEllipse(
    box: box,
    center: center,
    rx: fsx * math.sqrt2,
    ry: fsy * math.sqrt2,
    stops: stops,
  );
}

/// `linear-gradient(<deg>deg, c1 s1, …)` on a box of [box] size. [stops] are
/// fractions (or null for even spacing).
LinearGradient cssLinear({
  required double deg,
  required Size box,
  required List<Color> colors,
  List<double>? stops,
}) {
  final rad = deg * math.pi / 180;
  final dx = math.sin(rad), dy = -math.cos(rad);
  final len = box.width * dx.abs() + box.height * dy.abs();
  final ax = dx * len / box.width, ay = dy * len / box.height;
  return LinearGradient(
    begin: Alignment(-ax, -ay),
    end: Alignment(ax, ay),
    colors: colors,
    stops: stops,
  );
}

/// `conic-gradient(on [degrees]deg, off 0deg)` – a progress ring starting at
/// 12 o'clock and running clockwise.
SweepGradient cssConicProgress({
  required Color on,
  required Color off,
  required double degrees,
}) {
  final t = (degrees / 360).clamp(0.0, 1.0);
  return SweepGradient(
    startAngle: -math.pi / 2,
    endAngle: 3 * math.pi / 2,
    colors: [on, on, off, off],
    stops: [0, t, t, 1],
  );
}

/// Inverts Flutter's `sigma = r·0.57735 + 0.5` so a `BoxShadow` blurs with
/// the same Gaussian σ = [blurPx]/2 as CSS.
double cssBlurToRadius(double blurPx) =>
    blurPx <= 1 ? 0 : (blurPx / 2 - 0.5) / 0.57735;

/// One CSS `box-shadow` layer (`dx dy blur spread color`, never `inset`).
class CssShadow {
  const CssShadow(this.dx, this.dy, this.blur, this.spread, this.color);
  final double dx, dy, blur, spread;
  final Color color;

  BoxShadow toBoxShadow() => BoxShadow(
        color: color,
        offset: Offset(dx, dy),
        blurRadius: cssBlurToRadius(blur),
        spreadRadius: spread,
      );

  CssShadow withAlpha(double a) => CssShadow(dx, dy, blur, spread, color.withValues(alpha: a));
}

List<BoxShadow> cssBoxShadows(List<CssShadow> shadows) =>
    [for (final s in shadows) s.toBoxShadow()];

/// Paints [s] under [shape] (an `RRect`), as CSS would.
void paintCssShadow(Canvas canvas, RRect shape, CssShadow s) {
  final r = shape.shift(Offset(s.dx, s.dy)).inflate(s.spread);
  final p = Paint()..color = s.color;
  if (s.blur > 0) p.maskFilter = MaskFilter.blur(BlurStyle.normal, s.blur / 2);
  canvas.drawRRect(r, p);
}

/// `filter: blur(Npx)`.
class CssBlur extends StatelessWidget {
  const CssBlur({super.key, required this.px, required this.child});
  final double px;
  final Widget child;

  @override
  Widget build(BuildContext context) => ImageFiltered(
        imageFilter:
            ui.ImageFilter.blur(sigmaX: px, sigmaY: px, tileMode: TileMode.decal),
        child: child,
      );
}

/// `clip-path: polygon(x% y%, …)`; [points] are fractions of the box.
class PolygonClipper extends CustomClipper<Path> {
  const PolygonClipper(this.points);
  final List<Offset> points;

  @override
  Path getClip(Size size) {
    final path = Path()
      ..addPolygon([for (final p in points) Offset(p.dx * size.width, p.dy * size.height)], true);
    return path;
  }

  @override
  bool shouldReclip(PolygonClipper old) => old.points != points;
}

/// `border-radius: topH% topH% bottomH% bottomH% / topV% topV% bottomV% bottomV%`
/// – the shapes used by flames, embers and match heads (percent of the box).
RRect pctRRect(
  Rect r, {
  double topH = 0.5,
  double topV = 0.5,
  double bottomH = 0.5,
  double bottomV = 0.5,
}) {
  final top = Radius.elliptical(r.width * topH, r.height * topV);
  final bottom = Radius.elliptical(r.width * bottomH, r.height * bottomV);
  return RRect.fromRectAndCorners(
    r,
    topLeft: top,
    topRight: top,
    bottomLeft: bottom,
    bottomRight: bottom,
  );
}
