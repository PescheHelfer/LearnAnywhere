import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_desktop/src/learn/desktop_query_options.dart';
import 'package:learn_anywhere_desktop/src/learn/learn_session_page.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

void main() {
  const LearningMask mask = LearningMask(
    maskId: 'm_new_learn-session-fixture',
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

  final LearningDeck deck = LearningDeck(
    mask: mask,
    units: const <LearningUnit>[
      LearningUnit(
        categoryId: 0,
        fields: <int, FieldValue>{
          0: FieldValue.plain('eins'),
          1: FieldValue.plain('one'),
        },
      ),
      LearningUnit(
        categoryId: 0,
        fields: <int, FieldValue>{
          0: FieldValue.plain('zwei'),
          1: FieldValue.plain('two'),
        },
      ),
    ],
  );

  Widget buildPage({
    required VoidCallback onExit,
    bool startSessionOnOpen = false,
    ValueChanged<bool>? onSessionActiveChanged,
  }) {
    return MaterialApp(
      localizationsDelegates: LearnAnywhereLocalizations.localizationsDelegates,
      supportedLocales: LearnAnywhereLocalizations.supportedLocales,
      home: Scaffold(
        body: LearnSessionPage(
          startSessionOnOpen: startSessionOnOpen,
          onSessionActiveChanged: onSessionActiveChanged,
          deck: deck,
          statistics: const <UnitStats>[],
          options: const DesktopQueryOptions(),
          parameters: const SessionParameters(
            withInput: false,
            mode: SessionMode.onceThrough,
            directionSelection: DirectionSelection.direction1,
            shuffle: false,
          ),
          onParametersChanged: (SessionParameters _) {},
          onStatisticsChanged: (List<UnitStats> _) {},
          onOpenEditor: () {},
          onExit: onExit,
        ),
      ),
    );
  }

  testWidgets(
    '"Learn with last settings" skips setup and reports the session as active',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final List<bool> activeReports = <bool>[];
      await tester.pumpWidget(
        buildPage(
          onExit: () {},
          startSessionOnOpen: true,
          onSessionActiveChanged: activeReports.add,
        ),
      );
      await tester.pumpAndSettle();

      // Straight into the first unit — the setup screen is never shown.
      expect(find.textContaining('Use all units'), findsNothing);
      expect(find.textContaining('Unit 1/2'), findsOneWidget);
      expect(activeReports, <bool>[true]);
    },
  );

  testWidgets(
    'setup screen shows the deck size, expands a cleared range field to its '
    'own end, and pins the range with "Use all units"',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildPage(onExit: () {}));
      await tester.pumpAndSettle();

      // The deck size is stated in the "Use all units" toggle label.
      expect(find.text('Use all units (2)'), findsOneWidget);

      final Finder startField = find.ancestor(
        of: find.text('Start unit'),
        matching: find.byType(TextField),
      );
      final Finder endField = find.ancestor(
        of: find.text('End unit'),
        matching: find.byType(TextField),
      );

      // Clearing "End unit" means "through the last unit", not 1 — while
      // clearing "Start unit" still means the first unit.
      await tester.enterText(endField, '');
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(endField).controller!.text, '2');

      await tester.enterText(startField, '2');
      await tester.pumpAndSettle();
      await tester.enterText(startField, '');
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(startField).controller!.text, '1');

      // Narrow the range, then pin it: both fields go read-only and snap back
      // to the full deck.
      await tester.enterText(endField, '1');
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(endField).controller!.text, '1');
      expect(tester.widget<TextField>(startField).enabled, isTrue);

      await tester.tap(find.text('Use all units (2)'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(startField).enabled, isFalse);
      expect(tester.widget<TextField>(endField).enabled, isFalse);
      expect(tester.widget<TextField>(startField).controller!.text, '1');
      expect(tester.widget<TextField>(endField).controller!.text, '2');

      // Unpinning re-enables them and leaves the full range in place.
      await tester.tap(find.text('Use all units (2)'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(startField).enabled, isTrue);
      expect(tester.widget<TextField>(endField).controller!.text, '2');
    },
  );

  testWidgets(
    'F-key shortcuts keep working after a mouse-driven session start, '
    'through completion and onto the completion view',
    (WidgetTester tester) async {
      // The practice header row is too wide for the default 800px surface.
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var exited = false;
      await tester.pumpWidget(buildPage(onExit: () => exited = true));
      await tester.pumpAndSettle();

      // Mouse-driven start (the real-world trigger for the focus-loss bug):
      // the "Start session" button is disposed once the setup view is gone.
      await tester.tap(find.text('Start session'));
      await tester.pumpAndSettle();

      // First unit, withInput off: F10 (Reveal) must still be live.
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();
      expect(
        find.text('Your answer is correct. Congratulations!'),
        findsOneWidget,
      );

      // F3 continues to the second (last) unit.
      await tester.sendKeyEvent(LogicalKeyboardKey.f3);
      await tester.pumpAndSettle();

      // Second unit: F10 must still be live too (no answer fields ever
      // claimed focus in withInput-off mode).
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();
      expect(
        find.text('Your answer is correct. Congratulations!'),
        findsOneWidget,
      );

      // F3 ends the once-through session -> completion view.
      await tester.sendKeyEvent(LogicalKeyboardKey.f3);
      await tester.pumpAndSettle();
      expect(find.text('Extend session'), findsOneWidget);

      // Esc on the completion view must still be live and exit immediately
      // (no live stats to lose there).
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(exited, isTrue);
    },
  );

  testWidgets(
    'Esc during a live session exits immediately with no confirmation, and '
    "the header shows the current unit's own accuracy",
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var exited = false;
      await tester.pumpWidget(buildPage(onExit: () => exited = true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start session'));
      await tester.pumpAndSettle();

      // Not yet attempted in this scope: numeric zero, not a blank/omitted
      // segment. (This harness's `statistics` prop is static, so the value
      // never changes regardless of interaction — the point here is the
      // presence and formatting of the segment, not live updates.)
      expect(find.textContaining('This unit: 0/0 (0%)'), findsOneWidget);

      // Leaving mid-session (Esc) must exit immediately — no "Please
      // confirm" dialog, unlike the old confirmation prompt.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Please confirm'), findsNothing);
      expect(exited, isTrue);
    },
  );

  testWidgets(
    'Extend session from the completion view keeps Esc/F-keys live on '
    'the setup screen',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildPage(onExit: () {}));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start session'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f3);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f3);
      await tester.pumpAndSettle();
      expect(find.text('Extend session'), findsOneWidget);

      // The "Extend session" button that is tapped here gets disposed by the
      // view switch back to setup; F3 must still reach the setup view.
      await tester.tap(find.text('Extend session'));
      await tester.pumpAndSettle();
      expect(find.text('Start session'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.f3);
      await tester.pumpAndSettle();
      // F3 restarted the session straight from the setup view.
      expect(
        find.text('Your answer is correct. Congratulations!'),
        findsNothing,
      );
      expect(find.text('Start session'), findsNothing);
    },
  );

  testWidgets(
    'level learning: F10 respects Hide & type, the ladder promotes 3->0 to '
    'mastery, and only the level-0 attempt reaches the drill statistics',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final _LevelLearningHarnessState Function() harnessState =
          () => tester.state(find.byType(_LevelLearningHarness));
      await tester.pumpWidget(_LevelLearningHarness(deck: deck));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start session'));
      await tester.pumpAndSettle();

      // A fresh deck seeds level 3 (Beginner): full solution shown, no input,
      // and the primary action is "Hide & type". Attempts here is the ladder's
      // own deck-wide total, not a counter for this sitting.
      expect(find.text('Attempts: 0'), findsOneWidget);
      expect(find.text('Beginner: 1 (100%)'), findsOneWidget);
      expect(find.text('Hide & type'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      // F10 must enter the memorize step — NOT evaluate the empty input.
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();
      expect(find.text('The answer is unfortunately wrong.'), findsNothing);
      expect(find.byType(TextField), findsOneWidget);

      // Type from memory, check via F10, continue: promotes to level 2.
      await tester.enterText(find.byType(TextField), 'one');
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();
      expect(
        find.text('Your answer is correct. Congratulations!'),
        findsOneWidget,
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      // One attempt recorded at level 3 — the ladder is the only place it
      // exists, and Attempts reads it.
      expect(find.text('Attempts: 1'), findsOneWidget);
      expect(find.text('Learner: 1 (100%)'), findsOneWidget);
      expect(harnessState().drillStatsPushes, isEmpty);

      // Level 2: 'one' blanks the even candidates, so 'n' is revealed between
      // the two cells the student fills.
      expect(find.byType(TextField), findsNWidgets(2));
      await tester.enterText(find.byType(TextField).at(0), 'o');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(1), 'e');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();
      expect(
        find.text('Your answer is correct. Congratulations!'),
        findsOneWidget,
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Attempts: 2'), findsOneWidget);
      expect(find.text('Almost There: 1 (100%)'), findsOneWidget);

      // Level 1: first/last revealed, middle blank filled in place (one cell).
      await tester.enterText(find.byType(TextField), 'n');
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Attempts: 3'), findsOneWidget);
      expect(find.text('Champion: 1 (100%)'), findsOneWidget);
      expect(find.text('Mastered: 0 (0%)'), findsOneWidget);

      // Levels 3, 2 and 1 are scaffolded recall, so nothing has reached the
      // drill statistics yet — including the attempt that promoted 1 -> 0,
      // which was answered at level 1. The two readings agree: "Attempts: 3"
      // above counts the climb through the ladder, while the drill statistics
      // this deck would show are still untouched at zero.
      expect(harnessState().drillStatsPushes, isEmpty);

      // Level 0: free recall; a correct answer masters the unit and, with an
      // empty pool, completes the session.
      await tester.enterText(find.byType(TextField), 'one');
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Extend session'), findsOneWidget);

      // The level-0 attempt counts overall: exactly one push, carrying a
      // single correct attempt for the answered direction.
      expect(harnessState().drillStatsPushes, hasLength(1));
      final UnitStats drilled = harnessState().drillStatsPushes.single
          .singleWhere((UnitStats s) => s.index == 1);
      expect(drilled.direction1.attempts, 1);
      expect(drilled.direction1.correct, 1);
      expect(drilled.direction2.attempts, 0);
      // The ladder was materialized and the unit ends mastered at level 0.
      final LevelUnitStats entry = harnessState()
          ._levelStats
          .singleWhere((LevelUnitStats s) => s.index == 1);
      expect(entry.dir1.currentLevel, kFreeRecallLevel);

      // Choosing Learn again from the completion screen returns to the setup
      // screen (so a fresh session/mode can be configured) without needing to
      // Extend + cancel first.
      harnessState().chooseLearn();
      await tester.pumpAndSettle();
      expect(find.text('Extend session'), findsNothing);
      expect(find.text('Start session'), findsOneWidget);
    },
  );

  testWidgets(
    'level learning: Enter on an earlier answer field advances instead of '
    'checking; only the last field submits',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // A mask whose direction 1 has two answer fields (like infinitive +
      // past tense), each masked to two blank cells at level 2.
      const LearningMask twoAnswerMask = LearningMask(
        maskId: 'm_new_two-answer-fixture',
        name: 'Verbs',
        direction1Label: 'DE',
        direction2Label: 'EN',
        categories: <CategoryDefinition>[
          CategoryDefinition(
            id: 0,
            name: 'Verb',
            fields: <FieldDefinition>[
              FieldDefinition(
                id: 0,
                name: 'German',
                length: 40,
                equalGroup: 0,
                role1: FieldRole.question,
                role2: FieldRole.answer,
              ),
              FieldDefinition(
                id: 1,
                name: 'Infinitive',
                length: 40,
                equalGroup: 1,
                role1: FieldRole.answer,
                role2: FieldRole.question,
              ),
              FieldDefinition(
                id: 2,
                name: 'Past',
                length: 40,
                equalGroup: 2,
                role1: FieldRole.answer,
                role2: FieldRole.question,
              ),
            ],
          ),
        ],
      );
      final LearningDeck twoAnswerDeck = LearningDeck(
        mask: twoAnswerMask,
        units: const <LearningUnit>[
          LearningUnit(
            categoryId: 0,
            fields: <int, FieldValue>{
              0: FieldValue.plain('essen'),
              1: FieldValue.plain('eat'),
              2: FieldValue.plain('ate'),
            },
          ),
        ],
      );

      // entryLevelCap 2 seeds fresh units straight at level 2 (editable cells).
      await tester.pumpWidget(
        _LevelLearningHarness(deck: twoAnswerDeck, entryLevelCap: 2),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start session'));
      await tester.pumpAndSettle();

      // 'eat' -> [e]a[t], 'ate' -> [a]t[e]: two blank cells per answer field.
      expect(find.byType(TextField), findsNWidgets(4));

      // Fill the first field's blanks and press Enter on its last one. This
      // must NOT check the answer (the second field is still empty) — it
      // advances to it.
      await tester.enterText(find.byType(TextField).at(0), 'e');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(1), 't');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('The answer is unfortunately wrong.'), findsNothing);
      expect(
        find.text('Your answer is correct. Congratulations!'),
        findsNothing,
      );

      // Fill the last field's blanks and Enter: now the answer is checked.
      await tester.enterText(find.byType(TextField).at(2), 'a');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(3), 'e');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        find.text('Your answer is correct. Congratulations!'),
        findsOneWidget,
      );
    },
  );

  // A third unit keeps the once-through session running past the two attempts
  // the readout tests make.
  final LearningDeck drillDeck = LearningDeck(
    mask: mask,
    units: const <LearningUnit>[
      LearningUnit(
        categoryId: 0,
        fields: <int, FieldValue>{
          0: FieldValue.plain('eins'),
          1: FieldValue.plain('one'),
        },
      ),
      LearningUnit(
        categoryId: 0,
        fields: <int, FieldValue>{
          0: FieldValue.plain('zwei'),
          1: FieldValue.plain('two'),
        },
      ),
      LearningUnit(
        categoryId: 0,
        fields: <int, FieldValue>{
          0: FieldValue.plain('drei'),
          1: FieldValue.plain('three'),
        },
      ),
    ],
  );

  testWidgets(
    'the live Attempts and Accuracy pills read the deck statistics, so they '
    'open on what is already recorded and ignore an uncounted answer',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Statistics as they arrive from a loaded `.sta` — recorded before this
      // run of the app: 4 correct out of 6 across the deck.
      await tester.pumpWidget(
        _DrillHarness(
          deck: drillDeck,
          statistics: const <UnitStats>[
            UnitStats(
              index: 1,
              direction1: DirectionStats(attempts: 4, correct: 3),
            ),
            UnitStats(
              index: 2,
              direction1: DirectionStats(attempts: 2, correct: 1),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start session'));
      await tester.pumpAndSettle();

      // Nothing has been answered in this sitting, yet the pills already carry
      // the deck's totals instead of starting from zero.
      expect(find.text('Attempts: 6'), findsOneWidget);
      expect(find.text('Accuracy: 4/6 (67%)'), findsOneWidget);

      // A counted attempt moves both figures.
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Knew it'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Attempts: 7'), findsOneWidget);
      expect(find.text('Accuracy: 5/7 (71%)'), findsOneWidget);

      // "No count" records nothing, so the readouts must not move either.
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();
      await tester.tap(find.text('No count'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Attempts: 7'), findsOneWidget);
      expect(find.text('Accuracy: 5/7 (71%)'), findsOneWidget);
    },
  );

  testWidgets(
    'opening a second deck in the same run carries nothing over from the first',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _DrillHarness(
          deck: drillDeck,
          statistics: const <UnitStats>[
            UnitStats(
              index: 1,
              direction1: DirectionStats(attempts: 4, correct: 3),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start session'));
      await tester.pumpAndSettle();
      expect(find.text('Attempts: 4'), findsOneWidget);

      // The shell loads another deck: its statistics replace the first deck's
      // wholesale, and the readouts must follow them down again.
      tester
          .state<_DrillHarnessState>(find.byType(_DrillHarness))
          .openDeck(const <UnitStats>[]);
      await tester.pumpAndSettle();
      expect(find.text('Attempts: 0'), findsOneWidget);
      expect(find.text('Accuracy: 0/0 (0%)'), findsOneWidget);
    },
  );

  // A category whose direction-1 answers cover both ends of the scaffold: a
  // normal word, a "no plural" marker with no mask candidates at all, and a
  // one-letter gender marker.
  const LearningMask markerMask = LearningMask(
    maskId: 'm_new_marker-fixture',
    name: 'Nouns',
    direction1Label: 'DE',
    direction2Label: 'FR',
    categories: <CategoryDefinition>[
      CategoryDefinition(
        id: 0,
        name: 'Noun',
        fields: <FieldDefinition>[
          FieldDefinition(
            id: 0,
            name: 'German',
            length: 20,
            equalGroup: 0,
            role1: FieldRole.question,
            role2: FieldRole.answer,
          ),
          FieldDefinition(
            id: 1,
            name: 'French',
            length: 20,
            equalGroup: 0,
            role1: FieldRole.answer,
            role2: FieldRole.question,
          ),
          FieldDefinition(
            id: 2,
            name: 'Plural',
            length: 20,
            equalGroup: 0,
            role1: FieldRole.answer,
            role2: FieldRole.question,
          ),
          FieldDefinition(
            id: 3,
            name: 'Gender',
            length: 20,
            equalGroup: 0,
            role1: FieldRole.answer,
            role2: FieldRole.question,
          ),
        ],
      ),
    ],
  );
  final LearningDeck markerDeck = LearningDeck(
    mask: markerMask,
    units: const <LearningUnit>[
      LearningUnit(
        categoryId: 0,
        fields: <int, FieldValue>{
          0: FieldValue.plain('Katze'),
          1: FieldValue.plain('chat'),
          2: FieldValue.plain('-'),
          3: FieldValue.plain('m'),
        },
      ),
    ],
  );

  testWidgets(
    'level learning: a field the scaffold reveals whole is graded as the '
    'letters shown and appears answered, and every other field still asks for '
    'a letter',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _LevelLearningHarness(deck: markerDeck, entryLevelCap: 2),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start session'));
      await tester.pumpAndSettle();

      // At level 2 even candidates are blank: 'chat' -> [c]h[a]t (two blanks)
      // and the one-letter 'm' -> [m] (one). '-' has no candidates at all, so
      // it is shown whole and contributes no blank.
      expect(find.byType(TextField), findsNWidgets(3));

      await tester.enterText(find.byType(TextField).at(0), 'c');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(1), 'a');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(2), 'm');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();

      // The marker field is graded as the character the scaffold displayed,
      // not as the empty answer it was never given a chance to receive.
      expect(
        find.text('Your answer is correct. Congratulations!'),
        findsOneWidget,
      );

      // ... and "Your answer" shows it as answered rather than blank.
      await tester.sendKeyEvent(LogicalKeyboardKey.f9);
      await tester.pumpAndSettle();
      expect(find.text('-', findRichText: true), findsOneWidget);
    },
  );

  testWidgets(
    'level learning: an untouched scaffold submits the letters it displays',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _LevelLearningHarness(deck: markerDeck, entryLevelCap: 2),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start session'));
      await tester.pumpAndSettle();

      // Check without typing anything at all.
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();
      expect(find.text('The answer is unfortunately wrong.'), findsOneWidget);

      // The scaffold reported on build, so "Your answer" carries the revealed
      // letters of the untouched word field and the whole marker field. A wrong
      // answer opens on the correction view, so it takes two steps to get
      // there (correction -> solution -> your answer).
      await tester.sendKeyEvent(LogicalKeyboardKey.f9);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f9);
      await tester.pumpAndSettle();
      expect(find.text('ht', findRichText: true), findsOneWidget);
      expect(find.text('-', findRichText: true), findsOneWidget);
    },
  );
}

