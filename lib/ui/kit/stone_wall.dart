/// 2.5D stone walls (MGame / MPause maze, MLevels tiles) and the exit door.
///
/// A wall cell is a [cell]-square *top face* (165° gradient, three shades
/// picked by `(r*7 + c*3) % 3`) with a [WallStyle.frontHeight] px *front face*
/// directly below it. In CSS the top face of cell (c, r) sits at
/// `y = r*cell − frontHeight`, so the front of row r is overlapped by the top
/// of row r+1 wherever that is a wall, and visible where it is floor.
///
/// ## Phase 7 API
///
/// * [paintStoneWall] – paints one cell (shadow → front → top) at a rect.
/// * [MazeWallsPainter] / [MazeWalls] – paints rows `[fromRow, toRow]` of a
///   [Grid] (wall **and** exit cells; the exit is drawn as a wall, the
///   [ExitDoor] sprite goes on top). Entities are z-sorted with walls by
///   *row*: wall row r (`z = r*10+5`) < entities on row r (`r*10+6`) < wall
///   row r+1, so Phase 7 stacks `MazeWalls(fromRow: r, toRow: r)` and the
///   entities of row r alternately. All rows at once (default) is what the
///   blurred pause backdrop uses. The painter draws up to [WallStyle.frontHeight]
///   px *above* its box (row 0 tops sit at y = −12): do not clip it.
/// * [MazeFloor] – the `#2a211b` floor with the 20 px grid and board shadow.
///
/// ## CSS differences
///
/// `box-shadow: inset 0 1px 0 …` / `inset 0 -2px 0 …` (top highlight, bottom
/// edge) are not supported by Flutter; they are painted as 1 px / 2 px strips
/// over the top face, which is pixel-identical for zero-blur offset shadows.
/// `repeating-linear-gradient` joints are 1 px rects painted without
/// anti-aliasing.
library;

import 'package:flutter/widgets.dart';

import '../../game/grid.dart';
import '../../theme/tokens.dart';
import 'css.dart';

/// Face / shadow parameters of one wall look.
class WallStyle {
  const WallStyle({
    required this.frontColor,
    required this.frontHeight,
    this.frontHighlight = 0,
    this.jointPeriod = 0,
    this.jointStart = 0,
    this.jointAlpha = 0,
    this.frontShadow,
    this.topHighlight = 0,
    this.bottomEdge = 0,
  });

  final Color frontColor;
  final double frontHeight;

  /// Alpha of the 1 px `rgba(255,210,160,a)` line on top of the front face.
  final double frontHighlight;

  /// 1 px dark vertical joints at `jointStart + k * jointPeriod` (0 = none).
  final double jointPeriod, jointStart, jointAlpha;
  final CssShadow? frontShadow;

  /// Alpha of the top-face `inset 0 1px 0 rgba(255,225,190,a)` strip.
  final double topHighlight;

  /// Alpha of the top-face `inset 0 -2px 0 rgba(0,0,0,a)` strip.
  final double bottomEdge;

  /// MGame maze wall.
  static final maze = WallStyle(
    frontColor: Kc.wallFront,
    frontHeight: 12,
    frontHighlight: .12,
    jointPeriod: 20,
    jointStart: 19,
    jointAlpha: .45,
    frontShadow: CssShadow(0, 6, 9, 0, rgba(0, 0, 0, .5)),
    topHighlight: .18,
    bottomEdge: .25,
  );

  /// MPause's blurred backdrop: flat front, plain top.
  static const flat = WallStyle(frontColor: Kc.wallFront, frontHeight: 12);

  /// MLevels tile (58×54 top + 10 px front).
  static final levelTile = WallStyle(
    frontColor: Kc.wallFront,
    frontHeight: 10,
    jointPeriod: 19,
    jointStart: 18,
    jointAlpha: .4,
    frontShadow: CssShadow(0, 6, 10, 0, rgba(0, 0, 0, .5)),
    topHighlight: .16,
  );

  WallStyle copyWith({
    Color? frontColor,
    double? topHighlight,
    double? bottomEdge,
  }) => WallStyle(
    frontColor: frontColor ?? this.frontColor,
    frontHeight: frontHeight,
    frontHighlight: frontHighlight,
    jointPeriod: jointPeriod,
    jointStart: jointStart,
    jointAlpha: jointAlpha,
    frontShadow: frontShadow,
    topHighlight: topHighlight ?? this.topHighlight,
    bottomEdge: bottomEdge ?? this.bottomEdge,
  );
}

