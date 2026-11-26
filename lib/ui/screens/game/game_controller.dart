/// Drives a [GameEngine] from time and touch (the stateful half of MGame):
/// the 100 ms tick, the 170 ms repeat step while a finger is held, the
/// joystick drag and the "begin on first interaction" rule.
///
/// Time comes from an injectable [PeriodicTimerFactory] (default
/// `Timer.periodic`), so widget tests advance it with `tester.pump(Duration)`.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/settings.dart';
import '../../../game/drag_input.dart';
import '../../../game/game_config.dart';
import '../../../game/game_engine.dart';
import '../../../game/game_state.dart';
import '../../../game/grid.dart';
import '../../../game/hunter_ai.dart';
import '../../../game/level.dart';
import '../../../services/haptics.dart';
import 'joystick.dart';

typedef PeriodicTimerFactory = Timer Function(
    Duration period, void Function(Timer) callback);

Timer _defaultTimer(Duration p, void Function(Timer) cb) =>
    Timer.periodic(p, cb);

/// Numbers shown by the Complete / Caught / NoMatches screens.
class GameStats {
  const GameStats({
    required this.level,
    required this.startMatches,
    required this.matchesLeft,
    required this.matchesStruck,
    required this.elapsed,
    required this.steps,
    required this.stepsToDoor,
    required this.hunters,
  });

  factory GameStats.of(GameState s) => GameStats(
        level: s.level.id,
        startMatches: s.level.startMatches,
        matchesLeft: s.matches,
        matchesStruck: s.matchesStruck,
        elapsed: Duration(milliseconds: s.elapsedMs),
        steps: s.steps,
        stepsToDoor: stepsToExit(s.level.grid, s.player),
        hunters: s.level.hunterStarts.length,
      );

  final int level;
  final int startMatches;
  final int matchesLeft;
  final int matchesStruck;
  final Duration elapsed;
  final int steps;

  /// BFS distance from the player's current cell to the exit (null if none).
  final int? stepsToDoor;
  final int hunters;
}

class GameController extends ChangeNotifier {
  GameController(
    Level level, {
    this.haptics = const NoopHaptics(),
    this._settings = const AppSettings(),
    PeriodicTimerFactory? timerFactory,
  })  : _engine = GameEngine(level),
        _timerFactory = timerFactory ?? _defaultTimer;

  final GameEngine _engine;
  final Haptics haptics;
  final PeriodicTimerFactory _timerFactory;
  AppSettings _settings;

  Timer? _tick;
  Timer? _repeat;
  Dir? _dir;
  double _ox = 0, _oy = 0;
  JoystickDrag? _drag;
  bool _started = false;
  bool _paused = false;
  bool _disposed = false;

  GameState get state => _engine.state;

  /// The design's `init`: false until the first touch or strike.
  bool get started => _started;
  bool get paused => _paused;

  /// Non-null while a finger is down (joystick position, design space).
  JoystickDrag? get drag => _drag;
  GameStats get stats => GameStats.of(state);

  set settings(AppSettings s) => _settings = s;

  /// First interaction: the clock starts running.
  void begin() {
    if (_started) return;
    _started = true;
    _syncTimers();
    notifyListeners();
  }

  void strike() {
    if (_paused) return;
    begin();
    final before = state;
    _engine.strike();
    if (!identical(before, state)) notifyListeners();
  }

  void giveUp() {
    _engine.giveUp();
    _syncTimers();
    notifyListeners();
  }

  void pause() {
    if (_paused) return;
    _paused = true;
    _releaseFinger();
    _syncTimers();
    notifyListeners();
  }

  /// Resumes with burn/hunters exactly where they were.
  void resume() {
    if (!_paused) return;
    _paused = false;
    _syncTimers();
    notifyListeners();
  }

  // --- pointer input (design-space coordinates, 390x844) -------------------

  void pointerDown(double x, double y) {
    if (_paused) return;
    begin();
    if (!state.isPlaying) return;
    _ox = x;
    _oy = y;
    _dir = null;
    _drag = JoystickDrag(x, y);
    _repeat?.cancel();
    _repeat = _timerFactory(
      const Duration(milliseconds: GameConfig.stepMs),
      (_) {
        final d = _dir;
        if (d != null) _step(d);
      },
    );
    notifyListeners();
  }

  void pointerMove(double x, double y) {
    if (_drag == null) return;
    final r = DragClassifier.classify(_ox, _oy, x, y);
    final d = r.direction;
    if (d != null && d != _dir) {
      _dir = d;
      _step(d);
    } else {
      _dir = d;
    }
    _drag = JoystickDrag(_ox, _oy, r.knobDx, r.knobDy);
    notifyListeners();
  }

  void pointerUp() {
    if (_drag == null && _repeat == null) return;
    _releaseFinger();
    notifyListeners();
  }

  // --- internals ------------------------------------------------------------

  void _releaseFinger() {
    _repeat?.cancel();
    _repeat = null;
    _dir = null;
    _drag = null;
  }

  void _step(Dir d) {
    _engine.step(d);
    _afterChange();
  }

  void _onTick() {
    final before = state.hunters;
    _engine.tick();
    if (state.lit && !listEquals(before, state.hunters) && _settings.haptics) {
      haptics.hunterStep();
    }
    _afterChange();
  }

  void _afterChange() {
    if (!state.isPlaying) _releaseFinger();
    _syncTimers();
    notifyListeners();
  }

  /// The tick timer runs from the first interaction until the run ends or
  /// the game is paused; the repeat timer only while a finger is down.
  void _syncTimers() {
    final run = _started && !_paused && state.isPlaying && !_disposed;
    if (run && _tick == null) {
      _tick = _timerFactory(
          const Duration(milliseconds: GameConfig.tickMs), (_) => _onTick());
    } else if (!run) {
      _tick?.cancel();
      _tick = null;
      if (!state.isPlaying || _paused) {
        _repeat?.cancel();
        _repeat = null;
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _tick?.cancel();
    _repeat?.cancel();
    super.dispose();
  }
}
