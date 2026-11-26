import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/ui/kit/flame.dart';
import 'package:kebrit/ui/kit/flicker.dart';
import 'package:kebrit/ui/kit/light_overlay.dart';

import '../../helpers/golden_harness.dart';

Matrix4 _flameTransform(WidgetTester tester) => tester
    .widget<Transform>(
      find.descendant(of: find.byType(Flame), matching: find.byType(Transform)),
    )
    .transform;

void main() {
  testWidgets('flame flickers: transform changes while frames advance', (
    tester,
  ) async {
    await pumpScreen(tester, const Center(child: Flame.title()));
    final a = _flameTransform(tester).clone();
    await tester.pump(const Duration(milliseconds: 150));
    final b = _flameTransform(tester).clone();
    expect(a, isNot(b));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
  });

  testWidgets('reduce flicker (FlickerScope) stops the flame', (tester) async {
    await pumpScreen(
      tester,
      const FlickerScope(reduce: true, child: Center(child: Flame.title())),
    );
    final a = _flameTransform(tester).clone();
    expect(
      tester.binding.transientCallbackCount,
      0,
      reason: 'no ticker may run while flicker is reduced',
    );
    await tester.pump(const Duration(milliseconds: 150));
    expect(_flameTransform(tester), a);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('toggling reduce flicker at runtime starts/stops the flame', (
    tester,
  ) async {
    Widget app(bool reduce) => FlickerScope(
      reduce: reduce,
      child: const Center(child: Flame.player()),
    );
    await pumpScreen(tester, app(false));
    expect(tester.binding.transientCallbackCount, greaterThan(0));

    await pumpScreen(tester, app(true));
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);

    await pumpScreen(tester, app(false));
    await tester.pump();
    expect(tester.binding.transientCallbackCount, greaterThan(0));
  });

  testWidgets('pinned phase is static and deterministic', (tester) async {
    await pumpScreen(tester, const Center(child: Flame.title(phase: 1)));
    final a = _flameTransform(tester).clone();
    await tester.pump(const Duration(milliseconds: 300));
    expect(_flameTransform(tester), a);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('reduceFlicker param overrides the scope', (tester) async {
    await pumpScreen(
      tester,
      const FlickerScope(
        reduce: false,
        child: Center(child: Flame.title(reduceFlicker: true)),
      ),
    );
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('WarmFlicker pulses and is steady when reduced', (tester) async {
    double opacity() => tester
        .widget<Opacity>(
          find.descendant(
            of: find.byType(WarmFlicker),
            matching: find.byType(Opacity),
          ),
        )
        .opacity;

    await pumpScreen(
      tester,
      WarmFlicker.game(center: const Offset(100, 100), burn: 72),
    );
    final seen = <double>{};
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 160));
      seen.add(opacity());
    }
    expect(seen.length, greaterThan(3));
    expect(seen.every((o) => o >= .6 && o <= 1), isTrue);

    await pumpScreen(
      tester,
      FlickerScope(
        reduce: true,
        child: WarmFlicker.game(center: const Offset(100, 100), burn: 72),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(opacity(), 1);
    expect(tester.binding.transientCallbackCount, 0);
  });

  test('FlickerProfile follows the CSS keyframes', () {
    const p = FlickerProfile.game;
    expect(p.at(0), 1);
    expect(p.at(.18), closeTo(.72, 1e-9));
    expect(p.at(.40), closeTo(.95, 1e-9));
    expect(p.at(.63), closeTo(.68, 1e-9));
    expect(p.at(.82), closeTo(.9, 1e-9));
    expect(p.at(1), 1);
    // Between keyframes the value stays between its neighbours.
    expect(p.at(.1), inInclusiveRange(.72, 1));
  });
}
