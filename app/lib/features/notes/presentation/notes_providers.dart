import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:echonotes/features/notes/data/notes_repository_provider.dart';
import 'package:echonotes/features/notes/domain/note.dart';

/// Every note, newest first, kept up to date.
final notesProvider = StreamProvider<List<Note>>((ref) {
  return ref.watch(notesRepositoryProvider).watchNotes();
});

/// One note by id, kept up to date. Null when it doesn't exist.
final noteProvider = StreamProvider.autoDispose.family<Note?, String>((
  ref,
  id,
) {
  return ref.watch(notesRepositoryProvider).watchNote(id);
});
