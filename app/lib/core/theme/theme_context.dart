import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/theme/app_colors.dart';

/// Short access to the theme from a widget: `context.colors.accent`,
/// `context.textTheme.bodyMedium`.
extension ThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;

  TextTheme get textTheme => Theme.of(this).textTheme;
}
