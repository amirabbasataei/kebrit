// Golden sheets: wall cells and the full maze board. Goldens are generated and
// verified only on Windows (Windows Server 2019); do not copy them between
// machines.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/data/levels.dart';
import 'package:kebrit/theme/tokens.dart';
import 'package:kebrit/ui/kit/css.dart';
import 'package:kebrit/ui/kit/stone_wall.dart';

import '../helpers/fonts.dart';
import '../helpers/golden_harness.dart';
import '../helpers/kit_scene.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('kit wall cells: shades, level tiles, flat, door', (tester) async {
    await pumpScreen(
      tester,
      ColoredBox(
        color: Kc.floor,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Three maze shades, 1× and 3×.
            for (var i = 0; i < 3; i++)
              Positioned(
                  left: 20.0 + i * 60,
                  top: 20,
                  child: StoneWallCell(shade: i)),
            for (var i = 0; i < 3; i++)
              Positioned(
                left: 20.0 + i * 120,
                top: 120,
                child: Transform.scale(
                  scale: 2.5,
                  alignment: Alignment.topLeft,
                  child: StoneWallCell(shade: i),
                ),
              ),
            // Flat (pause) style.
            const Positioned(
              left: 220,
              top: 20,
              child: StoneWallCell(style: WallStyle.flat),
            ),
            // MLevels tiles: done / current / locked.
            Positioned(
              left: 20,
              top: 300,
              child: StoneWallCell(
                width: 58,
                topHeight: 54,
                style: WallStyle.levelTile,
                topGradient: Kc.wallTop(0),
              ),
            ),
            Positioned(
              left: 90,
              top: 300,
              child: StoneWallCell(
                width: 58,
                topHeight: 54,
                style: WallStyle.levelTile,
                topGradient: cssLinear(
                  deg: 165,
                  box: const Size(58, 54),
                  colors: const [Color(0xFF8A6C50), Color(0xFF6B523D)],
                ),
              ),
            ),
            Positioned(
              left: 160,
              top: 300,
              child: StoneWallCell(
                width: 58,
                topHeight: 54,
                style: WallStyle.levelTile.copyWith(
                    frontColor: const Color(0xFF17110D), topHighlight: .16),
                topGradient: cssLinear(
                  deg: 165,
                  box: const Size(58, 54),
                  colors: const [Color(0xFF2C231C), Color(0xFF221A15)],
                ),
              ),
            ),
            // Door + door light.
            const Positioned(left: 280, top: 300, child: ExitDoorLight()),
            const Positioned(left: 305, top: 310, child: ExitDoor()),
          ],
        ),
      ),
      size: const Size(390, 400),
    );
    await expectGolden(null, 'kit_wall_cells');
  });

  testWidgets('kit maze board (level 7): floor, walls, door, no overlay',
      (tester) async {
    await pumpScreen(tester, mazeScene(lit: true));
    await expectGolden(null, 'kit_maze');
  });

  test('wall shade matches the JS expression', () {
    expect([for (var r = 0; r < 4; r++) wallShade(r, 5)], [0, 1, 2, 0]);
    // The design picks the shade by (r*7 + c*3) % 3 = r % 3.
    final g = Levels.byId(7).grid;
    expect(g.cols * 40, 360);
    expect(g.rows * 40, 520);
  });
}
