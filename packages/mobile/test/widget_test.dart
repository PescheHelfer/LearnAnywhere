import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_mobile/main.dart';
import 'package:learn_anywhere_mobile/src/mobile_app_version.dart';
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

    // Direction 1 ("Forward") is the first-run default — a fresh session asks
    // one direction, not both — so the prompt is deterministic already.
    expect(find.text('Forward'), findsOneWidget);

    await tester.tap(find.text('Start session'));
    await tester.pumpAndSettle();

    // Unit 2 of the 2-unit deck, direction1 prompt is "goodbye".
    expect(find.textContaining('Unit 2/2'), findsOneWidget);
    expect(_hasAnyRichText(tester, <String>['goodbye']), isTrue);
  });

  testWidgets('the direction dropdown still switches to direction 2', (
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

    await tester.tap(find.text('Mobile sample'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Forward'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Backward').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start session'));
    await tester.pumpAndSettle();

    // Direction 2 asks the answer field and expects the prompt field back.
    expect(_hasAnyRichText(tester, <String>['bonjour']), isTrue);
  });

  testWidgets('a unit-range field can be cleared and retyped from the front', (
    WidgetTester tester,
  ) async {
    await _setPhoneSurface(tester);
    final LearningDeck deck = _deck(
      extraUnits: <LearningUnit>[
        for (int i = 0; i < 44; i++)
          LearningUnit(
            categoryId: 1,
            fields: <int, FieldValue>{
              0: PlainFieldValue('prompt $i'),
              1: PlainFieldValue('answer $i'),
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

    final Finder endUnit = find.widgetWithText(TextField, 'End unit');
    expect(_textOf(tester, endUnit), '45');

    // Clearing the field must leave it empty rather than snapping back to the
    // minimum — that refill was what made the leading digit undeletable.
    await tester.enterText(endUnit, '');
    await tester.pumpAndSettle();
    expect(_textOf(tester, endUnit), isEmpty);

    await tester.enterText(endUnit, '12');
    await tester.pumpAndSettle();
    expect(_textOf(tester, endUnit), '12');

    await tester.tap(find.text('Start session'));
    await tester.pumpAndSettle();

    expect(find.textContaining('/45'), findsOneWidget);
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

      // Twice: the field-group title and the question/answer toggle segment.
      expect(find.text('Solution'), findsNWidgets(2));
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

  testWidgets(
    'the accuracy chip is a deck total that matches the statistics screen',
    (WidgetTester tester) async {
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
      final List<UnitStats> recorded = <UnitStats>[
        UnitStats(
          index: 1,
          direction1: recordAttempt(
            const DirectionStats(),
            AttemptRating.correct,
          ),
        ),
        UnitStats(
          index: 2,
          direction1: recordAttempt(const DirectionStats(), AttemptRating.wrong),
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

      // Both directions, so the deck total (not just direction 1) is on
      // screen: 1 correct out of 2 attempts recorded above.
      await tester.tap(find.text('Forward'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Both').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start session'));
      await tester.pumpAndSettle();

      expect(find.text('Accuracy: 1/2 (50%)'), findsOneWidget);

      // Rating updates the figure immediately, because it is read from the
      // statistics after every save rather than held in a per-sitting
      // counter — whichever item was drawn, the deck total gains one
      // attempt and one correct.
      await tester.tap(find.text('Show answer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Knew it'));
      await tester.pumpAndSettle();

      expect(find.text('Accuracy: 2/3 (67%)'), findsOneWidget);

      // Leaving the session for the statistics screen shows the same figure.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Statistics'));
      await tester.pumpAndSettle();

      expect(find.text('Accuracy: 67%'), findsOneWidget);
    },
  );

  testWidgets(
    'the reveal screen can switch back to the question and stays rateable',
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

      await tester.tap(find.text('Show answer'));
      await tester.pumpAndSettle();
      expect(_hasAnyRichText(tester, <String>['bonjour']), isTrue);

      // Switch to the question — the rating buttons stay put and enabled.
      await tester.tap(find.text('Prompt'));
      await tester.pumpAndSettle();
      expect(_hasAnyRichText(tester, <String>['hello']), isTrue);
      expect(find.text('Knew it'), findsOneWidget);
      final FilledButton knewIt = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Knew it'),
      );
      expect(knewIt.onPressed, isNotNull);

      // Switch back to the answer, as often as wanted.
      await tester.tap(find.text('Solution').first);
      await tester.pumpAndSettle();
      expect(_hasAnyRichText(tester, <String>['bonjour']), isTrue);

      // Rating from the toggled-back answer view still advances normally,
      // and the next card always starts on the question again. No count, so
      // a single-unit deck's only item stays in the pool instead of being
      // mastered by this tap and ending the session.
      await tester.tap(find.text('No count'));
      await tester.pumpAndSettle();
      expect(find.text('Show answer'), findsOneWidget);
    },
  );

  testWidgets(
    'the question panel is top-anchored and fills the card width for a '
    'short prompt and a long one alike',
    (WidgetTester tester) async {
      await _setPhoneSurface(tester);
      final LearningDeck deck = LearningDeck(
        mask: _deck().mask,
        units: const <LearningUnit>[
          LearningUnit(
            categoryId: 1,
            fields: <int, FieldValue>{
              0: PlainFieldValue('hi'),
              1: PlainFieldValue('bonjour'),
            },
          ),
          LearningUnit(
            categoryId: 1,
            fields: <int, FieldValue>{
              0: PlainFieldValue(
                'a noticeably longer question that still fits on the card',
              ),
              1: PlainFieldValue('au revoir'),
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

      // Deterministic order: Once through, shuffle off.
      await tester.tap(find.text('Drill mode'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Once through').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Shuffle units'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start session'));
      await tester.pumpAndSettle();

      expect(_hasAnyRichText(tester, <String>['hi']), isTrue);
      final Finder panel = find.byWidgetPredicate(
        (Widget widget) => widget.runtimeType.toString() == '_FieldGroup',
      );
      final Rect shortRect = tester.getRect(panel);

      await tester.tap(find.text('Show answer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No count'));
      await tester.pumpAndSettle();

      expect(
        _hasAnyRichText(tester, <String>[
          'a noticeably longer question that still fits on the card',
        ]),
        isTrue,
      );
      final Rect longRect = tester.getRect(panel);

      // Anchored at the top (not vertically centred) and filling the full
      // card width regardless of content length, so consecutive cards do
      // not change shape.
      expect(longRect.top, shortRect.top);
      expect(longRect.width, shortRect.width);
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

    await _openFromOverflow(tester, 'Settings');

    expect(find.text('Settings'), findsOneWidget);

    // Section headings come from catalog entries that carry desktop's `&`
    // menu-mnemonic marker; a phone must never show it.
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.textContaining('&'), findsNothing);

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

    // German labels reach the screen as real umlauts, not as the "fÃ¼r"
    // double-encoding. Asserted on the rendered widget and again on the code
    // unit, so a UTF-8-as-Latin-1 slip anywhere between the catalog and the
    // screen shows up here rather than on a phone.
    const String ceiling = 'Grenze für falsche Antworten';
    expect(ceiling.codeUnitAt(8), 0x00FC); // LATIN SMALL LETTER U WITH DIAERESIS
    expect(find.text(ceiling), findsOneWidget);

    // The German headings are marked up too (&Darstellung, &Sprache).
    expect(find.text('Darstellung'), findsOneWidget);
    expect(find.text('Sprache'), findsOneWidget);
    expect(find.textContaining('&'), findsNothing);
  });

  testWidgets('the overflow menu opens only the Android guide chapter', (
    WidgetTester tester,
  ) async {
    await _setPhoneSurface(tester);

    await tester.pumpWidget(
      LearnAnywhereMobileApp(
        prefs: await _fakePrefs(),
        fileService: _FakeMobileFileService(),
      ),
    );
    await tester.pumpAndSettle();

    await _openFromOverflow(tester, 'User guide');

    // Reading a chapter is real file I/O, which a test's fake clock does not
    // advance; without yielding to the real event loop the viewer is still on
    // its blank pre-load frame. Polled rather than given one fixed delay,
    // which would be tuned to this machine and fail on a slower one.
    //
    // The chapter renders as Markdown, so its heading is rich text.
    final Finder chapterTitle = find.textContaining(
      'The Android companion',
      findRichText: true,
    );
    await _pumpUntil(tester, () => chapterTitle.evaluate().isNotEmpty);

    expect(chapterTitle, findsWidgets);
    // Single-chapter mode: no contents list, no search box, and none of the
    // desktop-only chapters the phone has no features for.
    expect(find.text('Contents'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    // No other chapter is reachable. "Getting started" is the title of one and
    // a phrase this chapter never uses, so finding it would mean the viewer
    // rendered the whole guide.
    expect(
      find.textContaining('Getting started', findRichText: true),
      findsNothing,
    );
  });

  testWidgets('About shows the app version and licence', (
    WidgetTester tester,
  ) async {
    await _setPhoneSurface(tester);

    await tester.pumpWidget(
      LearnAnywhereMobileApp(
        prefs: await _fakePrefs(),
        fileService: _FakeMobileFileService(),
      ),
    );
    await tester.pumpAndSettle();

    await _openFromOverflow(tester, 'About');

    expect(find.text('Learn Anywhere'), findsWidgets);
    expect(find.text('Version $kMobileAppVersion'), findsOneWidget);
    expect(
      find.text('Free software under the GNU General Public License v3.0.'),
      findsOneWidget,
    );
    expect(find.text(kMobileProjectUrl), findsOneWidget);
    // Desktop's bilingual version history is deliberately not here.
    expect(find.text('Version history'), findsNothing);
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
      // the setup screen below if it re-reads the settings live rather than
      // from a frozen constructor snapshot.
      await _openFromOverflow(tester, 'Settings');
      await tester.tap(find.text('Minimum-attempts guard'));
      await tester.pumpAndSettle();
      expect(fileService.savedSettings.minimumAttemptsGuardEnabled, isTrue);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mobile sample'));
      await tester.pumpAndSettle();
      // One direction only, so the pool holds exactly one item: with both
      // directions in scope, the still-unqueried second item alone would keep
      // the pool non-empty regardless of the guard, masking the very thing
      // this test checks. Direction 1 is the default, so nothing to change.
      expect(find.text('Forward'), findsOneWidget);
      // Drill mode is the default, so mastery (and thus the guard) already
      // decides when the session ends.
      expect(find.text('Drill mode'), findsOneWidget);
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

  testWidgets('setup defaults to Drill and remembers every choice', (
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
    await tester.tap(find.text('Mobile sample'));
    await tester.pumpAndSettle();

    // First run: Drill mode and direction 1, taken from LearnAnywhereSettings'
    // own defaults rather than hardcoded in the screen.
    expect(find.text('Drill mode'), findsOneWidget);
    expect(find.text('Forward'), findsOneWidget);

    // Change mode, direction, shuffle and the Drill-only mastery threshold.
    await tester.tap(find.text('Drill mode'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Once through').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Forward'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Backward').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Shuffle units'));
    await tester.pumpAndSettle();

    // Each change is written straight through to the settings file.
    expect(fileService.savedSettings.mode, SessionMode.onceThrough);
    expect(fileService.savedSettings.direction, DirectionSelection.direction2);
    expect(fileService.savedSettings.shuffle, isFalse);

    // Leaving the deck and coming back restores them — the bug was that this
    // always fell back to the hardcoded Endless default.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mobile sample'));
    await tester.pumpAndSettle();

    expect(find.text('Once through'), findsOneWidget);
    expect(find.text('Backward'), findsOneWidget);
    expect(find.text('Drill mode'), findsNothing);

    // And a cold start reads them back off disk.
    await tester.pumpWidget(
      LearnAnywhereMobileApp(
        prefs: await _fakePrefs(),
        fileService: fileService,
        key: const ValueKey<String>('restarted'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mobile sample'));
    await tester.pumpAndSettle();

    expect(find.text('Once through'), findsOneWidget);
    expect(find.text('Backward'), findsOneWidget);
  });

  testWidgets('the mastery threshold persists and is Drill-only', (
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
    await tester.tap(find.text('Mobile sample'));
    await tester.pumpAndSettle();

    // Drill is the default, so the threshold row is on screen at its stored
    // value (0.4 -> 40%).
    final Finder threshold = find.widgetWithText(
      TextField,
      'Mastery threshold (%)',
    );
    expect(_textOf(tester, threshold), '40');

    await tester.enterText(threshold, '75');
    await tester.pumpAndSettle();
    expect(fileService.savedSettings.masteryThreshold, closeTo(0.75, 1e-9));

    // It is a Drill-only option, so it disappears in Endless mode and comes
    // back with the stored value intact.
    await tester.tap(find.text('Drill mode'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Endless mode').last);
    await tester.pumpAndSettle();
    expect(threshold, findsNothing);

    await tester.tap(find.text('Endless mode'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Drill mode').last);
    await tester.pumpAndSettle();
    expect(_textOf(tester, threshold), '75');
  });

  testWidgets('an oversized prompt shrinks and scrolls instead of overflowing', (
    WidgetTester tester,
  ) async {
    await _setPhoneSurface(tester);
    // Far more text than a phone card can hold at any size, so both the
    // shrink and the scroll have to carry it.
    final String essay = List<String>.filled(60, 'Donaudampfschiff').join(' ');
    final LearningDeck deck = LearningDeck(
      mask: _deck().mask,
      units: <LearningUnit>[
        LearningUnit(
          categoryId: 1,
          fields: <int, FieldValue>{
            0: PlainFieldValue(essay),
            1: const PlainFieldValue('short answer'),
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
    await tester.tap(find.text('Start session'));
    await tester.pumpAndSettle();

    // A RenderFlex overflow would have failed the pump above. The rating flow
    // must still be reachable, which is what overflowing used to cost.
    expect(tester.takeException(), isNull);
    expect(find.text('Show answer'), findsOneWidget);

    // The prompt shrank to the floor and is scrollable past the fold.
    final Finder prompt = find.byType(Scrollable).last;
    await tester.drag(prompt, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

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

    // Direction 1 ("Forward") is the default, so each unit contributes one
    // item without touching the dropdown.
    expect(find.text('Forward'), findsOneWidget);

    // Endless mode, so the order repeats and the wrap-around is observable;
    // Drill draws from the mastery pool instead and ignores shuffle entirely.
    await tester.tap(find.text('Drill mode'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Endless mode').last);
    await tester.pumpAndSettle();

    // Shuffle defaults to ON (as on desktop); this test is about deck order,
    // so turn it off explicitly.
    await tester.tap(find.text('Shuffle units'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start session'));
    await tester.pumpAndSettle();

    // Deck order with shuffle off: unit 1 ("hello"), then unit 2 ("goodbye"),
    // then the endless pass wraps back to unit 1.
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

/// Opens the library's overflow menu and taps the entry labelled [label].
///
/// The user guide, Settings and About all live behind the overflow menu, so a
/// test reaching any of them takes two taps rather than one.
Future<void> _openFromOverflow(WidgetTester tester, String label) async {
  await tester.tap(find.byIcon(Icons.more_vert));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// Pumps, yielding to real async work between frames, until [ready] holds.
///
/// The bundled guide is read from the asset bundle with real file I/O, which a
/// test's fake clock never advances. Fails rather than hanging if the
/// condition never becomes true.
Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() ready, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final DateTime deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pumpAndSettle();
    if (ready()) {
      return;
    }
  }
  fail('timed out waiting for the help chapter to load');
}

Future<MobilePrefs> _fakePrefs() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  return MobilePrefs(await SharedPreferences.getInstance());
}

/// The live text of the [TextField] found by [finder], read from its
/// controller rather than the rendered value.
String _textOf(WidgetTester tester, Finder finder) {
  return tester.widget<TextField>(finder).controller!.text;
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

  /// The settings most recently saved — by the Settings screen (guardrails)
  /// or the setup screen (mode, direction, shuffle, mastery threshold).
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
