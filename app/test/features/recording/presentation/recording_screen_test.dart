import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:echonotes/features/notes/data/fake_notes_repository.dart';
import 'package:echonotes/features/notes/presentation/note_detail_screen.dart';
import 'package:echonotes/features/notes/presentation/processing_screen.dart';
import 'package:echonotes/features/recording/domain/audio_recorder_service.dart';
import 'package:echonotes/features/recording/domain/microphone_permission.dart';
import 'package:echonotes/features/recording/domain/recording_limits.dart';
import 'package:echonotes/features/recording/presentation/recording_screen.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/fake_audio_recorder_service.dart';
import '../../../helpers/fake_recording_services.dart';

void main() {
  // The recording screen ticks forever, so these tests pump set times
  // instead of waiting for everything to settle.
  const dialogTime = Duration(milliseconds: 300);
  const pageTime = Duration(seconds: 1);

  Future<void> openRecording(
    WidgetTester tester,
    FakeNotesRepository repository, {
    Duration? processingStep,
    FakeAudioRecorderService? recorder,
    FakeMicrophonePermission? permission,
    FakeRecordingPreferences? preferences,
    FakeBackgroundRecording? background,
    RecordingLimits limits = const RecordingLimits(),
  }) async {
    await pumpApp(
      tester,
      repository: repository,
      processingStep: processingStep,
      recorder: recorder,
      permission: permission,
      preferences: preferences,
      background: background,
      limits: limits,
    );
    await tester.tap(find.bySemanticsLabel('Start recording'));
    await tester.pump();
  }

  testWidgets('counts the recorded time, and pausing holds it', (tester) async {
    await openRecording(tester, FakeNotesRepository());

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Recording'), findsOneWidget);
    expect(find.text('00:03'), findsOneWidget);

    await tester.tap(find.byTooltip('Pause'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('00:03'), findsOneWidget);

    await tester.tap(find.byTooltip('Resume'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Recording'), findsOneWidget);
    expect(find.text('00:04'), findsOneWidget);
  });

  testWidgets('stopping saves the recording and follows it to its notes', (
    tester,
  ) async {
    await openRecording(
      tester,
      FakeNotesRepository(),
      processingStep: const Duration(seconds: 1),
    );
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.bySemanticsLabel('Stop recording'));
    await tester.pump();
    await tester.pump(pageTime);
    expect(find.byType(ProcessingScreen), findsOneWidget);
    expect(find.text('Making your notes'), findsOneWidget);

    // Four pretend steps, then the note opens by itself.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(pageTime);
    expect(find.byType(NoteDetailScreen), findsOneWidget);
    expect(find.text('Sample notes for your recording'), findsOneWidget);

    // Back goes to the list, which catches up and shows the finished note.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(NoteDetailScreen), findsNothing);
    expect(find.text('Sample notes for your recording'), findsOneWidget);
    expect(find.text('No notes yet'), findsNothing);
  });

  testWidgets('asks before discarding, and keeps recording on "Keep"', (
    tester,
  ) async {
    final repository = FakeNotesRepository();
    await openRecording(tester, repository);
    await tester.pump(pageTime);

    await tester.tap(find.byTooltip('Discard recording'));
    await tester.pump(dialogTime);
    expect(find.text('Discard this recording?'), findsOneWidget);

    await tester.tap(find.text('Keep recording'));
    await tester.pump(dialogTime);
    expect(find.text('Discard this recording?'), findsNothing);
    expect(find.byType(RecordingScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Discard recording'));
    await tester.pump(dialogTime);
    await tester.tap(find.text('Discard'));
    await tester.pump();
    await tester.pump(pageTime);

    expect(find.byType(RecordingScreen), findsNothing);
    expect(find.text('No notes yet'), findsOneWidget);
  });

  testWidgets('the system back button asks first too', (tester) async {
    await openRecording(tester, FakeNotesRepository());
    await tester.pump(pageTime);

    await tester.binding.handlePopRoute();
    await tester.pump(dialogTime);

    expect(find.text('Discard this recording?'), findsOneWidget);
    expect(find.byType(RecordingScreen), findsOneWidget);
  });

  testWidgets('reminds to tell people, once, before the first recording', (
    tester,
  ) async {
    final preferences = FakeRecordingPreferences(seenConsentReminder: false);
    await openRecording(
      tester,
      FakeNotesRepository(),
      preferences: preferences,
    );
    await tester.pump(pageTime);

    expect(find.text('Let people know'), findsOneWidget);
    expect(find.text('00:00'), findsNothing);

    await tester.tap(find.text('Start recording'));
    await tester.pump(pageTime);

    expect(find.text('Let people know'), findsNothing);
    expect(find.text('Recording'), findsOneWidget);
    expect(preferences.seenConsentReminder, isTrue);
  });

  testWidgets('without the microphone, offers the settings and can close', (
    tester,
  ) async {
    final permission = FakeMicrophonePermission(
      access: MicrophoneAccess.blocked,
    );
    await openRecording(tester, FakeNotesRepository(), permission: permission);
    await tester.pump(pageTime);

    expect(find.text('Microphone access is off'), findsOneWidget);
    await tester.tap(find.text('Open settings'));
    await tester.pump();
    expect(permission.settingsOpened, 1);

    // Nothing was recorded, so closing needs no confirmation.
    await tester.tap(find.byTooltip('Close'));
    await tester.pump();
    await tester.pump(pageTime);
    expect(find.byType(RecordingScreen), findsNothing);
    expect(find.text('No notes yet'), findsOneWidget);
  });

  testWidgets('shows why it paused when the phone interrupts it', (
    tester,
  ) async {
    final recorder = FakeAudioRecorderService(
      tick: const Duration(milliseconds: 100),
    );
    await openRecording(tester, FakeNotesRepository(), recorder: recorder);
    await tester.pump(pageTime);

    recorder.send(RecorderEvent.interrupted);
    await tester.pump(pageTime);

    expect(find.text('Paused'), findsOneWidget);
    expect(find.textContaining('a call or another app'), findsOneWidget);

    recorder.send(RecorderEvent.resumed);
    await tester.pump(pageTime);

    expect(find.text('Recording'), findsOneWidget);
    expect(find.textContaining('a call or another app'), findsNothing);
  });

  testWidgets('warns before the limit, then stops and says why', (
    tester,
  ) async {
    await openRecording(
      tester,
      FakeNotesRepository(),
      limits: const RecordingLimits(
        maxLength: Duration(minutes: 3),
        warnBeforeEnd: Duration(minutes: 2),
      ),
    );

    await tester.pump(const Duration(minutes: 1, seconds: 30));
    expect(find.textContaining('stops by itself in 2 min'), findsOneWidget);

    await tester.pump(const Duration(minutes: 1, seconds: 30));
    await tester.pump(pageTime);
    expect(find.byType(ProcessingScreen), findsOneWidget);
    expect(find.textContaining('reached its 3 min limit'), findsOneWidget);
  });

  testWidgets('keeps recording when the app is left', (tester) async {
    await openRecording(tester, FakeNotesRepository());
    await tester.pump(pageTime);

    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump(const Duration(seconds: 3));
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('Recording'), findsOneWidget);
    expect(find.text('00:04'), findsOneWidget);
  });

  testWidgets('offers the battery settings when they limit recording', (
    tester,
  ) async {
    final background = FakeBackgroundRecording()..isLimited = true;
    await openRecording(tester, FakeNotesRepository(), background: background);
    await tester.pump(pageTime);

    expect(find.textContaining('may stop this recording'), findsOneWidget);
    await tester.tap(find.text('Battery settings'));
    await tester.pump();

    expect(background.batterySettingsOpened, 1);
    expect(find.text('Recording'), findsOneWidget);
  });
}
