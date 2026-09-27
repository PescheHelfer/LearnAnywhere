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
    final ColorScheme colors = Theme.of(context).colorScheme;
    final LearnAnywhereMessage text = switch ((
      unit.manualDifficult,
      unit.autoDifficult,
    )) {
      (true, true) => LearnAnywhereMessage.learnDifficultBadgeBoth,
      (true, false) => LearnAnywhereMessage.learnDifficultBadgeManual,
      _ => LearnAnywhereMessage.learnDifficultBadgeAutomatic,
    };
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
