/// CSS `border: Npx dashed` look (Chromium: dash = 3N / gap = 2N for N < 3).
library;

import 'dart:ui' show PathMetric;

import 'package:flutter/widgets.dart';

/// Dash pattern Chromium uses for a `dashed` border of [width] px.
(double dash, double gap) cssDashPattern(double width) =>
    width >= 3 ? (width * 2, width) : (width * 3, width * 2);

Path _dashPath(Path source, double dash, double gap) {
  final out = Path();
  for (final PathMetric m in source.computeMetrics()) {
    // Spread the remainder over the gaps so the pattern closes evenly.
    final count = (m.length / (dash + gap)).round().clamp(1, 1 << 20);
    final g = (m.length - dash * count) / count;
    var d = 0.0;
    for (var n = 0; n < count; n++) {
      out.addPath(m.extractPath(d, d + dash), Offset.zero);
      d += dash + g;
    }
  }
  return out;
}

/// A dashed rounded-rect outline drawn inside the box (as a CSS border).
class DashedBorderBox extends StatelessWidget {
  const DashedBorderBox({
    super.key,
    required this.color,
    this.width = 1,
    this.radius = 0,
    this.padding = EdgeInsets.zero,
    required this.child,
  });

  final Color color;
  final double width;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
        foregroundPainter: _DashedRRectPainter(color, width, radius),
        child: Padding(padding: padding, child: child),
      );
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter(this.color, this.width, this.radius);
  final Color color;
  final double width, radius;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(width / 2),
      Radius.circular((radius - width / 2).clamp(0, double.infinity)),
    );
    final (dash, gap) = cssDashPattern(width);
    canvas.drawPath(
      _dashPath(Path()..addRRect(r), dash, gap),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_DashedRRectPainter o) =>
      o.color != color || o.width != width || o.radius != radius;
}

/// A horizontal dashed line (`border-top: Npx dashed`) filling its width.
class DashedLine extends StatelessWidget {
  const DashedLine({super.key, required this.color, this.width = 2});
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: width,
        child: CustomPaint(
          size: Size.fromHeight(width),
          painter: _DashedLinePainter(color, width),
        ),
      );
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter(this.color, this.width);
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final (dash, gap) = cssDashPattern(width);
    final p = Path()
      ..moveTo(0, width / 2)
      ..lineTo(size.width, width / 2);
    canvas.drawPath(
      _dashPath(p, dash, gap),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_DashedLinePainter o) => o.color != color || o.width != width;
}
