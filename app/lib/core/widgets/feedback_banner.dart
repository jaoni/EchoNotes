import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/theme/app_radius.dart';
import 'package:echonotes/core/theme/app_spacing.dart';
import 'package:echonotes/core/theme/theme_context.dart';

/// What a [FeedbackBanner] tells the user.
enum FeedbackTone {
  success,

  /// Something to know, such as a warning, that isn't an error.
  info,
  error,
}

/// A message shown in context: always an icon plus words, never color
/// alone. It can offer one action, such as opening a setting.
class FeedbackBanner extends StatelessWidget {
  const FeedbackBanner({
    super.key,
    required this.tone,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final FeedbackTone tone;
  final String message;

  /// Replaces the tone's own icon, to say more about the message.
  final IconData? icon;

  /// A button below the message, shown when [onAction] is set too.
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final actionLabel = this.actionLabel;
    final onAction = this.onAction;
    final (background, foreground, toneIcon) = switch (tone) {
      FeedbackTone.success => (
        colors.successSoft,
        colors.success,
        Icons.check_circle_outline_rounded,
      ),
      FeedbackTone.info => (
        colors.muted,
        colors.textPrimary,
        Icons.info_outline_rounded,
      ),
      FeedbackTone.error => (
        colors.errorSoft,
        colors.error,
        Icons.error_outline_rounded,
      ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon ?? toneIcon, color: foreground),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: foreground,
                    ),
                  ),
                  if (actionLabel != null && onAction != null)
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: foreground),
                      onPressed: onAction,
                      child: Text(actionLabel),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
