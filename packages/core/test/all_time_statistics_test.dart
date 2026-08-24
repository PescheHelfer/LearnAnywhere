import 'package:learn_anywhere_core/core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// The lifetime record: its file marker, the rule that it may only ever be
/// incremented by exactly what the working record took, and the realignment
/// that keeps a unit's history through a typo fix.
void main() {
  group('StatisticsScope marker', () {
    test('an all-time file carries the marker and decodes back as all-time',
        () {
      const StatisticsFile file = StatisticsFile(
        deckRef: 'french.vok',
        scope: StatisticsScope.allTime,
        perUnit: <UnitStats>[
          UnitStats(index: 1, direction1: DirectionStats(attempts: 9, correct: 7)),
        ],
      );
      final Map<String, Object?> json = encodeStatistics(file);
      expect(json['scope'], 'allTime');
      // Additive at the current version: the marker does not bump it, so a
      // build predating the marker still loads the file.
      expect(json['version'], currentStatisticsVersion);

      final StatisticsFile decoded = decodeStatisticsJson(
        encodeStatisticsJson(file),
      );
      expect(decoded.scope, StatisticsScope.allTime);
      expect(decoded.perUnit.single.direction1.attempts, 9);
    });

    test('a working file writes no marker at all', () {
      const StatisticsFile file = StatisticsFile(
        deckRef: 'french.vok',
        perUnit: <UnitStats>[UnitStats(index: 1)],
      );
      expect(encodeStatistics(file).containsKey('scope'), isFalse);
      expect(
        decodeStatisticsJson(encodeStatisticsJson(file)).scope,
        StatisticsScope.session,
      );
    });

    test('a file without the marker decodes as the working record, so every '
        'file written before now keeps its meaning', () {
      final Map<String, Object?> legacy = <String, Object?>{
        'format': statisticsFormat,
        'version': 1,
        'deckRef': 'french.vok',
        'perUnit': <Object?>[
          <String, Object?>{
            'index': 1,
            'dir1': <String, Object?>{'attempts': 3, 'correct': 2},
            'dir2': <String, Object?>{'attempts': 0, 'correct': 0},
          },
        ],
      };
      expect(decodeStatistics(legacy).scope, StatisticsScope.session);
    });

    test('an unrecognised marker value means the working record, not a failed '
        'load', () {
      final Map<String, Object?> json = encodeStatistics(
        const StatisticsFile(deckRef: 'french.vok', perUnit: <UnitStats>[]),
      )..['scope'] = 'somethingElse';
      expect(decodeStatistics(json).scope, StatisticsScope.session);
    });
  });

  group('AllTimeStatistics.record', () {
    test('a counted attempt increments the lifetime record once, by exactly '
        'what the working record took', () {
      const DirectionStats before = DirectionStats(attempts: 2, correct: 1);
      final DirectionStats after = recordAttempt(
        before,
        AttemptRating.correct,
      );
      expect(after, const DirectionStats(attempts: 3, correct: 2));

      const AllTimeStatistics lifetime = AllTimeStatistics(
        perUnit: <UnitStats>[
          UnitStats(index: 1, direction1: DirectionStats(attempts: 40, correct: 25)),
        ],
      );
      final AllTimeStatistics updated = lifetime.record(
        RecordedAttempt(
          unitIndex: 1,
          direction: QueryDirection.direction1,
          drill: AttemptDelta.between(before, after),
        ),
      );
      expect(
        updated.perUnit.single.direction1,
        const DirectionStats(attempts: 41, correct: 26),
      );
      // The other direction and the original record are untouched.
      expect(updated.perUnit.single.direction2, const DirectionStats());
      expect(lifetime.perUnit.single.direction1.attempts, 40);
    });

    test('a unit with no lifetime entry yet gets one, in index order', () {
      final AllTimeStatistics updated = AllTimeStatistics.empty
          .record(
            const RecordedAttempt(
              unitIndex: 3,
              direction: QueryDirection.direction2,
              drill: AttemptDelta(attempts: 1, correct: 1),
            ),
          )
          .record(
            const RecordedAttempt(
              unitIndex: 1,
              direction: QueryDirection.direction1,
              drill: AttemptDelta(attempts: 1),
            ),
          );
      expect(
        updated.perUnit.map((UnitStats stats) => stats.index),
        <int>[1, 3],
      );
      expect(updated.perUnit.last.direction2.correct, 1);
    });

    test('an attempt suppressed by the wrong-answer ceiling is skipped in '
        'BOTH records', () {
      const WrongAnswerCeiling ceiling = WrongAnswerCeiling(
        enabled: true,
        value: 5,
      );
      // Already at the ceiling: five wrong out of five.
      const DirectionStats before = DirectionStats(attempts: 5);
      final DirectionStats after = recordAttempt(
        before,
        AttemptRating.wrong,
        wrongAnswerCeiling: ceiling,
      );
      expect(after, before, reason: 'the working record suppressed it');

      const AllTimeStatistics lifetime = AllTimeStatistics(
        perUnit: <UnitStats>[
          UnitStats(index: 1, direction1: DirectionStats(attempts: 5)),
        ],
      );
      // The lifetime wrongs are nowhere near a ceiling of their own, and that
      // is the point: re-deciding it here would freeze the record forever once
      // a unit passed the working ceiling.
      final AllTimeStatistics updated = lifetime.record(
        RecordedAttempt(
          unitIndex: 1,
          direction: QueryDirection.direction1,
          drill: AttemptDelta.between(before, after),
        ),
      );
      expect(updated.perUnit.single.direction1, const DirectionStats(attempts: 5));
    });

    test('a "no count" rating is a no-op in both records', () {
      const DirectionStats before = DirectionStats(attempts: 4, correct: 3);
      expect(recordAttempt(before, AttemptRating.noCount), before);

      const AllTimeStatistics lifetime = AllTimeStatistics(
        perUnit: <UnitStats>[
          UnitStats(index: 1, direction1: DirectionStats(attempts: 9, correct: 6)),
        ],
      );
      final AllTimeStatistics updated = lifetime.record(
        RecordedAttempt(
          unitIndex: 1,
          direction: QueryDirection.direction1,
          drill: AttemptDelta.between(
            before,
            recordAttempt(before, AttemptRating.noCount),
          ),
          level: kFreeRecallLevel,
          reachedLevel: kFreeRecallLevel,
        ),
      );
      expect(identical(updated.perUnit, lifetime.perUnit), isTrue);
      expect(updated.perLevel, isEmpty);
    });

    test('Level-Learning attempts accumulate into the lifetime per-level '
        'counters and carry the level last reached', () {
      const SessionParameters parameters = SessionParameters(
        mode: SessionMode.levelLearning,
      );
      // A working ladder entry sitting at level 2 with nothing recorded there.
      final LevelDirectionStats before = LevelDirectionStats.fresh(2);
      final LevelDirectionStats after = recordLevelLearningAttempt(
        before,
        AttemptRating.correct,
        parameters: parameters,
      );
      // One correct answer at level 2 promotes to level 1.
      expect(after.currentLevel, 1);

      // The lifetime record already holds work done at level 2 weeks ago and
      // last stood at level 3 after a fresh start.
      final AllTimeStatistics lifetime = AllTimeStatistics(
        perLevel: <LevelUnitStats>[
          LevelUnitStats(
            index: 1,
            dir1: LevelDirectionStats.fresh(kMaxSupportLevel)
                .withLevelStats(2, const DirectionStats(attempts: 6, correct: 4)),
            dir2: LevelDirectionStats.fresh(kMaxSupportLevel),
          ),
        ],
      );
      final AllTimeStatistics updated = lifetime.record(
        RecordedAttempt(
          unitIndex: 1,
          direction: QueryDirection.direction1,
          level: 2,
          levelDelta: AttemptDelta.between(
            before.currentLevelStats,
            after.levels[2]!,
          ),
          reachedLevel: after.currentLevel,
        ),
      );
      final LevelDirectionStats lifetimeDir1 = updated.perLevel.single.dir1;
      expect(
        lifetimeDir1.levels[2],
        const DirectionStats(attempts: 7, correct: 5),
        reason: 'ladder work done weeks apart adds up',
      );
      // The level is a state, not a counter: the record keeps the one most
      // recently reached, which the all-time view reads as "Last level".
      expect(lifetimeDir1.currentLevel, 1);
      // The drill section stays empty — this answer was not free recall.
      expect(updated.perUnit, isEmpty);
    });

    test('a free-recall Level-Learning answer reaches both lifetime sections',
        () {
      const AllTimeStatistics lifetime = AllTimeStatistics();
      final AllTimeStatistics updated = lifetime.record(
        const RecordedAttempt(
          unitIndex: 2,
          direction: QueryDirection.direction1,
          drill: AttemptDelta(attempts: 1, correct: 1),
          level: kFreeRecallLevel,
          levelDelta: AttemptDelta(attempts: 1, correct: 1),
          reachedLevel: kFreeRecallLevel,
        ),
      );
      expect(
        updated.perUnit.single.direction1,
        const DirectionStats(attempts: 1, correct: 1),
      );
      expect(
        updated.perLevel.single.dir1.levels[kFreeRecallLevel],
        const DirectionStats(attempts: 1, correct: 1),
      );
    });

    test('a free-recall answer the ceiling suppressed still records on the '
        'ladder, where no ceiling applies', () {
      final AllTimeStatistics updated = AllTimeStatistics.empty.record(
        const RecordedAttempt(
          unitIndex: 1,
          direction: QueryDirection.direction1,
          level: kFreeRecallLevel,
          levelDelta: AttemptDelta(attempts: 1),
          reachedLevel: kFreeRecallLevel,
        ),
      );
      expect(updated.perUnit, isEmpty);
      expect(
        updated.perLevel.single.dir1.levels[kFreeRecallLevel],
        const DirectionStats(attempts: 1),
      );
    });
  });

  group('realignAllTimeStatistics', () {
    /// A three-unit deck; [terms] replaces the question text unit by unit.
    LearningDeck deckOf(List<String> terms) {
      return LearningDeck(
        mask: _mask,
        units: <LearningUnit>[
          for (final String term in terms)
            LearningUnit(
              categoryId: 0,
              fields: <int, FieldValue>{
                0: FieldValue.plain(term),
                1: FieldValue.plain('answer-$term'),
              },
            ),
        ],
      );
    }

    /// The lifetime record as it would come off disk for [deck]: one hashed
    /// entry per unit, each carrying [attempts] attempts in direction 1.
    AllTimeStatistics recordFor(LearningDeck deck, List<int> attempts) {
      final List<String> hashes = deckUnitHashes(deck);
      return AllTimeStatistics(
        perUnit: <UnitStats>[
          for (var i = 0; i < attempts.length; i += 1)
            UnitStats(
              index: i + 1,
              direction1: DirectionStats(attempts: attempts[i], correct: attempts[i]),
              hash: hashes[i],
            ),
        ],
        perLevel: <LevelUnitStats>[
          for (var i = 0; i < attempts.length; i += 1)
            LevelUnitStats(
              index: i + 1,
              dir1: LevelDirectionStats.fresh(kMaxSupportLevel)
                  .withLevelStats(3, DirectionStats(attempts: attempts[i])),
              dir2: LevelDirectionStats.fresh(kMaxSupportLevel),
            ),
        ],
      );
    }

    test('a unit that moved takes its lifetime counters with it', () {
      final LearningDeck before = deckOf(<String>['eins', 'zwei', 'drei']);
      final AllTimeStatistics record = recordFor(before, <int>[10, 20, 30]);
      // The learner reorders the deck: drei, eins, zwei.
      final LearningDeck after = deckOf(<String>['drei', 'eins', 'zwei']);

      final AllTimeStatistics realigned = realignAllTimeStatistics(
        deck: after,
        allTime: record,
      );
      expect(
        realigned.perUnit
            .map((UnitStats stats) => stats.direction1.attempts)
            .toList(),
        <int>[30, 10, 20],
      );
      expect(
        realigned.perLevel
            .map((LevelUnitStats stats) => stats.dir1.levels[3]!.attempts)
            .toList(),
        <int>[30, 10, 20],
      );
      // Every entry is re-pointed at the unit that now sits there.
      expect(
        realigned.perUnit.map((UnitStats stats) => stats.hash).toList(),
        deckUnitHashes(after),
      );
    });

    test('a unit whose text changed KEEPS its lifetime counters — unlike the '
        'working record, which resets it', () {
      final LearningDeck before = deckOf(<String>['eins', 'zwei', 'drei']);
      final AllTimeStatistics record = recordFor(before, <int>[10, 20, 30]);
      // A typo fix on unit 2: a different unit as far as identity goes.
      final LearningDeck after = deckOf(<String>['eins', 'zwei!', 'drei']);

      final AllTimeStatistics realigned = realignAllTimeStatistics(
        deck: after,
        allTime: record,
      );
      expect(
        realigned.perUnit
            .map((UnitStats stats) => stats.direction1.attempts)
            .toList(),
        <int>[10, 20, 30],
      );
      expect(realigned.perUnit[1].hash, deckUnitHashes(after)[1]);
      expect(
        realigned.perLevel
            .map((LevelUnitStats stats) => stats.dir1.levels[3]!.attempts)
            .toList(),
        <int>[10, 20, 30],
      );

      // The working record still resets that unit, and says so.
      final StatisticsRealignment working = realignStatistics(
        deck: after,
        statistics: record.perUnit,
        levelStatistics: record.perLevel,
      );
      expect(working.statistics[1].direction1.attempts, 0);
      expect(working.resetUnits, 1);
    });

    test('a unit deleted from the deck drops out of the record with its '
        'counters', () {
      final LearningDeck before = deckOf(<String>['eins', 'zwei', 'drei']);
      final AllTimeStatistics record = recordFor(before, <int>[10, 20, 30]);
      final LearningDeck after = deckOf(<String>['eins', 'drei']);

      final AllTimeStatistics realigned = realignAllTimeStatistics(
        deck: after,
        allTime: record,
      );
      expect(
        realigned.perUnit
            .map((UnitStats stats) => stats.direction1.attempts)
            .toList(),
        <int>[10, 30],
      );
      expect(realigned.perLevel, hasLength(2));
      expect(realigned.perLevel.last.dir1.levels[3]!.attempts, 30);
    });

    test('a unit inserted mid-deck starts empty and shifts nothing off', () {
      final LearningDeck before = deckOf(<String>['eins', 'zwei', 'drei']);
      final AllTimeStatistics record = recordFor(before, <int>[10, 20, 30]);
      final LearningDeck after = deckOf(
        <String>['eins', 'neu', 'zwei', 'drei'],
      );

      final AllTimeStatistics realigned = realignAllTimeStatistics(
        deck: after,
        allTime: record,
      );
      expect(
        realigned.perUnit
            .map((UnitStats stats) => stats.direction1.attempts)
            .toList(),
        <int>[10, 0, 20, 30],
      );
    });

    test('a unit answered only above free recall keeps its ladder history, '
        'even though it has no drill counters to travel with', () {
      final LearningDeck before = deckOf(<String>['eins', 'zwei', 'drei']);
      final List<String> hashes = deckUnitHashes(before);
      // Unit 1 was drilled; unit 3 has only ever been answered at level 3, so
      // the record says nothing about it in the drill section.
      final AllTimeStatistics record = AllTimeStatistics(
        perUnit: <UnitStats>[
          UnitStats(
            index: 1,
            direction1: const DirectionStats(attempts: 10, correct: 9),
            hash: hashes[0],
          ),
        ],
        perLevel: <LevelUnitStats>[
          LevelUnitStats(
            index: 3,
            dir1: LevelDirectionStats.fresh(kMaxSupportLevel)
                .withLevelStats(3, const DirectionStats(attempts: 4, correct: 3)),
            dir2: LevelDirectionStats.fresh(kMaxSupportLevel),
          ),
        ],
      );

      final AllTimeStatistics realigned = realignAllTimeStatistics(
        deck: before,
        allTime: record,
      );
      expect(realigned.perLevel, hasLength(1));
      expect(realigned.perLevel.single.index, 3);
      expect(
        realigned.perLevel.single.dir1.levels[3],
        const DirectionStats(attempts: 4, correct: 3),
      );
      expect(realigned.perUnit.first.direction1.attempts, 10);
    });

    test('a record carrying no hashes is realigned positionally', () {
      final LearningDeck deck = deckOf(<String>['eins', 'zwei']);
      const AllTimeStatistics record = AllTimeStatistics(
        perUnit: <UnitStats>[
          UnitStats(index: 1, direction1: DirectionStats(attempts: 4)),
          UnitStats(index: 2, direction1: DirectionStats(attempts: 5)),
          UnitStats(index: 3, direction1: DirectionStats(attempts: 6)),
        ],
      );
      final AllTimeStatistics realigned = realignAllTimeStatistics(
        deck: deck,
        allTime: record,
      );
      expect(
        realigned.perUnit
            .map((UnitStats stats) => stats.direction1.attempts)
            .toList(),
        <int>[4, 5],
      );
      expect(realigned.perUnit.first.hash, deckUnitHashes(deck).first);
    });
  });

  group('AllTimeStatistics editor shifts', () {
    test('an insert shifts later lifetime counters up a slot', () {
      const AllTimeStatistics record = AllTimeStatistics(
        perUnit: <UnitStats>[
          UnitStats(index: 1, direction1: DirectionStats(attempts: 10)),
          UnitStats(index: 2, direction1: DirectionStats(attempts: 20)),
        ],
      );
      final AllTimeStatistics shifted = record.afterInsert(2, 3);
      expect(
        shifted.perUnit
            .map((UnitStats stats) => stats.direction1.attempts)
            .toList(),
        <int>[10, 0, 20],
      );
    });

    test('a delete drops that unit and pulls the rest down', () {
      const AllTimeStatistics record = AllTimeStatistics(
        perUnit: <UnitStats>[
          UnitStats(index: 1, direction1: DirectionStats(attempts: 10)),
          UnitStats(index: 2, direction1: DirectionStats(attempts: 20)),
          UnitStats(index: 3, direction1: DirectionStats(attempts: 30)),
        ],
      );
      final AllTimeStatistics shifted = record.afterDelete(2, 2);
      expect(
        shifted.perUnit
            .map((UnitStats stats) => stats.direction1.attempts)
            .toList(),
        <int>[10, 30],
      );
    });
  });

  group('AllTimeRecord write authority', () {
    test('a record read from a file speaks for that file and for no other', () {
      const AllTimeRecord read = AllTimeRecord.loaded(
        AllTimeStatistics(
          perUnit: <UnitStats>[
            UnitStats(index: 1, direction1: DirectionStats(attempts: 900)),
          ],
        ),
        '/decks/french.vok',
      );
      expect(read.speaksFor('/decks/french.vok', context: p.posix), isTrue);
      expect(read.speaksFor('/decks/german.vok', context: p.posix), isFalse);
      expect(read.isUnreadable, isFalse);
    });

    test('a missing lifetime file still speaks for its deck path: creating a '
        'file destroys nothing', () {
      const AllTimeRecord absent = AllTimeRecord.absent('/decks/french.vok');
      expect(absent.isEmpty, isTrue);
      expect(absent.isUnreadable, isFalse);
      expect(absent.speaksFor('/decks/french.vok', context: p.posix), isTrue);
    });

    test('a file that could not be read speaks for nothing at all, and stays '
        'that way once the learner answers', () {
      const AllTimeRecord unreadable = AllTimeRecord.unreadable(
        '/decks/french.vok',
      );
      expect(unreadable.isUnreadable, isTrue);
      expect(
        unreadable.speaksFor('/decks/french.vok', context: p.posix),
        isFalse,
      );

      // One answer later the record is no longer empty -- and still not
      // entitled to replace the file it never read.
      final AllTimeRecord answered = unreadable.record(
        const RecordedAttempt(
          unitIndex: 1,
          direction: QueryDirection.direction1,
          drill: AttemptDelta(attempts: 1, correct: 1),
        ),
      );
      expect(answered.isEmpty, isFalse);
      expect(answered.perUnit.single.direction1.attempts, 1);
      expect(answered.origin, AllTimeOrigin.unreadable);
      expect(answered.speaksFor('/decks/french.vok', context: p.posix), isFalse);
    });

    test('a deck-shape change re-indexes a never-read record dense without '
        'granting it any authority', () {
      const AllTimeRecord unread = AllTimeRecord.unread;
      for (final AllTimeRecord reshaped in <AllTimeRecord>[
        unread.resized(3),
        unread.afterInsert(1, 3),
        unread.afterDelete(1, 3),
      ]) {
        // Dense, so an emptiness test would call it "something has happened"...
        expect(reshaped.perUnit, hasLength(3));
        expect(reshaped.isEmpty, isFalse);
        // ...but nothing was read, so it speaks for no file.
        expect(reshaped.origin, AllTimeOrigin.unread);
        expect(reshaped.speaksFor('/decks/french.vok', context: p.posix),
            isFalse);
      }
    });

    test('re-indexing a record that WAS read keeps its authority', () {
      const AllTimeRecord read = AllTimeRecord.loaded(
        AllTimeStatistics(
          perUnit: <UnitStats>[
            UnitStats(index: 1, direction1: DirectionStats(attempts: 12)),
          ],
        ),
        '/decks/french.vok',
      );
      final AllTimeRecord merged = read.resized(2);
      expect(
        merged.perUnit.map((UnitStats stats) => stats.direction1.attempts),
        <int>[12, 0],
      );
      expect(merged.speaksFor('/decks/french.vok', context: p.posix), isTrue);
    });

    test('a write that landed makes the record speak for the file it wrote',
        () {
      final AllTimeRecord adopted = AllTimeRecord.unread.adoptedAt(
        '/decks/french.vok',
      );
      expect(adopted.origin, AllTimeOrigin.loaded);
      expect(adopted.speaksFor('/decks/french.vok', context: p.posix), isTrue);
    });

    test('clearing empties the counters and keeps the authority', () {
      final AllTimeRecord read = AllTimeRecord.loaded(
        AllTimeStatistics(
          perUnit: const <UnitStats>[
            UnitStats(index: 1, direction1: DirectionStats(attempts: 12)),
          ],
          perLevel: <LevelUnitStats>[
            LevelUnitStats(
              index: 1,
              dir1: LevelDirectionStats.fresh(kFreeRecallLevel),
              dir2: LevelDirectionStats.fresh(kFreeRecallLevel),
            ),
          ],
        ),
        '/decks/french.vok',
      );

      final AllTimeRecord cleared = read.cleared();
      expect(cleared.isEmpty, isTrue);
      expect(cleared.perUnit, isEmpty);
      expect(cleared.perLevel, isEmpty);
      // The identity survives, so the answers given after the clear reach the
      // same file rather than piling up in memory.
      expect(cleared.speaksFor('/decks/french.vok', context: p.posix), isTrue);

      final AllTimeRecord again = cleared.record(
        const RecordedAttempt(
          unitIndex: 1,
          direction: QueryDirection.direction1,
          drill: AttemptDelta(attempts: 1, correct: 1),
        ),
      );
      expect(again.perUnit.single.direction1.attempts, 1);
      expect(again.speaksFor('/decks/french.vok', context: p.posix), isTrue);
    });

    test('clearing a record that read nothing gains it no authority', () {
      final AllTimeRecord cleared = AllTimeRecord.unread.cleared();
      expect(cleared.origin, AllTimeOrigin.unread);
      expect(cleared.speaksFor('/decks/french.vok', context: p.posix), isFalse);
    });

    test('paths are compared by the host rules, on either host', () {
      const AllTimeRecord windows = AllTimeRecord.absent(r'C:\Decks\French.vok');
      // Windows: separators and case are both immaterial.
      expect(
        windows.speaksFor(r'C:/Decks/french.vok', context: p.windows),
        isTrue,
      );

      const AllTimeRecord posix = AllTimeRecord.absent('/decks/french.vok');
      // POSIX: case is part of the name, so a different case is a different
      // deck and its file is protected.
      expect(posix.speaksFor('/decks/French.vok', context: p.posix), isFalse);
      expect(posix.speaksFor('/decks/./french.vok', context: p.posix), isTrue);
    });
  });
}

const LearningMask _mask = LearningMask(
  maskId: 'm_new_all-time-fixture',
  name: 'Fixture',
  direction1Label: 'A',
  direction2Label: 'B',
  categories: <CategoryDefinition>[
    CategoryDefinition(
      id: 0,
      name: 'Cat',
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
