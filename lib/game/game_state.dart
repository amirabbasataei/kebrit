import 'grid.dart';
import 'level.dart';

enum GameResult { playing, escaped, caught, outOfMatches }

/// Immutable snapshot of a run.
class GameState {
  GameState({
    required this.level,
    required this.player,
    required List<Cell> hunters,
    required this.matches,
    required this.burn,
    required this.lit,
    required Set<Cell> pickedUp,
    this.ticks = 0,
    this.litTicks = 0,
    this.matchesStruck = 0,
    this.steps = 0,
    this.result = GameResult.playing,
  }) : hunters = List.unmodifiable(hunters),
       pickedUp = Set.unmodifiable(pickedUp);

  /// Fresh state: dark, full matches, nothing picked up.
  factory GameState.initial(Level level) => GameState(
    level: level,
    player: level.playerStart,
    hunters: level.hunterStarts,
    matches: level.startMatches,
    burn: 0,
    lit: false,
    pickedUp: const {},
  );

  final Level level;
  final Cell player;
  final List<Cell> hunters;
  final int matches;

  /// 0..100. Seconds left = `burn / 100 * 8`.
  final double burn;
  final bool lit;
  final Set<Cell> pickedUp;

  /// Total ticks elapsed while playing (lit or dark); time = ticks * 100 ms.
  final int ticks;

  /// Ticks of the current flame; drives the every-9th-tick hunter cadence.
  final int litTicks;

  // Stats.
  final int matchesStruck;
  final int steps;

  final GameResult result;

  bool get isPlaying => result == GameResult.playing;

  /// Dark, no matches, run not finished. A flag only: the player decides
  /// whether to give up (see `GameEngine.giveUp`).
  bool get isOutOfMatches => isPlaying && !lit && matches == 0;

  /// Whole seconds of flame left (matches the strike-button label).
  int get secondsLeft => lit ? (burn / 100 * 8).ceil() : 0;

  /// Elapsed time in ticks (alias for [ticks]).
  int get elapsedTicks => ticks;

  /// Elapsed time in milliseconds.
  int get elapsedMs => ticks * 100;

  GameState copyWith({
    Cell? player,
    List<Cell>? hunters,
    int? matches,
    double? burn,
    bool? lit,
    Set<Cell>? pickedUp,
    int? ticks,
    int? litTicks,
    int? matchesStruck,
    int? steps,
    GameResult? result,
  }) => GameState(
    level: level,
    player: player ?? this.player,
    hunters: hunters ?? this.hunters,
    matches: matches ?? this.matches,
    burn: burn ?? this.burn,
    lit: lit ?? this.lit,
    pickedUp: pickedUp ?? this.pickedUp,
    ticks: ticks ?? this.ticks,
    litTicks: litTicks ?? this.litTicks,
    matchesStruck: matchesStruck ?? this.matchesStruck,
    steps: steps ?? this.steps,
    result: result ?? this.result,
  );
}
