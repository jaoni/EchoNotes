import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/theme/app_spacing.dart';
import 'package:echonotes/core/theme/app_text_styles.dart';
import 'package:echonotes/core/theme/theme_context.dart';

/// One color token: a swatch, its name in code and its hex value.
class ColorSwatchTile extends StatelessWidget {
  const ColorSwatchTile({super.key, required this.name, required this.color});

  static const _swatchHeight = 56.0;

  final String name;
  final Color color;

  String get _hex {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: color,
            child: const SizedBox(height: _swatchHeight),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: textTheme.labelLarge),
                Text(
                  _hex,
                  style: textTheme.labelMedium?.copyWith(
                    color: context.colors.textSecondary,
                    fontFeatures: AppTextStyles.tabularFigures,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
