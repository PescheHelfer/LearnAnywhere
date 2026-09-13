import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';

import 'learn_anywhere_rich_text.dart';

/// A [TextEditingController] that maintains a [FieldValue] run model alongside
/// the edited plain text and renders each run with its own style.
///
/// All run manipulation is delegated to the pure-Dart helpers in core
/// (`applyFormatToRange`, `reconcileRuns`, `formatAt`); this controller only
/// adapts them to Flutter's editing pipeline. Formatting is selection-scoped:
/// applying a format with an active selection changes only that range, while a
/// collapsed caret stores an "active format" used for the next typed run.
final class LearnAnywhereRichTextEditingController extends TextEditingController {
  /// Creates a controller seeded with [value].
  factory LearnAnywhereRichTextEditingController({FieldValue? value}) {
    return LearnAnywhereRichTextEditingController._(value ?? FieldValue.empty);
  }

  LearnAnywhereRichTextEditingController._(FieldValue value)
    : _runs = normalizeRuns(_runsOf(value)),
      _lastText = value.plainText,
      _activeFormat = formatAt(_runsOf(value), value.plainText.length),
      super(text: value.plainText);

  List<RichTextRun> _runs;
  String _lastText;
  RunFormat _activeFormat;
  bool _applying = false;

  static List<RichTextRun> _runsOf(FieldValue value) {
    return switch (value) {
      PlainFieldValue(:final String text) => <RichTextRun>[
        if (text.isNotEmpty) RichTextRun(text: text),
      ],
      RichFieldValue(:final List<RichTextRun> runs) => runs,
    };
  }

  /// The formatting that newly typed characters will receive.
  RunFormat get activeFormat => _activeFormat;

  /// The current value as a [FieldValue]: plain when unformatted, else rich.
  FieldValue get fieldValue {
    final List<RichTextRun> runs = normalizeRuns(_runs);
    if (runs.isEmpty) {
      return FieldValue.plain(text);
    }
    if (runs.length == 1 && RunFormat.fromRun(runs.first).isPlain) {
      return FieldValue.plain(runs.first.text);
    }
    return FieldValue.rich(runs);
  }

  /// Replaces the edited content with [value], moving the caret to the end.
  ///
  /// Used when the host swaps in a different field; does not reconcile against
  /// the previous text.
  void loadValue(FieldValue value) {
    _applying = true;
    _runs = normalizeRuns(_runsOf(value));
    final String text = value.plainText;
    _lastText = text;
    _activeFormat = formatAt(_runs, text.length);
    this.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _applying = false;
  }

  /// Whether every character in the current selection — or the active format
  /// for a collapsed caret — satisfies [test].
  bool selectionSatisfies(bool Function(RunFormat format) test) {
    final TextSelection sel = selection;
    if (!sel.isValid || sel.isCollapsed) {
      return test(_activeFormat);
    }
    final List<RunFormat> formats = formatsFromRuns(_runs);
    final int start = sel.start.clamp(0, formats.length);
    final int end = sel.end.clamp(0, formats.length);
    if (start >= end) {
      return test(_activeFormat);
    }
    for (var i = start; i < end; i += 1) {
      if (!test(formats[i])) {
        return false;
      }
    }
    return true;
  }

  /// Applies [transform] to the current selection, or stores it as the active
  /// insertion-point format when the selection is collapsed.
  void formatSelection(RunFormat Function(RunFormat format) transform) {
    final TextSelection sel = selection;
    if (sel.isValid && !sel.isCollapsed) {
      _runs = applyFormatToRange(_runs, sel.start, sel.end, transform);
      _activeFormat = formatAt(_runs, sel.end);
    } else {
      _activeFormat = transform(_activeFormat);
    }
    notifyListeners();
  }

  /// Clears all formatting from the selection (or resets the active format).
  void clearFormatting() => formatSelection((_) => RunFormat.none);

  @override
  set value(TextEditingValue newValue) {
    if (!_applying) {
      if (newValue.text != _lastText) {
        _runs = reconcileRuns(
          runs: _runs,
          oldText: _lastText,
          newText: newValue.text,
          insertedFormat: _activeFormat,
        );
        _lastText = newValue.text;
      } else if (newValue.selection.isCollapsed &&
          newValue.selection.baseOffset >= 0 &&
          newValue.selection != selection) {
        // Caret moved: adopt the formatting at the new insertion point.
        _activeFormat = formatAt(_runs, newValue.selection.baseOffset);
      }
    }
    super.value = newValue;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (_runs.isEmpty ||
        (_runs.length == 1 && RunFormat.fromRun(_runs.first).isPlain)) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }
    final ThemeData theme = Theme.of(context);
    final Color? fallbackDecorationColor =
        style?.color ?? DefaultTextStyle.of(context).style.color;
    return TextSpan(
      style: style,
      children: _runs
          .map(
            (RichTextRun run) => LearnAnywhereRichTextRenderer.spanForRun(
              run,
              theme: theme,
              fallbackDecorationColor: fallbackDecorationColor,
            ),
          )
          .toList(growable: false),
    );
  }
}
