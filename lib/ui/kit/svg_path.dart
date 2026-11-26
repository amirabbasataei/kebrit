/// Minimal SVG support for the design's stroke icons (no `flutter_svg`).
///
/// The mobile boards only use 24×24 line icons: `<path d="…">` and
/// `<circle>`, `fill="none"`, round caps/joins. [parseSvgPath] converts path
/// data (M L H V C S Q T A Z, absolute + relative, implicit command
/// repetition, compact numbers such as `1.4-7` / `.8` and packed arc flags)
/// into a Flutter [Path]; [SvgIcon] strokes it scaled from the viewBox.
///
/// Arcs map onto `Path.arcToPoint` (same endpoint parametrisation as SVG:
/// sweep-flag 1 = clockwise on screen, radii are scaled up when too small).
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Parses SVG path data [d] into a [Path] in viewBox units.
Path parseSvgPath(String d) => _PathParser(d).parse();

class _PathParser {
  _PathParser(this.s);
  final String s;
  int i = 0;

  static final _num = RegExp(r'[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?');

  bool _isCommand(String c) => 'MmLlHhVvCcSsQqTtAaZz'.contains(c);

  void _skipSep() {
    while (i < s.length && (s[i] == ' ' || s[i] == ',' || s[i] == '\n' || s[i] == '\t')) {
      i++;
    }
  }

  bool get _atNumber {
    _skipSep();
    if (i >= s.length) return false;
    final c = s[i];
    return c == '-' || c == '+' || c == '.' || (c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57);
  }

  double _number() {
    _skipSep();
    final m = _num.matchAsPrefix(s, i);
    if (m == null) throw FormatException('number expected at $i in "$s"');
    i = m.end;
    return double.parse(m.group(0)!);
  }

  /// Arc flags are single characters and may be packed (`a3 3 0 1060`).
  bool _flag() {
    _skipSep();
    final c = s[i++];
    if (c != '0' && c != '1') throw FormatException('flag expected at ${i - 1} in "$s"');
    return c == '1';
  }

