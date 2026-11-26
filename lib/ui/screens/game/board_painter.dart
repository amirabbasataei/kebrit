/// The gameplay board of MGame.dc.html: a 360×520 box at (15,150) holding the
/// floor, the 2.5D walls, the exit door, the match pickup, the player and the
/// hunters.
///
/// ## Stacking
///
/// The CSS stacks everything inside the board by `z-index`: wall row r
/// `r*10+5`, entities standing on row r `r*10+6`, the door `7`, the door light
/// and the pickup `2` (below every wall). Here one flat `Stack` holds all of
/// them sorted by that z (stable), each with a key, so a sprite that walks
/// onto the next row is re-ordered without losing its implicit animation.
///
/// ## Coordinates
///
/// [cellCenter] / [boardOrigin] map grid cells to the 390×844 design space.
/// Entities animate their position like the CSS `transition`: player
/// `.15s linear`, hunters `.5s ease`. [animate] = false turns that off.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../game/grid.dart';
import '../../../game/game_state.dart';
import '../../../theme/tokens.dart';
import '../../kit/css.dart';
import '../../kit/flame.dart';
import '../../kit/stone_wall.dart';
import '../tutorial/tutorial_parts.dart' show HunterPainter;

/// Top-left of the board in design space.
const Offset boardOrigin = Offset(15, 150);

/// Cell size in px.
const double kCell = 40;

/// Centre of grid cell ([x],[y]) in design space (the point the light is
/// centred on is `cellCenter(...)` shifted up 12 px: the player's torso).
Offset cellCenter(int x, int y) => Offset(
  boardOrigin.dx + x * kCell + kCell / 2,
  boardOrigin.dy + y * kCell + kCell / 2,
);

/// Where the light of the player standing on ([x],[y]) is centred.
Offset lightCenter(Cell c) {
  final p = cellCenter(c.x, c.y);
  return Offset(p.dx, p.dy - 12);
}

class GameBoard extends StatelessWidget {
  const GameBoard({
    super.key,
    required this.state,
    this.flickerPhase,
    this.reduceFlicker = false,
    this.animate = true,
  });

  final GameState state;

  /// Pins the player's flame flicker (goldens/tests).
  final double? flickerPhase;
  final bool reduceFlicker;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final grid = state.level.grid;
    final width = grid.cols * kCell, height = grid.rows * kCell;
    final exit = grid.exit;

    final layers = <_Z>[];
    var order = 0;
    void add(int z, Widget w) => layers.add(_Z(z, order++, w));

    for (var r = 0; r < grid.rows; r++) {
      add(
        r * 10 + 5,
        Positioned(
          key: ValueKey('walls$r'),
          left: 0,
          top: 0,
          child: MazeWalls(grid: grid, fromRow: r, toRow: r),
        ),
      );
    }
    add(
      7,
      Positioned(
        key: const ValueKey('door'),
        left: exit.x * kCell + 10,
        top: exit.y * kCell - 4,
        child: const ExitDoor(),
      ),
    );

    final p = state.player;
    add(
      p.y * 10 + 6,
      _Sprite(
        key: const ValueKey('player'),
        left: p.x * kCell + kCell / 2 - 12,
        top: p.y * kCell + kCell / 2 - 30,
        duration: animate ? const Duration(milliseconds: 150) : Duration.zero,
        curve: Curves.linear,
        child: PlayerSprite(
          lit: state.lit,
          flickerPhase: flickerPhase,
          reduceFlicker: reduceFlicker,
        ),
      ),
    );
    for (var i = 0; i < state.hunters.length; i++) {
      final h = state.hunters[i];
      add(
        h.y * 10 + 6,
        _Sprite(
          key: ValueKey('hunter$i'),
          left: h.x * kCell + kCell / 2 - 13,
          top: h.y * kCell + kCell / 2 - 34,
          duration: animate ? const Duration(milliseconds: 500) : Duration.zero,
          curve: Curves.ease,
          child: HunterSprite(alert: state.lit),
        ),
      );
    }
    layers.sort();

    return Positioned(
      left: boardOrigin.dx,
      top: boardOrigin.dy,
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topLeft,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: MazeFloor(cols: grid.cols, rows: grid.rows),
          ),
          Positioned(
            left: exit.x * kCell - 15,
            top: exit.y * kCell + 38,
            child: const ExitDoorLight(),
          ),
          for (final c in state.level.pickups)
            if (!state.pickedUp.contains(c))
              Positioned(
                key: ValueKey('pickup${c.x},${c.y}'),
                left: c.x * kCell + 9,
                top: c.y * kCell + 16,
                child: const MatchPickup(),
              ),
          for (final l in layers) l.widget,
        ],
      ),
    );
  }
}

class _Z implements Comparable<_Z> {
  _Z(this.z, this.order, this.widget);
  final int z, order;
  final Widget widget;

  @override
  int compareTo(_Z o) => z != o.z ? z.compareTo(o.z) : order.compareTo(o.order);
}

