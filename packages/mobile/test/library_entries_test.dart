import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_mobile/src/mobile_file_service.dart';

// Exercises libraryDeckEntries() directly against in-memory decks: no
// dart:io involved, so this is the exhaustive, instant coverage for the rule
// that MobileFileService.listDecks() and the widget-test fake both defer to.
void main() {
  test('returns an empty list for an empty library', () {
    expect(libraryDeckEntries(const <LibraryDeckSource>[]), isEmpty);
  });

  test('titles each entry by file base name and carries mask name/unit count', () {
    final List<LibraryDeckEntry> entries = libraryDeckEntries(<LibraryDeckSource>[
      _source('/library/my_french.vok', _deck('French', unitCount: 2)),
    ]);

    expect(entries, hasLength(1));
    expect(entries.single.path, '/library/my_french.vok');
    expect(entries.single.name, 'my_french');
    expect(entries.single.maskName, 'French');
    expect(entries.single.unitCount, 2);
  });

  test('keeps decks sharing one mask apart', () {
    final List<LibraryDeckEntry> entries = libraryDeckEntries(<LibraryDeckSource>[
      _source('/library/b.vok', _deck('Verbs')),
      _source('/library/a.vok', _deck('Verbs')),
    ]);

    expect(entries.map((LibraryDeckEntry e) => e.name).toList(), <String>['a', 'b']);
    expect(entries.map((LibraryDeckEntry e) => e.maskName).toSet(), <String>{'Verbs'});
  });

  test('never-practised decks sort above every practised deck', () {
    // A deck imported thirty seconds ago is the one the learner came to the
    // app to open; burying it under twenty practised decks is the worst case
    // on a phone.
    final List<LibraryDeckEntry> entries = libraryDeckEntries(<LibraryDeckSource>[
      _source('/library/worked_on.vok', _deck('A mask'), practisedAt: DateTime(2026, 9, 20)),
      _source('/library/zebra.vok', _deck('A mask')),
      _source('/library/older.vok', _deck('A mask'), practisedAt: DateTime(2026, 1, 1)),
      _source('/library/apple.vok', _deck('A mask')),
    ]);

    expect(entries.map((LibraryDeckEntry e) => e.name).toList(), <String>[
      // Never practised, among themselves by name.
      'apple',
      'zebra',
      // Then practised, newest first.
      'worked_on',
      'older',
    ]);
  });

  test('practised decks come newest first, whatever order they arrive in', () {
    final List<LibraryDeckEntry> entries = libraryDeckEntries(<LibraryDeckSource>[
      _source('/library/middle.vok', _deck('A mask'), practisedAt: DateTime(2026, 5, 5)),
      _source('/library/oldest.vok', _deck('A mask'), practisedAt: DateTime(2025, 1, 1)),
      _source('/library/newest.vok', _deck('A mask'), practisedAt: DateTime(2026, 9, 20, 14, 30)),
    ]);

    expect(entries.map((LibraryDeckEntry e) => e.name).toList(), <String>[
      'newest',
      'middle',
      'oldest',
    ]);
  });

  test('equal times tie-break on the deck name, so the order is stable', () {
    final DateTime sameMoment = DateTime(2026, 9, 20, 9);
    List<String> namesFrom(List<LibraryDeckSource> sources) =>
        libraryDeckEntries(sources).map((LibraryDeckEntry e) => e.name).toList();

    final List<LibraryDeckSource> sources = <LibraryDeckSource>[
      _source('/library/cherries.vok', _deck('A mask'), practisedAt: sameMoment),
      _source('/library/Apples.vok', _deck('Z mask'), practisedAt: sameMoment),
      _source('/library/bananas.vok', _deck('M mask'), practisedAt: sameMoment),
    ];

    expect(namesFrom(sources), <String>['Apples', 'bananas', 'cherries']);
    // The same set in a different arrival order gives the same list: nothing
    // reshuffles under the learner's finger between two visits.
    expect(namesFrom(sources.reversed.toList()), <String>[
      'Apples',
      'bananas',
      'cherries',
    ]);
  });

  test('the mask name orders nothing, in either group', () {
    final List<LibraryDeckEntry> entries = libraryDeckEntries(<LibraryDeckSource>[
      _source('/library/b.vok', _deck('A mask'), practisedAt: DateTime(2026, 1, 1)),
      _source('/library/a.vok', _deck('Z mask'), practisedAt: DateTime(2026, 6, 1)),
    ]);

    // By time, not by either name: the newer deck leads although its mask
    // name sorts last and its file name would have sorted first anyway.
    expect(entries.map((LibraryDeckEntry e) => e.name).toList(), <String>['a', 'b']);
    expect(entries.map((LibraryDeckEntry e) => e.maskName).toList(), <String>[
      'Z mask',
      'A mask',
    ]);
  });
}

LibraryDeckSource _source(
  String path,
  LearningDeck deck, {
  DateTime? practisedAt,
}) {
  return LibraryDeckSource(path: path, deck: deck, lastPractised: practisedAt);
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
