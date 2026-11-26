import 'dart:collection';

import 'grid.dart';

/// Neighbour order of the JS: right, left, down, up. Ties are broken by it.
const List<Cell> _order = [Cell(1, 0), Cell(-1, 0), Cell(0, 1), Cell(0, -1)];

class HunterAi {
  const HunterAi._();

  /// BFS distances from [from] over floor cells. The exit cell is blocked
  /// (hunters never enter it) unless [allowExit].
  static Map<Cell, int> distances(Grid grid, Cell from,
      {bool allowExit = false}) {
    final dist = <Cell, int>{from: 0};
    final q = Queue<Cell>()..add(from);
    while (q.isNotEmpty) {
      final c = q.removeFirst();
      final d = dist[c]!;
      for (final o in _order) {
        final n = c + o;
        if (grid.isWall(n.x, n.y)) continue;
        if (!allowExit && grid.isExit(n.x, n.y)) continue;
        if (dist.containsKey(n)) continue;
        dist[n] = d + 1;
        q.add(n);
      }
    }
    return dist;
  }

  /// One step for a hunter at [from] toward [target]. The first neighbour (in
  /// JS order) whose BFS distance is one less wins. Returns [from] when the
  /// target is unreachable or already reached.
  static Cell nextStep(Grid grid, Cell from, Cell target,
      {Map<Cell, int>? distFromTarget}) {
    final dist = distFromTarget ?? distances(grid, target);
    final d = dist[from];
    if (d == null || d == 0) return from;
    for (final o in _order) {
      final n = from + o;
      if (dist[n] == d - 1) return n;
    }
    return from;
  }
}

/// Fewest steps from [from] to the exit cell (the exit step included), or
/// null if the exit is unreachable. For the Complete screen.
int? stepsToExit(Grid grid, Cell from) =>
    HunterAi.distances(grid, from, allowExit: true)[grid.exit];
