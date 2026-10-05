import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:echonotes/features/notes/presentation/confirm_and_delete_note.dart';
import 'package:echonotes/features/notes/presentation/home_screen.dart';

/// Deletes the note on screen. Asks first; once the user says yes, goes
/// back to the list and deletes the note from there.
class DeleteNoteButton extends ConsumerWidget {
  const DeleteNoteButton({super.key, required this.noteId});

  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Delete note',
      icon: const Icon(Icons.delete_outline_rounded),
      onPressed: () => confirmAndDeleteNote(
        context,
        ref,
        noteId: noteId,
        leave: () => _backToList(context),
      ),
    );
  }

  /// Goes back to the list, and completes once this screen is gone.
  Future<void> _backToList(BuildContext context) async {
    final route = ModalRoute.of(context);
    context.go(HomeScreen.routePath);
    await route?.completed;
  }
}
