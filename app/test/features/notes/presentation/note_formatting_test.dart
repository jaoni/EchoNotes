import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:echonotes/features/notes/domain/note.dart';
import 'package:echonotes/features/notes/domain/note_status.dart';
import 'package:echonotes/features/notes/presentation/note_formatting.dart';

import '../../../helpers/themed_app.dart';

void main() {
  // Wednesday afternoon.
  final now = DateTime(2026, 9, 30, 15);

  Note recordedAt(DateTime date) => Note(
    id: 'n1',
    recordedAt: date,
    duration: const Duration(minutes: 24),
    status: NoteStatus.ready,
  );

  /// Formats [note] inside a real app, which provides the localizations.
  Future<String> metadataOf(WidgetTester tester, Note note) async {
    late String result;
    await tester.pumpWidget(
      themedApp(
        Builder(
          builder: (context) {
            result = noteMetadata(context, note, now: now);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return result;
  }

  testWidgets('says today and yesterday in words', (tester) async {
    expect(
      await metadataOf(tester, recordedAt(DateTime(2026, 9, 30, 9, 30))),
      'Today · 9:30 AM · 24 min',
    );
    expect(
      await metadataOf(tester, recordedAt(DateTime(2026, 9, 29, 23, 59))),
      'Yesterday · 11:59 PM · 24 min',
    );
  });

  testWidgets('uses the date for older notes, with the year if needed', (
    tester,
  ) async {
    expect(
      await metadataOf(tester, recordedAt(DateTime(2026, 9, 28, 14))),
      'Mon, Sep 28 · 2:00 PM · 24 min',
    );
    expect(
      await metadataOf(tester, recordedAt(DateTime(2025, 12, 31, 14))),
      'Dec 31, 2025 · 2:00 PM · 24 min',
    );
  });

  test('uses a stand-in title until the notes are written', () {
    final note = recordedAt(now);
    expect(noteDisplayTitle(note), untitledNoteTitle);
    expect(noteDisplayTitle(note.copyWith(title: 'Sync')), 'Sync');
  });
}
