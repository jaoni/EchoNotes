/// Plays one recording.
abstract interface class AudioPlayback {
  /// Opens the recording at [path], ready to play from the start. Throws
  /// when it can't be played.
  Future<void> load(String path);

  /// Plays from where it is, or from the start once it has played to the
  /// end.
  Future<void> play();

  Future<void> pause();

  Future<void> seek(Duration position);

  /// Where playback is, as it moves.
  Stream<Duration> get positions;

  /// Whether it's playing: false while paused and after the end.
  Stream<bool> get playingChanges;

  /// Stops and lets go of everything.
  Future<void> dispose();
}
