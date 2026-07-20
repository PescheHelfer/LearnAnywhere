/// Pure Dart learning, evaluation, statistics, and search engines.
library;

import 'dart:math';

import 'package:diacritic/diacritic.dart';

import '../models/models.dart';

/// Field-level answer evaluation result.
final class FieldEvaluation {
  /// Creates a field-level evaluation result.
  const FieldEvaluation({
    required this.fieldName,
    required this.expected,
    required this.entered,
    required this.correct,
  });

  /// Field name evaluated.
  final String fieldName;

  /// Expected normalized value.
  final String expected;

  /// Entered normalized value.
  final String entered;

  /// Whether this field or pooled group member matched.
  final bool correct;
}

/// Answer evaluation result for one unit.
final class AnswerEvaluation {
  /// Creates an answer evaluation result.
  const AnswerEvaluation({required this.correct, required this.fields});

  /// Whether the whole unit attempt is correct.
  final bool correct;

  /// Field-level results for UI feedback.
  final List<FieldEvaluation> fields;
}

/// Rating choices after a revealed answer.
enum AttemptRating {
  /// Count the attempt as correct.
  correct,

  /// Count the attempt as wrong.
  wrong,

  /// Do not change statistics.
  noCount,
}

/// Wrong-answer ceiling options.
final class WrongAnswerCeiling {
  /// Creates wrong-answer ceiling options.
  const WrongAnswerCeiling({this.enabled = false, this.value = 10});

  /// Whether the ceiling is enabled.
  final bool enabled;

  /// Maximum wrong answers to record per item and direction.
  final int value;
}

/// Statistics direction view.
enum StatisticsDirectionView {
  /// Combine both directions for each unit.
  combined,

  /// Use only direction 1.
  direction1,

  /// Use only direction 2.
  direction2,
}

/// Hit-rate bucket for statistics aggregation.
enum HitRateBucket {
  /// 100% hit rate.
  perfect,

  /// 75-99% hit rate.
  good,

  /// 50-74% hit rate.
  fair,

  /// 25-49% hit rate.
  unsure,

  /// 1-24% hit rate.
  veryUnsure,

  /// 0% hit rate.
  neverKnown,

  /// No attempts yet.
  notYetQueried,
}

/// Count and percentages for one statistics bucket.
final class BucketSummary {
  /// Creates a bucket summary.
  const BucketSummary({
    required this.bucket,
    required this.count,
    required this.percentageOfAll,
    required this.percentageOfQueried,
  });

  /// Bucket represented by this summary.
  final HitRateBucket bucket;

  /// Number of units in the bucket.
  final int count;

  /// Relative share of all units in scope.
  final double percentageOfAll;

  /// Relative share of queried units in scope.
  final double percentageOfQueried;
}

/// Aggregated statistics for a unit scope.
final class StatisticsSummary {
  /// Creates a statistics summary.
  const StatisticsSummary({
    required this.totalUnits,
    required this.queriedUnits,
    required this.buckets,
  });

  /// Number of units in scope.
  final int totalUnits;

  /// Number of units with at least one attempt.
  final int queriedUnits;

  /// Bucket summaries in legacy display order.
  final List<BucketSummary> buckets;
}

/// A memory or file-oriented search result.
final class SearchResult {
  /// Creates a search result.
  const SearchResult({
    required this.unitIndex,
    required this.categoryId,
    required this.matchedFieldNames,
    this.sourceFile,
  });

  /// One-based unit index in the searched deck.
  final int unitIndex;

  /// Category id of the matching unit.
  final int categoryId;

  /// Named fields that matched the query.
  final List<String> matchedFieldNames;

  /// Optional source file for file-oriented search.
  final String? sourceFile;
}

/// Normalizes text for answer comparison and search.
String normalizeText(String value, TextMatchOptions options) {
  var normalized = value.trim();
  if (!options.caseSensitive) {
    normalized = normalized.toLowerCase();
  }
  if (!options.accentSensitive) {
    normalized = removeDiacritics(normalized);
  }
  return normalized;
}

/// Returns prompt fields and values for a unit and direction.
Map<FieldDefinition, FieldValue> promptFields(
  LearningDeck deck,
  LearningUnit unit,
  QueryDirection direction,
) {
  return _fieldsForRole(deck, unit, direction, FieldRole.question);
}

/// Returns answer fields and values for a unit and direction.
Map<FieldDefinition, FieldValue> answerFields(
  LearningDeck deck,
  LearningUnit unit,
  QueryDirection direction,
) {
  return _fieldsForRole(deck, unit, direction, FieldRole.answer);
}

/// Returns remark fields and values for a unit and direction.
Map<FieldDefinition, FieldValue> remarkFields(
  LearningDeck deck,
  LearningUnit unit,
  QueryDirection direction,
) {
  return _fieldsForRole(deck, unit, direction, FieldRole.remark);
}

