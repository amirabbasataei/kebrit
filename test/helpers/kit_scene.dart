import 'package:flutter/widgets.dart';
import 'package:kebrit/data/levels.dart';
import 'package:kebrit/game/grid.dart';
import 'package:kebrit/ui/kit/flame.dart';
import 'package:kebrit/ui/kit/light_overlay.dart';
import 'package:kebrit/ui/kit/stone_bg.dart';
import 'package:kebrit/ui/kit/stone_wall.dart';

/// MGame's board composition from kit pieces only (no entities except the
/// player's flame): backdrop, board at (15,150), door, optional light layers.
/// Player at cell (1,11) like the design's mock.
Widget mazeScene({
  bool lit = true,
  double burn = 72,
  bool overlay = false,
  double? flamePhase = .5,
}) {
  final Grid grid = Levels.byId(7).grid;
  const cx = 15 + 1 * 40 + 20.0, cy = 150 + 11 * 40 + 20.0 - 12;
  return Stack(
    children: [
      const Positioned.fill(child: RadialBackdrop()),
      Positioned(
        left: 15,
        top: 150,
        width: 360,
        height: 520,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            MazeFloor(cols: grid.cols, rows: grid.rows),
            const Positioned(left: 145, top: 38, child: ExitDoorLight()),
            MazeWalls(grid: grid),
            const Positioned(left: 170, top: -4, child: ExitDoor()),
            if (lit)
              Positioned(
                left: 1 * 40 + 20 - 12 + 17,
                top: 11 * 40 + 20 - 30 - 1,
                child: Flame.player(phase: flamePhase),
              ),
          ],
        ),
      ),
      if (overlay) ...[
        lit
            ? LightOverlay.lit(center: const Offset(cx, cy), burn: burn)
            : LightOverlay.dark(center: const Offset(cx, cy)),
        if (lit)
          WarmFlicker.game(
              center: const Offset(cx, cy), burn: burn, phase: 0),
        Positioned(
          left: 145,
          top: 100,
          child: DoorGlow(opacity: lit ? .25 : .8),
        ),
      ],
    ],
  );
}
