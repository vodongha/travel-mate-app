import 'package:flutter/material.dart';

/// A modern Material 3 theme seeded from a travel-blue, with rounded cards, filled inputs and
/// pill-shaped buttons — the same look on Android and web.
class AppTheme {
  const AppTheme._();

  static const Color _seed = Color(0xFF1E6FE0);

  /// Shared corner radius for all buttons (filled, outlined, and the web Google button).
  static const BorderRadius buttonRadius =
      BorderRadius.all(Radius.circular(14));

  /// Shared height for all primary form buttons (and the web Google button row),
  /// so they all line up. Mirrored by FormButtons and the button themes below.
  static const double buttonHeight = 50;

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final ColorScheme scheme =
        ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
    final OutlineInputBorder inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 1,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
      // All buttons share one shape (radius 14) + height so Save / Cancel / Add / Delete and the
      // Google button line up. M3's default OutlinedButton is a pill, which is why Cancel/Google
      // looked different from the filled primary before.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: const RoundedRectangleBorder(borderRadius: buttonRadius),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: const RoundedRectangleBorder(borderRadius: buttonRadius),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: const ChipThemeData(side: BorderSide.none),
    );
  }
}
