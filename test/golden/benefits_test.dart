// Benefits goldens: the full 390x1960 board and a viewport-height scrolled
// frame. Goldens are generated and verified only on Windows (Windows Server
// 2019); do not copy them between machines.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/ui/screens/benefits/benefits_screen.dart';

import '../helpers/design_compare.dart';
import '../helpers/fonts.dart';
import '../helpers/golden_harness.dart';

void _noop() {}

void main() {
  setUpAll(loadAppFonts);

  // The design board is `min-height: 1960` but its content is ~2416 px tall;
  // the canvas export shows the top 1960 px.
  testWidgets('benefits board (top 1960 px, as exported)', (tester) async {
    await pumpScreen(
      tester,
      const BenefitsScreen(flamePhase: .5, onPlay: _noop, onTutorial: _noop),
      size: const Size(390, 1960),
    );
    await expectGolden(null, 'benefits_board');
    await expectMatchesDesign(
      tester,
      find.byKey(goldenKey),
      'design_refs/mobile/0b_Benefits.png',
    );
  });

  testWidgets('benefits full content', (tester) async {
    await pumpScreen(
      tester,
      const BenefitsScreen(flamePhase: .5, onPlay: _noop, onTutorial: _noop),
      size: const Size(390, 2420),
    );
    await expectGolden(null, 'benefits_full');
  });

  testWidgets('benefits scrolled viewport', (tester) async {
    final c = ScrollController();
    addTearDown(c.dispose);
    await pumpScreen(
      tester,
      BenefitsScreen(
        controller: c,
        flamePhase: .5,
        onPlay: _noop,
        onTutorial: _noop,
      ),
    );
    c.jumpTo(900);
    await tester.pump();
    await expectGolden(null, 'benefits_scrolled');
  });
}
