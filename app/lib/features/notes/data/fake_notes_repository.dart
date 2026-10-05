import 'dart:async';

import 'package:echonotes/features/notes/domain/note.dart';
import 'package:echonotes/features/notes/domain/note_status.dart';
import 'package:echonotes/features/notes/domain/notes_repository.dart';

/// Keeps notes in memory, for tests.
///
/// Notes stay exactly as they are until something changes them, so a test
/// can show any status for as long as it likes. Moving notes through
/// processing is `FakeNoteProcessing`'s job, as it is in the app.
class FakeNotesRepository implements NotesRepository {
  FakeNotesRepository({List<Note> notes = const []}) : _notes = [...notes];

  final List<Note> _notes;
  final _changes = StreamController<void>.broadcast();
  var _nextId = 0;

  @override
  Stream<List<Note>> watchNotes() {
    return Stream.multi((listener) {
      void emit() => listener.add(_sortedNotes());
      emit();
      final subscription = _changes.stream.listen((_) => emit());
      listener.onCancel = subscription.cancel;
    });
  }

  @override
  Stream<Note?> watchNote(String id) {
    // Unchanged notes keep their object, so distinct() skips them.
    return watchNotes().map((notes) => _find(notes, id)).distinct();
  }

  @override
  Future<Note> startRecording({
    required DateTime recordedAt,
    required String audioFileExtension,
  }) async {
    final id = 'recording-${_nextId++}';
    final note = Note(
      id: id,
      recordedAt: recordedAt,
      duration: Duration.zero,
      status: NoteStatus.recording,
      audioFileName: '$id.$audioFileExtension',
    );
    _notes.add(note);
    _changed();
    return note;
  }

  @override
  Future<void> finishRecording(String noteId, Duration duration) async {
    final note = _find(_notes, noteId);
    if (note == null || note.status != NoteStatus.recording) return;
    // Its length is one of the recording's own facts, which copyWith keeps.
    _replace(
      Note(
        id: note.id,
        recordedAt: note.recordedAt,
        duration: duration,
        status: NoteStatus.uploading,
        audioFileName: note.audioFileName,
      ),
    );
  }

  @override
  Future<List<Note>> unfinishedRecordings() async {
    return [
      for (final note in _notes)
        if (note.status == NoteStatus.recording) note,
    ];
  }

  @override
  Future<void> setActionItemDone({
    required String noteId,
    required String actionItemId,
    required bool isDone,
  }) async {
    final note = _find(_notes, noteId);
    if (note == null) return;
    _replace(
      note.copyWith(
        actionItems: [
          for (final item in note.actionItems)
            item.id == actionItemId ? item.copyWith(isDone: isDone) : item,
        ],
      ),
    );
  }

  @override
  Future<void> retryProcessing(String noteId) async {
    final note = _find(_notes, noteId);
    if (note == null || note.status != NoteStatus.failed) return;
    _replace(note.copyWith(status: NoteStatus.uploading));
  }

  @override
  Future<void> setStatus(String noteId, NoteStatus status) async {
    final note = _find(_notes, noteId);
    if (note == null) return;
    _replace(note.copyWith(status: status));
  }

  @override
  Future<void> saveNote(Note note) async {
    final saved = _find(_notes, note.id);
    if (saved == null) return;
    _replace(
      saved.copyWith(
        status: note.status,
        title: note.title,
        summary: note.summary,
        keyPoints: note.keyPoints,
        actionItems: note.actionItems,
        tags: note.tags,
        transcript: note.transcript,
      ),
    );
  }

  @override
  Future<void> deleteNote(String id) async {
    final before = _notes.length;
    _notes.removeWhere((note) => note.id == id);
    if (_notes.length != before) _changed();
  }

  /// Closes the streams.
  void dispose() {
    _changes.close();
  }

  List<Note> _sortedNotes() {
    final sorted = [..._notes]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return List.unmodifiable(sorted);
  }

  Note? _find(List<Note> notes, String id) {
    return notes.where((note) => note.id == id).firstOrNull;
  }

  void _replace(Note note) {
    final index = _notes.indexWhere((existing) => existing.id == note.id);
    if (index < 0) return;
    _notes[index] = note;
    _changed();
  }

  void _changed() {
    if (!_changes.isClosed) _changes.add(null);
  }
}
