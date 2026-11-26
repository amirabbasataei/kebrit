import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/data/levels.dart';
import 'package:kebrit/ui/screens/transition/transition_screen.dart';

import '../helpers/fonts.dart';
import '../helpers/golden_harness.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('forLevel builds the card texts for level 8', (tester) async {
    await pumpScreen(tester, TransitionScreen.forLevel(Levels.byId(8), time: 6));
    expect(find.text('فصل دوم · مرحله‌ی ۸'), findsOneWidget);
    expect(find.text(Levels.byId(8).name), findsOneWidget);
    expect(find.text('۵ کبریت · ۳ شکارچی'), findsOneWidget);
    expect(find.text('آن‌ها شنیدن را یاد گرفته‌اند.'), findsOneWidget);
  });

  testWidgets('natural end calls onDone exactly once', (tester) async {
    var done = 0;
    await pumpScreen(
      tester,
      TransitionScreen.forLevel(Levels.byId(8), onDone: () => done++),
    );
    await tester.pump(const Duration(seconds: 4));
    expect(done, 0);
    await tester.pump(const Duration(seconds: 6));
    expect(done, 1);
    await tester.pump(const Duration(seconds: 5));
    expect(done, 1);
  });

  testWidgets('skip calls onDone immediately and only once', (tester) async {
    var done = 0;
    await pumpScreen(
      tester,
      TransitionScreen.forLevel(Levels.byId(8), onDone: () => done++),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('رد شدن'));
    expect(done, 1);
    await tester.tap(find.text('رد شدن'));
    await tester.pump(const Duration(seconds: 12));
    expect(done, 1);
  });

  testWidgets('pinned time never fires onDone by itself', (tester) async {
    var done = 0;
    await pumpScreen(
      tester,
      TransitionScreen.forLevel(Levels.byId(8), time: 9, onDone: () => done++),
    );
    await tester.pump(const Duration(seconds: 20));
    expect(done, 0);
  });
}
