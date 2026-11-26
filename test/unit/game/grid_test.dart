import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/game/grid.dart';
import 'package:kebrit/game/hunter_ai.dart';

import 'fixtures.dart';

void main() {
  test('level 7 map parses to 9x13 with exit at (4,0)', () {
    final g = level7().grid;
    expect(g.cols, 9);
    expect(g.rows, 13);
    expect(g.exit, const Cell(4, 0));
    expect(g.isExit(4, 0), isTrue);
    expect(g.isWall(0, 0), isTrue);
    expect(g.isWall(1, 1), isFalse);
  });

  test('level 7 start cells are floor', () {
    final l = level7();
    expect(l.grid.typeAt(l.playerStart.x, l.playerStart.y), CellType.floor);
    for (final h in [...l.hunterStarts, ...l.pickups]) {
      expect(l.grid.typeAt(h.x, h.y), CellType.floor, reason: '$h');
    }
  });

  test('isWall/isExit are bounds-safe', () {
    final g = level7().grid;
    expect(g.isWall(-1, 0), isTrue);
    expect(g.isWall(0, -1), isTrue);
    expect(g.isWall(9, 0), isTrue);
    expect(g.isWall(0, 13), isTrue);
    expect(g.isExit(-1, -1), isFalse);
    expect(g.isExit(99, 99), isFalse);
  });

  test('parse rejects bad maps', () {
    expect(() => Grid.parse([]), throwsFormatException);
    expect(() => Grid.parse(['#E#', '##']), throwsFormatException);
    expect(() => Grid.parse(['#x#']), throwsFormatException);
    expect(() => Grid.parse(['###']), throwsFormatException); // no exit
    expect(() => Grid.parse(['#EE']), throwsFormatException); // two exits
  });

  test('stepsToExit on level 7 from the start is 16', () {
    // (1,11) →2 right →2 up (3,9) →2 right (5,9) →8 up (5,1) →1 left →1 up.
    final l = level7();
    expect(stepsToExit(l.grid, l.playerStart), 16);
    expect(stepsToExit(l.grid, const Cell(4, 1)), 1);
  });

  test('stepsToExit is null when the exit is unreachable', () {
    final g = Grid.parse(pocketsMap);
    expect(stepsToExit(g, const Cell(1, 1)), isNull);
  });
}
