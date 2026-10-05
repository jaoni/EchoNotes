import 'package:material_ui/material_ui.dart';

/// Type scale: Fraunces for headings, Inter for everything else.
///
/// Widgets use the roles in `context.textTheme` (already colored for the
/// current mode) or the extras below. Override only the color, and take it
/// from the theme; never set a font size or family in a widget.
abstract final class AppTextStyles {
  static const serifFamily = 'Fraunces';
  static const sansFamily = 'Inter';

  /// Even-width digits, so timers and timestamps don't jitter as they change.
  static const tabularFigures = [FontFeature.tabularFigures()];

  static const textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: serifFamily,
      fontSize: 48,
      height: 56 / 48,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.8,
    ),
    displayMedium: TextStyle(
      fontFamily: serifFamily,
      fontSize: 40,
      height: 48 / 40,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.6,
    ),
    displaySmall: TextStyle(
      fontFamily: serifFamily,
      fontSize: 36,
      height: 44 / 36,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
    ),
    headlineLarge: TextStyle(
      fontFamily: serifFamily,
      fontSize: 32,
      height: 40 / 32,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.4,
    ),
    headlineMedium: TextStyle(
      fontFamily: serifFamily,
      fontSize: 28,
      height: 36 / 28,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
    ),
    headlineSmall: TextStyle(
      fontFamily: serifFamily,
      fontSize: 24,
      height: 32 / 24,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    ),
    titleLarge: TextStyle(
      fontFamily: serifFamily,
      fontSize: 20,
      height: 28 / 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
    ),
    titleMedium: TextStyle(
      fontFamily: sansFamily,
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    ),
    titleSmall: TextStyle(
      fontFamily: sansFamily,
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    ),
    bodyLarge: TextStyle(
      fontFamily: sansFamily,
      fontSize: 17,
      height: 26 / 17,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),
    bodyMedium: TextStyle(
      fontFamily: sansFamily,
      fontSize: 15,
      height: 22 / 15,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),
    bodySmall: TextStyle(
      fontFamily: sansFamily,
      fontSize: 13,
      height: 18 / 13,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
    ),
    labelLarge: TextStyle(
      fontFamily: sansFamily,
      fontSize: 15,
      height: 20 / 15,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    ),
    labelMedium: TextStyle(
      fontFamily: sansFamily,
      fontSize: 13,
      height: 16 / 13,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    labelSmall: TextStyle(
      fontFamily: sansFamily,
      fontSize: 11,
      height: 16 / 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.4,
    ),
  );

  /// The recording timer: large, calm digits that stay put as they tick.
  static const timer = TextStyle(
    fontFamily: sansFamily,
    fontSize: 40,
    height: 48 / 40,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.5,
    fontFeatures: tabularFigures,
  );
}
