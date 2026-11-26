// Golden sheets: light overlay lit / dark over the maze, plus the menu
// overlays. Goldens are generated and verified only on Windows (Windows
// Server 2019); do not copy them between machines.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/theme/tokens.dart';
import 'package:kebrit/ui/kit/light_overlay.dart';
import 'package:kebrit/ui/kit/match_icon.dart';
import 'package:kebrit/ui/kit/stone_bg.dart';

import '../helpers/fonts.dart';
import '../helpers/golden_harness.dart';
import '../helpers/kit_scene.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('kit overlay lit (burn 72)', (tester) async {
    await pumpScreen(tester, mazeScene(lit: true, burn: 72, overlay: true));
    await expectGolden(null, 'kit_overlay_lit');
  });

  testWidgets('kit overlay lit (burn 8, nearly out)', (tester) async {
    await pumpScreen(tester, mazeScene(lit: true, burn: 8, overlay: true));
    await expectGolden(null, 'kit_overlay_lit_low');
  });

  testWidgets('kit overlay dark', (tester) async {
    await pumpScreen(tester, mazeScene(lit: false, overlay: true));
    await expectGolden(null, 'kit_overlay_dark');
  });

  testWidgets('kit menu overlays: title and pause', (tester) async {
    await pumpScreen(
      tester,
      Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                const StoneBackground(),
                LightOverlay.title(),
                const WarmFlicker.title(phase: 0),
                const Positioned(
                  left: 186,
                  top: 190,
                  child: MatchStick(phase: .5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2, child: ColoredBox(color: Kc.flame)),
          Expanded(
            child: Stack(
              children: [const StoneBackground(), LightOverlay.pause()],
            ),
          ),
        ],
      ),
    );
    await expectGolden(null, 'kit_overlay_menus');
  });
}
