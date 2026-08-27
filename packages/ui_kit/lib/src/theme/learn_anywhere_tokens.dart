import 'package:flutter/material.dart';

import 'learn_anywhere_zoom.dart';

/// Shared visual constants for Learn Anywhere widgets.
final class LearnAnywhereTokens {
  const LearnAnywhereTokens._();

  /// Border radius for cards and framed tool surfaces.
  static const BorderRadius smallRadius = BorderRadius.all(Radius.circular(8));

  /// Default compact spacing between related controls.
  static const double gapSmall = 8;

  /// Default spacing between grouped controls.
  static const double gapMedium = 16;

  /// Default page or panel padding.
  static const double gapLarge = 24;

  /// The bundled fixed-width family every fixed-dimension learning container
  /// renders with, and the family every question/answer/remark field value
  /// is displayed in.
  ///
  /// This is an EXPLICITLY NAMED family, not a generic "monospace" request:
  /// `FieldRow` column widths are computed by measuring one character, so the
  /// same deck must produce the same geometry on Windows, Linux, and Android.
  /// A system font can't guarantee that — `Consolas` and `Cascadia Mono` don't
  /// exist off Windows, and a bare `monospace` alias resolves to whatever the
  /// host's fontconfig picks (or, if nothing matches, to a PROPORTIONAL
  /// fallback, which silently breaks the fixed-width layout).
  ///
  /// The `packages/<name>/` prefix is how Flutter addresses a font declared in
  /// a dependency's pubspec; see `fonts:` in ui_kit's `pubspec.yaml`.
  static const String monospaceFamily =
      'packages/learn_anywhere_ui_kit/LabMono';

  /// System monospace families tried only if the bundled font is somehow
  /// unavailable (e.g. an asset-stripped build). Kept as a safety net so the
  /// containers degrade to *a* fixed-width font rather than a proportional one.
  static const List<String> monospaceFallback = <String>[
    'Cascadia Mono',
    'Consolas',
    'DejaVu Sans Mono',
    'monospace',
  ];

  /// Returns [base] restyled onto the bundled monospace family.
  ///
  /// Use this everywhere a fixed-width container is measured or rendered, so
  /// the measuring style and the painting style can never drift apart.
  static TextStyle monospace(TextStyle? base) {
    return (base ?? const TextStyle()).copyWith(
      fontFamily: monospaceFamily,
      fontFamilyFallback: monospaceFallback,
    );
  }

  /// Unzoomed size of the key-name caption under a button.
  static const double keyHintFontSize = 10;

  /// Style for the small key name printed under a button — `F3`, `Esc`, `F10`.
  ///
  /// Deliberately NOT a theme text style: it is smaller than anything the M3
  /// scale offers, and it is the one caption that must stay subordinate to the
  /// label above it. It still follows the zoom level, because a caption naming
  /// the key the learner is about to press is of no use at 10 pixels beside
  /// text she zoomed to twice that.
  static TextStyle keyHint(BuildContext context) => TextStyle(
    fontSize: LearnAnywhereZoom.scaleText(context, keyHintFontSize),
  );

  /// Minimum width of a field row's label column.
  static const double fieldLabelMinWidth = 64;

  /// Maximum width of a field row's label column, so one very long field name
  /// can't dominate the row layout.
  static const double fieldLabelMaxWidth = 220;

  /// Minimum width of a field row's value column.
  static const double fieldValueMinWidth = 48;
}
