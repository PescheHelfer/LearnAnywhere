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
}
