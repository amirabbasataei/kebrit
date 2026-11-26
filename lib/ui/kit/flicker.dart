/// Flicker plumbing shared by [Flame] and `WarmFlicker`.
///
/// The design's CSS keyframes (`flame`, `flick`) run forever; the in-game
/// "reduce flicker" setting and `prefers-reduced-motion` turn them off. Wrap
/// the app (or a screen) in [FlickerScope] and every flickering widget stops
/// scheduling frames. Tests and goldens pin a frame with `phase:`.
library;

import 'package:flutter/widgets.dart';

/// Inherited "reduce flicker" setting (`AppSettings.reduceFlicker`).
class FlickerScope extends InheritedWidget {
  const FlickerScope({super.key, required this.reduce, required super.child});

  final bool reduce;

  static bool reduceOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FlickerScope>()?.reduce ?? false;

  @override
  bool updateShouldNotify(FlickerScope old) => old.reduce != reduce;
}

/// Drives a looping animation and rebuilds [builder] with `t` in 0..1.
///
/// * live: a controller repeats (`reverse` = CSS `alternate`) and `live` is
///   true;
/// * static (reduce flicker on, or [phase] given): no controller runs, `t` is
///   [phase] (or [restPhase]) and `live` is false, so nothing schedules a
///   frame.
class FlickerBuilder extends StatefulWidget {
  const FlickerBuilder({
    super.key,
    required this.duration,
    required this.builder,
    this.reverse = false,
    this.phase,
    this.reduce,
    this.restPhase = 0,
  });

  final Duration duration;
  final bool reverse;

  /// Pins the animation at this phase (golden tests).
  final double? phase;

  /// Overrides [FlickerScope]; null = inherit.
  final bool? reduce;

  /// Phase shown when flicker is reduced and no [phase] was given.
  final double restPhase;
  final Widget Function(BuildContext context, double t, bool live) builder;

  @override
  State<FlickerBuilder> createState() => _FlickerBuilderState();
}

class _FlickerBuilderState extends State<FlickerBuilder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  bool _live = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(FlickerBuilder old) {
    super.didUpdateWidget(old);
    _c.duration = widget.duration;
    if (old.reverse != widget.reverse && _c.isAnimating) _c.stop();
    _sync();
  }

  void _sync() {
    final reduce = widget.reduce ?? FlickerScope.reduceOf(context);
    final live = widget.phase == null && !reduce;
    if (live) {
      if (!_c.isAnimating) _c.repeat(reverse: widget.reverse);
    } else {
      _c.stop();
    }
    _live = live;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => widget.builder(
        context,
        _live ? _c.value : (widget.phase ?? widget.restPhase),
        _live,
      ),
    );
  }
}

/// A CSS `@keyframes` opacity track: `(percent, value)` pairs, eased with the
/// CSS default `ease` between keyframes.
class FlickerProfile {
  const FlickerProfile(this.duration, this.keys);

  final Duration duration;
  final List<(double, double)> keys;

  /// MGame: `flick 1.3s` – 1, .72 @18 %, .95 @40 %, .68 @63 %, .9 @82 %, 1.
  static const game = FlickerProfile(Duration(milliseconds: 1300), [
    (0, 1), (.18, .72), (.40, .95), (.63, .68), (.82, .9), (1, 1),
  ]);

  /// MTitle: `flick 1.6s` – 1, .8, .96, .74, .92, 1.
  static const title = FlickerProfile(Duration(milliseconds: 1600), [
    (0, 1), (.18, .8), (.40, .96), (.63, .74), (.82, .92), (1, 1),
  ]);

  double at(double t) {
    t = t.clamp(0.0, 1.0);
    for (var i = 1; i < keys.length; i++) {
      final (t1, v1) = keys[i];
      if (t <= t1) {
        final (t0, v0) = keys[i - 1];
        final k = t1 == t0 ? 1.0 : Curves.ease.transform((t - t0) / (t1 - t0));
        return v0 + (v1 - v0) * k;
      }
    }
    return keys.last.$2;
  }
}

/// Fades [child] with a [FlickerProfile] (the CSS `.flick` class). Static
/// (opacity 1) when flicker is reduced.
class FlickerOpacity extends StatelessWidget {
  const FlickerOpacity({
    super.key,
    required this.child,
    this.profile = FlickerProfile.game,
    this.phase,
    this.reduce,
  });

  final Widget child;
  final FlickerProfile profile;
  final double? phase;
  final bool? reduce;

  @override
  Widget build(BuildContext context) => FlickerBuilder(
        duration: profile.duration,
        phase: phase,
        reduce: reduce,
        restPhase: 0, // profile.at(0) == 1: steady full light
        builder: (context, t, live) =>
            Opacity(opacity: profile.at(t), child: child),
      );
}
