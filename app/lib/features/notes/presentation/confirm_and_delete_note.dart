import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:echonotes/core/widgets/error_snack_bar_content.dart';
import 'package:echonotes/features/notes/data/notes_repository_provider.dart';
import 'package:echonotes/features/notes/presentation/widgets/delete_note_dialog.dart';

/// Asks first, then deletes the note and its recording. Says so in a snack
/// bar if deleting fails.
///
/// A screen that shows the note passes [leave], which navigates away and
/// completes once the screen is gone. Only then is the note deleted, so the
/// screen never shows it as missing on its way out.
Future<void> confirmAndDeleteNote(
  BuildContext context,
  WidgetRef ref, {
  required String noteId,
  Future<void> Function()? leave,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => const DeleteNoteDialog(),
  );
  if (confirmed != true || !context.mounted) return;

  // Taken now, while the screen is still here: leave() closes it.
  final repository = ref.read(notesRepositoryProvider);
  final messenger = ScaffoldMessenger.of(context);
  await leave?.call();

  try {
    await repository.deleteNote(noteId);
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(
        content: ErrorSnackBarContent(
          message: "Couldn't delete the note. Please try again.",
        ),
      ),
    );
  }
}
