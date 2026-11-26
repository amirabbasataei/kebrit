import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/ui/kit/pill_button.dart';

import '../../helpers/golden_harness.dart';

double _scale(WidgetTester tester) => tester
    .widget<AnimatedScale>(
      find.descendant(
        of: find.byType(PillButton),
        matching: find.byType(AnimatedScale),
      ),
    )
    .scale;

void main() {
  testWidgets('tap fires onPressed; pressed state scales down then restores', (
    tester,
  ) async {
    var taps = 0;
    await pumpScreen(
      tester,
      Center(
        child: PillButton(label: 'ادامه', onPressed: () => taps++),
      ),
    );
    expect(_scale(tester), 1);

    final g = await tester.startGesture(
      tester.getCenter(find.byType(PillButton)),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(_scale(tester), .97);
    expect(taps, 0);

    await g.up();
    await tester.pump(const Duration(milliseconds: 200));
    expect(_scale(tester), 1);
    expect(taps, 1);
  });

  testWidgets('dragging away cancels the tap', (tester) async {
    var taps = 0;
    await pumpScreen(
      tester,
      Center(
        child: PillButton(label: 'مراحل', onPressed: () => taps++),
      ),
    );
    final g = await tester.startGesture(
      tester.getCenter(find.byType(PillButton)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await g.moveBy(const Offset(0, 300));
    await g.up();
    await tester.pump(const Duration(milliseconds: 200));
    expect(taps, 0);
    expect(_scale(tester), 1);
  });

  testWidgets('disabled button ignores taps and never shows pressed', (
    tester,
  ) async {
    await pumpScreen(tester, const Center(child: PillButton(label: 'مراحل')));
    final g = await tester.startGesture(
      tester.getCenter(find.byType(PillButton)),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(_scale(tester), 1);
    await g.up();
    await tester.pump(const Duration(milliseconds: 200));
    expect(_scale(tester), 1);
    // Disabled buttons are dimmed.
    expect(
      tester
          .widget<Opacity>(
            find.descendant(
              of: find.byType(PillButton),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      .4,
    );
  });

  testWidgets('keyboard activation (Enter) fires onPressed', (tester) async {
    var taps = 0;
    await pumpScreen(
      tester,
      Center(
        child: PillButton(
          label: 'آموزش',
          autofocus: true,
          onPressed: () => taps++,
        ),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, 1);
  });

  test('button heights outside the design set are rejected', () {
    expect(() => PillButton(label: 'x', height: 30), throwsAssertionError);
  });
}
