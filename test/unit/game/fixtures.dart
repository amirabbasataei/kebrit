import 'package:kebrit/game/grid.dart';
import 'package:kebrit/game/level.dart';

/// Level-7 map from `MGame.dc.html` (PLAN.md §0.2).
const level7Map = [
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

Level level7() => Level(
      id: 7,
      name: 'سرداب زیرین',
      chapter: 'سرداب‌ها',
      startMatches: 6,
      grid: Grid.parse(level7Map),
      playerStart: const Cell(1, 11),
      hunterStarts: const [Cell(7, 4), Cell(3, 9)],
      pickups: const [Cell(1, 7)],
    );

/// A one-row corridor with the exit above its middle cell (2,1):
///
///     ##E##
///     #...#
///     #####
const corridorMap = ['##E##', '#...#', '#####'];

Level corridor({
  Cell player = const Cell(1, 1),
  List<Cell> hunters = const [],
  int matches = 3,
  List<Cell> pickups = const [],
}) =>
    Level(
      id: 0,
      name: 'test',
      chapter: 'test',
      startMatches: matches,
      grid: Grid.parse(corridorMap),
      playerStart: player,
      hunterStarts: hunters,
      pickups: pickups,
    );

/// 3×3 room under the exit at (2,0).
const roomMap = ['##E##', '#...#', '#...#', '#...#', '#####'];

/// Two sealed pockets, so (1,*) and (3,*) cannot reach each other.
const pocketsMap = ['##E##', '#.#.#', '#.#.#', '#####'];