/// Evaluates an entered answer map against the deck solution.
AnswerEvaluation evaluateAnswer({
  required LearningDeck deck,
  required LearningUnit unit,
  required QueryDirection direction,
  required Map<int, FieldValue> enteredValues,
  AnswerEvaluationOptions options = const AnswerEvaluationOptions(),
}) {
  final CategoryDefinition category = deck.categoryForUnit(unit);
  final List<FieldDefinition> answerFields = category.fieldsForRole(
    direction,
    FieldRole.answer,
  );
  final List<FieldEvaluation> fieldResults = <FieldEvaluation>[];
  var allCorrect = true;

  final Map<int, List<FieldDefinition>> grouped =
      <int, List<FieldDefinition>>{};
  for (final FieldDefinition field in answerFields) {
    grouped.putIfAbsent(field.equalGroup, () => <FieldDefinition>[]).add(field);
  }

  for (final MapEntry<int, List<FieldDefinition>> entry in grouped.entries) {
    final int equalGroup = entry.key;
    final List<FieldDefinition> fields = entry.value;
    if (equalGroup == 0) {
      for (final FieldDefinition field in fields) {
        final FieldEvaluation result = _evaluatePositionalField(
          unit,
          field,
          enteredValues,
          options,
        );
        fieldResults.add(result);
        allCorrect = allCorrect && result.correct;
      }
    } else {
      final List<FieldEvaluation> results = _evaluateEqualGroup(
        unit,
        fields,
        enteredValues,
        options,
      );
      fieldResults.addAll(results);
      allCorrect =
          allCorrect &&
          results.every((FieldEvaluation result) => result.correct);
    }
  }

  return AnswerEvaluation(
    correct: allCorrect,
    fields: List<FieldEvaluation>.unmodifiable(fieldResults),
  );
}

/// Applies a final attempt rating to direction statistics.
DirectionStats recordAttempt(
  DirectionStats stats,
  AttemptRating rating, {
  WrongAnswerCeiling wrongAnswerCeiling = const WrongAnswerCeiling(),
}) {
  return switch (rating) {
    AttemptRating.noCount => stats,
    AttemptRating.correct => stats.copyWith(
      attempts: stats.attempts + 1,
      correct: stats.correct + 1,
    ),
    AttemptRating.wrong =>
      wrongAnswerCeiling.enabled && stats.wrong >= wrongAnswerCeiling.value
          ? stats
          : stats.copyWith(attempts: stats.attempts + 1),
  };
}

/// Returns whether [stats] meets super-query mastery requirements.
bool isMastered(DirectionStats stats, SessionParameters parameters) {
  final double? hitRate = stats.hitRate;
  if (hitRate == null || hitRate < parameters.masteryThreshold) {
    return false;
  }
  if (parameters.minimumAttemptsGuardEnabled &&
      stats.attempts < parameters.minAttempts) {
    return false;
  }
  return true;
}

/// Recomputes the active super-query pool from current statistics.
List<SessionItem> activeSuperQueryPool({
  required LearningDeck deck,
  required List<UnitStats> statistics,
  required SessionParameters parameters,
}) {
  final List<SessionItem> items = <SessionItem>[];
  final Set<QueryDirection> directions = _directionsFor(
    parameters.directionSelection,
  );
  final int start = parameters.startIndex ?? 1;
  final int end = parameters.endIndex ?? deck.units.length;
  final Map<int, UnitStats> statsByIndex = _statsByIndex(statistics);

  for (
    var index = start;
    index <= end && index <= deck.units.length;
    index += 1
  ) {
    if (index < 1) {
      continue;
    }
    final UnitStats unitStats = statsByIndex[index] ?? UnitStats(index: index);
    for (final QueryDirection direction in directions) {
      if (!isMastered(unitStats.statsFor(direction), parameters)) {
        items.add(SessionItem(unitIndex: index, direction: direction));
      }
    }
  }
  return List<SessionItem>.unmodifiable(items);
}

/// Selects a random practice item, or `null` when the each-once set is exhausted.
///
/// In [SessionMode.onceThrough] each item is served at most once, so the result
/// is `null` once every in-scope item has been seen.
SessionItem? pickPracticeItem({
  required LearningDeck deck,
  required SessionParameters parameters,
  required Random random,
  Set<SessionItem> seenItems = const <SessionItem>{},
}) {
  final List<SessionItem> candidates = itemsInScope(deck, parameters);
  final List<SessionItem> available =
      parameters.mode == SessionMode.onceThrough
      ? candidates
            .where((SessionItem item) => !seenItems.contains(item))
            .toList(growable: false)
      : candidates;
  if (available.isEmpty) {
    return null;
  }
  return available[random.nextInt(available.length)];
}

