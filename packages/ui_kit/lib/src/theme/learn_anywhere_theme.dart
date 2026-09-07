import 'package:flutter/material.dart';

import 'learn_anywhere_tokens.dart';
import 'learn_anywhere_zoom.dart';

/// Theme-specific chrome that doesn't fit [ColorScheme] roles.
///
/// [ColorScheme.outlineVariant] is the default separator color, but the dark
/// blue theme sets `outline` and `outlineVariant` to the same low-contrast
/// value, so that theme opts into a stronger, theme-appropriate color here
/// instead of changing the shared role for every theme. [mutedForeground]
/// follows the same opt-in pattern for secondary/inert text.
@immutable
final class LearnAnywhereChromeTheme
    extends ThemeExtension<LearnAnywhereChromeTheme> {
  /// Creates a chrome theme extension.
  const LearnAnywhereChromeTheme({
    required this.separatorColor,
    this.mutedForeground,
  });

  /// Color used by menu separators (`_MenuSeparator` in the desktop shell).
  final Color separatorColor;

  /// Muted foreground for secondary or inert text (e.g. an "up to date"
  /// status label, or a dimmed non-selectable row) that needs more contrast
  /// than [ColorScheme.onSurfaceVariant] gives on this particular theme.
  ///
  /// `null` means the theme doesn't need to opt in; callers fall back to
  /// [ColorScheme.onSurfaceVariant].
  final Color? mutedForeground;

  /// Resolves the muted foreground for [theme]: the extension's own color
  /// when it opts in, otherwise [ColorScheme.onSurfaceVariant].
  static Color mutedForegroundOf(ThemeData theme) {
    return theme.extension<LearnAnywhereChromeTheme>()?.mutedForeground ??
        theme.colorScheme.onSurfaceVariant;
  }

  @override
  LearnAnywhereChromeTheme copyWith({
    Color? separatorColor,
    Color? mutedForeground,
  }) {
    return LearnAnywhereChromeTheme(
      separatorColor: separatorColor ?? this.separatorColor,
      mutedForeground: mutedForeground ?? this.mutedForeground,
    );
  }

  @override
  LearnAnywhereChromeTheme lerp(
    ThemeExtension<LearnAnywhereChromeTheme>? other,
    double t,
  ) {
    if (other is! LearnAnywhereChromeTheme) {
      return this;
    }
    return LearnAnywhereChromeTheme(
      separatorColor:
          Color.lerp(separatorColor, other.separatorColor, t) ??
          separatorColor,
      mutedForeground:
          Color.lerp(mutedForeground, other.mutedForeground, t) ??
          mutedForeground,
    );
  }
}

/// Shared light and dark theme definitions for Learn Anywhere shells.
final class LearnAnywhereTheme {
  const LearnAnywhereTheme._();

  /// Light theme used by desktop and mobile until user preferences are wired.
  static ThemeData light({int zoomPercent = LearnAnywhereZoom.normal}) {
    final ColorScheme colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF29615C),
      brightness: Brightness.light,
    );
    return _base(colors, zoomPercent);
  }

  /// Dark theme used by desktop and mobile until user preferences are wired.
  static ThemeData dark({int zoomPercent = LearnAnywhereZoom.normal}) {
    final ColorScheme colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5DB3A9),
      brightness: Brightness.dark,
    );
    return _base(colors, zoomPercent);
  }

  /// Dark Blue theme — inspired by VS Code "Tomorrow Night Blue".
  static ThemeData darkBlue({int zoomPercent = LearnAnywhereZoom.normal}) {
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
    return _base(colors, zoomPercent).copyWith(
      extensions: const <ThemeExtension<dynamic>>[
        LearnAnywhereChromeTheme(
          separatorColor: Color(0xFFFFC600),
          // The shared onSurfaceVariant (0xFF7285B7) is tuned against
          // `surface`, one step darker than the surfaceContainerHigh a
          // Material dialog actually paints on, which eats its contrast
          // margin below the 4.5:1 text floor. This is brighter, for that
          // one step lighter.
          mutedForeground: Color(0xFF9DB2E8),
        ),
      ],
    );
  }

  /// Light Blue theme — clean, high-contrast, vivid blue.
  static ThemeData lightBlue({int zoomPercent = LearnAnywhereZoom.normal}) {
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
    return _base(colors, zoomPercent);
  }

  /// Builds a theme whose every text size is multiplied by the zoom factor.
  ///
  /// The zoom level is applied HERE, to the theme's own font sizes, and never
  /// as a text-scaler override. The mask's fixed-width field boxes are sized by
  /// measuring one character in the very style they will be painted with; a
  /// text scaler is applied after that measurement, at paint time, so it would
  /// render text larger than the box measured for it and clip every field.
  /// Scaling the theme keeps measurement and rendering in agreement. See
  /// `docs/adr/0002-zoom-scales-the-theme-not-the-text-scaler.md`.
  static ThemeData _base(ColorScheme colors, int zoomPercent) {
    final Typography typography = Typography.material2021();
    // The colour theme (`black`) carries no font sizes at all — those live in
    // the geometry (`englishLike`), which Flutter normally merges in later,
    // during localization. Merging it in HERE is what gives the factor
    // something to multiply, and an explicit size survives that later merge
    // (`ThemeData.localize` puts the app's own theme on top of the geometry).
    // Both languages this program ships are englishLike, so pinning that
    // geometry costs nothing.
    final TextTheme textTheme = typography.englishLike
        .merge(typography.black)
        .apply(
          fontFamily: 'Atkinson Hyperlegible',
          fontSizeFactor: LearnAnywhereZoom.factor(zoomPercent),
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
