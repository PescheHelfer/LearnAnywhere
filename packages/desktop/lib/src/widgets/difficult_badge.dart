import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

/// The badge naming which flag makes a unit difficult in one direction,
/// shared by the learning session and the unit editor so the wording and
/// styling agree everywhere.
final class DifficultBadge extends StatelessWidget {
  /// Creates a badge naming the difficulty [flags] of one direction.
  const DifficultBadge({super.key, required this.flags});

  /// The flags of the direction the badge describes.
  final DifficultFlags flags;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereMessage? text = _flagMessage(flags);
    if (text == null) {
      return const SizedBox.shrink();
    }
    final ColorScheme colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      key: const Key('learnDifficultBadge'),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: LearnAnywhereTokens.smallRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LearnAnywhereTokens.gapSmall,
          vertical: LearnAnywhereTokens.gapSmall / 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.flag, size: 16, color: colors.onTertiaryContainer),
            const SizedBox(width: LearnAnywhereTokens.gapSmall / 2),
            Flexible(
              child: Text(
                LearnAnywhereLocalizations.of(context).message(text),
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: colors.onTertiaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact, table-sized sign of which flags make [unit] difficult where no
/// single direction is in view: a flag for a manual flag, a sparkle for an
/// automatic one, in either direction, both side by side for both, and
/// nothing at all for a unit difficult in neither direction.
///
/// Hovering names the flags in the badge's own words, so a table row and the
/// session badge say the same thing.
final class DifficultFlagIndicator extends StatelessWidget {
  /// Creates an indicator of [unit]'s difficulty flags.
  const DifficultFlagIndicator({super.key, required this.unit});

  /// The unit whose flags are shown.
  final LearningUnit unit;

  @override
  Widget build(BuildContext context) {
    final DifficultFlags flags = unit.flagsInEither;
    final LearnAnywhereMessage? text = _flagMessage(flags);
    if (text == null) {
      return const SizedBox.shrink();
    }
    return Tooltip(
      message: LearnAnywhereLocalizations.of(context).message(text),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (flags.manual) const Icon(Icons.flag, size: 18),
          if (flags.automatic) const Icon(Icons.auto_awesome, size: 18),
        ],
      ),
    );
  }
}

/// The badge text naming [flags], or null when there are none.
LearnAnywhereMessage? _flagMessage(DifficultFlags flags) {
  return switch ((flags.manual, flags.automatic)) {
    (true, true) => LearnAnywhereMessage.learnDifficultBadgeBoth,
    (true, false) => LearnAnywhereMessage.learnDifficultBadgeManual,
    (false, true) => LearnAnywhereMessage.learnDifficultBadgeAutomatic,
    (false, false) => null,
  };
}
