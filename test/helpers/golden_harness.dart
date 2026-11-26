import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/theme/app_theme.dart';
import 'package:kebrit/theme/tokens.dart';

const kPhone = Size(Kc.designWidth, Kc.designHeight);
final goldenKey = GlobalKey(debugLabel: 'golden');

/// Pumps [widget] at a fixed logical [size] and dpr (default 390x844 @1x),
/// RTL + `fa` locale + app default text style, wrapped in a [RepaintBoundary]
/// keyed by [goldenKey]. Optionally advances the clock by [clockAt].
Future<void> pumpScreen(
  WidgetTester tester,
  Widget widget, {
  Size size = kPhone,
  double dpr = 1.0,
  Duration? clockAt,
}) async {
  tester.view.physicalSize = size * dpr;
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.rtl,
      child: Localizations(
        locale: const Locale('fa'),
        delegates: const [
          DefaultWidgetsLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        child: MediaQuery(
          data: MediaQueryData(size: size, devicePixelRatio: dpr),
          child: KebritTheme(
            child: Center(
              child: RepaintBoundary(
                key: goldenKey,
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: widget,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  if (clockAt != null) {
    await tester.pump(clockAt);
  } else {
    await tester.pump();
  }
}

/// Compares the golden boundary (or [finder]) with `goldens/<name>.png`.
Future<void> expectGolden(Finder? finder, String name) {
  return expectLater(
    finder ?? find.byKey(goldenKey),
    matchesGoldenFile('goldens/$name.png'),
  );
}
