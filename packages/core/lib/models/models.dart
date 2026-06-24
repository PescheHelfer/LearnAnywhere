/// Domain models for masks, decks, learning units, rich text values, and stats.
library;

/// Stable package identifier used by setup smoke tests.
const String corePackageName = 'learn_anywhere_core';

/// The maximum number of categories allowed in a mask.
const int maxCategoriesPerMask = 20;

/// The maximum number of fields allowed in a category.
const int maxFieldsPerCategory = 20;

/// The maximum category name length.
const int maxCategoryNameLength = 40;

/// The minimum stored field length.
const int minFieldLength = 1;

/// The maximum stored field length.
const int maxFieldLength = 80;

/// A query direction in a bidirectional deck.
enum QueryDirection {
  /// The first mask-defined query direction.
  direction1,

  /// The second mask-defined query direction.
  direction2,
}

/// A direction selection for a learning session or statistics view.
enum DirectionSelection {
  /// Use only direction 1.
  direction1,

  /// Use only direction 2.
  direction2,

  /// Use both directions.
  both,
}

/// A field's role in one query direction.
enum FieldRole {
  /// Question or prompt field.
  question('Q'),

  /// Answer field.
  answer('A'),

  /// Remark field revealed with the solution.
  remark('R');

  const FieldRole(this.code);

  /// The serialized one-letter role code.
  final String code;

  /// Parses a serialized role code.
  static FieldRole parse(String value) {
    return switch (value) {
      'Q' => FieldRole.question,
      'A' => FieldRole.answer,
      'R' => FieldRole.remark,
      _ => throw ArgumentError.value(value, 'value', 'Unknown field role'),
    };
  }
}

/// One formatting run inside a rich text field value.
final class RichTextRun {
  /// Creates a rich text run.
  const RichTextRun({
    required this.text,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.color,
    this.highlight,
  });

  /// The run text.
  final String text;

  /// Whether the run is bold.
  final bool bold;

  /// Whether the run is italic.
  final bool italic;

  /// Whether the run is underlined.
  final bool underline;

  /// Optional foreground color as `#RRGGBB`.
  final String? color;

  /// Optional highlight color as `#RRGGBB`.
  final String? highlight;

  /// Returns a copy with selected fields changed.
  RichTextRun copyWith({
    String? text,
    bool? bold,
    bool? italic,
    bool? underline,
    String? color,
    String? highlight,
  }) {
    return RichTextRun(
      text: text ?? this.text,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      color: color ?? this.color,
      highlight: highlight ?? this.highlight,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RichTextRun &&
        other.text == text &&
        other.bold == bold &&
        other.italic == italic &&
        other.underline == underline &&
        other.color == color &&
        other.highlight == highlight;
  }

  @override
  int get hashCode =>
      Object.hash(text, bold, italic, underline, color, highlight);
}

/// A stored field value, either plain text or rich text runs.
sealed class FieldValue {
  const FieldValue();

  /// Creates a plain text value.
  const factory FieldValue.plain(String text) = PlainFieldValue;

  /// Creates a rich text value.
  factory FieldValue.rich(List<RichTextRun> runs) = RichFieldValue;

  /// An empty plain text value.
  static const FieldValue empty = PlainFieldValue('');

  /// Plain text used for search and answer evaluation.
  String get plainText;

  /// Whether this value is empty after trimming plain text.
  bool get isBlank => plainText.trim().isEmpty;
}

/// A field value stored as a plain string.
final class PlainFieldValue extends FieldValue {
  /// Creates a plain string field value.
  const PlainFieldValue(this.text);

  /// The stored text.
  final String text;

  @override
  String get plainText => text;

  @override
  bool operator ==(Object other) =>
      other is PlainFieldValue && other.text == text;

  @override
  int get hashCode => text.hashCode;
}

/// A field value stored as formatted runs.
final class RichFieldValue extends FieldValue {
  /// Creates a rich text field value.
  RichFieldValue(List<RichTextRun> runs) : runs = List.unmodifiable(runs);

  /// Ordered rich text runs.
  final List<RichTextRun> runs;

  @override
  String get plainText => runs.map((RichTextRun run) => run.text).join();

