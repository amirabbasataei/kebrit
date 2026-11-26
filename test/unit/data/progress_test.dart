import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/data/progress.dart';
import 'package:kebrit/data/settings.dart';

void main() {
  group('Progress', () {
    test('level 1 unlocked on fresh install, level 2 locked', () {
      final p = Progress();
      expect(p.currentLevel, 1);
      expect(p.isUnlocked(1), isTrue);
      expect(p.isUnlocked(2), isFalse);
      expect(p.statusOf(1), LevelStatus.current);
      expect(p.statusOf(2), LevelStatus.locked);
    });

    test('isUnlocked rejects out-of-range ids', () {
      final p = Progress(currentLevel: 15);
      expect(p.isUnlocked(0), isFalse);
      expect(p.isUnlocked(16), isFalse);
      expect(p.isUnlocked(15), isTrue);
    });

    test('complete advances current and records embers', () {
      final p = Progress().complete(1, 3);
      expect(p.currentLevel, 2);
      expect(p.bestEmbers(1), 3);
      expect(p.isUnlocked(2), isTrue);
      expect(p.statusOf(1), LevelStatus.done);
      expect(p.statusOf(2), LevelStatus.current);
    });

    test('replaying keeps the best embers and does not move current', () {
      var p = Progress(currentLevel: 7, embers: {for (var i = 1; i < 7; i++) i: 2});
      p = p.complete(3, 3);
      expect(p.bestEmbers(3), 3);
      expect(p.currentLevel, 7);
      p = p.complete(3, 1);
      expect(p.bestEmbers(3), 3);
    });

    test('completing a locked level is ignored', () {
      final p = Progress().complete(5, 3);
      expect(p.currentLevel, 1);
      expect(p.embers, isEmpty);
    });

    test('embers are clamped to 1..3', () {
      expect(Progress().complete(1, 9).bestEmbers(1), 3);
      expect(Progress().complete(1, 0).bestEmbers(1), 1);
    });

    test('level 15 finishes in place and counts as done', () {
      final p = Progress(currentLevel: 15).complete(15, 2);
      expect(p.currentLevel, 15);
      expect(p.statusOf(15), LevelStatus.done);
    });

    test('design mock: levels 1-6 done with 3,3,2,3,2,1 embers → 6 rooms, 14 embers', () {
      var p = Progress();
      const e = [3, 3, 2, 3, 2, 1];
      for (var i = 0; i < 6; i++) {
        p = p.complete(i + 1, e[i]);
      }
      expect(p.currentLevel, 7);
      expect(p.completedCount, 6);
      expect(p.totalEmbers, 14);
    });

    test('JSON round trip', () {
      final p = Progress().complete(1, 3).complete(2, 2);
      expect(Progress.fromJson(p.toJson()), p);
    });

    test('fromJson tolerates garbage and repairs current', () {
      final p = Progress.fromJson({
        'currentLevel': 'x',
        'embers': {'3': 2, 'z': 1, '99': 3, '4': 'no', '5': 7},
      });
      expect(p.embers, {3: 2, 5: 3});
      expect(p.currentLevel, 6);
    });
  });

  group('emberRule (assumed, Q4)', () {
    int r(int start, int struck) =>
        emberRule(startMatches: start, matchesStruck: struck);

    test('level 7: 6 matches', () {
      expect(r(6, 1), 3);
      expect(r(6, 2), 3);
      expect(r(6, 3), 2); // design mock: 3 of 6 left → 2 embers
      expect(r(6, 4), 2);
      expect(r(6, 5), 1);
      expect(r(6, 6), 1);
    });

    test('small and zero-strike cases', () {
      expect(r(2, 0), 3);
      expect(r(2, 1), 3); // ⌈2/3⌉ = 1
      expect(r(2, 2), 2); // ⌈4/3⌉ = 2 (level 15 can't score 1 without strikes > start)
      expect(r(12, 4), 3);
      expect(r(12, 8), 2);
      expect(r(12, 9), 1);
    });
  });

  group('AppSettings', () {
    test('defaults: sound and haptics on, others off', () {
      const s = AppSettings();
      expect(s.sound, isTrue);
      expect(s.haptics, isTrue);
      expect(s.reduceFlicker, isFalse);
      expect(s.leftHanded, isFalse);
    });

    test('copyWith and JSON round trip', () {
      final s = const AppSettings().copyWith(sound: false, leftHanded: true);
      expect(s.sound, isFalse);
      expect(s.haptics, isTrue);
      expect(AppSettings.fromJson(s.toJson()), s);
    });

    test('fromJson falls back to defaults on bad types', () {
      expect(AppSettings.fromJson({'sound': 1, 'leftHanded': 'yes'}),
          const AppSettings());
    });
  });
}
