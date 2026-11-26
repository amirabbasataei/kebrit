// Golden canary. Goldens are generated and verified only on Windows
// (Windows Server 2019); do not copy them between machines.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/theme/text_styles.dart';
import 'package:kebrit/theme/tokens.dart';

import '../helpers/design_compare.dart';
import '../helpers/fonts.dart';
import '../helpers/golden_harness.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('canary renders Persian glyphs with bundled fonts', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const DecoratedBox(
        decoration: BoxDecoration(color: Kc.page),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'کبریت',
                style: KText.logoTitle,
                textAlign: TextAlign.center,
              ),
              Text('هر شعله، هم راه است و هم خطر.', style: KText.tagline),
              Text('به سوی اعماق', style: KText.h1Serif),
              Text('مرحله‌ی ۷ · ۱۴ از ۴۵ اخگر · ۰۱۲۳۴۵۶۷۸۹', style: KText.body),
            ],
          ),
        ),
      ),
    );
    await expectGolden(null, 'canary');
  });

  testWidgets('design comparison skips cleanly when reference missing', (
    tester,
  ) async {
    await pumpScreen(tester, const SizedBox());
    await expectMatchesDesign(
      tester,
      find.byKey(goldenKey),
      'design_refs/mobile/__none__.png',
    );
  });
}
