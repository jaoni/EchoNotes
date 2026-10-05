import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';

import 'package:echonotes/core/theme/app_spacing.dart';
import 'package:echonotes/core/theme/app_text_styles.dart';
import 'package:echonotes/core/theme/theme_context.dart';
import 'package:echonotes/core/widgets/tag_chip.dart';

/// A note in a list: when it was recorded, its title, an optional status
/// badge, a short summary and its tags. Takes plain values so it doesn't
/// depend on the notes model.
class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.title,
    required this.metadata,
    this.badge,
    this.summary = '',
    this.tags = const [],
    this.onTap,
    this.onLongPress,
    this.longPressLabel,
  });

  static const _titleMaxLines = 2;
  static const _summaryMaxLines = 2;

  final String title;

  /// Already formatted date and length, such as "Today · 9:30 AM · 24 min".
  final String metadata;

  /// Shown under the title, such as a `StatusBadge` while notes are being
  /// written or when that failed.
  final Widget? badge;

  /// Hidden when empty, for example while the note is still being written.
  final String summary;
  final List<String> tags;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// What [onLongPress] does, such as "Delete note". Screen readers offer it
  /// as an action on the card.
  final String? longPressLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;
    final badge = this.badge;
    final onLongPress = this.onLongPress;
    final longPressLabel = this.longPressLabel;

    return Card(
      child: Semantics(
        onLongPressHint: longPressLabel,
        customSemanticsActions: onLongPress == null || longPressLabel == null
            ? null
            : {CustomSemanticsAction(label: longPressLabel): onLongPress},
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metadata,
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                    fontFeatures: AppTextStyles.tabularFigures,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  title,
                  style: textTheme.titleLarge,
                  maxLines: _titleMaxLines,
                  overflow: TextOverflow.ellipsis,
                ),
                if (badge != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  badge,
                ],
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    summary,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                    maxLines: _summaryMaxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [for (final tag in tags) TagChip(label: tag)],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
