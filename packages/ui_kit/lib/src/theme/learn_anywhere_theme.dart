import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';

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

/// The colours a rich-text value's formatting is drawn in, chosen per theme.
///
/// Unlike [LearnAnywhereChromeTheme] this is not opt-in: every theme builder
/// sets it, because a formatting colour has no [ColorScheme] role that would
/// stay legible on all four themes. [of] falls back only for a bare
/// [ThemeData] that none of the builders made (a test's default theme).
@immutable
final class LearnAnywhereFormatColours
    extends ThemeExtension<LearnAnywhereFormatColours> {
  /// Creates a format colours theme extension.
  const LearnAnywhereFormatColours({
    required this.text1,
    required this.correction,
  });

  /// The theme's one text colour, drawn for a run stored as
  /// `TextColourToken.text1`.
  ///
  /// At least 4.5:1 against every background a formatted value sits on, and
  /// clearly apart in hue from [correction], so a coloured remark can't pass
  /// for a mistake beside it.
  final Color text1;

  /// Colour of a correction mark — a mistyped, missing or extra character in
  /// the Correction view (`RichTextRun.correctionMark`).
  final Color correction;

  /// Resolves the format colours for [theme]: the extension when the theme
  /// carries one, otherwise [ColorScheme.primary] as the text colour and
  /// [ColorScheme.error] as the correction colour.
  static LearnAnywhereFormatColours of(ThemeData theme) {
    return theme.extension<LearnAnywhereFormatColours>() ??
        LearnAnywhereFormatColours(
          text1: theme.colorScheme.primary,
          correction: theme.colorScheme.error,
        );
  }

  /// The colour [token] is drawn in under this theme.
  Color textColour(TextColourToken token) {
    return switch (token) {
      TextColourToken.text1 => text1,
    };
  }

  @override
  LearnAnywhereFormatColours copyWith({Color? text1, Color? correction}) {
    return LearnAnywhereFormatColours(
      text1: text1 ?? this.text1,
      correction: correction ?? this.correction,
    );
  }

  @override
  LearnAnywhereFormatColours lerp(
    ThemeExtension<LearnAnywhereFormatColours>? other,
    double t,
  ) {
    if (other is! LearnAnywhereFormatColours) {
      return this;
    }
    return LearnAnywhereFormatColours(
      text1: Color.lerp(text1, other.text1, t) ?? text1,
      correction: Color.lerp(correction, other.correction, t) ?? correction,
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
    return _base(
      colors,
      zoomPercent,
      extensions: const <ThemeExtension<dynamic>>[
        // A deep blue: far from the red correction colour in hue, and dark
        // enough for the tinted field backgrounds.
        LearnAnywhereFormatColours(
          text1: Color(0xFF0D47A1),
          correction: Color(0xFFD32F2F),
        ),
      ],
    );
  }

  /// Dark theme used by desktop and mobile until user preferences are wired.
  static ThemeData dark({int zoomPercent = LearnAnywhereZoom.normal}) {
    final ColorScheme colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5DB3A9),
      brightness: Brightness.dark,
    );
    return _base(
      colors,
      zoomPercent,
      extensions: const <ThemeExtension<dynamic>>[
        // Warm amber reads more clearly than red against a dark surface; the
        // text colour is a pale blue, opposite it on the colour wheel.
        LearnAnywhereFormatColours(
          text1: Color(0xFFB3D4FF),
          correction: Color(0xFFFFC107),
        ),
      ],
    );
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
    return _base(
      colors,
      zoomPercent,
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
        // Not the Dark theme's amber: that is a near twin of this theme's
        // yellow primary (#FFC600), so a mark would read as accented chrome.
        // A light coral stays well clear of it in hue and of the navy ground
        // in contrast. The text colour is a mint green: any blue would sink
        // into the navy, and yellow is the primary.
        LearnAnywhereFormatColours(
          text1: Color(0xFF69F0AE),
          correction: Color(0xFFFF8A80),
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
    return _base(
      colors,
      zoomPercent,
      extensions: const <ThemeExtension<dynamic>>[
        // A deep purple: blue text would read as this theme's blue chrome.
        LearnAnywhereFormatColours(
          text1: Color(0xFF6A1B9A),
          correction: Color(0xFFD32F2F),
        ),
      ],
    );
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
  static ThemeData _base(
    ColorScheme colors,
    int zoomPercent, {
    required List<ThemeExtension<dynamic>> extensions,
  }) {
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
      extensions: extensions,
    );
  }
}
