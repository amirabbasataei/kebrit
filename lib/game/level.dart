import 'grid.dart';

/// Static description of one level.
class Level {
  const Level({
    required this.id,
    required this.name,
    required this.chapter,
    required this.startMatches,
    required this.grid,
    required this.playerStart,
    required this.hunterStarts,
    this.pickups = const [],
  });

  final int id;
  final String name;
  final String chapter;
  final int startMatches;
  final Grid grid;
  final Cell playerStart;
  final List<Cell> hunterStarts;

  /// Each pickup grants +2 matches, once.
  final List<Cell> pickups;
}
