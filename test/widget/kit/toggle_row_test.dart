import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/ui/kit/toggle_row.dart';

import '../../helpers/golden_harness.dart';

double _knobLeft(WidgetTester tester) =>
    tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned)).left!;

Color _track(WidgetTester tester) =>
    (tester
                .widget<Container>(
                  find
                      .descendant(
                        of: find.byType(KToggle),
                        matching: find.byType(Container),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration)
        .color!;

void main() {
  testWidgets('tapping the row flips the value; knob and track follow', (
    tester,
  ) async {
    var on = false;
    final changes = <bool>[];
    await pumpScreen(
      tester,
      StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.all(24),
          child: ToggleRow(
            label: 'صدا',
            description: 'صدای قدم‌ها',
            value: on,
            onChanged: (v) => setState(() {
              on = v;
              changes.add(v);
            }),
          ),
        ),
      ),
    );

    // Off: knob at left 23, translucent track.
    expect(_knobLeft(tester), 23);
    expect(_track(tester), KToggle.trackOff);

    await tester.tap(find.byType(ToggleRow));
    await tester.pump(const Duration(milliseconds: 200));
    expect(changes, [true]);
    expect(_knobLeft(tester), 3);
    expect(_track(tester), KToggle.trackOn);

    await tester.tap(find.byType(ToggleRow));
    await tester.pump(const Duration(milliseconds: 200));
    expect(changes, [true, false]);
    expect(_knobLeft(tester), 23);
  });

  testWidgets('null onChanged ignores taps', (tester) async {
    await pumpScreen(
      tester,
      const Padding(
        padding: EdgeInsets.all(24),
        child: ToggleRow(
          label: 'لرزش',
          description: 'x',
          value: true,
          onChanged: null,
        ),
      ),
    );
    await tester.tap(find.byType(ToggleRow));
    await tester.pump(const Duration(milliseconds: 200));
    expect(_knobLeft(tester), 3);
  });

  testWidgets('row is at least 56 px tall', (tester) async {
    await pumpScreen(
      tester,
      Padding(
        padding: const EdgeInsets.all(24),
        child: Align(
          alignment: Alignment.topCenter,
          child: ToggleRow(
            label: 'a',
            description: 'b',
            value: false,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(ToggleRow)).height,
      greaterThanOrEqualTo(56),
    );
  });
}
