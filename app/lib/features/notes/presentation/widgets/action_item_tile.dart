import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:echonotes/core/theme/theme_context.dart';
import 'package:echonotes/core/widgets/error_snack_bar_content.dart';
import 'package:echonotes/features/notes/data/notes_repository_provider.dart';
import 'package:echonotes/features/notes/domain/action_item.dart';

/// An action item the user can tick off. The change goes through the
/// repository, and the note on screen updates from there.
class ActionItemTile extends ConsumerWidget {
  const ActionItemTile({super.key, required this.noteId, required this.item});

  final String noteId;
  final ActionItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return CheckboxListTile(
      value: item.isDone,
      onChanged: (isDone) => _setDone(context, ref, isDone: isDone ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      title: Text(
        item.text,
        style: context.textTheme.bodyLarge?.copyWith(
          color: item.isDone ? colors.textSecondary : colors.textPrimary,
        ),
      ),
    );
  }

  Future<void> _setDone(
    BuildContext context,
    WidgetRef ref, {
    required bool isDone,
  }) async {
    try {
      await ref
          .read(notesRepositoryProvider)
          .setActionItemDone(
            noteId: noteId,
            actionItemId: item.id,
            isDone: isDone,
          );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: ErrorSnackBarContent(
            message: "Couldn't update this item. Please try again.",
          ),
        ),
      );
    }
  }
}