/// Returns every in-scope item for [parameters] in deck (file) order.
///
/// Items follow the unit order stored in the deck; each in-scope unit yields one
/// item per selected direction.
List<SessionItem> itemsInScope(
  LearningDeck deck,
  SessionParameters parameters,
) {
  return List<SessionItem>.unmodifiable(_allItemsInScope(deck, parameters));
}

/// Returns the in-scope items in presentation order for a session.
///
/// When [SessionParameters.shuffle] is `true` the items are returned in a
/// random permutation (driven by [random]); otherwise they follow deck order.
List<SessionItem> sessionItemOrder({
  required LearningDeck deck,
  required SessionParameters parameters,
  required Random random,
}) {
  final List<SessionItem> items = _allItemsInScope(deck, parameters);
  if (parameters.shuffle) {
    items.shuffle(random);
  }
  return List<SessionItem>.unmodifiable(items);
}

/// Aggregates hit-rate buckets for a unit scope and direction view.
StatisticsSummary aggregateStatistics({
  required int unitCount,
  required List<UnitStats> statistics,
  StatisticsDirectionView view = StatisticsDirectionView.combined,
  int? startIndex,
  int? endIndex,
}) {
  final int start = startIndex ?? 1;
  final int end = endIndex ?? unitCount;
  final Map<int, UnitStats> statsByIndex = _statsByIndex(statistics);
  final Map<HitRateBucket, int> counts = <HitRateBucket, int>{
    for (final HitRateBucket bucket in HitRateBucket.values) bucket: 0,
  };
  var total = 0;
  var queried = 0;

  for (var index = start; index <= end && index <= unitCount; index += 1) {
    if (index < 1) {
      continue;
    }
    total += 1;
    final UnitStats unitStats = statsByIndex[index] ?? UnitStats(index: index);
    final DirectionStats stats = statsForDirectionView(unitStats, view);
    final HitRateBucket bucket = bucketFor(stats);
    counts[bucket] = counts[bucket]! + 1;
    if (stats.attempts > 0) {
      queried += 1;
    }
  }

  final List<BucketSummary> buckets = HitRateBucket.values
      .map(
        (HitRateBucket bucket) => BucketSummary(
          bucket: bucket,
          count: counts[bucket]!,
          percentageOfAll: total == 0 ? 0 : counts[bucket]! / total,
          percentageOfQueried:
              queried == 0 || bucket == HitRateBucket.notYetQueried
              ? 0
              : counts[bucket]! / queried,
        ),
      )
      .toList(growable: false);
  return StatisticsSummary(
    totalUnits: total,
    queriedUnits: queried,
    buckets: buckets,
  );
}

/// Returns the statistics bucket for [stats].
HitRateBucket bucketFor(DirectionStats stats) {
  final double? hitRate = stats.hitRate;
  if (hitRate == null) {
    return HitRateBucket.notYetQueried;
  }
  if (hitRate == 1) {
    return HitRateBucket.perfect;
  }
  if (hitRate >= 0.75) {
    return HitRateBucket.good;
  }
  if (hitRate >= 0.5) {
    return HitRateBucket.fair;
  }
  if (hitRate >= 0.25) {
    return HitRateBucket.unsure;
  }
  if (hitRate > 0) {
    return HitRateBucket.veryUnsure;
  }
  return HitRateBucket.neverKnown;
}

// --- Level Learning: statistics matrix --------------------------------------

/// One `(unit, direction)` placement in the Level×Bucket matrix.
///
/// Carries the direction that placed the unit and that level's own track-record
/// [stats], so the drill-down list can show the level-specific attempts/accuracy
/// (not the unit's other-mode counters).
final class LevelMatrixEntry {
  /// Creates a matrix cell entry.
  const LevelMatrixEntry({
    required this.unitIndex,
    required this.direction,
    required this.stats,
  });

  /// One-based unit index.
  final int unitIndex;

  /// Direction whose Level-Learning stats placed the unit in this cell.
  final QueryDirection direction;

  /// The unit's `levels[currentLevel]` counters for [direction].
  final DirectionStats stats;
}

/// A Level×Bucket count matrix for the Level-Learning statistics tab.
///
/// Rows are the four support levels (`0..3`), columns the seven
/// [HitRateBucket]s. Counts are over `(unit, direction)` entries, so in the
/// combined view a unit at different levels per direction contributes twice.
final class LevelBucketMatrix {
  /// Creates a Level×Bucket matrix.
  const LevelBucketMatrix({
    required this.cells,
    required this.rowTotals,
    required this.columnTotals,
    required this.grandTotal,
  });

  /// Per-cell entries keyed by level then bucket (every level/bucket present).
  final Map<int, Map<HitRateBucket, List<LevelMatrixEntry>>> cells;

  /// Entry count per level (the row's own total).
  final Map<int, int> rowTotals;

  /// Entry count per bucket across all levels (the column's own total).
  final Map<HitRateBucket, int> columnTotals;

