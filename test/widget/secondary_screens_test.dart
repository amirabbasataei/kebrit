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

import '../helpers/fonts.dart';
import '../helpers/golden_harness.dart';

GameStats stats({int level = 7}) => GameStats(
      level: level,
      startMatches: 6,
      matchesLeft: 3,
      matchesStruck: 3,
      elapsed: const Duration(minutes: 1, seconds: 42),
      steps: 30,
      stepsToDoor: 6,
      hunters: 2,
    );

void main() {
  setUpAll(loadAppFonts);

  group('pause', () {
    testWidgets('toggles update the settings live', (tester) async {
      var settings = const AppSettings();
      await pumpScreen(
        tester,
        StatefulBuilder(
          builder: (context, setState) => PauseScreen(
            level: Levels.byId(7),
            settings: settings,
            onSettingsChanged: (s) => setState(() => settings = s),
          ),
        ),
      );
      expect(settings, const AppSettings());

      await tester.tap(find.text('صدا'));
      await tester.pump();
      expect(settings.sound, isFalse);

      await tester.tap(find.text('لرزش گوشی'));
      await tester.pump();
      expect(settings.haptics, isFalse);

      await tester.tap(find.text('کاهش سوسو'));
      await tester.pump();
      expect(settings.reduceFlicker, isTrue);

      await tester.tap(find.text('دکمه‌ی کبریت در سمت چپ'));
      await tester.pump();
      expect(settings.leftHanded, isTrue);

      // Flipping back restores the default.
      await tester.tap(find.text('صدا'));
      await tester.pump();
      expect(settings.sound, isTrue);
    });

    testWidgets('buttons call their callbacks', (tester) async {
      final calls = <String>[];
      await pumpScreen(
        tester,
        PauseScreen(
          level: Levels.byId(7),
          onContinue: () => calls.add('continue'),
          onRestart: () => calls.add('restart'),
          onTutorial: () => calls.add('tutorial'),
          onLevels: () => calls.add('levels'),
        ),
      );
      for (final label in ['ادامه', 'از نو', 'آموزش', 'مراحل']) {
        await tester.tap(find.text(label));
        await tester.pump();
      }
      expect(calls, ['continue', 'restart', 'tutorial', 'levels']);
    });

    test('status line: lit shows seconds, dark does not', () {
      final base = GameState.initial(Levels.byId(7));
      expect(
        pauseStatus(base.copyWith(lit: true, burn: 72, matches: 5)),
        'شعله‌ات با ۶ ثانیه‌ی باقی‌مانده منتظر است · ۵ کبریت در دست.',
      );
      expect(pauseStatus(base), 'شعله‌ات خاموش است · ۶ کبریت در دست.');
    });

    testWidgets('no status line without a game', (tester) async {
      await pumpScreen(tester, PauseScreen(level: Levels.byId(7)));
      expect(find.textContaining('شعله‌ات'), findsNothing);
      expect(find.text('توقف'), findsOneWidget);
    });
  });

  group('complete', () {
    testWidgets('shows stats, next-level teaser and calls back', (tester) async {
      final calls = <String>[];
      await pumpScreen(
        tester,
        CompleteScreen(
          stats: stats(),
          embers: 2,
          time: 0,
          onNext: () => calls.add('next'),
          onRepeat: () => calls.add('repeat'),
          onLevels: () => calls.add('levels'),
        ),
      );
      expect(find.text('۳ از ۶'), findsOneWidget);
      expect(find.text('۱:۴۲'), findsOneWidget);
      expect(find.text('۲ از ۲'), findsOneWidget);
      expect(find.text('بعدی: ${Levels.byId(8).name} — ۵ کبریت، ۳ شکارچی.'), findsOneWidget);

      await tester.tap(find.text('اتاق بعدی'));
      await tester.tap(find.text('تکرار برای ۳ اخگر'));
      await tester.tap(find.text('مراحل'));
      expect(calls, ['next', 'repeat', 'levels']);
    });

    testWidgets('repeat label depends on the embers earned', (tester) async {
      await pumpScreen(tester, CompleteScreen(stats: stats(), embers: 3, time: 0));
      expect(find.text('بازی دوباره'), findsOneWidget);
      expect(find.text('تکرار برای ۳ اخگر'), findsNothing);
      expect(repeatLabel(0), 'تکرار برای ۳ اخگر');
    });

    testWidgets('last level has no next-room button', (tester) async {
      await pumpScreen(
        tester,
        CompleteScreen(stats: stats(level: Levels.count), embers: 1, time: 0),
      );
      expect(find.text('اتاق بعدی'), findsNothing);
      expect(find.text('مراحل'), findsOneWidget);
    });

    testWidgets('embers semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpScreen(tester, CompleteScreen(stats: stats(), embers: 2, time: 0));
      expect(find.bySemanticsLabel('۲ اخگر از ۳ به دست آمد'), findsOneWidget);
      handle.dispose();
    });

    test('breathing opacity oscillates 1 → .82 → 1 over 3 s', () {
      expect(breatheOpacity(0), 1);
      expect(breatheOpacity(1.5), closeTo(.82, 1e-9));
      expect(breatheOpacity(3), closeTo(1, 1e-9));
    });
  });

  group('caught', () {
    testWidgets('stats and callbacks', (tester) async {
      final calls = <String>[];
      await pumpScreen(
        tester,
        CaughtScreen(
          stats: stats(),
          time: 0,
          onRetry: () => calls.add('retry'),
          onLevels: () => calls.add('levels'),
        ),
      );
      expect(find.text('۳ از ۶'), findsOneWidget); // matches struck
      expect(find.text('۶ قدم'), findsOneWidget);
      await tester.tap(find.text('دوباره تلاش کن'));
      await tester.tap(find.text('مراحل'));
      expect(calls, ['retry', 'levels']);
    });

    test('blink and loom keyframes', () {
      expect(blinkScale(0), 1);
      expect(blinkScale(4.5 * .45), 1);
      expect(blinkScale(4.5 * .5), closeTo(.1, 1e-9));
      expect(blinkScale(4.5 * .6), 1);
      expect(blinkScale(4.5 + 4.5 * .5), closeTo(.1, 1e-9)); // loops
      expect(loomAmount(0), 0);
      expect(loomAmount(2.5), closeTo(1, 1e-9));
      expect(loomAmount(5), closeTo(0, 1e-9));
    });
  });

  group('no matches', () {
    testWidgets('texts, match row and callbacks', (tester) async {
      final calls = <String>[];
      await pumpScreen(
        tester,
        NoMatchesScreen(
          stats: GameStats(
            level: 7,
            startMatches: 6,
            matchesLeft: 0,
            matchesStruck: 6,
            elapsed: const Duration(seconds: 80),
            steps: 20,
            stepsToDoor: 9,
            hunters: 2,
          ),
          time: 0,
          onRetry: () => calls.add('retry'),
          onLevels: () => calls.add('levels'),
        ),
      );
      expect(find.text('۰ از ۶ باقی مانده · در ۹ قدم دورتر بود'), findsOneWidget);
      await tester.tap(find.text('دوباره تلاش کن'));
      await tester.tap(find.text('مراحل'));
      expect(calls, ['retry', 'levels']);
    });

    test('smoke blobs show their base style until their delay passes', () {
      final early = smokeAt(.5, 1.3);
      expect(early.opacity, 1);
      expect(early.p, 0);
      expect(smokeAt(0, 0).opacity, 0);
      final peak = smokeAt(.8, 0); // 20 % of 4 s
      expect(peak.opacity, closeTo(.55, 1e-3));
      expect(smokeAt(3.999, 0).opacity, closeTo(0, 1e-3));
      // Loops every 4 s after the delay.
      expect(smokeAt(1.3 + 4.8, 1.3).opacity, closeTo(.55, 1e-3));
    });

    test('ember dims and recovers', () {
      expect(emberAmount(0), 0);
      expect(emberAmount(1.2), closeTo(1, 1e-9));
      expect(emberAmount(2.4), closeTo(0, 1e-9));
    });

    testWidgets('reduced flicker runs no ticker', (tester) async {
      await pumpScreen(
        tester,
        NoMatchesScreen(stats: stats(), reduceFlicker: true),
      );
      // No pending frames: pumpAndSettle would time out with a live ticker.
      await tester.pumpAndSettle();
    });
  });
}
