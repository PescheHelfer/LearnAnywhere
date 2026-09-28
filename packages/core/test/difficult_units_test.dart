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

  // The four states one direction can be in.
  const DifficultFlags noFlag = DifficultFlags.none;
  const DifficultFlags manualFlag = DifficultFlags(manual: true);
  const DifficultFlags autoFlag = DifficultFlags(automatic: true);
  const DifficultFlags bothFlags = DifficultFlags(
    manual: true,
    automatic: true,
  );

  LearningUnit unit({
    DifficultFlags d1 = DifficultFlags.none,
    DifficultFlags d2 = DifficultFlags.none,
  }) {
    return LearningUnit(
      categoryId: 0,
      fields: const <int, FieldValue>{
        0: FieldValue.plain('house'),
        1: FieldValue.plain('Haus'),
      },
      direction1Flags: d1,
      direction2Flags: d2,
    );
  }

  LearningUnit word(
    String question,
    String answer, {
    DifficultFlags d1 = DifficultFlags.none,
    DifficultFlags d2 = DifficultFlags.none,
  }) {
    return LearningUnit(
      categoryId: 0,
      fields: <int, FieldValue>{
        0: FieldValue.plain(question),
        1: FieldValue.plain(answer),
      },
      direction1Flags: d1,
      direction2Flags: d2,
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

  /// Each unit's `(Direction 1, Direction 2)` flags, in deck order.
  List<(DifficultFlags, DifficultFlags)> flags(LearningDeck deck) =>
      <(DifficultFlags, DifficultFlags)>[
        for (final LearningUnit unit in deck.units)
          (unit.direction1Flags, unit.direction2Flags),
      ];

  /// The direction that is not [direction].
  QueryDirection other(QueryDirection direction) =>
      direction == QueryDirection.direction1
      ? QueryDirection.direction2
      : QueryDirection.direction1;

  group('flags on a unit', () {
    test('an unflagged unit is difficult in neither direction', () {
      final LearningUnit plain = unit();
      expect(plain.direction1Flags, noFlag);
      expect(plain.direction2Flags, noFlag);
      expect(plain.isDifficultIn(QueryDirection.direction1), isFalse);
      expect(plain.isDifficultIn(QueryDirection.direction2), isFalse);
      expect(plain.isDifficultInEither, isFalse);
    });

    test('a flag in one direction makes the unit difficult in that direction '
        'only, and in either', () {
      for (final DifficultFlags set in <DifficultFlags>[
        manualFlag,
        autoFlag,
        bothFlags,
      ]) {
        final LearningUnit oneWay = unit(d2: set);
        expect(oneWay.flagsFor(QueryDirection.direction2), set);
        expect(oneWay.flagsFor(QueryDirection.direction1), noFlag);
        expect(oneWay.isDifficultIn(QueryDirection.direction2), isTrue);
        expect(oneWay.isDifficultIn(QueryDirection.direction1), isFalse);
        expect(oneWay.isDifficultInEither, isTrue);
      }
    });

    test('flagsInEither merges the two directions flag by flag', () {
      expect(unit().flagsInEither, noFlag);
      expect(unit(d2: manualFlag).flagsInEither, manualFlag);
      expect(unit(d1: manualFlag, d2: autoFlag).flagsInEither, bothFlags);
      expect(unit(d1: autoFlag, d2: autoFlag).flagsInEither, autoFlag);
    });

    test('flagsIn merges only the directions it is given', () {
      final LearningUnit mixed = unit(d1: manualFlag, d2: autoFlag);
      expect(mixed.flagsIn(<QueryDirection>{QueryDirection.direction1}),
          manualFlag);
      expect(mixed.flagsIn(<QueryDirection>{QueryDirection.direction2}),
          autoFlag);
      expect(mixed.flagsIn(QueryDirection.values), bothFlags);
      expect(mixed.flagsIn(const <QueryDirection>{}), noFlag);
    });

    test('a View covers its own direction, and Combined covers both', () {
      expect(StatisticsDirectionView.direction1.directions,
          <QueryDirection>{QueryDirection.direction1});
      expect(StatisticsDirectionView.direction2.directions,
          <QueryDirection>{QueryDirection.direction2});
      expect(StatisticsDirectionView.combined.directions,
          QueryDirection.values.toSet());
    });

    test('withFlags replaces one direction and keeps the other and the '
        'content', () {
      final LearningUnit before = unit(d1: manualFlag, d2: autoFlag);
      final LearningUnit after = before.withFlags(
        QueryDirection.direction2,
        bothFlags,
      );
      expect(after.direction1Flags, manualFlag);
      expect(after.direction2Flags, bothFlags);
      expect(after.fields, same(before.fields));
      expect(after.categoryId, before.categoryId);
    });

    test('copyWith keeps both directions unless told otherwise', () {
      final LearningUnit before = unit(d1: manualFlag, d2: autoFlag);
      final LearningUnit edited = before.copyWith(
        fields: const <int, FieldValue>{0: FieldValue.plain('home')},
      );
      expect(edited.direction1Flags, manualFlag);
      expect(edited.direction2Flags, autoFlag);
    });
  });

  group('.vok difficulty flags', () {
    test('a deck without them decodes to unflagged units and re-encodes '
        'byte-for-byte', () {
      final LearningDeck deck = decodeDeckJson(exampleVok());
      for (final LearningUnit unit in deck.units) {
        expect(unit.direction1Flags, noFlag);
        expect(unit.direction2Flags, noFlag);
      }
      expect(encodeDeckJson(deck), exampleVok());
      expect(encodeDeckJson(deck), isNot(contains('Difficult')));
    });

    test('each of the four keys round-trips, and only a true flag is '
        'written', () {
      final LearningDeck deck = LearningDeck(
        mask: mask,
        units: <LearningUnit>[
          unit(),
          unit(d1: manualFlag),
          unit(d2: manualFlag),
          unit(d1: autoFlag),
          unit(d2: autoFlag),
          unit(d1: bothFlags, d2: bothFlags),
          unit(d1: manualFlag, d2: autoFlag),
        ],
      );
      final String json = encodeDeckJson(deck);
      expect('"manualDifficult1": true'.allMatches(json).length, 3);
      expect('"manualDifficult2": true'.allMatches(json).length, 2);
      expect('"autoDifficult1": true'.allMatches(json).length, 2);
      expect('"autoDifficult2": true'.allMatches(json).length, 3);
      expect(json, isNot(contains('false')));
      // The development keys are never written.
      expect(json, isNot(contains('"manualDifficult":')));
      expect(json, isNot(contains('"autoDifficult":')));

      final LearningDeck decoded = decodeDeckJson(json);
      expect(flags(decoded), flags(deck));
      expect(encodeDeckJson(decoded), json);
    });

    test('the development keys are read as Direction 1 and written back as '
        'its keys', () {
      final String source = exampleVok().replaceFirst(
        '"categoryId": ',
        '"manualDifficult": true,\n'
            '      "autoDifficult": true,\n'
            '      "categoryId": ',
      );
      final LearningDeck deck = decodeDeckJson(source);
      expect(deck.units.first.direction1Flags, bothFlags);
      expect(deck.units.first.direction2Flags, noFlag);

      final String json = encodeDeckJson(deck);
      expect(json, contains('"manualDifficult1": true'));
      expect(json, contains('"autoDifficult1": true'));
      expect(json, isNot(contains('"manualDifficult":')));
      expect(json, isNot(contains('"autoDifficult":')));
    });

    test('an old and a new key for Direction 1 flag it if either says so', () {
      for (final String keys in <String>[
        '"manualDifficult": true, "manualDifficult1": false,',
        '"manualDifficult": false, "manualDifficult1": true,',
      ]) {
        final LearningDeck deck = decodeDeckJson(
          exampleVok().replaceFirst('"categoryId": ', '$keys "categoryId": '),
        );
        expect(deck.units.first.direction1Flags, manualFlag, reason: keys);
        expect(deck.units.first.direction2Flags, noFlag, reason: keys);
      }
    });

    test('a value that is not a boolean reads as unflagged rather than '
        'failing the load', () {
      for (final String key in <String>[
        'manualDifficult1',
        'manualDifficult2',
        'autoDifficult1',
        'autoDifficult2',
        'manualDifficult',
        'autoDifficult',
      ]) {
        for (final Object? value in <Object?>['true', 1, null, <Object?>[]]) {
          final String source = exampleVok().replaceFirst(
            '"categoryId": ',
            '"$key": ${value is String ? '"$value"' : value},\n'
                '      "categoryId": ',
          );
          final LearningUnit first = decodeDeckJson(source).units.first;
          expect(first.isDifficultInEither, isFalse, reason: '$key: $value');
        }
      }
    });

    test('the identity hash is blind to every flag, so flagging never resets '
        'statistics', () {
      final String plain = unitIdentityHash(mask, unit());
      for (final DifficultFlags set in <DifficultFlags>[
        manualFlag,
        autoFlag,
        bothFlags,
      ]) {
        expect(unitIdentityHash(mask, unit(d1: set)), plain);
        expect(unitIdentityHash(mask, unit(d2: set)), plain);
        expect(unitIdentityHash(mask, unit(d1: set, d2: set)), plain);
      }
    });

    test('applying a mask keeps every flag in its direction', () {
      final LearningDeck deck = LearningDeck(
        mask: mask,
        units: <LearningUnit>[
          unit(d1: manualFlag, d2: autoFlag),
          unit(d2: bothFlags),
        ],
      );
      final LearningDeck propagated = applyMaskToDeck(
        deck,
        mask.copyWith(revision: mask.revision + 1),
      );
      expect(flags(propagated), flags(deck));
    });
  });

  group('toggleDifficult', () {
    for (final QueryDirection direction in QueryDirection.values) {
      group('in ${direction.name}', () {
        // The other direction carries both flags throughout, so any change
        // to it shows.
        LearningUnit subject(DifficultFlags flags) =>
            unit().withFlags(direction, flags).withFlags(
              other(direction),
              bothFlags,
            );

        test('an unflagged direction gains the manual flag', () {
          final LearningUnit toggled = toggleDifficult(
            subject(noFlag),
            direction,
          );
          expect(toggled.flagsFor(direction), manualFlag);
          expect(toggled.flagsFor(other(direction)), bothFlags);
        });

        test('a manual flag is removed', () {
          final LearningUnit toggled = toggleDifficult(
            subject(manualFlag),
            direction,
          );
          expect(toggled.flagsFor(direction), noFlag);
          expect(toggled.flagsFor(other(direction)), bothFlags);
        });

        test('an automatic flag is removed: "not difficult" means not '
            'difficult', () {
          final LearningUnit toggled = toggleDifficult(
            subject(autoFlag),
            direction,
          );
          expect(toggled.flagsFor(direction), noFlag);
          expect(toggled.flagsFor(other(direction)), bothFlags);
        });

        test('both flags are removed together', () {
          final LearningUnit toggled = toggleDifficult(
            subject(bothFlags),
            direction,
          );
          expect(toggled.flagsFor(direction), noFlag);
          expect(toggled.flagsFor(other(direction)), bothFlags);
        });
      });
    }

    test('the unit content is untouched', () {
      final LearningUnit before = unit();
      final LearningUnit toggled = toggleDifficult(
        before,
        QueryDirection.direction1,
      );
      expect(toggled.categoryId, before.categoryId);
      expect(toggled.fields, same(before.fields));
    });

    test('on a deck it changes only the unit at the one-based index, in the '
        'given direction, and keeps the last-edited date', () {
      final LocalTimestamp edited = LocalTimestamp.tryParse(
        '2026-09-25T16:32:11+02:00',
      )!;
      final LearningDeck deck = LearningDeck(
        mask: mask,
        units: <LearningUnit>[unit(), unit(), unit(d1: autoFlag)],
        lastEdited: edited,
      );
      final LearningDeck toggled = toggleDifficultAt(
        deck,
        2,
        QueryDirection.direction2,
      );
      expect(flags(toggled), <(DifficultFlags, DifficultFlags)>[
        (noFlag, noFlag),
        (noFlag, manualFlag),
        (autoFlag, noFlag),
      ]);
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
        unit(d1: manualFlag),
        unit(d1: autoFlag, d2: autoFlag),
        unit(d1: bothFlags),
        unit(d2: manualFlag),
      ],
      lastEdited: edited,
    );

    test('mark in one direction sets that manual flag on each selected unit, '
        'keeping any automatic one and the other direction', () {
      final LearningDeck marked = markDifficultAt(
        deck(),
        <int>{1, 2, 3, 4},
        <QueryDirection>{QueryDirection.direction1},
      );
      expect(flags(marked), <(DifficultFlags, DifficultFlags)>[
        (manualFlag, noFlag),
        (manualFlag, noFlag),
        (bothFlags, autoFlag),
        (bothFlags, noFlag),
        (noFlag, manualFlag),
      ]);
    });

    test('mark in both directions sets both manual flags', () {
      final LearningDeck marked = markDifficultAt(
        deck(),
        <int>{1, 3},
        QueryDirection.values.toSet(),
      );
      expect(flags(marked), <(DifficultFlags, DifficultFlags)>[
        (manualFlag, manualFlag),
        (manualFlag, noFlag),
        (bothFlags, bothFlags),
        (bothFlags, noFlag),
        (noFlag, manualFlag),
      ]);
    });

    test('unmark in one direction clears both of its flags and leaves the '
        'other direction', () {
      final LearningDeck unmarked = unmarkDifficultAt(
        deck(),
        <int>{2, 3, 4, 5},
        <QueryDirection>{QueryDirection.direction1},
      );
      expect(flags(unmarked), <(DifficultFlags, DifficultFlags)>[
        (noFlag, noFlag),
        (noFlag, noFlag),
        (noFlag, autoFlag),
        (noFlag, noFlag),
        (noFlag, manualFlag),
      ]);
    });

    test('unmark in both directions clears every flag', () {
      final LearningDeck unmarked = unmarkDifficultAt(
        deck(),
        <int>{1, 2, 3, 4, 5},
        QueryDirection.values.toSet(),
      );
      for (final (DifficultFlags, DifficultFlags) unitFlags in flags(
        unmarked,
      )) {
        expect(unitFlags, (noFlag, noFlag));
      }
    });

    test('neither is an edit: the deck keeps its last-edited date and its '
        'unit content', () {
      final LearningDeck before = deck();
      for (final LearningDeck after in <LearningDeck>[
        markDifficultAt(before, <int>{1, 5}, QueryDirection.values.toSet()),
        unmarkDifficultAt(before, <int>{2, 4}, QueryDirection.values.toSet()),
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
    test('flags each unit the rule holds for, in that direction, and reports '
        'how many', () {
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
            stats(3, dog, direction2: hard),
          ],
        ),
      );
      expect(change.added, 2);
      expect(change.changed, isTrue);
      expect(flags(change.deck), <(DifficultFlags, DifficultFlags)>[
        (autoFlag, noFlag),
        (noFlag, noFlag),
        (noFlag, autoFlag),
      ]);
    });

    test('each direction is judged on its own and never summed; a unit '
        'qualifying both ways counts two flags', () {
      final LearningUnit house = word('house', 'Haus');
      final LearningUnit tree = word('tree', 'Baum');
      final LearningUnit dog = word('dog', 'Hund');
      final LearningDeck deck = LearningDeck(
        mask: mask,
        units: <LearningUnit>[house, tree, dog],
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
            stats(3, dog, direction1: hard, direction2: hard),
          ],
        ),
      );
      expect(change.added, 3);
      expect(flags(change.deck), <(DifficultFlags, DifficultFlags)>[
        (noFlag, autoFlag),
        (noFlag, noFlag),
        (autoFlag, autoFlag),
      ]);
    });

    test('never clears a flag, and a direction already flagged '
        'automatically is not counted again', () {
      final LearningUnit stale = word('house', 'Haus', d1: autoFlag);
      final LearningUnit already = word('tree', 'Baum', d2: autoFlag);
      final LearningUnit mine = word('dog', 'Hund', d1: manualFlag);
      final LearningUnit mineAndHard = word('cat', 'Katze', d1: manualFlag);
      final LearningDeck deck = LearningDeck(
        mask: mask,
        units: <LearningUnit>[stale, already, mine, mineAndHard],
      );
      final DifficultFlagChange change = addDetectedDifficult(
        deck,
        AllTimeStatistics(
          perUnit: <UnitStats>[
            stats(1, stale, direction1: easy),
            stats(2, already, direction2: hard),
            stats(3, mine, direction1: easy),
            stats(4, mineAndHard, direction1: hard),
          ],
        ),
      );
      expect(change.added, 1);
      expect(flags(change.deck), <(DifficultFlags, DifficultFlags)>[
        (autoFlag, noFlag),
        (noFlag, autoFlag),
        (manualFlag, noFlag),
        (bothFlags, noFlag),
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
      expect(flags(change.deck), <(DifficultFlags, DifficultFlags)>[
        (noFlag, noFlag),
        (autoFlag, noFlag),
      ]);
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
      expect(change.deck, same(deck));
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
        'still hold, per direction, and counts flags both ways', () {
      final LearningUnit stale = word('house', 'Haus', d1: autoFlag);
      final LearningUnit kept = word('tree', 'Baum', d2: autoFlag);
      final LearningUnit fresh = word('dog', 'Hund');
      final LearningUnit plain = word('cat', 'Katze');
      // Flagged the wrong way round: loses Direction 1, gains Direction 2.
      final LearningUnit swapped = word('bird', 'Vogel', d1: autoFlag);
      final LearningDeck deck = LearningDeck(
        mask: mask,
        units: <LearningUnit>[stale, kept, fresh, plain, swapped],
      );
      final DifficultFlagChange change = recomputeDetectedDifficult(
        deck,
        AllTimeStatistics(
          perUnit: <UnitStats>[
            stats(1, stale, direction1: easy),
            stats(2, kept, direction2: hard),
            stats(3, fresh, direction1: hard, direction2: hard),
            stats(4, plain, direction1: easy),
            stats(5, swapped, direction1: easy, direction2: hard),
          ],
        ),
      );
      expect(change.added, 3);
      expect(change.removed, 2);
      expect(change.changed, isTrue);
      expect(flags(change.deck), <(DifficultFlags, DifficultFlags)>[
        (noFlag, noFlag),
        (noFlag, autoFlag),
        (autoFlag, autoFlag),
        (noFlag, noFlag),
        (noFlag, autoFlag),
      ]);
    });

    test('never touches a manual flag, whatever the rule says', () {
      final LearningUnit mineStale = word('house', 'Haus', d1: bothFlags);
      final LearningUnit mineEasy = word('tree', 'Baum', d2: manualFlag);
      final LearningUnit mineHard = word('dog', 'Hund', d2: manualFlag);
      final LearningDeck deck = LearningDeck(
        mask: mask,
        units: <LearningUnit>[mineStale, mineEasy, mineHard],
      );
      final DifficultFlagChange change = recomputeDetectedDifficult(
        deck,
        AllTimeStatistics(
          perUnit: <UnitStats>[
            stats(1, mineStale, direction1: easy),
            stats(2, mineEasy, direction2: easy),
            stats(3, mineHard, direction2: hard),
          ],
        ),
      );
      expect(change.added, 1);
      expect(change.removed, 1);
      expect(flags(change.deck), <(DifficultFlags, DifficultFlags)>[
        (manualFlag, noFlag),
        (noFlag, manualFlag),
        (noFlag, bothFlags),
      ]);
    });

    test('a deck without statistics loses every automatic flag, counted per '
        'direction', () {
      final LearningUnit house = word(
        'house',
        'Haus',
        d1: autoFlag,
        d2: autoFlag,
      );
      final LearningUnit tree = word('tree', 'Baum', d1: bothFlags);
      final LearningDeck deck = LearningDeck(
        mask: mask,
        units: <LearningUnit>[house, tree],
      );
      final DifficultFlagChange change = recomputeDetectedDifficult(
        deck,
        AllTimeStatistics.empty,
      );
      expect(change.added, 0);
      expect(change.removed, 3);
      expect(flags(change.deck), <(DifficultFlags, DifficultFlags)>[
        (noFlag, noFlag),
        (manualFlag, noFlag),
      ]);
    });

    test('is not an edit, and nothing to change hands back the deck '
        'itself', () {
      final LocalTimestamp edited = LocalTimestamp.tryParse(
        '2026-09-25T16:32:11+02:00',
      )!;
      final LearningUnit house = word('house', 'Haus', d1: autoFlag);
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
      final LearningUnit house = word('house', 'Haus', d1: autoFlag);
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
      expect(flags(change.deck), <(DifficultFlags, DifficultFlags)>[
        (noFlag, noFlag),
      ]);
    });
  });

  group('clearing manual flags', () {
    test('clears every manual flag in both directions, keeps automatic ones, '
        'and counts flags', () {
      final LearningDeck deck = LearningDeck(
        mask: mask,
        units: <LearningUnit>[
          unit(d1: manualFlag, d2: manualFlag),
          unit(d1: bothFlags),
          unit(d2: autoFlag),
          unit(),
        ],
      );
      final DifficultFlagChange change = clearManualDifficult(deck);
      expect(change.removed, 3);
      expect(change.added, 0);
      expect(change.changed, isTrue);
      expect(flags(change.deck), <(DifficultFlags, DifficultFlags)>[
        (noFlag, noFlag),
        (autoFlag, noFlag),
        (noFlag, autoFlag),
        (noFlag, noFlag),
      ]);
    });

    test('is not an edit, and a deck without manual flags comes back as it '
        'is', () {
      final LocalTimestamp edited = LocalTimestamp.tryParse(
        '2026-09-25T16:32:11+02:00',
      )!;
      final LearningDeck flagged = LearningDeck(
        mask: mask,
        units: <LearningUnit>[unit(d2: manualFlag)],
        lastEdited: edited,
      );
      expect(clearManualDifficult(flagged).deck.lastEdited, edited);

      final LearningDeck clean = LearningDeck(
        mask: mask,
        units: <LearningUnit>[unit(d1: autoFlag, d2: autoFlag), unit()],
      );
      final DifficultFlagChange change = clearManualDifficult(clean);
      expect(change.removed, 0);
      expect(change.changed, isFalse);
      expect(change.deck, same(clean));
    });
  });

  group('difficult units only', () {
    // Units 1, 3 and 4 are difficult in Direction 1, each by a different
    // flag; unit 3 in Direction 2 too, and unit 5 only in Direction 2.
    // Unit 2 is not difficult at all.
    final LearningDeck deck = LearningDeck(
      mask: mask,
      units: <LearningUnit>[
        word('one', 'eins', d1: manualFlag),
        word('two', 'zwei'),
        word('three', 'drei', d1: autoFlag, d2: manualFlag),
        word('four', 'vier', d1: bothFlags),
        word('five', 'fünf', d2: autoFlag),
      ],
    );
    final LearningDeck noneFlagged = LearningDeck(
      mask: mask,
      units: <LearningUnit>[word('one', 'eins'), word('two', 'zwei')],
    );

    SessionParameters only(
      SessionMode mode, {
      DirectionSelection directions = DirectionSelection.direction1,
      int? start,
      int? end,
    }) {
      return SessionParameters(
        directionSelection: directions,
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

    /// [items] as "unit.direction" strings, in order.
    List<String> questionsOf(List<SessionItem> items) => <String>[
      for (final SessionItem item in items)
        '${item.unitIndex}.${item.direction.index + 1}',
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

    test('narrows the practice and once-through order to units difficult in '
        'the asked direction, within the unit range', () {
      for (final SessionMode mode in <SessionMode>[
        SessionMode.practice,
        SessionMode.onceThrough,
      ]) {
        expect(unitsOf(itemsInScope(deck, only(mode))), <int>[1, 3, 4]);
        expect(
          unitsOf(
            itemsInScope(
              deck,
              only(mode, directions: DirectionSelection.direction2),
            ),
          ),
          <int>[3, 5],
        );
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

    test('under Both each unit is asked only in the directions it is '
        'difficult in', () {
      for (final SessionMode mode in <SessionMode>[
        SessionMode.practice,
        SessionMode.onceThrough,
      ]) {
        expect(
          questionsOf(
            itemsInScope(
              deck,
              only(mode, directions: DirectionSelection.both),
            ),
          ),
          <String>['1.1', '3.1', '3.2', '4.1', '5.2'],
        );
      }
    });

    test('every question a practice draw serves is difficult in its '
        'direction', () {
      final Random random = Random(7);
      for (var draw = 0; draw < 50; draw += 1) {
        final SessionItem? item = pickPracticeItem(
          deck: deck,
          parameters: only(
            SessionMode.practice,
            directions: DirectionSelection.both,
          ),
          random: random,
        );
        expect(
          deck.units[item!.unitIndex - 1].isDifficultIn(item.direction),
          isTrue,
        );
      }
    });

    test('narrows the drill pool per question, and mastery still removes a '
        'difficult unit from it', () {
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
      // Both directions: a unit difficult only in Direction 1 is not asked
      // in Direction 2.
      expect(
        questionsOf(
          activeSuperQueryPool(
            deck: deck,
            statistics: const <UnitStats>[],
            parameters: only(
              SessionMode.superQuery,
              directions: DirectionSelection.both,
            ),
          ),
        ),
        <String>['1.1', '3.1', '3.2', '4.1', '5.2'],
      );
    });

    test('narrows the Level Learning pool per question, and level-0 mastery '
        'still removes a difficult unit from it', () {
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
      expect(
        questionsOf(
          activeLevelLearningPool(
            deck: deck,
            statistics: const <UnitStats>[],
            levelStatistics: levelStatistics,
            parameters: only(
              SessionMode.levelLearning,
              directions: DirectionSelection.both,
            ),
          ),
        ),
        <String>['1.1', '3.1', '3.2', '5.2'],
      );
    });

    test('a deck, a unit range or a direction without difficult units yields '
        'an empty pool in every mode', () {
      final LearningDeck direction1Only = LearningDeck(
        mask: mask,
        units: <LearningUnit>[word('one', 'eins', d1: bothFlags)],
      );
      for (final (
            LearningDeck subject,
            DirectionSelection directions,
            int? start,
            int? end,
          )
          in <(LearningDeck, DirectionSelection, int?, int?)>[
            (noneFlagged, DirectionSelection.direction1, null, null),
            (noneFlagged, DirectionSelection.both, null, null),
            (deck, DirectionSelection.direction1, 5, 5),
            (deck, DirectionSelection.both, 2, 2),
            (direction1Only, DirectionSelection.direction2, null, null),
          ]) {
        for (final SessionMode mode in SessionMode.values) {
          final SessionParameters parameters = only(
            mode,
            directions: directions,
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
    // Units 1, 3 and 4 are difficult, each by a different flag and unit 3
    // only in Direction 2; 2 and 5 are not. Every unit contains "e", so a
    // search for it matches them all.
    final LearningDeck deck = LearningDeck(
      mask: mask,
      units: <LearningUnit>[
        word('one', 'eins', d1: manualFlag),
        word('two', 'zwei'),
        word('three', 'drei', d2: autoFlag),
        word('four', 'vier', d1: manualFlag, d2: bothFlags),
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

    test('Difficult only keeps units difficult in either direction, ANDed '
        'with the search text', () {
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
          word('seven', 'sieben', d2: autoFlag),
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

    test('re-keying hits onto a reference mask keeps every flag in its '
        'direction', () {
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

      expect(flags(rekeyed), flags(hits));
    });
  });
}
