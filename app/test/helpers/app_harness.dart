import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:echonotes/app/app.dart';
import 'package:echonotes/app/router.dart';
import 'package:echonotes/features/notes/data/fake_note_processing.dart';
import 'package:echonotes/features/notes/data/fake_notes_repository.dart';
import 'package:echonotes/features/notes/data/note_processing_provider.dart';
import 'package:echonotes/features/notes/data/notes_repository_provider.dart';
import 'package:echonotes/features/notes/data/audio_file_store_provider.dart';
import 'package:echonotes/features/notes/presentation/home_screen.dart';
import 'package:echonotes/features/playback/data/audio_playback_provider.dart';
import 'package:echonotes/features/recording/data/recording_recovery.dart';
import 'package:echonotes/features/recording/data/recording_recovery_provider.dart';
import 'package:echonotes/features/recording/data/recording_service_providers.dart';
import 'package:echonotes/features/recording/domain/recording_limits.dart';

import 'fake_audio_file_store.dart';
import 'fake_audio_playback.dart';
import 'fake_audio_recorder_service.dart';
import 'fake_recording_services.dart';

/// Runs the whole app with [repository] in place of the database, opens
/// [location] and lets the notes load.
///
/// Notes keep the status they have, unless [processingStep] is given: then
/// the pretend processing moves them on, one step each time it passes.
///
/// Nothing touches the phone: recording, background recording, permissions,
/// storage and playback are fakes. Unless given, the recorder records
/// 100 ms of pretend audio every 100 ms, the microphone is allowed, there's
/// plenty of space, and the consent reminder and the notification question
/// are behind us. [playback] gets every player made. With [recovered],
/// launch recovery finds that instead of looking at the notes.
///
/// The repository is disposed with the app, so nothing outlives the test.
Future<void> pumpApp(
  WidgetTester tester, {
  required FakeNotesRepository repository,
  String location = HomeScreen.routePath,
  Duration? processingStep,
  FakeAudioRecorderService? recorder,
  FakeMicrophonePermission? permission,
  FakeStorageSpace? storage,
  FakeRecordingPreferences? preferences,
  FakeBackgroundRecording? background,
  RecordingLimits limits = const RecordingLimits(),
  List<FakeAudioPlayback>? playback,
  RecoveredRecordings? recovered,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        audioFileStoreProvider.overrideWithValue(FakeAudioFileStore()),
        audioRecorderServiceProvider.overrideWith((ref) {
          final service =
              recorder ??
              FakeAudioRecorderService(tick: const Duration(milliseconds: 100));
          ref.onDispose(service.dispose);
          return service;
        }),
        microphonePermissionProvider.overrideWithValue(
          permission ?? FakeMicrophonePermission(),
        ),
        storageSpaceProvider.overrideWithValue(storage ?? FakeStorageSpace()),
        backgroundRecordingProvider.overrideWithValue(
          background ?? FakeBackgroundRecording(),
        ),
        recordingPreferencesProvider.overrideWithValue(
          preferences ?? FakeRecordingPreferences(),
        ),
        recordingLimitsProvider.overrideWithValue(limits),
        if (recovered != null)
          recordingRecoveryProvider.overrideWith((ref) async => recovered),
        audioPlaybackFactoryProvider.overrideWithValue(() {
          final player = FakeAudioPlayback();
          playback?.add(player);
          return player;
        }),
        notesRepositoryProvider.overrideWith((ref) {
          ref.onDispose(repository.dispose);
          return repository;
        }),
        noteProcessingProvider.overrideWith((ref) {
          if (processingStep == null) return;
          final processing = FakeNoteProcessing(
            ref.watch(notesRepositoryProvider),
            stepDuration: processingStep,
          )..start();
          ref.onDispose(processing.dispose);
        }),
      ],
      child: const EchoNotesApp(),
    ),
  );
  if (location != HomeScreen.routePath) {
    ProviderScope.containerOf(tester.element(find.byType(EchoNotesApp)))
        .read(routerProvider)
        .go(location);
  }
  // One frame to build the route, one to show the notes once loaded.
  await tester.pump();
  await tester.pump();
}

/// Pretends to be a small phone (320 × 568, like the first iPhone SE) with
/// text at twice the normal size.
void useSmallPhoneWithLargeText(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 568) * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = 2;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// Turns on the phone's "reduce motion" setting.
void useReducedMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}
