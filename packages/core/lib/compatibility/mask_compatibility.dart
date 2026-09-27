/// Pure classification of whether a mask edit can be safely applied to a deck.
///
/// Given a deck's OLD embedded mask and the just-saved NEW mask (the linked
/// `.inf`), decide per deck whether propagating the new mask is COMPATIBLE
/// (safe to auto-apply) or BREAKING (would drop or truncate stored data).
/// Categories and fields are matched by their stable integer ids, so renaming
/// or reordering is never breaking — only structural loss is.
library;

import '../models/models.dart';

/// Overall compatibility verdict for one deck.
enum MaskCompatibility {
  /// The new mask can overwrite the deck's embedded cache without data loss.
  compatible,

  /// Applying the new mask would drop or truncate stored unit data.
  breaking,
}

/// The kind of breaking change, for structured (localizable) reporting.
enum MaskBreakingKind {
  /// A category still referenced by at least one unit was removed.
  categoryDeleted,

  /// A field holding a non-empty value in at least one unit was removed.
  fieldDeleted,

  /// A field's length was cut below data already stored in some unit.
  fieldLengthTooShort,
}

/// One reason a mask edit breaks a specific deck.
final class MaskBreakingReason {
  /// Creates a breaking-change reason.
  const MaskBreakingReason({
    required this.kind,
    required this.categoryId,
    required this.affectedUnits,
    this.fieldId,
    this.categoryName = '',
    this.fieldName = '',
    this.newLength,
  });

  /// What kind of loss this reason describes.
  final MaskBreakingKind kind;

  /// Id of the affected category.
  final int categoryId;

  /// Id of the affected field, when the reason is field-scoped.
  final int? fieldId;

  /// The affected category's display name in the OLD mask (for messages).
  final String categoryName;

  /// The affected field's display name in the OLD mask (for messages).
  final String fieldName;

  /// The new (too-short) length, for [MaskBreakingKind.fieldLengthTooShort].
  final int? newLength;

  /// Number of units that would lose data because of this change.
  final int affectedUnits;

  /// A plain-English description (fallback for logs/tests; the UI may localize
  /// from the structured fields instead).
  String describe() {
    final String category = categoryName.isEmpty
        ? 'category $categoryId'
        : 'category "$categoryName"';
    final String field = fieldName.isEmpty
        ? 'field $fieldId'
        : 'field "$fieldName"';
    return switch (kind) {
      MaskBreakingKind.categoryDeleted =>
        'Deleting $category would orphan $affectedUnits unit(s).',
      MaskBreakingKind.fieldDeleted =>
        'Deleting $field in $category would drop data in '
            '$affectedUnits unit(s).',
      MaskBreakingKind.fieldLengthTooShort =>
        'Shortening $field in $category to $newLength would truncate '
            '$affectedUnits unit(s).',
    };
  }
}

/// The result of comparing an old and new mask against a deck's units.
final class MaskCompatibilityResult {
  /// Creates a compatibility result.
  const MaskCompatibilityResult({required this.status, required this.reasons});

  /// The overall verdict.
  final MaskCompatibility status;

  /// The breaking reasons, empty when [status] is compatible.
  final List<MaskBreakingReason> reasons;

  /// Whether the new mask is safe to auto-apply to the deck.
  bool get isCompatible => status == MaskCompatibility.compatible;
}

