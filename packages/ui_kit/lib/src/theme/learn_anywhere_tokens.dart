import 'package:flutter/material.dart';

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

  /// Monospace stack used for fixed-dimension learning containers.
  static const List<String> monospaceFallback = <String>[
    'Cascadia Mono',
    'Consolas',
    'DejaVu Sans Mono',
    'monospace',
  ];

  /// Minimum width of a field row's label column.
  static const double fieldLabelMinWidth = 64;

  /// Maximum width of a field row's label column, so one very long field name
  /// can't dominate the row layout.
  static const double fieldLabelMaxWidth = 220;

  /// Minimum width of a field row's value column.
  static const double fieldValueMinWidth = 48;
}
