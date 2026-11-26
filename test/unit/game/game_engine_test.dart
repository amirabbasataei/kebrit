import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/game/game_config.dart';
import 'package:kebrit/game/game_engine.dart';
import 'package:kebrit/game/game_state.dart';
import 'package:kebrit/game/grid.dart';
import 'package:kebrit/game/level.dart';

import 'fixtures.dart';

void ticks(GameEngine e, int n) {
  for (var i = 0; i < n; i++) {
    e.tick();
  }
}

void main() {
  group('strike', () {
    test('lights the match: matches-1, burn 100, stats', () {
      final e = GameEngine(corridor(matches: 3))..strike();
      expect(e.state.lit, isTrue);
      expect(e.state.burn, 100);
      expect(e.state.matches, 2);
      expect(e.state.matchesStruck, 1);
    });

    test('strike while lit is a no-op', () {
      final e = GameEngine(corridor(matches: 3))..strike();
      ticks(e, 10);
      final before = e.state;
      e.strike();
      expect(e.state.matches, before.matches);
      expect(e.state.burn, before.burn);
      expect(e.state.matchesStruck, 1);
    });

    test('strike with 0 matches is a no-op', () {
      final e = GameEngine(corridor(matches: 0))..strike();
      expect(e.state.lit, isFalse);
      expect(e.state.matches, 0);
      expect(e.state.matchesStruck, 0);
    });

    test('strike after the run ended is a no-op', () {
      final e = GameEngine(corridor(player: const Cell(2, 1)))
        ..step(Dir.up)
        ..strike();
      expect(e.state.lit, isFalse);
      expect(e.state.matches, 3);
    });
  });

  group('tick', () {
    test('burns 1.25 per tick', () {
      final e = GameEngine(corridor())..strike();
      e.tick();
      expect(e.state.burn, 100 - GameConfig.burnPerTick);
    });

    test('flame out after 80 ticks', () {
      final e = GameEngine(corridor())..strike();
      ticks(e, 79);
      expect(e.state.lit, isTrue);
      expect(e.state.burn, 1.25);
      e.tick();
      expect(e.state.lit, isFalse);
      expect(e.state.burn, 0);
      expect(e.state.matches, 2);
    });

    test('hunters frozen while dark', () {
      final e = GameEngine(corridor(hunters: const [Cell(3, 1)]));
      ticks(e, 100);
      expect(e.state.hunters, const [Cell(3, 1)]);
      expect(e.state.burn, 0);
      expect(e.state.isPlaying, isTrue);
    });

    test('hunters move only on every 9th lit tick', () {
      final e = GameEngine(corridor(hunters: const [Cell(3, 1)]))..strike();
      ticks(e, 8);
      expect(e.state.hunters, const [Cell(3, 1)]);
      e.tick(); // 9th
      expect(e.state.hunters, const [Cell(2, 1)]);
      ticks(e, 8);
      expect(e.state.hunters, const [Cell(2, 1)]);
    });

    test(
      'hunter cadence restarts with each new flame (not a global count)',
      () {
        // Long corridor: the hunter starts 9 cells away, so one flame (8 moves
        // on ticks 9..72) leaves it adjacent; the 80-tick global count would
        // put the next move on tick 90, i.e. the 10th tick of the 2nd flame.
        final level = Level(
          id: 0,
          name: 't',
          chapter: 't',
          startMatches: 2,
          grid: Grid.parse(['#E##########', '#..........#', '############']),
          playerStart: const Cell(1, 1),
          hunterStarts: const [Cell(10, 1)],
        );
        final e = GameEngine(level)..strike();
        ticks(e, 80);
        expect(e.state.lit, isFalse);
        expect(e.state.hunters, const [Cell(2, 1)]);
        expect(e.state.isPlaying, isTrue);
        e.strike();
        ticks(e, 8);
        expect(e.state.hunters, const [Cell(2, 1)]);
        e.tick(); // 9th tick of the new flame
        expect(e.state.result, GameResult.caught);
      },
    );

    test('elapsed ticks count while dark and lit', () {
      final e = GameEngine(corridor());
      ticks(e, 5);
      e.strike();
      ticks(e, 5);
      expect(e.state.ticks, 10);
      expect(e.state.elapsedMs, 1000);
    });
  });

  group('step', () {
    test('walls block and do not count as steps', () {
      final e = GameEngine(corridor())..step(Dir.left);
      expect(e.state.player, const Cell(1, 1));
      e.step(Dir.down);
      e.step(Dir.up); // (1,0) is wall
      expect(e.state.steps, 0);
    });

    test('moves the player and counts steps', () {
      final e = GameEngine(corridor())
        ..step(Dir.right)
        ..step(Dir.right);
      expect(e.state.player, const Cell(3, 1));
      expect(e.state.steps, 2);
    });

    test('the exit stops the engine', () {
      final e = GameEngine(corridor(player: const Cell(2, 1)))..strike();
      e.step(Dir.up);
      expect(e.state.result, GameResult.escaped);
      expect(e.state.player, const Cell(2, 0));
      final frozen = e.state;
      e.step(Dir.down);
      e.tick();
      e.strike();
      expect(e.state.player, frozen.player);
      expect(e.state.ticks, frozen.ticks);
      expect(e.state.burn, frozen.burn);
      expect(e.state.matches, frozen.matches);
    });

    test('pickup only once', () {
      final e = GameEngine(corridor(pickups: const [Cell(2, 1)], matches: 3))
        ..step(Dir.right);
      expect(e.state.matches, 5);
      expect(e.state.pickedUp, {const Cell(2, 1)});
      e.step(Dir.left);
      e.step(Dir.right);
      expect(e.state.matches, 5);
    });

    test('level 7: walking up the left column reaches the pickup', () {
      final e = GameEngine(level7());
      for (var i = 0; i < 4; i++) {
        e.step(Dir.up);
      }
      expect(e.state.player, const Cell(1, 7));
      expect(e.state.matches, 8);
    });
  });

  group('caught', () {
    test('player steps onto a hunter', () {
      final e = GameEngine(corridor(hunters: const [Cell(2, 1)]))
        ..step(Dir.right);
      expect(e.state.result, GameResult.caught);
    });

    test('hunter steps onto the player', () {
      final e = GameEngine(corridor(hunters: const [Cell(3, 1)]))..strike();
      ticks(e, 17);
      expect(e.state.isPlaying, isTrue);
      expect(e.state.hunters, const [Cell(2, 1)]);
      e.tick(); // 18th
      expect(e.state.result, GameResult.caught);
      expect(e.state.hunters, const [Cell(1, 1)]);
    });

    test('catch from both sides: no more input after caught', () {
      final e = GameEngine(corridor(hunters: const [Cell(2, 1)]))
        ..step(Dir.right);
      final p = e.state.player;
      e.step(Dir.right);
      expect(e.state.player, p);
    });
  });

  group('out of matches', () {
    test('is a flag when dark with 0 matches, not an automatic loss', () {
      final e = GameEngine(corridor(matches: 0));
      expect(e.state.isOutOfMatches, isTrue);
      expect(e.state.result, GameResult.playing);
      e.step(Dir.right); // the player can still walk
      expect(e.state.player, const Cell(2, 1));
    });

    test('flag appears when the last match burns out', () {
      final e = GameEngine(corridor(matches: 1))..strike();
      expect(e.state.isOutOfMatches, isFalse);
      ticks(e, 80);
      expect(e.state.isOutOfMatches, isTrue);
      expect(e.state.result, GameResult.playing);
    });

    test('giveUp ends the run only from the out-of-matches state', () {
      final a = GameEngine(corridor(matches: 2))..giveUp();
      expect(a.state.result, GameResult.playing);
      final b = GameEngine(corridor(matches: 0))..giveUp();
      expect(b.state.result, GameResult.outOfMatches);
    });

    test('a pickup clears the flag', () {
      final e = GameEngine(corridor(matches: 0, pickups: const [Cell(2, 1)]))
        ..step(Dir.right);
      expect(e.state.isOutOfMatches, isFalse);
      expect(e.state.matches, 2);
    });
  });
}
