// Splash goldens at named timestamps (PLAN §3.3). Goldens are generated and
// verified only on Windows (Windows Server 2019); do not copy them between
// machines.
import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/ui/screens/splash/splash_screen.dart';

import '../helpers/design_compare.dart';
import '../helpers/fonts.dart';
import '../helpers/golden_harness.dart';

void main() {
  setUpAll(loadAppFonts);

  for (final (ms, name) in [
    (300, 'splash_0_3s'), // sparks start, flame igniting
    (700, 'splash_0_7s'), // flame at max scale, glow fading in
    (1000, 'splash_1_0s'),
    (2000, 'splash_2_0s'), // logo + tagline in, fuse running
    (3400, 'splash_3_4s'), // settled, tap hint
  ]) {
    testWidgets('splash @ ${ms}ms', (tester) async {
      await pumpScreen(
        tester,
        SplashScreen(time: Duration(milliseconds: ms), reduceFlicker: false),
      );
      await expectGolden(null, name);
    });
  }

  testWidgets('splash design compare (skipped without reference)', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const SplashScreen(
        time: Duration(milliseconds: 3400),
        reduceFlicker: true,
      ),
    );
    await expectMatchesDesign(
      tester,
      find.byKey(goldenKey),
      'design_refs/mobile/0_Splash.png',
    );
  });
}
