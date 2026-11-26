import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'progress.dart';
import 'settings.dart';

/// Persistence boundary for progress and settings.
abstract class ProgressRepository {
  Future<Progress> loadProgress();
  Future<void> saveProgress(Progress progress);
  Future<AppSettings> loadSettings();
  Future<void> saveSettings(AppSettings settings);

  /// First-launch rule: the Benefits page is shown until this is set.
  Future<bool> loadIntroSeen();
  Future<void> saveIntroSeen(bool seen);
}

/// Test/preview fake.
class InMemoryProgressRepository implements ProgressRepository {
  InMemoryProgressRepository({Progress? progress, AppSettings? settings})
    : _progress = progress ?? Progress(),
      _settings = settings ?? const AppSettings();

  Progress _progress;
  AppSettings _settings;
  bool _introSeen = false;

  @override
  Future<Progress> loadProgress() async => _progress;
  @override
  Future<void> saveProgress(Progress progress) async => _progress = progress;
  @override
  Future<AppSettings> loadSettings() async => _settings;
  @override
  Future<void> saveSettings(AppSettings settings) async => _settings = settings;
  @override
  Future<bool> loadIntroSeen() async => _introSeen;
  @override
  Future<void> saveIntroSeen(bool seen) async => _introSeen = seen;
}

/// `shared_preferences` implementation: one JSON string per object. Corrupt
/// or missing data yields defaults.
class PrefsProgressRepository implements ProgressRepository {
  PrefsProgressRepository(this._prefs);

  static const progressKey = 'kebrit.progress.v1';
  static const settingsKey = 'kebrit.settings.v1';
  static const introKey = 'kebrit.intro.v1';

  final SharedPreferences _prefs;

  static Future<PrefsProgressRepository> open() async =>
      PrefsProgressRepository(await SharedPreferences.getInstance());

  Map<String, Object?>? _read(String key) {
    final s = _prefs.getString(key);
    if (s == null) return null;
    try {
      final v = jsonDecode(s);
      return v is Map<String, Object?> ? v : null;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<Progress> loadProgress() async {
    final j = _read(progressKey);
    return j == null ? Progress() : Progress.fromJson(j);
  }

  @override
  Future<void> saveProgress(Progress progress) async {
    await _prefs.setString(progressKey, jsonEncode(progress.toJson()));
  }

  @override
  Future<AppSettings> loadSettings() async {
    final j = _read(settingsKey);
    return j == null ? const AppSettings() : AppSettings.fromJson(j);
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setString(settingsKey, jsonEncode(settings.toJson()));
  }

  @override
  Future<bool> loadIntroSeen() async => _prefs.getBool(introKey) ?? false;

  @override
  Future<void> saveIntroSeen(bool seen) async {
    await _prefs.setBool(introKey, seen);
  }
}
