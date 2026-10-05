import 'dart:io';
import 'dart:typed_data';

/// Writes a recording to its file as the audio arrives.
///
/// Each piece goes straight to the operating system, so it's kept even if
/// the app is killed a moment later. Every so often the file is also synced
/// to storage, in case the phone itself switches off.
class RecordingFileWriter {
  RecordingFileWriter._(this._file, this._onError);

  /// Pieces written between syncs to storage: about every four seconds.
  static const _writesPerSync = 64;

  /// Opens [path] for writing: added to when [append], otherwise emptied
  /// first. [onError] hears about the first write that fails; nothing more
  /// is written after it.
  static Future<RecordingFileWriter> open(
    String path, {
    required bool append,
    required void Function(Object error) onError,
  }) async {
    final file = await File(path)
        .open(mode: append ? FileMode.append : FileMode.write);
    return RecordingFileWriter._(file, onError);
  }

  final RandomAccessFile _file;
  final void Function(Object error) _onError;

  /// The writes still to finish, one after the other.
  var _queue = Future<void>.value();
  var _writesSinceSync = 0;
  var _failed = false;
  var _closed = false;

  /// Adds [bytes] to the end of the file.
  void write(Uint8List bytes) {
    if (_failed || _closed || bytes.isEmpty) return;
    final sync = ++_writesSinceSync >= _writesPerSync;
    if (sync) _writesSinceSync = 0;

    _queue = _queue.then((_) async {
      if (_failed) return;
      try {
        await _file.writeFrom(bytes);
        if (sync) await _file.flush();
      } catch (error) {
        _failed = true;
        _onError(error);
      }
    });
  }

  /// Finishes every write, syncs and closes the file. Safe to call twice.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _queue;
    try {
      if (!_failed) await _file.flush();
    } finally {
      await _file.close();
    }
  }
}
