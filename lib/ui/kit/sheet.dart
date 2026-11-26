/// Bottom sheet from MPause / MLevels:
///
/// ```css
/// border-radius: 24px 24px 0 0;
/// background: linear-gradient(170deg, #241b15, #120d0a);
/// border-top: 1px solid rgba(239,227,208,.12);
/// box-shadow: 0 -20px 50px rgba(0,0,0,.5);
/// ```
///
/// Flutter cannot give a rounded box a top-only `Border`, so the 1 px curved
/// top border is painted as a DRRect (outer rrect minus the same rrect moved
/// down 1 px with vertical corner radius 23). The shadow is drawn with
/// [paintCssShadow].
library;

import 'package:flutter/widgets.dart';

import '../../theme/tokens.dart';
import 'css.dart';

class BottomSheetPanel extends StatelessWidget {
  const BottomSheetPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 24, 24, 36),
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Fixed height (MLevels uses 300); null sizes to the content.
  final double? height;

  static const radius = Kc.sheetRadius;
  static final shadow = CssShadow(0, -20, 50, 0, rgba(0, 0, 0, .5));

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SheetPainter(),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _SheetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const r = BottomSheetPanel.radius;
    final rect = Offset.zero & size;
    final outer = RRect.fromRectAndCorners(
      rect,
      topLeft: const Radius.circular(r),
      topRight: const Radius.circular(r),
    );
    paintCssShadow(canvas, outer, BottomSheetPanel.shadow);
    canvas.drawRRect(
      outer,
      Paint()
        ..shader = cssLinear(
          deg: 170,
          box: size,
          colors: const [Color(0xFF241B15), Color(0xFF120D0A)],
        ).createShader(rect),
    );
    final inner = RRect.fromLTRBAndCorners(
      0,
      1,
      size.width,
      size.height,
      topLeft: const Radius.elliptical(r, r - 1),
      topRight: const Radius.elliptical(r, r - 1),
    );
    canvas.drawDRRect(outer, inner, Paint()..color = Kc.sheetBorder);
  }

  @override
  bool shouldRepaint(_SheetPainter o) => false;
}
