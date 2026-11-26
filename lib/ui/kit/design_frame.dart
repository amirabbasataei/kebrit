/// The 390×844 design canvas every full screen is drawn on, scaled to fit
/// (`FittedBox(contain)`) and clipped like the design's `overflow: hidden`.
library;

import 'package:flutter/widgets.dart';

import '../../theme/tokens.dart';

class DesignFrame extends StatelessWidget {
  const DesignFrame({
    super.key,
    this.background = Kc.page,
    required this.children,
  });

  /// Colour shown in the letterbox around the scaled canvas.
  final Color background;

  /// Stack children, positioned in design pixels (physical left/top).
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: background,
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: Kc.designWidth,
            height: Kc.designHeight,
            child: Stack(clipBehavior: Clip.hardEdge, children: children),
          ),
        ),
      );
}
