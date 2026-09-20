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

  test('titles each entry by file base name and carries mask name/unit count', () {
    final List<LibraryDeckEntry> entries = libraryDeckEntries(<MapEntry<String, LearningDeck>>[
      MapEntry<String, LearningDeck>('/library/my_french.vok', _deck('French', unitCount: 2)),
    ]);

    expect(entries, hasLength(1));
    expect(entries.single.path, '/library/my_french.vok');
    expect(entries.single.name, 'my_french');
    expect(entries.single.maskName, 'French');
    expect(entries.single.unitCount, 2);
  });

  test('keeps decks sharing one mask apart', () {
    final List<LibraryDeckEntry> entries = libraryDeckEntries(<MapEntry<String, LearningDeck>>[
      MapEntry<String, LearningDeck>('/library/b.vok', _deck('Verbs')),
      MapEntry<String, LearningDeck>('/library/a.vok', _deck('Verbs')),
    ]);

    expect(entries.map((LibraryDeckEntry e) => e.name).toList(), <String>['a', 'b']);
    expect(entries.map((LibraryDeckEntry e) => e.maskName).toSet(), <String>{'Verbs'});
  });

  test('sorts entries case-insensitively by file name, not mask name or input order', () {
    final List<LibraryDeckEntry> entries = libraryDeckEntries(<MapEntry<String, LearningDeck>>[
      MapEntry<String, LearningDeck>('/library/cherries.vok', _deck('A mask')),
      MapEntry<String, LearningDeck>('/library/Apples.vok', _deck('Z mask')),
      MapEntry<String, LearningDeck>('/library/bananas.vok', _deck('M mask')),
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