  @override
  bool operator ==(Object other) {
    if (other is! RichFieldValue || other.runs.length != runs.length) {
      return false;
    }
    for (var index = 0; index < runs.length; index += 1) {
      if (runs[index] != other.runs[index]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(runs);
}

/// A single field declared by a category.
final class FieldDefinition {
  /// Creates a field definition.
  const FieldDefinition({
    required this.name,
    required this.length,
    required this.equalGroup,
    required this.role1,
    required this.role2,
  });

  /// The user-visible field label. Empty means hidden.
  final String name;

  /// The maximum stored text length.
  final int length;

  /// Interchangeable answer group, or zero for positional matching.
  final int equalGroup;

  /// The field role in direction 1.
  final FieldRole role1;

  /// The field role in direction 2.
  final FieldRole role2;

  /// Whether this field should be hidden in the applications.
  bool get isHidden => name.isEmpty;

  /// Returns this field's role for [direction].
  FieldRole roleFor(QueryDirection direction) {
    return switch (direction) {
      QueryDirection.direction1 => role1,
      QueryDirection.direction2 => role2,
    };
  }
}

/// A named category containing an ordered field schema.
final class CategoryDefinition {
  /// Creates a category definition.
  const CategoryDefinition({
    required this.id,
    required this.name,
    required this.fields,
  });

  /// Stable category identifier used by learning units.
  final int id;

  /// User-authored category name.
  final String name;

  /// Ordered fields declared by this category.
  final List<FieldDefinition> fields;

  /// Returns the fields with [role] in [direction].
  List<FieldDefinition> fieldsForRole(
    QueryDirection direction,
    FieldRole role, {
    bool includeHidden = false,
  }) {
    return fields
        .where(
          (FieldDefinition field) =>
              field.roleFor(direction) == role &&
              (includeHidden || !field.isHidden),
        )
        .toList(growable: false);
  }

  /// Finds a field by name.
  FieldDefinition? fieldNamed(String name) {
    for (final FieldDefinition field in fields) {
      if (field.name == name) {
        return field;
      }
    }
    return null;
  }
}

/// A user-authored mask defining schema and direction labels.
final class LearningMask {
  /// Creates a learning mask.
  const LearningMask({
    required this.name,
    required this.direction1Label,
    required this.direction2Label,
    required this.categories,
  });

  /// User-authored mask name.
  final String name;

  /// User-authored label for direction 1.
  final String direction1Label;

  /// User-authored label for direction 2.
  final String direction2Label;

  /// Ordered category definitions.
  final List<CategoryDefinition> categories;

  /// Finds a category by id.
  CategoryDefinition? categoryById(int id) {
    for (final CategoryDefinition category in categories) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }
}

/// One ordered learning unit in a deck.
final class LearningUnit {
  /// Creates a learning unit.
  const LearningUnit({required this.categoryId, required this.fields});

  /// Category id this unit belongs to.
  final int categoryId;

  /// Stored values keyed by field name.
  final Map<String, FieldValue> fields;

  /// Returns the value for [fieldName], or an empty value when absent.
  FieldValue valueForField(String fieldName) {
    return fields[fieldName] ?? FieldValue.empty;
  }
}

/// A self-contained learning deck with an embedded mask.
final class LearningDeck {
  /// Creates a learning deck.
  const LearningDeck({required this.mask, required this.units});

  /// The embedded mask.
  final LearningMask mask;

  /// Ordered units. Their displayed indices are one-based.
  final List<LearningUnit> units;

  /// Returns the category for [unit].
  CategoryDefinition categoryForUnit(LearningUnit unit) {
    final CategoryDefinition? category = mask.categoryById(unit.categoryId);
    if (category == null) {
      throw StateError('Unknown category id ${unit.categoryId}.');
    }
    return category;
  }
}

/// Statistics for one unit in one direction.
final class DirectionStats {
  /// Creates direction statistics.
  const DirectionStats({this.attempts = 0, this.correct = 0});

  /// Number of counted attempts.
  final int attempts;

  /// Number of counted correct attempts.
  final int correct;

  /// Number of counted wrong attempts.
  int get wrong => attempts - correct;

  /// Hit rate, or `null` when the item has not yet been queried.
  double? get hitRate => attempts == 0 ? null : correct / attempts;

  /// Returns a copy with selected fields changed.
  DirectionStats copyWith({int? attempts, int? correct}) {
    return DirectionStats(
      attempts: attempts ?? this.attempts,
      correct: correct ?? this.correct,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DirectionStats &&
        other.attempts == attempts &&
        other.correct == correct;
  }

  @override
  int get hashCode => Object.hash(attempts, correct);
}

/// Statistics for one unit in both directions.
final class UnitStats {
  /// Creates unit statistics.
  const UnitStats({
    required this.index,
    this.direction1 = const DirectionStats(),
    this.direction2 = const DirectionStats(),
  });

  /// One-based unit index.
  final int index;

  /// Statistics for direction 1.
  final DirectionStats direction1;

  /// Statistics for direction 2.
  final DirectionStats direction2;

  /// Returns the stats for [direction].
  DirectionStats statsFor(QueryDirection direction) {
    return switch (direction) {
      QueryDirection.direction1 => direction1,
      QueryDirection.direction2 => direction2,
    };
  }

  /// Returns a copy with stats for [direction] replaced.
  UnitStats withDirectionStats(QueryDirection direction, DirectionStats stats) {
    return switch (direction) {
      QueryDirection.direction1 => UnitStats(
        index: index,
        direction1: stats,
        direction2: direction2,
      ),
      QueryDirection.direction2 => UnitStats(
        index: index,
        direction1: direction1,
        direction2: stats,
      ),
    };
  }
}

/// A `.sta` sidecar file model.
final class StatisticsFile {
  /// Creates a statistics sidecar model.
  const StatisticsFile({required this.deckRef, required this.perUnit});

  /// Deck path or file name referenced by this statistics file.
  final String deckRef;

  /// Per-unit statistics.
  final List<UnitStats> perUnit;
}

/// Query options shared by evaluation and search normalization.
final class TextMatchOptions {
  /// Creates text matching options.
  const TextMatchOptions({
    this.caseSensitive = false,
    this.accentSensitive = false,
  });

  /// Whether case differences are significant.
  final bool caseSensitive;

  /// Whether accent differences are significant.
  final bool accentSensitive;
}

/// Answer evaluation options.
final class AnswerEvaluationOptions extends TextMatchOptions {
  /// Creates answer evaluation options.
  const AnswerEvaluationOptions({
    super.caseSensitive,
    super.accentSensitive,
    this.completeInputRequired = true,
  });

  /// Whether all non-empty solution fields must be answered.
  final bool completeInputRequired;
}

/// A selected unit and direction in a learning session.
final class SessionItem {
  /// Creates a session item.
  const SessionItem({required this.unitIndex, required this.direction});

  /// One-based unit index.
  final int unitIndex;

  /// Query direction.
  final QueryDirection direction;

  @override
  bool operator ==(Object other) {
    return other is SessionItem &&
        other.unitIndex == unitIndex &&
        other.direction == direction;
  }

  @override
  int get hashCode => Object.hash(unitIndex, direction);
}

/// Learning session mode.
enum SessionMode {
  /// Endless random practice.
  practice,

  /// Mastery-loop super-query (drill mode).
  superQuery,

  /// Present every in-scope item exactly once, then finish.
  onceThrough,
}

/// Learning session parameters retained for interrupt and resume.
final class SessionParameters {
  /// Creates session parameters.
  const SessionParameters({
    this.directionSelection = DirectionSelection.both,
    this.startIndex,
    this.endIndex,
    this.withInput = true,
    this.mode = SessionMode.practice,
    this.shuffle = false,
    this.superStatusThreshold = 0.4,
    this.minimumAttemptsGuardEnabled = false,
    this.minAttempts = 2,
  });

  /// Selected direction scope.
  final DirectionSelection directionSelection;

  /// Optional one-based start index.
  final int? startIndex;

  /// Optional one-based end index.
  final int? endIndex;

  /// Whether the user types answers.
  final bool withInput;

  /// Session mode.
  final SessionMode mode;

  /// Whether in-scope units are presented in random order.
  ///
  /// When `false`, units are presented in the order they are stored in the deck.
  final bool shuffle;

  /// Required hit rate for super-query mastery.
  final double superStatusThreshold;

  /// Whether mastery additionally requires [minAttempts].
  final bool minimumAttemptsGuardEnabled;

  /// Minimum attempts required when the guard is enabled.
  final int minAttempts;

  /// Returns a copy with selected fields changed.
  SessionParameters copyWith({
    DirectionSelection? directionSelection,
    int? startIndex,
    int? endIndex,
    bool? withInput,
    SessionMode? mode,
    bool? shuffle,
    double? superStatusThreshold,
    bool? minimumAttemptsGuardEnabled,
    int? minAttempts,
  }) {
    return SessionParameters(
      directionSelection: directionSelection ?? this.directionSelection,
      startIndex: startIndex ?? this.startIndex,
      endIndex: endIndex ?? this.endIndex,
      withInput: withInput ?? this.withInput,
      mode: mode ?? this.mode,
      shuffle: shuffle ?? this.shuffle,
      superStatusThreshold: superStatusThreshold ?? this.superStatusThreshold,
      minimumAttemptsGuardEnabled:
          minimumAttemptsGuardEnabled ?? this.minimumAttemptsGuardEnabled,
      minAttempts: minAttempts ?? this.minAttempts,
    );
  }
}
