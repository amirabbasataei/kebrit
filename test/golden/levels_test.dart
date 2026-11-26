// Level-select goldens. Goldens are generated and verified only on Windows
// (Windows Server 2019); do not copy them between machines.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/data/progress.dart';
import 'package:kebrit/ui/screens/levels/levels_screen.dart';

import '../helpers/design_compare.dart';
import '../helpers/fonts.dart';
import '../helpers/golden_harness.dart';

void _noop() {}

/// The design mock: current = 7, levels 1-6 done with 3,3,2,3,2,1 embers.
Progress mockProgress() => Progress(
  currentLevel: 7,
  embers: const {1: 3, 2: 3, 3: 2, 4: 3, 5: 2, 6: 1},
);

Widget screen({int? selected}) => LevelsScreen(
  progress: mockProgress(),
  initialSelected: selected,
  onBack: _noop,
  onPlay: (_) {},
  pulsePhase: 0,
);

void main() {
  setUpAll(loadAppFonts);

  testWidgets('levels: current level (7) selected', (tester) async {
    await pumpScreen(tester, screen());
    await expectGolden(null, 'levels');
    await expectMatchesDesign(
      tester,
      find.byKey(goldenKey),
      'design_refs/mobile/3_Levels.png',
    );
  });

  testWidgets('levels: pulse at peak, tile 3 selected (done)', (tester) async {
    await pumpScreen(
      tester,
      LevelsScreen(
        progress: mockProgress(),
        initialSelected: 3,
        onPlay: (_) {},
        pulsePhase: .5,
      ),
    );
    await expectGolden(null, 'levels_done_selected');
  });

  testWidgets('levels: locked level (10) selected', (tester) async {
    await pumpScreen(tester, screen(selected: 10));
    await expectGolden(null, 'levels_locked_selected');
  });
}
