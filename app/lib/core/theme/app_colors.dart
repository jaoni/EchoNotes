import 'package:material_ui/material_ui.dart';

/// The "Paper & Ink" colors, one set per brightness.
///
/// Widgets read these with `context.colors` so they follow light and dark
/// mode. Never put a raw `Color(...)` in a widget: add a token here instead,
/// in both sets, and keep text at WCAG AA contrast (see app_colors_test.dart).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.card,
    required this.muted,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.success,
    required this.successSoft,
    required this.error,
    required this.onError,
    required this.errorSoft,
  });

  /// Warm paper and ink.
  static const light = AppColors(
    background: Color(0xFFF6F2EA),
    card: Color(0xFFFFFDF8),
    muted: Color(0xFFEDE7DB),
    border: Color(0xFFE4DCCF),
    borderStrong: Color(0xFF8C8478),
    textPrimary: Color(0xFF1D1B18),
    textSecondary: Color(0xFF5F584E),
    accent: Color(0xFFB8432A),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFF5DFD5),
    success: Color(0xFF2A7248),
    successSoft: Color(0xFFE1EEE4),
    error: Color(0xFFA8201A),
    onError: Color(0xFFFFFFFF),
    errorSoft: Color(0xFFF8DFDB),
  );

  /// Lamplight: warm near-black, never blue-black.
  static const dark = AppColors(
    background: Color(0xFF15130F),
    card: Color(0xFF201D18),
    muted: Color(0xFF2C2821),
    border: Color(0xFF35302A),
    borderStrong: Color(0xFF7A7266),
    textPrimary: Color(0xFFEEE8DC),
    textSecondary: Color(0xFFA69E90),
    accent: Color(0xFFF0845F),
    onAccent: Color(0xFF1D1B18),
    accentSoft: Color(0xFF3E261C),
    success: Color(0xFF74C995),
    successSoft: Color(0xFF1C2D22),
    error: Color(0xFFFF8C82),
    onError: Color(0xFF1D1B18),
    errorSoft: Color(0xFF3D1F1B),
  );

  /// The page behind everything.
  final Color background;

  /// Cards, sheets, dialogs and text fields.
  final Color card;

  /// Quiet fills: tags, tonal buttons.
  final Color muted;

  /// Hairline dividers and card outlines. Decorative only.
  final Color border;

  /// Outlines that must be seen, such as text fields (at least 3:1).
  final Color borderStrong;

  /// Main text and icons.
  final Color textPrimary;

  /// Supporting text: dates, captions, hints.
  final Color textSecondary;

  /// The one accent: record button, primary buttons, links.
  final Color accent;

  /// Text and icons on [accent].
  final Color onAccent;

  /// Tinted fill for selected or highlighted accent areas.
  final Color accentSoft;

  /// Success text and icons.
  final Color success;

  /// Background behind a success message.
  final Color successSoft;

  /// Error text and icons. Close in hue to [accent], so always show it with
  /// an icon and a message, never color alone.
  final Color error;

  /// Text and icons on [error].
  final Color onError;

  /// Background behind an error message.
  final Color errorSoft;

  @override
  AppColors copyWith({
    Color? background,
    Color? card,
    Color? muted,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? accent,
    Color? onAccent,
    Color? accentSoft,
    Color? success,
    Color? successSoft,
    Color? error,
    Color? onError,
    Color? errorSoft,
  }) {
    return AppColors(
      background: background ?? this.background,
      card: card ?? this.card,
      muted: muted ?? this.muted,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentSoft: accentSoft ?? this.accentSoft,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      error: error ?? this.error,
      onError: onError ?? this.onError,
      errorSoft: errorSoft ?? this.errorSoft,
    );
  }

  /// Blends two sets, so switching light and dark mode animates smoothly.
  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      error: Color.lerp(error, other.error, t)!,
      onError: Color.lerp(onError, other.onError, t)!,
      errorSoft: Color.lerp(errorSoft, other.errorSoft, t)!,
    );
  }
}
