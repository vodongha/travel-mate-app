import 'package:flutter/material.dart';

/// A modern, friendly Material 3 theme: seeded from the brand indigo, typeset in Plus Jakarta Sans,
/// with rounded cards, filled inputs, pill buttons and a fully themed component set (navigation,
/// FAB, chips, dialogs, sheets, snackbars). The same look on Android and web, light and dark.
class AppTheme {
  const AppTheme._();

  /// Brand indigo — matches the launcher icon / web theme color so the OS chrome, splash and UI
  /// all read as one product.
  static const Color _seed = Color(0xFF4F46E5);

  /// The bundled variable font (declared in pubspec). Applied to the whole text theme.
  static const String _fontFamily = 'PlusJakartaSans';

  /// Shared corner radius for all buttons (filled, outlined, and the web Google button).
  static const BorderRadius buttonRadius =
      BorderRadius.all(Radius.circular(14));

  /// Shared height for all primary form buttons (and the web Google button row),
  /// so they all line up. Mirrored by FormButtons and the button themes below.
  static const double buttonHeight = 50;

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    // A deep, slightly blue-tinted neutral for dark mode reads richer and friendlier than the
    // default near-black; light mode gets a soft off-white so cards (white-ish containers) lift
    // off the page instead of disappearing into it.
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
      surface: isDark ? const Color(0xFF14151A) : const Color(0xFFF7F8FB),
    );

    final TextTheme textTheme = _textTheme(scheme);
    final OutlineInputBorder inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: _fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 2,
        elevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surfaceTint,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
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
        floatingLabelStyle: TextStyle(color: scheme.primary),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
      ),

      // All buttons share one shape (radius 14) + height so Save / Cancel / Add / Delete and the
      // Google button line up. M3's default OutlinedButton is a pill, which is why Cancel/Google
      // looked different from the filled primary before.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(buttonHeight),
          shape: const RoundedRectangleBorder(borderRadius: buttonRadius),
          textStyle: textTheme.labelLarge
              ?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(buttonHeight),
          shape: const RoundedRectangleBorder(borderRadius: buttonRadius),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: textTheme.labelLarge
              ?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle:
              textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      // Pill FAB with a confident primary-container fill.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 1,
        focusElevation: 1,
        hoverElevation: 2,
        highlightElevation: 2,
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Tonal, rounded chips with no harsh outline.
      chipTheme: ChipThemeData(
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        secondaryLabelStyle:
            textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        selectedColor: scheme.secondaryContainer,
        checkmarkColor: scheme.onSecondaryContainer,
      ),

      // Bottom navigation (M3) — pill indicator, labels always shown.
      navigationBarTheme: NavigationBarThemeData(
        elevation: 2,
        height: 68,
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surfaceTint,
        indicatorColor: scheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.onSecondaryContainer),
        selectedLabelTextStyle:
            textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelTextStyle:
            textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),

      // Sheets & dialogs — generous rounding, no surface-tint colour shift.
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle:
            textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Floating, rounded snackbars read more modern than the default edge-to-edge bar.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        iconColor: scheme.onSurfaceVariant,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: textTheme.titleSmall,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle:
            textTheme.bodySmall?.copyWith(color: scheme.onInverseSurface),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      popupMenuTheme: PopupMenuThemeData(
        surfaceTintColor: Colors.transparent,
        color: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  /// Apply Plus Jakarta Sans across the M3 typescale, nudging weights and letter-spacing toward a
  /// friendlier, more confident feel (display/headline a touch tighter and bolder; body relaxed).
  static TextTheme _textTheme(ColorScheme scheme) {
    final TextTheme base = (scheme.brightness == Brightness.dark
            ? Typography.material2021().white
            : Typography.material2021().black)
        .apply(fontFamily: _fontFamily);
    return base.copyWith(
      displaySmall: base.displaySmall
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineMedium: base.headlineMedium
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.4),
      headlineSmall: base.headlineSmall
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleLarge: base.titleLarge
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: base.bodyLarge?.copyWith(height: 1.4),
      bodyMedium: base.bodyMedium?.copyWith(height: 1.4),
    );
  }
}
