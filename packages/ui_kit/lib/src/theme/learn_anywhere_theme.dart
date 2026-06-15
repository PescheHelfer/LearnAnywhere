import 'package:flutter/material.dart';

/// Shared light and dark theme definitions for Learn Anywhere shells.
final class LearnAnywhereTheme {
  const LearnAnywhereTheme._();

  /// Light theme used by desktop and mobile until user preferences are wired.
  static ThemeData light() => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF29615C),
      brightness: Brightness.light,
    ),
    useMaterial3: true,
  );

  /// Dark theme used by desktop and mobile until user preferences are wired.
  static ThemeData dark() => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF5DB3A9),
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );
}
