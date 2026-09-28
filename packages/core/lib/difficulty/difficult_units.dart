/// Difficult units: the one marking rule every surface that marks shares.
///
/// A unit is difficult in a direction when that direction carries a manual
/// flag, an automatic flag, or both (see "Difficult units" in
/// `packages/core/CONTEXT.md`). The flags live on the unit in the deck
/// (ADR-0005 and its per-direction amendment), so everything here is a pure
/// function from a unit or deck to a new one; writing it is the shell's
/// business.
library;

import '../models/models.dart';
import '../statistics/all_time.dart';

/// Toggles [unit]'s difficulty in [direction]: the one rule behind F12 and
/// the Difficult pill, which every later way of marking a unit reuses.
///
/// A direction carrying **any** flag loses **both** of its flags: "not
/// difficult" means not difficult, whoever said it was. Otherwise it gains
/// the **manual** flag — the program's automatic flag is never set by hand.
/// The other direction is never touched.
LearningUnit toggleDifficult(LearningUnit unit, QueryDirection direction) {
  return unit.withFlags(
    direction,
    unit.isDifficultIn(direction)
        ? DifficultFlags.none
        : const DifficultFlags(manual: true),
  );
}

/// Returns [deck] with [toggleDifficult] applied in [direction] to the unit
/// at the one-based [unitIndex].
///
/// Changing a flag is not an edit, so the deck keeps its last-edited date.
LearningDeck toggleDifficultAt(
  LearningDeck deck,
  int unitIndex,
  QueryDirection direction,
) {
  return _updateUnitsAt(
    deck,
    <int>{unitIndex},
    (LearningUnit unit) => toggleDifficult(unit, direction),
  );
}

/// Returns [deck] with the manual flag set in each of [directions] on each
/// unit at the one-based [unitIndices]: the unit list's **Mark selected**.
///
/// Unlike the toggle, marking a selection never clears anything — a unit the
/// program already flagged keeps its automatic flag as well.
LearningDeck markDifficultAt(
  LearningDeck deck,
  Set<int> unitIndices,
  Set<QueryDirection> directions,
) {
  return _updateUnitsAt(deck, unitIndices, (LearningUnit unit) {
    var marked = unit;
    for (final QueryDirection direction in directions) {
      marked = marked.withFlags(
        direction,
        marked.flagsFor(direction).copyWith(manual: true),
      );
    }
    return marked;
  });
}

/// Returns [deck] with both flags cleared in each of [directions] on each
/// unit at the one-based [unitIndices]: the unit list's **Unmark selected**,
/// which — like the toggle — means "not difficult", whoever said it was.
LearningDeck unmarkDifficultAt(
  LearningDeck deck,
  Set<int> unitIndices,
  Set<QueryDirection> directions,
) {
  return _updateUnitsAt(deck, unitIndices, (LearningUnit unit) {
    var unmarked = unit;
    for (final QueryDirection direction in directions) {
      unmarked = unmarked.withFlags(direction, DifficultFlags.none);
    }
    return unmarked;
  });
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
///
/// Every count is in flags — one per unit and direction — so a unit newly
/// flagged both ways counts two.
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

  /// How many flags were set.
  final int added;

  /// How many flags were cleared.
  final int removed;

  /// Whether any flag changed, i.e. whether the deck needs writing.
  bool get changed => added > 0 || removed > 0;
}

/// Sets the automatic flag in each direction of each unit of [deck] whose
/// lifetime record [allTime] satisfies the rule in that direction: what runs
/// when a learning session ends.
///
/// It only ever adds — a direction that no longer qualifies keeps its flag,
/// and a manual flag is never touched. Units are matched to [allTime] through
/// the lifetime record's own identity rules ([realignAllTimeStatistics]), so
/// a unit the record holds nothing for is not detected.
DifficultFlagChange addDetectedDifficult(
  LearningDeck deck,
  AllTimeStatistics allTime, {
  DetectionThresholds thresholds = DetectionThresholds.defaults,
}) {
  return _setAutomaticFlags(
    deck,
    allTime,
    thresholds,
    (bool detected, bool flagged) => detected || flagged,
  );
}

