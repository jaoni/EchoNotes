import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/theme/app_spacing.dart';
import 'package:echonotes/core/theme/app_text_styles.dart';
import 'package:echonotes/core/theme/theme_context.dart';
import 'package:echonotes/core/widgets/tag_chip.dart';
import 'package:echonotes/features/notes/domain/note.dart';
import 'package:echonotes/features/notes/presentation/note_formatting.dart';

/// The top of a note: its title, when and how long, and its tags.
class NoteHeader extends StatelessWidget {
  const NoteHeader({super.key, required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(noteDisplayTitle(note), style: textTheme.headlineMedium),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          noteMetadata(context, note),
          style: textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
            fontFeatures: AppTextStyles.tabularFigures,
          ),
        ),
        if (note.tags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [for (final tag in note.tags) TagChip(label: tag)],
          ),
        ],
      ],
    );
  }
}
