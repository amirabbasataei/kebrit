// Goldens for Pause, Level complete, Caught and Out of matches. Goldens are
// generated and verified only on Windows (Windows Server 2019); do not copy
// them between machines.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/data/levels.dart';
import 'package:kebrit/data/settings.dart';
import 'package:kebrit/game/game_state.dart';
import 'package:kebrit/ui/screens/caught/caught_screen.dart';
import 'package:kebrit/ui/screens/complete/complete_screen.dart';
import 'package:kebrit/ui/screens/game/game_controller.dart';
import 'package:kebrit/ui/screens/no_matches/no_matches_screen.dart';
import 'package:kebrit/ui/screens/pause/pause_screen.dart';

import '../helpers/design_compare.dart';
import '../helpers/fonts.dart';
import '../helpers/golden_harness.dart';

GameStats stats({int left = 3, int struck = 3, int? toDoor = 6}) => GameStats(
      level: 7,
      startMatches: 6,
      matchesLeft: left,
      matchesStruck: struck,
      elapsed: const Duration(minutes: 1, seconds: 42),
      steps: 30,
      stepsToDoor: toDoor,
      hunters: 2,
    );

/// The design's preview state: lit, 72 % burn (= 6 s), 5 matches.
GameState litState() => GameState.initial(Levels.byId(7))
    .copyWith(lit: true, burn: 72, matches: 5, matchesStruck: 1);

void _noop() {}

void main() {
  setUpAll(loadAppFonts);

  Widget pause({AppSettings settings = const AppSettings(), GameState? state}) =>
      PauseScreen(
        level: Levels.byId(7),
        state: state ?? litState(),
        settings: settings,
        onSettingsChanged: (_) {},
        onContinue: _noop,
        onRestart: _noop,
        onTutorial: _noop,
        onLevels: _noop,
      );

  testWidgets('pause: lit, default settings', (tester) async {
    await pumpScreen(tester, pause());
    await expectGolden(null, 'pause');
    await expectMatchesDesign(tester, find.byKey(goldenKey), 'design_refs/mobile/5_Pause.png');
  });

  testWidgets('pause: all toggles flipped, dark', (tester) async {
    await pumpScreen(
      tester,
      pause(
        settings: const AppSettings(
            sound: false, haptics: false, reduceFlicker: true, leftHanded: true),
        state: GameState.initial(Levels.byId(7)),
      ),
    );
    await expectGolden(null, 'pause_flipped');
  });

  Widget complete(int embers) => CompleteScreen(
        stats: stats(),
        embers: embers,
        onNext: _noop,
        onRepeat: _noop,
        onLevels: _noop,
        time: 0,
      );

  testWidgets('complete: 2 embers', (tester) async {
    await pumpScreen(tester, complete(2));
    await expectGolden(null, 'complete_2');
    await expectMatchesDesign(tester, find.byKey(goldenKey), 'design_refs/mobile/6_Complete.png');
  });

  testWidgets('complete: 0 embers', (tester) async {
    await pumpScreen(tester, complete(0));
    await expectGolden(null, 'complete_0');
  });

  testWidgets('complete: 3 embers, breathing at its dimmest', (tester) async {
    await pumpScreen(
      tester,
      CompleteScreen(
        stats: stats(left: 5, struck: 1),
        embers: 3,
        onNext: _noop,
        onRepeat: _noop,
        onLevels: _noop,
        time: 1.5,
      ),
    );
    await expectGolden(null, 'complete_3');
  });

  testWidgets('caught: t = 0', (tester) async {
    await pumpScreen(
      tester,
      CaughtScreen(
        stats: stats(left: 2, struck: 4),
        onRetry: _noop,
        onLevels: _noop,
        time: 0,
      ),
    );
    await expectGolden(null, 'caught');
    await expectMatchesDesign(tester, find.byKey(goldenKey), 'design_refs/mobile/8_Caught.png');
  });

  testWidgets('caught: mid-blink, risen', (tester) async {
    await pumpScreen(
      tester,
      CaughtScreen(
        stats: stats(left: 2, struck: 4),
        onRetry: _noop,
        onLevels: _noop,
        time: 2.25, // blink 50 %, loom 45 %
      ),
    );
    await expectGolden(null, 'caught_blink');
  });

  testWidgets('no matches: t = 0', (tester) async {
    await pumpScreen(
      tester,
      NoMatchesScreen(
        stats: stats(left: 0, struck: 6, toDoor: 9),
        onRetry: _noop,
        onLevels: _noop,
        time: 0,
      ),
    );
    await expectGolden(null, 'no_matches');
    await expectMatchesDesign(
        tester, find.byKey(goldenKey), 'design_refs/mobile/9_NoMatches.png');
  });

  testWidgets('no matches: smoke at 3 s', (tester) async {
    await pumpScreen(
      tester,
      NoMatchesScreen(
        stats: stats(left: 0, struck: 6, toDoor: 9),
        onRetry: _noop,
        onLevels: _noop,
        time: 3,
      ),
    );
    await expectGolden(null, 'no_matches_smoke');
  });
}
