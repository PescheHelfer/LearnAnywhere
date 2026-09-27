/// Difficult units: the one marking rule every surface that marks shares.
///
/// A unit is difficult when it carries a manual flag, an automatic flag, or
/// both (see "Difficult units" in `packages/core/CONTEXT.md`). The flags live
/// on the unit in the deck (ADR-0005), so everything here is a pure function
/// from a unit or deck to a new one; writing it is the shell's business.
library;

import '../models/models.dart';

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