/// Minimal shell that holds the mutable Level-Learning state the page pushes
/// back, so promotions and the ladder the Attempts pill reads survive across
/// prompts in the test.
class _LevelLearningHarness extends StatefulWidget {
  const _LevelLearningHarness({
    required this.deck,
    this.entryLevelCap = kMaxSupportLevel,
  });

  final LearningDeck deck;
  final int entryLevelCap;

  @override
  State<_LevelLearningHarness> createState() => _LevelLearningHarnessState();
}

class _LevelLearningHarnessState extends State<_LevelLearningHarness> {
  List<LevelUnitStats> _levelStats = const <LevelUnitStats>[];
  int _resetSignal = 0;

  /// Every drill-mode statistics push the page made, in order.
  ///
  /// In Level Learning only attempts answered *at* level 0 push here — level 0
  /// is free recall, the same thing the drill modes test.
  final List<List<UnitStats>> drillStatsPushes = <List<UnitStats>>[];

  /// Mimics choosing the Learn menu again (bumps the reset signal).
  void chooseLearn() => setState(() => _resetSignal++);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: LearnAnywhereLocalizations.localizationsDelegates,
      supportedLocales: LearnAnywhereLocalizations.supportedLocales,
      home: Scaffold(
        body: LearnSessionPage(
          deck: widget.deck,
          statistics: const <UnitStats>[],
          levelStatistics: _levelStats,
          entryLevelCap: widget.entryLevelCap,
          resetToSetupSignal: _resetSignal,
          options: const DesktopQueryOptions(),
          parameters: const SessionParameters(
            mode: SessionMode.levelLearning,
            directionSelection: DirectionSelection.direction1,
            startIndex: 1,
            endIndex: 1,
            shuffle: false,
          ),
          onParametersChanged: (SessionParameters _) {},
          onStatisticsChanged: (List<UnitStats> value) {
            drillStatsPushes.add(value);
          },
          onLevelStatisticsChanged: (List<LevelUnitStats> value) {
            setState(() => _levelStats = value);
          },
          onOpenEditor: () {},
          onExit: () {},
        ),
      ),
    );
  }
}

