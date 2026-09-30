import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

/// The badge showing that a unit is difficult in one direction: the icon of
/// each flag that direction carries, then "Difficult". Shared by the learning
/// session and the unit editor so the look and wording agree everywhere.
///
/// Hovering names the flags in a few words; the icons are the unit list's.
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
    final LearnAnywhereMessage? tooltip = _flagMessage(flags);
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

/// The pill that shows whether the unit on screen is difficult in one
/// direction and toggles it, like its key.
///
/// Filled while the unit is difficult, outlined while it is not. Its focus
/// node never takes focus, so clicking it while typing an answer or editing a
/// field leaves the cursor where it was.
final class DifficultPill extends StatefulWidget {
  /// Creates a pill reading [label] above [keyName].
  const DifficultPill({
    super.key,
    required this.difficult,
    required this.onPressed,
    this.label = LearnAnywhereMessage.learnDifficult,
    this.keyName = 'F12',
    this.tooltip,
  });

  /// Whether the unit is difficult in the pill's direction.
  final bool difficult;

  /// Toggles the unit's difficulty in the pill's direction.
  final VoidCallback onPressed;

  /// The pill's text.
  final LearnAnywhereMessage label;

  /// The key printed under [label].
  final String keyName;

  /// Shown on hover, or nothing when null.
  final String? tooltip;

  @override
  State<DifficultPill> createState() => _DifficultPillState();
}

final class _DifficultPillState extends State<DifficultPill> {
  final FocusNode _focusNode = FocusNode(
    skipTraversal: true,
    canRequestFocus: false,
  );

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget label = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(LearnAnywhereLocalizations.of(context).message(widget.label)),
        Text(widget.keyName, style: LearnAnywhereTokens.keyHint(context)),
      ],
    );
    final Widget pill = Semantics(
      toggled: widget.difficult,
      child: widget.difficult
          ? FilledButton.icon(
              focusNode: _focusNode,
              onPressed: widget.onPressed,
              icon: const Icon(Icons.flag),
              label: label,
            )
          : OutlinedButton.icon(
              focusNode: _focusNode,
              onPressed: widget.onPressed,
              icon: const Icon(Icons.outlined_flag),
              label: label,
            ),
    );
    final String? tooltip = widget.tooltip;
    return tooltip == null ? pill : Tooltip(message: tooltip, child: pill);
  }
}

/// A compact, table-sized sign of which flags make [unit] difficult in the
/// [directions] in view: a flag for a manual flag, a sparkle for an automatic
/// one, both side by side for both, and nothing at all for a unit difficult
/// in none of them.
///
/// Hovering names the flags. With one direction in view that is the badge's
/// own tooltip; with both (the Lexicon, the unit list under Combined) each
/// flag is named with the directions it sits in, in the statistics View's
/// words, so a merged icon still says where it came from.
final class DifficultFlagIndicator extends StatelessWidget {
  /// Creates an indicator of [unit]'s difficulty flags in [directions].
  const DifficultFlagIndicator({
    super.key,
    required this.unit,
    required this.directions,
  });

  /// The unit whose flags are shown.
  final LearningUnit unit;

  /// The directions in view; flags in any other direction are not shown.
  final Set<QueryDirection> directions;

  @override
  Widget build(BuildContext context) {
    final DifficultFlags flags = unit.flagsIn(directions);
    if (!flags.isDifficult) {
      return const SizedBox.shrink();
    }
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return Tooltip(
      message: directions.length == 1
          ? messages.message(_flagMessage(flags)!)
          : _flagsByDirection(messages),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: difficultFlagIcons(flags, 18, null),
      ),
    );
  }

  /// "Manual flag: Direction 1 · Automatic flag: Direction 1 and 2": each
  /// flag present, with the directions in view that carry it.
  String _flagsByDirection(LearnAnywhereLocalizations messages) {
    String? named(LearnAnywhereMessage flag, bool Function(DifficultFlags) has) {
      final List<QueryDirection> carrying = <QueryDirection>[
        for (final QueryDirection direction in QueryDirection.values)
          if (directions.contains(direction) && has(unit.flagsFor(direction)))
            direction,
      ];
      if (carrying.isEmpty) {
        return null;
      }
      final LearnAnywhereMessage where = carrying.length > 1
          ? LearnAnywhereMessage.learnDifficultFlagBothDirections
          : switch (carrying.single) {
              QueryDirection.direction1 =>
                LearnAnywhereMessage.statisticsDirection1,
              QueryDirection.direction2 =>
                LearnAnywhereMessage.statisticsDirection2,
            };
      return '${messages.message(flag)}: ${messages.message(where)}';
    }

    return <String?>[
      named(
        LearnAnywhereMessage.learnDifficultFlagManual,
        (DifficultFlags flags) => flags.manual,
      ),
      named(
        LearnAnywhereMessage.learnDifficultFlagAutomatic,
        (DifficultFlags flags) => flags.automatic,
      ),
    ].nonNulls.join(' · ');
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

/// The few words naming [flags], or null when there are none.
LearnAnywhereMessage? _flagMessage(DifficultFlags flags) {
  return switch ((flags.manual, flags.automatic)) {
    (true, true) => LearnAnywhereMessage.learnDifficultFlagBoth,
    (true, false) => LearnAnywhereMessage.learnDifficultFlagManual,
    (false, true) => LearnAnywhereMessage.learnDifficultFlagAutomatic,
    (false, false) => null,
  };
}
