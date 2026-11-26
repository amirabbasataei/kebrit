import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/ui/kit/flicker.dart';
import 'package:kebrit/ui/screens/benefits/benefits_screen.dart';
import 'package:kebrit/ui/screens/splash/splash_screen.dart';

import '../helpers/fonts.dart';
import '../helpers/golden_harness.dart';

void main() {
  setUpAll(loadAppFonts);

  group('SplashScreen', () {
    testWidgets('tap anywhere calls onStart once', (tester) async {
      var n = 0;
      await pumpScreen(tester, SplashScreen(onStart: () => n++));
      await tester.tapAt(const Offset(30, 30));
      await tester.pump();
      await tester.tap(find.text('کبریت'), warnIfMissed: false);
      expect(n, 2); // two taps, one callback each
    });

    testWidgets('live clock reveals the logo and tap hint', (tester) async {
      await pumpScreen(tester, const SplashScreen());
      double opacityOf(String text) {
        final o = tester.widget<Opacity>(
          find
              .ancestor(of: find.text(text), matching: find.byType(Opacity))
              .first,
        );
        return o.opacity;
      }

      expect(opacityOf('کبریت'), 0);
      await tester.pump(const Duration(milliseconds: 2000));
      expect(opacityOf('کبریت'), 1);
      await tester.pump(const Duration(milliseconds: 1500));
      expect(opacityOf('برای شروع، صفحه را لمس کن'), greaterThan(.3));
    });

    testWidgets('reduced flicker stops the clock once settled', (tester) async {
      await pumpScreen(
        tester,
        const FlickerScope(reduce: true, child: SplashScreen()),
      );
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(seconds: 1));
      // No frame is scheduled any more, so this settles immediately.
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
    });
  });

  group('BenefitsScreen', () {
    testWidgets('CTAs call their callbacks', (tester) async {
      var play = 0, tut = 0;
      final c = ScrollController();
      addTearDown(c.dispose);
      await pumpScreen(
        tester,
        BenefitsScreen(
          onPlay: () => play++,
          onTutorial: () => tut++,
          controller: c,
          flamePhase: .5,
        ),
        size: const Size(390, 844),
      );
      c.jumpTo(c.position.maxScrollExtent);
      await tester.pump();
      await tester.tap(find.text('کبریت را روشن کن'));
      await tester.tap(find.text('اول آموزش را ببینم'));
      expect([play, tut], [1, 1]);
    });

    testWidgets('eight numbered cards in Persian digits', (tester) async {
      await pumpScreen(
        tester,
        const BenefitsScreen(flamePhase: .5),
        size: const Size(390, 1960),
      );
      for (final n in ['۰۱', '۰۲', '۰۳', '۰۴', '۰۵', '۰۶', '۰۷', '۰۸']) {
        expect(find.text(n), findsOneWidget, reason: n);
      }
      // The design's `min-height: 1960` is only the canvas preview crop; the
      // real content is taller and scrolls.
      final h = tester.getSize(find.byType(Column).first).height;
      expect(h, greaterThan(1960));
    });
  });
}
