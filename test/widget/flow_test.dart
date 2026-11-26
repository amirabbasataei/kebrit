import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/app.dart';
import 'package:kebrit/data/progress.dart';
import 'package:kebrit/data/progress_repository.dart';
import 'package:kebrit/data/settings.dart';
import 'package:kebrit/data/levels.dart';
import 'package:kebrit/game/game_state.dart';
import 'package:kebrit/game/grid.dart';
import 'package:kebrit/ui/screens/benefits/benefits_screen.dart';
import 'package:kebrit/ui/screens/caught/caught_screen.dart';
import 'package:kebrit/ui/screens/complete/complete_screen.dart';
import 'package:kebrit/ui/screens/game/game_screen.dart';
import 'package:kebrit/ui/screens/game/overlays.dart';
import 'package:kebrit/ui/screens/levels/levels_screen.dart';
import 'package:kebrit/ui/screens/pause/pause_screen.dart';
import 'package:kebrit/ui/screens/splash/splash_screen.dart';
import 'package:kebrit/ui/screens/title/title_screen.dart';
import 'package:kebrit/ui/screens/transition/transition_screen.dart';
import 'package:kebrit/ui/screens/tutorial/tutorial_screen.dart';

import '../helpers/fonts.dart';

const _fade = Duration(milliseconds: 300);

