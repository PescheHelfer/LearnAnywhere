import 'dart:io';

import 'package:learn_anywhere_core/core.dart';
import 'package:test/test.dart';

void main() {
  /// The canonical example deck, which predates the difficulty flags.
  String exampleVok() => File('test/fixtures/example.vok').readAsStringSync();

  const LearningMask mask = LearningMask(
    maskId: 'm_new_difficult-units',
    name: 'Sample',
    direction1Label: 'Direction 1',
    direction2Label: 'Direction 2',
    categories: <CategoryDefinition>[
      CategoryDefinition(
        id: 0,
        name: 'Default',
        fields: <FieldDefinition>[
          FieldDefinition(
            id: 0,
            name: 'Question',
            length: 40,
            equalGroup: 0,
            role1: FieldRole.question,
            role2: FieldRole.answer,
          ),
          FieldDefinition(
            id: 1,
            name: 'Answer',
            length: 40,
            equalGroup: 0,
            role1: FieldRole.answer,
            role2: FieldRole.question,
          ),
        ],
      ),
    ],
  );

  LearningUnit unit({bool manual = false, bool automatic = false}) {
    return LearningUnit(
      categoryId: 0,
      fields: const <int, FieldValue>{
        0: FieldValue.plain('house'),
        1: FieldValue.plain('Haus'),
      },
      manualDifficult: manual,
      autoDifficult: automatic,
    );
  }

  group('.vok difficulty flags', () {
    test('a deck without them decodes to unflagged units and re-encodes '
        'byte-for-byte', () {
      final LearningDeck deck = decodeDeckJson(exampleVok());
      for (final LearningUnit unit in deck.units) {
        expect(unit.manualDifficult, isFalse);
        expect(unit.autoDifficult, isFalse);
        expect(unit.isDifficult, isFalse);
      }
      expect(encodeDeckJson(deck), exampleVok());
      expect(encodeDeckJson(deck), isNot(contains('Difficult')));
    });

    test('each flag round-trips, and only a true flag is written', () {
      final LearningDeck deck = LearningDeck(
        mask: mask,
        units: <LearningUnit>[
          unit(),
          unit(manual: true),
          unit(automatic: true),
          unit(manual: true, automatic: true),
        ],
      );
      final String json = encodeDeckJson(deck);
      expect('"manualDifficult": true'.allMatches(json).length, 2);
      expect('"autoDifficult": true'.allMatches(json).length, 2);
      expect(json, isNot(contains('false')));

      final LearningDeck decoded = decodeDeckJson(json);
      expect(
        <(bool, bool)>[
          for (final LearningUnit unit in decoded.units)
            (unit.manualDifficult, unit.autoDifficult),
        ],
        <(bool, bool)>[
          (false, false),
          (true, false),
          (false, true),
          (true, true),
        ],
      );
      expect(encodeDeckJson(decoded), json);
    });

    test('a value that is not a boolean reads as unflagged rather than '
        'failing the load', () {
      for (final Object? value in <Object?>['true', 1, null, <Object?>[]]) {
        final String source = exampleVok().replaceFirst(
          '"categoryId": ',
          '"manualDifficult": ${value is String ? '"$value"' : value},\n'
              '      "categoryId": ',
        );
        final LearningDeck deck = decodeDeckJson(source);
        expect(deck.units.first.manualDifficult, isFalse, reason: '$value');
      }
    });

    test('the identity hash is blind to both flags, so flagging never resets '
        'statistics', () {
      final String plain = unitIdentityHash(mask, unit());
      expect(unitIdentityHash(mask, unit(manual: true)), plain);
      expect(unitIdentityHash(mask, unit(automatic: true)), plain);
      expect(unitIdentityHash(mask, unit(manual: true, automatic: true)), plain);
    });

    test('applying a mask keeps both flags', () {
      final LearningDeck deck = LearningDeck(
        mask: mask,
        units: <LearningUnit>[unit(manual: true), unit(automatic: true)],
      );
      final LearningDeck propagated = applyMaskToDeck(
        deck,
        mask.copyWith(revision: mask.revision + 1),
      );
      expect(propagated.units[0].manualDifficult, isTrue);
      expect(propagated.units[1].autoDifficult, isTrue);
    });
  });

  group('toggleDifficult', () {
    test('an unflagged unit gains the manual flag', () {
      final LearningUnit toggled = toggleDifficult(unit());
      expect(toggled.manualDifficult, isTrue);
      expect(toggled.autoDifficult, isFalse);
    });

    test('a manually flagged unit loses its flag', () {
      final LearningUnit toggled = toggleDifficult(unit(manual: true));
      expect(toggled.isDifficult, isFalse);
    });

    test('an automatically flagged unit loses its flag: "not difficult" means '
        'not difficult', () {
      final LearningUnit toggled = toggleDifficult(unit(automatic: true));
      expect(toggled.manualDifficult, isFalse);
      expect(toggled.autoDifficult, isFalse);
    });

    test('a unit carrying both flags loses both', () {
      final LearningUnit toggled = toggleDifficult(
        unit(manual: true, automatic: true),
      );
      expect(toggled.manualDifficult, isFalse);
      expect(toggled.autoDifficult, isFalse);
    });

    test('the unit content is untouched', () {
      final LearningUnit before = unit();
      final LearningUnit toggled = toggleDifficult(before);
      expect(toggled.categoryId, before.categoryId);
      expect(toggled.fields, same(before.fields));
    });

    test('on a deck it changes only the unit at the one-based index and keeps '
        'the last-edited date', () {
      final LocalTimestamp edited = LocalTimestamp.tryParse(
        '2026-09-25T16:32:11+02:00',
      )!;
      final LearningDeck deck = LearningDeck(
        mask: mask,
        units: <LearningUnit>[unit(), unit(), unit(automatic: true)],
        lastEdited: edited,
      );
      final LearningDeck toggled = toggleDifficultAt(deck, 2);
      expect(
        <bool>[for (final LearningUnit u in toggled.units) u.isDifficult],
        <bool>[false, true, true],
      );
      expect(toggled.units[1].manualDifficult, isTrue);
      expect(toggled.lastEdited, edited);
      expect(toggled.mask, same(deck.mask));
    });
  });

  group('marking a selection', () {
    final LocalTimestamp edited = LocalTimestamp.tryParse(
      '2026-09-25T16:32:11+02:00',
    )!;
    LearningDeck deck() => LearningDeck(
      mask: mask,
      units: <LearningUnit>[
        unit(),
        unit(manual: true),
        unit(automatic: true),
        unit(manual: true, automatic: true),
        unit(),
      ],
      lastEdited: edited,
    );
    List<(bool, bool)> flags(LearningDeck deck) => <(bool, bool)>[
      for (final LearningUnit unit in deck.units)
        (unit.manualDifficult, unit.autoDifficult),
    ];

    test('mark sets the manual flag on each selected unit and keeps any '
        'automatic one', () {
      final LearningDeck marked = markDifficultAt(deck(), <int>{1, 2, 3, 4});
      expect(flags(marked), <(bool, bool)>[
        (true, false),
        (true, false),
        (true, true),
        (true, true),
        (false, false),
      ]);
    });

    test('unmark clears both flags on each selected unit', () {
      final LearningDeck unmarked = unmarkDifficultAt(
        deck(),
        <int>{1, 2, 3, 4},
      );
      expect(flags(unmarked), <(bool, bool)>[
        (false, false),
        (false, false),
        (false, false),
        (false, false),
        (false, false),
      ]);
    });

    test('units outside the selection are untouched', () {
      final LearningDeck marked = markDifficultAt(deck(), <int>{5});
      expect(flags(marked), <(bool, bool)>[
        (false, false),
        (true, false),
        (false, true),
        (true, true),
        (true, false),
      ]);
      final LearningDeck unmarked = unmarkDifficultAt(deck(), <int>{3});
      expect(flags(unmarked), <(bool, bool)>[
        (false, false),
        (true, false),
        (false, false),
        (true, true),
        (false, false),
      ]);
    });

    test('neither is an edit: the deck keeps its last-edited date and its '
        'unit content', () {
      final LearningDeck before = deck();
      for (final LearningDeck after in <LearningDeck>[
        markDifficultAt(before, <int>{1, 5}),
        unmarkDifficultAt(before, <int>{2, 4}),
      ]) {
        expect(after.lastEdited, edited);
        expect(after.mask, same(before.mask));
        for (var i = 0; i < before.units.length; i += 1) {
          expect(after.units[i].fields, same(before.units[i].fields));
        }
      }
    });
  });

  group('the detection rule', () {
    bool detected(
      int attempts,
      int correct, [
      DetectionThresholds thresholds = DetectionThresholds.defaults,
    ]) {
      return isDetectedDifficult(
        DirectionStats(attempts: attempts, correct: correct),
        thresholds,
      );
    }

    test('the defaults are the tested rule: 2 wrong, 33 %, 6 attempts', () {
      expect(DetectionThresholds.defaults.minWrong, 2);
      expect(DetectionThresholds.defaults.minWrongRatePercent, 33);
      expect(DetectionThresholds.defaults.minAttemptsWithoutCorrect, 6);
    });

    test('a unit never answered is not detected', () {
      expect(detected(0, 0), isFalse);
    });

    test('fewer wrong answers than the minimum are not enough, however high '
        'the rate', () {
      expect(detected(2, 1), isFalse); // 1 wrong, 50 %
      expect(detected(3, 1), isTrue); // 2 wrong, 67 %
    });

    test('the wrong rate must reach the minimum, and exactly the minimum '
        'counts', () {
      expect(detected(100, 67), isTrue); // 33 wrong, 33 %
      expect(detected(100, 68), isFalse); // 32 wrong, 32 %
      // The default sits at the tested 1/3, which a whole 33 % admits...
      expect(detected(6, 4), isTrue); // 2 wrong of 6
      // ...while one more right answer takes it below.
      expect(detected(7, 5), isFalse); // 2 wrong of 7, 29 %
    });

    test('a unit never answered correctly needs the minimum attempts', () {
      expect(detected(2, 0), isFalse);
      expect(detected(5, 0), isFalse);
      expect(detected(6, 0), isTrue);
    });

    test('one correct answer lifts the attempts requirement', () {
      expect(detected(3, 1), isTrue);
    });

    test('custom thresholds replace every default', () {
      const DetectionThresholds strict = DetectionThresholds(
        minWrong: 3,
        minWrongRatePercent: 50,
        minAttemptsWithoutCorrect: 4,
      );
      expect(detected(3, 1, strict), isFalse); // 2 wrong
      expect(detected(6, 3, strict), isTrue); // 3 wrong, 50 %
      expect(detected(7, 4, strict), isFalse); // 3 wrong, 43 %
      expect(detected(3, 0, strict), isFalse); // 3 attempts, none correct
      expect(detected(4, 0, strict), isTrue);
    });
  });

  group('adding detected flags', () {
    LearningUnit word(
      String question,
      String answer, {
      bool manual = false,
      bool automatic = false,
    }) {
      return LearningUnit(
        categoryId: 0,
        fields: <int, FieldValue>{
          0: FieldValue.plain(question),
          1: FieldValue.plain(answer),
        },
        manualDifficult: manual,
        autoDifficult: automatic,
      );
    }

    // Qualifies under the defaults: 3 wrong of 4.
    const DirectionStats hard = DirectionStats(attempts: 4, correct: 1);
    // Does not: 1 wrong of 4.
    const DirectionStats easy = DirectionStats(attempts: 4, correct: 3);

    UnitStats stats(
      int index,
      LearningUnit unit, {
      DirectionStats direction1 = const DirectionStats(),
      DirectionStats direction2 = const DirectionStats(),
    }) {
      return UnitStats(
        index: index,
        direction1: direction1,
        direction2: direction2,
        hash: unitIdentityHash(mask, unit),
      );
    }

    List<(bool, bool)> flags(LearningDeck deck) => <(bool, bool)>[
      for (final LearningUnit unit in deck.units)
        (unit.manualDifficult, unit.autoDifficult),
    ];

    test('flags each unit the rule holds for and reports how many', () {
      final LearningUnit house = word('house', 'Haus');
      final LearningUnit tree = word('tree', 'Baum');
      final LearningUnit dog = word('dog', 'Hund');
      final LearningDeck deck = LearningDeck(
        mask: mask,
        units: <LearningUnit>[house, tree, dog],
      );
      final AutomaticFlagChange change = addDetectedDifficult(
        deck,
        AllTimeStatistics(
          perUnit: <UnitStats>[
            stats(1, house, direction1: hard),
            stats(2, tree, direction1: easy),
            stats(3, dog, direction1: hard),
          ],
        ),
      );
      expect(change.added, 2);
      expect(change.changed, isTrue);
      expect(flags(change.deck), <(bool, bool)>[
        (false, true),
        (false, false),
        (false, true),
      ]);
    });

    test('either direction qualifying is enough, but the two are never '
        'summed', () {
      final LearningUnit house = word('house', 'Haus');
      final LearningUnit tree = word('tree', 'Baum');
      final LearningDeck deck = LearningDeck(
        mask: mask,
        units: <LearningUnit>[house, tree],
      );
      // 1 wrong of 2 each way: 2 of 4 together would qualify, neither alone
      // does.
      const DirectionStats half = DirectionStats(attempts: 2, correct: 1);
      final AutomaticFlagChange change = addDetectedDifficult(
        deck,
        AllTimeStatistics(
          perUnit: <UnitStats>[
            stats(1, house, direction1: easy, direction2: hard),
            stats(2, tree, direction1: half, direction2: half),
          ],
        ),
      );
      expect(flags(change.deck), <(bool, bool)>[(false, true), (false, false)]);
    });

    test('never clears a flag, and a unit already flagged automatically is '
        'not counted again', () {
      final LearningUnit stale = word('house', 'Haus', automatic: true);
      final LearningUnit already = word('tree', 'Baum', automatic: true);
      final LearningUnit mine = word('dog', 'Hund', manual: true);
      final LearningUnit mineAndHard = word('cat', 'Katze', manual: true);
      final LearningDeck deck = LearningDeck(
        mask: mask,
        units: <LearningUnit>[stale, already, mine, mineAndHard],
      );
      final AutomaticFlagChange change = addDetectedDifficult(
        deck,
        AllTimeStatistics(
          perUnit: <UnitStats>[
            stats(1, stale, direction1: easy),
            stats(2, already, direction1: hard),
            stats(3, mine, direction1: easy),
            stats(4, mineAndHard, direction1: hard),
          ],
        ),
      );
      expect(change.added, 1);
      expect(flags(change.deck), <(bool, bool)>[
        (false, true),
        (false, true),
        (true, false),
        (true, true),
      ]);
    });

    test('is not an edit: the deck keeps its last-edited date and its unit '
        'content', () {
      final LocalTimestamp edited = LocalTimestamp.tryParse(
        '2026-09-25T16:32:11+02:00',
      )!;
      final LearningUnit house = word('house', 'Haus');
      final LearningDeck deck = LearningDeck(
        mask: mask,
        units: <LearningUnit>[house],
        lastEdited: edited,
      );
      final AutomaticFlagChange change = addDetectedDifficult(
        deck,
        AllTimeStatistics(
          perUnit: <UnitStats>[stats(1, house, direction1: hard)],
        ),
      );
      expect(change.deck.lastEdited, edited);
      expect(change.deck.units.single.fields, same(house.fields));
    });

    test('nothing to add hands back the deck itself', () {
      final LearningUnit house = word('house', 'Haus');
      final LearningDeck deck = LearningDeck(
        mask: mask,
        units: <LearningUnit>[house],
      );
      for (final AllTimeStatistics allTime in <AllTimeStatistics>[
        AllTimeStatistics.empty,
        AllTimeStatistics(
          perUnit: <UnitStats>[stats(1, house, direction1: easy)],
        ),
      ]) {
        final AutomaticFlagChange change = addDetectedDifficult(deck, allTime);
        expect(change.added, 0);
        expect(change.changed, isFalse);
        expect(change.deck, same(deck));
      }
    });

    test('follows a unit that moved, by its identity', () {
      final LearningUnit house = word('house', 'Haus');
      final LearningUnit tree = word('tree', 'Baum');
      // The record was written when house was unit 1; the deck now has tree
      // first.
      final LearningDeck deck = LearningDeck(
        mask: mask,
        units: <LearningUnit>[tree, house],
      );
      final AutomaticFlagChange change = addDetectedDifficult(
        deck,
        AllTimeStatistics(
          perUnit: <UnitStats>[
            stats(1, house, direction1: hard),
            stats(2, tree, direction1: easy),
          ],
        ),
      );
      expect(flags(change.deck), <(bool, bool)>[(false, false), (false, true)]);
    });

    test('a unit with no matching record is not detected', () {
      final LearningUnit house = word('house', 'Haus');
      final LearningUnit gone = word('gone', 'weg');
      final LearningUnit fresh = word('new', 'neu');
      // The hard record belongs to a unit no longer in the deck. It sits at
      // house's position, so matching by position alone would hand it to
      // house; by identity house has its own, easy record.
      final LearningDeck deck = LearningDeck(
        mask: mask,
        units: <LearningUnit>[fresh, house],
      );
      final AutomaticFlagChange change = addDetectedDifficult(
        deck,
        AllTimeStatistics(
          perUnit: <UnitStats>[
            stats(1, house, direction1: easy),
            stats(2, gone, direction1: hard),
          ],
        ),
      );
      expect(change.added, 0);
      expect(flags(change.deck), <(bool, bool)>[(false, false), (false, false)]);
    });

    test('custom thresholds are honoured', () {
      final LearningUnit house = word('house', 'Haus');
      final LearningDeck deck = LearningDeck(
        mask: mask,
        units: <LearningUnit>[house],
      );
      final AllTimeStatistics allTime = AllTimeStatistics(
        perUnit: <UnitStats>[stats(1, house, direction1: hard)],
      );
      expect(
        addDetectedDifficult(
          deck,
          allTime,
          thresholds: const DetectionThresholds(minWrong: 4),
        ).added,
        0,
      );
    });
  });
}
