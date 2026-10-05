import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/widgets/state_message.dart';

/// Notes couldn't be read. Reassures the user and offers to try again.
class LoadErrorMessage extends StatelessWidget {
  const LoadErrorMessage({
    super.key,
    required this.title,
    required this.onRetry,
  });

  final String title;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return StateMessage(
      icon: Icons.error_outline_rounded,
      isError: true,
      title: title,
      message: 'Your recordings are safe. Please try again.',
      action: FilledButton(onPressed: onRetry, child: const Text('Try again')),
    );
  }
}
