import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:echonotes/features/notes/data/audio_file_store_provider.dart';
import 'package:echonotes/features/notes/data/notes_repository_provider.dart';
import 'package:echonotes/features/recording/data/adts.dart';
import 'package:echonotes/features/recording/data/recording_recovery.dart';
import 'package:echonotes/features/recording/data/recording_service_providers.dart';

/// Recovers recordings cut off when the app last closed, once per launch,
/// and says what it found. The app starts it at its root; a new recording
/// waits for it.
final recordingRecoveryProvider = FutureProvider<RecoveredRecordings>((ref) {
  final recovery = RecordingRecovery(
    ref.watch(notesRepositoryProvider),
    ref.watch(audioFileStoreProvider),
    ref.watch(recordingPreferencesProvider),
    repairFile: repairAdtsFile,
  );
  return recovery.recover();
});
