import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

/// The badge naming which flag makes a unit difficult, shared by the learning
/// session and the unit editor so the wording and styling agree everywhere.
final class DifficultBadge extends StatelessWidget {
  /// Creates a badge naming [unit]'s difficulty flag.
  const DifficultBadge({super.key, required this.unit});

  /// The unit whose flag the badge names.
  final LearningUnit unit;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereMessage? text = _flagMessage(unit);
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

/// A compact, table-sized sign of which flags make [unit] difficult: a flag
/// for the learner's manual flag, a sparkle for the program's automatic one,
/// both side by side for both, and nothing at all for an unflagged unit.
///
/// Hovering names the flag in the badge's own words, so a table row and the
/// session badge say the same thing.
final class DifficultFlagIndicator extends StatelessWidget {
  /// Creates an indicator of [unit]'s difficulty flags.
  const DifficultFlagIndicator({super.key, required this.unit});

  /// The unit whose flags are shown.
  final LearningUnit unit;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereMessage? text = _flagMessage(unit);
    if (text == null) {
      return const SizedBox.shrink();
    }
    return Tooltip(
      message: LearnAnywhereLocalizations.of(context).message(text),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (unit.manualDifficult) const Icon(Icons.flag, size: 18),
          if (unit.autoDifficult) const Icon(Icons.auto_awesome, size: 18),
        ],
      ),
    );
  }
}

/// The badge text naming [unit]'s flags, or null when it carries none.
LearnAnywhereMessage? _flagMessage(LearningUnit unit) {
  return switch ((unit.manualDifficult, unit.autoDifficult)) {
    (true, true) => LearnAnywhereMessage.learnDifficultBadgeBoth,
    (true, false) => LearnAnywhereMessage.learnDifficultBadgeManual,
    (false, true) => LearnAnywhereMessage.learnDifficultBadgeAutomatic,
    (false, false) => null,
  };
}
