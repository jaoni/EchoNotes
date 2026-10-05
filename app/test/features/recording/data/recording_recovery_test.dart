import 'package:flutter_test/flutter_test.dart';

import 'package:echonotes/features/notes/data/fake_notes_repository.dart';
import 'package:echonotes/features/notes/domain/note.dart';
import 'package:echonotes/features/notes/domain/note_status.dart';
import 'package:echonotes/features/recording/data/recording_recovery.dart';

import '../../../helpers/fake_audio_file_store.dart';
import '../../../helpers/fake_recording_services.dart';

void main() {
  final monday = DateTime(2026, 9, 28, 10);

  late FakeNotesRepository repository;
  late FakeRecordingPreferences preferences;

  /// The audio in each file, by path. Files not listed hold none.
  late Map<String, Duration> audio;
  late List<String> repaired;

  setUp(() {
    audio = {};
    repaired = [];
    preferences = FakeRecordingPreferences();
  });

  Note recording(String id, {String? audioFileName = 'default'}) {
    return Note(
      id: id,
      recordedAt: monday,
      duration: Duration.zero,
      status: NoteStatus.recording,
      audioFileName: audioFileName == 'default' ? '$id.aac' : audioFileName,
    );
  }

  Future<RecoveredRecordings> recover(List<Note> notes) {
    repository = FakeNotesRepository(notes: notes);
    addTearDown(repository.dispose);
    return RecordingRecovery(
      repository,
      FakeAudioFileStore(),
      preferences,
      repairFile: (path) async {
        repaired.add(path);
        if (path.contains('broken')) throw Exception('Unreadable');
        return audio[path] ?? Duration.zero;
      },
    ).recover();
  }

  Future<Note?> read(String id) => repository.watchNote(id).first;

  test('keeps a cut-off recording, as long as its audio', () async {
    audio['/recordings/cut.aac'] = const Duration(minutes: 12, seconds: 3);

    final recovered = await recover([recording('cut')]);

    expect(recovered.kept, 1);
    expect(recovered.cutOffInBackground, isFalse);
    expect(repaired, ['/recordings/cut.aac']);
    final note = (await read('cut'))!;
    expect(note.status, NoteStatus.uploading);
    expect(note.duration, const Duration(minutes: 12, seconds: 3));
  });

  test('deletes a recording that holds no audio', () async {
    final recovered = await recover([
      recording('empty'),
      recording('no-file', audioFileName: null),
    ]);

    expect(recovered.kept, 0);
    expect(await read('empty'), isNull);
    expect(await read('no-file'), isNull);
  });

  test('leaves a recording it cannot read for the next launch', () async {
    audio['/recordings/fine.aac'] = const Duration(seconds: 30);

    final recovered = await recover([recording('broken'), recording('fine')]);

    expect(recovered.kept, 1);
    expect((await read('broken'))!.status, NoteStatus.recording);
    expect((await read('fine'))!.status, NoteStatus.uploading);
  });

  test('tells when the phone stopped it in the background', () async {
    audio['/recordings/cut.aac'] = const Duration(minutes: 40);
    preferences.noteInBackground = 'cut';

    final recovered = await recover([recording('cut')]);

    expect(recovered.kept, 1);
    expect(recovered.cutOffInBackground, isTrue);
    // Said once: the next launch starts afresh.
    expect(preferences.noteInBackground, isNull);
  });

  test('a recording that stopped in the app was not cut off in the '
      'background', () async {
    audio['/recordings/cut.aac'] = const Duration(minutes: 40);
    // An earlier recording, which ended normally.
    preferences.noteInBackground = 'older';

    final recovered = await recover([recording('cut')]);

    expect(recovered.cutOffInBackground, isFalse);
    expect(preferences.noteInBackground, isNull);
  });

  test('leaves notes that are not recording alone', () async {
    final recovered = await recover([
      Note(
        id: 'done',
        recordedAt: monday,
        duration: const Duration(minutes: 5),
        status: NoteStatus.ready,
        audioFileName: 'done.aac',
      ),
    ]);

    expect(recovered.kept, 0);
    expect(repaired, isEmpty);
    expect((await read('done'))!.status, NoteStatus.ready);
  });
}
