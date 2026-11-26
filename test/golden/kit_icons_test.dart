// Golden sheet: match + ember icons. Goldens are generated and verified only
// on Windows (Windows Server 2019); do not copy them between machines.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/theme/tokens.dart';
import 'package:kebrit/ui/kit/ember_icon.dart';
import 'package:kebrit/ui/kit/match_icon.dart';

import '../helpers/fonts.dart';
import '../helpers/golden_harness.dart';

Widget _scaled(Widget w, double k) => Transform.scale(scale: k, child: w);

void main() {
  setUpAll(loadAppFonts);

  testWidgets('kit match and ember icons', (tester) async {
    await pumpScreen(
      tester,
      DecoratedBox(
        decoration: const BoxDecoration(color: Kc.page),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Hero match (MTitle position 186,190 → shifted down for the sheet)
            const Positioned(
                left: 80, top: 130, child: MatchStick(phase: .5)),
            const Positioned(
                left: 250, top: 130, child: MatchStick(lit: false)),

            // HUD match icon + strike match, 1× and 4×.
            Positioned(
              left: 40,
              top: 360,
              child: Row(
                children: [
                  const MatchIcon(),
                  const SizedBox(width: 24),
                  const MatchStrikeIcon(),
                  const SizedBox(width: 24),
                  const MatchStrikeIcon(lit: true, phase: .5),
                ],
              ),
            ),
            Positioned(
              left: 190,
              top: 380,
              child: Row(
                children: [
                  _scaled(const MatchIcon(), 4),
                  const SizedBox(width: 50),
                  _scaled(const MatchStrikeIcon(), 4),
                  const SizedBox(width: 60),
                  _scaled(const MatchStrikeIcon(lit: true, phase: .5), 4),
                ],
              ),
            ),

            // Embers: small rows 0..3, large rows 0..3.
            Positioned(
              left: 40,
              top: 500,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i <= 3; i++) ...[
                    EmberRow(count: i),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 150,
              top: 490,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i <= 3; i++) ...[
                    EmberRow(count: i, size: EmberSize.large),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 290,
              top: 500,
              child: Column(
                children: [
                  _scaled(const EmberIcon.small(lit: true), 6),
                  const SizedBox(height: 50),
                  _scaled(const EmberIcon.small(lit: false), 6),
                ],
              ),
            ),
          ],
        ),
      ),
      size: const Size(390, 640),
    );
    await expectGolden(null, 'kit_icons');
  });
}
