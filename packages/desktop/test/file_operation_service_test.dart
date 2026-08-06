import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_desktop/src/file_operations/desktop_document.dart';
import 'package:learn_anywhere_desktop/src/file_operations/desktop_file_service.dart';

void main() {
  group('DesktopFileService', () {
    test('saveDeck auto-saves stats to the active target; openDeck clears '
        'stats without auto-loading', () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'learn_anywhere_file_ops',
      );
      final DesktopFileService service = const DesktopFileService();
      final String deckPath = '${temp.path}${Platform.pathSeparator}sample.vok';
      final String targetPath = service.timestampedStatisticsPath(
        deckPath,
        DateTime(2026, 7, 21, 14, 30, 0),
      );

      final LearningDeck deck = LearningDeck(
        mask: sampleMask(),
        units: const <LearningUnit>[
          LearningUnit(
            categoryId: 1,
            fields: <int, FieldValue>{0: FieldValue.plain('Q')}, // Question
          ),
        ],
      );
      final DesktopDocument document = DesktopDocument(
        deck: deck,
        statistics: const <UnitStats>[
          UnitStats(
            index: 1,
            direction1: DirectionStats(attempts: 1, correct: 1),
          ),
        ],
        // A live auto-save target is what drives the pre-switch/deck-save write.
        autoSaveTargetPath: targetPath,
        autoLoadStatistics: true,
        autoSaveStatistics: true,
      );

      final DesktopDocument saved = await service.saveDeck(
        document,
        path: deckPath,
      );
      expect(await File(deckPath).exists(), isTrue);
      // Stats went to the timestamped target, not a derived sidecar.
      expect(await File(targetPath).exists(), isTrue);

      // Opening clears stats and adopts no target: the app layer drives the
      // "load these?" auto-load prompt separately.
      final DesktopDocument opened = await service.openDeck(saved, deckPath);
      expect(opened.deck.units, hasLength(1));
      expect(opened.statistics.single.direction1.attempts, 0);
      expect(opened.statisticsPath, isNull);
      expect(opened.autoSaveTargetPath, isNull);

      await temp.delete(recursive: true);
    });

    test('builds timestamped statistics names in the deck folder', () {
      final DesktopFileService service = const DesktopFileService();
      final String sep = Platform.pathSeparator;
      final String path = service.timestampedStatisticsPath(
        '${Directory.current.path}${sep}french.vok',
        DateTime(2026, 1, 9, 8, 5, 3),
      );
      expect(
        path,
        '${Directory.current.path}${sep}french_20260109_080503.sta',
      );
    });

    test('finds timestamped statistics newest-first, ignoring other files',
        () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'learn_anywhere_stats_glob',
      );
      final DesktopFileService service = const DesktopFileService();
      final String sep = Platform.pathSeparator;
      final String deckPath = '${temp.path}${sep}french.vok';

      final String older = '${temp.path}${sep}french_20260101_090000.sta';
      final String newer = '${temp.path}${sep}french_20260721_143000.sta';
      // A plain sidecar and a different deck's session file must be ignored.
      final String sidecar = '${temp.path}${sep}french.sta';
      final String otherDeck = '${temp.path}${sep}german_20260721_143000.sta';
      for (final String p in <String>[older, newer, sidecar, otherDeck]) {
        await File(p).writeAsString('{}');
      }

      final List<TimestampedStatistics> found =
          await service.findTimestampedStatistics(deckPath);

      expect(
        found.map((TimestampedStatistics e) => e.path),
        <String>[newer, older],
      );
      expect(found.first.timestamp, DateTime(2026, 7, 21, 14, 30, 0));
      await temp.delete(recursive: true);
    });

    test('prunes timestamped statistics beyond the keep count, oldest first',
        () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'learn_anywhere_stats_prune',
      );
      final DesktopFileService service = const DesktopFileService();
      final String sep = Platform.pathSeparator;
      final String deckPath = '${temp.path}${sep}french.vok';

      final List<String> paths = <String>[
        '${temp.path}${sep}french_20260101_090000.sta',
        '${temp.path}${sep}french_20260102_090000.sta',
        '${temp.path}${sep}french_20260103_090000.sta',
        '${temp.path}${sep}french_20260104_090000.sta',
      ];
      for (final String p in paths) {
        await File(p).writeAsString('{}');
      }

      await service.pruneTimestampedStatistics(deckPath, keep: 2);

      final List<TimestampedStatistics> remaining =
          await service.findTimestampedStatistics(deckPath);
      expect(
        remaining.map((TimestampedStatistics e) => e.path).toSet(),
        <String>{paths[3], paths[2]},
      );
      await temp.delete(recursive: true);
    });

    test('keep == 0 disables pruning', () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'learn_anywhere_stats_prune_off',
      );
      final DesktopFileService service = const DesktopFileService();
      final String sep = Platform.pathSeparator;
      final String deckPath = '${temp.path}${sep}french.vok';

      final List<String> paths = <String>[
        '${temp.path}${sep}french_20260101_090000.sta',
        '${temp.path}${sep}french_20260102_090000.sta',
      ];
      for (final String p in paths) {
        await File(p).writeAsString('{}');
      }

      await service.pruneTimestampedStatistics(deckPath, keep: 0);

      final List<TimestampedStatistics> remaining =
          await service.findTimestampedStatistics(deckPath);
      expect(remaining, hasLength(2));
      await temp.delete(recursive: true);
    });

    test('never prunes the protected (active auto-save target) path',
        () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'learn_anywhere_stats_prune_protect',
      );
      final DesktopFileService service = const DesktopFileService();
      final String sep = Platform.pathSeparator;
      final String deckPath = '${temp.path}${sep}french.vok';

      // The active target is the OLDEST file — without protection it would
      // be the first one pruned by a keep:1 run.
      final String activeButOld = '${temp.path}${sep}french_20260101_090000.sta';
      final String newer = '${temp.path}${sep}french_20260102_090000.sta';
      for (final String p in <String>[activeButOld, newer]) {
        await File(p).writeAsString('{}');
      }

      await service.pruneTimestampedStatistics(
        deckPath,
        keep: 1,
        protectPath: activeButOld,
      );

      final List<TimestampedStatistics> remaining =
          await service.findTimestampedStatistics(deckPath);
      expect(
        remaining.map((TimestampedStatistics e) => e.path).toSet(),
        <String>{activeButOld, newer},
      );
      await temp.delete(recursive: true);
    });

    test('summarizes x-of-y queried coverage for a loaded stats file', () {
      final DesktopFileService service = const DesktopFileService();
      const StatisticsFile file = StatisticsFile(
        deckRef: 'deck.vok',
        perUnit: <UnitStats>[
          UnitStats(index: 1, direction1: DirectionStats(attempts: 2, correct: 1)),
          UnitStats(index: 3, direction1: DirectionStats(attempts: 1, correct: 1)),
        ],
      );

      final StatisticsCoverage coverage = service.statisticsCoverage(file, 4);
      expect(coverage.totalUnits, 4);
      expect(coverage.queriedUnits, 2);
    });

    test('loads masks by clearing units and keeping the new schema', () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'learn_anywhere_mask_ops',
      );
      final DesktopFileService service = const DesktopFileService();
      final String maskPath = '${temp.path}${Platform.pathSeparator}mask.inf';
      await File(
        maskPath,
      ).writeAsString(encodeMaskJson(sampleMask(name: 'Loaded')));

      final DesktopDocument loaded = await service.loadMask(
        DesktopDocument.empty(sampleMask()),
        maskPath,
      );

      expect(loaded.mask.name, 'Loaded');
      expect(loaded.deck.units, isEmpty);

      await temp.delete(recursive: true);
    });

    test('merges decks with matching masks only', () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'learn_anywhere_merge_ops',
      );
      final DesktopFileService service = const DesktopFileService();
      final String incomingPath =
          '${temp.path}${Platform.pathSeparator}incoming.vok';
      final LearningDeck incoming = LearningDeck(
        mask: sampleMask(),
        units: const <LearningUnit>[
          LearningUnit(categoryId: 1, fields: <int, FieldValue>{}),
        ],
      );
      await File(incomingPath).writeAsString(encodeDeckJson(incoming));

      final DesktopDocument merged = await service.mergeDeck(
        DesktopDocument.empty(sampleMask()),
        incomingPath,
      );

      expect(merged.deck.units, hasLength(1));
      await temp.delete(recursive: true);
    });

    test('loads saves clears and exports statistics-related files', () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'learn_anywhere_stats_ops',
      );
      final DesktopFileService service = const DesktopFileService();
      final String statsPath = '${temp.path}${Platform.pathSeparator}deck.sta';
      final String selectedPath =
          '${temp.path}${Platform.pathSeparator}selected.vok';
      final LearningDeck deck = LearningDeck(
        mask: sampleMask(),
        units: const <LearningUnit>[
          LearningUnit(
            categoryId: 1,
            fields: <int, FieldValue>{0: FieldValue.plain('Q')}, // Question
          ),
        ],
      );
      final DesktopDocument document = DesktopDocument(
        deck: deck,
        statistics: const <UnitStats>[
          UnitStats(
            index: 1,
            direction1: DirectionStats(attempts: 3, correct: 2),
          ),
        ],
      );

      final DesktopDocument saved = await service.saveStatistics(
        document,
        statsPath,
      );
      expect(await File(statsPath).exists(), isTrue);
      expect(saved.statisticsPath, statsPath);

      final DesktopDocument cleared = service.clearStatisticsInMemory(saved);
      expect(cleared.statistics.single.direction1.attempts, 0);

      final StatisticsLoadResult loaded = await service.loadStatistics(
        cleared,
        statsPath,
      );
      expect(loaded.document.statistics.single.direction1.correct, 2);
      expect(loaded.resetUnits, 0);

      await service.saveDeckSnapshot(deck, selectedPath);
      expect(
        decodeDeckJson(await File(selectedPath).readAsString()).units,
        hasLength(1),
      );

      await temp.delete(recursive: true);
    });

    test('round-trips lastSessionMode and drops it when stats are cleared', () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'learn_anywhere_stats_mode',
      );
      final DesktopFileService service = const DesktopFileService();
      final String statsPath = '${temp.path}${Platform.pathSeparator}deck.sta';
      final LearningDeck deck = LearningDeck(
        mask: sampleMask(),
        units: const <LearningUnit>[
          LearningUnit(
            categoryId: 1,
            fields: <int, FieldValue>{0: FieldValue.plain('Q')}, // Question
          ),
        ],
      );
      final DesktopDocument document = DesktopDocument(
        deck: deck,
        statistics: const <UnitStats>[
          UnitStats(
            index: 1,
            direction1: DirectionStats(attempts: 1, correct: 1),
          ),
        ],
        levelStatistics: const <LevelUnitStats>[
          LevelUnitStats(
            index: 1,
            dir1: LevelDirectionStats(
              currentLevel: 0,
              levels: <int, DirectionStats>{
                0: DirectionStats(attempts: 1, correct: 1),
              },
            ),
            dir2: LevelDirectionStats(
              currentLevel: 3,
              levels: <int, DirectionStats>{3: DirectionStats()},
            ),
          ),
        ],
        lastSessionMode: SessionMode.levelLearning,
      );

      await service.saveStatistics(document, statsPath);
      final DesktopDocument reloaded = (await service.loadStatistics(
        DesktopDocument(deck: deck, statistics: clearStatistics(deck)),
        statsPath,
      )).document;
      expect(reloaded.lastSessionMode, SessionMode.levelLearning);
      expect(reloaded.levelStatistics, hasLength(1));

      // "Start fresh" wipes both stores, so there is no recording mode left.
      final DesktopDocument cleared = service.clearStatisticsInMemory(reloaded);
      expect(cleared.lastSessionMode, isNull);
      expect(cleared.levelStatistics, isEmpty);
      expect(cleared.statistics.single.direction1.attempts, 0);

      // A file written before the field existed loads as "unknown".
      final DesktopDocument legacy = (await service.loadStatistics(
        DesktopDocument(deck: deck, statistics: clearStatistics(deck)),
        statsPath,
      )).document;
      await File(statsPath).writeAsString(
        encodeStatisticsJson(
          StatisticsFile(deckRef: 'deck.vok', perUnit: legacy.statistics),
        ),
      );
      final DesktopDocument unknown = (await service.loadStatistics(
        legacy,
        statsPath,
      )).document;
      expect(unknown.lastSessionMode, isNull);

      await temp.delete(recursive: true);
    });

    test('realigns loaded statistics onto a deck edited outside the app', () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'learn_anywhere_stats_realign',
      );
      final DesktopFileService service = const DesktopFileService();
      final String statsPath = '${temp.path}${Platform.pathSeparator}deck.sta';
      LearningUnit unit(String question) => LearningUnit(
        categoryId: 1,
        fields: <int, FieldValue>{0: FieldValue.plain(question)},
      );
      final LearningDeck deck = LearningDeck(
        mask: sampleMask(),
        units: <LearningUnit>[unit('one'), unit('two'), unit('three')],
      );

      await service.saveStatistics(
        DesktopDocument(
          deck: deck,
          statistics: const <UnitStats>[
            UnitStats(index: 1, direction1: DirectionStats(attempts: 1, correct: 1)),
            UnitStats(index: 2, direction1: DirectionStats(attempts: 2, correct: 2)),
            UnitStats(index: 3, direction1: DirectionStats(attempts: 3, correct: 3)),
          ],
        ),
        statsPath,
      );

      // The deck comes back reordered, with unit "two" rewritten and a new one
      // appended — exactly what a re-import or an outside edit looks like.
      final LearningDeck edited = LearningDeck(
        mask: sampleMask(),
        units: <LearningUnit>[
          unit('three'),
          unit('two!'),
          unit('one'),
          unit('four'),
        ],
      );
      final StatisticsLoadResult loaded = await service.loadStatistics(
        DesktopDocument(deck: edited, statistics: clearStatistics(edited)),
        statsPath,
      );

      expect(
        loaded.document.statistics.map((UnitStats s) => s.direction1.attempts),
        <int>[3, 0, 1, 0],
      );
      expect(loaded.resetUnits, 1);

      // With no deck open there is nothing the counters could belong to, and
      // nothing changed — loading must not claim units were reset.
      final LearningDeck none = LearningDeck(
        mask: sampleMask(),
        units: const <LearningUnit>[],
      );
      final StatisticsLoadResult withoutDeck = await service.loadStatistics(
        DesktopDocument(deck: none, statistics: clearStatistics(none)),
        statsPath,
      );
      expect(withoutDeck.resetUnits, 0);

      await temp.delete(recursive: true);
    });

    test('recursively loads .vok decks under a folder', () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'learn_anywhere_folder_search',
      );
      final DesktopFileService service = const DesktopFileService();
      final String sep = Platform.pathSeparator;
      final LearningDeck deck = LearningDeck(
        mask: sampleMask(),
        units: const <LearningUnit>[
          LearningUnit(
            categoryId: 1,
            fields: <int, FieldValue>{0: FieldValue.plain('Q')}, // Question
          ),
        ],
      );
      final String topPath = '${temp.path}${sep}one.vok';
      final Directory sub = Directory('${temp.path}${sep}nested');
      await sub.create();
      final String nestedPath = '${sub.path}${sep}two.vok';
      final String ignoredPath = '${temp.path}${sep}one.txt';
      await File(topPath).writeAsString(encodeDeckJson(deck));
      await File(nestedPath).writeAsString(encodeDeckJson(deck));
      await File(ignoredPath).writeAsString('ignored');

      final Map<String, LearningDeck> loaded = await service.loadDecksInFolder(
        temp.path,
      );

      // Both the top-level and the nested .vok are found; the .txt is skipped.
      expect(loaded.keys, contains(topPath));
      expect(loaded.keys, contains(nestedPath));
      expect(loaded.keys, isNot(contains(ignoredPath)));
      expect(loaded, hasLength(2));
      await temp.delete(recursive: true);
    });

    test('reports a missing folder for a file search', () async {
      final DesktopFileService service = const DesktopFileService();
      final String missing =
          '${Directory.systemTemp.path}${Platform.pathSeparator}la_no_such_dir_xyz';
      await expectLater(
        service.loadDecksInFolder(missing),
        throwsA(isA<FileOperationException>()),
      );
    });

    test('resolves the linked .inf for a deck by matching maskId', () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'learn_anywhere_linked_mask',
      );
      final DesktopFileService service = const DesktopFileService();
      final String sep = Platform.pathSeparator;
      final String deckPath = '${temp.path}${sep}french.vok';

      // A sibling .inf with the SAME maskId is the link; a decoy with a
      // different maskId in the same directory must be ignored.
      await service.saveMask(sampleMask(), '${temp.path}${sep}french.inf');
      await File(
        '${temp.path}${sep}other.inf',
      ).writeAsString(encodeMaskJson(sampleMask().copyWith(maskId: 'm_new_x')));

      final String? linked = await service.findLinkedMaskPath(
        deckPath,
        'm_new_fileop-fixture',
      );
      expect(linked, '${temp.path}${sep}french.inf');

      final String? none = await service.findLinkedMaskPath(
        deckPath,
        'm_new_absent',
      );
      expect(none, isNull);
      await temp.delete(recursive: true);
    });

    test('creates a linked .inf reusing the mask id, never minting', () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'learn_anywhere_create_mask',
      );
      final DesktopFileService service = const DesktopFileService();
      final String deckPath =
          '${temp.path}${Platform.pathSeparator}french.vok';

      final LearningMask embedded = sampleMask();
      final String infPath = await service.createLinkedMask(deckPath, embedded);

      expect(infPath, endsWith('french.inf'));
      final LearningMask reloaded = await service.readMask(infPath);
      // The created file REUSES the embedded maskId (identity is preserved).
      expect(reloaded.maskId, embedded.maskId);
      // And it is now resolvable as the deck's link.
      expect(
        await service.findLinkedMaskPath(deckPath, embedded.maskId),
        infPath,
      );
      await temp.delete(recursive: true);
    });

    test('createLinkedMask does not clobber an unrelated existing .inf', () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'learn_anywhere_create_mask_collision',
      );
      final DesktopFileService service = const DesktopFileService();
      final String sep = Platform.pathSeparator;
      final String deckPath = '${temp.path}${sep}french.vok';
      final String collidingPath = '${temp.path}${sep}french.inf';

      // An unrelated .inf already sits at the exact path this deck's link
      // would conventionally use.
      final LearningMask unrelated = sampleMask(
        name: 'Unrelated',
      ).copyWith(maskId: 'm_new_unrelated');
      await service.saveMask(unrelated, collidingPath);

      final LearningMask embedded = sampleMask();
      final String infPath = await service.createLinkedMask(deckPath, embedded);

      expect(infPath, isNot(collidingPath));
      expect(infPath, endsWith('french_2.inf'));
      // The unrelated file survives untouched.
      final LearningMask stillUnrelated = await service.readMask(
        collidingPath,
      );
      expect(stillUnrelated.maskId, 'm_new_unrelated');
      expect(stillUnrelated.name, 'Unrelated');
      // The new file was created with the expected content instead.
      final LearningMask created = await service.readMask(infPath);
      expect(created.maskId, embedded.maskId);
      await temp.delete(recursive: true);
    });

    test('plans and applies tier-1 propagation to sibling decks', () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'learn_anywhere_propagation',
      );
      final DesktopFileService service = const DesktopFileService();
      final String sep = Platform.pathSeparator;
      final String okPath = '${temp.path}${sep}short.vok';
      final String breakPath = '${temp.path}${sep}long.vok';

      // Two decks share the fixture maskId. "short" holds a 1-char value;
      // "long" holds a 6-char value in field id 0.
      await service.saveDeckSnapshot(
        LearningDeck(
          mask: sampleMask(),
          units: const <LearningUnit>[
            LearningUnit(categoryId: 1, fields: <int, FieldValue>{0: FieldValue.plain('Q')}),
          ],
        ),
        okPath,
      );
      await service.saveDeckSnapshot(
        LearningDeck(
          mask: sampleMask(),
          units: const <LearningUnit>[
            LearningUnit(
              categoryId: 1,
              fields: <int, FieldValue>{0: FieldValue.plain('sixchr')},
            ),
          ],
        ),
        breakPath,
      );

      // New mask shrinks field id 0 from 40 to 3: "short" is fine, "long" breaks.
      final LearningMask shrunk = _withFirstFieldLength(sampleMask(), 3);
      final MaskPropagationPlan plan = await service.planMaskPropagation(
        maskDirectory: temp.path,
        newMask: shrunk,
      );
      expect(plan.compatible, <String>[okPath]);
      expect(plan.breaking, hasLength(1));
      expect(plan.breaking.single.deckPath, breakPath);

      // Auto-apply to the compatible deck only.
      await service.applyMaskPropagation(
        newMask: shrunk,
        deckPaths: plan.compatible,
      );
      final LearningDeck updatedOk = decodeDeckJson(
        await File(okPath).readAsString(),
      );
      expect(updatedOk.mask.categories.single.fields.single.length, 3);
      expect(updatedOk.units.single.valueForFieldId(0).plainText, 'Q');
      // The breaking deck was left untouched (still length 40).
      final LearningDeck untouched = decodeDeckJson(
        await File(breakPath).readAsString(),
      );
      expect(untouched.mask.categories.single.fields.single.length, 40);

      // Forcing applies to the breaking deck too, truncating its data.
      await service.applyMaskPropagation(
        newMask: shrunk,
        deckPaths: <String>[breakPath],
      );
      final LearningDeck forced = decodeDeckJson(
        await File(breakPath).readAsString(),
      );
      expect(forced.mask.categories.single.fields.single.length, 3);
      expect(forced.units.single.valueForFieldId(0).plainText, 'six');
      await temp.delete(recursive: true);
    });

    test('planMaskPropagation excludes the currently open deck', () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'learn_anywhere_exclude_open',
      );
      final DesktopFileService service = const DesktopFileService();
      final String sep = Platform.pathSeparator;
      final String openPath = '${temp.path}${sep}open.vok';
      final String siblingPath = '${temp.path}${sep}sibling.vok';
      final LearningDeck deck = LearningDeck(
        mask: sampleMask(),
        units: const <LearningUnit>[
          LearningUnit(
            categoryId: 1,
            fields: <int, FieldValue>{0: FieldValue.plain('Q')},
          ),
        ],
      );
      await service.saveDeckSnapshot(deck, openPath);
      await service.saveDeckSnapshot(deck, siblingPath);

      final MaskPropagationPlan plan = await service.planMaskPropagation(
        maskDirectory: temp.path,
        newMask: sampleMask(),
        excludePaths: <String>[openPath],
      );

      // Only the sibling appears; the excluded "currently open" deck's
      // on-disk copy is left for the app layer to handle separately.
      expect(plan.compatible, <String>[siblingPath]);
      await temp.delete(recursive: true);
    });

    test('scans cross-directory copies and classifies each status', () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'learn_anywhere_sync',
      );
      final DesktopFileService service = const DesktopFileService();
      final String sep = Platform.pathSeparator;
      final Directory nested = Directory('${temp.path}${sep}sub');
      await nested.create();

      // Reference: field length 60, revision 3.
      final LearningMask reference = _withFirstFieldLength(
        sampleMask(),
        60,
      ).copyWith(revision: 3);

      final String identicalPath = '${temp.path}${sep}identical.inf';
      final String olderPath = '${nested.path}${sep}older.inf';
      final String sameRevPath = '${temp.path}${sep}samerev.inf';
      final String okDeckPath = '${nested.path}${sep}ok.vok';
      final String breakDeckPath = '${temp.path}${sep}break.vok';
      final String foreignPath = '${temp.path}${sep}foreign.inf';

      await service.saveMask(reference, identicalPath);
      await service.saveMask(
        _withFirstFieldLength(sampleMask(), 40).copyWith(revision: 1),
        olderPath,
      );
      await service.saveMask(
        _withFirstFieldLength(sampleMask(), 40).copyWith(revision: 3),
        sameRevPath,
      );
      await service.saveDeckSnapshot(
        LearningDeck(
          mask: _withFirstFieldLength(
            sampleMask(name: 'Ok Deck Mask'),
            40,
          ).copyWith(revision: 1),
          units: const <LearningUnit>[
            LearningUnit(categoryId: 1, fields: <int, FieldValue>{0: FieldValue.plain('Q')}),
          ],
        ),
        okDeckPath,
      );
      await service.saveDeckSnapshot(
        LearningDeck(
          mask: _withFirstFieldLength(sampleMask(), 80).copyWith(revision: 1),
          units: <LearningUnit>[
            LearningUnit(
              categoryId: 1,
              fields: <int, FieldValue>{0: FieldValue.plain('x' * 70)},
            ),
          ],
        ),
        breakDeckPath,
      );
      await service.saveMask(sampleMask().copyWith(maskId: 'm_new_other'), foreignPath);

      final List<MaskSyncEntry> entries = await service.scanMaskCopies(
        root: temp.path,
        reference: reference,
      );
      final Map<String, MaskSyncStatus> byPath = <String, MaskSyncStatus>{
        for (final MaskSyncEntry e in entries) e.path: e.status,
      };

      // The foreign-maskId file is not a copy and must not appear.
      expect(byPath.containsKey(foreignPath), isFalse);
      expect(byPath[identicalPath], MaskSyncStatus.upToDate);
      expect(byPath[olderPath], MaskSyncStatus.willUpdate);
      expect(byPath[sameRevPath], MaskSyncStatus.differs);
      expect(byPath[okDeckPath], MaskSyncStatus.willUpdate);
      expect(byPath[breakDeckPath], MaskSyncStatus.wouldBreak);

      // Each entry carries the copy's OWN mask name, not the reference's, so
      // the review dialog can distinguish differently-named copies.
      final Map<String, String> maskNameByPath = <String, String>{
        for (final MaskSyncEntry e in entries) e.path: e.maskName,
      };
      expect(maskNameByPath[identicalPath], reference.name);
      expect(maskNameByPath[okDeckPath], 'Ok Deck Mask');

      // Apply only the updatable (willUpdate) copies.
      final List<String> updatable = entries
          .where((MaskSyncEntry e) => e.isUpdatable)
          .map((MaskSyncEntry e) => e.path)
          .toList();
      await service.applyMaskSync(reference: reference, paths: updatable);

      // The older .inf now matches the reference exactly.
      expect(
        encodeMaskJson(await service.readMask(olderPath)),
        encodeMaskJson(reference),
      );
      // The ok deck adopted the reference mask (length 60), units intact.
      final LearningDeck syncedDeck = decodeDeckJson(
        await File(okDeckPath).readAsString(),
      );
      expect(syncedDeck.mask.categories.single.fields.single.length, 60);
      expect(syncedDeck.mask.revision, 3);
      expect(syncedDeck.units.single.valueForFieldId(0).plainText, 'Q');
      // The breaking deck and same-revision divergent copy were untouched.
      expect(
        decodeDeckJson(
          await File(breakDeckPath).readAsString(),
        ).mask.categories.single.fields.single.length,
        80,
      );
      expect((await service.readMask(sameRevPath)).revision, 3);
      await temp.delete(recursive: true);
    });

    test(
      'classifies a copy ahead of the reference as newer, never updatable',
      () async {
        final Directory temp = await Directory.systemTemp.createTemp(
          'learn_anywhere_sync_newer',
        );
        final DesktopFileService service = const DesktopFileService();
        final String sep = Platform.pathSeparator;

        // A stale reference (revision 1) must not be able to downgrade a
        // copy that has already moved on to revision 2 — this is the bug
        // that let an un-reconciled open deck's embedded mask (see
        // [_reconcileLinkedMask] in main.dart) overwrite a newer `.inf`.
        final LearningMask staleReference = sampleMask().copyWith(revision: 1);
        final LearningMask newerCopy = _withFirstFieldLength(
          sampleMask(),
          80,
        ).copyWith(revision: 2);

        final String newerMaskPath = '${temp.path}${sep}newer.inf';
        final String newerDeckPath = '${temp.path}${sep}newer.vok';
        await service.saveMask(newerCopy, newerMaskPath);
        await service.saveDeckSnapshot(
          LearningDeck(mask: newerCopy, units: const <LearningUnit>[]),
          newerDeckPath,
        );

        final List<MaskSyncEntry> entries = await service.scanMaskCopies(
          root: temp.path,
          reference: staleReference,
        );
        final Map<String, MaskSyncEntry> byPath = <String, MaskSyncEntry>{
          for (final MaskSyncEntry e in entries) e.path: e,
        };

        expect(byPath[newerMaskPath]!.status, MaskSyncStatus.newer);
        expect(byPath[newerMaskPath]!.isUpdatable, isFalse);
        expect(byPath[newerDeckPath]!.status, MaskSyncStatus.newer);
        expect(byPath[newerDeckPath]!.isUpdatable, isFalse);

        // Confirm the guard actually prevents a downgrade: even if somehow
        // selected, applyMaskSync itself would overwrite — the real
        // protection is that isUpdatable is false, so the app never offers
        // the checkbox. Verify the files are unchanged by a scan-only run.
        expect((await service.readMask(newerMaskPath)).revision, 2);
        await temp.delete(recursive: true);
      },
    );
  });
}

LearningMask _withFirstFieldLength(LearningMask mask, int length) {
  final CategoryDefinition category = mask.categories.single;
  final FieldDefinition field = category.fields.single;
  return mask.copyWith(
    categories: <CategoryDefinition>[
      CategoryDefinition(
        id: category.id,
        name: category.name,
        fields: <FieldDefinition>[
          FieldDefinition(
            id: field.id,
            name: field.name,
            length: length,
            equalGroup: field.equalGroup,
            role1: field.role1,
            role2: field.role2,
          ),
        ],
      ),
    ],
  );
}

LearningMask sampleMask({String name = 'Sample'}) {
  return LearningMask(
    maskId: 'm_new_fileop-fixture',
    name: name,
    direction1Label: 'Direction 1',
    direction2Label: 'Direction 2',
    categories: const <CategoryDefinition>[
      CategoryDefinition(
        id: 1,
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
        ],
      ),
    ],
  );
}
