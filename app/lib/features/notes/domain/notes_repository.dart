import 'package:echonotes/features/notes/domain/note.dart';
import 'package:echonotes/features/notes/domain/note_status.dart';

/// Where the app keeps its notes. Screens only ever talk to this interface.
///
/// Reads are live: each stream gives the current value straight away, then
/// again after every change, so screens stay up to date on their own.
abstract interface class NotesRepository {
  /// Every note, newest first, with what a list shows: title, summary,
  /// status and tags.
  ///
  /// Key points, action items and the transcript may be left out, so the
  /// list never loads every transcript. [watchNote] gives the whole note.
  Stream<List<Note>> watchNotes();

  /// One whole note, or null when there is no note with this [id].
  Stream<Note?> watchNote(String id);

  /// Makes the note for a recording that starts now, before any audio is
  /// recorded, so the recording is never lost: a note left recording when
  /// the app closed is found by [unfinishedRecordings] on the next launch.
  ///
  /// The audio file is named after the note, `<id>.<audioFileExtension>`.
  Future<Note> startRecording({
    required DateTime recordedAt,
    required String audioFileExtension,
  });

  /// Marks a recording as done, [duration] long, so it waits to be uploaded
  /// and processing picks it up. Does nothing to a note that isn't
  /// recording, or is gone.
  Future<void> finishRecording(String noteId, Duration duration);

  /// Every note still marked as recording.
  Future<List<Note>> unfinishedRecordings();

  /// Ticks an action item off, or back on.
  Future<void> setActionItemDone({
    required String noteId,
    required String actionItemId,
    required bool isDone,
  });

  /// Puts a failed note back in line for processing. Does nothing to a note
  /// that hasn't failed.
  Future<void> retryProcessing(String noteId);

  /// Moves a note on to [status]. Does nothing if the note is gone.
  Future<void> setStatus(String noteId, NoteStatus status);

  /// Saves the notes written for [note], all at once: its status, title,
  /// summary, key points, action items, tags and transcript. They replace
  /// whatever was there. The recording's own facts (when, how long, its
  /// audio) stay as they were.
  ///
  /// Does nothing if the note is gone, so a note deleted while it was being
  /// processed stays deleted.
  Future<void> saveNote(Note note);

  /// Deletes a note, all its parts and its recording. Does nothing if the
  /// note is already gone.
  Future<void> deleteNote(String id);
}
