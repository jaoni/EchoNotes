import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/formatting/duration_format.dart';
import 'package:echonotes/core/theme/app_spacing.dart';
import 'package:echonotes/core/theme/app_text_styles.dart';
import 'package:echonotes/core/theme/theme_context.dart';
import 'package:echonotes/features/notes/domain/transcript_segment.dart';

/// One stretch of the transcript, with its timestamp above it. Stacked, so
/// it fits narrow screens and large text.
class TranscriptSegmentTile extends StatelessWidget {
  const TranscriptSegmentTile({super.key, required this.segment});

  final TranscriptSegment segment;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatClock(segment.start),
            style: textTheme.labelMedium?.copyWith(
              color: colors.textSecondary,
              fontFeatures: AppTextStyles.tabularFigures,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(segment.text, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}
