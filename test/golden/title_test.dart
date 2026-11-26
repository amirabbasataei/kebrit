// Title golden. Goldens are generated and verified only on Windows (Windows
// Server 2019); do not copy them between machines.
import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/data/progress.dart';
import 'package:kebrit/ui/screens/title/title_screen.dart';

import '../helpers/design_compare.dart';
import '../helpers/fonts.dart';
import '../helpers/golden_harness.dart';

void _noop() {}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('title (level 7, flicker pinned)', (tester) async {
    await pumpScreen(
      tester,
      TitleScreen(
        progress: Progress(currentLevel: 7),
        onContinue: _noop,
        onTutorial: _noop,
        onLevels: _noop,
        onSettings: _noop,
        flickerPhase: 0, // warm layer at full opacity
      ),
    );
    await expectGolden(null, 'title');
    await expectMatchesDesign(tester, find.byKey(goldenKey), 'design_refs/mobile/1_Title.png');
  });
}
