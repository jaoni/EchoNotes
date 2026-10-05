import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/theme/app_spacing.dart';
import 'package:echonotes/core/theme/theme_context.dart';
import 'package:echonotes/core/widgets/feedback_banner.dart';
import 'package:echonotes/features/design_preview/presentation/widgets/color_swatch_tile.dart';
import 'package:echonotes/features/design_preview/presentation/widgets/preview_section.dart';

/// Every color token for the current mode, then success and error in use.
class ColorsSection extends StatelessWidget {
  const ColorsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final swatches = [
      ('background', colors.background),
      ('card', colors.card),
      ('muted', colors.muted),
      ('border', colors.border),
      ('borderStrong', colors.borderStrong),
      ('textPrimary', colors.textPrimary),
      ('textSecondary', colors.textSecondary),
      ('accent', colors.accent),
      ('onAccent', colors.onAccent),
      ('accentSoft', colors.accentSoft),
      ('success', colors.success),
      ('successSoft', colors.successSoft),
      ('error', colors.error),
      ('onError', colors.onError),
      ('errorSoft', colors.errorSoft),
    ];

    return PreviewSection(
      title: 'Colors',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - AppSpacing.md) / 2;
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  for (final (name, color) in swatches)
                    SizedBox(
                      width: tileWidth,
                      child: ColorSwatchTile(name: name, color: color),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          const FeedbackBanner(
            tone: FeedbackTone.success,
            message: 'Note saved. Your summary is ready.',
          ),
          const SizedBox(height: AppSpacing.sm),
          const FeedbackBanner(
            tone: FeedbackTone.info,
            icon: Icons.timer_outlined,
            message: 'The recording stops by itself in 5 min, at its limit.',
          ),
          const SizedBox(height: AppSpacing.sm),
          FeedbackBanner(
            tone: FeedbackTone.info,
            icon: Icons.battery_alert_outlined,
            message: 'Your phone may stop this recording if you leave the app.',
            actionLabel: 'Battery settings',
            onAction: () {},
          ),
          const SizedBox(height: AppSpacing.sm),
          const FeedbackBanner(
            tone: FeedbackTone.error,
            message: 'Upload failed. Your recording is safe on this phone.',
          ),
        ],
      ),
    );
  }
}
