import 'dart:async';
import 'dart:developer' as developer;

import 'package:echonotes/features/notes/data/sample_notes.dart';
import 'package:echonotes/features/notes/domain/note.dart';
import 'package:echonotes/features/notes/domain/note_status.dart';
import 'package:echonotes/features/notes/domain/notes_repository.dart';

/// Stands in for the backend until there is one.
///
/// Follows the notes in a repository and moves each one that is still
/// processing on to its next status, one step every [stepDuration], until
/// it's ready with sample notes. Because it follows the saved notes, it
/// also picks up retried notes, and notes that were left unfinished when
/// the app closed.
class FakeNoteProcessing {
  FakeNoteProcessing(
    this._repository, {
    this.stepDuration = const Duration(seconds: 2),
  });

  /// The statuses a note moves through, in order.
  static const _pipeline = [
    NoteStatus.uploading,
    NoteStatus.queued,
    NoteStatus.transcribing,
    NoteStatus.writingNotes,
    NoteStatus.ready,
  ];

  final NotesRepository _repository;
  final Duration stepDuration;

  /// The latest version of every note that is still processing, by id.
  final _processing = <String, Note>{};
  final _timers = <String, Timer>{};
  StreamSubscription<List<Note>>? _subscription;

  /// Starts following the notes.
  void start() {
    _subscription ??= _repository.watchNotes().listen(
      _follow,
      onError: (Object error, StackTrace stackTrace) {
        _log("Couldn't read the notes", error, stackTrace);
      },
    );
  }

  /// Stops following the notes, and every step still to come.
  void dispose() {
    _subscription?.cancel();
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  void _follow(List<Note> notes) {
    _processing
      ..clear()
      ..addEntries([
        for (final note in notes)
          if (note.status.isProcessing) MapEntry(note.id, note),
      ]);
    // Notes that are done, failed or deleted need no more steps.
    _timers.removeWhere((id, timer) {
      if (_processing.containsKey(id)) return false;
      timer.cancel();
      return true;
    });
    for (final id in _processing.keys) {
      _timers[id] ??= Timer.periodic(stepDuration, (_) => _advance(id));
    }
  }

  Future<void> _advance(String id) async {
    final note = _processing[id];
    if (note == null) return;
    final next = _pipeline[_pipeline.indexOf(note.status) + 1];

    try {
      if (next == NoteStatus.ready) {
        await _repository.saveNote(withSampleResult(note));
      } else {
        await _repository.setStatus(id, next);
      }
    } catch (error, stackTrace) {
      // The timer keeps going, so the same step is tried again next time.
      _log("Couldn't move note $id on to ${next.name}", error, stackTrace);
    }
  }

  void _log(String message, Object error, StackTrace stackTrace) {
    developer.log(
      message,
      name: 'echonotes.notes',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
