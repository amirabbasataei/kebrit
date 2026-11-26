import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/game/grid.dart';
import 'package:kebrit/game/hunter_ai.dart';

import 'fixtures.dart';

void main() {
  final room = Grid.parse(roomMap);

  test('BFS tie-break: right is preferred over down', () {
    // (1,1) -> target (2,2): (2,1) and (1,2) are both distance 1.
    expect(
      HunterAi.nextStep(room, const Cell(1, 1), const Cell(2, 2)),
      const Cell(2, 1),
    );
  });

  test('BFS tie-break: left is preferred over down', () {
    // (3,1) -> target (2,2): right is a wall; (2,1) and (3,2) tie.
    expect(
      HunterAi.nextStep(room, const Cell(3, 1), const Cell(2, 2)),
      const Cell(2, 1),
    );
  });

  test('BFS tie-break: down is preferred over up', () {
    // The centre (2,2) is a wall, so (1,2) reaches (3,2) equally well via
    // row 1 or row 3 (4 steps each); down must win over up.
    final g = Grid.parse(['##E##', '#...#', '#.#.#', '#...#', '#####']);
    expect(
      HunterAi.nextStep(g, const Cell(1, 2), const Cell(3, 2)),
      const Cell(1, 3),
    );
  });

  test('unreachable target: hunter stays put', () {
    final g = Grid.parse(pocketsMap);
    expect(
      HunterAi.nextStep(g, const Cell(3, 1), const Cell(1, 1)),
      const Cell(3, 1),
    );
  });

  test('hunter already on the target stays put', () {
    expect(
      HunterAi.nextStep(room, const Cell(2, 2), const Cell(2, 2)),
      const Cell(2, 2),
    );
  });

  test('exit cell is blocked for BFS but not for stepsToExit', () {
    expect(
      HunterAi.distances(room, const Cell(2, 1)).containsKey(room.exit),
      isFalse,
    );
    expect(
      HunterAi.distances(room, const Cell(2, 1), allowExit: true)[room.exit],
      1,
    );
  });

  test('hunter never steps into the exit', () {
    // Corridor: the exit hangs above (2,1); a hunter chasing along the
    // corridor must stay on row 1.
    final g = Grid.parse(corridorMap);
    var h = const Cell(3, 1);
    h = HunterAi.nextStep(g, h, const Cell(1, 1));
    expect(h, const Cell(2, 1));
    expect(g.isExit(h.x, h.y), isFalse);
  });
}
