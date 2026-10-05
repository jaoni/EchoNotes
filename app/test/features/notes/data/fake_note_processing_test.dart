import 'package:flutter_test/flutter_test.dart';

import 'package:echonotes/features/notes/data/fake_note_processing.dart';
import 'package:echonotes/features/notes/data/fake_notes_repository.dart';
import 'package:echonotes/features/notes/domain/note.dart';
import 'package:echonotes/features/notes/domain/note_status.dart';

void main() {
  final monday = DateTime(2026, 9, 28, 10);

  late FakeNotesRepository repository;
  late FakeNoteProcessing processing;

  void start([List<Note> notes = const []]) {
    repository = FakeNotesRepository(notes: notes);
    processing = FakeNoteProcessing(
      repository,
      stepDuration: const Duration(milliseconds: 1),
    )..start();
    addTearDown(() {
      processing.dispose();
      repository.dispose();
    });
  }

  Note note(String id, NoteStatus status) {
    return Note(
      id: id,
      recordedAt: monday,
      duration: const Duration(minutes: 5),
      status: status,
    );
  }

  /// Every status [id] goes through until it's ready or failed.
  Future<List<NoteStatus>> statusesUntilDone(String id) async {
    final statuses = <NoteStatus>[];
    await for (final note in repository.watchNote(id)) {
      statuses.add(note!.status);
      if (!note.status.isProcessing) break;
    }
    return statuses;
  }

  /// Gives the pretend processing time for several steps.
  Future<void> waitSeveralSteps() {
    return Future<void>.delayed(const Duration(milliseconds: 30));
  }

  test('a new recording goes through every step and gets notes', () async {
    start();

    final started = await repository.startRecording(
      recordedAt: monday,
      audioFileExtension: 'aac',
    );
    final id = started.id;
    await repository.finishRecording(id, const Duration(seconds: 30));

    expect(await statusesUntilDone(id), [
      NoteStatus.uploading,
      NoteStatus.queued,
      NoteStatus.transcribing,
      NoteStatus.writingNotes,
      NoteStatus.ready,
    ]);
    final done = (await repository.watchNote(id).first)!;
    expect(done.title, isNotEmpty);
    expect(done.transcript, isNotEmpty);
    expect(done.duration, const Duration(seconds: 30));
  });

  test('carries on with a note left unfinished, as after a restart', () async {
    start([note('n1', NoteStatus.transcribing)]);

    expect(await statusesUntilDone('n1'), [
      NoteStatus.transcribing,
      NoteStatus.writingNotes,
      NoteStatus.ready,
    ]);
  });

  test('runs a retried note again until it is ready', () async {
    start([note('n1', NoteStatus.failed)]);

    await repository.retryProcessing('n1');

    final statuses = await statusesUntilDone('n1');
    expect(statuses.first, NoteStatus.uploading);
    expect(statuses.last, NoteStatus.ready);
  });

  test('leaves recordings, finished and failed notes alone', () async {
    start([
      note('recording', NoteStatus.recording),
      note('done', NoteStatus.ready),
      note('failed', NoteStatus.failed),
    ]);

    await waitSeveralSteps();

    final notes = await repository.watchNotes().first;
    expect(notes.map((note) => note.status), [
      NoteStatus.recording,
      NoteStatus.ready,
      NoteStatus.failed,
    ]);
  });

  test('stops working on a note that was deleted', () async {
    start([note('n1', NoteStatus.uploading)]);

    await repository.deleteNote('n1');
    await waitSeveralSteps();

    expect(await repository.watchNote('n1').first, isNull);
  });

  test('stops altogether once disposed', () async {
    start([note('n1', NoteStatus.uploading)]);

    processing.dispose();
    await waitSeveralSteps();

    expect(
      (await repository.watchNote('n1').first)!.status,
      NoteStatus.uploading,
    );
  });
}
