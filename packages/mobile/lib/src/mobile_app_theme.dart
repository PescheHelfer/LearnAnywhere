import 'package:flutter/material.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

/// The five UI themes offered on mobile, mirroring desktop's Options ▸ Theme.
enum MobileAppTheme {
  /// Follows the device's light/dark setting.
  system,

  /// Light theme.
  light,

  /// Dark theme.
  dark,

  /// Dark Blue theme.
  darkBlue,

  /// Light Blue theme.
  lightBlue,
}

/// Resolves [name] (a [MobileAppTheme]'s enum name) to its value, defaulting
/// to Dark Blue — the same default desktop uses — when [name] is null or
/// unrecognized.
MobileAppTheme mobileAppThemeFromName(String? name) {
  if (name != null) {
    for (final MobileAppTheme theme in MobileAppTheme.values) {
      if (theme.name == name) {
        return theme;
      }
    }
  }
  return MobileAppTheme.darkBlue;
}

/// The light-mode [ThemeData] for [theme] (used when the resolved
/// [ThemeMode] is light).
ThemeData mobileLightThemeData(MobileAppTheme theme) {
  return theme == MobileAppTheme.lightBlue
      ? LearnAnywhereTheme.lightBlue()
      : LearnAnywhereTheme.light();
}

/// The dark-mode [ThemeData] for [theme] (used when the resolved [ThemeMode]
/// is dark).
ThemeData mobileDarkThemeData(MobileAppTheme theme) {
  return theme == MobileAppTheme.darkBlue
      ? LearnAnywhereTheme.darkBlue()
      : LearnAnywhereTheme.dark();
}

/// The [ThemeMode] [theme] resolves to.
ThemeMode mobileThemeMode(MobileAppTheme theme) {
  return switch (theme) {
    MobileAppTheme.system => ThemeMode.system,
    MobileAppTheme.light => ThemeMode.light,
    MobileAppTheme.dark || MobileAppTheme.darkBlue => ThemeMode.dark,
    MobileAppTheme.lightBlue => ThemeMode.light,
  };
}
