import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:echonotes/core/theme/app_motion.dart';
import 'package:echonotes/core/theme/app_spacing.dart';
import 'package:echonotes/core/theme/app_text_styles.dart';
import 'package:echonotes/core/theme/theme_context.dart';
import 'package:echonotes/core/widgets/error_snack_bar_content.dart';
import 'package:echonotes/features/notes/data/notes_repository_provider.dart';
import 'package:echonotes/features/notes/domain/note.dart';
import 'package:echonotes/features/notes/domain/note_status.dart';
import 'package:echonotes/features/notes/presentation/note_formatting.dart';
import 'package:echonotes/features/notes/presentation/widgets/processing_failed_panel.dart';
import 'package:echonotes/features/notes/presentation/widgets/processing_steps.dart';

/// A recording's progress towards finished notes, or why it stopped.
class ProcessingView extends ConsumerWidget {
  const ProcessingView({super.key, required this.note});

  final Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = context.textTheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final status = note.status;
    final hasFailed = status == NoteStatus.failed;

    final title = switch (status) {
      NoteStatus.failed => "We couldn't finish your notes",
      NoteStatus.ready => 'Your notes are ready',
      _ => 'Making your notes',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.sm,
        AppSpacing.page,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            liveRegion: true,
            child: Text(title, style: textTheme.headlineMedium),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            noteMetadata(context, note),
            style: textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              fontFeatures: AppTextStyles.tabularFigures,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AnimatedSwitcher(
            duration: reduceMotion ? Duration.zero : AppMotion.medium,
            child: hasFailed
                ? ProcessingFailedPanel(
                    key: const ValueKey('failed'),
                    onRetry: () => _retry(context, ref),
                  )
                : ProcessingSteps(key: const ValueKey('steps'), status: status),
          ),
          if (status.isProcessing) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(
              'This usually takes a minute or two. You can leave this '
              "screen: we'll keep going and your note will appear in the list.",
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _retry(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(notesRepositoryProvider).retryProcessing(note.id);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: ErrorSnackBarContent(
            message: "Couldn't start again. Please try once more.",
          ),
        ),
      );
    }
  }
}
