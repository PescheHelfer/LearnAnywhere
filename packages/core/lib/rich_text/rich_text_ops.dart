/// Pure-Dart operations on rich-text run lists used by editors and renderers.
///
/// These helpers keep all run/span manipulation (splitting, merging, applying
/// formatting to a selection, and reconciling runs after a plain-text edit) in
/// core so the UI layer never embeds business rules. No Flutter imports.
library;

import '../engine/engine.dart';
import '../models/models.dart';

/// The formatting attributes of a rich-text run, without its text.
///
/// Used to describe the active formatting at a caret position and to apply a
/// formatting change to a range without caring about the underlying text.
final class RunFormat {
  /// Creates a run format.
  const RunFormat({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
    this.color,
    this.highlight,
  });

  /// Extracts the formatting of [run], dropping its text.
  factory RunFormat.fromRun(RichTextRun run) {
    return RunFormat(
      bold: run.bold,
      italic: run.italic,
      underline: run.underline,
      strikethrough: run.strikethrough,
      color: run.color,
      highlight: run.highlight,
    );
  }

  /// Whether the run is bold.
  final bool bold;

  /// Whether the run is italic.
  final bool italic;

  /// Whether the run is underlined.
  final bool underline;

  /// Whether the run is struck through.
  final bool strikethrough;

  /// Optional foreground color as `#RRGGBB`.
  final String? color;

  /// Optional highlight color as `#RRGGBB`.
  final String? highlight;

  /// The unformatted default.
  static const RunFormat none = RunFormat();

  /// Whether this format carries no formatting at all.
  bool get isPlain =>
      !bold &&
      !italic &&
      !underline &&
      !strikethrough &&
      color == null &&
      highlight == null;

  /// Returns a run combining this formatting with [text].
  RichTextRun applyTo(String text) {
    return RichTextRun(
      text: text,
      bold: bold,
      italic: italic,
      underline: underline,
      strikethrough: strikethrough,
      color: color,
      highlight: highlight,
    );
  }

  /// Returns a copy with the boolean toggles optionally changed.
  ///
  /// Colors are left untouched; use [withColor] and [withHighlight] to change
  /// them (so that clearing to `null` is expressible).
  RunFormat copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strikethrough,
  }) {
    return RunFormat(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      strikethrough: strikethrough ?? this.strikethrough,
      color: color,
      highlight: highlight,
    );
  }

  /// Returns a copy with the foreground color set to [value] (nullable).
  RunFormat withColor(String? value) {
    return RunFormat(
      bold: bold,
      italic: italic,
      underline: underline,
      strikethrough: strikethrough,
      color: value,
      highlight: highlight,
    );
  }

  /// Returns a copy with the highlight color set to [value] (nullable).
  RunFormat withHighlight(String? value) {
    return RunFormat(
      bold: bold,
      italic: italic,
      underline: underline,
      strikethrough: strikethrough,
      color: color,
      highlight: value,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RunFormat &&
        other.bold == bold &&
        other.italic == italic &&
        other.underline == underline &&
        other.strikethrough == strikethrough &&
        other.color == color &&
        other.highlight == highlight;
  }

  @override
  int get hashCode =>
      Object.hash(bold, italic, underline, strikethrough, color, highlight);
}

/// The total plain-text length of [runs] (in UTF-16 code units).
int runsLength(List<RichTextRun> runs) {
  var total = 0;
  for (final RichTextRun run in runs) {
    total += run.text.length;
  }
  return total;
}

/// The plain text of [runs].
String runsText(List<RichTextRun> runs) {
  final StringBuffer buffer = StringBuffer();
  for (final RichTextRun run in runs) {
    buffer.write(run.text);
  }
  return buffer.toString();
}

/// Merges adjacent runs with identical formatting and drops empty runs.
List<RichTextRun> normalizeRuns(List<RichTextRun> runs) {
  final List<RichTextRun> result = <RichTextRun>[];
  for (final RichTextRun run in runs) {
    if (run.text.isEmpty) {
      continue;
    }
    if (result.isNotEmpty &&
        RunFormat.fromRun(result.last) == RunFormat.fromRun(run)) {
      final RichTextRun previous = result.removeLast();
      result.add(previous.copyWith(text: previous.text + run.text));
    } else {
      result.add(run);
    }
  }
  return result;
}