  /// Total entries in scope.
  final int grandTotal;

  /// Entries currently at [level] in [bucket] (empty when none).
  List<LevelMatrixEntry> entriesAt(int level, HitRateBucket bucket) {
    return cells[level]?[bucket] ?? const <LevelMatrixEntry>[];
  }

  /// Count of entries currently at [level] in [bucket].
  int countAt(int level, HitRateBucket bucket) {
    return entriesAt(level, bucket).length;
  }
}

/// Builds the Level×Bucket matrix for the Level-Learning statistics tab.
///
/// Each in-scope unit ([unitIndices]) that has a [levelStatistics] entry
/// contributes one entry per selected direction ([view]); the combined view
/// counts both directions independently (Batch 1 pool convention — see
/// [activeLevelLearningPool]), so a unit at different levels per direction lands
/// in two rows. An entry sits in the row of its `currentLevel` and the column of
/// `bucketFor(levels[currentLevel])`. Units without a Level-Learning entry are
/// excluded (they have not yet entered Level Learning). Row, column, and grand
/// totals count entries, not distinct units.
LevelBucketMatrix levelBucketMatrix({
  required List<LevelUnitStats> levelStatistics,
  required List<int> unitIndices,
  StatisticsDirectionView view = StatisticsDirectionView.combined,
}) {
  final Map<int, LevelUnitStats> byIndex = <int, LevelUnitStats>{
    for (final LevelUnitStats stats in levelStatistics) stats.index: stats,
  };
  final Map<int, Map<HitRateBucket, List<LevelMatrixEntry>>> cells =
      <int, Map<HitRateBucket, List<LevelMatrixEntry>>>{
        for (var level = kMaxSupportLevel; level >= kFreeRecallLevel; level -= 1)
          level: <HitRateBucket, List<LevelMatrixEntry>>{
            for (final HitRateBucket bucket in HitRateBucket.values)
              bucket: <LevelMatrixEntry>[],
          },
      };
  final Map<int, int> rowTotals = <int, int>{
    for (var level = kMaxSupportLevel; level >= kFreeRecallLevel; level -= 1)
      level: 0,
  };
  final Map<HitRateBucket, int> columnTotals = <HitRateBucket, int>{
    for (final HitRateBucket bucket in HitRateBucket.values) bucket: 0,
  };
  var grandTotal = 0;

  final List<QueryDirection> directions = switch (view) {
    StatisticsDirectionView.direction1 => <QueryDirection>[
      QueryDirection.direction1,
    ],
    StatisticsDirectionView.direction2 => <QueryDirection>[
      QueryDirection.direction2,
    ],
    StatisticsDirectionView.combined => <QueryDirection>[
      QueryDirection.direction1,
      QueryDirection.direction2,
    ],
  };

  for (final int index in unitIndices) {
    final LevelUnitStats? levelStats = byIndex[index];
    if (levelStats == null) {
      continue;
    }
    for (final QueryDirection direction in directions) {
      final LevelDirectionStats dirStats = levelStats.statsFor(direction);
      final int level = dirStats.currentLevel;
      final DirectionStats levelCounters =
          dirStats.levels[level] ?? const DirectionStats();
      final HitRateBucket bucket = bucketFor(levelCounters);
      cells[level]![bucket]!.add(
        LevelMatrixEntry(
          unitIndex: index,
          direction: direction,
          stats: levelCounters,
        ),
      );
      rowTotals[level] = rowTotals[level]! + 1;
      columnTotals[bucket] = columnTotals[bucket]! + 1;
      grandTotal += 1;
    }
  }

  return LevelBucketMatrix(
    cells: <int, Map<HitRateBucket, List<LevelMatrixEntry>>>{
      for (final MapEntry<int, Map<HitRateBucket, List<LevelMatrixEntry>>> row
          in cells.entries)
        row.key: <HitRateBucket, List<LevelMatrixEntry>>{
          for (final MapEntry<HitRateBucket, List<LevelMatrixEntry>> cell
              in row.value.entries)
            cell.key: List<LevelMatrixEntry>.unmodifiable(cell.value),
        },
    },
    rowTotals: Map<int, int>.unmodifiable(rowTotals),
    columnTotals: Map<HitRateBucket, int>.unmodifiable(columnTotals),
    grandTotal: grandTotal,
  );
}

// --- Level Learning: masking ------------------------------------------------

final RegExp _maskWhitespace = RegExp(r'\s');
final RegExp _maskCandidate = RegExp(r'[\p{L}\p{N}]', unicode: true);

