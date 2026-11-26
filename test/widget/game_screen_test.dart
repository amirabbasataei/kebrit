import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/data/settings.dart';
import 'package:kebrit/game/game_state.dart';
import 'package:kebrit/game/grid.dart';
import 'package:kebrit/services/haptics.dart';
import 'package:kebrit/ui/screens/game/game_controller.dart';
import 'package:kebrit/ui/screens/game/game_screen.dart';

import '../helpers/fonts.dart';
import '../helpers/golden_harness.dart';
import '../unit/game/fixtures.dart';

const strikeButton = Offset(322, 758);
const pauseButton = Offset(352, 78);
const ms100 = Duration(milliseconds: 100);
const ms170 = Duration(milliseconds: 170);

class CountingHaptics extends Haptics {
  int n = 0;
  @override
  void hunterStep() => n++;
}

void main() {
  setUpAll(loadAppFonts);

  late GameController c;
  late Offset origin;

  Future<void> start(
    WidgetTester tester,
    GameController controller, {
    void Function(GameStats)? onEscaped,
    void Function(GameStats)? onCaught,
    void Function(GameStats)? onGiveUp,
    VoidCallback? onPause,
    AppSettings settings = const AppSettings(),
  }) async {
    c = controller;
    addTearDown(c.dispose);
    await pumpScreen(
      tester,
      GameScreen(
        controller: c,
        settings: settings,
        animate: false,
        flickerPhase: .5,
        onEscaped: onEscaped,
        onCaught: onCaught,
        onGiveUp: onGiveUp,
        onPause: onPause,
      ),
    );
    origin = tester.getTopLeft(find.byKey(goldenKey));
  }

  Future<TestGesture> drag(WidgetTester tester, Offset by,
      {Offset from = const Offset(200, 400)}) async {
    final g = await tester.startGesture(origin + from);
    await g.moveBy(by);
    await tester.pump();
    return g;
  }

  testWidgets('drag right moves one cell at once, then repeats every 170 ms',
      (tester) async {
    await start(tester, GameController(level7()));
    expect(c.state.player, const Cell(1, 11));
    final g = await drag(tester, const Offset(30, 0));
    expect(c.started, isTrue);
    expect(c.state.player, const Cell(2, 11));
    expect(c.drag, isNotNull);
    await tester.pump(ms170);
    expect(c.state.player, const Cell(3, 11));
    await tester.pump(ms170);
    expect(c.state.player, const Cell(4, 11));
    await g.up();
    await tester.pump();
    expect(c.drag, isNull);
    await tester.pump(ms170 * 3);
    expect(c.state.player, const Cell(4, 11), reason: 'released: no repeat');
  });

  testWidgets('a wall blocks the step', (tester) async {
    await start(tester, GameController(level7()));
    final g = await drag(tester, const Offset(-30, 0));
    await tester.pump(ms170 * 2);
    expect(c.state.player, const Cell(1, 11));
    expect(c.state.steps, 0);
    await g.up();
  });

  testWidgets('joystick knob follows the finger, clamped to 30 px',
      (tester) async {
    await start(tester, GameController(level7()));
    final g = await drag(tester, const Offset(0, -80));
    final d = c.drag!;
    expect([d.ox, d.oy], [200, 400]);
    expect(d.kx, closeTo(0, 1e-9));
    expect(d.ky, closeTo(-30, 1e-9));
    await g.up();
  });

  testWidgets('the +2 match pickup is collected once', (tester) async {
    await start(tester, GameController(level7()));
    final g = await drag(tester, const Offset(0, -30));
    await tester.pump(ms170 * 3); // (1,11) -> (1,7)
    expect(c.state.player, const Cell(1, 7));
    expect(c.state.matches, 8);
    await g.moveTo(origin + const Offset(200, 430)); // down
    await tester.pump();
    await tester.pump(ms170 * 2);
    await g.moveTo(origin + const Offset(200, 370)); // up again
    await tester.pump();
    await tester.pump(ms170 * 2);
    expect(c.state.matches, 8);
    await g.up();
  });

  testWidgets('strike lights the match; a second strike is a no-op',
      (tester) async {
    await start(tester, GameController(level7()));
    expect(c.started, isFalse);
    await tester.tapAt(origin + strikeButton);
    await tester.pump();
    expect(c.started, isTrue);
    expect(c.state.lit, isTrue);
    expect(c.state.matches, 5);
    await tester.tapAt(origin + strikeButton);
    await tester.pump();
    expect(c.state.matches, 5);
    expect(c.state.burn, 100);
  });

  testWidgets('the flame goes out after 8 s and a new strike restarts it',
      (tester) async {
    await start(tester, GameController(corridor()));
    await tester.tapAt(origin + strikeButton);
    await tester.pump(const Duration(seconds: 4));
    expect(c.state.lit, isTrue);
    expect(c.state.burn, closeTo(50, 1e-9));
    await tester.pump(const Duration(seconds: 4));
    expect(c.state.lit, isFalse);
    expect(c.state.burn, 0);
    await tester.tapAt(origin + strikeButton);
    await tester.pump(ms100);
    expect(c.state.lit, isTrue);
    expect(c.state.matches, 1);
  });

  testWidgets('a hunter converges and catches the player', (tester) async {
    GameStats? caught;
    final haptics = CountingHaptics();
    await start(
      tester,
      GameController(corridor(hunters: const [Cell(3, 1)]),
          haptics: haptics),
      onCaught: (s) => caught = s,
    );
    await tester.tapAt(origin + strikeButton);
    await tester.pump(const Duration(milliseconds: 900));
    expect(c.state.hunters, const [Cell(2, 1)]);
    expect(haptics.n, 1);
    await tester.pump(const Duration(milliseconds: 900));
    expect(c.state.result, GameResult.caught);
    expect(haptics.n, 2);
    await tester.pump(const Duration(seconds: 2));
    expect(c.state.hunters, const [Cell(1, 1)], reason: 'run is over');
    expect(caught, isNull);
    await tester.tap(find.text('ادامه'));
    expect(caught, isNotNull);
    expect(caught!.matchesStruck, 1);
    expect(caught!.matchesLeft, 2);
  });

  testWidgets('hunters stay put in the dark and haptics can be disabled',
      (tester) async {
    final haptics = CountingHaptics();
    await start(
      tester,
      GameController(corridor(hunters: const [Cell(3, 1)]),
          haptics: haptics),
      settings: const AppSettings(haptics: false),
    );
    await tester.tapAt(origin + const Offset(100, 300)); // begin, still dark
    await tester.pump(const Duration(seconds: 3));
    expect(c.state.hunters, const [Cell(3, 1)]);
    await tester.tapAt(origin + strikeButton);
    await tester.pump(const Duration(milliseconds: 900));
    expect(c.state.hunters, const [Cell(2, 1)]);
    expect(haptics.n, 0);
  });

  testWidgets('reaching the exit reports onEscaped with stats', (tester) async {
    GameStats? stats;
    await start(
      tester,
      GameController(corridor(player: const Cell(2, 1))),
      onEscaped: (s) => stats = s,
    );
    final g = await drag(tester, const Offset(0, -30));
    expect(c.state.result, GameResult.escaped);
    expect(find.text('در را پیدا کردی.'), findsOneWidget);
    await g.up();
    await tester.pump(ms170 * 3);
    expect(c.state.steps, 1, reason: 'no more steps after the exit');
    await tester.tap(find.text('ادامه'));
    expect(stats!.steps, 1);
    expect(stats!.level, 0);
    expect(stats!.startMatches, 3);
    expect(stats!.matchesLeft, 3);
  });

  testWidgets('dark with no matches shows the give-up link', (tester) async {
    GameStats? stats;
    await start(
      tester,
      GameController(corridor(matches: 0)),
      onGiveUp: (s) => stats = s,
    );
    const link = 'کبریت تمام شد — تسلیم می‌شوی؟';
    expect(find.text(link), findsNothing, reason: 'not started yet');
    await tester.tapAt(origin + const Offset(100, 300));
    await tester.pump();
    expect(find.text(link), findsOneWidget);
    await tester.tap(find.text(link));
    expect(c.state.result, GameResult.outOfMatches);
    expect(stats, isNotNull);
    expect(c.drag, isNull, reason: 'the link swallowed the touch');
  });

  testWidgets('HUD buttons swallow pointers: no joystick, no step',
      (tester) async {
    await start(tester, GameController(level7()));
    final g = await tester.startGesture(origin + strikeButton);
    await g.moveBy(const Offset(-30, 0));
    await tester.pump(ms170 * 2);
    expect(c.drag, isNull);
    expect(c.state.player, const Cell(1, 11));
    await g.up();
    await tester.pump();
    expect(c.started, isFalse, reason: 'a claimed pointer does not begin');
  });

  testWidgets('pause freezes burn and resume continues from there',
      (tester) async {
    var paused = 0;
    await start(tester, GameController(corridor()), onPause: () => paused++);
    await tester.tapAt(origin + strikeButton);
    await tester.pump(const Duration(seconds: 2));
    final burn = c.state.burn;
    await tester.tapAt(origin + pauseButton);
    await tester.pump();
    expect(paused, 1);
    expect(c.paused, isTrue);
    await tester.pump(const Duration(seconds: 5));
    expect(c.state.burn, burn);
    expect(c.state.lit, isTrue);
    c.resume();
    await tester.pump(const Duration(seconds: 1));
    expect(c.state.burn, closeTo(burn - 12.5, 1e-9));
  });

  testWidgets('backgrounding the app pauses a started run', (tester) async {
    var paused = 0;
    await start(tester, GameController(corridor()), onPause: () => paused++);
    await tester.tapAt(origin + strikeButton);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(c.paused, isTrue);
    expect(paused, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('GameScreen(level:) owns its controller and plays', (tester) async {
    await pumpScreen(tester, GameScreen(level: corridor(), animate: false));
    final o = tester.getTopLeft(find.byKey(goldenKey));
    await tester.tapAt(o + strikeButton);
    await tester.pump(const Duration(seconds: 1));
    // Unmounting disposes the controller and cancels its timers.
    await tester.pumpWidget(const SizedBox());
  });
}
