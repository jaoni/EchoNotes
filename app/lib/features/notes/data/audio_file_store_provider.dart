import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:echonotes/features/notes/data/local_audio_file_store.dart';
import 'package:echonotes/features/notes/domain/audio_file_store.dart';

/// Where the app keeps its recordings. Tests override it with a fake.
final audioFileStoreProvider = Provider<AudioFileStore>((ref) {
  return LocalAudioFileStore();
});
