// Goldens for the next-level transition at fixed timestamps. Goldens are
// generated and verified only on Windows (Windows Server 2019); do not copy
// them between machines.
import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/data/levels.dart';
import 'package:kebrit/ui/screens/transition/transition_screen.dart';

import '../helpers/design_compare.dart';
import '../helpers/fonts.dart';
import '../helpers/golden_harness.dart';

void main() {
  setUpAll(loadAppFonts);

  for (final (t, name) in [
    (.4, '0_4'),
    (1.5, '1_5'),
    (2.7, '2_7'),
    (3.6, '3_6'),
    (5.0, '5_0'),
    (6.5, '6_5'),
  ]) {
    testWidgets('transition @ ${t}s', (tester) async {
      await pumpScreen(
        tester,
        TransitionScreen.forLevel(Levels.byId(8), time: t, onDone: () {}),
      );
      await expectGolden(null, 'transition_$name');
      await expectMatchesDesign(
        tester,
        find.byKey(goldenKey),
        'design_refs/mobile/7_Transition_$name.png',
      );
    });
  }
}
