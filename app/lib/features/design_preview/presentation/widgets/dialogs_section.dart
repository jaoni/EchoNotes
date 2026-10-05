import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/widgets/confirm_dialog.dart';
import 'package:echonotes/features/design_preview/presentation/widgets/preview_section.dart';

/// The dialog that asks before something is deleted or thrown away.
class DialogsSection extends StatelessWidget {
  const DialogsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return PreviewSection(
      title: 'Dialogs',
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: OutlinedButton(
          onPressed: () => _showConfirmDialog(context),
          child: const Text('Show confirm dialog'),
        ),
      ),
    );
  }

  void _showConfirmDialog(BuildContext context) {
    // Dialogs open above this screen, so hand them the theme picked here.
    final theme = Theme.of(context);
    showDialog<bool>(
      context: context,
      builder: (context) => Theme(
        data: theme,
        child: const ConfirmDialog(
          title: 'Delete this note?',
          message:
              "The note and its recording will be deleted. This can't be "
              'undone.',
          cancelLabel: 'Cancel',
          confirmLabel: 'Delete',
        ),
      ),
    );
  }
}
