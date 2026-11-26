/// Navigation graph (PLAN Phase 11 flow table).
///
/// Stack discipline: the app is always `[title, X]` (or `[splash]`/`[title]`);
/// result screens replace the top route, and jumps to Game/Tutorial/Levels from
/// elsewhere rebuild the stack on top of a fresh Title.
library;

import 'package:flutter/widgets.dart';

import 'app_scope.dart';
import 'data/levels.dart';
import 'data/progress.dart';
import 'game/game_state.dart';
import 'game/level.dart';
import 'ui/screens/benefits/benefits_screen.dart';
import 'ui/screens/caught/caught_screen.dart';
import 'ui/screens/complete/complete_screen.dart';
import 'ui/screens/game/game_controller.dart';
import 'ui/screens/game/game_screen.dart';
import 'ui/screens/levels/levels_screen.dart';
import 'ui/screens/no_matches/no_matches_screen.dart';
import 'ui/screens/pause/pause_screen.dart';
import 'ui/screens/splash/splash_screen.dart';
import 'ui/screens/title/title_screen.dart';
import 'ui/screens/transition/transition_screen.dart';
import 'ui/screens/tutorial/tutorial_screen.dart';

/// What the Pause screen asks its caller to do.
enum PauseAction { resume, restart, tutorial, levels }

Route<T> fadeRoute<T>(WidgetBuilder builder) => PageRouteBuilder<T>(
      pageBuilder: (c, _, _) => builder(c),
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (_, a, _, child) =>
          FadeTransition(opacity: a, child: child),
    );

abstract final class AppFlow {
  /// Home route of the app.
  static Widget splash(BuildContext context) {
    final app = AppScope.of(context).app;
    return SplashScreen(
      reduceFlicker: app.settings.reduceFlicker,
      onStart: () => app.introSeen ? toTitle(context) : _benefits(context),
    );
  }

  // --- stack helpers -------------------------------------------------------

  static void _reset(BuildContext context, List<WidgetBuilder> stack) {
    final nav = Navigator.of(context);
    nav.pushAndRemoveUntil(fadeRoute<void>(stack.first), (_) => false);
    for (final b in stack.skip(1)) {
      nav.push(fadeRoute<void>(b));
    }
  }

  static void _replace(BuildContext context, WidgetBuilder b) =>
      Navigator.of(context).pushReplacement(fadeRoute<void>(b));

  static void toTitle(BuildContext context) => _reset(context, [_title]);

  static void toLevels(BuildContext context) => _reset(context, [_title, _levels]);

  static void toTutorial(BuildContext context) =>
      _reset(context, [_title, _tutorial]);

  static void toGame(BuildContext context, int level) =>
      _reset(context, [_title, (c) => _GamePage(level: Levels.byId(level))]);

  // --- screens -------------------------------------------------------------

  static void _benefits(BuildContext context) {
    final app = AppScope.of(context).app;
    _replace(
      context,
      (c) => BenefitsScreen(
        reduceFlicker: app.settings.reduceFlicker,
        onPlay: () {
          app.markIntroSeen();
          toTitle(c);
        },
        onTutorial: () {
          app.markIntroSeen();
          toTutorial(c);
        },
      ),
    );
  }

