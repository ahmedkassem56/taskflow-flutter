/// Material 3 theme built from the backend design tokens (DESIGN.md §9).
library;

import 'package:flutter/material.dart';

/// Accent indigo — light mode (#5E6AD2).
const Color kAccentLight = Color(0xFF5E6AD2);

/// Accent indigo — dark mode (#6B77E0).
const Color kAccentDark = Color(0xFF6B77E0);

/// App background — light mode (#FAFAFB).
const Color kBackgroundLight = Color(0xFFFAFAFB);

/// App background — dark mode (#0F0F13).
const Color kBackgroundDark = Color(0xFF0F0F13);

/// Priority / danger red (Radix red 9).
const Color kPriorityHigh = Color(0xFFE5484D);

/// Priority medium amber (Radix amber 11).
const Color kPriorityMedium = Color(0xFFB25E09);

/// Priority low green (Radix green 9).
const Color kPriorityLow = Color(0xFF30A46C);

/// Priority chip color for the given wire priority name.
///
/// Returns `null` for `none`/unknown so callers can omit the chip entirely.
Color? priorityColor(String priority) {
  switch (priority) {
    case 'high':
      return kPriorityHigh;
    case 'medium':
      return kPriorityMedium;
    case 'low':
      return kPriorityLow;
    default:
      return null;
  }
}

/// Light Material 3 [ColorScheme] from the design tokens.
ColorScheme buildLightColorScheme() {
  final ColorScheme seeded = ColorScheme.fromSeed(
    seedColor: kAccentLight,
    brightness: Brightness.light,
  );
  return seeded.copyWith(
    primary: kAccentLight,
    onPrimary: const Color(0xFFFFFFFF),
    primaryContainer: const Color(0xFFE3E6FB),
    onPrimaryContainer: const Color(0xFF2A2F6B),
    secondary: kAccentLight,
    onSecondary: const Color(0xFFFFFFFF),
    secondaryContainer: const Color(0xFFE3E6FB),
    onSecondaryContainer: const Color(0xFF2A2F6B),
    surface: kBackgroundLight,
    onSurface: const Color(0xFF1B1B20),
    surfaceContainerHighest: const Color(0xFFECECF0),
    onSurfaceVariant: const Color(0xFF4A4A52),
    outline: const Color(0xFFC9C9D1),
    error: kPriorityHigh,
    onError: const Color(0xFFFFFFFF),
    errorContainer: const Color(0xFFFFE0E0),
    onErrorContainer: const Color(0xFF7A1F22),
  );
}

/// Dark Material 3 [ColorScheme] from the design tokens.
ColorScheme buildDarkColorScheme() {
  final ColorScheme seeded = ColorScheme.fromSeed(
    seedColor: kAccentDark,
    brightness: Brightness.dark,
  );
  return seeded.copyWith(
    primary: kAccentDark,
    onPrimary: const Color(0xFF16161C),
    primaryContainer: const Color(0xFF32376E),
    onPrimaryContainer: const Color(0xFFDDE0FB),
    secondary: kAccentDark,
    onSecondary: const Color(0xFF16161C),
    secondaryContainer: const Color(0xFF32376E),
    onSecondaryContainer: const Color(0xFFDDE0FB),
    surface: kBackgroundDark,
    onSurface: const Color(0xFFE8E8EE),
    surfaceContainerHighest: const Color(0xFF22222A),
    onSurfaceVariant: const Color(0xFF9E9EA9),
    outline: const Color(0xFF3F3F48),
    error: const Color(0xFFF2555A),
    onError: const Color(0xFF2B0B0C),
    errorContainer: const Color(0xFF4A1618),
    onErrorContainer: const Color(0xFFFFDADB),
  );
}

/// Full [ThemeData] for one brightness, with Material 3 enabled.
ThemeData buildAppTheme(Brightness brightness) {
  final ColorScheme scheme = brightness == Brightness.dark
      ? buildDarkColorScheme()
      : buildLightColorScheme();

  final ThemeData base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
  );

  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: 0.6),
      space: 1,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: brightness == Brightness.dark
          ? const Color(0xFF2A2A33)
          : const Color(0xFF2A2A33),
      contentTextStyle: TextStyle(color: const Color(0xFFF5F5F7)),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.secondaryContainer,
      selectedIconTheme: IconThemeData(color: scheme.onSecondaryContainer),
      selectedLabelTextStyle: TextStyle(
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: scheme.onSurfaceVariant,
        fontSize: 13,
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: scheme.onSurfaceVariant,
      textColor: scheme.onSurface,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: brightness == Brightness.dark
          ? const Color(0xFF191920)
          : const Color(0xFFF1F1F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: scheme.surfaceContainerHighest,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: TextStyle(
        color: scheme.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
