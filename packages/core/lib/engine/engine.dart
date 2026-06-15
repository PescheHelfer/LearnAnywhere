/// Pure Dart learning, evaluation, statistics, and search engines.
library;

import 'dart:io';
import 'dart:math';

import 'package:diacritic/diacritic.dart';

import '../models/models.dart';
import '../serialization/serialization.dart';

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
  required Map<String, FieldValue> enteredValues,
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
  if (hitRate == null || hitRate < parameters.superStatusThreshold) {
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
SessionItem? pickPracticeItem({
  required LearningDeck deck,
  required SessionParameters parameters,
  required Random random,
  Set<SessionItem> seenItems = const <SessionItem>{},
}) {
  final List<SessionItem> candidates = _allItemsInScope(deck, parameters);
  final List<SessionItem> available = parameters.practiceEachOnce
      ? candidates
            .where((SessionItem item) => !seenItems.contains(item))
            .toList(growable: false)
      : candidates;
  if (available.isEmpty) {
    return null;
  }
  return available[random.nextInt(available.length)];
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
    final DirectionStats stats = _statsForView(unitStats, view);
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

/// Returns zeroed statistics for every unit in [deck].
List<UnitStats> clearStatistics(LearningDeck deck) {
  return List<UnitStats>.generate(
    deck.units.length,
    (int index) => UnitStats(index: index + 1),
    growable: false,
  );
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
        unit.valueForField(field.name).plainText,
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

/// Searches deck files from disk and returns hits with source file paths.
Future<List<SearchResult>> searchDeckFilesOnDisk({
  required Iterable<String> filePaths,
  required String query,
  TextMatchOptions options = const TextMatchOptions(),
  int? categoryId,
}) async {
  final List<SearchResult> results = <SearchResult>[];
  for (final String filePath in filePaths) {
    final String source = await File(filePath).readAsString();
    final LearningDeck deck = decodeDeckJson(source);
    results.addAll(
      searchDeck(
        deck: deck,
        query: query,
        options: options,
        categoryId: categoryId,
        sourceFile: filePath,
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
      field: unit.valueForField(field.name),
  };
}

FieldEvaluation _evaluatePositionalField(
  LearningUnit unit,
  FieldDefinition field,
  Map<String, FieldValue> enteredValues,
  AnswerEvaluationOptions options,
) {
  final String expected = normalizeText(
    unit.valueForField(field.name).plainText,
    options,
  );
  final String entered = normalizeText(
    (enteredValues[field.name] ?? FieldValue.empty).plainText,
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
  Map<String, FieldValue> enteredValues,
  AnswerEvaluationOptions options,
) {
  final List<_GroupedAnswer> expectedAnswers = <_GroupedAnswer>[];
  final List<_GroupedAnswer> enteredAnswers = <_GroupedAnswer>[];
  for (final FieldDefinition field in fields) {
    final String expected = normalizeText(
      unit.valueForField(field.name).plainText,
      options,
    );
    final String entered = normalizeText(
      (enteredValues[field.name] ?? FieldValue.empty).plainText,
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
            unit.valueForField(field.name).plainText,
            options,
          ),
          entered: normalizeText(
            (enteredValues[field.name] ?? FieldValue.empty).plainText,
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

DirectionStats _statsForView(UnitStats stats, StatisticsDirectionView view) {
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
