import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_mobile/src/mobile_file_service.dart';

// Exercises libraryDeckEntries() directly against in-memory decks: no
// dart:io involved, so this is the exhaustive, instant coverage for the rule
// that MobileFileService.listDecks() and the widget-test fake both defer to.
void main() {
  test('returns an empty list for an empty library', () {
    expect(libraryDeckEntries(const <MapEntry<String, LearningDeck>>[]), isEmpty);
  });

  test('titles each entry with the deck mask name and carries path/unit count', () {
    final List<LibraryDeckEntry> entries = libraryDeckEntries(<MapEntry<String, LearningDeck>>[
      MapEntry<String, LearningDeck>('/library/french.vok', _deck('French', unitCount: 2)),
    ]);

    expect(entries, hasLength(1));
    expect(entries.single.path, '/library/french.vok');
    expect(entries.single.name, 'French');
    expect(entries.single.unitCount, 2);
  });

  test('sorts entries case-insensitively by mask name, not input order', () {
    final List<LibraryDeckEntry> entries = libraryDeckEntries(<MapEntry<String, LearningDeck>>[
      MapEntry<String, LearningDeck>('/library/c.vok', _deck('cherries')),
      MapEntry<String, LearningDeck>('/library/a.vok', _deck('Apples')),
      MapEntry<String, LearningDeck>('/library/b.vok', _deck('bananas')),
    ]);

    expect(entries.map((LibraryDeckEntry e) => e.name).toList(), <String>[
      'Apples',
      'bananas',
      'cherries',
    ]);
  });
}

LearningDeck _deck(String maskName, {int unitCount = 1}) {
  return LearningDeck(
    mask: LearningMask(
      maskId: 'm_new_${maskName.toLowerCase()}-fixture',
      name: maskName,
      direction1Label: 'Forward',
      direction2Label: 'Backward',
      categories: const <CategoryDefinition>[
        CategoryDefinition(
          id: 1,
          name: 'Words',
          fields: <FieldDefinition>[
            FieldDefinition(
              id: 0,
              name: 'Prompt field',
              length: 40,
              equalGroup: 0,
              role1: FieldRole.question,
              role2: FieldRole.answer,
            ),
            FieldDefinition(
              id: 1,
              name: 'Answer field',
              length: 40,
              equalGroup: 0,
              role1: FieldRole.answer,
              role2: FieldRole.question,
            ),
          ],
        ),
      ],
    ),
    units: List<LearningUnit>.generate(
      unitCount,
      (int i) => LearningUnit(
        categoryId: 1,
        fields: <int, FieldValue>{
          0: PlainFieldValue('word$i'),
          1: PlainFieldValue('translation$i'),
        },
      ),
    ),
  );
}
