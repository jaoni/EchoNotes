import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:echonotes/core/database/app_database_provider.dart';
import 'package:echonotes/features/notes/data/audio_file_store_provider.dart';
import 'package:echonotes/features/notes/data/drift_notes_repository.dart';
import 'package:echonotes/features/notes/data/sample_notes.dart';
import 'package:echonotes/features/notes/domain/notes_repository.dart';

/// The notes repository the whole app uses: the app's database.
///
/// Debug builds fill an empty database with the sample notes, so every
/// screen has something to show. Tests override this with
/// `FakeNotesRepository`.
final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  final repository = DriftNotesRepository(
    ref.watch(appDatabaseProvider),
    audioFiles: ref.watch(audioFileStoreProvider),
  );
  if (kDebugMode) unawaited(_addSampleNotesIfEmpty(repository));
  return repository;
});

Future<void> _addSampleNotesIfEmpty(DriftNotesRepository repository) async {
  try {
    await repository.seedIfEmpty(sampleNotes(DateTime.now()));
  } catch (error, stackTrace) {
    developer.log(
      "Couldn't add the sample notes",
      name: 'echonotes.notes',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
