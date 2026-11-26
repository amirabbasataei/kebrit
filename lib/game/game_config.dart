/// Tuning constants, ported from the `MGame.dc.html` script (PLAN.md §0.2).
class GameConfig {
  const GameConfig._();

  /// Board cell edge in logical px.
  static const double cellSize = 40;

  /// Engine tick period (the JS `setInterval(…, 100)`).
  static const int tickMs = 100;

  /// Burn lost per tick; a fresh match (100) lasts 80 ticks.
  static const double burnPerTick = 1.25;

  /// Hunters take one step on every Nth tick of the current flame.
  static const int hunterEveryTicks = 9;

  /// Repeat period of a held direction.
  static const int stepMs = 170;

  /// Drag distance (px) below which no direction is produced.
  static const double deadZone = 16;

  /// Joystick knob clamp radius (px).
  static const double knobMax = 30;

  /// Seconds a match burns (used for the strike-button label).
  static const int matchSeconds = 8;

  /// Burn value right after a strike.
  static const double fullBurn = 100;

  /// Matches granted by a pickup.
  static const int pickupMatches = 2;
}
