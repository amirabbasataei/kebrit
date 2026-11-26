import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'theme/app_theme.dart';
import 'theme/tokens.dart';

const kFaLocale = Locale('fa');

class KebritApp extends StatelessWidget {
  const KebritApp({super.key, this.home});

  /// Overridable so tests / later phases can inject a screen.
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      debugShowCheckedModeBanner: false,
      color: Kc.page,
      locale: kFaLocale,
      supportedLocales: const [kFaLocale],
      localizationsDelegates: const [
        GlobalWidgetsLocalizations.delegate,
      ],
      pageRouteBuilder: <T>(settings, builder) =>
          PageRouteBuilder<T>(settings: settings, pageBuilder: (c, _, _) => builder(c)),
      home: KebritTheme(child: home ?? const _Placeholder()),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('کبریت', style: TextStyle(fontFamily: 'Lalezar', fontSize: 64)),
    );
  }
}