/// Rebuilds every automatic flag of [deck], in both directions, from its
/// lifetime record [allTime]: **Statistics ▸ Recompute automatic flags**.
///
/// A direction the rule holds for carries the automatic flag afterwards, and
/// every other does not — so, unlike [addDetectedDifficult], stale flags go
/// away. A unit the record holds nothing for is not detected, which is why a
/// deck without statistics loses all its automatic flags. Manual flags are
/// never touched. The counts are relative to the flags [deck] carried.
DifficultFlagChange recomputeDetectedDifficult(
  LearningDeck deck,
  AllTimeStatistics allTime, {
  DetectionThresholds thresholds = DetectionThresholds.defaults,
}) {
  return _setAutomaticFlags(
    deck,
    allTime,
    thresholds,
    (bool detected, bool flagged) => detected,
  );
}

/// Clears the manual flag in both directions of every unit of [deck]:
/// **Statistics ▸ Remove all manual flags**. Automatic flags are never
/// touched.
DifficultFlagChange clearManualDifficult(LearningDeck deck) {
  var removed = 0;
  final List<LearningUnit> units = <LearningUnit>[];
  for (final LearningUnit unit in deck.units) {
    var cleared = unit;
    for (final QueryDirection direction in QueryDirection.values) {
      final DifficultFlags flags = cleared.flagsFor(direction);
      if (flags.manual) {
        removed += 1;
        cleared = cleared.withFlags(direction, flags.copyWith(manual: false));
      }
    }
    units.add(cleared);
  }
  return _flagChange(deck, units, removed: removed);
}

/// Sets each direction's automatic flag on each unit of [deck] to what
/// [decide] makes of whether the rule detects that direction by its lifetime
/// record in [allTime] and whether the flag is set already.
///
/// Units are matched to records by the lifetime record's own identity rules
/// ([realignAllTimeStatistics]).
DifficultFlagChange _setAutomaticFlags(
  LearningDeck deck,
  AllTimeStatistics allTime,
  DetectionThresholds thresholds,
  bool Function(bool detected, bool flagged) decide,
) {
  final List<UnitStats> records = realignAllTimeStatistics(
    deck: deck,
    allTime: allTime,
  ).perUnit;
  var added = 0;
  var removed = 0;
  final List<LearningUnit> units = <LearningUnit>[];
  for (var slot = 0; slot < deck.units.length; slot += 1) {
    var unit = deck.units[slot];
    for (final QueryDirection direction in QueryDirection.values) {
      final DifficultFlags flags = unit.flagsFor(direction);
      final bool automatic = decide(
        isDetectedDifficult(records[slot].statsFor(direction), thresholds),
        flags.automatic,
      );
      if (automatic != flags.automatic) {
        if (automatic) {
          added += 1;
        } else {
          removed += 1;
        }
        unit = unit.withFlags(direction, flags.copyWith(automatic: automatic));
      }
    }
    units.add(unit);
  }
  return _flagChange(deck, units, added: added, removed: removed);
}

/// The change from [deck] to [deck] with [units], which set [added] flags and
/// cleared [removed] — [deck] itself when neither is any.
///
/// Changing a flag is not an edit, so the deck keeps its last-edited date.
DifficultFlagChange _flagChange(
  LearningDeck deck,
  List<LearningUnit> units, {
  int added = 0,
  int removed = 0,
}) {
  if (added == 0 && removed == 0) {
    return DifficultFlagChange(deck: deck);
  }
  return DifficultFlagChange(
    deck: deck.copyWith(units: List<LearningUnit>.unmodifiable(units)),
    added: added,
    removed: removed,
  );
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
