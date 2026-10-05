import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:echonotes/features/recording/data/audio_mode_background_recording.dart';
import 'package:echonotes/features/recording/data/channel_storage_space.dart';
import 'package:echonotes/features/recording/data/foreground_service_background_recording.dart';
import 'package:echonotes/features/recording/data/permission_handler_microphone_permission.dart';
import 'package:echonotes/features/recording/data/record_audio_recorder_service.dart';
import 'package:echonotes/features/recording/data/shared_preferences_recording_preferences.dart';
import 'package:echonotes/features/recording/domain/audio_recorder_service.dart';
import 'package:echonotes/features/recording/domain/background_recording.dart';
import 'package:echonotes/features/recording/domain/microphone_permission.dart';
import 'package:echonotes/features/recording/domain/recording_limits.dart';
import 'package:echonotes/features/recording/domain/recording_preferences.dart';
import 'package:echonotes/features/recording/domain/storage_space.dart';

// What recording is built on. Tests override these with fakes.

/// A recorder for one recording session, released when it ends.
final audioRecorderServiceProvider = Provider.autoDispose<AudioRecorderService>(
  (ref) {
    final recorder = RecordAudioRecorderService();
    ref.onDispose(recorder.dispose);
    return recorder;
  },
);

final microphonePermissionProvider = Provider<MicrophonePermission>((ref) {
  return PermissionHandlerMicrophonePermission();
});

final storageSpaceProvider = Provider<StorageSpace>((ref) {
  return ChannelStorageSpace();
});

/// What keeps a recording going in the background: Android's foreground
/// service, or iOS's audio background mode.
final backgroundRecordingProvider = Provider<BackgroundRecording>((ref) {
  return Platform.isAndroid
      ? ForegroundServiceBackgroundRecording()
      : AudioModeBackgroundRecording();
});

final recordingPreferencesProvider = Provider<RecordingPreferences>((ref) {
  return SharedPreferencesRecordingPreferences();
});

/// The longest recording, and the space it needs. Later, this can follow
/// the user's plan.
final recordingLimitsProvider = Provider<RecordingLimits>((ref) {
  return const RecordingLimits();
});