/// Minimal shell for the non-ladder readout tests: it holds the statistics the
/// page pushes back, exactly as the desktop shell's document does, so the live
/// pills can be read against a deck total rather than a sitting's counter.
class _DrillHarness extends StatefulWidget {
  const _DrillHarness({required this.deck, required this.statistics});

  final LearningDeck deck;
  final List<UnitStats> statistics;

  @override
  State<_DrillHarness> createState() => _DrillHarnessState();
}

class _DrillHarnessState extends State<_DrillHarness> {
  late List<UnitStats> _statistics = widget.statistics;

  /// Mimics the shell opening another deck: statistics are replaced wholesale.
  void openDeck(List<UnitStats> statistics) {
    setState(() => _statistics = statistics);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: LearnAnywhereLocalizations.localizationsDelegates,
      supportedLocales: LearnAnywhereLocalizations.supportedLocales,
      home: Scaffold(
        body: LearnSessionPage(
          deck: widget.deck,
          statistics: _statistics,
          options: const DesktopQueryOptions(),
          parameters: const SessionParameters(
            withInput: false,
            mode: SessionMode.onceThrough,
            directionSelection: DirectionSelection.direction1,
            shuffle: false,
          ),
          onParametersChanged: (SessionParameters _) {},
          onStatisticsChanged: (List<UnitStats> value) {
            setState(() => _statistics = value);
          },
          onOpenEditor: () {},
          onExit: () {},
        ),
      ),
    );
  }
}
