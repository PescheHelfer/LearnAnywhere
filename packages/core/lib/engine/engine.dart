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
    required this.totalAttempts,
    required this.totalCorrect,
  });

  /// Number of units in scope.
  final int totalUnits;

  /// Number of units with at least one attempt.
  final int queriedUnits;

  /// Bucket summaries in legacy display order.
  final List<BucketSummary> buckets;

  /// Sum of attempts across in-scope units for the active direction view.
  final int totalAttempts;

  /// Sum of correct attempts across in-scope units for the active direction
  /// view.
  final int totalCorrect;

  /// Correct-attempt hit rate, or `null` when there are no attempts.
  double? get attemptsHitRate =>
      totalAttempts == 0 ? null : totalCorrect / totalAttempts;
}

/// Largest number of hits either search entry point returns by default.
///
/// A search walks every unit of every deck it is handed, and its caller renders
/// a row per hit. An unbounded result set is therefore what turns a broad query
/// — an empty one above all — over a large folder tree into an apparent freeze.
const int maxSearchResults = 2000;

/// A capped set of search hits, plus whether the cap cut the set short.
final class SearchOutcome {
  /// Creates a search outcome.
  const SearchOutcome({required this.results, required this.isTruncated});

  /// The hits, in deck order, never more than the search's `maxResults`.
  final List<SearchResult> results;

