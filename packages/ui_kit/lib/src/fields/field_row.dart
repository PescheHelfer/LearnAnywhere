import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';

import '../theme/learn_anywhere_tokens.dart';

/// Measures the rendered width of [text] using [style].
///
/// Used to size the fixed-width [FieldRow] label/value columns so they fit
/// their content instead of stretching or truncating.
double measureTextWidth(String text, TextStyle style) {
  final TextPainter painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  return painter.width;
}

/// Width of a single monospace character rendered with [style].
double measureMonospaceCharWidth(TextStyle style) =>
    measureTextWidth('0', style);

/// Computes a [FieldRow] label-column width that fits the longest field name
/// declared anywhere in [mask] (across all categories), so the column stays
/// aligned and stable regardless of which unit/category is on screen.
///
/// Clamped to [minWidth]/[maxWidth] so one very long field name can't
/// dominate the layout.
double computeFieldLabelWidth(
  BuildContext context,
  LearningMask mask, {
  TextStyle? style,
  double minWidth = LearnAnywhereTokens.fieldLabelMinWidth,
  double maxWidth = LearnAnywhereTokens.fieldLabelMaxWidth,
}) {
  final TextStyle effectiveStyle =
      style ?? Theme.of(context).textTheme.bodySmall ?? const TextStyle();
  double widest = 0;
  for (final CategoryDefinition category in mask.categories) {
    for (final FieldDefinition field in category.fields) {
      if (field.isHidden) continue;
      final double width = measureTextWidth(field.name, effectiveStyle);
      if (width > widest) widest = width;
    }
  }
  return (widest + 16).clamp(minWidth, maxWidth);
}

/// Computes a [FieldRow] value-column width sized to hold [fieldLength]
/// characters of width [charWidth], plus row padding and any [extraWidth]
/// (e.g. reserved space for a used/allowed counter).
double computeFieldValueWidth({
  required int fieldLength,
  required double charWidth,
  double extraWidth = 0,
  double minWidth = LearnAnywhereTokens.fieldValueMinWidth,
}) {
  final double raw = fieldLength * charWidth + 16 + extraWidth;
  return math.max(minWidth, raw);
}

/// A single "label + value" field row: a colored accent bar, a fixed-width
/// label column (sized by the caller to align with every other row on
/// screen), a divider, then a fixed-width value column sized to the field's
/// declared length.
///
/// Shared by the Unit Editor (editable, with a used/allowed counter) and the
/// Learn session (read-only or editable, no counter).
final class FieldRow extends StatelessWidget {
  /// Creates a field row.
  const FieldRow({
    required this.label,
    required this.labelWidth,
    required this.valueWidth,
    required this.accentColor,
    required this.backgroundColor,
    required this.value,
    this.counterText,
    super.key,
  });

  /// The field's display name.
  final String label;

  /// Width of the label column; shared across every row on screen.
  final double labelWidth;

  /// Width of the value column; sized to this field's declared length.
  final double valueWidth;

  /// Accent bar / label-column tint color for this field's role.
  final Color accentColor;

  /// Background color shared by the label and value columns.
  final Color backgroundColor;

  /// The value content: an editable text field, read-only rich text, or a
  /// Level-Learning scaffold.
  final Widget value;

  /// Optional "used/allowed" character counter, shown only by the Editor.
  final String? counterText;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(width: 4, color: accentColor),
          Container(
            width: labelWidth,
            color: backgroundColor,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(width: 1, color: colors.outlineVariant),
          Container(
            width: valueWidth,
            color: backgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: <Widget>[
                Expanded(child: value),
                if (counterText != null) ...<Widget>[
                  const SizedBox(width: 4),
                  Text(
                    counterText!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
