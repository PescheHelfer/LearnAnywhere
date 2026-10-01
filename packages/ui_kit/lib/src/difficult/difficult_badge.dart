import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';

import '../i18n/learn_anywhere_localizations.dart';
import '../theme/learn_anywhere_tokens.dart';

/// The badge showing that a unit is difficult in one direction: the icon of
/// each flag that direction carries, then "Difficult". Shared by the desktop
/// session, the unit editor and the Android card so the look and wording
/// agree everywhere.
///
/// Hovering (a long press on a phone) names the flags in a few words; the
/// icons are the desktop unit list's.
final class DifficultBadge extends StatelessWidget {
  /// Creates a badge for the difficulty [flags] of one direction.
  const DifficultBadge({
    super.key,
    required this.flags,
    this.label = LearnAnywhereMessage.learnDifficult,
  });

  /// The flags of the direction the badge describes.
  final DifficultFlags flags;

  /// The badge's text: "Difficult" where one direction is in view,
  /// "Difficult 1" / "Difficult 2" in the unit editor, which shows both.
  final LearnAnywhereMessage label;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereMessage? tooltip = difficultFlagMessage(flags);
    if (tooltip == null) {
      return const SizedBox.shrink();
    }
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: messages.message(tooltip),
      child: DecoratedBox(
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
              ...difficultFlagIcons(flags, 16, colors.onTertiaryContainer),
              const SizedBox(width: LearnAnywhereTokens.gapSmall / 2),
              Flexible(
                child: Text(
                  messages.message(label),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The icon of each flag in [flags]: the manual flag, then the automatic
/// sparkle. The badge's icons, wherever a flag is named.
List<Widget> difficultFlagIcons(
  DifficultFlags flags,
  double size,
  Color? color,
) {
  return <Widget>[
    if (flags.manual) Icon(Icons.flag, size: size, color: color),
    if (flags.automatic) Icon(Icons.auto_awesome, size: size, color: color),
  ];
}

/// The few words naming [flags], or null when there are none: the badge's
/// tooltip, and the indicator's while one direction is in view.
LearnAnywhereMessage? difficultFlagMessage(DifficultFlags flags) {
  return switch ((flags.manual, flags.automatic)) {
    (true, true) => LearnAnywhereMessage.learnDifficultFlagBoth,
    (true, false) => LearnAnywhereMessage.learnDifficultFlagManual,
    (false, true) => LearnAnywhereMessage.learnDifficultFlagAutomatic,
    (false, false) => null,
  };
}
