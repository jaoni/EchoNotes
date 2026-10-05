import 'package:flutter_test/flutter_test.dart';

import 'package:echonotes/features/notes/data/fake_notes_repository.dart';
import 'package:echonotes/features/notes/domain/action_item.dart';
import 'package:echonotes/features/notes/domain/key_point.dart';
import 'package:echonotes/features/notes/domain/note.dart';
import 'package:echonotes/features/notes/domain/note_status.dart';

void main() {
  final monday = DateTime(2026, 9, 28, 10);

  Note note(
    String id, {
    DateTime? recordedAt,
    NoteStatus status = NoteStatus.ready,
    List<ActionItem> actionItems = const [],
  }) {
    return Note(
      id: id,
      recordedAt: recordedAt ?? monday,
      duration: const Duration(minutes: 5),
      status: status,
      actionItems: actionItems,
    );
  }

  late FakeNotesRepository repository;

  FakeNotesRepository create(List<Note> notes) {
    repository = FakeNotesRepository(notes: notes);
    addTearDown(repository.dispose);
    return repository;
  }

  test('lists notes newest first', () async {
    create([
      note('old', recordedAt: monday),
      note('new', recordedAt: monday.add(const Duration(days: 1))),
    ]);

    final notes = await repository.watchNotes().first;

    expect(notes.map((n) => n.id), ['new', 'old']);
  });

  test('gives null for a note that does not exist', () async {
    create([]);

    expect(await repository.watchNote('missing').first, isNull);
  });

  test('ticks an action item and tells listeners', () async {
    create([
      note(
        'n1',
        actionItems: const [
          ActionItem(id: 'a1', text: 'Call back'),
          ActionItem(id: 'a2', text: 'Send notes'),
        ],
      ),
    ]);
    final updates = repository.watchNote('n1').take(2).toList();

    await repository.setActionItemDone(
      noteId: 'n1',
      actionItemId: 'a2',
      isDone: true,
    );

    final latest = (await updates).last!;
    expect(latest.actionItems.map((a) => a.isDone), [false, true]);
  });

  test('a recording is a note from its start until it finishes', () async {
    create([]);

    final started = await repository.startRecording(
      recordedAt: monday,
      audioFileExtension: 'aac',
    );
    expect(started.status, NoteStatus.recording);
    expect(started.audioFileName, '${started.id}.aac');
    expect(await repository.unfinishedRecordings(), [started]);

    await repository.finishRecording(started.id, const Duration(seconds: 30));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final finished = (await repository.watchNote(started.id).first)!;
    expect(finished.status, NoteStatus.uploading);
    expect(finished.duration, const Duration(seconds: 30));
    expect(finished.audioFileName, started.audioFileName);
    expect(await repository.unfinishedRecordings(), isEmpty);
  });

  test('finishing leaves a note that is not recording alone', () async {
    create([note('n1', status: NoteStatus.transcribing)]);

    await repository.finishRecording('n1', const Duration(hours: 1));

    final same = (await repository.watchNote('n1').first)!;
    expect(same.status, NoteStatus.transcribing);
    expect(same.duration, const Duration(minutes: 5));
  });

  test('retrying puts only a failed note back in line', () async {
    create([
      note('failed', status: NoteStatus.failed),
      note('busy', status: NoteStatus.transcribing),
    ]);

    await repository.retryProcessing('failed');
    await repository.retryProcessing('busy');

    expect(
      (await repository.watchNote('failed').first)!.status,
      NoteStatus.uploading,
    );
    expect(
      (await repository.watchNote('busy').first)!.status,
      NoteStatus.transcribing,
    );
  });

  test("saving notes keeps the recording's own facts", () async {
    create([note('n1', status: NoteStatus.writingNotes)]);

    await repository.saveNote(
      Note(
        id: 'n1',
        recordedAt: monday.add(const Duration(days: 3)),
        duration: const Duration(hours: 2),
        status: NoteStatus.ready,
        title: 'Written',
        keyPoints: const [KeyPoint(text: 'A point')],
      ),
    );

    final saved = (await repository.watchNote('n1').first)!;
    expect(saved.status, NoteStatus.ready);
    expect(saved.title, 'Written');
    expect(saved.keyPoints, hasLength(1));
    expect(saved.recordedAt, monday);
    expect(saved.duration, const Duration(minutes: 5));
  });

  test('saving or moving on a missing note does nothing', () async {
    create([]);

    await repository.saveNote(note('gone'));
    await repository.setStatus('gone', NoteStatus.queued);

    expect(await repository.watchNotes().first, isEmpty);
  });

  test('deletes a note', () async {
    create([note('n1'), note('n2')]);

    await repository.deleteNote('n1');

    final notes = await repository.watchNotes().first;
    expect(notes.map((n) => n.id), ['n2']);
  });
}
