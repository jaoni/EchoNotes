import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:echonotes/core/theme/app_colors.dart';
import 'package:echonotes/core/theme/app_text_styles.dart';
import 'package:echonotes/core/theme/app_theme.dart';

void main() {
  for (final (mode, theme, colors, brightness) in [
    ('light', AppTheme.light, AppColors.light, Brightness.light),
    ('dark', AppTheme.dark, AppColors.dark, Brightness.dark),
  ]) {
    group('$mode theme', () {
      test('is built from its own color set', () {
        expect(theme.brightness, brightness);
        expect(theme.extension<AppColors>(), same(colors));
        expect(theme.scaffoldBackgroundColor, colors.background);
        expect(theme.colorScheme.primary, colors.accent);
        expect(theme.colorScheme.onSurface, colors.textPrimary);
        expect(theme.colorScheme.error, colors.error);
      });

      test('sets headings in Fraunces and everything else in Inter', () {
        final text = theme.textTheme;

        for (final style in [
          text.displaySmall,
          text.headlineMedium,
          text.titleLarge,
        ]) {
          expect(style?.fontFamily, AppTextStyles.serifFamily);
        }
        for (final style in [
          text.titleMedium,
          text.bodyLarge,
          text.bodyMedium,
          text.labelLarge,
        ]) {
          expect(style?.fontFamily, AppTextStyles.sansFamily);
        }
        expect(text.bodyMedium?.color, colors.textPrimary);
      });
    });
  }
}
