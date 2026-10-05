import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/theme/app_spacing.dart';
import 'package:echonotes/core/widgets/feedback_banner.dart';

/// Processing failed: says so plainly, reassures that the recording is
/// safe, and offers to try again.
class ProcessingFailedPanel extends StatelessWidget {
  const ProcessingFailedPanel({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FeedbackBanner(
          tone: FeedbackTone.error,
          message:
              'Something went wrong while making your notes. Your recording '
              'is still on this phone, so nothing is lost.',
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}