/// Splits [runs] so that a run boundary exists at [offset].
///
/// [offset] is a plain-text index in `0..runsLength`. When it already falls on
/// a boundary (or is at either end) an equivalent list is returned unchanged.
List<RichTextRun> splitRunsAt(List<RichTextRun> runs, int offset) {
  if (offset <= 0) {
    return List<RichTextRun>.of(runs);
  }
  final List<RichTextRun> result = <RichTextRun>[];
  var cursor = 0;
  for (final RichTextRun run in runs) {
    final int runEnd = cursor + run.text.length;
    if (offset > cursor && offset < runEnd) {
      final int local = offset - cursor;
      result.add(run.copyWith(text: run.text.substring(0, local)));
      result.add(run.copyWith(text: run.text.substring(local)));
    } else {
      result.add(run);
    }
    cursor = runEnd;
  }
  return result;
}

/// Expands [runs] into one [RunFormat] per character.
List<RunFormat> formatsFromRuns(List<RichTextRun> runs) {
  final List<RunFormat> formats = <RunFormat>[];
  for (final RichTextRun run in runs) {
    final RunFormat format = RunFormat.fromRun(run);
    for (var i = 0; i < run.text.length; i += 1) {
      formats.add(format);
    }
  }
  return formats;
}

/// Builds normalized runs from [text] and a per-character [formats] list.
///
/// [formats] must have the same length as [text].
List<RichTextRun> runsFromFormats(String text, List<RunFormat> formats) {
  assert(
    text.length == formats.length,
    'formats length (${formats.length}) must match text length (${text.length})',
  );
  final List<RichTextRun> runs = <RichTextRun>[];
  var start = 0;
  while (start < text.length) {
    var end = start + 1;
    while (end < text.length && formats[end] == formats[start]) {
      end += 1;
    }
    runs.add(formats[start].applyTo(text.substring(start, end)));
    start = end;
  }
  return runs;
}

/// Returns the formatting applied to characters in `[start, end)` of [runs].
///
/// Applies [transform] to the formatting of every overlapping character and
/// leaves the rest unchanged. The resulting runs are normalized. Out-of-range
/// or empty ranges return a normalized copy of [runs].
List<RichTextRun> applyFormatToRange(
  List<RichTextRun> runs,
  int start,
  int end,
  RunFormat Function(RunFormat format) transform,
) {
  final String text = runsText(runs);
  final int from = start.clamp(0, text.length);
  final int to = end.clamp(0, text.length);
  if (from >= to) {
    return normalizeRuns(runs);
  }
  final List<RunFormat> formats = formatsFromRuns(runs);
  for (var i = from; i < to; i += 1) {
    formats[i] = transform(formats[i]);
  }
  return runsFromFormats(text, formats);
}

/// Returns the formatting that applies at caret [offset] within [runs].
///
/// The caret inherits the formatting of the character immediately before it
/// (standard word-processor behaviour), or of the following character when the
/// caret is at the very start. Returns [RunFormat.none] for empty content.
RunFormat formatAt(List<RichTextRun> runs, int offset) {
  final List<RunFormat> formats = formatsFromRuns(runs);
  if (formats.isEmpty) {
    return RunFormat.none;
  }
  final int index = (offset - 1).clamp(0, formats.length - 1);
  return formats[index];
}

