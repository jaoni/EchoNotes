import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:echonotes/features/notes/data/local_audio_file_store.dart';

void main() {
  late Directory base;
  late LocalAudioFileStore store;

  setUp(() async {
    base = await Directory.systemTemp.createTemp('echonotes_audio_test');
    store = LocalAudioFileStore(baseDirectory: () async => base);
  });

  tearDown(() => base.delete(recursive: true));

  test('builds the full path inside the recordings folder', () async {
    expect(
      await store.pathOf('meeting.m4a'),
      p.join(base.path, 'recordings', 'meeting.m4a'),
    );
  });

  test('makes the recordings folder for a new recording', () async {
    final path = await store.pathForNewRecording('meeting.aac');

    expect(path, p.join(base.path, 'recordings', 'meeting.aac'));
    expect(await Directory(p.dirname(path)).exists(), isTrue);
    // Asking again is fine.
    await store.pathForNewRecording('other.aac');
  });

  test('deletes a recording', () async {
    final file = File(p.join(base.path, 'recordings', 'meeting.m4a'));
    await file.create(recursive: true);

    await store.delete('meeting.m4a');

    expect(await file.exists(), isFalse);
  });

  test('deleting a recording that is already gone is fine', () async {
    await store.delete('missing.m4a');
  });

  test('refuses a name that could reach outside the folder', () async {
    for (final name in ['', '.', '..', '../echonotes.sqlite', 'a/b.m4a']) {
      await expectLater(store.pathOf(name), throwsArgumentError, reason: name);
      await expectLater(
        store.pathForNewRecording(name),
        throwsArgumentError,
        reason: name,
      );
    }
  });
}
