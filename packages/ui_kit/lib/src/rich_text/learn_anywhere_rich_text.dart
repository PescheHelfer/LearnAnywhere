import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';

/// Builds Flutter text spans from Learn Anywhere portable rich-text values.
final class LearnAnywhereRichTextRenderer {
  const LearnAnywhereRichTextRenderer._();

  /// Converts a stored [FieldValue] into a [TextSpan].
  static TextSpan spanForFieldValue(FieldValue value, {TextStyle? baseStyle}) {
    return switch (value) {
      PlainFieldValue(:final String text) => TextSpan(
        text: text,
        style: baseStyle,
      ),
      RichFieldValue(:final List<RichTextRun> runs) => TextSpan(
        style: baseStyle,
        children: runs.map(spanForRun).toList(growable: false),
      ),
    };
  }

  /// Converts a single rich-text run into a [TextSpan].
  static TextSpan spanForRun(RichTextRun run) {
    return TextSpan(
      text: run.text,
      style: TextStyle(
        fontWeight: run.bold ? FontWeight.bold : FontWeight.normal,
        fontStyle: run.italic ? FontStyle.italic : FontStyle.normal,
        decoration: run.underline
            ? TextDecoration.underline
            : TextDecoration.none,
        color: _colorFromHex(run.color),
        backgroundColor: _colorFromHex(run.highlight),
      ),
    );
  }

  static Color? _colorFromHex(String? value) {
    if (value == null) {
      return null;
    }
    final String hex = value.substring(1);
    return Color(int.parse('FF$hex', radix: 16));
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
    return RichText(
      text: LearnAnywhereRichTextRenderer.spanForFieldValue(
        value,
        baseStyle: style ?? DefaultTextStyle.of(context).style,
      ),
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
