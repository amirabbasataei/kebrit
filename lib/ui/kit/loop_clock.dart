/// A seconds clock for screens whose animation is a pure function of time
/// (the pattern from Splash/Tutorial).
///
/// * live: a [Ticker] reports elapsed seconds;
/// * pinned ([time] given, goldens/tests): no ticker, the builder gets [time];
/// * reduced ([reduce] true, or `FlickerScope`): no ticker, the builder gets
///   [restTime].
library;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'flicker.dart';

class LoopClock extends StatefulWidget {
  const LoopClock({
    super.key,
    required this.builder,
    this.time,
    this.reduce,
    this.restTime = 0,
  });

  final double? time;

  /// Overrides [FlickerScope]; null = inherit.
  final bool? reduce;
  final double restTime;
  final Widget Function(BuildContext context, double seconds) builder;

  @override
  State<LoopClock> createState() => _LoopClockState();
}

class _LoopClockState extends State<LoopClock>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  double _seconds = 0;
  bool _reduce = false;

  void _sync() {
    final live = widget.time == null && !_reduce;
    if (live && _ticker == null) {
      _ticker = createTicker((d) => setState(() => _seconds = d.inMicroseconds / 1e6))
        ..start();
    } else if (!live && _ticker != null) {
      _ticker!.dispose();
      _ticker = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = widget.reduce ?? FlickerScope.reduceOf(context);
    _sync();
  }

  @override
  void didUpdateWidget(LoopClock old) {
    super.didUpdateWidget(old);
    _reduce = widget.reduce ?? FlickerScope.reduceOf(context);
    _sync();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.time ?? (_reduce ? widget.restTime : _seconds);
    return widget.builder(context, t);
  }
}
