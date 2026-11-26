/// The four toggles on the Pause screen (design keys: sound, haptics,
/// flicker, lefty).
class AppSettings {
  const AppSettings({
    this.sound = true,
    this.haptics = true,
    this.reduceFlicker = false,
    this.leftHanded = false,
  });

  final bool sound;
  final bool haptics;
  final bool reduceFlicker;
  final bool leftHanded;

  AppSettings copyWith({
    bool? sound,
    bool? haptics,
    bool? reduceFlicker,
    bool? leftHanded,
  }) => AppSettings(
    sound: sound ?? this.sound,
    haptics: haptics ?? this.haptics,
    reduceFlicker: reduceFlicker ?? this.reduceFlicker,
    leftHanded: leftHanded ?? this.leftHanded,
  );

  Map<String, Object> toJson() => {
    'sound': sound,
    'haptics': haptics,
    'reduceFlicker': reduceFlicker,
    'leftHanded': leftHanded,
  };

  /// Missing or wrongly-typed keys fall back to the defaults.
  factory AppSettings.fromJson(Map<String, Object?> j) {
    bool b(String k, bool d) => j[k] is bool ? j[k] as bool : d;
    const d = AppSettings();
    return AppSettings(
      sound: b('sound', d.sound),
      haptics: b('haptics', d.haptics),
      reduceFlicker: b('reduceFlicker', d.reduceFlicker),
      leftHanded: b('leftHanded', d.leftHanded),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.sound == sound &&
      other.haptics == haptics &&
      other.reduceFlicker == reduceFlicker &&
      other.leftHanded == leftHanded;

  @override
  int get hashCode => Object.hash(sound, haptics, reduceFlicker, leftHanded);
}
