// Golden sheet: flame sizes and flicker poses. Goldens are generated and
// verified only on Windows (Windows Server 2019); do not copy them between
// machines.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/theme/tokens.dart';
import 'package:kebrit/ui/kit/flame.dart';

import '../helpers/fonts.dart';
import '../helpers/golden_harness.dart';

Widget _cell(Widget flame, {double w = 90, double h = 150}) => SizedBox(
      width: w,
      height: h,
      child: Align(alignment: const Alignment(0, .6), child: flame),
    );

void main() {
  setUpAll(loadAppFonts);

  testWidgets('kit flame sizes and poses', (tester) async {
    await pumpScreen(
      tester,
      DecoratedBox(
        decoration: const BoxDecoration(color: Kc.page),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Title flame at the three poses of the flicker (from / mid / to).
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _cell(const Flame.title(phase: 0)),
                _cell(const Flame.title(phase: .5)),
                _cell(const Flame.title(phase: 1)),
              ],
            ),
            // Player + strike-button flames at 1× and magnified 5×.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _cell(const Flame.player(phase: .5), h: 120),
                _cell(const Flame.strikeButton(phase: .5), h: 120),
                _cell(
                  Transform.scale(
                      scale: 5,
                      alignment: Alignment.bottomCenter,
                      child: const Flame.player(phase: .5)),
                  h: 120,
                ),
                _cell(
                  Transform.scale(
                      scale: 5,
                      alignment: Alignment.bottomCenter,
                      child: const Flame.strikeButton(phase: .5)),
                  h: 120,
                ),
              ],
            ),
            // Not flickering at all.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _cell(const Flame.title(flicker: false), h: 130),
              ],
            ),
          ],
        ),
      ),
      size: const Size(390, 440),
    );
    await expectGolden(null, 'kit_flame');
  });
}
