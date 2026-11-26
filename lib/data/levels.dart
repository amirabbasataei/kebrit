import '../game/grid.dart';
import '../game/hunter_ai.dart';
import '../game/level.dart';

/// Chapter names (index = `(levelId - 1) ~/ 5`), from MLevels.
class Chapter {
  const Chapter(this.label, this.name);
  final String label;
  final String name;
}

const chapters = [
  Chapter('فصل اول', 'خانه‌ی کهنه'),
  Chapter('فصل دوم', 'سرداب‌ها'),
  Chapter('فصل سوم', 'دخمه‌ها'),
];

const levelsPerChapter = 5;

int chapterIndexOf(int levelId) => (levelId - 1) ~/ levelsPerChapter;

/// The real level-7 maze from `MGame.dc.html`.
const level7Rows = [
  '####E####',
  '#.......#',
  '#.#.#.#.#',
  '#.#...#.#',
  '#.###.#.#',
  '#...#...#',
  '###.#.###',
  '#...#...#',
  '#.###.#.#',
  '#.#...#.#',
  '#.#.###.#',
  '#.......#',
  '#########',
];

// (id, Persian name, starting matches, hunters) — MLevels table.
const _table = <(int, String, int, int)>[
  (1, 'نخستین نور', 12, 0),
  (2, 'راه‌های باریک', 11, 0),
  (3, 'اجاق سرد', 10, 0),
  (4, 'تاریکی بلند', 9, 0),
  (5, 'انبار ریشه', 8, 0),
  (6, 'نگهبانان خاموش', 7, 1),
  (7, 'سرداب زیرین', 6, 2),
  (8, 'استخوان‌دان', 5, 3),
  (9, 'تالار استخوان', 5, 3),
  (10, 'سرای نگهبانان', 4, 3),
  (11, 'پله‌های غرقه', 4, 4),
  (12, 'گورهای فانوس', 4, 4),
  (13, 'همسرایان تهی', 3, 4),
  (14, 'دالان‌های خاکستر', 3, 5),
  (15, 'آخرین در', 2, 5),
];

/// The 15-level catalogue. Only level 7 has its real maze; every other level
/// uses a generated PLACEHOLDER maze (open question Q3).
class Levels {
  const Levels._();

  static const count = 15;

  static final List<Level> all = List.unmodifiable([
    for (final (id, name, matches, hunters) in _table)
      id == 7
          ? Level(
              id: 7,
              name: name,
              chapter: chapters[chapterIndexOf(7)].name,
              startMatches: matches,
              grid: Grid.parse(level7Rows),
              playerStart: const Cell(1, 11),
              hunterStarts: const [Cell(7, 4), Cell(3, 9)],
              pickups: const [Cell(1, 7)],
            )
          : _placeholder(id, name, matches, hunters),
  ]);

  /// Levels whose maze is a generated placeholder.
  static final Set<int> placeholderIds = {
    for (final l in all)
      if (l.id != 7) l.id
  };

  /// 1-based. Throws [RangeError] outside 1..15.
  static Level byId(int id) {
    RangeError.checkValueInInterval(id, 1, count, 'id');
    return all[id - 1];
  }
}

// ---------------------------------------------------------------------------
// PLACEHOLDER generator: deterministic 9×13 mazes (recursive backtracker on
// the odd-cell lattice, row 1 opened like level 7, exit at (4,0)).

class _Lcg {
  _Lcg(this._s);
  int _s;
  int next(int n) {
    _s = (_s * 1103515245 + 12345) & 0x7fffffff;
    return (_s >> 8) % n;
  }
}

Level _placeholder(int id, String name, int matches, int hunters) {
  final rng = _Lcg(id * 7919 + 13);
  const cols = 9, rows = 13;
  final g = [for (var y = 0; y < rows; y++) List.filled(cols, '#')];
  final seen = <Cell>{};
  final stack = <Cell>[const Cell(1, 11)];
  g[11][1] = '.';
  seen.add(const Cell(1, 11));
  const dirs = [Cell(2, 0), Cell(-2, 0), Cell(0, 2), Cell(0, -2)];
  while (stack.isNotEmpty) {
    final c = stack.last;
    final open = [
      for (final d in dirs)
        if ((c + d).x > 0 &&
            (c + d).x < cols - 1 &&
            (c + d).y > 0 &&
            (c + d).y < rows - 1 &&
            !seen.contains(c + d))
          d
    ];
    if (open.isEmpty) {
      stack.removeLast();
      continue;
    }
    final d = open[rng.next(open.length)];
    final n = c + d;
    g[c.y + d.y ~/ 2][c.x + d.x ~/ 2] = '.';
    g[n.y][n.x] = '.';
    seen.add(n);
    stack.add(n);
  }
  for (var x = 1; x < cols - 1; x++) {
    g[1][x] = '.';
  }
  g[0][4] = 'E';
  final grid = Grid.parse([for (final r in g) r.join()]);

  const start = Cell(1, 11);
  final dist = HunterAi.distances(grid, start);
  final hunterCells = <Cell>[];
  for (var minDist = 8; hunterCells.length < hunters && minDist >= 1; minDist--) {
    final pool = [
      for (var y = 0; y < rows; y++)
        for (var x = 0; x < cols; x++)
          if ((dist[Cell(x, y)] ?? 0) >= minDist &&
              !hunterCells.contains(Cell(x, y)))
            Cell(x, y)
    ];
    while (hunterCells.length < hunters && pool.isNotEmpty) {
      hunterCells.add(pool.removeAt(rng.next(pool.length)));
    }
  }

  return Level(
    id: id,
    name: name,
    chapter: chapters[chapterIndexOf(id)].name,
    startMatches: matches,
    grid: grid,
    playerStart: start,
    hunterStarts: hunterCells,
  );
}