class _Sprite extends StatelessWidget {
  const _Sprite({
    super.key,
    required this.left,
    required this.top,
    required this.duration,
    required this.curve,
    required this.child,
  });

  final double left, top;
  final Duration duration;
  final Curve curve;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedPositioned(
    left: left,
    top: top,
    duration: duration,
    curve: curve,
    child: child,
  );
}

/// The two match sticks and two red heads lying on the floor (24×14).
class MatchPickup extends StatelessWidget {
  const MatchPickup({super.key});

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(size: Size(24, 14), painter: _PickupPainter());
}

class _PickupPainter extends CustomPainter {
  const _PickupPainter();

  void _stick(Canvas canvas, Rect r, double deg, Color c) {
    canvas.save();
    canvas.translate(r.center.dx, r.center.dy);
    canvas.rotate(deg * math.pi / 180);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: r.width, height: r.height),
      Paint()..color = c,
    );
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    _stick(
      canvas,
      const Rect.fromLTWH(2, 3, 18, 3),
      -12,
      const Color(0xFFD9B98A),
    );
    _stick(
      canvas,
      const Rect.fromLTWH(4, 7, 18, 3),
      8,
      const Color(0xFFCFAE7C),
    );
    canvas.drawOval(
      const Rect.fromLTWH(17, 0, 5, 5),
      Paint()..color = Kc.ember,
    );
    canvas.drawOval(
      const Rect.fromLTWH(19, 6, 5, 5),
      Paint()..color = const Color(0xFFB8392A),
    );
  }

  @override
  bool shouldRepaint(_PickupPainter o) => false;
}

/// The player: 24×36, optional 8×12 flame at (17,−1).
class PlayerSprite extends StatelessWidget {
  const PlayerSprite({
    super.key,
    required this.lit,
    this.flickerPhase,
    this.reduceFlicker = false,
  });

  final bool lit;
  final double? flickerPhase;
  final bool reduceFlicker;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 24,
    height: 36,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned.fill(child: CustomPaint(painter: _PlayerPainter())),
        if (lit)
          Positioned(
            left: 17,
            top: -1,
            child: Flame.player(
              phase: flickerPhase,
              reduceFlicker: reduceFlicker ? true : null,
            ),
          ),
      ],
    ),
  );
}

class _PlayerPainter extends CustomPainter {
  const _PlayerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
      const Rect.fromLTWH(2, 30, 20, 6),
      Paint()..color = rgba(0, 0, 0, .5),
    );
    const bodyRect = Rect.fromLTWH(4, 13, 16, 21);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        bodyRect,
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(8),
        bottomLeft: const Radius.circular(5),
        bottomRight: const Radius.circular(5),
      ),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9A8268), Color(0xFF6B5744)],
        ).createShader(bodyRect),
    );
    // Head with `inset 0 -4px 0 #3a2c20`: a dark crescent along the bottom.
    const head = Rect.fromLTWH(5, 5, 14, 14);
    canvas.save();
    canvas.clipPath(Path()..addOval(head));
    canvas.drawRect(head, Paint()..color = const Color(0xFF3A2C20));
    canvas.drawOval(
      head.shift(const Offset(0, -4)),
      Paint()..color = const Color(0xFF7A6550),
    );
    canvas.restore();
    // The match in the hand: 3×12 at (19,10), rotated 14° about its centre.
    canvas.save();
    canvas.translate(20.5, 16);
    canvas.rotate(14 * math.pi / 180);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: 3, height: 12),
      Paint()..color = Kc.matchStick,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PlayerPainter o) => false;
}

/// A hunter: 26×40 silhouette (see [HunterPainter]) with a ground shadow, eyes
/// lit while the player's flame burns, and the "!" bubble when [alert].
class HunterSprite extends StatelessWidget {
  const HunterSprite({super.key, required this.alert});

  final bool alert;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 26,
    height: 40,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned.fill(
          child: CustomPaint(painter: _HunterShadowPainter()),
        ),
        Positioned.fill(
          child: CustomPaint(painter: HunterPainter(alert ? 1 : 0)),
        ),
        if (alert)
          Positioned(
            left: 5,
            top: -16,
            width: 16,
            height: 16,
            child: const _AlertBubble(),
          ),
      ],
    ),
  );
}

class _HunterShadowPainter extends CustomPainter {
  const _HunterShadowPainter();

  @override
  void paint(Canvas canvas, Size size) => canvas.drawOval(
    const Rect.fromLTWH(1, 33, 24, 7),
    Paint()..color = rgba(0, 0, 0, .55),
  );

  @override
  bool shouldRepaint(_HunterShadowPainter o) => false;
}

class _AlertBubble extends StatelessWidget {
  const _AlertBubble();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(shape: BoxShape.circle, color: Kc.danger),
    child: Center(
      child: Text(
        '!',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 16 / 11,
          color: Color(0xFF1A0B05),
        ),
      ),
    ),
  );
}
