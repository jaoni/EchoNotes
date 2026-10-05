import 'dart:developer' as developer;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:echonotes/core/database/app_database.dart';
import 'package:echonotes/features/notes/data/note_rows.dart';
import 'package:echonotes/features/notes/domain/audio_file_store.dart';
import 'package:echonotes/features/notes/domain/note.dart';
import 'package:echonotes/features/notes/domain/note_status.dart';
import 'package:echonotes/features/notes/domain/notes_repository.dart';

/// Keeps notes in the app's SQLite database.
///
/// Drift runs a watched query again whenever a table it reads changes,
/// which keeps the streams live. A note and its parts are always written in
/// one transaction, so a half-saved note is never seen or kept.
class DriftNotesRepository implements NotesRepository {
  DriftNotesRepository(this._db, {required this._audioFiles});

  /// Time-ordered UUIDs (version 7): unique across phones and the server,
  /// and they keep indexes tidy.
  static const _uuid = Uuid();

  final AppDatabase _db;
  final AudioFileStore _audioFiles;

  @override
  Stream<List<Note>> watchNotes() {
    final notes = _db.notes;
    final tags = _db.noteTags;
    final query = _db.select(notes).join([
      leftOuterJoin(tags, tags.noteId.equalsExp(notes.id)),
    ]);
    query.orderBy([
      OrderingTerm.desc(notes.createdAt),
      // Keeps recordings that started in the same millisecond in one order.
      OrderingTerm.desc(notes.id),
      OrderingTerm.asc(tags.position),
    ]);

    return query.watch().map((rows) {
      // One row per tag, so gather the tags back under their note.
      final noteRows = <NoteRow>[];
      final tagsByNote = <String, List<NoteTagRow>>{};
      for (final row in rows) {
        final note = row.readTable(notes);
        final noteTags = tagsByNote.putIfAbsent(note.id, () {
          noteRows.add(note);
          return [];
        });
        if (row.readTableOrNull(tags) case final tag?) noteTags.add(tag);
      }
      return List.unmodifiable([
        for (final note in noteRows)
          noteFromRows(note, tags: tagsByNote[note.id]!),
      ]);
    });
  }

  @override
  Stream<Note?> watchNote(String id) {
    // Every change to a note's parts also changes its row (updatedAt), so
    // the row alone says when to read the whole note again.
    return (_db.select(_db.notes)..where((note) => note.id.equals(id)))
        .watchSingleOrNull()
        .asyncMap((_) => _readNote(id));
  }

  @override
  Future<Note> startRecording({
    required DateTime recordedAt,
    required String audioFileExtension,
  }) async {
    final id = _newId();
    final note = Note(
      id: id,
      recordedAt: recordedAt,
      duration: Duration.zero,
      status: NoteStatus.recording,
      audioFileName: '$id.$audioFileExtension',
    );
    await _insertNote(id, note);
    return note;
  }

  @override
  Future<void> finishRecording(String noteId, Duration duration) async {
    final query = _db.update(_db.notes)
      ..where(
        (note) =>
            note.id.equals(noteId) &
            note.status.equals(noteStatusCode(NoteStatus.recording)),
      );
    await query.write(
      NotesCompanion(
        status: Value(noteStatusCode(NoteStatus.uploading)),
        durationMs: Value(duration.inMilliseconds),
        updatedAt: Value(_now()),
      ),
    );
  }

  @override
  Future<List<Note>> unfinishedRecordings() async {
    final query = _db.select(_db.notes)
      ..where(
        (note) => note.status.equals(noteStatusCode(NoteStatus.recording)),
      )
      ..orderBy([(note) => OrderingTerm.asc(note.createdAt)]);
    final rows = await query.get();
    return [for (final row in rows) noteFromRows(row)];
  }

  @override
  Future<void> setActionItemDone({
    required String noteId,
    required String actionItemId,
    required bool isDone,
  }) {
    return _db.transaction(() async {
      final query = _db.update(_db.actionItems)
        ..where(
          (item) => item.id.equals(actionItemId) & item.noteId.equals(noteId),
        );
      final changed = await query.write(
        ActionItemsCompanion(isDone: Value(isDone)),
      );
      if (changed > 0) await _updateNote(noteId, const NotesCompanion());
    });
  }

  @override
  Future<void> retryProcessing(String noteId) async {
    final query = _db.update(_db.notes)
      ..where(
        (note) =>
            note.id.equals(noteId) &
            note.status.equals(noteStatusCode(NoteStatus.failed)),
      );
    await query.write(
      NotesCompanion(
        status: Value(noteStatusCode(NoteStatus.uploading)),
        errorMessage: const Value(null),
        updatedAt: Value(_now()),
      ),
    );
  }

  @override
  Future<void> setStatus(String noteId, NoteStatus status) async {
    await _updateNote(
      noteId,
      NotesCompanion(status: Value(noteStatusCode(status))),
    );
  }

  /// The parts get new ids.
  @override
  Future<void> saveNote(Note note) {
    return _db.transaction(() async {
      final exists = await _updateNote(
        note.id,
        NotesCompanion(
          status: Value(noteStatusCode(note.status)),
          title: Value(note.title),
          summary: Value(note.summary),
        ),
      );
      if (!exists) return;

      await _db.batch((batch) {
        batch
          ..deleteWhere(_db.keyPoints, (row) => row.noteId.equals(note.id))
          ..deleteWhere(_db.actionItems, (row) => row.noteId.equals(note.id))
          ..deleteWhere(
            _db.transcriptSegments,
            (row) => row.noteId.equals(note.id),
          )
          ..deleteWhere(_db.noteTags, (row) => row.noteId.equals(note.id));
        _addParts(batch, note.id, note);
      });
    });
  }