/// Builds a per-character scaffold template for one answer field at [level].
///
/// Scaffolding is applied **per word**: whitespace runs are always
/// [MaskCellKind.shown] verbatim and reset the reveal pattern, so it restarts at
/// the start of each word. Within a word only letters and digits are mask
/// candidates (enumerated 0,1,2…); all other characters (punctuation) are always
/// [MaskCellKind.shown] and do not advance the candidate counter.
///
/// Per candidate, by [level] (higher = more support):
/// - **3** every candidate [MaskCellKind.revealed];
/// - **2** even candidate index revealed, odd [MaskCellKind.blank];
/// - **1** first and last candidate revealed, middle blank (a 1–2-candidate word
///   is fully revealed);
/// - **0** every candidate blank.
///
/// This is a pure rendering concern; grading still runs the student's full typed
/// string through [evaluateAnswer].
List<MaskCell> maskFieldValue(String expectedPlainText, int level) {
  if (!isValidLevel(level)) {
    throw ArgumentError.value(level, 'level', 'Level must be 0..3');
  }
  final List<String> chars = expectedPlainText.runes
      .map(String.fromCharCode)
      .toList(growable: false);
  final List<MaskCell> cells = <MaskCell>[];
  var i = 0;
  while (i < chars.length) {
    if (_maskWhitespace.hasMatch(chars[i])) {
      cells.add(MaskCell(chars[i], MaskCellKind.shown));
      i += 1;
      continue;
    }
    // Collect one word run (up to the next whitespace) and index its candidates.
    final int wordStart = i;
    final Map<int, int> candidateIndexAt = <int, int>{};
    var candidateCount = 0;
    while (i < chars.length && !_maskWhitespace.hasMatch(chars[i])) {
      if (_maskCandidate.hasMatch(chars[i])) {
        candidateIndexAt[i] = candidateCount;
        candidateCount += 1;
      }
      i += 1;
    }
    for (var j = wordStart; j < i; j += 1) {
      final int? candidateIndex = candidateIndexAt[j];
      if (candidateIndex == null) {
        cells.add(MaskCell(chars[j], MaskCellKind.shown));
        continue;
      }
      cells.add(
        MaskCell(chars[j], _maskCellKind(level, candidateIndex, candidateCount)),
      );
    }
  }
  return List<MaskCell>.unmodifiable(cells);
}

MaskCellKind _maskCellKind(int level, int candidateIndex, int candidateCount) {
  switch (level) {
    case 3:
      return MaskCellKind.revealed;
    case 2:
      return candidateIndex.isEven ? MaskCellKind.revealed : MaskCellKind.blank;
    case 1:
      final bool isEdge =
          candidateIndex == 0 || candidateIndex == candidateCount - 1;
      return isEdge ? MaskCellKind.revealed : MaskCellKind.blank;
    default: // 0
      return MaskCellKind.blank;
  }
}

// --- Level Learning: leveling engine ----------------------------------------

/// Maps a prior hit-rate [bucket] to a Level-Learning start level (`0..3`).
///
/// Higher level = more support. This table is a first guess (roadmap §11 flag);
/// it lives in one function so it is easy to tune later.
int levelForBucket(HitRateBucket bucket) {
  return switch (bucket) {
    HitRateBucket.perfect || HitRateBucket.good => 0,
    HitRateBucket.fair => 1,
    HitRateBucket.unsure => 2,
    HitRateBucket.veryUnsure ||
    HitRateBucket.neverKnown ||
    HitRateBucket.notYetQueried => kMaxSupportLevel,
  };
}

/// Seeds fresh Level-Learning stats for a unit+direction new to Level Learning.
///
/// The start level is [levelForBucket] of [priorStats]'s bucket (its existing,
/// mode-agnostic per-direction counters), then capped by [entryLevelCap]. Since a
/// higher number means more support, `min` applies the cap correctly (cap 3 = no
/// restriction). All four level counters start 0/0. Seeding runs once; afterward
/// the promotion cascade owns the level.
LevelDirectionStats seedLevelLearningStats(
  DirectionStats priorStats, {
  int entryLevelCap = kMaxSupportLevel,
}) {
  final int mapped = levelForBucket(bucketFor(priorStats));
  return LevelDirectionStats.fresh(min(mapped, entryLevelCap));
}

/// Records a Level-Learning attempt at the current level, then auto-promotes.
///
/// The attempt is applied to `levels[currentLevel]` with [recordAttempt]
/// semantics ([AttemptRating.noCount] records nothing). Then, if the current
/// level now meets mastery ([isMastered] against [parameters]) and it is not
/// already the free-recall level, the unit promotes one level down; that lower
/// level's counters are already fresh 0/0. There is no auto-demotion — a wrong
/// answer only adds to the current level's attempts.
LevelDirectionStats recordLevelLearningAttempt(
  LevelDirectionStats stats,
  AttemptRating rating, {
  required SessionParameters parameters,
}) {
  final DirectionStats updatedLevel = recordAttempt(
    stats.currentLevelStats,
    rating,
  );
  var next = stats.withLevelStats(stats.currentLevel, updatedLevel);
  if (next.currentLevel > kFreeRecallLevel &&
      isMastered(updatedLevel, parameters)) {
    next = next.withCurrentLevel(next.currentLevel - 1);
  }
  return next;
}

