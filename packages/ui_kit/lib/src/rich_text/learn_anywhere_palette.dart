import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';

/// Parses a `#RRGGBB` string into an opaque [Color].
Color colorFromHex(String hex) {
  return Color(int.parse('FF${hex.substring(1)}', radix: 16));
}

/// A selectable color with a stored hex value and a localizable label.
///
/// A `null` [hex] represents the "default / inherit" (text) or "none"
/// (highlight) option, so older files without the field stay valid.
final class LearnAnywhereColorSwatch {
  /// Creates a color swatch.
  const LearnAnywhereColorSwatch({required this.label, required this.hex});

  /// The localizable label key for this swatch.
  final LearnAnywhereMessage label;

  /// Stored `#RRGGBB` value, or `null` for the default/none option.
  final String? hex;

  /// The rendered color, or `null` for the default/none option.
  Color? get color => hex == null ? null : colorFromHex(hex!);
}

/// Curated, theme-aware highlight palettes for the rich-text editor.
final class LearnAnywherePalette {
  const LearnAnywherePalette._();

  /// Highlight options tuned for light mode (dark text on a light fill).
  static const List<LearnAnywhereColorSwatch> lightHighlights =
      <LearnAnywhereColorSwatch>[
        LearnAnywhereColorSwatch(
          label: LearnAnywhereMessage.colorNone,
          hex: null,
        ),
        LearnAnywhereColorSwatch(
          label: LearnAnywhereMessage.colorYellow,
          hex: '#FFE066',
        ),
        LearnAnywhereColorSwatch(
          label: LearnAnywhereMessage.colorCyan,
          hex: '#80DEEA',
        ),
        LearnAnywhereColorSwatch(
          label: LearnAnywhereMessage.colorLime,
          hex: '#C5E1A5',
        ),
        LearnAnywhereColorSwatch(
          label: LearnAnywhereMessage.colorOrange,
          hex: '#FFCC80',
        ),
        LearnAnywhereColorSwatch(
          label: LearnAnywhereMessage.colorPink,
          hex: '#F8BBD0',
        ),
      ];

  /// Highlight options tuned for dark mode (light text on a dark fill).
  static const List<LearnAnywhereColorSwatch> darkHighlights =
      <LearnAnywhereColorSwatch>[
        LearnAnywhereColorSwatch(
          label: LearnAnywhereMessage.colorNone,
          hex: null,
        ),
        LearnAnywhereColorSwatch(
          label: LearnAnywhereMessage.colorAmber,
          hex: '#8D6E00',
        ),
        LearnAnywhereColorSwatch(
          label: LearnAnywhereMessage.colorTeal,
          hex: '#00695C',
        ),
        LearnAnywhereColorSwatch(
          label: LearnAnywhereMessage.colorPurple,
          hex: '#4A148C',
        ),
        LearnAnywhereColorSwatch(
          label: LearnAnywhereMessage.colorRed,
          hex: '#7F1D1D',
        ),
        LearnAnywhereColorSwatch(
          label: LearnAnywhereMessage.colorBlue,
          hex: '#0D47A1',
        ),
      ];

  /// The highlight palette appropriate for [brightness].
  static List<LearnAnywhereColorSwatch> highlightsFor(Brightness brightness) {
    return brightness == Brightness.dark ? darkHighlights : lightHighlights;
  }

  /// Maps a light-mode highlight value to a readable dark-mode equivalent.
  ///
  /// Light-mode highlights (including legacy plain yellow such as `#FFFF00`
  /// stored by older `.vok` files) would be nearly invisible behind light text
  /// in dark mode, so they are remapped by index to the dark palette.
  static const Map<String, String> _lightToDarkHighlight = <String, String>{
    '#FFE066': '#8D6E00', // yellow -> amber
    '#FFFF00': '#8D6E00', // legacy plain yellow -> amber
    '#80DEEA': '#00695C', // cyan -> teal
    '#C5E1A5': '#33691E', // lime -> dark green
    '#FFCC80': '#E65100', // orange -> dark orange
    '#F8BBD0': '#880E4F', // pink -> dark pink
  };

  /// Returns a highlight value readable under [brightness].
  ///
  /// In light mode the stored value is returned unchanged. In dark mode known
  /// light-mode highlights are remapped to their dark equivalents; unknown
  /// values (already dark) pass through untouched.
  static String highlightForBrightness(String hex, Brightness brightness) {
    if (brightness != Brightness.dark) {
      return hex;
    }
    return _lightToDarkHighlight[hex.toUpperCase()] ?? hex;
  }
}
