import 'package:flutter_test/flutter_test.dart';

import 'package:echonotes/features/notes/data/note_rows.dart';
import 'package:echonotes/features/notes/domain/note_status.dart';

void main() {
  test('stores every status under the server spelling', () {
    // Saved notes depend on these exact words, so they must never change.
    expect(
      {for (final status in NoteStatus.values) noteStatusCode(status)},
      {
        'recording',
        'uploading',
        'queued',
        'transcribing',
        'writing_notes',
        'ready',
        'failed',
      },
    );
    for (final status in NoteStatus.values) {
      expect(noteStatusFromCode(noteStatusCode(status)), status);
    }
  });

  test('refuses a status it does not know', () {
    expect(() => noteStatusFromCode('archived'), throwsFormatException);
  });

  test('stores dates in UTC, to the millisecond', () {
    final local = DateTime(2026, 9, 28, 10, 30, 15, 123, 456);

    final stored = storedDate(local);

    expect(stored.isUtc, isTrue);
    expect(stored.microsecond, 0);
    expect(stored.millisecondsSinceEpoch, local.millisecondsSinceEpoch);
  });
}
