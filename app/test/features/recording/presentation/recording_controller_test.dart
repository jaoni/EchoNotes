import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:echonotes/features/notes/data/audio_file_store_provider.dart';
import 'package:echonotes/features/notes/data/fake_notes_repository.dart';
import 'package:echonotes/features/notes/data/notes_repository_provider.dart';
import 'package:echonotes/features/notes/domain/note.dart';
import 'package:echonotes/features/notes/domain/note_status.dart';
import 'package:echonotes/features/recording/data/recording_recovery.dart';
import 'package:echonotes/features/recording/data/recording_recovery_provider.dart';
import 'package:echonotes/features/recording/data/recording_service_providers.dart';
import 'package:echonotes/features/recording/domain/audio_recorder_service.dart';
import 'package:echonotes/features/recording/domain/background_recording.dart';
import 'package:echonotes/features/recording/domain/microphone_permission.dart';
import 'package:echonotes/features/recording/domain/recording_limits.dart';
import 'package:echonotes/features/recording/presentation/recording_controller.dart';
import 'package:echonotes/features/recording/presentation/recording_state.dart';

import '../../../helpers/fake_audio_file_store.dart';
import '../../../helpers/fake_audio_recorder_service.dart';
import '../../../helpers/fake_recording_services.dart';

/// Fails to finish recordings while [failFinishing] is set.
class _FlakyNotesRepository extends FakeNotesRepository {
  _FlakyNotesRepository({super.notes});

  var failFinishing = false;

