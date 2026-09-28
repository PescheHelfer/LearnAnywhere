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
/// They are an input rather than constants, so a caller can judge by others.
final class DetectionThresholds {
  /// Creates detection thresholds; each one left out keeps its default.
  const DetectionThresholds({
    this.minWrong = 2,
    this.minWrongRatePercent = 33,
    this.minAttemptsWithoutCorrect = 6,
  });

  /// The tested rule: 2 wrong, a third of the time, 6 attempts if never right.
  static const DetectionThresholds defaults = DetectionThresholds();

  /// The fewest wrong answers that make a unit difficult.
  final int minWrong;

  /// The lowest wrong rate, as a whole percentage, that makes a unit
  /// difficult — whole, so the default can sit at the tested 1/3.
  final int minWrongRatePercent;

  /// How many attempts a unit never answered correctly needs before it can
  /// be detected, so that a brand-new word missed twice is not flagged.
  final int minAttemptsWithoutCorrect;
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

/// A deck after automatic flags were added to it, and how many.
final class AutomaticFlagChange {
  /// Creates a change result.
  const AutomaticFlagChange({required this.deck, required this.added});

  /// The deck with the change applied — the same instance when nothing
  /// changed.
  final LearningDeck deck;

  /// How many units gained an automatic flag.
  final int added;

  /// Whether any flag changed, i.e. whether the deck needs writing.
  bool get changed => added > 0;
}

/// Sets the automatic flag on every unit of [deck] whose lifetime record
/// [allTime] satisfies the rule in either direction: what runs when a
/// learning session ends.
///
/// It only ever adds — a unit that no longer qualifies keeps its flag, and a
/// manual flag is never touched. Units are matched to [allTime] through the
/// lifetime record's own identity rules ([realignAllTimeStatistics]), so a
/// unit the record holds nothing for is not detected.
AutomaticFlagChange addDetectedDifficult(
  LearningDeck deck,
  AllTimeStatistics allTime, {
  DetectionThresholds thresholds = DetectionThresholds.defaults,
}) {
  final List<UnitStats> records = realignAllTimeStatistics(
    deck: deck,
    allTime: allTime,
  ).perUnit;
  final Set<int> detected = <int>{
    for (var slot = 0; slot < deck.units.length; slot += 1)
      if (!deck.units[slot].autoDifficult &&
          (isDetectedDifficult(records[slot].direction1, thresholds) ||
              isDetectedDifficult(records[slot].direction2, thresholds)))
        slot + 1,
  };
  if (detected.isEmpty) {
    return AutomaticFlagChange(deck: deck, added: 0);
  }
  return AutomaticFlagChange(
    deck: _updateUnitsAt(
      deck,
      detected,
      (LearningUnit unit) => unit.copyWith(autoDifficult: true),
    ),
    added: detected.length,
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
