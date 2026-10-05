import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:echonotes/core/widgets/note_card.dart';
import 'package:echonotes/core/widgets/status_badge.dart';
import 'package:echonotes/features/notes/data/fake_notes_repository.dart';
import 'package:echonotes/features/notes/data/sample_notes.dart';
import 'package:echonotes/features/notes/presentation/note_detail_screen.dart';
import 'package:echonotes/features/notes/presentation/processing_screen.dart';
import 'package:echonotes/features/recording/data/recording_recovery.dart';
import 'package:echonotes/features/recording/presentation/recording_screen.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/fake_recording_services.dart';

void main() {
  const meetingId = 'sample-team-meeting';

  FakeNotesRepository withSampleNotes() {
    return FakeNotesRepository(notes: sampleNotes(DateTime.now()));
  }

  // The notes list; the search field has a scrollable of its own.
  final list = find.byType(Scrollable).first;

  group('with notes', () {
    testWidgets('lists every note, newest first, with its status', (
      tester,
    ) async {
      await pumpApp(tester, repository: withSampleNotes());

      expect(find.text('Search notes'), findsOneWidget);
      expect(find.bySemanticsLabel('Start recording'), findsOneWidget);

      // Newest first: the note still being transcribed tops the list.
      final firstCard = find.byType(NoteCard).first;
      expect(
        find.descendant(of: firstCard, matching: find.text('Transcribing…')),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.text('Weekly product sync'),
        200,
        scrollable: list,
      );
      expect(find.textContaining('The team reviewed'), findsOneWidget);
      expect(find.text('planning'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text("Couldn't finish · Tap to retry"),
        200,
        scrollable: list,
      );
      await tester.scrollUntilVisible(
        find.text('Interview: senior mobile engineer'),
        200,
        scrollable: list,
      );
    });

    testWidgets('shows a status badge only on unfinished notes', (
      tester,
    ) async {
      await pumpApp(tester, repository: withSampleNotes());

      final meeting = find.ancestor(
        of: find.text('Weekly product sync'),
        matching: find.byType(NoteCard),
      );
      expect(
        find.descendant(of: meeting, matching: find.byType(StatusBadge)),
        findsNothing,
      );
    });

    testWidgets('opens a finished note', (tester) async {
      await pumpApp(tester, repository: withSampleNotes());

      await tester.tap(find.text('Weekly product sync'));
      await tester.pumpAndSettle();

      expect(find.byType(NoteDetailScreen), findsOneWidget);
      expect(find.text('Summary'), findsOneWidget);
    });

    testWidgets('opens the progress of a failed note, to retry it', (
      tester,
    ) async {
      await pumpApp(tester, repository: withSampleNotes());

      final failed = find.text("Couldn't finish · Tap to retry");
      await tester.scrollUntilVisible(failed, 200, scrollable: list);
      await tester.tap(failed);
      await tester.pumpAndSettle();

      expect(find.byType(ProcessingScreen), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('a long press deletes a note, after asking', (tester) async {
      final repository = withSampleNotes();
      await pumpApp(tester, repository: repository);

      await tester.longPress(find.text('Weekly product sync'));
      await tester.pumpAndSettle();
      expect(find.text('Delete this note?'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete this note?'), findsNothing);
      expect(find.text('Weekly product sync'), findsNothing);
      // Streams need real async, outside the test's fake clock.
      final notes = await tester.runAsync(() => repository.watchNotes().first);
      expect(notes!.map((note) => note.id), isNot(contains(meetingId)));
    });

    testWidgets('cancelling the delete keeps the note', (tester) async {
      await pumpApp(tester, repository: withSampleNotes());

      await tester.longPress(find.text('Weekly product sync'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Delete this note?'), findsNothing);
      expect(find.text('Weekly product sync'), findsOneWidget);
    });
  });

  group('without notes', () {
    testWidgets('invites the first recording', (tester) async {
      await pumpApp(tester, repository: FakeNotesRepository());
      await tester.pumpAndSettle();

      expect(find.text('No notes yet'), findsOneWidget);
      expect(
        find.text(
          'Tap the record button below to capture your first conversation.',
        ),
        findsOneWidget,
      );
      expect(find.byType(NoteCard), findsNothing);
      expect(find.text('Search notes'), findsNothing);
      expect(find.bySemanticsLabel('Start recording'), findsOneWidget);
    });

    testWidgets('the record button opens the recording screen', (tester) async {
      await pumpApp(tester, repository: FakeNotesRepository());

      await tester.tap(find.bySemanticsLabel('Start recording'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(RecordingScreen), findsOneWidget);
    });
  });

  group('after recordings were cut off', () {
    testWidgets('says they were saved', (tester) async {
      await pumpApp(
        tester,
        repository: withSampleNotes(),
        recovered: const RecoveredRecordings(kept: 2),
      );
      await tester.pump();

      expect(find.textContaining('2 recordings were cut off'), findsOneWidget);
    });

    testWidgets('explains a cut-off in the background, once asked', (
      tester,
    ) async {
      final background = FakeBackgroundRecording();
      await pumpApp(
        tester,
        repository: withSampleNotes(),
        background: background,
        recovered: const RecoveredRecordings(kept: 1, cutOffInBackground: true),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your recording was cut off'), findsOneWidget);
      await tester.tap(find.text('Open settings'));
      await tester.pumpAndSettle();

      expect(find.text('Your recording was cut off'), findsNothing);
      expect(background.batterySettingsOpened, 1);
    });

    testWidgets('"Not now" just closes the explanation', (tester) async {
      final background = FakeBackgroundRecording();
      await pumpApp(
        tester,
        repository: withSampleNotes(),
        background: background,
        recovered: const RecoveredRecordings(kept: 1, cutOffInBackground: true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(find.text('Your recording was cut off'), findsNothing);
      expect(background.batterySettingsOpened, 0);
    });

    testWidgets('without battery settings, as on iOS, only says it was saved', (
      tester,
    ) async {
      await pumpApp(
        tester,
        repository: withSampleNotes(),
        background: FakeBackgroundRecording(hasBatterySettings: false),
        recovered: const RecoveredRecordings(kept: 1, cutOffInBackground: true),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your recording was cut off'), findsNothing);
      expect(find.textContaining('A recording was cut off'), findsOneWidget);
    });
  });
}
