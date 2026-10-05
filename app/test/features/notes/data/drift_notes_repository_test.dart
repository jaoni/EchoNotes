import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:echonotes/core/database/app_database.dart';
import 'package:echonotes/features/notes/data/drift_notes_repository.dart';
import 'package:echonotes/features/notes/data/sample_notes.dart';
import 'package:echonotes/features/notes/domain/action_item.dart';
import 'package:echonotes/features/notes/domain/key_point.dart';
import 'package:echonotes/features/notes/domain/note.dart';
import 'package:echonotes/features/notes/domain/note_status.dart';
import 'package:echonotes/features/notes/domain/transcript_segment.dart';

import '../../../helpers/fake_audio_file_store.dart';
import '../../../helpers/test_database.dart';

void main() {
  final uuid = matches(
    RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    ),
  );
  // With milliseconds, to check that they're kept.
  final monday = DateTime(2026, 9, 28, 10, 30, 15, 123);

  late AppDatabase db;
  late FakeAudioFileStore audioFiles;
  late DriftNotesRepository repository;

  setUp(() {
    db = inMemoryDatabase();
    audioFiles = FakeAudioFileStore();
    repository = DriftNotesRepository(db, audioFiles: audioFiles);
  });

  tearDown(() => db.close());

  /// A recording that's been made and waits to be uploaded. Its audio file
  /// is `<id>.aac`.
  Future<String> addRecording({DateTime? recordedAt}) async {
    final note = await repository.startRecording(
      recordedAt: recordedAt ?? monday,
      audioFileExtension: 'aac',
    );
    await repository.finishRecording(
      note.id,
      const Duration(minutes: 32, seconds: 40),
    );
    return note.id;
  }

  /// Finished notes for the recording [id].
  Note meetingNotes(String id) {
    return Note(
      id: id,
      recordedAt: monday,
      duration: const Duration(minutes: 32, seconds: 40),
      status: NoteStatus.ready,
      title: 'Weekly product sync',
      summary: 'The team agreed to make long recordings more reliable.',
      keyPoints: const [
        KeyPoint(text: 'Reliability comes first.'),
        KeyPoint(text: 'Sharing waits until after launch.'),
      ],
      actionItems: const [
        ActionItem(id: 'a1', text: 'Draft the offline upload plan'),
        ActionItem(id: 'a2', text: 'Share the survey', isDone: true),
      ],
      tags: const ['meeting', 'planning'],
      transcript: const [
        TranscriptSegment(
          start: Duration.zero,
          end: Duration(seconds: 6),
          text: "Okay, let's get started.",
        ),
        TranscriptSegment(
          start: Duration(seconds: 6),
          end: Duration(seconds: 14),
          text: 'People really like the summaries.',
        ),
      ],
    );
  }

  Future<Note?> read(String id) => repository.watchNote(id).first;

  group('recording', () {
    test('a recording gets its note, with a UUID, as it starts', () async {
      final started = await repository.startRecording(
        recordedAt: monday,
        audioFileExtension: 'aac',
      );

      final note = (await read(started.id))!;
      expect(started.id, uuid);
      expect(note.status, NoteStatus.recording);
      expect(note.audioFileName, '${started.id}.aac');
      expect(started.audioFileName, note.audioFileName);
      expect(note.recordedAt, monday);
      expect(note.duration, Duration.zero);
      expect(note.title, isEmpty);
    });

    test('finishing saves its length and puts it in line for upload', () async {
      final id = await addRecording();

      final note = (await read(id))!;
      expect(note.status, NoteStatus.uploading);
      expect(note.duration, const Duration(minutes: 32, seconds: 40));
      expect(note.audioFileName, '$id.aac');
      expect(note.recordedAt, monday);
    });

    test('finishing leaves a note that is no longer recording alone', () async {
      final id = await addRecording();
      await repository.setStatus(id, NoteStatus.transcribing);

      await repository.finishRecording(id, const Duration(seconds: 5));
      await repository.finishRecording('missing', const Duration(seconds: 5));

      final note = (await read(id))!;
      expect(note.status, NoteStatus.transcribing);
      expect(note.duration, const Duration(minutes: 32, seconds: 40));
    });

    test('lists the recordings that never finished, oldest first', () async {
      await addRecording();
      final later = await repository.startRecording(
        recordedAt: monday.add(const Duration(hours: 2)),
        audioFileExtension: 'aac',
      );
      final earlier = await repository.startRecording(
        recordedAt: monday.add(const Duration(hours: 1)),
        audioFileExtension: 'aac',
      );

      final unfinished = await repository.unfinishedRecordings();

      expect(unfinished.map((note) => note.id), [earlier.id, later.id]);
      expect(unfinished.first.audioFileName, '${earlier.id}.aac');
    });
  });

  group('saving and reading', () {
    test('saves the notes with every part, in order', () async {
      final id = await addRecording();

      await repository.saveNote(meetingNotes(id));

      final note = (await read(id))!;
      expect(note.status, NoteStatus.ready);
      expect(note.title, 'Weekly product sync');
      expect(note.summary, startsWith('The team agreed'));
      expect(note.keyPoints.map((point) => point.text), [
        'Reliability comes first.',
        'Sharing waits until after launch.',
      ]);
      expect(note.actionItems.map((item) => (item.text, item.isDone)), [
        ('Draft the offline upload plan', false),
        ('Share the survey', true),
      ]);
      expect(note.actionItems.map((item) => item.id), everyElement(uuid));
      expect(note.tags, ['meeting', 'planning']);
      expect(note.transcript.map((s) => (s.start, s.end, s.text)), [
        (Duration.zero, const Duration(seconds: 6), "Okay, let's get started."),
        (
          const Duration(seconds: 6),
          const Duration(seconds: 14),
          'People really like the summaries.',
        ),
      ]);
      // The recording's own facts stay as they were.
      expect(note.recordedAt, monday);
    });

    test('saving again replaces the parts instead of adding to them', () async {
      final id = await addRecording();
      await repository.saveNote(meetingNotes(id));

      await repository.saveNote(
        meetingNotes(id).copyWith(
          keyPoints: const [KeyPoint(text: 'Only this one.')],
          tags: const ['retro'],
        ),
      );

      final note = (await read(id))!;
      expect(note.keyPoints.map((point) => point.text), ['Only this one.']);
      expect(note.tags, ['retro']);
      expect(note.actionItems, hasLength(2));
    });

    test('saving is all or nothing', () async {
      final id = await addRecording();
      final broken = meetingNotes(id).copyWith(
        transcript: const [
          TranscriptSegment(
            start: Duration(seconds: 9),
            end: Duration(seconds: 3),
            text: 'Ends before it starts',
          ),
        ],
      );

      await expectLater(repository.saveNote(broken), throwsA(isA<Exception>()));

      // Neither the note nor any of its parts changed.
      final note = (await read(id))!;
      expect(note.status, NoteStatus.uploading);
      expect(note.title, isEmpty);
      expect(note.keyPoints, isEmpty);
      expect(note.actionItems, isEmpty);
      expect(note.tags, isEmpty);
    });

    test('keeps each tag once, whatever its case or spaces', () async {
      final id = await addRecording();

      await repository.saveNote(
        meetingNotes(
          id,
        ).copyWith(tags: const ['Meeting', ' meeting ', '', 'Plan', 'MEETING']),
      );

      expect((await read(id))!.tags, ['Meeting', 'Plan']);
    });

    test('saving a note that was deleted does not bring it back', () async {
      final id = await addRecording();
      await repository.deleteNote(id);

      await repository.saveNote(meetingNotes(id));
      await repository.setStatus(id, NoteStatus.transcribing);

      expect(await read(id), isNull);
      expect(await db.select(db.keyPoints).get(), isEmpty);
    });

    test('gives null for a note that does not exist', () async {
      expect(await read('missing'), isNull);
    });
  });

  group('the notes list', () {
    test('lists notes newest first, with their tags', () async {
      final oldest = await addRecording(recordedAt: monday);
      final newest = await addRecording(
        recordedAt: monday.add(const Duration(days: 1)),
      );
      final middle = await addRecording(
        recordedAt: monday.add(const Duration(hours: 5)),
      );
      await repository.saveNote(meetingNotes(middle));

      final notes = await repository.watchNotes().first;

      expect(notes.map((note) => note.id), [newest, middle, oldest]);
      expect(notes[1].title, 'Weekly product sync');
      expect(notes[1].tags, ['meeting', 'planning']);
      // The list leaves the heavy parts out.
      expect(notes[1].transcript, isEmpty);
    });

    test('updates by itself when a note is added', () async {
      final lists = StreamIterator(repository.watchNotes());
      addTearDown(lists.cancel);
      expect(await lists.moveNext(), isTrue);
      expect(lists.current, isEmpty);

      final id = await addRecording();

      expect(await lists.moveNext(), isTrue);
      expect(lists.current.map((note) => note.id), [id]);
    });
  });

  group('action items', () {
    test('ticking one saves it, and the open note updates', () async {
      final id = await addRecording();
      await repository.saveNote(meetingNotes(id));
      final versions = StreamIterator(repository.watchNote(id));
      addTearDown(versions.cancel);
      expect(await versions.moveNext(), isTrue);
      final first = versions.current!.actionItems.first;
      expect(first.isDone, isFalse);

      await repository.setActionItemDone(
        noteId: id,
        actionItemId: first.id,
        isDone: true,
      );

      expect(await versions.moveNext(), isTrue);
      expect(versions.current!.actionItems.map((item) => item.isDone), [
        true,
        true,
      ]);
    });
  });

  group('deleting', () {
    test('removes the note, all its parts and its recording', () async {
      final id = await addRecording();
      await repository.saveNote(meetingNotes(id));
      final other = await addRecording();
      await repository.saveNote(meetingNotes(other));

      await repository.deleteNote(id);

      expect(await read(id), isNull);
      expect(audioFiles.deleted, ['$id.aac']);
      // Only the other note's parts are left.
      for (final noteIds in [
        (await db.select(db.keyPoints).get()).map((row) => row.noteId),
        (await db.select(db.actionItems).get()).map((row) => row.noteId),
        (await db.select(db.transcriptSegments).get()).map((row) => row.noteId),
        (await db.select(db.noteTags).get()).map((row) => row.noteId),
      ]) {
        expect(noteIds, isNotEmpty);
        expect(noteIds, everyElement(other));
      }
    });

    test('deletes no file for a note without a recording', () async {
      await repository.seedIfEmpty([meetingNotes('sample')]);
      final id = (await repository.watchNotes().first).single.id;

      await repository.deleteNote(id);

      expect(await read(id), isNull);
      expect(audioFiles.deleted, isEmpty);
    });

    test('the note stays deleted when its recording cannot be', () async {
      final id = await addRecording();
      audioFiles.deleteError = const FileSystemException('Disk error');

      await repository.deleteNote(id);

      expect(await read(id), isNull);
    });

    test('does nothing for a note that is already gone', () async {
      await repository.deleteNote('missing');

      expect(audioFiles.deleted, isEmpty);
    });
  });

  group('retrying', () {
    test('puts a failed note back in line', () async {
      final id = await addRecording();
      await repository.setStatus(id, NoteStatus.failed);

      await repository.retryProcessing(id);

      expect((await read(id))!.status, NoteStatus.uploading);
    });

    test('leaves a note that has not failed alone', () async {
      final id = await addRecording();
      await repository.setStatus(id, NoteStatus.transcribing);

      await repository.retryProcessing(id);

      expect((await read(id))!.status, NoteStatus.transcribing);
    });
  });

  group('sample notes', () {
    test('fill an empty database, with new ids', () async {
      await repository.seedIfEmpty(sampleNotes(monday));

      final notes = await repository.watchNotes().first;
      expect(notes, hasLength(sampleNotes(monday).length));
      expect(notes.map((note) => note.id), everyElement(uuid));
      final meeting = notes.firstWhere((n) => n.title == 'Weekly product sync');
      final whole = (await read(meeting.id))!;
      expect(whole.keyPoints, hasLength(4));
      expect(whole.transcript, isNotEmpty);
    });

    test('leave a database that has notes alone', () async {
      final id = await addRecording();

      await repository.seedIfEmpty(sampleNotes(monday));

      final notes = await repository.watchNotes().first;
      expect(notes.map((note) => note.id), [id]);
    });
  });
}
