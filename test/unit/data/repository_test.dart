import 'package:flutter_test/flutter_test.dart';
import 'package:kebrit/data/progress.dart';
import 'package:kebrit/data/progress_repository.dart';
import 'package:kebrit/data/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<PrefsProgressRepository> prefsRepo([Map<String, Object> init = const {}]) async {
  SharedPreferences.setMockInitialValues(init);
  return PrefsProgressRepository(await SharedPreferences.getInstance());
}

void main() {
  test('fresh install: level 1 unlocked, default settings (prefs)', () async {
    final r = await prefsRepo();
    final p = await r.loadProgress();
    expect(p.currentLevel, 1);
    expect(p.isUnlocked(1), isTrue);
    expect(await r.loadSettings(), const AppSettings());
  });

  test('round-trip save/load through SharedPreferences', () async {
    final r = await prefsRepo();
    final p = Progress().complete(1, 3).complete(2, 1);
    final s = const AppSettings(sound: false, reduceFlicker: true);
    await r.saveProgress(p);
    await r.saveSettings(s);
    // A new repository over the same prefs store sees the same data.
    final r2 = PrefsProgressRepository(await SharedPreferences.getInstance());
    expect(await r2.loadProgress(), p);
    expect(await r2.loadSettings(), s);
  });

  test('corrupt stored JSON falls back to defaults', () async {
    final r = await prefsRepo({
      PrefsProgressRepository.progressKey: '{not json',
      PrefsProgressRepository.settingsKey: '[1,2]',
    });
    expect((await r.loadProgress()).currentLevel, 1);
    expect(await r.loadSettings(), const AppSettings());
  });

  test('in-memory fake round-trips', () async {
    final r = InMemoryProgressRepository();
    expect((await r.loadProgress()).currentLevel, 1);
    final p = Progress().complete(1, 2);
    await r.saveProgress(p);
    await r.saveSettings(const AppSettings(haptics: false));
    expect(await r.loadProgress(), p);
    expect((await r.loadSettings()).haptics, isFalse);
  });
}
