import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/data/progress.dart';
import 'package:kebrit/ui/kit/flicker.dart';
import 'package:kebrit/ui/screens/title/title_screen.dart';
import 'package:kebrit/ui/screens/tutorial/tutorial_parts.dart';
import 'package:kebrit/ui/screens/tutorial/tutorial_screen.dart';

import '../helpers/fonts.dart';
import '../helpers/golden_harness.dart';

void main() {
  setUpAll(loadAppFonts);

  group('track (CSS keyframes)', () {
    test('holds outside the keys and eases inside', () {
      const k = [(0.0, 0.0), (.5, 10.0), (1.0, 10.0)];
      expect(track(0, k), 0);
      expect(track(.5, k), 10);
      expect(track(1, k), 10);
      final mid = track(.25, k);
      expect(mid, closeTo(5, 1e-9)); // ease-in-out is symmetric
      expect(track(.1, k), lessThan(2)); // slow start
    });
  });

  group('TitleScreen', () {
    testWidgets('continue subtitle follows progress; buttons call back', (tester) async {
      final calls = <String>[];
      await pumpScreen(
        tester,
        TitleScreen(
          progress: Progress(currentLevel: 7),
          onContinue: () => calls.add('continue'),
          onTutorial: () => calls.add('tutorial'),
          onLevels: () => calls.add('levels'),
          onSettings: () => calls.add('settings'),
          flickerPhase: 0,
        ),
      );
      expect(find.text('مرحله‌ی ۷ · سرداب زیرین'), findsOneWidget);
      for (final t in ['ادامه', 'آموزش بازی', 'مراحل', 'تنظیمات']) {
        await tester.tap(find.text(t));
      }
      expect(calls, ['continue', 'tutorial', 'levels', 'settings']);
    });

    testWidgets('fresh install shows level 1', (tester) async {
      await pumpScreen(tester, const TitleScreen(flickerPhase: 0));
      expect(find.textContaining('مرحله‌ی ۱ ·'), findsOneWidget);
    });
  });

  group('TutorialScreen', () {
    double dotWidth(WidgetTester t, int i) => t.getSize(find.byKey(ValueKey('dot-$i'))).width;

    testWidgets('next / back / dots / last-step CTA / skip', (tester) async {
      var skip = 0, done = 0;
      await pumpScreen(
        tester,
        TutorialScreen(
          time: const Duration(milliseconds: 1500),
          onSkip: () => skip++,
          onDone: () => done++,
        ),
      );
      expect(find.text('راه زنده ماندن · ۱ از ۴'), findsOneWidget);
      expect([for (var i = 0; i < 4; i++) dotWidth(tester, i)], [22, 6, 6, 6]);

      await tester.tap(find.text('بعدی'));
      await tester.pump();
      expect(find.text('کبریت بزن تا ببینی'), findsOneWidget);
      expect([for (var i = 0; i < 4; i++) dotWidth(tester, i)], [6, 22, 6, 6]);

      await tester.tap(find.text('قبلی'));
      await tester.pump();
      expect(find.text('برای حرکت، بکش'), findsOneWidget);

      // «قبلی» is inert on the first step.
      await tester.tap(find.text('قبلی'));
      await tester.pump();
      expect(find.text('برای حرکت، بکش'), findsOneWidget);

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('بعدی'));
        await tester.pump();
      }
      expect(find.text('بعدی'), findsNothing);
      expect(find.text('ورود به اولین اتاق'), findsOneWidget);
      await tester.tap(find.text('ورود به اولین اتاق'));
      expect(done, 1);

      await tester.tap(find.text('رد شدن'));
      expect(skip, 1);
    });

    testWidgets('live clock loops and restarts on step change', (tester) async {
      await pumpScreen(tester, const TutorialScreen());
      await tester.pump(const Duration(seconds: 5)); // beyond one loop
      await tester.tap(find.text('بعدی'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('کبریت بزن تا ببینی'), findsOneWidget);
    });

    testWidgets('reduced flicker freezes: no frames are scheduled', (tester) async {
      await pumpScreen(
        tester,
        const FlickerScope(reduce: true, child: TutorialScreen()),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
    });
  });
}
