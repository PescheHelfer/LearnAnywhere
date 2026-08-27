import 'package:flutter/material.dart';

/// The offered zoom levels and the stepping rules the shells share.
///
/// Zoom is a *discrete* setting on purpose: the learner always lands on a size
/// that has been laid out and tested, and the keyboard steps move between those
/// same sizes rather than scaling freely.
final class LearnAnywhereZoom {
  const LearnAnywhereZoom._();

  /// Every offered level, in per cent, ascending.
  static const List<int> levels = <int>[100, 125, 150, 175, 200];

  /// The unzoomed level, and what an unset or unusable stored value falls to.
  static const int normal = 100;

  /// The largest offered level.
  static int get maximum => levels.last;

  /// Whether [percent] is one of the offered [levels].
  static bool isLevel(int percent) => levels.contains(percent);

  /// [percent] snapped onto the nearest offered level.
  ///
  /// A stored value can be anything — a hand-edited preferences entry, or a
  /// level an older build offered — and every caller wants a level back rather
  /// than an arbitrary number.
  static int nearest(int percent) {
    int best = levels.first;
    for (final int level in levels) {
      if ((level - percent).abs() < (best - percent).abs()) {
        best = level;
      }
    }
    return best;
  }

  /// The next level above [percent]; the top level stays where it is.
  static int stepUp(int percent) {
    final int index = levels.indexOf(nearest(percent));
    return index == levels.length - 1 ? levels[index] : levels[index + 1];
  }

  /// The next level below [percent]; the bottom level stays where it is.
  static int stepDown(int percent) {
    final int index = levels.indexOf(nearest(percent));
    return index == 0 ? levels[index] : levels[index - 1];
  }

  /// [percent] as the factor the theme's text sizes are multiplied by.
  static double factor(int percent) => nearest(percent) / normal;

  /// The unzoomed size of the body text every other size is measured against.
  static final double _baselineBodySize =
      Typography.material2021().englishLike.bodyMedium!.fontSize!;

  /// The zoom factor currently in force, read back from the theme in [context].
  ///
  /// The level itself is not carried down the tree — the theme's own text sizes
  /// are, which is the whole mechanism — so this recovers the factor from them.
  static double factorOf(BuildContext context) {
    final double? size = Theme.of(context).textTheme.bodyMedium?.fontSize;
    return size == null ? 1 : size / _baselineBodySize;
  }

  /// [dimension] grown by the zoom factor currently in force.
  ///
  /// For a width or height that exists to HOLD TEXT — a box sized for a label,
  /// a numeric field, a column of names. Such a box has to follow the text
  /// inside it or its content is clipped at every level above 100 per cent.
  /// Paddings, hairlines and icon boxes deliberately do not use this: they
  /// stay put, which is why chrome is proportionally tighter when zoomed in.
  static double scale(BuildContext context, double dimension) =>
      dimension * factorOf(context);
}
