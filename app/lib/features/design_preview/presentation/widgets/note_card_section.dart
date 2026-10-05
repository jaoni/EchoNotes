import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/theme/app_spacing.dart';
import 'package:echonotes/core/widgets/note_card.dart';
import 'package:echonotes/core/widgets/status_badge.dart';
import 'package:echonotes/features/design_preview/presentation/widgets/preview_section.dart';

/// A finished note, one whose notes are still being written, and one whose
/// processing failed.
class NoteCardSection extends StatelessWidget {
  const NoteCardSection({super.key});

  @override
  Widget build(BuildContext context) {
    return PreviewSection(
      title: 'Note card',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NoteCard(
            title: 'Weekly design sync',
            metadata: 'Today · 9:30 AM · 24 min',
            summary:
                'The team agreed to ship the recording flow first. Maya will '
                'test long recordings on real phones, and the note layout is '
                'reviewed again next week.',
            tags: const ['design', 'planning', 'mobile'],
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.md),
          NoteCard(
            title: 'New recording',
            metadata: 'Just now · 3 min',
            badge: const StatusBadge(
              icon: Icons.edit_note_rounded,
              label: 'Writing notes…',
            ),
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.md),
          NoteCard(
            title: 'New recording',
            metadata: 'Yesterday · 6:40 PM · 7 min',
            badge: const StatusBadge(
              icon: Icons.error_outline_rounded,
              label: "Couldn't finish · Tap to retry",
              tone: StatusBadgeTone.error,
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
