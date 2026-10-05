import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:echonotes/core/theme/app_colors.dart';

/// WCAG AA minimums: normal text, and UI parts such as field outlines.
const _textContrast = 4.5;
const _uiContrast = 3.0;

/// WCAG contrast ratio, from 1 (no contrast) to 21 (black on white).
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (lighter, darker) = la > lb ? (la, lb) : (lb, la);
  return (lighter + 0.05) / (darker + 0.05);
}

List<int> _values(AppColors c) => [
  for (final color in [
    c.background,
    c.card,
    c.muted,
    c.border,
    c.borderStrong,
    c.textPrimary,
    c.textSecondary,
    c.accent,
    c.onAccent,
    c.accentSoft,
    c.success,
    c.successSoft,
    c.error,
    c.onError,
    c.errorSoft,
  ])
    color.toARGB32(),
];

void main() {
  for (final (mode, c) in [
    ('light', AppColors.light),
    ('dark', AppColors.dark),
  ]) {
    group('$mode colors are readable (WCAG AA)', () {
      final textPairs = {
        'textPrimary on background': (c.textPrimary, c.background),
        'textPrimary on card': (c.textPrimary, c.card),
        'textPrimary on muted': (c.textPrimary, c.muted),
        'textPrimary on accentSoft': (c.textPrimary, c.accentSoft),
        'textSecondary on background': (c.textSecondary, c.background),
        'textSecondary on card': (c.textSecondary, c.card),
        'textSecondary on muted': (c.textSecondary, c.muted),
        'accent on background': (c.accent, c.background),
        'accent on card': (c.accent, c.card),
        'onAccent on accent': (c.onAccent, c.accent),
        'success on card': (c.success, c.card),
        'success on successSoft': (c.success, c.successSoft),
        'error on card': (c.error, c.card),
        'error on errorSoft': (c.error, c.errorSoft),
        'onError on error': (c.onError, c.error),
      };
      for (final MapEntry(key: name, value: (fg, bg)) in textPairs.entries) {
        test('$name >= $_textContrast', () {
          expect(_contrast(fg, bg), greaterThanOrEqualTo(_textContrast));
        });
      }

      final uiPairs = {
        'borderStrong on card': (c.borderStrong, c.card),
        'borderStrong on background': (c.borderStrong, c.background),
      };
      for (final MapEntry(key: name, value: (fg, bg)) in uiPairs.entries) {
        test('$name >= $_uiContrast', () {
          expect(_contrast(fg, bg), greaterThanOrEqualTo(_uiContrast));
        });
      }
    });
  }

  group('AppColors', () {
    test('lerp gives each set back at its end', () {
      const light = AppColors.light;
      const dark = AppColors.dark;

      expect(_values(light.lerp(dark, 0)), _values(light));
      expect(_values(light.lerp(dark, 1)), _values(dark));
    });

    test('lerp keeps itself when there is nothing to blend with', () {
      expect(AppColors.light.lerp(null, 0.5), same(AppColors.light));
    });

    test('copyWith changes only the given color', () {
      final copy = AppColors.light.copyWith(accent: AppColors.dark.accent);

      expect(copy.accent, AppColors.dark.accent);
      expect(
        _values(copy.copyWith(accent: AppColors.light.accent)),
        _values(AppColors.light),
      );
    });
  });
}