/// `(r*7 + c*3) % 3` – the design's shade pick (`Kc.wallTops` index).
int wallShade(int row, int col) => (row * 7 + col * 3) % 3;

/// Paints one wall: shadow of the front face, the front face, then the top
/// face at [top] filled with [topGradient].
void paintStoneWall(
  Canvas canvas,
  Rect top,
  WallStyle style,
  Gradient topGradient,
) {
  final front = Rect.fromLTWH(
    top.left,
    top.bottom,
    top.width,
    style.frontHeight,
  );

  if (style.frontShadow != null) {
    paintCssShadow(canvas, RRect.fromRectXY(front, 0, 0), style.frontShadow!);
  }
  canvas.drawRect(front, Paint()..color = style.frontColor);
  final crisp = Paint()..isAntiAlias = false;
  if (style.frontHighlight > 0) {
    canvas.drawRect(
      Rect.fromLTWH(front.left, front.top, front.width, 1),
      crisp..color = rgba(255, 210, 160, style.frontHighlight),
    );
  }
  if (style.jointPeriod > 0) {
    crisp.color = rgba(0, 0, 0, style.jointAlpha);
    for (var x = style.jointStart; x < front.width; x += style.jointPeriod) {
      canvas.drawRect(
        Rect.fromLTWH(front.left + x, front.top, 1, front.height),
        crisp,
      );
    }
  }

  canvas.drawRect(top, Paint()..shader = topGradient.createShader(top));
  if (style.topHighlight > 0) {
    canvas.drawRect(
      Rect.fromLTWH(top.left, top.top, top.width, 1),
      crisp..color = rgba(255, 225, 190, style.topHighlight),
    );
  }
  if (style.bottomEdge > 0) {
    canvas.drawRect(
      Rect.fromLTWH(top.left, top.bottom - 2, top.width, 2),
      crisp..color = rgba(0, 0, 0, style.bottomEdge),
    );
  }
}

/// Paints the walls of rows `[fromRow, toRow]` (inclusive; default all) of
/// [grid], row-major, so later cells/rows overlap earlier ones like the CSS
/// z-order. Origin = board top-left; the top face of (c, r) is drawn at
/// `(c*cell, r*cell − frontHeight)`.
class MazeWallsPainter extends CustomPainter {
  MazeWallsPainter(
    this.grid, {
    this.style,
    this.fromRow = 0,
    this.toRow,
    this.cell = 40,
  });

  final Grid grid;
  final WallStyle? style;
  final int fromRow;
  final int? toRow;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final st = style ?? WallStyle.maze;
    final last = (toRow ?? grid.rows - 1).clamp(0, grid.rows - 1);
    for (var r = fromRow; r <= last; r++) {
      for (var c = 0; c < grid.cols; c++) {
        if (grid.typeAt(c, r) == CellType.floor) continue;
        final top = Rect.fromLTWH(
          c * cell,
          r * cell - st.frontHeight,
          cell,
          cell,
        );
        paintStoneWall(canvas, top, st, Kc.wallTop(wallShade(r, c)));
      }
    }
  }

  @override
  bool shouldRepaint(MazeWallsPainter o) =>
      o.grid != grid ||
      o.style != style ||
      o.fromRow != fromRow ||
      o.toRow != toRow ||
      o.cell != cell;
}

/// Widget around [MazeWallsPainter], sized `cols*cell × rows*cell`.
class MazeWalls extends StatelessWidget {
  const MazeWalls({
    super.key,
    required this.grid,
    this.style,
    this.fromRow = 0,
    this.toRow,
    this.cell = 40,
  });

  final Grid grid;
  final WallStyle? style;
  final int fromRow;
  final int? toRow;
  final double cell;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(grid.cols * cell, grid.rows * cell),
    painter: MazeWallsPainter(
      grid,
      style: style,
      fromRow: fromRow,
      toRow: toRow,
      cell: cell,
    ),
  );
}

/// A single wall cell on its own (kit sheet, level tiles). The box is
/// `width × (topHeight + style.frontHeight)`; the top face is at the top.
class StoneWallCell extends StatelessWidget {
  const StoneWallCell({
    super.key,
    this.width = 40,
    this.topHeight = 40,
    this.shade = 0,
    this.style,
    this.topGradient,
  });

  final double width, topHeight;
  final int shade;
  final WallStyle? style;

  /// Overrides the shade gradient (level tiles use other gradients).
  final Gradient? topGradient;

