import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/theme/app_spacing.dart';
import 'package:echonotes/core/theme/theme_context.dart';
import 'package:echonotes/features/notes/domain/note.dart';
import 'package:echonotes/features/notes/presentation/widgets/action_item_tile.dart';
import 'package:echonotes/features/notes/presentation/widgets/key_point_tile.dart';
import 'package:echonotes/features/notes/presentation/widgets/note_header.dart';
import 'package:echonotes/features/notes/presentation/widgets/note_section_heading.dart';
import 'package:echonotes/features/notes/presentation/widgets/transcript_segment_tile.dart';

/// A finished note, top to bottom: header, summary, key points, action
/// items and the full transcript. Empty parts are left out.
///
/// The transcript is built lazily, so an hour-long recording scrolls
/// smoothly.
class NoteDetailView extends StatelessWidget {
  const NoteDetailView({super.key, required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final transcript = note.transcript;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.page,
            0,
          ),
          sliver: SliverList.list(
            children: [
              NoteHeader(note: note),
              if (note.summary.isNotEmpty) ...[
                const NoteSectionHeading(title: 'Summary'),
                Text(note.summary, style: context.textTheme.bodyLarge),
              ],
              if (note.keyPoints.isNotEmpty) ...[
                const NoteSectionHeading(title: 'Key points'),
                for (final point in note.keyPoints) KeyPointTile(point: point),
              ],
              if (note.actionItems.isNotEmpty) ...[
                const NoteSectionHeading(title: 'Action items'),
                for (final item in note.actionItems)
                  ActionItemTile(
                    key: ValueKey(item.id),
                    noteId: note.id,
                    item: item,
                  ),
              ],
              if (transcript.isNotEmpty)
                const NoteSectionHeading(title: 'Full transcript'),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            AppSpacing.xxl,
          ),
          sliver: SliverList.separated(
            itemCount: transcript.length,
            itemBuilder: (context, index) =>
                TranscriptSegmentTile(segment: transcript[index]),
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.lg),
          ),
        ),
      ],
    );
  }
}
