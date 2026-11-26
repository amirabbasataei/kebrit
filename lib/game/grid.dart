/// A board cell coordinate (column [x], row [y]).
class Cell {
  const Cell(this.x, this.y);

  final int x;
  final int y;

  Cell operator +(Cell o) => Cell(x + o.x, y + o.y);

  @override
  bool operator ==(Object other) =>
      other is Cell && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x,$y)';
}

/// The four movement directions.
enum Dir {
  up(0, -1),
  down(0, 1),
  left(-1, 0),
  right(1, 0);

  const Dir(this.dx, this.dy);
  final int dx;
  final int dy;
}

enum CellType { wall, floor, exit }

/// Immutable maze. `#` wall, `.` floor, `E` exit.
class Grid {
  Grid._(this._cells, this.cols, this.rows, this.exit);

  /// Parses rows of `#`, `.`, `E`. Throws [FormatException] on ragged rows,
  /// unknown characters, or when there is not exactly one exit.
  factory Grid.parse(List<String> rows) {
    if (rows.isEmpty) throw const FormatException('empty grid');
    final cols = rows.first.length;
    final cells = <List<CellType>>[];
    Cell? exit;
    for (var y = 0; y < rows.length; y++) {
      final r = rows[y];
      if (r.length != cols) {
        throw FormatException('row $y has ${r.length} columns, expected $cols');
      }
      final line = <CellType>[];
      for (var x = 0; x < cols; x++) {
        switch (r[x]) {
          case '#':
            line.add(CellType.wall);
          case '.':
            line.add(CellType.floor);
          case 'E':
            if (exit != null) throw const FormatException('multiple exits');
            exit = Cell(x, y);
            line.add(CellType.exit);
          default:
            throw FormatException("unknown cell '${r[x]}' at ($x,$y)");
        }
      }
      cells.add(List.unmodifiable(line));
    }
    if (exit == null) throw const FormatException('no exit');
    return Grid._(List.unmodifiable(cells), cols, rows.length, exit);
  }

  final List<List<CellType>> _cells;
  final int cols;
  final int rows;
  final Cell exit;

  bool inBounds(int x, int y) => x >= 0 && y >= 0 && x < cols && y < rows;

  /// Out-of-bounds counts as wall.
  bool isWall(int x, int y) => !inBounds(x, y) || _cells[y][x] == CellType.wall;

  bool isExit(int x, int y) => inBounds(x, y) && _cells[y][x] == CellType.exit;

  CellType typeAt(int x, int y) => !inBounds(x, y) ? CellType.wall : _cells[y][x];
}