  Path parse() {
    final path = Path();
    var x = 0.0, y = 0.0; // current point
    var sx = 0.0, sy = 0.0; // sub-path start
    var cx = 0.0, cy = 0.0; // last control point (for S/T reflection)
    var prev = ''; // previous command (upper-case)

    while (true) {
      _skipSep();
      if (i >= s.length) break;
      var cmd = s[i];
      if (!_isCommand(cmd)) throw FormatException('command expected at $i in "$s"');
      i++;
      final rel = cmd == cmd.toLowerCase();
      var up = cmd.toUpperCase();

      if (up == 'Z') {
        path.close();
        x = sx;
        y = sy;
        prev = 'Z';
        continue;
      }

      var first = true;
      // Implicit repetition: further coordinate sets repeat the command
      // (M → L).
      while (first || _atNumber) {
        first = false;
        switch (up) {
          case 'M':
            final nx = _number() + (rel ? x : 0), ny = _number() + (rel ? y : 0);
            path.moveTo(nx, ny);
            x = sx = nx;
            y = sy = ny;
            up = 'L';
            prev = 'M';
          case 'L':
            final nx = _number() + (rel ? x : 0), ny = _number() + (rel ? y : 0);
            path.lineTo(nx, ny);
            x = nx;
            y = ny;
            prev = 'L';
          case 'H':
            final nx = _number() + (rel ? x : 0);
            path.lineTo(nx, y);
            x = nx;
            prev = 'H';
          case 'V':
            final ny = _number() + (rel ? y : 0);
            path.lineTo(x, ny);
            y = ny;
            prev = 'V';
          case 'C':
            final x1 = _number() + (rel ? x : 0), y1 = _number() + (rel ? y : 0);
            final x2 = _number() + (rel ? x : 0), y2 = _number() + (rel ? y : 0);
            final nx = _number() + (rel ? x : 0), ny = _number() + (rel ? y : 0);
            path.cubicTo(x1, y1, x2, y2, nx, ny);
            cx = x2;
            cy = y2;
            x = nx;
            y = ny;
            prev = 'C';
          case 'S':
            final x2 = _number() + (rel ? x : 0), y2 = _number() + (rel ? y : 0);
            final nx = _number() + (rel ? x : 0), ny = _number() + (rel ? y : 0);
            final smooth = prev == 'C' || prev == 'S';
            final x1 = smooth ? 2 * x - cx : x, y1 = smooth ? 2 * y - cy : y;
            path.cubicTo(x1, y1, x2, y2, nx, ny);
            cx = x2;
            cy = y2;
            x = nx;
            y = ny;
            prev = 'S';
          case 'Q':
            final x1 = _number() + (rel ? x : 0), y1 = _number() + (rel ? y : 0);
            final nx = _number() + (rel ? x : 0), ny = _number() + (rel ? y : 0);
            path.quadraticBezierTo(x1, y1, nx, ny);
            cx = x1;
            cy = y1;
            x = nx;
            y = ny;
            prev = 'Q';
          case 'T':
            final nx = _number() + (rel ? x : 0), ny = _number() + (rel ? y : 0);
            final smooth = prev == 'Q' || prev == 'T';
            final x1 = smooth ? 2 * x - cx : x, y1 = smooth ? 2 * y - cy : y;
            path.quadraticBezierTo(x1, y1, nx, ny);
            cx = x1;
            cy = y1;
            x = nx;
            y = ny;
            prev = 'T';
          case 'A':
            final rx = _number(), ry = _number(), rot = _number();
            final large = _flag(), sweep = _flag();
            final nx = _number() + (rel ? x : 0), ny = _number() + (rel ? y : 0);
            if (rx == 0 || ry == 0) {
              path.lineTo(nx, ny);
            } else {
              path.arcToPoint(
                Offset(nx, ny),
                radius: Radius.elliptical(rx.abs(), ry.abs()),
                rotation: rot * math.pi / 180,
                largeArc: large,
                clockwise: sweep,
              );
            }
            x = nx;
            y = ny;
            prev = 'A';
          default:
            throw FormatException('unsupported command $cmd');
        }
      }
    }
    return path;
  }
}

/// A 24-unit stroke icon: path data strings and `<circle>`s as `(cx, cy, r)`.
class SvgIconData {
  const SvgIconData(this.paths, {this.circles = const []});
  final List<String> paths;
  final List<(double, double, double)> circles;

  Path toPath() {
    final p = Path();
    for (final d in paths) {
      p.addPath(parseSvgPath(d), Offset.zero);
    }
    for (final (cx, cy, r) in circles) {
      p.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    }
    return p;
  }
}

/// Strokes [data] (viewBox 24×24) at [size] px: `fill="none"`,
/// `stroke-linecap/linejoin="round"`, [strokeWidth] in viewBox units.
class SvgIcon extends StatelessWidget {
  const SvgIcon(
    this.data, {
    super.key,
    required this.color,
    this.size = 24,
    this.strokeWidth = 1.8,
    this.viewBox = 24,
  });

  final SvgIconData data;
  final Color color;
  final double size;
  final double strokeWidth;
  final double viewBox;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: CustomPaint(
          size: Size.square(size),
          painter: _SvgIconPainter(data, color, strokeWidth, viewBox),
        ),
      );
}

class _SvgIconPainter extends CustomPainter {
  _SvgIconPainter(this.data, this.color, this.stroke, this.viewBox)
      : path = data.toPath();
  final SvgIconData data;
  final Color color;
  final double stroke, viewBox;
  final Path path;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / viewBox;
    canvas.save();
    canvas.scale(k);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SvgIconPainter o) =>
      o.data != data || o.color != color || o.stroke != stroke || o.viewBox != viewBox;
}
