// Tutorial goldens at named timestamps (time since the step appeared).
// Goldens are generated and verified only on Windows (Windows Server 2019);
// do not copy them between machines.
import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/ui/screens/tutorial/tutorial_screen.dart';

import '../helpers/design_compare.dart';
import '../helpers/fonts.dart';
import '../helpers/golden_harness.dart';

void _noop() {}

void main() {
  setUpAll(loadAppFonts);

  for (final (step, ms, name) in [
    (0, 1500, 'tutorial_1'), // finger dragging, explorer walking
    (1, 500, 'tutorial_2_dark'), // before the tap: black room
    (1, 1500, 'tutorial_2_lit'), // after the strike: lit room + flame
    (2, 1500, 'tutorial_3'), // hunter awake and approaching
    (3, 1500, 'tutorial_4'), // door + spare matches
  ]) {
    testWidgets('tutorial step ${step + 1} @${ms}ms', (tester) async {
      await pumpScreen(
        tester,
        TutorialScreen(
          initialStep: step,
          time: Duration(milliseconds: ms),
          onSkip: _noop,
          onDone: _noop,
        ),
      );
      await expectGolden(null, name);
      if (ms == 1500 && step != 1) {
        await expectMatchesDesign(
          tester,
          find.byKey(goldenKey),
          'design_refs/mobile/2_Tutorial_${step + 1}.png',
        );
      }
    });
  }
}
