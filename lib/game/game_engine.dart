import 'game_config.dart';
import 'game_state.dart';
import 'grid.dart';
import 'hunter_ai.dart';
import 'level.dart';

/// Deterministic rules engine. Holds the current [GameState]; every method
/// replaces it with a new immutable snapshot. No timers: the caller drives
/// [tick] every [GameConfig.tickMs].
class GameEngine {
  GameEngine(Level level) : _state = GameState.initial(level);

  GameEngine.fromState(GameState state) : _state = state;

  GameState _state;

  GameState get state => _state;
  Level get level => _state.level;

  /// Light a match. No-op when finished, already lit, or out of matches.
  void strike() {
    final s = _state;
    if (!s.isPlaying || s.lit || s.matches <= 0) return;
    _state = s.copyWith(
      lit: true,
      burn: GameConfig.fullBurn,
      matches: s.matches - 1,
      matchesStruck: s.matchesStruck + 1,
      litTicks: 0,
    );
  }

  /// Advance 100 ms. Time always counts while playing; burn and hunters only
  /// move while lit. Hunters move on every 9th tick of the current flame.
  void tick() {
    final s = _state;
    if (!s.isPlaying) return;
    if (!s.lit) {
      _state = s.copyWith(ticks: s.ticks + 1);
      return;
    }
    final litTicks = s.litTicks + 1;
    final burn = s.burn - GameConfig.burnPerTick;
    if (burn <= 0) {
      _state = s.copyWith(
          ticks: s.ticks + 1, litTicks: litTicks, burn: 0, lit: false);
      return;
    }
    if (litTicks % GameConfig.hunterEveryTicks != 0) {
      _state =
          s.copyWith(ticks: s.ticks + 1, litTicks: litTicks, burn: burn);
      return;
    }
    final dist = HunterAi.distances(level.grid, s.player);
    var caught = false;
    final hunters = [
      for (final h in s.hunters)
        () {
          final n = HunterAi.nextStep(level.grid, h, s.player,
              distFromTarget: dist);
          if (n == s.player) caught = true;
          return n;
        }()
    ];
    _state = s.copyWith(
      ticks: s.ticks + 1,
      litTicks: litTicks,
      burn: burn,
      hunters: hunters,
      result: caught ? GameResult.caught : null,
    );
  }

  /// Move the player one cell. Walls block; the exit ends the run; the +2
  /// match pickup is one-time; stepping onto a hunter is caught.
  void step(Dir dir) {
    final s = _state;
    if (!s.isPlaying) return;
    final nx = s.player.x + dir.dx, ny = s.player.y + dir.dy;
    final grid = level.grid;
    if (grid.isWall(nx, ny)) return;
    final to = Cell(nx, ny);
    if (grid.isExit(nx, ny)) {
      _state = s.copyWith(
          player: to, steps: s.steps + 1, result: GameResult.escaped);
      return;
    }
    var matches = s.matches;
    var picked = s.pickedUp;
    if (level.pickups.contains(to) && !picked.contains(to)) {
      picked = {...picked, to};
      matches += GameConfig.pickupMatches;
    }
    final caught = s.hunters.contains(to);
    _state = s.copyWith(
      player: to,
      steps: s.steps + 1,
      matches: matches,
      pickedUp: picked,
      result: caught ? GameResult.caught : null,
    );
  }

  /// The player surrenders. Only allowed from the out-of-matches state.
  void giveUp() {
    if (_state.isOutOfMatches) {
      _state = _state.copyWith(result: GameResult.outOfMatches);
    }
  }
}