  @override
  Future<void> finishRecording(String noteId, Duration duration) async {
    if (failFinishing) throw Exception('Disk I/O error');
    return super.finishRecording(noteId, duration);
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final monday = DateTime(2026, 9, 28, 10);
  const limits = RecordingLimits(
    maxLength: Duration(minutes: 10),
    warnBeforeEnd: Duration(minutes: 1),
    minimumFreeBytes: 1000,
  );

  late _FlakyNotesRepository repository;
  late FakeAudioFileStore audioFiles;
  late FakeAudioRecorderService recorder;
  late FakeMicrophonePermission permission;
  late FakeStorageSpace storage;
  late FakeBackgroundRecording background;
  late FakeRecordingPreferences preferences;
  late ProviderContainer container;

  setUp(() {
    audioFiles = FakeAudioFileStore();
    recorder = FakeAudioRecorderService();
    permission = FakeMicrophonePermission();
    storage = FakeStorageSpace();
    background = FakeBackgroundRecording();
    preferences = FakeRecordingPreferences();
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  tearDown(() {
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  RecordingState state() => container.read(recordingControllerProvider);
  RecordingController controller() {
    return container.read(recordingControllerProvider.notifier);
  }

  Future<Note?> read(String id) => repository.watchNote(id).first;

  /// Opens the recording screen's controller with [notes] saved, and lets
  /// it get going. [recoverable] is the audio in files left by a crash.
  Future<void> open({
    List<Note> notes = const [],
    Map<String, Duration> recoverable = const {},
  }) async {
    repository = _FlakyNotesRepository(notes: notes);
    addTearDown(repository.dispose);
    container = ProviderContainer(
      overrides: [
        notesRepositoryProvider.overrideWithValue(repository),
        audioFileStoreProvider.overrideWithValue(audioFiles),
        audioRecorderServiceProvider.overrideWith((ref) {
          ref.onDispose(recorder.dispose);
          return recorder;
        }),
        microphonePermissionProvider.overrideWithValue(permission),
        storageSpaceProvider.overrideWithValue(storage),
        backgroundRecordingProvider.overrideWithValue(background),
        recordingPreferencesProvider.overrideWithValue(preferences),
        recordingLimitsProvider.overrideWithValue(limits),
        recordingRecoveryProvider.overrideWith((ref) {
          return RecordingRecovery(
            repository,
            audioFiles,
            preferences,
            repairFile: (path) async => recoverable[path] ?? Duration.zero,
          ).recover();
        }),
      ],
    );
    addTearDown(container.dispose);
    container.listen(recordingControllerProvider, (previous, next) {});
    await pumpEventQueue();
  }

  /// The user switches to another app, or locks the phone.
  void leaveApp() {
    binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  }

  void returnToApp() {
    binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  }

  /// Closes the recording screen.
  Future<void> close() async {
    container.dispose();
    await pumpEventQueue();
  }

  group('starting', () {
    test('records at once, in the note made as it starts', () async {
      await open();

      expect(state().phase, RecordingPhase.recording);
      final note = (await read(state().noteId!))!;
      expect(note.status, NoteStatus.recording);
      expect(note.audioFileName, '${note.id}.aac');
      expect(recorder.path, '/recordings/${note.id}.aac');
      expect(recorder.isRecording, isTrue);
      expect(background.isRunning, isTrue);
    });

    test('shows the reminder before the first recording only', () async {
      preferences.seenConsentReminder = false;
      await open();

      expect(state().phase, RecordingPhase.reminder);
      expect(recorder.calls, isEmpty);
      expect(permission.requests, 0);

      await controller().continueAfterReminder();

      expect(state().phase, RecordingPhase.recording);
      expect(preferences.seenConsentReminder, isTrue);
    });

    test('recovers earlier cut-off recordings first, not this one', () async {
      await open(
        notes: [
          Note(
            id: 'cut-off',
            recordedAt: monday,
            duration: Duration.zero,
            status: NoteStatus.recording,
            audioFileName: 'cut-off.aac',
          ),
        ],
        recoverable: {'/recordings/cut-off.aac': const Duration(minutes: 7)},
      );

      final recovered = (await read('cut-off'))!;
      expect(recovered.status, NoteStatus.uploading);
      expect(recovered.duration, const Duration(minutes: 7));
      expect(state().phase, RecordingPhase.recording);
      expect((await read(state().noteId!))!.status, NoteStatus.recording);
    });

    test('says so when the microphone will not start, and can retry', () async {
      recorder.startError = Exception('The microphone is busy');
      await open();

      expect(state().phase, RecordingPhase.couldNotStart);
      expect(await repository.watchNotes().first, isEmpty);

      recorder.startError = null;
      await controller().retry();

      expect(state().phase, RecordingPhase.recording);
    });
  });

  group('microphone access', () {
    test('asks only when it is not allowed yet', () async {
      await open();

      expect(permission.requests, 0);
    });

    test('refused: records nothing, and asking again can allow it', () async {
      permission = FakeMicrophonePermission(access: MicrophoneAccess.denied);
      await open();

      expect(permission.requests, 1);
      expect(state().phase, RecordingPhase.permissionDenied);
      expect(recorder.calls, isEmpty);
      expect(await repository.watchNotes().first, isEmpty);

      permission.afterRequest = MicrophoneAccess.granted;
      await controller().retry();

      expect(state().phase, RecordingPhase.recording);
    });

    test('blocked: opens the settings, and records once it is on', () async {
      permission = FakeMicrophonePermission(
        access: MicrophoneAccess.denied,
        afterRequest: MicrophoneAccess.blocked,
      );
      await open();

      expect(state().phase, RecordingPhase.permissionBlocked);
      await controller().openSettings();
      expect(permission.settingsOpened, 1);

      // The user turns the microphone on in the settings and comes back.
      leaveApp();
      permission.access = MicrophoneAccess.granted;
      returnToApp();
      await pumpEventQueue();

      expect(state().phase, RecordingPhase.recording);
    });
  });

  group('free space', () {
    test('too little: records nothing, and can try again', () async {
      storage.bytes = 900;
      await open();

      expect(state().phase, RecordingPhase.notEnoughSpace);
      expect(recorder.calls, isEmpty);

      storage.bytes = 10 * 1000 * 1000 * 1000;
      await controller().retry();

      expect(state().phase, RecordingPhase.recording);
      expect(state().notice, isNull);
    });

    test('low: records, and says how long it has room for', () async {
      // Room for two minutes at 4000 bytes a second, on top of the minimum.
      storage.bytes = 1000 + 4000 * 120;
      await open();

      expect(state().phase, RecordingPhase.recording);
      expect(state().notice, RecordingNotice.lowSpace);
      expect(state().spaceLeft, const Duration(minutes: 2));
    });

    test('unknown: records anyway', () async {
      storage.bytes = null;
      await open();

      expect(state().phase, RecordingPhase.recording);
      expect(state().notice, isNull);
    });
  });

  group('while recording', () {
    test('counts the recorded audio and draws the voice level', () async {
      await open();

      recorder
        ..addAudio(const Duration(seconds: 3))
        ..addLevel(-30)
        ..addLevel(-100);
      await pumpEventQueue();

      expect(state().elapsed, const Duration(seconds: 3));
      expect(state().levels, [0.5, 0.0]);
    });

    test('pauses and resumes', () async {
      await open();

      await controller().pause();
      expect(state().phase, RecordingPhase.paused);
      expect(recorder.isRecording, isFalse);

      await controller().resume();
      expect(state().phase, RecordingPhase.recording);
      expect(recorder.calls, ['start', 'pause', 'resume']);
    });

    test('stopping saves the note, as long as its audio', () async {
      await open();
      recorder.addAudio(const Duration(minutes: 1, seconds: 5));
      await pumpEventQueue();

      await controller().stop();

      expect(state().phase, RecordingPhase.stopped);
      expect(state().ending, RecordingEnding.byUser);
      expect(recorder.calls.last, 'stop');
      final note = (await read(state().noteId!))!;
      expect(note.status, NoteStatus.uploading);
      expect(note.duration, const Duration(minutes: 1, seconds: 5));
    });

    test('stopping while paused saves it too', () async {
      await open();
      await controller().pause();

      await controller().stop();

      expect(state().phase, RecordingPhase.stopped);
    });

    test('discarding deletes the note, and with it the audio', () async {
      await open();
      final noteId = state().noteId!;

      await controller().discard();

      expect(state().phase, RecordingPhase.discarded);
      expect(recorder.isRecording, isFalse);
      // Deleting a note deletes its audio: see the repository's tests.
      expect(await read(noteId), isNull);
    });

    test('if saving fails, it stays paused and safe until saved', () async {
      await open();
      recorder.addAudio(const Duration(seconds: 40));
      await pumpEventQueue();
      final noteId = state().noteId!;
      repository.failFinishing = true;

      await controller().stop();

      expect(state().phase, RecordingPhase.paused);
      expect(state().notice, RecordingNotice.saveFailed);
      expect(state().canResume, isFalse);
      expect((await read(noteId))!.status, NoteStatus.recording);

      repository.failFinishing = false;
      await controller().stop();

      expect(state().phase, RecordingPhase.stopped);
      expect((await read(noteId))!.duration, const Duration(seconds: 40));
    });
  });

  group('interruptions', () {
    test('a call pauses it, and it carries on after', () async {
      await open();

      recorder.send(RecorderEvent.interrupted);
      await pumpEventQueue();
      expect(state().phase, RecordingPhase.paused);
      expect(state().notice, RecordingNotice.interrupted);

      recorder.send(RecorderEvent.resumed);
      await pumpEventQueue();
      expect(state().phase, RecordingPhase.recording);
      expect(state().notice, isNull);
    });

    test('the user can resume after an interruption', () async {
      await open();
      recorder.send(RecorderEvent.interrupted);
      await pumpEventQueue();

      await controller().resume();

      expect(state().phase, RecordingPhase.recording);
      expect(state().notice, isNull);
    });

    test('says so when resuming fails, and stays paused', () async {
      await open();
      recorder
        ..send(RecorderEvent.interrupted)
        ..resumeError = Exception('A call has the microphone');
      await pumpEventQueue();

      await controller().resume();

      expect(state().phase, RecordingPhase.paused);
      expect(state().notice, RecordingNotice.resumeFailed);
    });

    test('says so when only silence arrives', () async {
      await open();

      for (var i = 0; i < 50; i++) {
        recorder.addLevel(-160);
      }
      await pumpEventQueue();
      expect(state().notice, RecordingNotice.noSound);

      recorder.addLevel(-40);
      await pumpEventQueue();
      expect(state().notice, isNull);
    });
  });

  group('limits', () {
    test('warns before the maximum length, then stops and saves', () async {
      await open();

      recorder.addAudio(const Duration(minutes: 9));
      await pumpEventQueue();
      expect(state().notice, RecordingNotice.limitSoon);

      recorder.addAudio(const Duration(minutes: 1));
      await pumpEventQueue();
      expect(state().phase, RecordingPhase.stopped);
      expect(state().ending, RecordingEnding.limitReached);
      final note = (await read(state().noteId!))!;
      expect(note.duration, const Duration(minutes: 10));
    });

    test('running out of space stops and saves what was recorded', () async {
      await open();
      recorder.addAudio(const Duration(seconds: 12));
      await pumpEventQueue();

      recorder.send(RecorderEvent.outOfSpace);
      await pumpEventQueue();

      expect(state().phase, RecordingPhase.stopped);
      expect(state().ending, RecordingEnding.outOfSpace);
      expect((await read(state().noteId!))!.status, NoteStatus.uploading);
    });
  });

  group('closing the screen', () {
    test('mid-recording keeps what was recorded', () async {
      await open();
      recorder.addAudio(const Duration(seconds: 20));
      await pumpEventQueue();
      final noteId = state().noteId!;

      await close();

      final note = (await read(noteId))!;
      expect(note.status, NoteStatus.uploading);
      expect(note.duration, const Duration(seconds: 20));
      expect(recorder.isDisposed, isTrue);
      expect(background.isRunning, isFalse);
    });

    test('before recording started leaves nothing behind', () async {
      permission = FakeMicrophonePermission(access: MicrophoneAccess.denied);
      await open();

      await close();

      expect(await repository.watchNotes().first, isEmpty);
      expect(background.isRunning, isFalse);
    });
  });

  group('in the background', () {
    test('it keeps recording going from the start', () async {
      await open();

      expect(background.isRunning, isTrue);
      expect(background.isPaused, isFalse);
      expect(background.holdsWakeLock, isTrue);
    });

    test('leaving the app keeps it recording, and remembers that', () async {
      await open();
      final noteId = state().noteId!;

      leaveApp();
      await pumpEventQueue();

      expect(state().phase, RecordingPhase.recording);
      expect(recorder.isRecording, isTrue);
      // If the phone kills the app now, recovery can tell why.
      expect(preferences.noteInBackground, noteId);

      returnToApp();
      await pumpEventQueue();
      expect(preferences.noteInBackground, isNull);
    });

    test('the notification follows pause and resume', () async {
      await open();
      recorder.addAudio(const Duration(minutes: 2));
      await pumpEventQueue();

      await controller().pause();
      await pumpEventQueue();
      expect(background.isPaused, isTrue);
      expect(background.elapsed, const Duration(minutes: 2));

      await controller().resume();
      await pumpEventQueue();
      expect(background.isPaused, isFalse);
    });

    test("the notification's buttons pause, resume and stop it", () async {
      await open();

      background.send(BackgroundRecordingEvent.pause);
      await pumpEventQueue();
      expect(state().phase, RecordingPhase.paused);
      expect(recorder.isRecording, isFalse);

      background.send(BackgroundRecordingEvent.resume);
      await pumpEventQueue();
      expect(state().phase, RecordingPhase.recording);

      background.send(BackgroundRecordingEvent.stop);
      await pumpEventQueue();
      expect(state().phase, RecordingPhase.stopped);
      expect((await read(state().noteId!))!.status, NoteStatus.uploading);
      expect(background.isRunning, isFalse);
    });

    test('stopping in the app leaves nothing to remember', () async {
      await open();
      leaveApp();
      await pumpEventQueue();
      returnToApp();
      leaveApp();
      await pumpEventQueue();

      await controller().stop();
      await pumpEventQueue();

      expect(preferences.noteInBackground, isNull);
    });

    test('asks to show its notification on the first recording', () async {
      preferences.askedToShowNotifications = false;
      await open();

      expect(background.notificationRequests, 1);
      expect(preferences.askedToShowNotifications, isTrue);
      expect(state().phase, RecordingPhase.recording);
    });

    test('never asks again, whatever the answer was', () async {
      await open();

      expect(background.notificationRequests, 0);
    });

    test('warns when battery settings limit EchoNotes there', () async {
      background.isLimited = true;
      await open();

      expect(state().phase, RecordingPhase.recording);
      expect(state().notice, RecordingNotice.limitedInBackground);

      await controller().openBatterySettings();
      expect(background.batterySettingsOpened, 1);
    });

    test("warns when the phone won't keep it going", () async {
      background.startError = Exception('Not allowed in the background');
      await open();

      expect(state().phase, RecordingPhase.recording);
      expect(state().notice, RecordingNotice.limitedInBackground);
    });

    test('warns when the phone stops keeping it going', () async {
      await open();

      background.send(BackgroundRecordingEvent.unavailable);
      await pumpEventQueue();

      expect(state().notice, RecordingNotice.limitedInBackground);
    });

    test(
      'says why it stopped by itself, when the app is out of sight',
      () async {
        await open();
        leaveApp();

        recorder.addAudio(limits.maxLength);
        await pumpEventQueue();

        expect(state().phase, RecordingPhase.stopped);
        expect(background.endedBecause, contains('10 min limit'));
      },
    );

    test('leaves that to the app when it can be seen', () async {
      await open();

      recorder.addAudio(limits.maxLength);
      await pumpEventQueue();

      expect(state().phase, RecordingPhase.stopped);
      expect(background.stops, 1);
      expect(background.endedBecause, isNull);
    });
  });

  group('the phone may sleep again', () {
    // Each way a recording pauses or ends, and none may keep the phone
    // awake.
    final ways = <String, Future<void> Function()>{
      'when paused': () => controller().pause(),
      'when paused from the notification': () async {
        background.send(BackgroundRecordingEvent.pause);
      },
      'when stopped': () => controller().stop(),
      'when discarded': () => controller().discard(),
      'when it stops at its limit': () async {
        recorder.addAudio(limits.maxLength);
      },
      'when the phone runs out of space': () async {
        recorder.send(RecorderEvent.outOfSpace);
      },
      "when the file can't be written": () async {
        recorder.send(RecorderEvent.writeFailed);
      },
      'when a call takes the microphone': () async {
        recorder.send(RecorderEvent.interrupted);
      },
      'when saving fails': () async {
        repository.failFinishing = true;
        await controller().stop();
      },
      'when the screen closes': close,
    };

    for (final MapEntry(key: way, value: act) in ways.entries) {
      test(way, () async {
        await open();
        expect(background.holdsWakeLock, isTrue);

        await act();
        await pumpEventQueue();

        expect(background.holdsWakeLock, isFalse);
      });
    }

    test('and is kept awake again when recording carries on', () async {
      await open();
      recorder.send(RecorderEvent.interrupted);
      await pumpEventQueue();

      recorder.send(RecorderEvent.resumed);
      await pumpEventQueue();

      expect(background.holdsWakeLock, isTrue);
    });

    test('and is never kept awake when recording never started', () async {
      recorder.startError = Exception('The microphone is busy');
      await open();

      expect(state().phase, RecordingPhase.couldNotStart);
      expect(background.holdsWakeLock, isFalse);
    });
  });
}
