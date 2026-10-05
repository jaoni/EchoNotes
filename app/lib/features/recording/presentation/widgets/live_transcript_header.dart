import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/theme/theme_context.dart';

/// The title above the live transcript, and what to expect from it.
class LiveTranscriptHeader extends StatelessWidget {
  const LiveTranscriptHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Live preview', style: textTheme.titleSmall),
        Text(
          'A rough preview. The full transcript comes after you stop.',
          style: textTheme.bodySmall?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
