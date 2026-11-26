// Golden sheets: stone / radial backgrounds, bottom sheet with toggle rows.
// Goldens are generated and verified only on Windows (Windows Server 2019);
// do not copy them between machines.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/theme/text_styles.dart';
import 'package:kebrit/ui/kit/fa_digits.dart';
import 'package:kebrit/ui/kit/pill_button.dart';
import 'package:kebrit/ui/kit/sheet.dart';
import 'package:kebrit/ui/kit/stone_bg.dart';
import 'package:kebrit/ui/kit/toggle_row.dart';

import '../helpers/fonts.dart';
import '../helpers/golden_harness.dart';

void noop() {}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('kit backgrounds: stone (title), stone (complete), vignettes',
      (tester) async {
    await pumpScreen(
      tester,
      Column(
        children: const [
          Expanded(child: StoneBackground()),
          Expanded(child: StoneBackground.complete()),
          Expanded(child: RadialBackdrop()),
          Expanded(child: RadialBackdrop.levels()),
        ],
      ),
    );
    await expectGolden(null, 'kit_backgrounds');
  });

  testWidgets('kit sheet with toggle rows (MPause) and Persian digits',
      (tester) async {
    await pumpScreen(
      tester,
      Stack(
        children: [
          const StoneBackground(),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomSheetPanel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text('تنظیمات', style: KText.caption),
                  ),
                  ToggleRow(
                      label: 'صدا',
                      description: 'صدای قدم‌ها، کبریت و نفس شکارچی‌ها',
                      value: true,
                      onChanged: (_) {}),
                  const SizedBox(height: 2),
                  ToggleRow(
                      label: 'لرزش گوشی',
                      description: 'لرزشی کوتاه وقتی شکارچی راه می‌افتد',
                      value: true,
                      onChanged: (_) {}),
                  const SizedBox(height: 2),
                  ToggleRow(
                      label: 'کاهش سوسو',
                      description: 'نور ثابت به‌جای شعله‌ی لرزان',
                      value: false,
                      onChanged: (_) {}),
                  const SizedBox(height: 2),
                  ToggleRow(
                      label: 'دکمه‌ی کبریت در سمت چپ',
                      description: 'برای بازی با دست چپ',
                      value: false,
                      onChanged: (_) {}),
                  const SizedBox(height: 20),
                  const PillButton(
                      label: 'ادامه',
                      height: 56,
                      glowAlpha: .3,
                      onPressed: noop),
                  const SizedBox(height: 16),
                  const Center(
                    child: FaText('مرحله‌ی 7 · 14 از 45 اخگر',
                        style: KText.body),
                  ),
                  Center(child: FaText.number(1402, style: KText.h2Serif)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    await expectGolden(null, 'kit_sheet');
  });
}