  /// Whether at least one further hit existed beyond the cap.
  ///
  /// False for a set that exactly fills the cap: nothing was left out.
  final bool isTruncated;
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

/// Whether [field] renders as a row for [direction] in the current session
/// state.
///
/// A remark row appears only after Check. An answer row appears before Check
/// only in typed-input mode, where it renders as an empty input box. A
/// hidden field never renders.
bool isFieldRowVisible(
  FieldDefinition field,
  QueryDirection direction, {
  required bool afterCheck,
  required bool withInput,
}) {
  if (field.isHidden) return false;
  return switch (field.roleFor(direction)) {
    FieldRole.question => true,
    FieldRole.remark => afterCheck,
    FieldRole.answer => afterCheck || withInput,
  };
}

/// Whether [field]'s value — not just an empty row — is on screen.
///
/// Distinct from [isFieldRowVisible]: in typed-input mode an answer row
/// renders before Check as an empty input box, so its row is visible while
/// its value is not. Speech must check this, not [isFieldRowVisible], or it
/// would read out the solution the learner is still trying to produce.
///
/// [answerShown] is the one case where an answer's value is on screen before
/// Check: Level Learning at [kMaxSupportLevel] shows the whole solution to be
/// read and memorized, until "Hide & type". Nothing is being withheld there,
/// so nothing can be given away.
bool isFieldValueVisible(
  FieldDefinition field,
  QueryDirection direction, {
  required bool afterCheck,
  bool answerShown = false,
}) {
  if (field.isHidden) return false;
  return switch (field.roleFor(direction)) {
    FieldRole.question => true,
    FieldRole.remark => afterCheck,
    FieldRole.answer => afterCheck || answerShown,
  };
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

// --- Answer similarity and the "Almost" outcome -----------------------------

/// The default similarity threshold for the "Almost" outcome (§9.1).
const double kDefaultAlmostThreshold = 0.8;

/// A display-only classification of a revealed answer.
///
/// This never changes what is recorded; it only drives the reveal-screen
/// messaging and which rating labels are shown (see [classifyOutcome]).
enum AnswerOutcome {
  /// An exact match after normalization.
  correct,

  /// Not exact, but similar enough to flag as a near-miss (scored as wrong
  /// unless the user overrides with "Close enough").
  almost,

  /// A plain wrong answer.
  wrong,
}

/// The Levenshtein edit distance between [a] and [b] (in UTF-16 code units).
///
/// Insertions, deletions, and substitutions each cost 1. Runs in `O(a·b)` time
/// with two rolling rows.
int levenshteinDistance(String a, String b) {
  if (identical(a, b) || a == b) {
    return 0;
  }
  if (a.isEmpty) {
    return b.length;
  }
  if (b.isEmpty) {
    return a.length;
  }
  List<int> previous = List<int>.generate(b.length + 1, (int j) => j);
  List<int> current = List<int>.filled(b.length + 1, 0);
  for (var i = 1; i <= a.length; i += 1) {
    current[0] = i;
    for (var j = 1; j <= b.length; j += 1) {
      final int cost = a[i - 1] == b[j - 1] ? 0 : 1;
      current[j] = min(
        min(current[j - 1] + 1, previous[j] + 1),
        previous[j - 1] + cost,
      );
    }
    final List<int> swap = previous;
    previous = current;
    current = swap;
  }
  return previous[b.length];
}

/// Normalized similarity of [a] and [b] in `0.0..1.0`.
///
/// Defined as `1 - editDistance / max(len(a), len(b))`. Two empty strings are
/// perfectly similar (`1.0`). Callers pass already-normalized text so the
/// similarity matches the case/accent rules used for scoring.
double normalizedSimilarity(String a, String b) {
  final int maxLen = max(a.length, b.length);
  if (maxLen == 0) {
    return 1;
  }
  return 1 - levenshteinDistance(a, b) / maxLen;
}

/// The whole-answer similarity of an [evaluation] in `0.0..1.0`.
///
/// The already-normalized per-field expected and entered values are joined (so
/// a single-field answer is compared directly) and run through
/// [normalizedSimilarity].
double answerSimilarity(AnswerEvaluation evaluation) {
  final String expected = evaluation.fields
      .map((FieldEvaluation f) => f.expected)
      .join('\n');
  final String entered = evaluation.fields
      .map((FieldEvaluation f) => f.entered)
      .join('\n');
  return normalizedSimilarity(expected, entered);
}

/// Classifies [evaluation] as correct, almost, or wrong (display only).
///
/// An exact match is always [AnswerOutcome.correct]. When [similarityEnabled]
/// is on, a non-exact answer whose [answerSimilarity] reaches
/// [similarityThreshold] is [AnswerOutcome.almost]; otherwise it is
/// [AnswerOutcome.wrong]. This adds no stored statistic — it only selects the
/// reveal messaging and rating labels.
AnswerOutcome classifyOutcome(
  AnswerEvaluation evaluation, {
  bool similarityEnabled = false,
  double similarityThreshold = kDefaultAlmostThreshold,
}) {
  if (evaluation.correct) {
    return AnswerOutcome.correct;
  }
  if (!similarityEnabled) {
    return AnswerOutcome.wrong;
  }
  return answerSimilarity(evaluation) >= similarityThreshold
      ? AnswerOutcome.almost
      : AnswerOutcome.wrong;
}

// --- Diff alignment (for reveal-screen highlighting) ------------------------

/// The kind of a single [DiffOp] in an expected↔entered alignment.
enum DiffOpKind {
  /// The expected and entered characters match (after normalization).
  match,

  /// The student typed a different character in this position.
  substitute,

  /// A character present in the expected text but missing from the entry.
  delete,

  /// An extra character the student typed that the expected text lacks.
  insert,
}

/// One aligned operation between the expected and entered text.
///
/// [expectedIndex] indexes the expected string (or `-1` for [DiffOpKind.insert]);
/// [enteredIndex] indexes the entered string (or `-1` for [DiffOpKind.delete]).
final class DiffOp {
  /// Creates a diff operation.
  const DiffOp(this.kind, this.expectedIndex, this.enteredIndex);

  /// The kind of operation.
  final DiffOpKind kind;

  /// Index into the expected string, or `-1` for an insert.
  final int expectedIndex;

  /// Index into the entered string, or `-1` for a delete.
  final int enteredIndex;

  @override
  bool operator ==(Object other) =>
      other is DiffOp &&
      other.kind == kind &&
      other.expectedIndex == expectedIndex &&
      other.enteredIndex == enteredIndex;

  @override
  int get hashCode => Object.hash(kind, expectedIndex, enteredIndex);
}

/// Aligns [expected] to [entered] via Levenshtein backtrace, in text order.
///
/// [DiffOpKind.delete] marks a character present in [expected] but missing from
/// [entered]; [DiffOpKind.insert] marks an extra character in [entered]. Pass
/// the same normalization used for scoring (see [normalizeForDiff]) so that
/// differences the evaluator ignores align as matches.
List<DiffOp> alignTexts(String expected, String entered) {
  final int m = expected.length;
  final int n = entered.length;
  final List<List<int>> dp = List<List<int>>.generate(
    m + 1,
    (int i) => List<int>.filled(n + 1, 0),
  );
  for (var i = 0; i <= m; i += 1) {
    dp[i][0] = i;
  }
  for (var j = 0; j <= n; j += 1) {
    dp[0][j] = j;
  }
  for (var i = 1; i <= m; i += 1) {
    for (var j = 1; j <= n; j += 1) {
      if (expected[i - 1] == entered[j - 1]) {
        dp[i][j] = dp[i - 1][j - 1];
      } else {
        dp[i][j] =
            1 + min(dp[i - 1][j - 1], min(dp[i - 1][j], dp[i][j - 1]));
      }
    }
  }

  final List<DiffOp> ops = <DiffOp>[];
  var i = m;
  var j = n;
  while (i > 0 || j > 0) {
    if (i > 0 && j > 0 && expected[i - 1] == entered[j - 1]) {
      ops.add(DiffOp(DiffOpKind.match, i - 1, j - 1));
      i -= 1;
      j -= 1;
    } else if (i > 0 && j > 0 && dp[i][j] == dp[i - 1][j - 1] + 1) {
      ops.add(DiffOp(DiffOpKind.substitute, i - 1, j - 1));
      i -= 1;
      j -= 1;
    } else if (i > 0 && dp[i][j] == dp[i - 1][j] + 1) {
      ops.add(DiffOp(DiffOpKind.delete, i - 1, -1));
      i -= 1;
    } else {
      ops.add(DiffOp(DiffOpKind.insert, -1, j - 1));
      j -= 1;
    }
  }
  return List<DiffOp>.unmodifiable(ops.reversed);
}

/// Position-preserving normalization for diff alignment.
///
/// Applies the same case/accent folding as [normalizeText] but per code unit
/// and never changing the string's length, so an index into the result maps
/// back to the same index in [value] (used to split the original runs). A fold
/// that would change a character's length (a rare expansion such as `ß`→`ss`)
/// is skipped for that character, keeping the 1:1 mapping intact.
String normalizeForDiff(String value, TextMatchOptions options) {
  final StringBuffer buffer = StringBuffer();
  for (var i = 0; i < value.length; i += 1) {
    var ch = value[i];
    if (!options.caseSensitive) {
      final String lower = ch.toLowerCase();
      if (lower.length == 1) {
        ch = lower;
      }
    }
    if (!options.accentSensitive) {
      final String stripped = removeDiacritics(ch);
      if (stripped.length == 1) {
        ch = stripped;
      }
    }
    buffer.write(ch);
  }
  return buffer.toString();
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

/// Draws a random item from [pool], never repeating [lastItem] back-to-back.
///
/// When the drawn item is the one just shown it is re-drawn from the rest of
/// the pool — except when it is the only item left, which must still repeat.
/// A single extra draw (plus one linear scan for [lastItem]) keeps this cheap
/// enough to run on every unit change. Returns `null` for an empty pool.
SessionItem? pickAvoidingRepeat(
  List<SessionItem> pool,
  Random random, {
  SessionItem? lastItem,
}) {
  if (pool.isEmpty) {
    return null;
  }
  if (pool.length == 1 || lastItem == null) {
    return pool[random.nextInt(pool.length)];
  }
  final int lastIndex = pool.indexOf(lastItem);
  if (lastIndex < 0) {
    return pool[random.nextInt(pool.length)];
  }
  // Draw over the pool minus that one slot, then step past it.
  var index = random.nextInt(pool.length - 1);
  if (index >= lastIndex) {
    index += 1;
  }
  return pool[index];
}

/// Selects a random practice item, or `null` when the each-once set is exhausted.
///
/// In [SessionMode.onceThrough] each item is served at most once, so the result
/// is `null` once every in-scope item has been seen. Passing [lastItem] avoids
/// serving the same item twice in a row (see [pickAvoidingRepeat]).
SessionItem? pickPracticeItem({
  required LearningDeck deck,
  required SessionParameters parameters,
  required Random random,
  Set<SessionItem> seenItems = const <SessionItem>{},
  SessionItem? lastItem,
}) {
  final List<SessionItem> candidates = itemsInScope(deck, parameters);
  final List<SessionItem> available =
      parameters.mode == SessionMode.onceThrough
      ? candidates
            .where((SessionItem item) => !seenItems.contains(item))
            .toList(growable: false)
      : candidates;
  return pickAvoidingRepeat(available, random, lastItem: lastItem);
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
  var totalAttempts = 0;
  var totalCorrect = 0;

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
    totalAttempts += stats.attempts;
    totalCorrect += stats.correct;
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
    totalAttempts: totalAttempts,
    totalCorrect: totalCorrect,
  );
}

/// Whether anything has actually been recorded yet.
///
/// True when any unit carries a drill attempt, or when the Level-Learning
/// ladder has any entry at all (an entry exists only once a session has
/// materialized it, so its mere presence is real progress). Used to decide
/// whether switching session mode is worth prompting about — with nothing
/// recorded there is nothing to keep or discard.
bool hasRecordedStatistics({
  required List<UnitStats> statistics,
  required List<LevelUnitStats> levelStatistics,
}) {
  if (levelStatistics.isNotEmpty) {
    return true;
  }
  return statistics.any((UnitStats stats) => stats.hasAttempts);
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

/// Deck-wide Level-Learning attempt totals.
///
/// Summed across **every** level of the ladder and **both** directions, so a
/// unit's climb from level 3 to level 0 keeps counting after it has left a
/// level behind. Deliberately larger than [StatisticsSummary.totalAttempts] for
/// the same deck: only attempts answered at level 0 (free recall) are written
/// through to the mode-agnostic statistics.
final class LadderAttemptTotals {
  /// Creates ladder attempt totals.
  const LadderAttemptTotals({required this.attempts, required this.correct});

  /// Sum of attempts across all levels and both directions.
  final int attempts;

  /// Sum of correct attempts across all levels and both directions.
  final int correct;
}

/// Sums the Level-Learning ladder's own counters for the whole deck.
///
/// Every entry in [levelStatistics] contributes all four per-level counters of
/// each direction [view] selects; the combined view sums both. Units without a
/// ladder entry contribute nothing — they have not entered Level Learning — so
/// no unit count or scope is needed.
///
/// This is what the live **Attempts** readout shows in Level Learning, where
/// the mode-agnostic statistics would sit almost still while the student climbs.
/// Pass the session's own view ([directionViewFor]) so a single-direction
/// session does not count the direction it never asks.
///
/// Entries whose index falls outside [unitCount] are ignored, like every
/// sibling aggregator ([aggregateStatistics], [levelBucketMatrix]) bounds
/// itself to the deck. This is the only consumer that walks the entry list
/// instead of the deck, so it is the one place a stray out-of-range entry
/// (an orphan a producer failed to drop) could otherwise reach the pill.
LadderAttemptTotals aggregateLadderAttempts({
  required List<LevelUnitStats> levelStatistics,
  required int unitCount,
  StatisticsDirectionView view = StatisticsDirectionView.combined,
}) {
  var attempts = 0;
  var correct = 0;
  for (final LevelUnitStats unit in levelStatistics) {
    if (unit.index < 1 || unit.index > unitCount) {
      continue;
    }
    for (final LevelDirectionStats direction in <LevelDirectionStats>[
      if (view != StatisticsDirectionView.direction2) unit.dir1,
      if (view != StatisticsDirectionView.direction1) unit.dir2,
    ]) {
      for (final DirectionStats stats in direction.levels.values) {
        attempts += stats.attempts;
        correct += stats.correct;
      }
    }
  }
  return LadderAttemptTotals(attempts: attempts, correct: correct);
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
/// - **2** even candidate index [MaskCellKind.blank], odd revealed;
/// - **1** first and last candidate revealed, middle blank; a two-candidate word
///   reveals the first and blanks the last, a one-candidate word is blank;
/// - **0** every candidate blank.
///
/// Below level 3 every word therefore keeps at least one blank, so no field is
/// ever served with nothing for the student to type. One consequence is
/// accepted: a three-candidate word reveals two characters at level 1 and one at
/// level 2, so level 1 is marginally easier at that single length. The two levels
/// also reveal equally many characters at 1, 2, 4 and 5 candidates; only from 6 on
/// does level 2 reveal strictly more.
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
      // Even candidates are the student's, so the first letter of every word —
      // and the only letter of a one-letter word — has to be recalled.
      return candidateIndex.isEven ? MaskCellKind.blank : MaskCellKind.revealed;
    case 1:
      if (candidateCount == 1) {
        return MaskCellKind.blank;
      }
      if (candidateCount == 2) {
        // No "between" to blank: keep the first as the anchor and ask for the
        // last, rather than revealing the whole word.
        return candidateIndex == 0 ? MaskCellKind.revealed : MaskCellKind.blank;
      }
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

/// Returns [levelStatistics] with entries outside a deck of [unitCount] units
/// dropped.
///
/// Unlike [resizeUnitStats], missing indices are not filled in: a
/// Level-Learning entry exists only once a unit has actually entered the
/// ladder (see [levelStatsAfterInsert]), so the list stays sparse by design.
/// Used whenever a deck's unit count changes without a positional
/// insert/delete (open, merge, load-stats).
List<LevelUnitStats> resizeLevelStats(
  List<LevelUnitStats> levelStatistics,
  int unitCount,
) {
  return List<LevelUnitStats>.unmodifiable(<LevelUnitStats>[
    for (final LevelUnitStats stats in levelStatistics)
      if (stats.index >= 1 && stats.index <= unitCount) stats,
  ]);
}

/// Remaps Level-Learning [levelStatistics] after a unit is inserted at
/// 1-based [position], mirroring how [statsAfterInsert] shifts drill
/// statistics.
///
/// Entries at or after [position] shift up by one index. Unlike
/// [statsAfterInsert], the newly inserted position gets **no** entry: a fresh
/// unit has no drill stats to seed a ladder entry from, and minting a zeroed
/// one here would freeze the entry-level cap as it stood at insert time
/// instead of the cap in force when the unit is first served. It is seeded
/// lazily on first serve instead, exactly like a freshly appended unit.
List<LevelUnitStats> levelStatsAfterInsert(
  List<LevelUnitStats> levelStatistics,
  int position,
) {
  return List<LevelUnitStats>.unmodifiable(<LevelUnitStats>[
    for (final LevelUnitStats stats in levelStatistics)
      if (stats.index < position)
        stats
      else
        LevelUnitStats(
          index: stats.index + 1,
          dir1: stats.dir1,
          dir2: stats.dir2,
        ),
  ]);
}

/// Remaps Level-Learning [levelStatistics] after the unit at 1-based
/// [position] is removed, mirroring how [statsAfterDelete] shifts drill
/// statistics.
///
/// The removed unit's ladder entry is dropped and reports nothing: the
/// delete already asks for confirmation, and losing that unit's ladder
/// history is the point of the action, not a loss to flag. Every later entry
/// shifts down by one index.
List<LevelUnitStats> levelStatsAfterDelete(
  List<LevelUnitStats> levelStatistics,
  int position,
) {
  return List<LevelUnitStats>.unmodifiable(<LevelUnitStats>[
    for (final LevelUnitStats stats in levelStatistics)
      if (stats.index < position)
        stats
      else if (stats.index > position)
        LevelUnitStats(
          index: stats.index - 1,
          dir1: stats.dir1,
          dir2: stats.dir2,
        ),
  ]);
}

/// Searches the in-memory deck.
///
/// A [query] that normalizes to nothing — empty, or only whitespace — matches
/// every unit, so [categoryId] on its own lists one category. Such a hit names
/// no matched fields: there was no text to match one with. A query with text
/// matches the plain text of the named (non-hidden) fields of the unit's own
/// category, under [options].
///
/// Stops after [maxResults] hits and reports that in [SearchOutcome.isTruncated].
SearchOutcome searchDeck({
  required LearningDeck deck,
  required String query,
  TextMatchOptions options = const TextMatchOptions(),
  int? categoryId,
  String? sourceFile,
  int maxResults = maxSearchResults,
}) {
  final String normalizedQuery = normalizeText(query, options);
  final bool matchesEveryUnit = normalizedQuery.isEmpty;
  final List<SearchResult> results = <SearchResult>[];
  var isTruncated = false;
  for (var unitOffset = 0; unitOffset < deck.units.length; unitOffset += 1) {
    final LearningUnit unit = deck.units[unitOffset];
    if (categoryId != null && unit.categoryId != categoryId) {
      continue;
    }
    var matchedFields = const <String>[];
    if (!matchesEveryUnit) {
      final CategoryDefinition category = deck.categoryForUnit(unit);
      final List<String> matches = <String>[];
      for (final FieldDefinition field in category.fields) {
        if (field.isHidden) {
          continue;
        }
        final String text = normalizeText(
          unit.valueForFieldId(field.id).plainText,
          options,
        );
        if (text.contains(normalizedQuery)) {
          matches.add(field.name);
        }
      }
      if (matches.isEmpty) {
        continue;
      }
      matchedFields = List<String>.unmodifiable(matches);
    }
    // The cap is tested only once a hit is in hand, so a set that exactly
    // fills it is reported as complete rather than as truncated.
    if (results.length >= maxResults) {
      isTruncated = true;
      break;
    }
    results.add(
      SearchResult(
        unitIndex: unitOffset + 1,
        categoryId: unit.categoryId,
        matchedFieldNames: matchedFields,
        sourceFile: sourceFile,
      ),
    );
  }
  return SearchOutcome(
    results: List<SearchResult>.unmodifiable(results),
    isTruncated: isTruncated,
  );
}

/// Searches already-loaded file decks with source labels.
///
/// [maxResults] caps the whole set, not each file: the walk stops at the first
/// hit past the cap, wherever in the map it falls.
SearchOutcome searchDeckFiles({
  required Map<String, LearningDeck> decksBySource,
  required String query,
  TextMatchOptions options = const TextMatchOptions(),
  int? categoryId,
  int maxResults = maxSearchResults,
}) {
  final List<SearchResult> results = <SearchResult>[];
  var isTruncated = false;
  for (final MapEntry<String, LearningDeck> entry in decksBySource.entries) {
    final SearchOutcome outcome = searchDeck(
      deck: entry.value,
      query: query,
      options: options,
      categoryId: categoryId,
      sourceFile: entry.key,
      maxResults: maxResults - results.length,
    );
    results.addAll(outcome.results);
    if (outcome.isTruncated) {
      isTruncated = true;
      break;
    }
  }
  return SearchOutcome(
    results: List<SearchResult>.unmodifiable(results),
    isTruncated: isTruncated,
  );
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

// --- Live readout scope -----------------------------------------------------
//
// The rule the live readouts follow: attempts, accuracy, what is mastered, what
// is left, and each Level-Learning level are **deck totals in the session's
// direction**. Restricting the unit range narrows what is asked, never what is
// counted, so figures standing side by side cannot contradict each other;
// selecting a single direction narrows both. Item selection keeps the session's
// own parameters — pass [deckWideScope] only where a readout is computed.
//
// The rule lives here, rather than in one shell's session page, so that every
// shell showing these readouts derives the same figures from the same helpers
// instead of restating it.

/// The readout scope for a session run with [parameters]: the whole deck.
///
/// Drops the unit range and keeps everything else — above all the direction
/// selection and the mastery rule, so the widened readout still answers the same
/// question, just about every unit. [parameters] itself is untouched.
SessionParameters deckWideScope(SessionParameters parameters) {
  // Not copyWith: its `??` fallbacks cannot clear an index back to null.
  return SessionParameters(
    directionSelection: parameters.directionSelection,
    withInput: parameters.withInput,
    mode: parameters.mode,
    shuffle: parameters.shuffle,
    masteryThreshold: parameters.masteryThreshold,
    minimumAttemptsGuardEnabled: parameters.minimumAttemptsGuardEnabled,
    minAttempts: parameters.minAttempts,
  );
}

/// The statistics view that shows exactly what a [selection] session asks.
///
/// Its point is that a readout and the statistics screen agree: a **Both**
/// session is the screen's **Combined** view, and a single-direction session is
/// that direction's view.
StatisticsDirectionView directionViewFor(DirectionSelection selection) {
  return switch (selection) {
    DirectionSelection.both => StatisticsDirectionView.combined,
    DirectionSelection.direction1 => StatisticsDirectionView.direction1,
    DirectionSelection.direction2 => StatisticsDirectionView.direction2,
  };
}

/// How many unit+direction items [parameters] covers over a deck of [unitCount].
///
/// A unit range reaching past either end of the deck is clamped, so an
/// out-of-range range counts zero rather than a negative. **Both** counts each
/// unit twice — one item per direction. Pass [deckWideScope] parameters for the
/// denominator of a live readout, the session's own for what it will serve.
int sessionItemCount({
  required int unitCount,
  required SessionParameters parameters,
}) {
  final int start = max(1, parameters.startIndex ?? 1);
  final int end = min(parameters.endIndex ?? unitCount, unitCount);
  final int units = max(0, end - start + 1);
  return switch (parameters.directionSelection) {
    DirectionSelection.both => units * 2,
    DirectionSelection.direction1 || DirectionSelection.direction2 => units,
  };
}

final class _GroupedAnswer {
  const _GroupedAnswer(this.value);

  final String value;
}
