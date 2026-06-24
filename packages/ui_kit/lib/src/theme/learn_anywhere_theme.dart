import 'package:flutter/material.dart';

import 'learn_anywhere_tokens.dart';

/// Shared light and dark theme definitions for Learn Anywhere shells.
final class LearnAnywhereTheme {
  const LearnAnywhereTheme._();

  /// Light theme used by desktop and mobile until user preferences are wired.
  static ThemeData light() {
    final ColorScheme colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF29615C),
      brightness: Brightness.light,
    );
    return _base(colors);
  }

  /// Dark theme used by desktop and mobile until user preferences are wired.
  static ThemeData dark() {
    final ColorScheme colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5DB3A9),
      brightness: Brightness.dark,
    );
    return _base(colors);
  }

  /// Dark Blue theme — inspired by VS Code "Tomorrow Night Blue".
  static ThemeData darkBlue() {
    final ColorScheme base = ColorScheme.fromSeed(
      seedColor: const Color(0xFF002451),
      brightness: Brightness.dark,
    );
    final ColorScheme colors = base.copyWith(
      surface: const Color(0xFF002451),
      onSurface: const Color(0xFFFFFFFF),
      onSurfaceVariant: const Color(0xFF7285B7),
      surfaceContainer: const Color(0xFF00346E),
      surfaceContainerHigh: const Color(0xFF00346E),
      surfaceContainerHighest: const Color(0xFF003F8E),
      primary: const Color(0xFFFFC600),
      onPrimary: const Color(0xFF1A1000),
      primaryContainer: const Color(0xFF003F8E),
      onPrimaryContainer: const Color(0xFFFFE57A),
      secondary: const Color(0xFF7285B7),
      onSecondary: const Color(0xFF002451),
      outline: const Color(0xFF1D3B6E),
      outlineVariant: const Color(0xFF1D3B6E),
    );
    return _base(colors);
  }

  /// Light Blue theme — clean, high-contrast, vivid blue.
  static ThemeData lightBlue() {
    final ColorScheme base = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0057E7),
      brightness: Brightness.light,
    );
    final ColorScheme colors = base.copyWith(
      surface: const Color(0xFFF0F7FF),
      onSurface: const Color(0xFF00214D),
      onSurfaceVariant: const Color(0xFF3A5A8C),
      surfaceContainer: const Color(0xFFFFFFFF),
      surfaceContainerHighest: const Color(0xFFE8F0FE),
      primary: const Color(0xFF0057E7),
      onPrimary: const Color(0xFFFFFFFF),
      primaryContainer: const Color(0xFFD0E4FF),
      onPrimaryContainer: const Color(0xFF00214D),
      secondary: const Color(0xFF0057E7),
      onSecondary: const Color(0xFFFFFFFF),
      outline: const Color(0xFFB3CFFF),
      outlineVariant: const Color(0xFFB3CFFF),
    );
    return _base(colors);
  }

  static ThemeData _base(ColorScheme colors) {
    final TextTheme textTheme = Typography.material2021().black.apply(
      fontFamily: 'Atkinson Hyperlegible',
      bodyColor: colors.onSurface,
      displayColor: colors.onSurface,
    );
    return ThemeData(
      colorScheme: colors,
      useMaterial3: true,
      textTheme: textTheme,
      cardTheme: const CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: LearnAnywhereTokens.smallRadius,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
