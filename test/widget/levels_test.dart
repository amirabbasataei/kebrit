import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/data/progress.dart';
import 'package:kebrit/ui/screens/levels/level_tile.dart';
import 'package:kebrit/ui/screens/levels/levels_screen.dart';

import '../helpers/fonts.dart';
import '../helpers/golden_harness.dart';

Progress mock() => Progress(
      currentLevel: 7,
      embers: const {1: 3, 2: 3, 3: 2, 4: 3, 5: 2, 6: 1},
    );

void main() {
  setUpAll(loadAppFonts);

  test('pulseShadow eases between the keyframes', () {
    expect(pulseShadow(0).blur, 12);
    expect(pulseShadow(1).blur, 12);
    expect(pulseShadow(.5).blur, 22);
    expect(pulseShadow(.5).spread, 4);
    expect(pulseShadow(.25).blur, inExclusiveRange(12, 22));
  });

  testWidgets('header shows rooms and embers; default selection is current',
      (tester) async {
    await pumpScreen(tester, LevelsScreen(progress: mock(), pulsePhase: 0));
    expect(find.textContaining('۶ از ۱۵ اتاق'), findsOneWidget);
    expect(find.textContaining('۱۴ از ۴۵ اخگر'), findsOneWidget);
    expect(find.text('ورود به اتاق'), findsOneWidget);
    expect(find.text('سرداب زیرین'), findsOneWidget);
  });

  testWidgets('tapping tiles switches the sheet: done / locked', (tester) async {
    final played = <int>[];
    await pumpScreen(
      tester,
      LevelsScreen(progress: mock(), pulsePhase: 0, onPlay: played.add),
    );

    await tester.tap(find.bySemanticsLabel('مرحله‌ی ۳، اجاق سرد، گذرانده‌شده'));
    await tester.pump();
    expect(find.text('بازی دوباره'), findsOneWidget);
    expect(find.text('۲ از ۳'), findsOneWidget);
    await tester.tap(find.text('بازی دوباره'));
    expect(played, [3]);

    await tester.tap(find.bySemanticsLabel('مرحله‌ی ۱۰، سرای نگهبانان، قفل'));
    await tester.pump();
    expect(find.text('ورود به اتاق'), findsNothing);
    expect(find.text('برای باز شدن، از مرحله‌ی ۹ بگریز'), findsOneWidget);
    expect(find.text('راه پایین هنوز بسته است.'), findsOneWidget);
  });

  testWidgets('back arrow calls onBack', (tester) async {
    var back = 0;
    await pumpScreen(
      tester,
      LevelsScreen(progress: mock(), pulsePhase: 0, onBack: () => back++),
    );
    await tester.tap(find.bySemanticsLabel('بازگشت به منوی اصلی'));
    expect(back, 1);
  });

  testWidgets('live pulse runs a ticker; reduced flicker does not',
      (tester) async {
    await pumpScreen(tester, LevelsScreen(progress: mock()));
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.hasRunningAnimations, isTrue);

    await pumpScreen(
      tester,
      LevelsScreen(progress: mock(), reduceFlicker: true),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('tile is a labelled, selected button for semantics', (tester) async {
    final h = tester.ensureSemantics();
    await pumpScreen(tester, LevelsScreen(progress: mock(), pulsePhase: 0));
    expect(
      tester.getSemantics(find.bySemanticsLabel('مرحله‌ی ۷، سرداب زیرین، مرحله‌ی فعلی')),
      matchesSemantics(
        label: 'مرحله‌ی ۷، سرداب زیرین، مرحله‌ی فعلی',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
        hasEnabledState: false,
        isFocusable: false,
      ),
    );
    h.dispose();
  });
}
