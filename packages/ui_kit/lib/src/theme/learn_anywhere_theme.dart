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