/// Reconciles [runs] after the plain text changed from [oldText] to [newText].
///
/// Characters in the unchanged common prefix and suffix keep their original
/// formatting; newly inserted characters receive [insertedFormat]. This mirrors
/// how a text field reports incremental edits and keeps run formatting aligned
/// with the edited text. The result is normalized.
List<RichTextRun> reconcileRuns({
  required List<RichTextRun> runs,
  required String oldText,
  required String newText,
  required RunFormat insertedFormat,
}) {
  if (oldText == newText) {
    return normalizeRuns(runs);
  }
  final List<RunFormat> oldFormats = formatsFromRuns(runs);
  // The expansion length tracks oldText; guard against a desynced caller.
  final int oldLen = oldText.length;
  final int newLen = newText.length;

  var prefix = 0;
  final int maxPrefix = oldLen < newLen ? oldLen : newLen;
  while (prefix < maxPrefix && oldText[prefix] == newText[prefix]) {
    prefix += 1;
  }

  var suffix = 0;
  final int maxSuffix = maxPrefix - prefix;
  while (suffix < maxSuffix &&
      oldText[oldLen - 1 - suffix] == newText[newLen - 1 - suffix]) {
    suffix += 1;
  }

  final List<RunFormat> formats = <RunFormat>[];
  for (var i = 0; i < prefix; i += 1) {
    formats.add(i < oldFormats.length ? oldFormats[i] : insertedFormat);
  }
  for (var i = prefix; i < newLen - suffix; i += 1) {
    formats.add(insertedFormat);
  }
  for (var i = oldLen - suffix; i < oldLen; i += 1) {
    formats.add(
      i >= 0 && i < oldFormats.length ? oldFormats[i] : insertedFormat,
    );
  }
  return runsFromFormats(newText, formats);
}

/// The colour used to mark diff deviations on the reveal screen (`#RRGGBB`).
const String kDiffMarkColor = '#D32F2F';

/// Overlays the student's mistakes onto the expected value's rich-text runs.
///
/// Returns the expected [expectedRuns] with the diff against [enteredPlain]
/// painted on top, preserving every original run attribute except where a
/// deviation is flagged:
/// - a **substituted** character keeps its formatting but its `color` is set to
///   [kDiffMarkColor];
/// - a **missing** character (in the solution, absent from the entry) is marked
///   by a synthetic red `_` run inserted at that position;
/// - **extra** characters the student typed are shown in place, at the position
///   they were typed, as a red, struck-through run.
///
/// Alignment runs on [normalizeForDiff] of both texts (the same case/accent
/// folding used for scoring), so a difference the evaluator ignores — a case or
/// accent mismatch when the corresponding option is off — aligns as a match and
/// is never painted. A fully correct answer yields the expected runs unchanged.
List<RichTextRun> buildDiffRuns({
  required List<RichTextRun> expectedRuns,
  required String enteredPlain,
  TextMatchOptions options = const TextMatchOptions(),
}) {
  final String expected = runsText(expectedRuns);
  final List<RunFormat> expectedFormats = formatsFromRuns(expectedRuns);
  final List<DiffOp> ops = alignTexts(
    normalizeForDiff(expected, options),
    normalizeForDiff(enteredPlain, options),
  );

  final List<RichTextRun> result = <RichTextRun>[];
  for (final DiffOp op in ops) {
    switch (op.kind) {
      case DiffOpKind.match:
        result.add(
          expectedFormats[op.expectedIndex].applyTo(expected[op.expectedIndex]),
        );
      case DiffOpKind.substitute:
        result.add(
          expectedFormats[op.expectedIndex]
              .withColor(kDiffMarkColor)
              .applyTo(expected[op.expectedIndex]),
        );
      case DiffOpKind.delete:
        // The expected character is missing from the entry. Show the actual
        // character (so the complete solution stays visible), marked in the
        // diff colour and underlined to signal it was omitted rather than
        // mistyped.
        result.add(
          expectedFormats[op.expectedIndex]
              .withColor(kDiffMarkColor)
              .copyWith(underline: true)
              .applyTo(expected[op.expectedIndex]),
        );
      case DiffOpKind.insert:
        // An extra character the student typed. Show it in place — struck
        // through, at the position it was typed — so the correction stays where
        // the mistake is. Adjacent extras merge in [normalizeRuns].
        result.add(
          RichTextRun(
            text: enteredPlain[op.enteredIndex],
            color: kDiffMarkColor,
            strikethrough: true,
          ),
        );
    }
  }
  return normalizeRuns(result);
}
