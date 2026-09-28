/// Difficult units: the one marking rule every surface that marks shares.
///
/// A unit is difficult when it carries a manual flag, an automatic flag, or
/// both (see "Difficult units" in `packages/core/CONTEXT.md`). The flags live
/// on the unit in the deck (ADR-0005), so everything here is a pure function
/// from a unit or deck to a new one; writing it is the shell's business.
library;

import '../models/models.dart';
import '../statistics/all_time.dart';

/// Toggles [unit]'s difficulty: the one rule behind F12 and the Difficult
/// pill, which every later way of marking a unit reuses.
///
/// A unit carrying **any** flag loses **both**: "not difficult" means not
/// difficult, whoever said it was. Otherwise the unit gains the **manual**
/// flag — the program's automatic flag is never set by hand.
LearningUnit toggleDifficult(LearningUnit unit) {
  return unit.isDifficult
      ? unit.copyWith(manualDifficult: false, autoDifficult: false)
      : unit.copyWith(manualDifficult: true);
}

/// Returns [deck] with [toggleDifficult] applied to the unit at the one-based
/// [unitIndex].
///
/// Changing a flag is not an edit, so the deck keeps its last-edited date.
LearningDeck toggleDifficultAt(LearningDeck deck, int unitIndex) {
  return _updateUnitsAt(deck, <int>{unitIndex}, toggleDifficult);
}

/// Returns [deck] with the manual flag set on each unit at the one-based
/// [unitIndices]: the unit list's **Mark selected**.
///
/// Unlike the toggle, marking a selection never clears anything — a unit the
/// program already flagged keeps its automatic flag as well.
LearningDeck markDifficultAt(LearningDeck deck, Set<int> unitIndices) {
  return _updateUnitsAt(
    deck,
    unitIndices,
    (LearningUnit unit) => unit.copyWith(manualDifficult: true),
  );
}

/// Returns [deck] with both flags cleared on each unit at the one-based
/// [unitIndices]: the unit list's **Unmark selected**, which — like the
/// toggle — means "not difficult", whoever said it was.
LearningDeck unmarkDifficultAt(LearningDeck deck, Set<int> unitIndices) {
  return _updateUnitsAt(
    deck,
    unitIndices,
    (LearningUnit unit) =>
        unit.copyWith(manualDifficult: false, autoDifficult: false),
  );
}

/// The three thresholds of the detection rule ([isDetectedDifficult]).
///
/// The defaults are the rule tested against real learners' lifetime records.
/// They are an input rather than constants, so a caller can judge by others:
/// the learner tunes them in the settings, within the ranges below.
final class DetectionThresholds {
  /// Creates detection thresholds; each one left out keeps its default.
  const DetectionThresholds({
    this.minWrong = 2,
    this.minWrongRatePercent = 33,
    this.minAttemptsWithoutCorrect = 6,
  });

  /// The tested rule: 2 wrong, a third of the time, 6 attempts if never right.
  static const DetectionThresholds defaults = DetectionThresholds();

  /// The values a learner may choose for [minWrong].
  static const ThresholdRange minWrongRange = ThresholdRange(1, 10);

  /// The values a learner may choose for [minWrongRatePercent], in steps of
  /// one percent.
  static const ThresholdRange minWrongRatePercentRange = ThresholdRange(10, 90);

  /// The values a learner may choose for [minAttemptsWithoutCorrect].
  static const ThresholdRange minAttemptsWithoutCorrectRange = ThresholdRange(
    3,
    20,
  );

  /// The fewest wrong answers that make a unit difficult.
  final int minWrong;

  /// The lowest wrong rate, as a whole percentage, that makes a unit
  /// difficult — whole, so the default can sit at the tested 1/3.
  final int minWrongRatePercent;

  /// How many attempts a unit never answered correctly needs before it can
  /// be detected, so that a brand-new word missed twice is not flagged.
  final int minAttemptsWithoutCorrect;

  /// Whether every threshold lies within the range a learner may choose.
  bool get isInRange =>
      minWrongRange.contains(minWrong) &&
      minWrongRatePercentRange.contains(minWrongRatePercent) &&
      minAttemptsWithoutCorrectRange.contains(minAttemptsWithoutCorrect);

  @override
  bool operator ==(Object other) {
    return other is DetectionThresholds &&
        other.minWrong == minWrong &&
        other.minWrongRatePercent == minWrongRatePercent &&
        other.minAttemptsWithoutCorrect == minAttemptsWithoutCorrect;
  }

  @override
  int get hashCode =>
      Object.hash(minWrong, minWrongRatePercent, minAttemptsWithoutCorrect);
}

/// The whole numbers, [min] to [max] inclusive, a detection threshold may
/// take.
final class ThresholdRange {
  /// Creates the range [min] to [max], both included.
  const ThresholdRange(this.min, this.max);

  /// The lowest value allowed.
  final int min;

  /// The highest value allowed.
  final int max;

  /// Whether [value] lies within the range; null never does.
  bool contains(int? value) => value != null && value >= min && value <= max;
}

/// Whether one direction's lifetime counters make a unit difficult:
///
/// ```
/// wrong >= minWrong
///   AND wrong / attempts >= minWrongRate
///   AND (correct >= 1 OR attempts >= minAttemptsWithoutCorrect)
/// ```
///
/// The unit is judged by its own record alone, never against the rest of the
/// deck. "Almost" is display-only and never reaches the counters.
bool isDetectedDifficult(
  DirectionStats stats, [
  DetectionThresholds thresholds = DetectionThresholds.defaults,
]) {
  if (stats.attempts == 0) {
    return false;
  }
  // Cross-multiplied, so the rate compares in whole numbers.
  return stats.wrong >= thresholds.minWrong &&
      stats.wrong * 100 >= thresholds.minWrongRatePercent * stats.attempts &&
      (stats.correct >= 1 ||
          stats.attempts >= thresholds.minAttemptsWithoutCorrect);
}

