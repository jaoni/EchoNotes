import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:echonotes/features/notes/data/fake_notes_repository.dart';
import 'package:echonotes/features/notes/domain/note.dart';
import 'package:echonotes/features/notes/domain/note_status.dart';
import 'package:echonotes/features/notes/presentation/note_detail_screen.dart';
import 'package:echonotes/features/notes/presentation/processing_screen.dart';

import '../../../helpers/app_harness.dart';

void main() {
  FakeNotesRepository withNote(NoteStatus status) {
    return FakeNotesRepository(
      notes: [
        Note(
          id: 'n1',
          recordedAt: DateTime.now(),
          duration: const Duration(minutes: 3),
          status: status,
        ),
      ],
    );
  }

  testWidgets('marks earlier steps done and the current one in progress', (
    tester,
  ) async {
    useReducedMotion(tester);
    await pumpApp(
      tester,
      repository: withNote(NoteStatus.queued),
      location: ProcessingScreen.location('n1'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Making your notes'), findsOneWidget);
    expect(find.text('Waiting in line…'), findsOneWidget);
    // Uploading is done, transcribing is in progress, writing hasn't begun.
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsOneWidget);
  });

  testWidgets('a failed note says so, and retrying runs it to its notes', (
    tester,
  ) async {
    await pumpApp(
      tester,
      repository: withNote(NoteStatus.failed),
      location: ProcessingScreen.location('n1'),
      processingStep: const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();

    expect(find.text("We couldn't finish your notes"), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(find.textContaining('nothing is lost'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Making your notes'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(NoteDetailScreen), findsOneWidget);
  });

  testWidgets('explains when the note does not exist', (tester) async {
    await pumpApp(
      tester,
      repository: FakeNotesRepository(),
      location: ProcessingScreen.location('missing'),
    );
    await tester.pumpAndSettle();

    expect(find.text("This note isn't here"), findsOneWidget);
    await tester.tap(find.text('Back to notes'));
    await tester.pumpAndSettle();
    expect(find.text('No notes yet'), findsOneWidget);
  });
}
