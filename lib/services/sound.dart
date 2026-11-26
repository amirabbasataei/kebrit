/// Sound cues the game could play. Phase 11 ships only a silent player: there
/// are no audio assets or package decision yet (PLAN Q9).
enum SoundCue { strike, step, hunterBreath, door, caught }

abstract class SoundPlayer {
  const SoundPlayer();

  void play(SoundCue cue);
}

class SilentSoundPlayer extends SoundPlayer {
  const SilentSoundPlayer();

  @override
  void play(SoundCue cue) {}
}
