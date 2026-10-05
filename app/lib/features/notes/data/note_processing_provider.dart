import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:echonotes/features/notes/data/fake_note_processing.dart';
import 'package:echonotes/features/notes/data/notes_repository_provider.dart';

/// Moves notes through processing for as long as the app runs. The app
/// watches it once, at its root, to start it.
///
/// For now it's the pretend backend. The backend step swaps in the real
/// upload and sync here.
final noteProcessingProvider = Provider<void>((ref) {
  final processing = FakeNoteProcessing(ref.watch(notesRepositoryProvider))
    ..start();
  ref.onDispose(processing.dispose);
});
