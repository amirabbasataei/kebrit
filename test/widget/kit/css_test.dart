import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/ui/kit/css.dart';

void main() {
  test('radial px stops → radius R/shortestSide, stops px/R', () {
    const box = Size(390, 844);
    final g = cssRadialPx(
      box: box,
      center: const Offset(195, 210),
      stops: [
        CssStop(rgba(255, 170, 90, .10), 0),
        CssStop(rgba(0, 0, 0, 0), 90),
        CssStop(rgba(8, 5, 3, .62), 280),
        CssStop(rgba(6, 4, 3, .97), 520),
      ],
    );
    expect(g.radius, closeTo(520 / 390, 1e-9));
    expect(g.center, Alignment(0, 210 / 844 * 2 - 1));
    expect(g.stops!.first, 0);
    expect(g.stops!.last, 1);
    expect(g.stops!.any((s) => (s - 90 / 520).abs() < 1e-9), isTrue);
    expect(g.stops!.any((s) => (s - 280 / 520).abs() < 1e-9), isTrue);
    expect(g.stops!.length, g.colors.length);
    // Monotonic.
    for (var i = 1; i < g.stops!.length; i++) {
      expect(g.stops![i], greaterThanOrEqualTo(g.stops![i - 1]));
    }
  });

  test('gradient interpolation is premultiplied like CSS', () {
    final s = cssStops([
      CssStop(rgba(255, 150, 60, .2), 0),
      CssStop(rgba(0, 0, 0, 0), 100),
    ], steps: 2);
    // Midpoint keeps the hue (255,150,60) and halves the alpha.
    final mid = s[1].color;
    expect(mid.a, closeTo(.1, 1e-6));
    expect(mid.r, closeTo(1.0, 1e-6));
    expect(mid.g, closeTo(150 / 255, 1e-6));
    expect(mid.b, closeTo(60 / 255, 1e-6));
  });

  test('hard stops (same position) are kept', () {
    final s = cssStops([
      CssStop(rgba(255, 0, 0, 1), 0),
      CssStop(rgba(255, 0, 0, 1), 10),
      CssStop(rgba(0, 0, 255, 1), 10),
      CssStop(rgba(0, 0, 255, 1), 20),
    ]);
    expect(s.length, 4);
  });

  test('linear 165deg on a square reaches the corners', () {
    final g = cssLinear(
        deg: 165,
        box: const Size(40, 40),
        colors: const [Color(0xFF000000), Color(0xFFFFFFFF)]);
    final b = g.begin as Alignment, e = g.end as Alignment;
    expect(b.x, closeTo(-0.317, 1e-3));
    expect(b.y, closeTo(-1.183, 1e-3));
    expect(e.x, closeTo(0.317, 1e-3));
    expect(e.y, closeTo(1.183, 1e-3));
  });

  test('linear 180deg is vertical top→bottom edge to edge', () {
    final g = cssLinear(
        deg: 180,
        box: const Size(100, 60),
        colors: const [Color(0xFF000000), Color(0xFFFFFFFF)]);
    final b = g.begin as Alignment, e = g.end as Alignment;
    expect(b.x.abs(), lessThan(1e-9));
    expect(b.y, closeTo(-1, 1e-9));
    expect(e.y, closeTo(1, 1e-9));
  });

  test('conic ring starts at 12 o\'clock with a hard stop at deg/360', () {
    final g = cssConicProgress(
        on: const Color(0xFFFFB45A),
        off: const Color(0x24EFE3D0),
        degrees: 90);
    expect(g.startAngle, -math.pi / 2);
    expect(g.endAngle, 3 * math.pi / 2);
    expect(g.stops, [0, .25, .25, 1]);
  });

  test('shadow blur maps to the same Gaussian sigma as CSS', () {
    for (final b in [9.0, 24.0, 50.0]) {
      final s = CssShadow(0, 0, b, 0, rgba(0, 0, 0, .5)).toBoxShadow();
      expect(s.blurSigma, closeTo(b / 2, 1e-6));
    }
    expect(CssShadow(0, 0, 0, 3, rgba(0, 0, 0, 1)).toBoxShadow().blurRadius, 0);
  });

  test('ellipse gradient uses rx as radius', () {
    final g = cssEllipse(
      box: const Size(390, 844),
      center: const Offset(195, 190),
      rx: 420,
      ry: 520,
      stops: [CssStop(rgba(255, 180, 100, .18), 0), CssStop(rgba(6, 4, 3, .96), 1)],
    );
    expect(g.radius, closeTo(420 / 390, 1e-9));
    expect(g.transform, isNotNull);
  });

  test('pctRRect builds elliptical corners from box fractions', () {
    final r = pctRRect(const Rect.fromLTWH(0, 0, 40, 80),
        topV: .62, bottomV: .38);
    expect(r.tlRadius, const Radius.elliptical(20, 49.6));
    expect(r.brRadius.y, closeTo(30.4, 1e-9));
  });
}
