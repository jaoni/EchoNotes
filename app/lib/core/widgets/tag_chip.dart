import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/theme/app_radius.dart';
import 'package:echonotes/core/theme/app_spacing.dart';
import 'package:echonotes/core/theme/theme_context.dart';

/// A small, quiet label for a note's tag.
class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.sm)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: context.textTheme.labelMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
