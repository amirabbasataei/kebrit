/// Ember ("اخگر") rating icons.
///
/// * small (MLevels tile, 5×7): lit = flat `#ff8a2b` + `0 0 5px
///   rgba(255,140,40,.7)`, unlit = `rgba(239,227,208,.18)`.
/// * large (MComplete, 18×24): lit = `radial-gradient(circle at 50% 65%,
///   #fff1b8, #ff8a2b 60%)` + `0 0 16px rgba(255,140,40,.8)`, unlit =
///   `rgba(239,227,208,.16)`.
///
/// Both use `border-radius: 50% 50% 45% 45%`.
library;

import 'package:flutter/widgets.dart';

import '../../theme/tokens.dart';
import 'css.dart';

enum EmberSize { small, large }

class EmberIcon extends StatelessWidget {
  const EmberIcon({super.key, required this.lit, this.size = EmberSize.small});

  const EmberIcon.small({super.key, required this.lit})
    : size = EmberSize.small;
  const EmberIcon.large({super.key, required this.lit})
    : size = EmberSize.large;

  final bool lit;
  final EmberSize size;

  @override
  Widget build(BuildContext context) {
    final large = size == EmberSize.large;
    return CustomPaint(
      size: large ? const Size(18, 24) : const Size(5, 7),
      painter: _EmberPainter(lit, large),
    );
  }
}

/// A row of three embers (`gap` 3 small / 12 large), [count] of them lit.
/// The row's order follows the ambient text direction like the design's
/// flex row.
class EmberRow extends StatelessWidget {
  const EmberRow({
    super.key,
    required this.count,
    this.total = 3,
    this.size = EmberSize.small,
  });

  final int count;
  final int total;
  final EmberSize size;

  @override
  Widget build(BuildContext context) {
    final gap = size == EmberSize.large ? 12.0 : 3.0;
    return Semantics(
      container: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) SizedBox(width: gap),
            EmberIcon(lit: i < count, size: size),
          ],
        ],
      ),
    );
  }
}

class _EmberPainter extends CustomPainter {
  _EmberPainter(this.lit, this.large);
  final bool lit, large;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = pctRRect(
      rect,
      topH: .5,
      topV: .5,
      bottomH: .45,
      bottomV: .45,
    );
    if (!lit) {
      canvas.drawRRect(
        shape,
        Paint()..color = rgba(239, 227, 208, large ? .16 : .18),
      );
      return;
    }
    if (large) {
      paintCssShadow(
        canvas,
        shape,
        CssShadow(0, 0, 16, 0, rgba(255, 140, 40, .8)),
      );
      final g = cssRadialFarthestCorner(
        box: size,
        center: Offset(size.width * .5, size.height * .65),
        stops: const [CssStop(Color(0xFFFFF1B8), 0), CssStop(Kc.flameDeep, .6)],
      );
      canvas.drawRRect(shape, Paint()..shader = g.createShader(rect));
    } else {
      paintCssShadow(
        canvas,
        shape,
        CssShadow(0, 0, 5, 0, rgba(255, 140, 40, .7)),
      );
      canvas.drawRRect(shape, Paint()..color = Kc.flameDeep);
    }
  }

  @override
  bool shouldRepaint(_EmberPainter o) => o.lit != lit || o.large != large;
}
