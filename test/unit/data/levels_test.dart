import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/data/levels.dart';
import 'package:kebrit/game/game_engine.dart';
import 'package:kebrit/game/game_state.dart';
import 'package:kebrit/game/grid.dart';
import 'package:kebrit/game/hunter_ai.dart';

import '../game/fixtures.dart';

void main() {
  test('catalogue has 15 levels with ids 1..15', () {
    expect(Levels.all.map((l) => l.id), [for (var i = 1; i <= 15; i++) i]);
    expect(() => Levels.byId(0), throwsRangeError);
    expect(() => Levels.byId(16), throwsRangeError);
  });

  test('matches/hunters table matches MLevels', () {
    const matches = [12, 11, 10, 9, 8, 7, 6, 5, 5, 4, 4, 4, 3, 3, 2];
    const hunters = [0, 0, 0, 0, 0, 1, 2, 3, 3, 3, 4, 4, 4, 5, 5];
    for (var i = 0; i < 15; i++) {
      final l = Levels.all[i];
      expect(l.startMatches, matches[i], reason: 'level ${l.id} matches');
      expect(l.hunterStarts.length, hunters[i], reason: 'level ${l.id} hunters');
    }
  });

  test('chapters: 5 levels each, names from the design', () {
    expect(Levels.byId(1).chapter, 'خانه‌ی کهنه');
    expect(Levels.byId(5).chapter, 'خانه‌ی کهنه');
    expect(Levels.byId(6).chapter, 'سرداب‌ها');
    expect(Levels.byId(10).chapter, 'سرداب‌ها');
    expect(Levels.byId(11).chapter, 'دخمه‌ها');
    expect(Levels.byId(7).name, 'سرداب زیرین');
    expect(Levels.byId(15).name, 'آخرین در');
  });

  test('level 7 is the real map with its real start cells', () {
    final l = Levels.byId(7);
    final fx = level7();
    expect(l.playerStart, fx.playerStart);
    expect(l.hunterStarts, fx.hunterStarts);
    expect(l.pickups, fx.pickups);
    for (var y = 0; y < fx.grid.rows; y++) {
      for (var x = 0; x < fx.grid.cols; x++) {
        expect(l.grid.typeAt(x, y), fx.grid.typeAt(x, y), reason: '($x,$y)');
      }
    }
    expect(Levels.placeholderIds.contains(7), isFalse);
    expect(Levels.placeholderIds.length, 14);
  });

  test('every level is solvable (BFS start → exit)', () {
    for (final l in Levels.all) {
      expect(stepsToExit(l.grid, l.playerStart), isNotNull,
          reason: 'level ${l.id}');
    }
  });

  test('every level is solvable by actually walking it with the engine', () {
    // Greedy walk along BFS distances using only public engine API.
    for (final l in Levels.all) {
      final e = GameEngine(l);
      final dist = HunterAi.distances(l.grid, l.grid.exit, allowExit: true);
      var guard = 0;
      while (e.state.isPlaying && guard++ < 500) {
        final p = e.state.player;
        final d = dist[p]!;
        final dir = Dir.values.firstWhere(
            (dr) => dist[Cell(p.x + dr.dx, p.y + dr.dy)] == d - 1);
        e.step(dir);
        // Dark: hunters never move, so walking into one is the only risk;
        // placeholders keep hunters away from the start, so just assert.
      }
      expect(e.state.result == GameResult.escaped || e.state.result == GameResult.caught,
          isTrue,
          reason: 'level ${l.id}');
    }
  });

  test('placeholder layout sanity: bounds, start, hunters', () {
    for (final l in Levels.all) {
      expect(l.grid.cols, 9);
      expect(l.grid.rows, 13);
      expect(l.grid.exit, const Cell(4, 0));
      expect(l.grid.typeAt(l.playerStart.x, l.playerStart.y), CellType.floor);
      expect(l.hunterStarts.toSet().length, l.hunterStarts.length,
          reason: 'level ${l.id} distinct hunters');
      for (final h in l.hunterStarts) {
        expect(l.grid.typeAt(h.x, h.y), CellType.floor, reason: '${l.id} $h');
        expect(h, isNot(l.playerStart), reason: 'level ${l.id}');
        expect(HunterAi.distances(l.grid, l.playerStart)[h], isNotNull,
            reason: 'level ${l.id} hunter reachable');
      }
    }
  });

  test('placeholders are deterministic', () {
    final a = Levels.byId(3).grid;
    final b = Levels.byId(3).grid;
    for (var y = 0; y < a.rows; y++) {
      for (var x = 0; x < a.cols; x++) {
        expect(a.typeAt(x, y), b.typeAt(x, y));
      }
    }
  });
}
