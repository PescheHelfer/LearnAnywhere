import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_desktop/src/file_operations/desktop_document.dart';
import 'package:learn_anywhere_desktop/src/file_operations/desktop_file_service.dart';

void main() {
  group('DesktopFileService', () {
    test('saves and opens decks with statistics sidecars', () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'learn_anywhere_file_ops',
      );
      final DesktopFileService service = const DesktopFileService();
      final String deckPath = '${temp.path}${Platform.pathSeparator}sample.vok';

      final LearningDeck deck = LearningDeck(
        mask: sampleMask(),
        units: const <LearningUnit>[
          LearningUnit(
            categoryId: 1,
            fields: <String, FieldValue>{'Question': FieldValue.plain('Q')},
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
      );

      final DesktopDocument saved = await service.saveDeck(
        document,
        path: deckPath,
      );
      expect(await File(deckPath).exists(), isTrue);
      expect(
        await File(service.statisticsSidecarPath(deckPath)).exists(),
        isTrue,
      );

      final DesktopDocument opened = await service.openDeck(saved, deckPath);
      expect(opened.deck.units, hasLength(1));
      expect(opened.statistics.single.direction1.correct, 1);

      await temp.delete(recursive: true);
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
          LearningUnit(categoryId: 1, fields: <String, FieldValue>{}),
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
            fields: <String, FieldValue>{'Question': FieldValue.plain('Q')},
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

      final DesktopDocument loaded = await service.loadStatistics(
        cleared,
        statsPath,
      );
      expect(loaded.statistics.single.direction1.correct, 2);

      await service.saveDeckSnapshot(deck, selectedPath);
      expect(
        decodeDeckJson(await File(selectedPath).readAsString()).units,
        hasLength(1),
      );

      await temp.delete(recursive: true);
    });

    test('loads decks matching a file mask pattern', () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'learn_anywhere_pattern_ops',
      );
      final DesktopFileService service = const DesktopFileService();
      final LearningDeck deck = LearningDeck(
        mask: sampleMask(),
        units: const <LearningUnit>[
          LearningUnit(
            categoryId: 1,
            fields: <String, FieldValue>{'Question': FieldValue.plain('Q')},
          ),
        ],
      );
      final String deckPath = '${temp.path}${Platform.pathSeparator}one.vok';
      final String ignoredPath = '${temp.path}${Platform.pathSeparator}one.txt';
      await File(deckPath).writeAsString(encodeDeckJson(deck));
      await File(ignoredPath).writeAsString('ignored');

      final Map<String, LearningDeck> loaded = await service.loadDecksByPattern(
        '${temp.path}${Platform.pathSeparator}*.vok',
      );

      expect(loaded.keys, contains(deckPath));
      expect(loaded[deckPath]!.units, hasLength(1));
      await temp.delete(recursive: true);
    });
  });
}

LearningMask sampleMask({String name = 'Sample'}) {
  return LearningMask(
    name: name,
    direction1Label: 'Direction 1',
    direction2Label: 'Direction 2',
    categories: const <CategoryDefinition>[
      CategoryDefinition(
        id: 1,
        name: 'Default',
        fields: <FieldDefinition>[
          FieldDefinition(
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
