import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/theme/app_radius.dart';
import 'package:echonotes/core/theme/app_spacing.dart';
import 'package:echonotes/core/theme/app_text_styles.dart';
import 'package:echonotes/core/theme/theme_context.dart';
import 'package:echonotes/features/design_preview/presentation/widgets/preview_section.dart';

/// The spacing scale as bars, and each corner radius as a box.
class SpacingSection extends StatelessWidget {
  const SpacingSection({super.key});

  static const _labelWidth = 72.0;
  static const _barHeight = 12.0;
  static const _radiusSampleSize = 64.0;

  static const _spacings = [
    ('xs', AppSpacing.xs),
    ('sm', AppSpacing.sm),
    ('md', AppSpacing.md),
    ('lg', AppSpacing.lg),
    ('xl', AppSpacing.xl),
    ('xxl', AppSpacing.xxl),
    ('xxxl', AppSpacing.xxxl),
  ];

  static const _radii = [
    ('sm', AppRadius.sm),
    ('md', AppRadius.md),
    ('lg', AppRadius.lg),
    ('xl', AppRadius.xl),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final labelStyle = context.textTheme.labelMedium?.copyWith(
      color: colors.textSecondary,
      fontFeatures: AppTextStyles.tabularFigures,
    );

    return PreviewSection(
      title: 'Spacing and corners',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (name, value) in _spacings)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  SizedBox(
                    width: _labelWidth,
                    child: Text('$name ${value.round()}', style: labelStyle),
                  ),
                  Container(
                    width: value,
                    height: _barHeight,
                    color: colors.accent,
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            children: [
              for (final (name, value) in _radii)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: _radiusSampleSize,
                      height: _radiusSampleSize,
                      decoration: BoxDecoration(
                        color: colors.card,
                        border: Border.all(color: colors.borderStrong),
                        borderRadius: BorderRadius.circular(value),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('$name ${value.round()}', style: labelStyle),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