void main() {
  setUpAll(loadAppFonts);

  Future<void> launch(WidgetTester tester, ProgressRepository repo) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(KebritApp(repository: repo));
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).first);
    await tester.pump();
    await tester.tap(find.text(text).first);
    await tester.pump(_fade);
    await tester.pump(_fade);
  }

  Future<void> pressBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pump(_fade);
    await tester.pump(_fade);
  }

  Future<void> step(WidgetTester tester, Offset by) async {
    final g = await tester.startGesture(const Offset(200, 400));
    await g.moveBy(by);
    await tester.pump(const Duration(milliseconds: 20));
    await g.up();
    await tester.pump(const Duration(milliseconds: 20));
  }

  /// Walks the player of the current level 7 game to the door (dark, hunters
  /// frozen), avoiding hunter cells.
  Future<void> walkToExit(WidgetTester tester) async {
    final level = Levels.byId(7);
    final g = level.grid;
    final start = level.playerStart;
    final goal = g.exit;
    final blocked = level.hunterStarts.toSet();
    final prev = <Cell, (Cell, Dir)>{};
    final queue = [start];
    final seen = {start};
    while (queue.isNotEmpty && !seen.contains(goal)) {
      final c = queue.removeAt(0);
      for (final d in Dir.values) {
        final n = Cell(c.x + d.dx, c.y + d.dy);
        if (seen.contains(n) || g.isWall(n.x, n.y) && !g.isExit(n.x, n.y))
          continue;
        if (blocked.contains(n)) continue;
        seen.add(n);
        prev[n] = (c, d);
        queue.add(n);
      }
    }
    final path = <Dir>[];
    for (var c = goal; c != start; c = prev[c]!.$1) {
      path.add(prev[c]!.$2);
    }
    for (final d in path.reversed) {
      await step(tester, Offset(d.dx * 30.0, d.dy * 30.0));
    }
  }

  testWidgets(
    'fresh install: Splash → Benefits → Title; later launches skip Benefits',
    (tester) async {
      final repo = InMemoryProgressRepository();
      await launch(tester, repo);
      expect(find.byType(SplashScreen), findsOneWidget);
      await tester.tap(find.byType(SplashScreen));
      await tester.pump(_fade);
      await tester.pump(_fade);
      expect(find.byType(BenefitsScreen), findsOneWidget);

      await tapText(tester, 'کبریت را روشن کن');
      expect(find.byType(TitleScreen), findsOneWidget);
      expect(await repo.loadIntroSeen(), isTrue);

      // New launch with the same repository.
      await tester.pumpWidget(const SizedBox());
      await launch(tester, repo);
      await tester.tap(find.byType(SplashScreen));
      await tester.pump(_fade);
      await tester.pump(_fade);
      expect(find.byType(TitleScreen), findsOneWidget);
      expect(find.byType(BenefitsScreen), findsNothing);
    },
  );

  testWidgets('Benefits tutorial link opens the tutorial', (tester) async {
    await launch(tester, InMemoryProgressRepository());
    await tester.tap(find.byType(SplashScreen));
    await tester.pump(_fade);
    await tester.pump(_fade);
    await tapText(tester, 'اول آموزش را ببینم');
    expect(find.byType(TutorialScreen), findsOneWidget);
  });

  testWidgets('Title menu: levels, back, tutorial back', (tester) async {
    final repo = InMemoryProgressRepository()..saveIntroSeen(true);
    await launch(tester, repo);
    await tester.tap(find.byType(SplashScreen));
    await tester.pump(_fade);
    await tester.pump(_fade);

    await tapText(tester, 'مراحل');
    expect(find.byType(LevelsScreen), findsOneWidget);
    await pressBack(tester); // hardware back: Levels → Title
    expect(find.byType(TitleScreen), findsOneWidget);

    await tapText(tester, 'آموزش بازی');
    expect(find.byType(TutorialScreen), findsOneWidget);
    await pressBack(tester);
    expect(find.byType(TitleScreen), findsOneWidget);
  });

  testWidgets(
    'win level 7 → progress saved → level 8 unlocked → transition → game 8',
    (tester) async {
      final repo = InMemoryProgressRepository(
        progress: Progress(currentLevel: 7),
      )..saveIntroSeen(true);
      await launch(tester, repo);
      await tester.tap(find.byType(SplashScreen));
      await tester.pump(_fade);
      await tester.pump(_fade);

      await tapText(tester, 'ادامه'); // Continue → level 7
      expect(find.byType(GameScreen), findsOneWidget);
      await walkToExit(tester);
      expect(find.byType(ResultOverlay), findsOneWidget);

      await tapText(tester, 'ادامه');
      expect(find.byType(CompleteScreen), findsOneWidget);
      final saved = await repo.loadProgress();
      expect(saved.currentLevel, 8);
      expect(saved.bestEmbers(7), 3, reason: 'no matches struck → best rating');

      await tapText(tester, 'اتاق بعدی');
      expect(find.byType(TransitionScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 9));
      await tester.pump(_fade);
      await tester.pump(_fade);
      expect(find.byType(TransitionScreen), findsNothing);
      final game = tester.widget<GameScreen>(find.byType(GameScreen));
      expect(game.controller!.state.level.id, 8);
    },
  );

  testWidgets('caught → retry starts the same level fresh; Levels works', (
    tester,
  ) async {
    final repo = InMemoryProgressRepository(progress: Progress(currentLevel: 7))
      ..saveIntroSeen(true);
    await launch(tester, repo);
    await tester.tap(find.byType(SplashScreen));
    await tester.pump(_fade);
    await tester.pump(_fade);
    await tapText(tester, 'ادامه');

    // Light the match, then wait for a hunter to arrive (re-strike as needed).
    for (
      var i = 0;
      i < 6 && find.byType(ResultOverlay).evaluate().isEmpty;
      i++
    ) {
      await tester.tapAt(const Offset(322, 758));
      for (
        var t = 0;
        t < 90 && find.byType(ResultOverlay).evaluate().isEmpty;
        t++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
    expect(find.byType(ResultOverlay), findsOneWidget);
    await tapText(tester, 'ادامه');
    expect(find.byType(CaughtScreen), findsOneWidget);

    await tapText(tester, 'دوباره تلاش کن');
    expect(find.byType(GameScreen), findsOneWidget);
    final c = tester.widget<GameScreen>(find.byType(GameScreen)).controller!;
    expect(c.state.level.id, 7);
    expect(c.state.result, GameResult.playing);
    expect(c.state.matches, Levels.byId(7).startMatches);

    // Hardware back = pause; «مراحل» goes to the level select.
    await pressBack(tester);
    expect(find.byType(PauseScreen), findsOneWidget);
    await tapText(tester, 'مراحل');
    expect(find.byType(LevelsScreen), findsOneWidget);
  });

  testWidgets('pause: back resumes, restart gives a fresh game', (
    tester,
  ) async {
    final repo = InMemoryProgressRepository(progress: Progress(currentLevel: 7))
      ..saveIntroSeen(true);
    await launch(tester, repo);
    await tester.tap(find.byType(SplashScreen));
    await tester.pump(_fade);
    await tester.pump(_fade);
    await tapText(tester, 'ادامه');

    await step(tester, const Offset(30, 0));
    var c = tester.widget<GameScreen>(find.byType(GameScreen)).controller!;
    expect(c.state.steps, 1);

    await tester.tapAt(const Offset(352, 78)); // pause button
    await tester.pump(_fade);
    await tester.pump(_fade);
    expect(find.byType(PauseScreen), findsOneWidget);
    expect(c.paused, isTrue);
    await pressBack(tester);
    expect(find.byType(PauseScreen), findsNothing);
    expect(c.paused, isFalse);
    expect(c.state.steps, 1, reason: 'resume keeps the run');

    await pressBack(tester);
    await tapText(tester, 'از نو');
    c = tester.widget<GameScreen>(find.byType(GameScreen)).controller!;
    expect(c.state.steps, 0, reason: 'restart = fresh engine');
  });

  testWidgets('settings from Title are persisted across a rebuilt app', (
    tester,
  ) async {
    final repo = InMemoryProgressRepository()..saveIntroSeen(true);
    await launch(tester, repo);
    await tester.tap(find.byType(SplashScreen));
    await tester.pump(_fade);
    await tester.pump(_fade);

    await tapText(tester, 'تنظیمات');
    expect(find.byType(PauseScreen), findsOneWidget);
    await tapText(tester, 'کاهش سوسو');
    await tapText(tester, 'دکمه‌ی کبریت در سمت چپ');
    final s = await repo.loadSettings();
    expect(s.reduceFlicker, isTrue);
    expect(s.leftHanded, isTrue);
    expect(s.sound, isTrue);

    await pressBack(tester); // back to Title
    expect(find.byType(TitleScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await launch(tester, repo);
    await tester.tap(find.byType(SplashScreen));
    await tester.pump(_fade);
    await tester.pump(_fade);
    await tapText(tester, 'تنظیمات');
    final reloaded = await repo.loadSettings();
    expect(reloaded, const AppSettings(reduceFlicker: true, leftHanded: true));
    expect(find.byType(PauseScreen), findsOneWidget);
  });
}
