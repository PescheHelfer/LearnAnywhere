import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_mobile/main.dart';
import 'package:learn_anywhere_mobile/src/mobile_file_service.dart';

void main() {
  testWidgets('library screen launches into empty state and imports a deck', (
    WidgetTester tester,
  ) async {
    final _FakeMobileFileService fileService = _FakeMobileFileService();

    await tester.pumpWidget(LearnAnywhereMobileApp(fileService: fileService));
    await tester.pumpAndSettle();

    expect(find.text('Library'), findsOneWidget);
    expect(find.text('No decks yet'), findsOneWidget);

    fileService.filesToImport = <MapEntry<String, LearningDeck>>[
      MapEntry<String, LearningDeck>('mobile_sample.vok', _deck()),
    ];

    await tester.tap(find.byTooltip('Import decks'));
    await tester.pumpAndSettle();

    expect(find.text('1 deck(s) imported.'), findsOneWidget);
    expect(find.text('Mobile sample'), findsOneWidget);
    expect(find.text('Units: 1'), findsOneWidget);
  });

  testWidgets(
    'opening a deck starts a session and persists statistics',
    (WidgetTester tester) async {
      final _FakeMobileFileService fileService = _FakeMobileFileService()
        ..seedDeck('mobile_sample.vok', _deck());

      await tester.pumpWidget(
        LearnAnywhereMobileApp(fileService: fileService),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mobile sample'));
      await tester.pumpAndSettle();

      expect(find.text('Units: 1'), findsOneWidget);

      await tester.tap(find.text('Start session'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Unit 1/1'), findsOneWidget);
      expect(find.text('Prompt'), findsOneWidget);
      expect(_hasAnyRichText(tester, <String>['hello', 'bonjour']), isTrue);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Solution'), findsOneWidget);
      expect(find.text('Remarks'), findsOneWidget);
      expect(find.text('use greeting', findRichText: true), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('How did it go?'), findsOneWidget);
      expect(find.text('No count'), findsOneWidget);

      await tester.tap(find.text('Knew it'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Accuracy: 100%'), findsOneWidget);

      final List<UnitStats> saved = fileService.savedStatistics(
        'mobile_sample.vok',
      );
      final UnitStats stats = saved.single;
      expect(stats.direction1.attempts + stats.direction2.attempts, 1);
      expect(stats.direction1.correct + stats.direction2.correct, 1);
    },
  );

  testWidgets(
    're-importing a name collision replaces the deck and realigns statistics',
    (WidgetTester tester) async {
      final LearningDeck original = _deck();
      final List<UnitStats> recorded = <UnitStats>[
        UnitStats(
          index: 1,
          direction1: recordAttempt(
            const DirectionStats(),
            AttemptRating.correct,
          ),
        ),
      ];
      final _FakeMobileFileService fileService = _FakeMobileFileService()
        ..seedDeck(
          'mobile_sample.vok',
          original,
          statistics: withUnitHashes(original, recorded),
        );

      await tester.pumpWidget(
        LearnAnywhereMobileApp(fileService: fileService),
      );
      await tester.pumpAndSettle();

      // Re-import under the same file name: the original unit (same
      // identity hash) plus one brand-new unit.
      final LearningDeck updated = _deck(
        extraUnits: const <LearningUnit>[
          LearningUnit(
            categoryId: 1,
            fields: <int, FieldValue>{
              0: PlainFieldValue('goodbye'),
              1: PlainFieldValue('au revoir'),
              2: PlainFieldValue('farewell'),
            },
          ),
        ],
      );
      fileService.filesToImport = <MapEntry<String, LearningDeck>>[
        MapEntry<String, LearningDeck>('mobile_sample.vok', updated),
      ];

      await tester.tap(find.byTooltip('Import decks'));
      await tester.pumpAndSettle();

      expect(find.text('Units: 2'), findsOneWidget);

      final List<UnitStats> realigned = fileService.savedStatistics(
        'mobile_sample.vok',
      );
      // realignStatistics returns one entry per deck unit: the matched unit
      // keeps its counters, the brand-new one starts clean.
      expect(realigned, hasLength(2));
      final UnitStats keptStats = realigned[0];
      expect(keptStats.index, 1);
      expect(
        keptStats.direction1.attempts + keptStats.direction2.attempts,
        1,
      );
    },
  );

  testWidgets('deleting a deck removes it and its statistics', (
    WidgetTester tester,
  ) async {
    final _FakeMobileFileService fileService = _FakeMobileFileService()
      ..seedDeck('mobile_sample.vok', _deck(), statistics: const <UnitStats>[]);

    await tester.pumpWidget(LearnAnywhereMobileApp(fileService: fileService));
    await tester.pumpAndSettle();

    expect(find.text('Mobile sample'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('No decks yet'), findsOneWidget);
    expect(fileService.hasDeck('mobile_sample.vok'), isFalse);
  });
}

bool _hasAnyRichText(WidgetTester tester, List<String> values) {
  return values.any(
    (String value) => tester.any(find.text(value, findRichText: true)),
  );
}

LearningDeck _deck({List<LearningUnit> extraUnits = const <LearningUnit>[]}) {
  return LearningDeck(
    mask: const LearningMask(
      maskId: 'm_new_mobile-fixture',
      name: 'Mobile sample',
      direction1Label: 'Forward',
      direction2Label: 'Backward',
      categories: <CategoryDefinition>[
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
            FieldDefinition(
              id: 2,
              name: 'Remark field',
              length: 40,
              equalGroup: 0,
              role1: FieldRole.remark,
              role2: FieldRole.remark,
            ),
          ],
        ),
      ],
    ),
    units: <LearningUnit>[
      const LearningUnit(
        categoryId: 1,
        fields: <int, FieldValue>{
          0: PlainFieldValue('hello'), // Prompt field
          1: PlainFieldValue('bonjour'), // Answer field
          2: PlainFieldValue('use greeting'), // Remark field
        },
      ),
      ...extraUnits,
    ],
  );
}

/// An in-memory stand-in for [MobileFileService]'s on-disk library.
///
/// Widget tests drive UI interaction (import, open, delete, status
/// messages) against this fake; the real file-based implementation is
/// covered separately in `mobile_file_service_test.dart`, which uses plain
/// `test()` so real dart:io `Future`s resolve normally — `testWidgets`'s
/// fake-clock binding never drives them.
final class _FakeMobileFileService extends MobileFileService {
  final Map<String, LearningDeck> _decks = <String, LearningDeck>{};
  final Map<String, List<UnitStats>> _statistics = <String, List<UnitStats>>{};

  /// Files the next [importDecks] call "picks", keyed by library file name.
  List<MapEntry<String, LearningDeck>> filesToImport =
      const <MapEntry<String, LearningDeck>>[];

  void seedDeck(
    String path,
    LearningDeck deck, {
    List<UnitStats>? statistics,
  }) {
    _decks[path] = deck;
    if (statistics != null) {
      _statistics[path] = statistics;
    }
  }

  bool hasDeck(String path) => _decks.containsKey(path);

  List<UnitStats> savedStatistics(String path) =>
      _statistics[path] ?? const <UnitStats>[];

  @override
  Future<List<LibraryDeckEntry>> listDecks() async {
    final List<LibraryDeckEntry> entries = _decks.entries
        .map(
          (MapEntry<String, LearningDeck> entry) => LibraryDeckEntry(
            path: entry.key,
            name: entry.value.mask.name,
            unitCount: entry.value.units.length,
          ),
        )
        .toList();
    entries.sort(
      (LibraryDeckEntry a, LibraryDeckEntry b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return entries;
  }

  @override
  Future<MobileDeckDocument> openDeck(String path) async {
    final LearningDeck deck = _decks[path]!;
    final List<UnitStats> stored = _statistics[path] ?? clearStatistics(deck);
    return MobileDeckDocument(
      deck: deck,
      deckPath: path,
      statistics: realignStatistics(deck: deck, statistics: stored).statistics,
    );
  }

  @override
  Future<int> importDecks() async {
    for (final MapEntry<String, LearningDeck> file in filesToImport) {
      final List<UnitStats>? existing = _statistics[file.key];
      if (existing != null) {
        _statistics[file.key] = realignStatistics(
          deck: file.value,
          statistics: existing,
        ).statistics;
      }
      _decks[file.key] = file.value;
    }
    return filesToImport.length;
  }

  @override
  Future<void> deleteDeck(String path) async {
    _decks.remove(path);
    _statistics.remove(path);
  }

  @override
  Future<void> saveStatistics(
    MobileDeckDocument document,
    List<UnitStats> statistics,
  ) async {
    final String? path = document.deckPath;
    if (path == null) {
      return;
    }
    _statistics[path] = withUnitHashes(document.deck, statistics);
  }
}
