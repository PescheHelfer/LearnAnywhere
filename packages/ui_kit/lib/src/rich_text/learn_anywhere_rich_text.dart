import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';

import '../theme/learn_anywhere_theme.dart';
import 'learn_anywhere_palette.dart';

/// Builds Flutter text spans from Learn Anywhere portable rich-text values.
final class LearnAnywhereRichTextRenderer {
  const LearnAnywhereRichTextRenderer._();

  /// Converts a stored [FieldValue] into a [TextSpan].
  ///
  /// [theme] resolves text colours and correction marks through
  /// [LearnAnywhereFormatColours], and its brightness selects how stored
  /// highlight colors are mapped so they stay readable: light-mode highlights
  /// (including legacy plain yellow) are remapped to dark equivalents on a
  /// dark theme.
  static TextSpan spanForFieldValue(
    FieldValue value, {
    required ThemeData theme,
    TextStyle? baseStyle,
  }) {
    return switch (value) {
      PlainFieldValue(:final String text) => TextSpan(
        text: text,
        style: baseStyle,
      ),
      RichFieldValue(:final List<RichTextRun> runs) => TextSpan(
        style: baseStyle,
        children: runs
            .map(
              (RichTextRun run) => spanForRun(
                run,
                theme: theme,
                fallbackDecorationColor: baseStyle?.color,
              ),
            )
            .toList(growable: false),
      ),
    };
  }

  /// Converts a single rich-text run into a [TextSpan].
  ///
  /// A run's text colour token is drawn in [theme]'s colour for it, and a
  /// [RichTextRun.correctionMark] in [theme]'s correction colour, over any
  /// text colour the run stores.
  ///
  /// [fallbackDecorationColor] is used as the underline colour when the run
  /// carries no explicit text colour. Pass the parent span's resolved text
  /// colour so the decoration follows the inherited foreground instead of
  /// defaulting to black.
  static TextSpan spanForRun(
    RichTextRun run, {
    required ThemeData theme,
    Color? fallbackDecorationColor,
  }) {
    final LearnAnywhereFormatColours colours = LearnAnywhereFormatColours.of(
      theme,
    );
    final TextColourToken? token = run.color;
    final Color? explicitColor = run.correctionMark
        ? colours.correction
        : token == null
        ? null
        : colours.textColour(token);
    // Underline and strikethrough can both be on; combine them so neither is
    // dropped.
    final List<TextDecoration> decorations = <TextDecoration>[
      if (run.underline) TextDecoration.underline,
      if (run.strikethrough) TextDecoration.lineThrough,
    ];
    return TextSpan(
      text: run.text,
      style: TextStyle(
        fontWeight: run.bold ? FontWeight.bold : FontWeight.normal,
        fontStyle: run.italic ? FontStyle.italic : FontStyle.normal,
        decoration: decorations.isEmpty
            ? TextDecoration.none
            : TextDecoration.combine(decorations),
        decorationColor: explicitColor ?? fallbackDecorationColor,
        color: explicitColor,
        backgroundColor: _highlightColor(run.highlight, theme.brightness),
      ),
    );
  }

  static Color? _highlightColor(String? value, Brightness brightness) {
    if (value == null) {
      return null;
    }
    return colorFromHex(
      LearnAnywherePalette.highlightForBrightness(value, brightness),
    );
  }
}

/// Displays a Learn Anywhere [FieldValue] using Flutter's rich text system.
final class LearnAnywhereRichText extends StatelessWidget {
  /// Creates a rich-text renderer widget.
  const LearnAnywhereRichText({
    required this.value,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    super.key,
  });

  /// Field value to display.
  final FieldValue value;

  /// Base text style applied to the value.
  final TextStyle? style;

  /// Text alignment.
  final TextAlign? textAlign;

  /// Optional maximum line count.
  final int? maxLines;

  /// Overflow behavior when [maxLines] is reached.
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    final TextStyle effectiveStyle =
        style ?? DefaultTextStyle.of(context).style;
    return RichText(
      text: LearnAnywhereRichTextRenderer.spanForFieldValue(
        value,
        baseStyle: effectiveStyle,
        theme: Theme.of(context),
      ),
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