/// Whether [stats] has reached free-recall (level 0) mastery and leaves the pool.
///
/// True only when the unit is at [kFreeRecallLevel] and its level-0 track record
/// meets mastery under [parameters]. With the min-attempts guard off (default) a
/// single correct level-0 answer (1/1) already qualifies.
bool isLevelLearningMastered(
  LevelDirectionStats stats, {
  required SessionParameters parameters,
}) {
  return stats.currentLevel == kFreeRecallLevel &&
      isMastered(
        stats.levels[kFreeRecallLevel] ?? const DirectionStats(),
        parameters,
      );
}

/// Moves [stats] to [newLevel] and resets THAT level's counters to 0/0.
///
/// This is the manual override (§10.4): the unit starts building a fresh track
/// record at [newLevel] like any newly-arrived unit, with no penalty. The other
/// levels' counters — and all other-mode statistics — are untouched.
LevelDirectionStats setLevelLearningLevel(
  LevelDirectionStats stats,
  int newLevel,
) {
  if (!isValidLevel(newLevel)) {
    throw ArgumentError.value(newLevel, 'newLevel', 'Level must be 0..3');
  }
  return LevelDirectionStats(
    currentLevel: newLevel,
    levels: <int, DirectionStats>{
      ...stats.levels,
      newLevel: const DirectionStats(),
    },
  );
}

/// Recomputes the active Level-Learning pool from current statistics.
///
/// Every `(unit, direction)` in range and in the direction selection is included
/// unless it has reached level-0 mastery ([isLevelLearningMastered]). A unit with
/// no [levelStatistics] entry yet is seeded on the fly from its prior [statistics]
/// bucket (see [seedLevelLearningStats]) so a fresh deck yields the full pool. For
/// `direction = both` a unit leaves the pool only when both directions are
/// mastered, because each direction is evaluated independently here.
List<SessionItem> activeLevelLearningPool({
  required LearningDeck deck,
  required List<UnitStats> statistics,
  required List<LevelUnitStats> levelStatistics,
  required SessionParameters parameters,
  int entryLevelCap = kMaxSupportLevel,
}) {
  final List<SessionItem> items = <SessionItem>[];
  final Set<QueryDirection> directions = _directionsFor(
    parameters.directionSelection,
  );
  final int start = parameters.startIndex ?? 1;
  final int end = parameters.endIndex ?? deck.units.length;
  final Map<int, UnitStats> statsByIndex = _statsByIndex(statistics);
  final Map<int, LevelUnitStats> levelByIndex = <int, LevelUnitStats>{
    for (final LevelUnitStats stats in levelStatistics) stats.index: stats,
  };

  for (
    var index = start;
    index <= end && index <= deck.units.length;
    index += 1
  ) {
    if (index < 1) {
      continue;
    }
    final LevelUnitStats? levelStats = levelByIndex[index];
    final UnitStats unitStats = statsByIndex[index] ?? UnitStats(index: index);
    for (final QueryDirection direction in directions) {
      final LevelDirectionStats dirStats = levelStats != null
          ? levelStats.statsFor(direction)
          : seedLevelLearningStats(
              unitStats.statsFor(direction),
              entryLevelCap: entryLevelCap,
            );
      if (!isLevelLearningMastered(dirStats, parameters: parameters)) {
        items.add(SessionItem(unitIndex: index, direction: direction));
      }
    }
  }
  return List<SessionItem>.unmodifiable(items);
}

/// Returns zeroed statistics for every unit in [deck].
List<UnitStats> clearStatistics(LearningDeck deck) {
  return List<UnitStats>.generate(
    deck.units.length,
    (int index) => UnitStats(index: index + 1),
    growable: false,
  );
}

/// Returns [statistics] re-indexed to exactly [unitCount] units.
///
/// Existing per-unit counters are kept by their 1-based index; missing indices
/// (e.g. after the deck grew) are filled with zeroed [UnitStats], and any
/// entries beyond [unitCount] are dropped. Used whenever a deck's unit count
/// changes without a positional insert/delete (open, merge, load-stats).
List<UnitStats> resizeUnitStats(List<UnitStats> statistics, int unitCount) {
  final Map<int, UnitStats> byIndex = <int, UnitStats>{
    for (final UnitStats stats in statistics) stats.index: stats,
  };
  return List<UnitStats>.generate(
    unitCount,
    (int index) => byIndex[index + 1] ?? UnitStats(index: index + 1),
    growable: false,
  );
}