/// A deck after a deck-wide flag operation, and how many flags it set and
/// cleared.
final class DifficultFlagChange {
  /// Creates a change result.
  const DifficultFlagChange({
    required this.deck,
    this.added = 0,
    this.removed = 0,
  });

  /// The deck with the change applied — the same instance when nothing
  /// changed.
  final LearningDeck deck;

  /// How many units gained a flag.
  final int added;

  /// How many units lost a flag.
  final int removed;

  /// Whether any flag changed, i.e. whether the deck needs writing.
  bool get changed => added > 0 || removed > 0;
}

/// Sets the automatic flag on every unit of [deck] whose lifetime record
/// [allTime] satisfies the rule in either direction: what runs when a
/// learning session ends.
///
/// It only ever adds — a unit that no longer qualifies keeps its flag, and a
/// manual flag is never touched. Units are matched to [allTime] through the
/// lifetime record's own identity rules ([realignAllTimeStatistics]), so a
/// unit the record holds nothing for is not detected.
DifficultFlagChange addDetectedDifficult(
  LearningDeck deck,
  AllTimeStatistics allTime, {
  DetectionThresholds thresholds = DetectionThresholds.defaults,
}) {
  final List<bool> detected = _detectedSlots(deck, allTime, thresholds);
  final Set<int> gained = <int>{
    for (var slot = 0; slot < deck.units.length; slot += 1)
      if (detected[slot] && !deck.units[slot].autoDifficult) slot + 1,
  };
  if (gained.isEmpty) {
    return DifficultFlagChange(deck: deck);
  }
  return DifficultFlagChange(
    deck: _updateUnitsAt(
      deck,
      gained,
      (LearningUnit unit) => unit.copyWith(autoDifficult: true),
    ),
    added: gained.length,
  );
}

/// Rebuilds every automatic flag of [deck] from its lifetime record
/// [allTime]: **Statistics ▸ Recompute automatic flags**.
///
/// A unit the rule holds for carries the automatic flag afterwards, and
/// every other unit does not — so, unlike [addDetectedDifficult], stale flags
/// go away. A unit the record holds nothing for is not detected, which is
/// why a deck without statistics loses all its automatic flags. Manual flags
/// are never touched. The counts are relative to the flags [deck] carried.
DifficultFlagChange recomputeDetectedDifficult(
  LearningDeck deck,
  AllTimeStatistics allTime, {
  DetectionThresholds thresholds = DetectionThresholds.defaults,
}) {
  final List<bool> detected = _detectedSlots(deck, allTime, thresholds);
  final Set<int> gained = <int>{};
  final Set<int> lost = <int>{};
  for (var slot = 0; slot < deck.units.length; slot += 1) {
    if (detected[slot] != deck.units[slot].autoDifficult) {
      (detected[slot] ? gained : lost).add(slot + 1);
    }
  }
  if (gained.isEmpty && lost.isEmpty) {
    return DifficultFlagChange(deck: deck);
  }
  return DifficultFlagChange(
    deck: _updateUnitsAt(
      deck,
      <int>{...gained, ...lost},
      (LearningUnit unit) => unit.copyWith(autoDifficult: !unit.autoDifficult),
    ),
    added: gained.length,
    removed: lost.length,
  );
}

/// Clears the manual flag on every unit of [deck]: **Statistics ▸ Remove all
/// manual flags**. Automatic flags are never touched.
DifficultFlagChange clearManualDifficult(LearningDeck deck) {
  final Set<int> marked = <int>{
    for (var slot = 0; slot < deck.units.length; slot += 1)
      if (deck.units[slot].manualDifficult) slot + 1,
  };
  if (marked.isEmpty) {
    return DifficultFlagChange(deck: deck);
  }
  return DifficultFlagChange(
    deck: _updateUnitsAt(
      deck,
      marked,
      (LearningUnit unit) => unit.copyWith(manualDifficult: false),
    ),
    removed: marked.length,
  );
}

/// For each unit of [deck], whether its lifetime record in [allTime]
/// satisfies the rule in either direction.
///
/// Units are matched to records by the lifetime record's own identity rules
/// ([realignAllTimeStatistics]).
List<bool> _detectedSlots(
  LearningDeck deck,
  AllTimeStatistics allTime,
  DetectionThresholds thresholds,
) {
  final List<UnitStats> records = realignAllTimeStatistics(
    deck: deck,
    allTime: allTime,
  ).perUnit;
  return <bool>[
    for (final UnitStats record in records)
      isDetectedDifficult(record.direction1, thresholds) ||
          isDetectedDifficult(record.direction2, thresholds),
  ];
}

/// Applies [update] to the units at the one-based [unitIndices].
///
/// Changing a flag is not an edit, so the deck keeps its last-edited date.
LearningDeck _updateUnitsAt(
  LearningDeck deck,
  Set<int> unitIndices,
  LearningUnit Function(LearningUnit unit) update,
) {
  final List<LearningUnit> units = deck.units.toList();
  for (final int index in unitIndices) {
    units[index - 1] = update(units[index - 1]);
  }
  return deck.copyWith(units: List<LearningUnit>.unmodifiable(units));
}