  static Widget _title(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: scope.app,
      builder: (context, _) => TitleScreen(
        progress: scope.app.progress,
        reduceFlicker: scope.app.settings.reduceFlicker,
        onContinue: () => toGame(context, scope.app.progress.currentLevel),
        onTutorial: () => Navigator.of(context)
            .push(fadeRoute<void>((c) => _tutorialPage(c, fromTitle: true))),
        onLevels: () =>
            Navigator.of(context).push(fadeRoute<void>(_levels)),
        onSettings: () => _settingsFromTitle(context),
      ),
    );
  }

  static Widget _tutorial(BuildContext context) => _tutorialPage(context);

  static Widget _tutorialPage(BuildContext context, {bool fromTitle = false}) {
    final app = AppScope.of(context).app;
    void leave() => toGame(context, app.progress.currentLevel);
    return TutorialScreen(
      reduceFlicker: app.settings.reduceFlicker,
      onSkip: leave,
      onDone: leave,
    );
  }

  static Widget _levels(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: scope.app,
      builder: (context, _) => LevelsScreen(
        progress: scope.app.progress,
        reduceFlicker: scope.app.settings.reduceFlicker,
        onBack: () async {
          final nav = Navigator.of(context);
          if (!await nav.maybePop() && context.mounted) toTitle(context);
        },
        onPlay: (n) => toGame(context, n),
      ),
    );
  }

  /// Title → «تنظیمات»: the Pause screen without a running game (Q8).
  static Future<void> _settingsFromTitle(BuildContext context) async {
    final app = AppScope.of(context).app;
    final level = Levels.byId(app.progress.currentLevel);
    final action = await Navigator.of(context).push<PauseAction>(
      fadeRoute((c) => pauseRoute(c, level: level, state: null)),
    );
    if (!context.mounted) return;
    switch (action) {
      case PauseAction.restart:
        toGame(context, level.id);
      case PauseAction.tutorial:
        toTutorial(context);
      case PauseAction.levels:
        toLevels(context);
      case PauseAction.resume || null:
        break;
    }
  }

  /// Pause screen bound to live settings; pops with a [PauseAction].
  static Widget pauseRoute(
    BuildContext context, {
    required Level level,
    required GameState? state,
  }) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: scope.app,
      builder: (context, _) => PauseScreen(
        level: level,
        state: state,
        settings: scope.app.settings,
        onSettingsChanged: scope.app.updateSettings,
        onContinue: () => Navigator.of(context).pop(PauseAction.resume),
        onRestart: () => Navigator.of(context).pop(PauseAction.restart),
        onTutorial: () => Navigator.of(context).pop(PauseAction.tutorial),
        onLevels: () => Navigator.of(context).pop(PauseAction.levels),
      ),
    );
  }

  static void _complete(BuildContext context, GameStats stats) {
    final app = AppScope.of(context).app;
    final embers = emberRule(
      startMatches: stats.startMatches,
      matchesStruck: stats.matchesStruck,
    );
    app.completeLevel(stats.level, embers);
    final id = stats.level;
    _replace(
      context,
      (c) => ListenableBuilder(
        listenable: app,
        builder: (c, _) => CompleteScreen(
          stats: stats,
          embers: app.progress.bestEmbers(id) == 0 ? embers : app.progress.bestEmbers(id),
          reduceFlicker: app.settings.reduceFlicker,
          onNext: () => _replace(
            c,
            (c) => TransitionScreen.forLevel(
              Levels.byId(id + 1),
              reduceFlicker: app.settings.reduceFlicker,
              onDone: () => toGame(c, id + 1),
            ),
          ),
          onRepeat: () => toGame(c, id),
          onLevels: () => toLevels(c),
        ),
      ),
    );
  }

  static void _caught(BuildContext context, GameStats stats) {
    final app = AppScope.of(context).app;
    _replace(
      context,
      (c) => CaughtScreen(
        stats: stats,
        reduceFlicker: app.settings.reduceFlicker,
        onRetry: () => toGame(c, stats.level),
        onLevels: () => toLevels(c),
      ),
    );
  }

  static void _noMatches(BuildContext context, GameStats stats) {
    final app = AppScope.of(context).app;
    _replace(
      context,
      (c) => NoMatchesScreen(
        stats: stats,
        reduceFlicker: app.settings.reduceFlicker,
        onRetry: () => toGame(c, stats.level),
        onLevels: () => toLevels(c),
      ),
    );
  }
}

/// Gameplay route: owns the [GameController] so it survives the Pause screen.
class _GamePage extends StatefulWidget {
  const _GamePage({required this.level});

  final Level level;

  @override
  State<_GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<_GamePage> {
  GameController? _c;
  bool _pausing = false;

  GameController _controller(AppScope scope) => _c ??= GameController(
        widget.level,
        haptics: scope.haptics,
        settings: scope.app.settings,
        timerFactory: scope.timerFactory,
      );

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  Future<void> _pause() async {
    if (_pausing) return;
    _pausing = true;
    final c = _c!;
    if (c.started && c.state.isPlaying) c.pause();
    final action = await Navigator.of(context).push<PauseAction>(fadeRoute(
      (ctx) => AppFlow.pauseRoute(ctx, level: widget.level, state: c.state),
    ));
    _pausing = false;
    if (!mounted) return;
    switch (action) {
      case PauseAction.restart:
        AppFlow.toGame(context, widget.level.id);
      case PauseAction.tutorial:
        AppFlow.toTutorial(context);
      case PauseAction.levels:
        AppFlow.toLevels(context);
      case PauseAction.resume || null:
        if (c.paused) c.resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final c = _controller(scope);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _pause();
      },
      child: ListenableBuilder(
        listenable: scope.app,
        builder: (context, _) => GameScreen(
          controller: c,
          settings: scope.app.settings,
          haptics: scope.haptics,
          onPause: _pause,
          onEscaped: (s) => AppFlow._complete(context, s),
          onCaught: (s) => AppFlow._caught(context, s),
          onGiveUp: (s) => AppFlow._noMatches(context, s),
        ),
      ),
    );
  }
}