/// Remaps per-unit [statistics] after a unit is inserted at 1-based [position].
///
/// Counters for units at or after [position] shift up by one index; the newly
/// inserted position gets zeroed stats. This keeps learning history attached to
/// the units it belongs to when a unit is inserted mid-deck (see the editor's
/// insert-before action). [newUnitCount] is the deck's unit count *after* the
/// insertion.
List<UnitStats> statsAfterInsert(
  List<UnitStats> statistics,
  int position,
  int newUnitCount,
) {
  final Map<int, UnitStats> byIndex = <int, UnitStats>{
    for (final UnitStats stats in statistics) stats.index: stats,
  };
  return List<UnitStats>.generate(newUnitCount, (int slot) {
    final int index = slot + 1;
    if (index < position) {
      return byIndex[index] ?? UnitStats(index: index);
    }
    if (index == position) {
      return UnitStats(index: index);
    }
    final UnitStats? old = byIndex[index - 1];
    return old == null
        ? UnitStats(index: index)
        : UnitStats(
            index: index,
            direction1: old.direction1,
            direction2: old.direction2,
          );
  }, growable: false);
}

/// Remaps per-unit [statistics] after the unit at 1-based [position] is removed.
///
/// The removed unit's counters are dropped and every later unit shifts down by
/// one index, so surviving units keep their history. [newUnitCount] is the
/// deck's unit count *after* the deletion.
List<UnitStats> statsAfterDelete(
  List<UnitStats> statistics,
  int position,
  int newUnitCount,
) {
  final Map<int, UnitStats> byIndex = <int, UnitStats>{
    for (final UnitStats stats in statistics) stats.index: stats,
  };
  return List<UnitStats>.generate(newUnitCount, (int slot) {
    final int index = slot + 1;
    final UnitStats? source = index < position
        ? byIndex[index]
        : byIndex[index + 1];
    return source == null
        ? UnitStats(index: index)
        : UnitStats(
            index: index,
            direction1: source.direction1,
            direction2: source.direction2,
          );
  }, growable: false);
}

/// Searches the in-memory deck.
List<SearchResult> searchDeck({
  required LearningDeck deck,
  required String query,
  TextMatchOptions options = const TextMatchOptions(),
  int? categoryId,
  String? sourceFile,
}) {
  final String normalizedQuery = normalizeText(query, options);
  if (normalizedQuery.isEmpty) {
    return const <SearchResult>[];
  }
  final List<SearchResult> results = <SearchResult>[];
  for (var unitOffset = 0; unitOffset < deck.units.length; unitOffset += 1) {
    final LearningUnit unit = deck.units[unitOffset];
    if (categoryId != null && unit.categoryId != categoryId) {
      continue;
    }
    final CategoryDefinition category = deck.categoryForUnit(unit);
    final List<String> matchedFields = <String>[];
    for (final FieldDefinition field in category.fields) {
      if (field.isHidden) {
        continue;
      }
      final String text = normalizeText(
        unit.valueForFieldId(field.id).plainText,
        options,
      );
      if (text.contains(normalizedQuery)) {
        matchedFields.add(field.name);
      }
    }
    if (matchedFields.isNotEmpty) {
      results.add(
        SearchResult(
          unitIndex: unitOffset + 1,
          categoryId: unit.categoryId,
          matchedFieldNames: List<String>.unmodifiable(matchedFields),
          sourceFile: sourceFile,
        ),
      );
    }
  }
  return List<SearchResult>.unmodifiable(results);
}

/// Searches already-loaded file decks with source labels.
List<SearchResult> searchDeckFiles({
  required Map<String, LearningDeck> decksBySource,
  required String query,
  TextMatchOptions options = const TextMatchOptions(),
  int? categoryId,
}) {
  final List<SearchResult> results = <SearchResult>[];
  for (final MapEntry<String, LearningDeck> entry in decksBySource.entries) {
    results.addAll(
      searchDeck(
        deck: entry.value,
        query: query,
        options: options,
        categoryId: categoryId,
        sourceFile: entry.key,
      ),
    );
  }
  return List<SearchResult>.unmodifiable(results);
}

Map<FieldDefinition, FieldValue> _fieldsForRole(
  LearningDeck deck,
  LearningUnit unit,
  QueryDirection direction,
  FieldRole role,
) {
  final CategoryDefinition category = deck.categoryForUnit(unit);
  return <FieldDefinition, FieldValue>{
    for (final FieldDefinition field in category.fieldsForRole(direction, role))
      field: unit.valueForFieldId(field.id),
  };
}

FieldEvaluation _evaluatePositionalField(
  LearningUnit unit,
  FieldDefinition field,
  Map<int, FieldValue> enteredValues,
  AnswerEvaluationOptions options,
) {
  final String expected = normalizeText(
    unit.valueForFieldId(field.id).plainText,
    options,
  );
  final String entered = normalizeText(
    (enteredValues[field.id] ?? FieldValue.empty).plainText,
    options,
  );
  final bool checked = options.completeInputRequired || entered.isNotEmpty;
  final bool correct = checked ? expected == entered : true;
  return FieldEvaluation(
    fieldName: field.name,
    expected: expected,
    entered: entered,
    correct: correct,
  );
}

