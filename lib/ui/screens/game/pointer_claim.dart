/// HUD buttons "stop propagation" of pointer-down (MGame `stop`): Flutter has
/// no such thing, but hit testing delivers events to the innermost listener
/// first, so a [PointerClaim] records the pointer id and the screen-wide drag
/// [Listener] (outer) skips claimed pointers.
library;

import 'package:flutter/widgets.dart';

/// Set of pointer ids claimed by HUD buttons; provided by `GameScreen`.
class PointerClaims extends InheritedWidget {
  const PointerClaims({super.key, required this.claimed, required super.child});

  final Set<int> claimed;

  static Set<int>? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<PointerClaims>()?.claimed;

  @override
  bool updateShouldNotify(PointerClaims old) => claimed != old.claimed;
}

/// Wraps a HUD button so pointers that start on it never reach the joystick.
class PointerClaim extends StatelessWidget {
  const PointerClaim({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final claimed = PointerClaims.maybeOf(context);
    if (claimed == null) return child;
    return Listener(onPointerDown: (e) => claimed.add(e.pointer), child: child);
  }
}
