/// Domain models for masks, decks, learning units, rich text values, and stats.
library;

import 'dart:math';

/// Stable package identifier used by setup smoke tests.
const String corePackageName = 'learn_anywhere_core';

/// Prefix for mask IDs minted by THIS app for masks created here.
///
/// See [mintNewMaskId]. The Converter mints IDs with [legacyMaskIdPrefix]; this
/// app must never produce that prefix, so app-minted and converter-minted mask
/// IDs can never collide.
const String appMaskIdPrefix = 'm_new_';

/// Prefix reserved for the Converter's legacy mask IDs.
///
/// This app only ever READS mask IDs that use this prefix (from files); it never
/// mints one. Documented here so the convention is discoverable in one place.
const String legacyMaskIdPrefix = 'm_legacy_';

final Random _idRandom = Random.secure();

/// Mints a fresh, opaque [LearningMask.maskId] for a mask CREATED IN THIS APP.
///
/// The result is [appMaskIdPrefix] followed by a random v4 UUID. A maskId is an
/// opaque string: nothing in the app parses or recomputes it. Masks arriving
/// from files keep whatever maskId the file already carries — see
/// [LearningMask.maskId]. No hashing/crypto dependency is required; the UUID is
/// generated from [Random.secure].
String mintNewMaskId() => '$appMaskIdPrefix${_uuidV4()}';

String _uuidV4() {
  final List<int> bytes = List<int>.generate(
    16,
    (_) => _idRandom.nextInt(256),
  );
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // Version 4.
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant 1 (RFC 4122).
  final String hex = bytes
      .map((int b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

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

/// The default stored field length for a newly created field.
const int defaultFieldLength = 80;

/// The maximum Level-Learning support level (most scaffolding shown).
///
/// Levels run `0..3` where a higher number means MORE support: level 3 shows the
/// full solution, level 0 is free recall. The `.sta` per-level maps key on these
/// same integers.
const int kMaxSupportLevel = 3;

/// The minimum Level-Learning level: free recall, no scaffolding.
const int kFreeRecallLevel = 0;

/// Whether [level] is a valid Level-Learning level (`0..3`).
bool isValidLevel(int level) =>
    level >= kFreeRecallLevel && level <= kMaxSupportLevel;

/// The kind of a single [MaskCell] in a Level-Learning scaffold template.
enum MaskCellKind {
  /// An always-visible structural character (whitespace/punctuation).
  ///
  /// Rendered verbatim, not as an editable cell, and never counted as a mask
  /// candidate.
  shown,

  /// A locked, greyed letter the student sees but cannot edit.
  revealed,

  /// A cell the student must type into.
  blank,
}

/// One character of a Level-Learning scaffold template for an answer field.
///
/// Produced by `maskFieldValue`. The UI renders [char] according to [kind]:
/// [MaskCellKind.shown] verbatim, [MaskCellKind.revealed] as a locked letter, and
/// [MaskCellKind.blank] as an input the student fills.
final class MaskCell {
  /// Creates a mask cell.
  const MaskCell(this.char, this.kind);

  /// The source character this cell represents.
  final String char;

  /// How the UI should render this cell.
  final MaskCellKind kind;

  @override
  bool operator ==(Object other) =>
      other is MaskCell && other.char == char && other.kind == kind;

  @override
  int get hashCode => Object.hash(char, kind);

  @override
  String toString() => 'MaskCell($char, ${kind.name})';
}

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
    this.strikethrough = false,
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

  /// Whether the run is struck through.
  final bool strikethrough;

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
    bool? strikethrough,
    String? color,
    String? highlight,
  }) {
    return RichTextRun(
      text: text ?? this.text,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      strikethrough: strikethrough ?? this.strikethrough,
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
        other.strikethrough == strikethrough &&
        other.color == color &&
        other.highlight == highlight;
  }

  @override
  int get hashCode =>
      Object.hash(text, bold, italic, underline, strikethrough, color, highlight);
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
    required this.id,
    required this.name,
    required this.length,
    required this.equalGroup,
    required this.role1,
    required this.role2,
  });

  /// Stable field identifier, unique WITHIN its owning mask.
  ///
  /// Assigned once at creation as a 0-based integer (first field created in a
  /// mask gets 0, the next 1, and so on) and NEVER reused, renumbered, or
  /// changed. Deleting a field does not recycle its id; the next new field
  /// takes `max existing + 1`. Reordering fields changes only their array
  /// position, never their id. Unit field VALUES are keyed by this id, so a
  /// field can be renamed or reordered without breaking stored data. These
  /// integers only need to be unique within one mask; a single assigner (this
  /// app, or the Converter for legacy files) guarantees that — no hashing.
  final int id;

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
  ///
  /// Assigned once at creation as a 0-based integer (first category created in a
  /// mask gets 0, the next 1, and so on) and NEVER reused, renumbered, or
  /// changed. Deleting a category does not recycle its id; the next new category
  /// takes `max existing + 1`. Reordering categories changes only their array
  /// position (which defines display order), never their id. Units reference
  /// categories by this id, so categories can be renamed or reordered without
  /// breaking unit links. Unique within one mask.
  final int id;

  /// User-authored category name.
  final String name;

  /// Ordered fields declared by this category.
  ///
  /// Display order is defined by array position; there is no separate sort
  /// field. Field ids are independent of position.
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

  /// Finds a field by its stable [FieldDefinition.id].
  FieldDefinition? fieldById(int id) {
    for (final FieldDefinition field in fields) {
      if (field.id == id) {
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
    required this.maskId,
    required this.name,
    required this.direction1Label,
    required this.direction2Label,
    required this.categories,
    this.revision = 0,
  });

  /// Opaque unique identifier for this mask.
  ///
  /// This app only ever READS this string (for masks loaded from files) or
  /// MINTS a fresh one for masks created here via [mintNewMaskId] (prefix
  /// [appMaskIdPrefix]). It is NEVER recomputed from mask contents. The
  /// Converter mints IDs with a different prefix ([legacyMaskIdPrefix]), so
  /// app-minted and converter-minted IDs can never collide. Two `.inf`/`.vok`
  /// files describe "the same mask" iff their maskIds are equal.
  final String maskId;

  /// Monotonic revision, bumped on each `.inf` save.
  ///
  /// Used to tell copies of the same mask (same [maskId]) apart and to record
  /// which revision a deck's embedded mask cache is synced to.
  final int revision;

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

  /// Returns a copy with selected fields changed.
  ///
  /// The [maskId] is preserved unless explicitly overridden — schema edits never
  /// change identity; only an explicit fork mints a new id.
  LearningMask copyWith({
    String? maskId,
    int? revision,
    String? name,
    String? direction1Label,
    String? direction2Label,
    List<CategoryDefinition>? categories,
  }) {
    return LearningMask(
      maskId: maskId ?? this.maskId,
      revision: revision ?? this.revision,
      name: name ?? this.name,
      direction1Label: direction1Label ?? this.direction1Label,
      direction2Label: direction2Label ?? this.direction2Label,
      categories: categories ?? this.categories,
    );
  }
}

