import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/theme/theme_context.dart';

/// Asks before something that can't be undone, such as deleting. Closes with
/// true to go ahead, and with false (or null when dismissed) to leave
/// things as they are.
///
/// ```dart
/// final confirmed = await showDialog<bool>(
///   context: context,
///   builder: (context) => const ConfirmDialog(...),
/// );
/// ```
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.confirmLabel,
  });

  final String title;
  final String message;
  final String cancelLabel;

  /// Names the action, such as "Delete", since the color alone can't say
  /// what happens.
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: context.colors.error),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
