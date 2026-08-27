import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The offered zoom levels and the stepping rules the shells share.
///
/// Zoom is a *discrete* setting on purpose: the learner always lands on a size
/// that has been laid out and tested, and the keyboard steps move between those
/// same sizes rather than scaling freely.
final class LearnAnywhereZoom {
  const LearnAnywhereZoom._();

  /// Every offered level, in per cent, ascending.
  ///
  /// One level below [normal] is offered as well as four above: a learner who
  /// wants more of a wide deck on screen at once is asking for the same control
  /// as one who wants larger characters.
  static const List<int> levels = <int>[75, 100, 125, 150, 175, 200];

  /// The unzoomed level, and what an unset or unusable stored value falls to.
  ///
  /// Not the smallest level — it is the one the program starts at and the one
  /// Ctrl+zero returns to, which is why it is named rather than an index.
  static const int normal = 100;

  /// The smallest offered level.
  static int get minimum => levels.first;

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

  /// [fontSize] scaled by the zoom factor currently in force, in both
  /// directions.
  ///
  /// For a font size written as a literal because the M3 scale has nothing
  /// small enough — the key-name caption under a button. Text taken from the
  /// theme needs none of this; it is already scaled.
  static double scaleText(BuildContext context, double fontSize) =>
      fontSize * factorOf(context);

  /// [dimension] grown by the zoom factor currently in force, but **never
  /// shrunk below its unzoomed value**.
  ///
  /// For a hard-coded box dimension expressed in text-sized units: a box sized
  /// for a label, a numeric field, a column of names, or the breakpoint between
  /// a one- and a two-column layout. It has to grow with the text or its
  /// content clips at 200 per cent.
  ///
  /// The floor is not timidity. Such a box holds fixed-size chrome as well as
  /// text — a dropdown's arrow, an icon, the padding inside an input decoration
  /// — and none of that shrinks with the level. Scaling the box down to match
  /// 75 per cent text overflowed it on exactly that chrome. Holding every box
  /// at its 100 per cent size below the normal level is provably safe: smaller
  /// text always fits a layout that already fits at 100.
  ///
  /// Paddings, hairlines and icon boxes use neither this nor [scaleText]: they
  /// stay put, which is why chrome is proportionally tighter when zoomed in.
  static double scaleBox(BuildContext context, double dimension) =>
      dimension * math.max(1, factorOf(context));
}