  @override
  Widget build(BuildContext context) {
    final st = style ?? WallStyle.maze;
    return CustomPaint(
      size: Size(width, topHeight + st.frontHeight),
      painter: _CellPainter(
        st,
        topGradient ??
            cssLinear(
              deg: 165,
              box: Size(width, topHeight),
              colors: Kc.wallTops[shade % 3],
            ),
        Size(width, topHeight),
      ),
    );
  }
}

class _CellPainter extends CustomPainter {
  _CellPainter(this.style, this.gradient, this.top);
  final WallStyle style;
  final Gradient gradient;
  final Size top;

  @override
  void paint(Canvas canvas, Size size) =>
      paintStoneWall(canvas, Offset.zero & top, style, gradient);

  @override
  bool shouldRepaint(_CellPainter o) =>
      o.style != style || o.gradient != gradient || o.top != top;
}

/// Maze floor: `#2a211b` with a 1 px `rgba(0,0,0,.3)` grid every 20 px and the
/// board shadow `0 30px 60px rgba(0,0,0,.7)`. Sized `cols*cell × rows*cell`.
class MazeFloor extends StatelessWidget {
  const MazeFloor({
    super.key,
    required this.cols,
    required this.rows,
    this.cell = 40,
    this.shadow = true,
  });

  final int cols, rows;
  final double cell;
  final bool shadow;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(cols * cell, rows * cell),
    painter: _FloorPainter(shadow),
  );
}

class _FloorPainter extends CustomPainter {
  _FloorPainter(this.shadow);
  final bool shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (shadow) {
      paintCssShadow(
        canvas,
        RRect.fromRectXY(rect, 0, 0),
        CssShadow(0, 30, 60, 0, rgba(0, 0, 0, .7)),
      );
    }
    canvas.drawRect(rect, Paint()..color = Kc.floor);
    final line = Paint()
      ..color = rgba(0, 0, 0, .3)
      ..isAntiAlias = false;
    for (var y = 0.0; y < size.height; y += 20) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), line);
    }
    for (var x = 0.0; x < size.width; x += 20) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), line);
    }
  }

  @override
  bool shouldRepaint(_FloorPainter o) => o.shadow != shadow;
}

/// The glowing exit door sprite (20×44; MGame places it at x 170, y −4 of the
/// board, centred on the exit column): rings `0 0 0 3px #3b2c21`, glow
/// `0 0 22px rgba(255,160,70,.7)`, `linear-gradient(#ffe6ad, #ff9c3e 65%,
/// #d4661b)`, radius 10 10 2 2.
class ExitDoor extends StatelessWidget {
  const ExitDoor({super.key});

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(size: Size(20, 44), painter: _DoorPainter());
}

class _DoorPainter extends CustomPainter {
  const _DoorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = RRect.fromRectAndCorners(
      rect,
      topLeft: const Radius.circular(10),
      topRight: const Radius.circular(10),
      bottomLeft: const Radius.circular(2),
      bottomRight: const Radius.circular(2),
    );
    paintCssShadow(
      canvas,
      shape,
      CssShadow(0, 0, 22, 0, rgba(255, 160, 70, .7)),
    );
    paintCssShadow(
      canvas,
      shape,
      CssShadow(0, 0, 0, 3, const Color(0xFF3B2C21)),
    );
    canvas.drawRRect(
      shape,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE6AD), Color(0xFFFF9C3E), Color(0xFFD4661B)],
          stops: [0, .65, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_DoorPainter o) => false;
}

/// The light pool the door casts on the floor (70×50, MGame at x 145, y 38):
/// `radial-gradient(ellipse at 50% 0%, rgba(255,170,80,.5),
/// rgba(255,170,80,0) 70%)` clipped to an ellipse.
class ExitDoorLight extends StatelessWidget {
  const ExitDoorLight({super.key});

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(size: Size(70, 50), painter: _DoorLightPainter());
}

class _DoorLightPainter extends CustomPainter {
  const _DoorLightPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final g = cssEllipseFarthestCorner(
      box: size,
      center: Offset(size.width / 2, 0),
      stops: [
        CssStop(rgba(255, 170, 80, .5), 0),
        CssStop(rgba(255, 170, 80, 0), .7),
      ],
    );
    canvas.drawOval(rect, Paint()..shader = g.createShader(rect));
  }

  @override
  bool shouldRepaint(_DoorLightPainter o) => false;
}
