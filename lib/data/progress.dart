import 'levels.dart';

enum LevelStatus { done, current, locked }

/// ASSUMED ember rule (open question Q4), isolated here so it is a one-place
/// change. Fewer strikes = more embers; finishing always earns at least 1.
///
/// 3 embers: struck <= ceil(start/3); 2 embers: struck <= ceil(2*start/3);
/// otherwise 1. (Consistent with the design: "3 of 6 matches left" gives
/// 2 embers, and the hint "keep more matches to get them all".)
int emberRule({required int startMatches, required int matchesStruck}) {
  final three = (startMatches + 2) ~/ 3;
  final two = (2 * startMatches + 2) ~/ 3;
  if (matchesStruck <= three) return 3;
  if (matchesStruck <= two) return 2;
  return 1;
}

/// Immutable player progress. Level 1 is unlocked on a fresh install.
class Progress {
  Progress({this.currentLevel = 1, Map<int, int> embers = const {}})
      : embers = Map.unmodifiable(embers);

  /// The "continue" pointer: the furthest unlocked level (1..15).
  final int currentLevel;

  /// Best embers (1..3) per finished level.
  final Map<int, int> embers;

  bool isUnlocked(int n) => n >= 1 && n <= Levels.count && n <= currentLevel;

  bool isDone(int n) => embers.containsKey(n);

  int bestEmbers(int n) => embers[n] ?? 0;

  int get completedCount => embers.length;
  int get totalEmbers => embers.values.fold(0, (a, b) => a + b);

  /// done / current / locked as drawn on Level select. The current level is
  /// "done" only once it has been finished (e.g. level 15 at the end).
  LevelStatus statusOf(int n) {
    if (n < currentLevel) return LevelStatus.done;
    if (n == currentLevel) {
      return isDone(n) ? LevelStatus.done : LevelStatus.current;
    }
    return LevelStatus.locked;
  }

  /// Record finishing level [n] with [earned] embers (clamped to 1..3). Keeps
  /// the best score and only ever advances [currentLevel]. Locked or unknown
  /// levels are ignored.
  Progress complete(int n, int earned) {
    if (!isUnlocked(n)) return this;
    final e = earned.clamp(1, 3);
    final best = e > bestEmbers(n) ? e : bestEmbers(n);
    final next = (n == currentLevel && n < Levels.count) ? n + 1 : currentLevel;
    return Progress(currentLevel: next, embers: {...embers, n: best});
  }

  Map<String, Object> toJson() => {
        'currentLevel': currentLevel,
        'embers': {for (final e in embers.entries) '${e.key}': e.value},
      };

  /// Tolerant: bad values are dropped or clamped.
  factory Progress.fromJson(Map<String, Object?> j) {
    final cur = j['currentLevel'];
    final raw = j['embers'];
    final embers = <int, int>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        final n = int.tryParse('$k');
        if (n != null && n >= 1 && n <= Levels.count && v is int) {
          embers[n] = v.clamp(1, 3);
        }
      });
    }
    var current = cur is int ? cur.clamp(1, Levels.count) : 1;
    // Finished levels imply their successors are unlocked.
    for (final n in embers.keys) {
      final unlocked = n < Levels.count ? n + 1 : n;
      if (unlocked > current) current = unlocked;
    }
    return Progress(currentLevel: current, embers: embers);
  }

  @override
  bool operator ==(Object other) =>
      other is Progress &&
      other.currentLevel == currentLevel &&
      other.embers.length == embers.length &&
      other.embers.entries.every((e) => embers[e.key] == e.value);

  @override
  int get hashCode => Object.hash(currentLevel, embers.length);
}
