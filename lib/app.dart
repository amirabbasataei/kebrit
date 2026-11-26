import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_scope.dart';
import 'data/progress_repository.dart';
import 'routes.dart';
import 'services/haptics.dart';
import 'services/sound.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';
import 'ui/kit/flicker.dart';
import 'ui/screens/game/game_controller.dart';

const kFaLocale = Locale('fa');

/// Root widget. Loads progress/settings from [repository] first, then runs the
/// flow starting at the Splash (or at [home], for tests/previews).
class KebritApp extends StatefulWidget {
  const KebritApp({
    super.key,
    required this.repository,
    this.haptics = const NoopHaptics(),
    this.sound = const SilentSoundPlayer(),
    this.timerFactory,
    this.home,
  });

  final ProgressRepository repository;
  final Haptics haptics;
  final SoundPlayer sound;
  final PeriodicTimerFactory? timerFactory;

  /// Overrides the first screen (builder gets a context inside [AppScope]).
  final WidgetBuilder? home;

  @override
  State<KebritApp> createState() => _KebritAppState();
}

class _KebritAppState extends State<KebritApp> {
  AppController? _app;

  @override
  void initState() {
    super.initState();
    AppController.load(widget.repository).then((a) {
      if (mounted) setState(() => _app = a);
    });
  }

  @override
  void dispose() {
    _app?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = _app;
    return WidgetsApp(
      debugShowCheckedModeBanner: false,
      color: Kc.page,
      locale: kFaLocale,
      supportedLocales: const [kFaLocale],
      localizationsDelegates: const [GlobalWidgetsLocalizations.delegate],
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (c, _, _) => builder(c),
      ),
      builder: (context, child) => ColoredBox(
        color: Kc.page,
        child: app == null
            ? const SizedBox.expand()
            : AppScope(
                controller: app,
                haptics: widget.haptics,
                sound: widget.sound,
                timerFactory: widget.timerFactory,
                child: ListenableBuilder(
                  listenable: app,
                  builder: (context, _) => FlickerScope(
                    reduce: app.settings.reduceFlicker,
                    child: KebritTheme(child: child!),
                  ),
                ),
              ),
      ),
      home: app == null
          ? const SizedBox.expand()
          : Builder(builder: widget.home ?? AppFlow.splash),
    );
  }
}
