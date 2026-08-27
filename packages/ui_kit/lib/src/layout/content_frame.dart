import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';

import '../fields/field_row.dart';
import '../theme/learn_anywhere_tokens.dart';
import '../theme/learn_anywhere_zoom.dart';

/// The *content frame*: the centred, width-limited box a screen's content sits
/// in, so a maximised window does not pin everything to one corner.
///
/// Centring is horizontal only. Content keeps the frame's full height and is
/// anchored to the top, deliberately: a session's feedback line appears and
/// disappears as answers are given, and a vertically centred frame would make
/// the whole mask jump on every answer.
///
/// The frame is always clamped to the width it is given. At or below
/// [maxWidth] it steps out of the way entirely — the child is returned
/// unwrapped, so a narrow window lays out exactly as it did before the frame
/// existed, and no horizontal scrollbar can ever appear on the page itself.
///
/// Expects a bounded height, which is what the shell's content area gives it.
final class ContentFrame extends StatelessWidget {
  /// Frames [child] at no more than [maxWidth].
  const ContentFrame({
    required this.maxWidth,
    required this.child,
    this.enabled = true,
    super.key,
  });

  /// The widest the frame may become. Wider surfaces gain margins instead.
  final double maxWidth;

  /// Whether the learner wants centring at all. When false the frame is inert
  /// and [child] is returned untouched.
  final bool enabled;

  /// The screen to frame.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double available = constraints.maxWidth;
        if (!available.isFinite || available <= maxWidth) {
          return child;
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Spacer(),
            SizedBox(width: maxWidth, child: child),
            const Spacer(),
          ],
        );
      },
    );
  }
}

/// Fixed chrome around a pill whose label sits beside a leading icon: the
/// icon, the gap after it and the button's own horizontal padding.
///
/// None of the three follows the text size, which is why this is a constant
/// while every label beside it is measured. Pinned against real Material
/// buttons by the desktop shell's content-frame test.
const double iconPillChrome = 66;

/// Fixed chrome around a pill with no icon — its horizontal padding alone.
const double plainPillChrome = 48;

/// The width of a pill's label column: the label above its key name, whichever
/// of the two is wider.
///
/// Measured in the very styles the two are painted in, so the figure follows
/// the language, the zoom level and the host's font without being told about
/// any of them.
double measurePillLabelWidth(
  BuildContext context,
  String label,
  String keyName,
) => math.max(
  measureTextWidth(
    label,
    Theme.of(context).textTheme.labelLarge ?? const TextStyle(),
  ),
  measureTextWidth(keyName, LearnAnywhereTokens.keyHint(context)),
);

/// The content-frame width for a screen that is not sized from a deck.
///
/// The fixed part is zoomed, because the layouts it has to keep intact are —
/// the Mask Editor's two-column breakpoint above all.
double fixedContentFrameWidth(BuildContext context) =>
    LearnAnywhereZoom.scaleBox(
      context,
      LearnAnywhereTokens.contentFrameFixedWidth,
    ) +
    LearnAnywhereTokens.contentFrameMargin;

/// The content-frame width for the session and editor screens, derived from
/// [mask] so a deck's own geometry decides how much room it gets.
///
/// The larger of two things, plus a margin: the widest field row [mask] can
/// produce, and [minimumWidth] — what the screen's own control rows need to
/// stay on one line. Taking the mask alone would let a deck of short fields
/// derive a frame narrower than the buttons and stack them permanently, which
/// is worse than no frame at all.
///
/// The mask is measured the way the **Unit Editor** lays it out — with the
/// used/allowed counter reserved — even when the caller is the session, which
/// has no counter. The editor's is the wider of the two, and using it on both
/// screens is what stops the frame shifting as the learner moves between
/// learning and editing the same deck.
double deckContentFrameWidth(
  BuildContext context,
  LearningMask mask, {
  required double minimumWidth,
}) {
  final TextStyle valueStyle = LearnAnywhereTokens.monospace(
    Theme.of(context).textTheme.bodyMedium,
  );
  final double charWidth = measureMonospaceCharWidth(valueStyle);
  double widestValue = 0;
  for (final CategoryDefinition category in mask.categories) {
    for (final FieldDefinition field in category.fields) {
      if (field.isHidden) continue;
      final double valueWidth = computeFieldValueWidth(
        fieldLength: field.length,
        charWidth: charWidth,
        extraWidth: measureFieldCounterWidth(context, field.length),
      );
      if (valueWidth > widestValue) widestValue = valueWidth;
    }
  }
  // A mask with nothing visible in it has no width of its own; the control
  // rows alone then decide the frame.
  final double maskWidth = widestValue == 0
      ? 0
      : LearnAnywhereTokens.fieldRowAccentWidth +
            computeFieldLabelWidth(context, mask) +
            LearnAnywhereTokens.fieldRowDividerThickness +
            widestValue +
            2 * LearnAnywhereTokens.fieldRowGridBorderWidth;
  return math.max(maskWidth, minimumWidth) +
      LearnAnywhereTokens.contentFrameMargin;
}