  @override
  Future<void> deleteNote(String id) async {
    // Its parts go with it: their foreign keys cascade the delete.
    final query = _db.delete(_db.notes)..where((note) => note.id.equals(id));
    final deleted = await query.goAndReturn();

    // The note goes first, then its recording. Failing in between leaves a
    // file without a note, which a cleanup can find later. The other way
    // round could leave a note whose recording is gone.
    for (final fileName in deleted.map((note) => note.audioFileName).nonNulls) {
      try {
        await _audioFiles.delete(fileName);
      } catch (error, stackTrace) {
        // The note is gone, so for the user the delete worked.
        developer.log(
          "Couldn't delete the recording $fileName",
          name: 'echonotes.notes',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// Adds [notes] with new ids, but only when there are no notes at all.
  /// Debug builds use it for the sample notes.
  Future<void> seedIfEmpty(List<Note> notes) {
    return _db.transaction(() async {
      final anyNote = await (_db.select(_db.notes)..limit(1)).getSingleOrNull();
      if (anyNote != null) return;

      for (final note in notes) {
        final id = _newId();
        await _insertNote(id, note);
        await _db.batch((batch) => _addParts(batch, id, note));
      }
    });
  }

  Future<Note?> _readNote(String id) {
    // One transaction, so the note and its parts come from the same moment.
    return _db.transaction(() async {
      final note = await (_db.select(
        _db.notes,
      )..where((note) => note.id.equals(id))).getSingleOrNull();
      if (note == null) return null;

      final tags = _db.select(_db.noteTags)
        ..where((tag) => tag.noteId.equals(id))
        ..orderBy([(tag) => OrderingTerm.asc(tag.position)]);
      final keyPoints = _db.select(_db.keyPoints)
        ..where((point) => point.noteId.equals(id))
        ..orderBy([(point) => OrderingTerm.asc(point.position)]);
      final actionItems = _db.select(_db.actionItems)
        ..where((item) => item.noteId.equals(id))
        ..orderBy([(item) => OrderingTerm.asc(item.position)]);
      final transcript = _db.select(_db.transcriptSegments)
        ..where((segment) => segment.noteId.equals(id))
        ..orderBy([
          (segment) => OrderingTerm.asc(segment.startMs),
          (segment) => OrderingTerm.asc(segment.endMs),
        ]);

      return noteFromRows(
        note,
        tags: await tags.get(),
        keyPoints: await keyPoints.get(),
        actionItems: await actionItems.get(),
        transcript: await transcript.get(),
      );
    });
  }

  /// Adds the row of [note] under [id]. Its parts are added separately.
  Future<void> _insertNote(String id, Note note) {
    final now = _now();
    return _db
        .into(_db.notes)
        .insert(
          NotesCompanion.insert(
            id: id,
            title: Value(note.title),
            summary: Value(note.summary),
            audioFileName: Value(note.audioFileName),
            durationMs: note.duration.inMilliseconds,
            status: noteStatusCode(note.status),
            createdAt: storedDate(note.recordedAt),
            updatedAt: now,
          ),
        );
  }

  /// Writes [changes] to a note and marks it as updated. Returns false when
  /// the note is gone.
  Future<bool> _updateNote(String id, NotesCompanion changes) async {
    final query = _db.update(_db.notes)..where((note) => note.id.equals(id));
    final changed = await query.write(
      changes.copyWith(updatedAt: Value(_now())),
    );
    return changed > 0;
  }

  /// Adds the key points, action items, transcript and tags of [note] to
  /// [batch], under the note [noteId], each part with a new id.
  void _addParts(Batch batch, String noteId, Note note) {
    batch
      ..insertAll(_db.keyPoints, [
        for (final (position, point) in note.keyPoints.indexed)
          KeyPointsCompanion.insert(
            id: _newId(),
            noteId: noteId,
            content: point.text,
            position: position,
          ),
      ])
      ..insertAll(_db.actionItems, [
        for (final (position, item) in note.actionItems.indexed)
          ActionItemsCompanion.insert(
            id: _newId(),
            noteId: noteId,
            content: item.text,
            isDone: Value(item.isDone),
            position: position,
          ),
      ])
      ..insertAll(_db.transcriptSegments, [
        for (final segment in note.transcript)
          TranscriptSegmentsCompanion.insert(
            id: _newId(),
            noteId: noteId,
            startMs: segment.start.inMilliseconds,
            endMs: segment.end.inMilliseconds,
            content: segment.text,
          ),
      ])
      ..insertAll(_db.noteTags, [
        for (final (position, tag) in _cleanTags(note.tags).indexed)
          NoteTagsCompanion.insert(
            noteId: noteId,
            name: tag,
            position: position,
          ),
      ]);
  }

  /// [tags] trimmed, without blanks, and each only once, ignoring case like
  /// the database does.
  static List<String> _cleanTags(List<String> tags) {
    final seen = <String>{};
    return [
      for (final tag in tags.map((tag) => tag.trim()))
        if (tag.isNotEmpty && seen.add(tag.toLowerCase())) tag,
    ];
  }

  static String _newId() => _uuid.v7();

  static DateTime _now() => storedDate(DateTime.now());
}
