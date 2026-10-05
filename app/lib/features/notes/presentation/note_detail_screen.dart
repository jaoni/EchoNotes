import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:echonotes/features/notes/domain/note_status.dart';
import 'package:echonotes/features/notes/presentation/notes_providers.dart';
import 'package:echonotes/features/notes/presentation/widgets/delete_note_button.dart';
import 'package:echonotes/features/notes/presentation/widgets/load_error_message.dart';
import 'package:echonotes/features/notes/presentation/widgets/missing_note_message.dart';
import 'package:echonotes/features/notes/presentation/widgets/note_detail_view.dart';
import 'package:echonotes/features/notes/presentation/widgets/note_not_ready_message.dart';
import 'package:echonotes/features/playback/presentation/widgets/note_audio_player.dart';

/// A finished note, with the audio player at the bottom.
class NoteDetailScreen extends ConsumerWidget {
  const NoteDetailScreen({super.key, required this.noteId});

  /// Its path under the home route, and the location of one note.
  static const routePath = 'notes/:id';
  static String location(String noteId) => '/notes/$noteId';

  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = ref.watch(noteProvider(noteId));
    final readyNote = note.value?.status == NoteStatus.ready
        ? note.value
        : null;

    return Scaffold(
      appBar: AppBar(
        actions: [if (note.value != null) DeleteNoteButton(noteId: noteId)],
      ),
      body: note.when(
        data: (note) => switch (note) {
          null => const MissingNoteMessage(),
          _ when note.status == NoteStatus.ready => NoteDetailView(note: note),
          _ => NoteNotReadyMessage(noteId: noteId),
        },
        error: (error, stackTrace) => LoadErrorMessage(
          title: "Couldn't open this note",
          onRetry: () => ref.invalidate(noteProvider(noteId)),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      bottomNavigationBar: readyNote == null
          ? null
          : NoteAudioPlayer(
              audioFileName: readyNote.audioFileName,
              duration: readyNote.duration,
            ),
    );
  }
}
