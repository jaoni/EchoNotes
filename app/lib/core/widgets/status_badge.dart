import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/theme/app_radius.dart';
import 'package:echonotes/core/theme/app_spacing.dart';
import 'package:echonotes/core/theme/theme_context.dart';

/// How a [StatusBadge] is colored. Color only supports the icon and words.
enum StatusBadgeTone { neutral, error }

/// A small label with an icon for a short status, such as "Transcribing…".
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.icon,
    required this.label,
    this.tone = StatusBadgeTone.neutral,
  });

  static const _iconSize = 16.0;

  final IconData icon;
  final String label;
  final StatusBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isError = tone == StatusBadgeTone.error;
    final foreground = isError ? colors.error : colors.textSecondary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isError ? colors.errorSoft : colors.muted,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.sm)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              // Grows with the text, so the icon stays readable at large sizes.
              size: MediaQuery.textScalerOf(context).scale(_iconSize),
              color: foreground,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                style: context.textTheme.labelMedium?.copyWith(
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
