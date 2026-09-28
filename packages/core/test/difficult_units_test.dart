import 'dart:io';
import 'dart:math';

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

  /// Each unit's `(manual, automatic)` flags, in deck order.
  List<(bool, bool)> flags(LearningDeck deck) => <(bool, bool)>[
    for (final LearningUnit unit in deck.units)
      (unit.manualDifficult, unit.autoDifficult),
  ];

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
    test('flags each unit the rule holds for and reports how many', () {
      final LearningUnit house = word('house', 'Haus');
      final LearningUnit tree = word('tree', 'Baum');
      final LearningUnit dog = word('dog', 'Hund');
      final LearningDeck deck = LearningDeck(
        mask: mask,
        units: <LearningUnit>[house, tree, dog],
      );
      final DifficultFlagChange change = addDetectedDifficult(
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
      final DifficultFlagChange change = addDetectedDifficult(
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
      final DifficultFlagChange change = addDetectedDifficult(
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
      final DifficultFlagChange change = addDetectedDifficult(
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
        final DifficultFlagChange change = addDetectedDifficult(deck, allTime);
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
      final DifficultFlagChange change = addDetectedDifficult(
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
      final DifficultFlagChange change = addDetectedDifficult(
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

  group('recomputing automatic flags', () {
    test('removes stale automatic flags, adds new ones, keeps those that '
        'still hold, and counts both ways', () {
      final LearningUnit stale = word('house', 'Haus', automatic: true);
      final LearningUnit kept = word('tree', 'Baum', automatic: true);
      final LearningUnit fresh = word('dog', 'Hund');
      final LearningUnit plain = word('cat', 'Katze');
      final LearningDeck deck = LearningDeck(
        mask: mask,
        units: <LearningUnit>[stale, kept, fresh, plain],
      );
      final DifficultFlagChange change = recomputeDetectedDifficult(
        deck,
        AllTimeStatistics(
          perUnit: <UnitStats>[
            stats(1, stale, direction1: easy),
            stats(2, kept, direction2: hard),
            stats(3, fresh, direction1: hard),
            stats(4, plain, direction1: easy),
          ],
        ),
      );
      expect(change.added, 1);
      expect(change.removed, 1);
      expect(change.changed, isTrue);
      expect(flags(change.deck), <(bool, bool)>[
        (false, false),
        (false, true),
        (false, true),
        (false, false),
      ]);
    });

    test('never touches a manual flag, whatever the rule says', () {
      final LearningUnit mineStale = word(
        'house',
        'Haus',
        manual: true,
        automatic: true,
      );
      final LearningUnit mineEasy = word('tree', 'Baum', manual: true);
      final LearningUnit mineHard = word('dog', 'Hund', manual: true);
      final LearningDeck deck = LearningDeck(
        mask: mask,
        units: <LearningUnit>[mineStale, mineEasy, mineHard],
      );
      final DifficultFlagChange change = recomputeDetectedDifficult(
        deck,
        AllTimeStatistics(
          perUnit: <UnitStats>[
            stats(1, mineStale, direction1: easy),
            stats(2, mineEasy, direction1: easy),
            stats(3, mineHard, direction1: hard),
          ],
        ),
      );
      expect(change.added, 1);
      expect(change.removed, 1);
      expect(flags(change.deck), <(bool, bool)>[
        (true, false),
        (true, false),
        (true, true),
      ]);
    });

    test('a deck without statistics loses every automatic flag', () {
      final LearningUnit house = word('house', 'Haus', automatic: true);
      final LearningUnit tree = word(
        'tree',
        'Baum',
        manual: true,
        automatic: true,
      );
      final LearningDeck deck = LearningDeck(
        mask: mask,
        units: <LearningUnit>[house, tree],
      );
      final DifficultFlagChange change = recomputeDetectedDifficult(
        deck,
        AllTimeStatistics.empty,
      );
      expect(change.added, 0);
      expect(change.removed, 2);
      expect(flags(change.deck), <(bool, bool)>[(false, false), (true, false)]);
    });

    test('is not an edit, and nothing to change hands back the deck '
        'itself', () {
      final LocalTimestamp edited = LocalTimestamp.tryParse(
        '2026-09-25T16:32:11+02:00',
      )!;
      final LearningUnit house = word('house', 'Haus', automatic: true);
      final LearningUnit tree = word('tree', 'Baum');
      final LearningDeck deck = LearningDeck(
        mask: mask,
        units: <LearningUnit>[house, tree],
        lastEdited: edited,
      );
      final AllTimeStatistics allTime = AllTimeStatistics(
        perUnit: <UnitStats>[
          stats(1, house, direction1: hard),
          stats(2, tree, direction1: easy),
        ],
      );
      final DifficultFlagChange unchanged = recomputeDetectedDifficult(
        deck,
        allTime,
      );
      expect(unchanged.changed, isFalse);
      expect(unchanged.deck, same(deck));

      final DifficultFlagChange changed = recomputeDetectedDifficult(
        deck,
        AllTimeStatistics.empty,
      );
      expect(changed.deck.lastEdited, edited);
      expect(changed.deck.units.first.fields, same(house.fields));
    });

    test('custom thresholds are honoured', () {
      final LearningUnit house = word('house', 'Haus', automatic: true);
      final LearningDeck deck = LearningDeck(
        mask: mask,
        units: <LearningUnit>[house],
      );
      final DifficultFlagChange change = recomputeDetectedDifficult(
        deck,
        AllTimeStatistics(
          perUnit: <UnitStats>[stats(1, house, direction1: hard)],
        ),
        thresholds: const DetectionThresholds(minWrong: 4),
      );
      expect(change.removed, 1);
      expect(flags(change.deck), <(bool, bool)>[(false, false)]);
    });
  });

  group('clearing manual flags', () {
    test('clears every manual flag, keeps automatic ones, and counts', () {
      final LearningDeck deck = LearningDeck(
        mask: mask,
        units: <LearningUnit>[
          unit(manual: true),
          unit(manual: true, automatic: true),
          unit(automatic: true),
          unit(),
        ],
      );
      final DifficultFlagChange change = clearManualDifficult(deck);
      expect(change.removed, 2);
      expect(change.added, 0);
      expect(change.changed, isTrue);
      expect(flags(change.deck), <(bool, bool)>[
        (false, false),
        (false, true),
        (false, true),
        (false, false),
      ]);
    });

    test('is not an edit, and a deck without manual flags comes back as it '
        'is', () {
      final LocalTimestamp edited = LocalTimestamp.tryParse(
        '2026-09-25T16:32:11+02:00',
      )!;
      final LearningDeck flagged = LearningDeck(
        mask: mask,
        units: <LearningUnit>[unit(manual: true)],
        lastEdited: edited,
      );
      expect(clearManualDifficult(flagged).deck.lastEdited, edited);

      final LearningDeck clean = LearningDeck(
        mask: mask,
        units: <LearningUnit>[unit(automatic: true), unit()],
      );
      final DifficultFlagChange change = clearManualDifficult(clean);
      expect(change.removed, 0);
      expect(change.changed, isFalse);
      expect(change.deck, same(clean));
    });
  });

  group('difficult units only', () {
    // Units 1, 3 and 4 are difficult, each by a different flag; 2 and 5 are
    // not.
    final LearningDeck deck = LearningDeck(
      mask: mask,
      units: <LearningUnit>[
        word('one', 'eins', manual: true),
        word('two', 'zwei'),
        word('three', 'drei', automatic: true),
        word('four', 'vier', manual: true, automatic: true),
        word('five', 'fünf'),
      ],
    );
    final LearningDeck noneFlagged = LearningDeck(
      mask: mask,
      units: <LearningUnit>[word('one', 'eins'), word('two', 'zwei')],
    );

    SessionParameters only(SessionMode mode, {int? start, int? end}) {
      return SessionParameters(
        directionSelection: DirectionSelection.direction1,
        mode: mode,
        startIndex: start,
        endIndex: end,
        difficultOnly: true,
      );
    }

    /// The unit indices of [items], in order.
    List<int> unitsOf(List<SessionItem> items) => <int>[
      for (final SessionItem item in items) item.unitIndex,
    ];

    test('is off by default, so every unit is in scope', () {
      expect(const SessionParameters().difficultOnly, isFalse);
      expect(
        unitsOf(
          itemsInScope(
            deck,
            const SessionParameters(
              directionSelection: DirectionSelection.direction1,
            ),
          ),
        ),
        <int>[1, 2, 3, 4, 5],
      );
    });

    test('narrows the practice and once-through order to units with either '
        'flag, within the unit range', () {
      for (final SessionMode mode in <SessionMode>[
        SessionMode.practice,
        SessionMode.onceThrough,
      ]) {
        expect(unitsOf(itemsInScope(deck, only(mode))), <int>[1, 3, 4]);
        expect(
          unitsOf(
            sessionItemOrder(
              deck: deck,
              parameters: only(mode, start: 2, end: 5),
              random: Random(1),
            ),
          ),
          <int>[3, 4],
        );
      }
    });

    test('every unit a practice draw serves is difficult', () {
      final Random random = Random(7);
      for (var draw = 0; draw < 50; draw += 1) {
        final SessionItem? item = pickPracticeItem(
          deck: deck,
          parameters: only(SessionMode.practice),
          random: random,
        );
        expect(<int>[1, 3, 4], contains(item!.unitIndex));
      }
    });

    test('narrows the drill pool, and mastery still removes a difficult unit '
        'from it', () {
      // Unit 1 is mastered in direction 1; unit 3 has tried and failed.
      final List<UnitStats> statistics = <UnitStats>[
        const UnitStats(
          index: 1,
          direction1: DirectionStats(attempts: 2, correct: 2),
        ),
        const UnitStats(index: 3, direction1: DirectionStats(attempts: 2)),
      ];
      final List<SessionItem> pool = activeSuperQueryPool(
        deck: deck,
        statistics: statistics,
        parameters: only(SessionMode.superQuery),
      );
      expect(unitsOf(pool), <int>[3, 4]);
      // Both directions: a difficult unit is asked both ways.
      expect(
        activeSuperQueryPool(
          deck: deck,
          statistics: const <UnitStats>[],
          parameters: const SessionParameters(
            mode: SessionMode.superQuery,
            difficultOnly: true,
          ),
        ),
        const <SessionItem>[
          SessionItem(unitIndex: 1, direction: QueryDirection.direction1),
          SessionItem(unitIndex: 1, direction: QueryDirection.direction2),
          SessionItem(unitIndex: 3, direction: QueryDirection.direction1),
          SessionItem(unitIndex: 3, direction: QueryDirection.direction2),
          SessionItem(unitIndex: 4, direction: QueryDirection.direction1),
          SessionItem(unitIndex: 4, direction: QueryDirection.direction2),
        ],
      );
    });

    test('narrows the Level Learning pool, and level-0 mastery still removes '
        'a difficult unit from it', () {
      final List<LevelUnitStats> levelStatistics = <LevelUnitStats>[
        LevelUnitStats(
          index: 4,
          dir1: const LevelDirectionStats(
            currentLevel: kFreeRecallLevel,
            levels: <int, DirectionStats>{
              kFreeRecallLevel: DirectionStats(attempts: 2, correct: 2),
            },
          ),
          dir2: LevelDirectionStats.fresh(kMaxSupportLevel),
        ),
      ];
      final List<SessionItem> pool = activeLevelLearningPool(
        deck: deck,
        statistics: const <UnitStats>[],
        levelStatistics: levelStatistics,
        parameters: only(SessionMode.levelLearning),
      );
      expect(unitsOf(pool), <int>[1, 3]);
    });

    test('a deck, or a unit range, without difficult units yields an empty '
        'pool in every mode', () {
      for (final (LearningDeck subject, int? start, int? end)
          in <(LearningDeck, int?, int?)>[
            (noneFlagged, null, null),
            (deck, 5, 5),
          ]) {
        for (final SessionMode mode in SessionMode.values) {
          final SessionParameters parameters = only(
            mode,
            start: start,
            end: end,
          );
          expect(itemsInScope(subject, parameters), isEmpty);
          expect(
            sessionItemOrder(
              deck: subject,
              parameters: parameters,
              random: Random(1),
            ),
            isEmpty,
          );
          expect(
            pickPracticeItem(
              deck: subject,
              parameters: parameters,
              random: Random(1),
            ),
            isNull,
          );
          expect(
            activeSuperQueryPool(
              deck: subject,
              statistics: const <UnitStats>[],
              parameters: parameters,
            ),
            isEmpty,
          );
          expect(
            activeLevelLearningPool(
              deck: subject,
              statistics: const <UnitStats>[],
              levelStatistics: const <LevelUnitStats>[],
              parameters: parameters,
            ),
            isEmpty,
          );
        }
      }
    });

    test('narrows what is asked, never what the live readouts count', () {
      final SessionParameters wide = deckWideScope(
        only(SessionMode.superQuery),
      );
      expect(wide.difficultOnly, isFalse);
      expect(
        unitsOf(
          activeSuperQueryPool(
            deck: deck,
            statistics: const <UnitStats>[],
            parameters: wide,
          ),
        ),
        <int>[1, 2, 3, 4, 5],
      );
    });

    test('copyWith keeps and changes the option', () {
      final SessionParameters on = only(SessionMode.practice);
      expect(on.copyWith(shuffle: true).difficultOnly, isTrue);
      expect(on.copyWith(difficultOnly: false).difficultOnly, isFalse);
    });
  });

  group('Lexicon', () {
    // Units 1, 3 and 4 are difficult, each by a different flag; 2 and 5 are
    // not. Every unit contains "e", so a search for it matches them all.
    final LearningDeck deck = LearningDeck(
      mask: mask,
      units: <LearningUnit>[
        word('one', 'eins', manual: true),
        word('two', 'zwei'),
        word('three', 'drei', automatic: true),
        word('four', 'vier', manual: true, automatic: true),
        word('five', 'fünf'),
      ],
    );

    /// The unit indices of [outcome]'s hits, in order.
    List<int> hitsOf(SearchOutcome outcome) => <int>[
      for (final SearchResult result in outcome.results) result.unitIndex,
    ];

    test('the filter is off by default, so every matching unit is found', () {
      expect(hitsOf(searchDeck(deck: deck, query: 'e')), <int>[1, 2, 3, 4, 5]);
    });

    test('Difficult only keeps units with either flag, ANDed with the search '
        'text', () {
      expect(
        hitsOf(searchDeck(deck: deck, query: 'e', difficultOnly: true)),
        <int>[1, 3, 4],
      );
      // "ei" matches eins, zwei and drei; the filter drops zwei.
      expect(
        hitsOf(searchDeck(deck: deck, query: 'ei', difficultOnly: true)),
        <int>[1, 3],
      );
      expect(
        hitsOf(searchDeck(deck: deck, query: 'zwei', difficultOnly: true)),
        isEmpty,
      );
    });

    test('an empty query with the filter lists every difficult unit', () {
      expect(
        hitsOf(searchDeck(deck: deck, query: '', difficultOnly: true)),
        <int>[1, 3, 4],
      );
    });

    test('the result cap counts only difficult hits', () {
      final SearchOutcome capped = searchDeck(
        deck: deck,
        query: '',
        difficultOnly: true,
        maxResults: 2,
      );
      expect(hitsOf(capped), <int>[1, 3]);
      expect(capped.isTruncated, isTrue);

      // Unit 5 matches the text but not the filter, so three difficult hits
      // exactly fill a cap of three.
      final SearchOutcome exact = searchDeck(
        deck: deck,
        query: '',
        difficultOnly: true,
        maxResults: 3,
      );
      expect(hitsOf(exact), <int>[1, 3, 4]);
      expect(exact.isTruncated, isFalse);
    });

    test('a file search applies the filter to every deck, with no statistics '
        'loaded', () {
      final LearningDeck other = LearningDeck(
        mask: mask,
        units: <LearningUnit>[
          word('six', 'sechs'),
          word('seven', 'sieben', automatic: true),
        ],
      );
      final SearchOutcome outcome = searchDeckFiles(
        decksBySource: <String, LearningDeck>{'a.vok': deck, 'b.vok': other},
        query: '',
        difficultOnly: true,
      );
      expect(
        <String>[
          for (final SearchResult result in outcome.results)
            '${result.sourceFile}#${result.unitIndex}',
        ],
        <String>['a.vok#1', 'a.vok#3', 'a.vok#4', 'b.vok#2'],
      );
    });

    test('re-keying hits onto a reference mask keeps both flags', () {
      // The reference comes from another deck of the same mask: a later
      // revision with a renamed field and one added.
      final LearningMask reference = mask.copyWith(
        revision: mask.revision + 1,
        categories: <CategoryDefinition>[
          CategoryDefinition(
            id: 0,
            name: 'Default',
            fields: <FieldDefinition>[
              mask.categories.single.fields[0].copyWith(name: 'Word'),
              mask.categories.single.fields[1],
              const FieldDefinition(
                id: 2,
                name: 'Note',
                length: 40,
                equalGroup: 1,
                role1: FieldRole.remark,
                role2: FieldRole.remark,
              ),
            ],
          ),
        ],
      );
      final LearningDeck hits = LearningDeck(
        mask: mask,
        units: deck.units.take(4).toList(),
      );
      expect(
        checkMaskCompatibility(
          oldMask: mask,
          newMask: reference,
          units: hits.units,
        ).isCompatible,
        isTrue,
      );

      final LearningDeck rekeyed = applyMaskToDeck(hits, reference);

      expect(
        <(bool, bool)>[
          for (final LearningUnit unit in rekeyed.units)
            (unit.manualDifficult, unit.autoDifficult),
        ],
        <(bool, bool)>[
          (true, false),
          (false, false),
          (false, true),
          (true, true),
        ],
      );
    });
  });
}
