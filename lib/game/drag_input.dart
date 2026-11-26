import 'dart:math' as math;

import 'game_config.dart';
import 'grid.dart';

/// Result of classifying a drag: a direction (null inside the dead-zone) and
/// the joystick knob offset from the origin, clamped to [GameConfig.knobMax].
class DragResult {
  const DragResult(this.direction, this.knobDx, this.knobDy);

  final Dir? direction;
  final double knobDx;
  final double knobDy;

  @override
  bool operator ==(Object other) =>
      other is DragResult &&
      other.direction == direction &&
      other.knobDx == knobDx &&
      other.knobDy == knobDy;

  @override
  int get hashCode => Object.hash(direction, knobDx, knobDy);

  @override
  String toString() => 'DragResult($direction, $knobDx, $knobDy)';
}

class DragClassifier {
  const DragClassifier._();

  /// Origin (ox, oy) is the first touch point; (px, py) the current pointer.
  /// Direction needs distance > deadZone (strict); the dominant axis wins and
  /// ties go vertical, as in the JS.
  static DragResult classify(double ox, double oy, double px, double py) {
    final dx = px - ox, dy = py - oy;
    final m = math.sqrt(dx * dx + dy * dy);
    const max = GameConfig.knobMax;
    final kx = m > max ? dx / m * max : dx;
    final ky = m > max ? dy / m * max : dy;
    Dir? dir;
    if (m > GameConfig.deadZone) {
      dir = dx.abs() > dy.abs()
          ? (dx > 0 ? Dir.right : Dir.left)
          : (dy > 0 ? Dir.down : Dir.up);
    }
    return DragResult(dir, kx, ky);
  }
}
