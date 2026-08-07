import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_mobile/main.dart';
import 'package:learn_anywhere_mobile/src/mobile_file_service.dart';
import 'package:learn_anywhere_mobile/src/mobile_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    // Phone-sized surface, so overflow in the new setup/session/statistics
    // screens fails the test instead of going unnoticed on the wider default
    // test viewport.
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('library screen launches into empty state and imports a deck', (
    WidgetTester tester,
  ) async {
    await _setPhoneSurface(tester);
    final _FakeMobileFileService fileService = _FakeMobileFileService();

    await tester.pumpWidget(
      LearnAnywhereMobileApp(
        prefs: await _fakePrefs(),
        fileService: fileService,
      ),
    );
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

  testWidgets('deleting a deck removes it and its statistics', (
    WidgetTester tester,
  ) async {
    await _setPhoneSurface(tester);
    final _FakeMobileFileService fileService = _FakeMobileFileService()
      ..seedDeck('mobile_sample.vok', _deck(), statistics: const <UnitStats>[]);

    await tester.pumpWidget(
      LearnAnywhereMobileApp(
        prefs: await _fakePrefs(),
        fileService: fileService,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mobile sample'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('No decks yet'), findsOneWidget);
    expect(fileService.hasDeck('mobile_sample.vok'), isFalse);
  });

  testWidgets(
    're-importing a name collision replaces the deck and realigns statistics',
    (WidgetTester tester) async {
      await _setPhoneSurface(tester);
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
        LearnAnywhereMobileApp(
          prefs: await _fakePrefs(),
          fileService: fileService,
        ),
      );
      await tester.pumpAndSettle();

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
      expect(realigned, hasLength(2));
      final UnitStats keptStats = realigned[0];
      expect(keptStats.index, 1);
      expect(
        keptStats.direction1.attempts + keptStats.direction2.attempts,
        1,
      );
    },
  );

  testWidgets('setup applies the chosen range and direction to the session', (
    WidgetTester tester,
  ) async {
    await _setPhoneSurface(tester);
    final LearningDeck deck = _deck(
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
    final _FakeMobileFileService fileService = _FakeMobileFileService()
      ..seedDeck('mobile_sample.vok', deck, statistics: const <UnitStats>[]);

    await tester.pumpWidget(
      LearnAnywhereMobileApp(
        prefs: await _fakePrefs(),
        fileService: fileService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mobile sample'));
    await tester.pumpAndSettle();

    expect(find.text('Practice setup'), findsOneWidget);

    // Narrow the range to unit 2 only.
    await tester.enterText(find.widgetWithText(TextField, 'Start unit'), '2');
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'End unit'), '2');
    await tester.pumpAndSettle();

    // Narrow direction to "Forward" (direction1) for a deterministic prompt.
    await tester.tap(find.text('Both'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forward').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start session'));
    await tester.pumpAndSettle();

    // Unit 2 of the 2-unit deck, direction1 prompt is "goodbye".
    expect(find.textContaining('Unit 2/2'), findsOneWidget);
    expect(_hasAnyRichText(tester, <String>['goodbye']), isTrue);
  });

  testWidgets(
    'a full two-tap card records the rating and persists statistics',
    (WidgetTester tester) async {
      await _setPhoneSurface(tester);
      final _FakeMobileFileService fileService = _FakeMobileFileService()
        ..seedDeck('mobile_sample.vok', _deck());

      await tester.pumpWidget(
        LearnAnywhereMobileApp(
          prefs: await _fakePrefs(),
          fileService: fileService,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mobile sample'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start session'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Unit 1/1'), findsOneWidget);
      expect(_hasAnyRichText(tester, <String>['hello', 'bonjour']), isTrue);

      // Tap 1 of 2: reveal the solution.
      await tester.tap(find.text('Show answer'));
      await tester.pumpAndSettle();

      expect(find.text('Solution'), findsOneWidget);
      expect(find.text('Remarks'), findsOneWidget);
      expect(find.text('use greeting', findRichText: true), findsOneWidget);

      // Tap 2 of 2: rate, which also advances.
      await tester.tap(find.text('Knew it'));
      await tester.pumpAndSettle();

      final List<UnitStats> saved = fileService.savedStatistics(
        'mobile_sample.vok',
      );
      final UnitStats stats = saved.single;
      expect(stats.direction1.attempts + stats.direction2.attempts, 1);
      expect(stats.direction1.correct + stats.direction2.correct, 1);
    },
  );

  testWidgets('statistics screen renders totals and buckets, and clears', (
    WidgetTester tester,
  ) async {
    await _setPhoneSurface(tester);
    final LearningDeck deck = _deck();
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
        deck,
        statistics: withUnitHashes(deck, recorded),
      );

    await tester.pumpWidget(
      LearnAnywhereMobileApp(
        prefs: await _fakePrefs(),
        fileService: fileService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mobile sample'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Statistics'));
    await tester.pumpAndSettle();

    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('Total units: 1'), findsOneWidget);
    expect(find.text('Total Attempts: 1'), findsOneWidget);
    expect(find.text('Correct Attempts: 1'), findsOneWidget);
    expect(find.text('Perfect'), findsOneWidget);
    expect(find.text('Never known'), findsOneWidget);
    expect(find.text('Not yet practiced'), findsOneWidget);

    await tester.tap(find.text('Clear stats...'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Clear'));
    await tester.pumpAndSettle();

    expect(find.text('Total Attempts: 0'), findsOneWidget);
    final List<UnitStats> cleared = fileService.savedStatistics(
      'mobile_sample.vok',
    );
    expect(cleared.single.direction1.attempts, 0);
  });

  testWidgets('settings round-trip theme and guardrails through fake stores', (
    WidgetTester tester,
  ) async {
    // Taller than the phone-sized surface used elsewhere: the settings list
    // (5 theme options + 2 language options + 2 guardrail pairs) needs the
    // extra room so every control can be reached without scroll plumbing in
    // the test itself.
    await _setPhoneSurface(tester, const Size(360, 1400));
    final _FakeMobileFileService fileService = _FakeMobileFileService();
    final MobilePrefs prefs = await _fakePrefs();

    await tester.pumpWidget(
      LearnAnywhereMobileApp(prefs: prefs, fileService: fileService),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);

    // Theme applies and persists immediately through the (mocked)
    // shared_preferences store.
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(prefs.theme, 'dark');

    // Guardrails persist through the fake settings-file store. Checked before
    // the language switch below, which re-renders every label in German.
    await tester.tap(find.text('Minimum-attempts guard'));
    await tester.pumpAndSettle();
    expect(fileService.savedSettings.minimumAttemptsGuardEnabled, isTrue);

    await tester.enterText(
      find.widgetWithText(TextField, 'Minimum attempts'),
      '3',
    );
    await tester.pumpAndSettle();
    expect(fileService.savedSettings.minAttempts, 3);

    // Language likewise applies and persists immediately.
    await tester.tap(find.text('German'));
    await tester.pumpAndSettle();
    expect(prefs.locale, 'de');
    expect(find.text('Einstellungen'), findsOneWidget);
  });

  testWidgets(
    'a guardrail enabled in Settings applies to a session opened afterward',
    (WidgetTester tester) async {
      await _setPhoneSurface(tester);
      final _FakeMobileFileService fileService = _FakeMobileFileService()
        ..seedDeck('mobile_sample.vok', _deck());

      await tester.pumpWidget(
        LearnAnywhereMobileApp(
          prefs: await _fakePrefs(),
          fileService: fileService,
        ),
      );
      await tester.pumpAndSettle();

      // Turn the minimum-attempts guard on (default minAttempts stays 2),
      // then return to the library — MobileLibraryScreen is the app's
      // Navigator `home` route, built once and cached, so this only reaches
      // the setup screen below if it re-reads guardSettings live rather than
      // from a frozen constructor snapshot.
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Minimum-attempts guard'));
      await tester.pumpAndSettle();
      expect(fileService.savedSettings.minimumAttemptsGuardEnabled, isTrue);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mobile sample'));
      await tester.pumpAndSettle();
      // Narrow to one direction so the pool holds exactly one item: with
      // both directions in scope, the still-unqueried second item alone
      // would keep the pool non-empty regardless of the guard, masking the
      // very thing this test checks.
      await tester.tap(find.text('Both'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forward').last);
      await tester.pumpAndSettle();
      // Mode defaults to "Endless mode"; switch it to "Drill mode" so
      // mastery (and thus the guard) is what decides when the session ends.
      await tester.tap(find.text('Endless mode'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Drill mode'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start session'));
      await tester.pumpAndSettle();

      // One correct answer is short of the min-attempts guard (2), so a
      // 100% hit rate must not yet count as mastered: the sole item stays in
      // the pool and another card is served, not the completion view.
      await tester.tap(find.text('Show answer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Knew it'));
      await tester.pumpAndSettle();

      expect(find.text('Show answer'), findsOneWidget);
      expect(find.text('Extend session'), findsNothing);
    },
  );

  testWidgets('shuffle off presents units in deck order', (
    WidgetTester tester,
  ) async {
    await _setPhoneSurface(tester);
    final LearningDeck deck = _deck(
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
    final _FakeMobileFileService fileService = _FakeMobileFileService()
      ..seedDeck('mobile_sample.vok', deck, statistics: const <UnitStats>[]);

    await tester.pumpWidget(
      LearnAnywhereMobileApp(
        prefs: await _fakePrefs(),
        fileService: fileService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mobile sample'));
    await tester.pumpAndSettle();

    // Narrow direction to "Forward" so each unit contributes one item.
    await tester.tap(find.text('Both'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forward').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start session'));
    await tester.pumpAndSettle();

    // Deck order, shuffle off (the default): unit 1 ("hello"), then unit 2
    // ("goodbye"), then the endless pass wraps back to unit 1.
    expect(_hasAnyRichText(tester, <String>['hello']), isTrue);
    await tester.tap(find.text('Show answer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Knew it'));
    await tester.pumpAndSettle();

    expect(_hasAnyRichText(tester, <String>['goodbye']), isTrue);
    await tester.tap(find.text('Show answer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Knew it'));
    await tester.pumpAndSettle();

    expect(_hasAnyRichText(tester, <String>['hello']), isTrue);
  });
}

Future<void> _setPhoneSurface(WidgetTester tester, [Size size = const Size(360, 740)]) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<MobilePrefs> _fakePrefs() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  return MobilePrefs(await SharedPreferences.getInstance());
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

/// An in-memory stand-in for [MobileFileService]'s on-disk library and
/// settings file. Widget tests drive UI interaction against this fake; the
/// real file-based implementation is covered separately in
/// `mobile_file_service_test.dart`, which uses plain `test()` so real
/// dart:io `Future`s resolve normally — `testWidgets`'s fake-clock test
/// binding never drives them.
final class _FakeMobileFileService extends MobileFileService {
  final Map<String, LearningDeck> _decks = <String, LearningDeck>{};
  final Map<String, List<UnitStats>> _statistics = <String, List<UnitStats>>{};
  LearnAnywhereSettings _settings = const LearnAnywhereSettings();

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

  /// The guardrail settings most recently saved by the settings screen.
  LearnAnywhereSettings get savedSettings => _settings;

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

  @override
  Future<LearnAnywhereSettings> loadSettings() async => _settings;

  @override
  Future<void> saveSettings(LearnAnywhereSettings settings) async {
    _settings = settings;
  }
}
