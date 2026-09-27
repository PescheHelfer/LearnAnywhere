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
  final List<LearningUnit> units = deck.units.toList();
  units[unitIndex - 1] = toggleDifficult(units[unitIndex - 1]);
  return deck.copyWith(units: List<LearningUnit>.unmodifiable(units));
}