/// One ordered learning unit in a deck.
final class LearningUnit {
  /// Creates a learning unit.
  const LearningUnit({required this.categoryId, required this.fields});

  /// Category id this unit belongs to.
  final int categoryId;

  /// Stored values keyed by [FieldDefinition.id].
  ///
  /// Keying by the stable field id (not the field name) is what lets a field be
  /// renamed or reordered without touching stored unit data. In `.vok` files
  /// these ids are serialized as JSON string keys; the field's display name
  /// lives only in the embedded mask.
  final Map<int, FieldValue> fields;

  /// Returns the value for the field with [fieldId], or empty when absent.
  FieldValue valueForFieldId(int fieldId) {
    return fields[fieldId] ?? FieldValue.empty;
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

/// Level-Learning statistics for one direction of one unit.
///
/// [currentLevel] is the unit's active support level (`0..3`). [levels] holds one
/// [DirectionStats] per level, keyed by the level integers `3, 2, 1, 0` — each a
/// track record built while the unit sat at that level. When a level is mastered
/// the unit promotes to the next lower level, whose counters start fresh at 0/0.
final class LevelDirectionStats {
  /// Creates Level-Learning direction statistics.
  const LevelDirectionStats({
    required this.currentLevel,
    required this.levels,
  });

  /// Returns fresh stats at [startLevel] with all four level counters at 0/0.
  factory LevelDirectionStats.fresh(int startLevel) {
    return LevelDirectionStats(
      currentLevel: startLevel,
      levels: <int, DirectionStats>{
        for (var level = kMaxSupportLevel; level >= kFreeRecallLevel; level -= 1)
          level: const DirectionStats(),
      },
    );
  }

  /// The active support level, `0..3`.
  final int currentLevel;

  /// Per-level statistics keyed by level integer (`3, 2, 1, 0`).
  final Map<int, DirectionStats> levels;

  /// The statistics for the [currentLevel].
  DirectionStats get currentLevelStats =>
      levels[currentLevel] ?? const DirectionStats();

  /// Returns a copy with [level]'s stats replaced.
  LevelDirectionStats withLevelStats(int level, DirectionStats stats) {
    return LevelDirectionStats(
      currentLevel: currentLevel,
      levels: <int, DirectionStats>{...levels, level: stats},
    );
  }

  /// Returns a copy with [currentLevel] replaced.
  LevelDirectionStats withCurrentLevel(int level) {
    return LevelDirectionStats(currentLevel: level, levels: levels);
  }

  @override
  bool operator ==(Object other) {
    if (other is! LevelDirectionStats ||
        other.currentLevel != currentLevel ||
        other.levels.length != levels.length) {
      return false;
    }
    for (final MapEntry<int, DirectionStats> entry in levels.entries) {
      if (other.levels[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    currentLevel,
    Object.hashAllUnordered(
      levels.entries.map(
        (MapEntry<int, DirectionStats> e) => Object.hash(e.key, e.value),
      ),
    ),
  );
}

/// Level-Learning statistics for one unit in both directions.
final class LevelUnitStats {
  /// Creates Level-Learning unit statistics.
  const LevelUnitStats({
    required this.index,
    required this.dir1,
    required this.dir2,
  });

  /// One-based unit index.
  final int index;

  /// Level-Learning statistics for direction 1.
  final LevelDirectionStats dir1;

  /// Level-Learning statistics for direction 2.
  final LevelDirectionStats dir2;

  /// Returns the Level-Learning stats for [direction].
  LevelDirectionStats statsFor(QueryDirection direction) {
    return switch (direction) {
      QueryDirection.direction1 => dir1,
      QueryDirection.direction2 => dir2,
    };
  }

  /// Returns a copy with the stats for [direction] replaced.
  LevelUnitStats withDirectionStats(
    QueryDirection direction,
    LevelDirectionStats stats,
  ) {
    return switch (direction) {
      QueryDirection.direction1 => LevelUnitStats(
        index: index,
        dir1: stats,
        dir2: dir2,
      ),
      QueryDirection.direction2 => LevelUnitStats(
        index: index,
        dir1: dir1,
        dir2: stats,
      ),
    };
  }
}

/// The optional Level-Learning section of a `.sta` file (format v2).
final class LevelLearningStats {
  /// Creates a Level-Learning statistics section.
  const LevelLearningStats({required this.perUnit});

  /// Per-unit Level-Learning statistics.
  final List<LevelUnitStats> perUnit;
}

/// A `.sta` sidecar file model.
final class StatisticsFile {
  /// Creates a statistics sidecar model.
  const StatisticsFile({
    required this.deckRef,
    required this.perUnit,
    this.levelLearning,
    this.lastSessionMode,
  });

  /// Deck path or file name referenced by this statistics file.
  final String deckRef;

  /// Per-unit statistics.
  final List<UnitStats> perUnit;

  /// Optional Level-Learning section (present in format v2 files only).
  final LevelLearningStats? levelLearning;

  /// Mode of the session that last wrote these statistics, when known.
  ///
  /// Lets the shell notice that a session is starting in a different mode than
  /// the one the stored numbers came from. `null` in files written before this
  /// field existed, which simply means "unknown" — no prompt.
  final SessionMode? lastSessionMode;
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
  /// Level-Learning: a per-word scaffold ladder from full solution to free recall.
  levelLearning,

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
    this.masteryThreshold = 0.4,
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

  /// Required hit rate for mastery.
  final double masteryThreshold;

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
    double? masteryThreshold,
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
      masteryThreshold: masteryThreshold ?? this.masteryThreshold,
      minimumAttemptsGuardEnabled:
          minimumAttemptsGuardEnabled ?? this.minimumAttemptsGuardEnabled,
      minAttempts: minAttempts ?? this.minAttempts,
    );
  }
}