List<FieldEvaluation> _evaluateEqualGroup(
  LearningUnit unit,
  List<FieldDefinition> fields,
  Map<int, FieldValue> enteredValues,
  AnswerEvaluationOptions options,
) {
  final List<_GroupedAnswer> expectedAnswers = <_GroupedAnswer>[];
  final List<_GroupedAnswer> enteredAnswers = <_GroupedAnswer>[];
  for (final FieldDefinition field in fields) {
    final String expected = normalizeText(
      unit.valueForFieldId(field.id).plainText,
      options,
    );
    final String entered = normalizeText(
      (enteredValues[field.id] ?? FieldValue.empty).plainText,
      options,
    );
    if (expected.isNotEmpty) {
      expectedAnswers.add(_GroupedAnswer(expected));
    }
    if (options.completeInputRequired || entered.isNotEmpty) {
      if (entered.isNotEmpty) {
        enteredAnswers.add(_GroupedAnswer(entered));
      }
    }
  }

  final Map<String, int> expectedCounts = _valueCounts(expectedAnswers);
  final Map<String, int> enteredCounts = _valueCounts(enteredAnswers);
  final bool groupCorrect = options.completeInputRequired
      ? _sameCounts(expectedCounts, enteredCounts)
      : _containsCounts(expectedCounts, enteredCounts);
  return fields
      .map(
        (FieldDefinition field) => FieldEvaluation(
          fieldName: field.name,
          expected: normalizeText(
            unit.valueForFieldId(field.id).plainText,
            options,
          ),
          entered: normalizeText(
            (enteredValues[field.id] ?? FieldValue.empty).plainText,
            options,
          ),
          correct: groupCorrect,
        ),
      )
      .toList(growable: false);
}

Map<String, int> _valueCounts(List<_GroupedAnswer> answers) {
  final Map<String, int> counts = <String, int>{};
  for (final _GroupedAnswer answer in answers) {
    counts[answer.value] = (counts[answer.value] ?? 0) + 1;
  }
  return counts;
}

bool _sameCounts(Map<String, int> left, Map<String, int> right) {
  if (left.length != right.length) {
    return false;
  }
  for (final MapEntry<String, int> entry in left.entries) {
    if (right[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

bool _containsCounts(Map<String, int> expected, Map<String, int> entered) {
  for (final MapEntry<String, int> entry in entered.entries) {
    if ((expected[entry.key] ?? 0) < entry.value) {
      return false;
    }
  }
  return true;
}

Set<QueryDirection> _directionsFor(DirectionSelection selection) {
  return switch (selection) {
    DirectionSelection.direction1 => <QueryDirection>{
      QueryDirection.direction1,
    },
    DirectionSelection.direction2 => <QueryDirection>{
      QueryDirection.direction2,
    },
    DirectionSelection.both => <QueryDirection>{
      QueryDirection.direction1,
      QueryDirection.direction2,
    },
  };
}

List<SessionItem> _allItemsInScope(
  LearningDeck deck,
  SessionParameters parameters,
) {
  final List<SessionItem> items = <SessionItem>[];
  final Set<QueryDirection> directions = _directionsFor(
    parameters.directionSelection,
  );
  final int start = parameters.startIndex ?? 1;
  final int end = parameters.endIndex ?? deck.units.length;
  for (
    var index = start;
    index <= end && index <= deck.units.length;
    index += 1
  ) {
    if (index < 1) {
      continue;
    }
    for (final QueryDirection direction in directions) {
      items.add(SessionItem(unitIndex: index, direction: direction));
    }
  }
  return items;
}

Map<int, UnitStats> _statsByIndex(List<UnitStats> statistics) {
  return <int, UnitStats>{
    for (final UnitStats unitStats in statistics) unitStats.index: unitStats,
  };
}

/// Returns the [DirectionStats] for [stats] under a statistics [view].
///
/// The [StatisticsDirectionView.combined] view sums both directions. This is
/// the single source of truth for the combined-direction rule; UI code must
/// use it rather than re-summing.
DirectionStats statsForDirectionView(
  UnitStats stats,
  StatisticsDirectionView view,
) {
  return switch (view) {
    StatisticsDirectionView.direction1 => stats.direction1,
    StatisticsDirectionView.direction2 => stats.direction2,
    StatisticsDirectionView.combined => DirectionStats(
      attempts: stats.direction1.attempts + stats.direction2.attempts,
      correct: stats.direction1.correct + stats.direction2.correct,
    ),
  };
}

final class _GroupedAnswer {
  const _GroupedAnswer(this.value);

  final String value;
}
