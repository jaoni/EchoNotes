import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/theme/app_spacing.dart';
import 'package:echonotes/core/theme/app_text_styles.dart';
import 'package:echonotes/core/theme/theme_context.dart';
import 'package:echonotes/features/design_preview/presentation/widgets/preview_section.dart';

/// Every text style with its name, font, size and line height.
class TypographySection extends StatelessWidget {
  const TypographySection({super.key});

  static const _heading = 'Weekly design sync';
  static const _body =
      'We agreed to ship the recording flow first and to test it on real '
      'phones early.';
  static const _label = 'Today · 24 min';

  /// For example "Fraunces 28/36 · 600".
  static String _describe(TextStyle? style) {
    final size = style?.fontSize ?? 0;
    final lineHeight = (size * (style?.height ?? 1)).round();
    final weight = style?.fontWeight?.value ?? FontWeight.normal.value;
    return '${style?.fontFamily} ${size.round()}/$lineHeight · $weight';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colors = context.colors;
    final samples = [
      ('displaySmall', textTheme.displaySmall, _heading),
      ('headlineLarge', textTheme.headlineLarge, _heading),
      ('headlineMedium', textTheme.headlineMedium, _heading),
      ('headlineSmall', textTheme.headlineSmall, _heading),
      ('titleLarge', textTheme.titleLarge, _heading),
      ('titleMedium', textTheme.titleMedium, _heading),
      ('titleSmall', textTheme.titleSmall, _heading),
      ('bodyLarge', textTheme.bodyLarge, _body),
      ('bodyMedium', textTheme.bodyMedium, _body),
      ('bodySmall', textTheme.bodySmall, _body),
      ('labelLarge', textTheme.labelLarge, _label),
      ('labelMedium', textTheme.labelMedium, _label),
      ('labelSmall', textTheme.labelSmall, _label),
      (
        'AppTextStyles.timer',
        AppTextStyles.timer.copyWith(color: colors.textPrimary),
        '12:34',
      ),
    ];

    return PreviewSection(
      title: 'Typography',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (name, style, sample) in samples)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$name · ${_describe(style)}',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(sample, style: style),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
