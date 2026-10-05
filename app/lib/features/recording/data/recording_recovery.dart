import 'dart:developer' as developer;

import 'package:echonotes/features/notes/domain/audio_file_store.dart';
import 'package:echonotes/features/notes/domain/notes_repository.dart';
import 'package:echonotes/features/recording/domain/recording_preferences.dart';

/// Saves recordings that were cut off because the app closed while they
/// ran: it crashed, was killed, or the phone switched off.
///
/// Each note still marked as recording gets its file repaired and measured.
/// With any audio in it, it goes on to be uploaded like any finished
/// recording. Without any, there's nothing to keep, so it's deleted.
class RecordingRecovery {
  /// [repairFile] makes a cut-off file safe to use and says how much audio
  /// it holds (see `repairAdtsFile`).
  RecordingRecovery(
    this._notes,
    this._audioFiles,
    this._preferences, {
    required this._repairFile,
  });

  final NotesRepository _notes;
  final AudioFileStore _audioFiles;
  final RecordingPreferences _preferences;
  final Future<Duration> Function(String path) _repairFile;

  /// Recovers every cut-off recording, and says what it found.
  ///
  /// Must finish before a new recording starts, so it never touches one
  /// that is still running.
  Future<RecoveredRecordings> recover() async {
    final inBackground = await _readAndForgetBackgroundNote();
    var kept = 0;
    var keptFromBackground = false;
    for (final note in await _notes.unfinishedRecordings()) {
      try {
        final fileName = note.audioFileName;
        final length = fileName == null
            ? Duration.zero
            : await _repairFile(await _audioFiles.pathOf(fileName));
        if (length > Duration.zero) {
          await _notes.finishRecording(note.id, length);
          kept++;
          if (note.id == inBackground) keptFromBackground = true;
        } else {
          await _notes.deleteNote(note.id);
        }
      } catch (error, stackTrace) {
        // Left as it is, to try again on the next launch.
        _log("Couldn't recover the recording ${note.id}", error, stackTrace);
      }
    }
    return RecoveredRecordings(
      kept: kept,
      cutOffInBackground: keptFromBackground,
    );
  }

  /// Which note was recording when the app last left the screen. Read only
  /// once: after this launch, it no longer means anything.
  Future<String?> _readAndForgetBackgroundNote() async {
    try {
      final noteId = await _preferences.noteRecordingInBackground();
      if (noteId != null) await _preferences.setNoteRecordingInBackground(null);
      return noteId;
    } catch (error, stackTrace) {
      _log(
        "Couldn't check for a recording in the background",
        error,
        stackTrace,
      );
      return null;
    }
  }

  void _log(String message, Object error, StackTrace stackTrace) {
    developer.log(
      message,
      name: 'echonotes.recording',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// What recovery found.
class RecoveredRecordings {
  const RecoveredRecordings({this.kept = 0, this.cutOffInBackground = false});

  /// How many cut-off recordings were saved.
  final int kept;

  /// One of them was cut off while the app was in the background: most
  /// likely the phone stopped it to save battery.
  final bool cutOffInBackground;
}
