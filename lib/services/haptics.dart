import 'package:flutter/services.dart';

/// Haptic feedback hook. The game only needs one cue (a hunter moved while the
/// flame is lit); Phase 11 injects the real one via `AppScope`.
abstract class Haptics {
  const Haptics();

  /// A hunter took a step toward the player.
  void hunterStep();
}

class NoopHaptics extends Haptics {
  const NoopHaptics();

  @override
  void hunterStep() {}
}

class SystemHaptics extends Haptics {
  const SystemHaptics();

  @override
  void hunterStep() => HapticFeedback.selectionClick();
}
