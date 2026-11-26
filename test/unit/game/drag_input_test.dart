import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/game/drag_input.dart';
import 'package:kebrit/game/grid.dart';

void main() {
  DragResult c(double dx, double dy) =>
      DragClassifier.classify(100, 200, 100 + dx, 200 + dy);

  test('drag dead-zone: no direction at or below 16 px', () {
    expect(c(0, 0).direction, isNull);
    expect(c(16, 0).direction, isNull);
    expect(c(0, -16).direction, isNull);
    expect(c(11, 11).direction, isNull); // hypot ≈ 15.56
    expect(c(16.01, 0).direction, Dir.right);
  });

  test('drag dead-zone: knob still follows the pointer', () {
    final r = c(5, -7);
    expect(r.knobDx, 5);
    expect(r.knobDy, -7);
  });

  test('drag clamp: knob stays within 30 px of the origin', () {
    final r = c(60, 0);
    expect(r.knobDx, closeTo(30, 1e-9));
    expect(r.knobDy, 0);
    final d = c(60, 80); // hypot 100 -> scaled to 30
    expect(d.knobDx, closeTo(18, 1e-9));
    expect(d.knobDy, closeTo(24, 1e-9));
    expect(c(20, 0).knobDx, 20); // below the clamp: unchanged
  });

  test('drag dominant axis picks the direction', () {
    expect(c(30, 10).direction, Dir.right);
    expect(c(-30, 10).direction, Dir.left);
    expect(c(10, 30).direction, Dir.down);
    expect(c(10, -30).direction, Dir.up);
  });

  test('drag tie between axes goes vertical, as in the JS', () {
    expect(c(20, 20).direction, Dir.down);
    expect(c(20, -20).direction, Dir.up);
    expect(c(-20, 20).direction, Dir.down);
  });
}
