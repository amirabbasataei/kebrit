// Gameplay view goldens. Goldens are generated and verified only on Windows
// (Windows Server 2019); do not copy them between machines.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/data/levels.dart';
import 'package:kebrit/data/settings.dart';
import 'package:kebrit/game/game_state.dart';
import 'package:kebrit/game/grid.dart';
import 'package:kebrit/ui/screens/game/game_screen_view.dart';
import 'package:kebrit/ui/screens/game/joystick.dart';

import '../helpers/design_compare.dart';
import '../helpers/fonts.dart';
import '../helpers/golden_harness.dart';

GameState base() => GameState.initial(Levels.byId(7));

/// The design's preview mock: lit, 72 % burn, 5 matches.
GameState lit() => base().copyWith(lit: true, burn: 72, matches: 5, matchesStruck: 1);

Widget view(
  GameState s, {
  bool started = true,
  JoystickDrag? drag,
  AppSettings settings = const AppSettings(),
}) =>
    GameScreenView(
      state: s,
      started: started,
      drag: drag,
      settings: settings,
      flickerPhase: .5,
      animate: false,
      onPause: () {},
      onStrike: () {},
      onContinueEscaped: () {},
      onContinueCaught: () {},
      onGiveUp: () {},
    );

void main() {
  setUpAll(loadAppFonts);

  testWidgets('game: lit 72 % / 5 matches', (tester) async {
    await pumpScreen(tester, view(lit()));
    await expectGolden(null, 'game_lit');
    await expectMatchesDesign(tester, find.byKey(goldenKey), 'design_refs/mobile/4_Game_lit.png');
  });

  testWidgets('game: dark / 6 matches, before first touch', (tester) async {
    await pumpScreen(tester, view(base(), started: false));
    await expectGolden(null, 'game_dark');
    await expectMatchesDesign(tester, find.byKey(goldenKey), 'design_refs/mobile/4_Game_dark.png');
  });

  testWidgets('game: dark / 0 matches shows the give-up link', (tester) async {
    await pumpScreen(tester, view(base().copyWith(matches: 0, matchesStruck: 6)));
    await expectGolden(null, 'game_no_matches');
  });

  testWidgets('game: escaped overlay', (tester) async {
    await pumpScreen(
      tester,
      view(base().copyWith(player: const Cell(4, 0), result: GameResult.escaped)),
    );
    await expectGolden(null, 'game_escaped');
  });

  testWidgets('game: caught overlay', (tester) async {
    await pumpScreen(
      tester,
      view(lit().copyWith(result: GameResult.caught)),
    );
    await expectGolden(null, 'game_caught');
  });

  testWidgets('game: left-handed, lit', (tester) async {
    await pumpScreen(
      tester,
      view(lit(), settings: const AppSettings(leftHanded: true)),
    );
    await expectGolden(null, 'game_lefty');
  });

  testWidgets('game: joystick visible', (tester) async {
    await pumpScreen(
      tester,
      view(lit(), drag: const JoystickDrag(150, 640, 24, -18)),
    );
    await expectGolden(null, 'game_joystick');
  });
}
