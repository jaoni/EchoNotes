/// Where recordings are kept on the phone.
///
/// Notes store only a recording's file name. The folder it's in can move (on
/// iOS its path changes with app updates), so the full path is worked out
/// each time it's needed.
abstract interface class AudioFileStore {
  /// The full path of the recording called [fileName], as of now.
  Future<String> pathOf(String fileName);

  /// Like [pathOf], for a recording about to be made: also creates the
  /// folder it goes in.
  Future<String> pathForNewRecording(String fileName);

  /// Deletes the recording called [fileName]. Does nothing if it's already
  /// gone.
  Future<void> delete(String fileName);
}