/// Classifies whether replacing [oldMask] with [newMask] is safe for a deck
/// whose [units] were authored against [oldMask].
///
/// Non-breaking (auto-applied): adding a category or field; renaming the mask,
/// a category, or a field; changing direction labels; reordering categories or
/// fields; changing equalGroup/role1/role2; increasing a field's length.
///
/// Breaking (gated): deleting a category still referenced by a unit; deleting a
/// field that holds a non-empty value in some unit; decreasing a field's length
/// below data already stored in some unit.
MaskCompatibilityResult checkMaskCompatibility({
  required LearningMask oldMask,
  required LearningMask newMask,
  required List<LearningUnit> units,
}) {
  final List<MaskBreakingReason> reasons = <MaskBreakingReason>[];

  // Units grouped by their category id (units reference categories by id).
  final Map<int, List<LearningUnit>> unitsByCategory =
      <int, List<LearningUnit>>{};
  for (final LearningUnit unit in units) {
    unitsByCategory.putIfAbsent(unit.categoryId, () => <LearningUnit>[]).add(
      unit,
    );
  }

  for (final CategoryDefinition oldCategory in oldMask.categories) {
    final CategoryDefinition? newCategory = newMask.categoryById(
      oldCategory.id,
    );
    final List<LearningUnit> categoryUnits =
        unitsByCategory[oldCategory.id] ?? const <LearningUnit>[];

    if (newCategory == null) {
      // Deleting a category is breaking only if a unit still references it.
      if (categoryUnits.isNotEmpty) {
        reasons.add(
          MaskBreakingReason(
            kind: MaskBreakingKind.categoryDeleted,
            categoryId: oldCategory.id,
            categoryName: oldCategory.name,
            affectedUnits: categoryUnits.length,
          ),
        );
      }
      continue;
    }

    for (final FieldDefinition oldField in oldCategory.fields) {
      final FieldDefinition? newField = newCategory.fieldById(oldField.id);

      if (newField == null) {
        // Deleting a field is breaking only if some unit holds a value for it.
        final int affected = categoryUnits
            .where(
              (LearningUnit unit) => !unit.valueForFieldId(oldField.id).isBlank,
            )
            .length;
        if (affected > 0) {
          reasons.add(
            MaskBreakingReason(
              kind: MaskBreakingKind.fieldDeleted,
              categoryId: oldCategory.id,
              fieldId: oldField.id,
              categoryName: oldCategory.name,
              fieldName: oldField.name,
              affectedUnits: affected,
            ),
          );
        }
        continue;
      }

      if (newField.length < oldField.length) {
        // Shrinking a field is breaking only where stored data exceeds the new
        // length. Increasing (or unchanged) length is always safe.
        final int affected = categoryUnits
            .where(
              (LearningUnit unit) =>
                  unit.valueForFieldId(oldField.id).plainText.length >
                  newField.length,
            )
            .length;
        if (affected > 0) {
          reasons.add(
            MaskBreakingReason(
              kind: MaskBreakingKind.fieldLengthTooShort,
              categoryId: oldCategory.id,
              fieldId: oldField.id,
              categoryName: oldCategory.name,
              fieldName: oldField.name,
              newLength: newField.length,
              affectedUnits: affected,
            ),
          );
        }
      }
    }
  }

  return MaskCompatibilityResult(
    status: reasons.isEmpty
        ? MaskCompatibility.compatible
        : MaskCompatibility.breaking,
    reasons: List<MaskBreakingReason>.unmodifiable(reasons),
  );
}

/// Returns [deck] with its embedded mask replaced by [newMask], dropping unit
/// data that no longer has a home under the new schema.
///
/// Units whose category was removed are dropped; surviving units keep only the
/// field values whose field id still exists in the unit's category. For a
/// COMPATIBLE change this removes nothing meaningful (at most already-blank
/// values); for a forcibly applied BREAKING change it realizes the accepted
/// data loss so the written file stays internally consistent. Field ids are
/// stable, so renaming/reordering never drops anything.
LearningDeck applyMaskToDeck(LearningDeck deck, LearningMask newMask) {
  final List<LearningUnit> units = <LearningUnit>[];
  for (final LearningUnit unit in deck.units) {
    final CategoryDefinition? category = newMask.categoryById(unit.categoryId);
    if (category == null) {
      // The unit's category no longer exists: drop the whole unit.
      continue;
    }
    final Map<int, FieldValue> fields = <int, FieldValue>{};
    for (final MapEntry<int, FieldValue> entry in unit.fields.entries) {
      final FieldDefinition? field = category.fieldById(entry.key);
      if (field == null) {
        // Field removed from the schema: drop its stored value.
        continue;
      }
      // A forced length decrease truncates over-long values so the written
      // deck still satisfies the new schema (and reloads). Compatible changes
      // never exceed the new length, so this is a no-op there.
      fields[entry.key] = _truncateValue(entry.value, field.length);
    }
    units.add(
      LearningUnit(
        categoryId: unit.categoryId,
        fields: Map<int, FieldValue>.unmodifiable(fields),
      ),
    );
  }
  // A mask change is not an edit of the units, even when a forced one drops
  // or truncates values: the deck keeps its last-edited date.
  return LearningDeck(
    mask: newMask,
    units: List<LearningUnit>.unmodifiable(units),
    lastEdited: deck.lastEdited,
  );
}

/// Truncates [value] to at most [maxLength] characters of plain text, keeping
/// run formatting up to the cut. Returns [value] unchanged when it already fits.
FieldValue _truncateValue(FieldValue value, int maxLength) {
  if (value.plainText.length <= maxLength) {
    return value;
  }
  switch (value) {
    case PlainFieldValue(:final String text):
      return FieldValue.plain(text.substring(0, maxLength));
    case RichFieldValue(:final List<RichTextRun> runs):
      final List<RichTextRun> kept = <RichTextRun>[];
      var remaining = maxLength;
      for (final RichTextRun run in runs) {
        if (remaining <= 0) {
          break;
        }
        if (run.text.length <= remaining) {
          kept.add(run);
          remaining -= run.text.length;
        } else {
          kept.add(run.copyWith(text: run.text.substring(0, remaining)));
          remaining = 0;
        }
      }
      return FieldValue.rich(kept);
  }
}
