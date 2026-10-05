import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:echonotes/features/notes/data/fake_notes_repository.dart';
import 'package:echonotes/features/notes/data/sample_notes.dart';
import 'package:echonotes/features/notes/presentation/home_screen.dart';
import 'package:echonotes/features/notes/presentation/note_detail_screen.dart';
import 'package:echonotes/features/notes/presentation/processing_screen.dart';
import 'package:echonotes/features/recording/data/recording_recovery.dart';
import 'package:echonotes/features/recording/domain/microphone_permission.dart';
import 'package:echonotes/features/recording/presentation/recording_screen.dart';

import '../helpers/app_harness.dart';
import '../helpers/fake_recording_services.dart';

/// Every screen on a small phone with text at twice the normal size.
/// Anything that overflows makes Flutter report an error, which fails the
/// test.
void main() {
  final screens = {
    'home': HomeScreen.routePath,
    'empty home': HomeScreen.routePath,
    'recording': RecordingScreen.location,
    'processing': ProcessingScreen.location('sample-processing'),
    'failed processing': ProcessingScreen.location('sample-failed'),
    'note detail': NoteDetailScreen.location('sample-team-meeting'),
    'missing note': NoteDetailScreen.location('missing'),
  };

  for (final MapEntry(key: name, value: location) in screens.entries) {
    testWidgets('$name fits', (tester) async {
      useSmallPhoneWithLargeText(tester);
      await pumpApp(
        tester,
        repository: FakeNotesRepository(
          notes: name == 'empty home' ? const [] : sampleNotes(DateTime.now()),
        ),
        location: location,
      );
      await tester.pump(const Duration(seconds: 1));

      // Scroll to the end, so every lazily built part gets laid out too.
      final scrollables = find.byType(Scrollable);
      if (scrollables.evaluate().isNotEmpty) {
        await tester.drag(scrollables.first, const Offset(0, -5000));
        await tester.pump(const Duration(seconds: 1));
      }

      final error = tester.takeException();
      // The full error names the widget that overflowed.
      expect(error, isNull, reason: '$error');
    });
  }

  // The recording screen's other states: what brings each about, and a
  // text that shows it's there.
  final recordingStates =
      <String, (Future<void> Function(WidgetTester), String)>{
        'recording reminder': (
          (tester) => pumpApp(
            tester,
            repository: FakeNotesRepository(),
            location: RecordingScreen.location,
            preferences: FakeRecordingPreferences(seenConsentReminder: false),
          ),
          'Let people know',
        ),
        'microphone blocked': (
          (tester) => pumpApp(
            tester,
            repository: FakeNotesRepository(),
            location: RecordingScreen.location,
            permission: FakeMicrophonePermission(
              access: MicrophoneAccess.blocked,
            ),
          ),
          'Microphone access is off',
        ),
        'recording with the battery notice': (
          (tester) => pumpApp(
            tester,
            repository: FakeNotesRepository(),
            location: RecordingScreen.location,
            background: FakeBackgroundRecording()..isLimited = true,
          ),
          'Battery settings',
        ),
        'cut-off explanation': (
          (tester) => pumpApp(
            tester,
            repository: FakeNotesRepository(notes: sampleNotes(DateTime.now())),
            recovered: const RecoveredRecordings(
              kept: 1,
              cutOffInBackground: true,
            ),
          ),
          'Your recording was cut off',
        ),
        // Room for a few minutes only, so it warns while recording.
        'recording with a notice': (
          (tester) => pumpApp(
            tester,
            repository: FakeNotesRepository(),
            location: RecordingScreen.location,
            storage: FakeStorageSpace(30 * 1000 * 1000),
          ),
          'Your phone is low on space',
        ),
      };

  for (final MapEntry(key: name, value: (open, shown))
      in recordingStates.entries) {
    testWidgets('$name fits', (tester) async {
      useSmallPhoneWithLargeText(tester);
      await open(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining(shown), findsOneWidget);

      final scrollables = find.byType(Scrollable);
      if (scrollables.evaluate().isNotEmpty) {
        await tester.drag(scrollables.first, const Offset(0, -5000));
        await tester.pump(const Duration(seconds: 1));
      }

      final error = tester.takeException();
      expect(error, isNull, reason: '$error');
    });
  }

  testWidgets('the delete dialog fits', (tester) async {
    useSmallPhoneWithLargeText(tester);
    await pumpApp(
      tester,
      repository: FakeNotesRepository(notes: sampleNotes(DateTime.now())),
      location: NoteDetailScreen.location('sample-team-meeting'),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byTooltip('Delete note'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Delete this note?'), findsOneWidget);
    final error = tester.takeException();
    expect(error, isNull, reason: '$error');
  });
}
