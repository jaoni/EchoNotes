import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/widgets/confirm_dialog.dart';

/// Asks before deleting a note. Closes with true to delete.
class DeleteNoteDialog extends StatelessWidget {
  const DeleteNoteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return const ConfirmDialog(
      title: 'Delete this note?',
      message:
          "The note and its recording will be deleted. This can't be undone.",
      cancelLabel: 'Cancel',
      confirmLabel: 'Delete',
    );
  }
}
