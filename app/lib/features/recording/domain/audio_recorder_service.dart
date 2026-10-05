/// Records from the microphone into a file.
///
/// The file stays readable while it grows, so a recording cut off by a
/// crash still holds everything up to that moment.
abstract interface class AudioRecorderService {
  /// The extension of the files it writes, without the dot, such as `aac`.
  String get fileExtension;

  /// About how many bytes one second of recording takes on disk.
  int get bytesPerSecond;

  /// Starts a new recording into [path], replacing any file there. Throws
  /// when the microphone can't be used, for example because another app
  /// has it.
  Future<void> start(String path);

  /// Pauses, and lets go of the microphone until [resume].
  Future<void> pause();

  /// Carries on after [pause], or after an interruption that didn't end by
  /// itself, adding to the same file.
  Future<void> resume();

  /// Stops and closes the file. Does nothing when not recording.
  Future<void> stop();

  /// How much audio the file holds so far. Grows while recording.
  Stream<Duration> get recordedLength;

  /// How loud the microphone is, in dBFS: 0 is the loudest, -160 is
  /// complete silence. About ten a second while recording.
  Stream<double> get levels;

  /// What happens without being asked: see [RecorderEvent].
  Stream<RecorderEvent> get events;

  /// Stops if needed and lets go of everything.
  Future<void> dispose();
}

/// Something that happened to a recording on its own.
enum RecorderEvent {
  /// The phone took the microphone away, for a call or another app. The
  /// recording is paused, and usually picks up again by itself.
  interrupted,

  /// Recording again after [interrupted].
  resumed,

  /// The phone is full, so nothing more can be saved. The recording has
  /// stopped, and the file keeps what was recorded.
  outOfSpace,

  /// The file couldn't be written for another reason. The recording has
  /// stopped, and the file keeps what was recorded.
  writeFailed,
}
