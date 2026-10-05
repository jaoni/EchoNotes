import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:echonotes/core/theme/app_spacing.dart';
import 'package:echonotes/features/notes/data/fake_notes_repository.dart';
import 'package:echonotes/features/notes/data/sample_notes.dart';
import 'package:echonotes/features/notes/domain/note.dart';
import 'package:echonotes/features/notes/domain/note_status.dart';
import 'package:echonotes/features/notes/presentation/home_screen.dart';
import 'package:echonotes/features/notes/presentation/note_detail_screen.dart';
import 'package:echonotes/features/playback/presentation/widgets/audio_player_bar.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/fake_audio_playback.dart';

void main() {
  const meetingId = 'sample-team-meeting';
  final list = find.byType(Scrollable).first;

  testWidgets('shows every part of a finished note', (tester) async {
    await pumpApp(
      tester,
      repository: FakeNotesRepository(notes: sampleNotes(DateTime.now())),
      location: NoteDetailScreen.location(meetingId),
    );
    await tester.pumpAndSettle();

    expect(find.text('Weekly product sync'), findsOneWidget);
    expect(find.text('meeting'), findsOneWidget);
    expect(find.byTooltip('Play'), findsOneWidget);

    // The player's times sit at either end, not run together.
    Finder playerText(String text) => find.descendant(
      of: find.byType(AudioPlayerBar),
      matching: find.text(text),
    );
    final gap =
        tester.getTopLeft(playerText('32:40')).dx -
        tester.getTopRight(playerText('00:00')).dx;
    expect(gap, greaterThan(AppSpacing.xxxl));

    for (final section in [
      'Summary',
      'Key points',
      'Action items',
      'Full transcript',
    ]) {
      await tester.scrollUntilVisible(
        find.text(section),
        200,
        scrollable: list,
      );
    }
    await tester.scrollUntilVisible(find.text('00:31'), 200, scrollable: list);
  });

  testWidgets('ticking an action item saves it through the repository', (
    tester,
  ) async {
    final repository = FakeNotesRepository(notes: sampleNotes(DateTime.now()));
    await pumpApp(
      tester,
      repository: repository,
      location: NoteDetailScreen.location(meetingId),
    );
    await tester.pumpAndSettle();

    final item = find.widgetWithText(
      CheckboxListTile,
      'Sam: draft the offline upload plan',
    );
    await tester.scrollUntilVisible(item, 200, scrollable: list);
    expect(tester.widget<CheckboxListTile>(item).value, isFalse);

    await tester.tap(item);
    await tester.pumpAndSettle();

    expect(tester.widget<CheckboxListTile>(item).value, isTrue);
    // Streams need real async, outside the test's fake clock.
    final saved = await tester.runAsync(
      () => repository.watchNote(meetingId).first,
    );
    expect(saved!.actionItems.firstWhere((a) => a.id == 'team-2').isDone, true);
  });

  group('the player', () {
    IconButton playButton(WidgetTester tester) {
      return tester.widget<IconButton>(
        find.descendant(
          of: find.byType(AudioPlayerBar),
          matching: find.byType(IconButton),
        ),
      );
    }

    testWidgets("plays and pauses the note's recording", (tester) async {
      final meeting = sampleNotes(DateTime.now())[1];
      final players = <FakeAudioPlayback>[];
      await pumpApp(
        tester,
        repository: FakeNotesRepository(
          notes: [
            Note(
              id: meeting.id,
              recordedAt: meeting.recordedAt,
              duration: meeting.duration,
              status: NoteStatus.ready,
              audioFileName: 'meeting.aac',
              title: meeting.title,
            ),
          ],
        ),
        location: NoteDetailScreen.location(meeting.id),
        playback: players,
      );
      await tester.pumpAndSettle();

      final player = players.single;
      expect(player.loadedPath, '/recordings/meeting.aac');

      await tester.tap(find.byTooltip('Play'));
      await tester.pumpAndSettle();
      expect(player.isPlaying, isTrue);
      expect(find.byTooltip('Pause'), findsOneWidget);

      await tester.tap(find.byTooltip('Pause'));
      await tester.pumpAndSettle();
      expect(player.isPlaying, isFalse);
    });

    testWidgets('stays off for a note without a recording', (tester) async {
      final players = <FakeAudioPlayback>[];
      await pumpApp(
        tester,
        repository: FakeNotesRepository(notes: sampleNotes(DateTime.now())),
        location: NoteDetailScreen.location(meetingId),
        playback: players,
      );
      await tester.pumpAndSettle();

      expect(players, isEmpty);
      expect(playButton(tester).onPressed, isNull);
    });
  });

  testWidgets('points to the progress of a note that is not ready', (
    tester,
  ) async {
    final repository = FakeNotesRepository(notes: sampleNotes(DateTime.now()));
    await pumpApp(
      tester,
      repository: repository,
      location: NoteDetailScreen.location('sample-failed'),
    );
    await tester.pumpAndSettle();

    expect(find.text("These notes aren't ready yet"), findsOneWidget);
    expect(find.byTooltip('Play'), findsNothing);

    await tester.tap(find.text('See progress'));
    await tester.pumpAndSettle();
    expect(find.text("We couldn't finish your notes"), findsOneWidget);
  });

  group('deleting', () {
    Future<FakeNotesRepository> openMeeting(
      WidgetTester tester, [
      FakeNotesRepository? repository,
    ]) async {
      final notes =
          repository ?? FakeNotesRepository(notes: sampleNotes(DateTime.now()));
      await pumpApp(
        tester,
        repository: notes,
        location: NoteDetailScreen.location(meetingId),
      );
      await tester.pumpAndSettle();
      return notes;
    }

    Future<void> confirmDelete(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Delete note'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      // Frame by frame through the way back: the note must never show as
      // missing while its screen leaves.
      for (var frame = 0; frame < 30; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text("This note isn't here"), findsNothing);
      }
      await tester.pumpAndSettle();
    }

    testWidgets('asks first, then goes back to the list without the note', (
      tester,
    ) async {
      final repository = await openMeeting(tester);

      await confirmDelete(tester);

      expect(find.byType(NoteDetailScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Weekly product sync'), findsNothing);
      expect(find.text("This note isn't here"), findsNothing);
      final saved = await tester.runAsync(
        () => repository.watchNote(meetingId).first,
      );
      expect(saved, isNull);
    });

    testWidgets('cancelling stays on the note', (tester) async {
      await openMeeting(tester);

      await tester.tap(find.byTooltip('Delete note'));
      await tester.pumpAndSettle();
      expect(find.text('Delete this note?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(NoteDetailScreen), findsOneWidget);
      expect(find.text('Weekly product sync'), findsOneWidget);
    });

    testWidgets('says so when the note could not be deleted', (tester) async {
      await openMeeting(
        tester,
        _FailingDeleteRepository(notes: sampleNotes(DateTime.now())),
      );

      await confirmDelete(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        find.text("Couldn't delete the note. Please try again."),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.error_outline_rounded), findsWidgets);
      expect(find.text('Weekly product sync'), findsOneWidget);
    });
  });
}

class _FailingDeleteRepository extends FakeNotesRepository {
  _FailingDeleteRepository({super.notes});

  @override
  Future<void> deleteNote(String id) async {
    throw StateError('The disk is full');
  }
}
