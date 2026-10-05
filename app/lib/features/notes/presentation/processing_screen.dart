import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:echonotes/features/notes/domain/note_status.dart';
import 'package:echonotes/features/notes/presentation/note_detail_screen.dart';
import 'package:echonotes/features/notes/presentation/notes_providers.dart';
import 'package:echonotes/features/notes/presentation/widgets/load_error_message.dart';
import 'package:echonotes/features/notes/presentation/widgets/missing_note_message.dart';
import 'package:echonotes/features/notes/presentation/widgets/processing_view.dart';

/// Follows a recording while it's uploaded, transcribed and turned into
/// notes. Opens the note by itself once it's ready.
class ProcessingScreen extends ConsumerWidget {
  const ProcessingScreen({super.key, required this.noteId});

  /// Its path under the home route, and the location for one note.
  static const routePath = 'processing/:id';
  static String location(String noteId) => '/processing/$noteId';

  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(noteProvider(noteId), (previous, next) {
      final wasReady = previous?.value?.status == NoteStatus.ready;
      final isReady = next.value?.status == NoteStatus.ready;
      if (isReady && !wasReady) {
        // Replaces this screen, so back goes to the list.
        context.go(NoteDetailScreen.location(noteId));
      }
    });
    final note = ref.watch(noteProvider(noteId));

    return Scaffold(
      appBar: AppBar(),
      body: note.when(
        data: (note) => note == null
            ? const MissingNoteMessage()
            : ProcessingView(note: note),
        error: (error, stackTrace) => LoadErrorMessage(
          title: "Couldn't open this note",
          onRetry: () => ref.invalidate(noteProvider(noteId)),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
