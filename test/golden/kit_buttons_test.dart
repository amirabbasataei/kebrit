// Golden sheet: pill buttons. Goldens are generated and verified only on
// Windows (Windows Server 2019); do not copy them between machines.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/theme/tokens.dart';
import 'package:kebrit/ui/kit/pill_button.dart';
import 'package:kebrit/ui/kit/stone_bg.dart';

import '../helpers/fonts.dart';
import '../helpers/golden_harness.dart';

void noop() {}

Widget _sheet() {
  return StoneBackground(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // MTitle nav
          const PillButton(
            label: 'ادامه',
            subLabel: 'مرحله‌ی ۷ · سرداب زیرین',
            height: 60,
            onPressed: noop,
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: PillButton(
                  label: 'آموزش بازی',
                  variant: PillVariant.outline,
                  height: 52,
                  fillColor: kOutlineFillTitle,
                  onPressed: noop,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: PillButton(
                  label: 'مراحل',
                  variant: PillVariant.outline,
                  height: 52,
                  fillColor: kOutlineFillTitle,
                  onPressed: noop,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const PillButton(
            label: 'تنظیمات',
            variant: PillVariant.text,
            height: 44,
            onPressed: noop,
          ),
          const SizedBox(height: 20),
          // MComplete
          const PillButton(
            label: 'اتاق بعدی',
            height: 58,
            onPressed: noop,
            icon: ChevronIcon(color: Kc.onFlame),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: PillButton(
                  label: 'تکرار برای ۳ اخگر',
                  variant: PillVariant.outline,
                  height: 50,
                  fontSize: 14,
                  onPressed: noop,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: PillButton(
                  label: 'مراحل',
                  variant: PillVariant.outline,
                  height: 50,
                  fontSize: 14,
                  onPressed: noop,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // MPause
          const PillButton(
            label: 'ادامه',
            height: 56,
            glowAlpha: .3,
            onPressed: noop,
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(
                child: PillButton(
                  label: 'از نو',
                  variant: PillVariant.outline,
                  height: 48,
                  fontSize: 13,
                  borderColor: Color(0x3DEFE3D0),
                  onPressed: noop,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: PillButton(
                  label: 'آموزش',
                  variant: PillVariant.outline,
                  height: 48,
                  fontSize: 13,
                  borderColor: Color(0x3DEFE3D0),
                  onPressed: noop,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: PillButton(
                  label: 'مراحل',
                  variant: PillVariant.outline,
                  height: 48,
                  fontSize: 13,
                  borderColor: Color(0x3DEFE3D0),
                  onPressed: noop,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Hugging pill (MGame overlay) + disabled
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PillButton(
                label: 'ادامه',
                height: 52,
                fontSize: 15,
                expand: false,
                onPressed: noop,
              ),
              SizedBox(width: 16),
              PillButton(
                label: 'غیرفعال',
                height: 52,
                fontSize: 15,
                expand: false,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('kit buttons sheet', (tester) async {
    await pumpScreen(tester, _sheet());
    await expectGolden(null, 'kit_buttons');
  });

  testWidgets('kit buttons: pressed + keyboard focus ring', (tester) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await pumpScreen(
      tester,
      StoneBackground(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PillButton(
                key: ValueKey('pressed-primary'),
                label: 'فشرده',
                height: 60,
                onPressed: noop,
              ),
              const SizedBox(height: 16),
              const PillButton(
                key: ValueKey('pressed-outline'),
                label: 'فشرده',
                variant: PillVariant.outline,
                height: 52,
                onPressed: noop,
              ),
              const SizedBox(height: 16),
              const PillButton(
                key: ValueKey('pressed-text'),
                label: 'فشرده',
                variant: PillVariant.text,
                height: 44,
                onPressed: noop,
              ),
              const SizedBox(height: 24),
              PillButton(
                label: 'فوکوس صفحه‌کلید',
                height: 56,
                autofocus: true,
                onPressed: noop,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    final gestures = [
      await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('pressed-primary'))),
      ),
    ];
    final g2 = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('pressed-outline'))),
      pointer: 2,
    );
    final g3 = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('pressed-text'))),
      pointer: 3,
    );
    gestures.addAll([g2, g3]);
    await tester.pump(const Duration(milliseconds: 300));
    await expectGolden(null, 'kit_buttons_pressed');
    for (final g in gestures) {
      await g.cancel();
    }
  });
}
