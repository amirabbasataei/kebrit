import 'package:flutter/widgets.dart';

import 'data/progress.dart';
import 'data/progress_repository.dart';
import 'data/settings.dart';
import 'services/haptics.dart';
import 'services/sound.dart';
import 'ui/screens/game/game_controller.dart';

/// Live app state: progress, settings and the first-launch flag, persisted
/// through a [ProgressRepository] on every change.
class AppController extends ChangeNotifier {
  AppController(
    this.repository, {
    Progress? progress,
    AppSettings? settings,
    this._introSeen = false,
  })  : _progress = progress ?? Progress(),
        _settings = settings ?? const AppSettings();

  static Future<AppController> load(ProgressRepository repository) async {
    return AppController(
      repository,
      progress: await repository.loadProgress(),
      settings: await repository.loadSettings(),
      introSeen: await repository.loadIntroSeen(),
    );
  }

  final ProgressRepository repository;
  Progress _progress;
  AppSettings _settings;
  bool _introSeen;

  Progress get progress => _progress;
  AppSettings get settings => _settings;
  bool get introSeen => _introSeen;

  void updateSettings(AppSettings s) {
    if (s == _settings) return;
    _settings = s;
    notifyListeners();
    repository.saveSettings(s);
  }

  void completeLevel(int level, int embers) {
    _progress = _progress.complete(level, embers);
    notifyListeners();
    repository.saveProgress(_progress);
  }

  void markIntroSeen() {
    if (_introSeen) return;
    _introSeen = true;
    repository.saveIntroSeen(true);
  }
}

/// Service lookup for the screens' route builders.
class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    this.haptics = const NoopHaptics(),
    this.sound = const SilentSoundPlayer(),
    this.timerFactory,
    required super.child,
  }) : super(notifier: controller);

  final Haptics haptics;
  final SoundPlayer sound;

  /// Test hook for the game's tick/repeat timers.
  final PeriodicTimerFactory? timerFactory;

  static AppScope of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(s != null, 'No AppScope above this context');
    return s!;
  }

  AppController get app => notifier!;
}