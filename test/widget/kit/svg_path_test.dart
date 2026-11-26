import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/ui/kit/svg_path.dart';
import 'package:kebrit/ui/screens/benefits/benefit_items.dart';

void main() {
  test('relative lines, implicit repetition and h/v', () {
    final b = parseSvgPath('M1 2h3v4z').getBounds();
    expect(b, const Rect.fromLTRB(1, 2, 4, 6));
    // M with extra pairs = implicit lineTo.
    expect(parseSvgPath('M0 0 10 0 10 10').getBounds(), const Rect.fromLTRB(0, 0, 10, 10));
  });

  test('compact numbers: 1.4-7 and .8', () {
    final b = parseSvgPath('M1.4-7L2 9.3l7-.8').getBounds();
    expect(b.left, closeTo(1.4, 1e-5));
    expect(b.top, closeTo(-7, 1e-5));
    expect(b.right, closeTo(9, 1e-5));
    expect(b.bottom, closeTo(9.3, 1e-5));
  });

  test('arc flags may be packed', () {
    final a = parseSvgPath('M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z').getBounds();
    final p = parseSvgPath('M12 15a3 3 0 100-6 3 3 0 000 6z').getBounds();
    expect(p, a);
    // A circle of r=3 centred on (12,12).
    expect(a.left, closeTo(9, .01));
    expect(a.right, closeTo(15, .01));
    expect(a.top, closeTo(9, .01));
    expect(a.bottom, closeTo(15, .01));
  });

  test('smooth curve reflects the previous control point', () {
    final eye = parseSvgPath('M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z').getBounds();
    expect(eye.left, closeTo(2, .01));
    expect(eye.right, closeTo(22, .01));
    expect(eye.top, closeTo(5, .5));
    expect(eye.bottom, closeTo(19, .5));
  });

  test('bad data throws', () {
    expect(() => parseSvgPath('M1 2 X'), throwsFormatException);
    expect(() => parseSvgPath('M1'), throwsFormatException);
  });

  test('every benefit and step icon parses inside the 24 viewBox', () {
    final icons = [
      for (final i in benefitItems) i.icon,
      for (final s in benefitSteps) s.icon,
    ];
    expect(icons, hasLength(11));
    for (final icon in icons) {
      final b = icon.toPath().getBounds();
      expect(b.isEmpty, isFalse);
      expect(b.left, greaterThanOrEqualTo(0));
      expect(b.top, greaterThanOrEqualTo(-.01));
      expect(b.right, lessThanOrEqualTo(24.01));
      expect(b.bottom, lessThanOrEqualTo(24.01));
    }
  });
}
