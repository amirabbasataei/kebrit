import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/data/levels.dart';
import 'package:kebrit/data/settings.dart';
import 'package:kebrit/game/game_state.dart';
import 'package:kebrit/game/grid.dart';
import 'package:kebrit/ui/screens/game/board_painter.dart';
import 'package:kebrit/ui/screens/game/game_screen_view.dart';
import 'package:kebrit/ui/screens/game/hud.dart';
import 'package:kebrit/ui/screens/game/joystick.dart';
import 'package:kebrit/ui/screens/game/strike_button.dart';

import '../helpers/fonts.dart';
import '../helpers/golden_harness.dart';

GameState base() => GameState.initial(Levels.byId(7));

void main() {
  setUpAll(loadAppFonts);

  testWidgets('strike, pause and give-up callbacks fire', (tester) async {
    var strike = 0, pause = 0, giveUp = 0;
    await pumpScreen(
      tester,
      GameScreenView(
        state: base().copyWith(matches: 0),
        onStrike: () => strike++,
        onPause: () => pause++,
        onGiveUp: () => giveUp++,
        animate: false,
      ),
    );
    // Pause button centre in design space (390x844 at 1:1).
    final origin = tester.getTopLeft(find.byKey(goldenKey));
    await tester.tapAt(origin + const Offset(352, 78));
    await tester.tap(find.text('کبریت تمام شد — تسلیم می‌شوی؟'));
    // No matches: the strike button is disabled by the view.
    await tester.tapAt(origin + const Offset(322, 758));
    expect(pause, 1);
    expect(giveUp, 1);
    expect(strike, 0);
  });

  testWidgets('strike forwarded when a match can be struck', (tester) async {
    var strike = 0;
    await pumpScreen(
      tester,
      GameScreenView(state: base(), onStrike: () => strike++, animate: false),
    );
    final origin = tester.getTopLeft(find.byKey(goldenKey));
    await tester.tapAt(origin + const Offset(322, 758));
    expect(strike, 1);
  });

  testWidgets('strike is inert while the flame burns', (tester) async {
    var strike = 0;
    await pumpScreen(
      tester,
      GameScreenView(
        state: base().copyWith(lit: true, burn: 50, matches: 5),
        onStrike: () => strike++,
        animate: false,
      ),
    );
    final origin = tester.getTopLeft(find.byKey(goldenKey));
    await tester.tapAt(origin + const Offset(322, 758));
    expect(strike, 0);
  });

  testWidgets('give-up link only when dark, empty and started', (tester) async {
    const link = 'کبریت تمام شد — تسلیم می‌شوی؟';
    await pumpScreen(
      tester,
      GameScreenView(state: base().copyWith(matches: 0)),
    );
    expect(find.text(link), findsOneWidget);

    await pumpScreen(tester, GameScreenView(state: base()));
    expect(find.text(link), findsNothing);

    await pumpScreen(
      tester,
      GameScreenView(state: base().copyWith(matches: 0), started: false),
    );
    expect(find.text(link), findsNothing);

    await pumpScreen(
      tester,
      GameScreenView(state: base().copyWith(matches: 0, lit: true, burn: 10)),
    );
    expect(find.text(link), findsNothing);
  });

  testWidgets('result overlays and their continue buttons', (tester) async {
    var escaped = 0, caught = 0;
    await pumpScreen(
      tester,
      GameScreenView(
        state: base().copyWith(
          player: const Cell(4, 0),
          result: GameResult.escaped,
        ),
        onContinueEscaped: () => escaped++,
        onContinueCaught: () => caught++,
      ),
    );
    expect(find.text('در را پیدا کردی.'), findsOneWidget);
    await tester.tap(find.text('ادامه'));
    expect(escaped, 1);

    await pumpScreen(
      tester,
      GameScreenView(
        state: base().copyWith(result: GameResult.caught),
        onContinueEscaped: () => escaped++,
        onContinueCaught: () => caught++,
      ),
    );
    expect(find.text('شکارچی به تو رسید.'), findsOneWidget);
    await tester.tap(find.text('ادامه'));
    expect(caught, 1);
  });

  testWidgets('joystick only while dragging', (tester) async {
    await pumpScreen(tester, GameScreenView(state: base()));
    expect(find.byType(JoystickOverlay), findsNothing);
    await pumpScreen(
      tester,
      GameScreenView(state: base(), drag: const JoystickDrag(100, 600, 10, 0)),
    );
    expect(find.byType(JoystickOverlay), findsOneWidget);
  });

  testWidgets('pickup disappears once collected; flame follows lit', (
    tester,
  ) async {
    final level = Levels.byId(7);
    expect(level.pickups, isNotEmpty);
    await pumpScreen(tester, GameScreenView(state: base()));
    expect(find.byType(MatchPickup), findsOneWidget);
    await pumpScreen(
      tester,
      GameScreenView(state: base().copyWith(pickedUp: {...level.pickups})),
    );
    expect(find.byType(MatchPickup), findsNothing);
  });

  testWidgets('hunters show alert bubbles only while lit', (tester) async {
    await pumpScreen(tester, GameScreenView(state: base()));
    expect(find.text('!'), findsNothing);
    await pumpScreen(
      tester,
      GameScreenView(state: base().copyWith(lit: true, burn: 80)),
    );
    expect(find.text('!'), findsNWidgets(2));
  });

  test('hints per state', () {
    final s = base();
    expect(hintFor(s, started: false), contains('روی کبریت بزن'));
    expect(
      hintFor(s.copyWith(lit: true), started: true),
      'شعله‌ات را دیدند. از حرکت نایست.',
    );
    expect(hintFor(s, started: true), contains('در تاریکی'));
    expect(
      hintFor(s.copyWith(matches: 0), started: true),
      contains('کبریتی نمانده'),
    );
  });

  test('coordinate helpers match the design', () {
    // Player (1,11): light at x 15+40+20, y 150+440+20-12.
    expect(lightCenter(const Cell(1, 11)), const Offset(75, 598));
    expect(cellCenter(4, 0), const Offset(195, 170));
  });

  testWidgets('left-handed mirrors the strike button', (tester) async {
    await pumpScreen(tester, GameScreenView(state: base()));
    final right = tester.getTopLeft(find.byType(StrikeButton)).dx;
    await pumpScreen(
      tester,
      GameScreenView(
        state: base(),
        settings: const AppSettings(leftHanded: true),
      ),
    );
    final left = tester.getTopLeft(find.byType(StrikeButton)).dx;
    expect(right, greaterThan(200));
    expect(left, lessThan(100));
  });
}
