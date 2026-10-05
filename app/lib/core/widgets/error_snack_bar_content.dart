import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/theme/app_spacing.dart';

/// What goes inside a snack bar that reports a problem: an icon and the
/// message, so the error never relies on color.
///
/// ```dart
/// ScaffoldMessenger.of(context).showSnackBar(
///   const SnackBar(content: ErrorSnackBarContent(message: "Couldn't save.")),
/// );
/// ```
class ErrorSnackBarContent extends StatelessWidget {
  const ErrorSnackBarContent({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    // Snack bars sit on the inverse surface, so match their text color.
    final color = Theme.of(context).colorScheme.onInverseSurface;

    return Row(
      children: [
        Icon(Icons.error_outline_rounded, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(message)),
      ],
    );
  }
}
