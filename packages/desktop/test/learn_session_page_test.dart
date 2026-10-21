import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_desktop/src/learn/desktop_query_options.dart';
import 'package:learn_anywhere_desktop/src/learn/learn_session_page.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

/// Whether [span] or any span below it has a style matching [test].
bool _anySpan(InlineSpan span, bool Function(TextStyle style) test) {
  var found = false;
  span.visitChildren((InlineSpan child) {
    final TextStyle? style = child.style;
    found = style != null && test(style);
    return !found;
  });
  return found;
}

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
    'Correction hides the highlight of an answer with a typo, while the same '
    'answer typed correctly keeps it',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      FieldDefinition field(int id, FieldRole role) => FieldDefinition(
        id: id,
        name: 'Field $id',
        length: 40,
        equalGroup: 0,
        role1: role,
        role2: role,
      );
      final FieldValue highlighted = FieldValue.rich(const <RichTextRun>[
        RichTextRun(text: 'house', highlight: HighlightToken.highlight1),
      ]);
      final LearningDeck highlightDeck = LearningDeck(
        mask: LearningMask(
          maskId: 'm_new_correction-formatting',
          name: 'Fixture',
          direction1Label: 'A',
          direction2Label: 'B',
          categories: <CategoryDefinition>[
            CategoryDefinition(
              id: 0,
              name: 'Cat',
              fields: <FieldDefinition>[
                field(0, FieldRole.question),
                field(1, FieldRole.answer),
                field(2, FieldRole.answer),
              ],
            ),
          ],
        ),
        units: <LearningUnit>[
          LearningUnit(
            categoryId: 0,
            fields: <int, FieldValue>{
              0: const FieldValue.plain('Haus'),
              1: highlighted,
              2: highlighted,
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates:
              LearnAnywhereLocalizations.localizationsDelegates,
          supportedLocales: LearnAnywhereLocalizations.supportedLocales,
          home: Scaffold(
            body: LearnSessionPage(
              startSessionOnOpen: true,
              deck: highlightDeck,
              statistics: const <UnitStats>[],
              options: const DesktopQueryOptions(),
              parameters: const SessionParameters(
                mode: SessionMode.onceThrough,
                directionSelection: DirectionSelection.direction1,
                shuffle: false,
              ),
              onParametersChanged: (SessionParameters _) {},
              onStatisticsChanged: (List<UnitStats> _) {},
              onOpenEditor: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'hause');
      await tester.enterText(find.byType(TextField).at(1), 'house');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();

      // Whether each displayed "house", in field order, draws a highlight.
      List<bool> highlightedAnswers() {
        return <bool>[
          for (final RichText text in tester.widgetList<RichText>(
            find.byType(RichText),
          ))
            if (text.text.toPlainText() == 'house')
              _anySpan(
                text.text,
                (TextStyle style) => style.backgroundColor != null,
              ),
        ];
      }

      // A wrong answer opens on Correction.
      expect(highlightedAnswers(), <bool>[false, true]);

      // The Solution view keeps the formatting of both.
      await tester.sendKeyEvent(LogicalKeyboardKey.f9);
      await tester.pumpAndSettle();
      expect(highlightedAnswers(), <bool>[true, true]);
    },
  );

  testWidgets(
    'Correction of a wrong answer marks a case difference in one row and a '
    'typo in another',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      FieldDefinition field(int id, FieldRole role) => FieldDefinition(
        id: id,
        name: 'Field $id',
        length: 40,
        equalGroup: 0,
        role1: role,
        role2: role,
      );
      final LearningDeck caseDeck = LearningDeck(
        mask: LearningMask(
          maskId: 'm_new_correction-case',
          name: 'Fixture',
          direction1Label: 'A',
          direction2Label: 'B',
          categories: <CategoryDefinition>[
            CategoryDefinition(
              id: 0,
              name: 'Cat',
              fields: <FieldDefinition>[
                field(0, FieldRole.question),
                field(1, FieldRole.answer),
                field(2, FieldRole.answer),
              ],
            ),
          ],
        ),
        units: const <LearningUnit>[
          LearningUnit(
            categoryId: 0,
            fields: <int, FieldValue>{
              0: FieldValue.plain('Haus'),
              1: FieldValue.plain('Maison'),
              2: FieldValue.plain('chien'),
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates:
              LearnAnywhereLocalizations.localizationsDelegates,
          supportedLocales: LearnAnywhereLocalizations.supportedLocales,
          home: Scaffold(
            body: LearnSessionPage(
              startSessionOnOpen: true,
              deck: caseDeck,
              statistics: const <UnitStats>[],
              options: const DesktopQueryOptions(),
              parameters: const SessionParameters(
                mode: SessionMode.onceThrough,
                directionSelection: DirectionSelection.direction1,
                shuffle: false,
              ),
              onParametersChanged: (SessionParameters _) {},
              onStatisticsChanged: (List<UnitStats> _) {},
              onOpenEditor: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // "maison" only differs by case, which judging ignores by default;
      // "chen" is missing its "i" and makes the answer Wrong.
      await tester.enterText(find.byType(TextField).at(0), 'maison');
      await tester.enterText(find.byType(TextField).at(1), 'chen');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();

      final Color correction = LearnAnywhereFormatColours.of(
        Theme.of(tester.element(find.byType(LearnSessionPage))),
      ).correction;

      String markedText(InlineSpan root) {
        final StringBuffer marked = StringBuffer();
        root.visitChildren((InlineSpan span) {
          if (span is TextSpan && span.style?.color == correction) {
            marked.write(span.text ?? '');
          }
          return true;
        });
        return marked.toString();
      }

      // Each displayed answer value in row order, with the characters drawn
      // in the correction colour.
      List<(String, String)> markedRows() {
        return <(String, String)>[
          for (final RichText text in tester.widgetList<RichText>(
            find.byType(RichText),
          ))
            if (const <String>{
              'Maison',
              'chien',
            }.contains(text.text.toPlainText()))
              (text.text.toPlainText(), markedText(text.text)),
        ];
      }

      expect(find.text('Correction'), findsOneWidget);
      expect(markedRows(), <(String, String)>[('Maison', 'M'), ('chien', 'i')]);
    },
  );

  testWidgets(
    'Correction shows a swapped equal group in the typed order, marking only '
    'the typo, while Solution keeps the stored order',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      FieldDefinition field(int id, FieldRole role, int equalGroup) =>
          FieldDefinition(
            id: id,
            name: 'Field $id',
            length: 40,
            equalGroup: equalGroup,
            role1: role,
            role2: role,
          );
      final LearningDeck groupDeck = LearningDeck(
        mask: LearningMask(
          maskId: 'm_new_equal-group-correction',
          name: 'Fixture',
          direction1Label: 'A',
          direction2Label: 'B',
          categories: <CategoryDefinition>[
            CategoryDefinition(
              id: 0,
              name: 'Cat',
              fields: <FieldDefinition>[
                field(0, FieldRole.question, 0),
                field(1, FieldRole.answer, 1),
                field(2, FieldRole.answer, 1),
              ],
            ),
          ],
        ),
        units: const <LearningUnit>[
          LearningUnit(
            categoryId: 0,
            fields: <int, FieldValue>{
              0: FieldValue.plain('Haus'),
              1: FieldValue.plain('maison'),
              2: FieldValue.plain('domicile'),
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates:
              LearnAnywhereLocalizations.localizationsDelegates,
          supportedLocales: LearnAnywhereLocalizations.supportedLocales,
          home: Scaffold(
            body: LearnSessionPage(
              startSessionOnOpen: true,
              deck: groupDeck,
              statistics: const <UnitStats>[],
              options: const DesktopQueryOptions(),
              parameters: const SessionParameters(
                mode: SessionMode.onceThrough,
                directionSelection: DirectionSelection.direction1,
                shuffle: false,
              ),
              onParametersChanged: (SessionParameters _) {},
              onStatisticsChanged: (List<UnitStats> _) {},
              onOpenEditor: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Swapped, with the "o" of "maison" left out.
      await tester.enterText(find.byType(TextField).at(0), 'domicile');
      await tester.enterText(find.byType(TextField).at(1), 'maisn');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();

      final Color correction = LearnAnywhereFormatColours.of(
        Theme.of(tester.element(find.byType(LearnSessionPage))),
      ).correction;

      // Each displayed answer value in row order, and whether it carries a
      // correction mark.
      List<(String, bool)> answerRows() {
        return <(String, bool)>[
          for (final RichText text in tester.widgetList<RichText>(
            find.byType(RichText),
          ))
            if (const <String>{
              'maison',
              'domicile',
            }.contains(text.text.toPlainText()))
              (
                text.text.toPlainText(),
                _anySpan(
                  text.text,
                  (TextStyle style) => style.color == correction,
                ),
              ),
        ];
      }

      expect(find.text('Correction'), findsOneWidget);
      expect(answerRows(), <(String, bool)>[
        ('domicile', false),
        ('maison', true),
      ]);

      await tester.sendKeyEvent(LogicalKeyboardKey.f9);
      await tester.pumpAndSettle();
      expect(answerRows(), <(String, bool)>[
        ('maison', false),
        ('domicile', false),
      ]);
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
      expect(find.textContaining('Unit accuracy: 0/0 (0%)'), findsOneWidget);

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
      //
      // The session is restricted to unit 1, but the level pills count the whole
      // deck in the session's direction, so both units show — 2 of 2 items.
      expect(find.text('Attempts: 0'), findsOneWidget);
      expect(find.text('Beginner: 2 (100%)'), findsOneWidget);
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
      // Unit 1 has climbed to Learner; unit 2, never served, still sits at
      // Beginner and is still counted.
      expect(find.text('Learner: 1 (50%)'), findsOneWidget);
      expect(find.text('Beginner: 1 (50%)'), findsOneWidget);
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
      expect(find.text('Almost There: 1 (50%)'), findsOneWidget);

      // Level 1: first/last revealed, middle blank filled in place (one cell).
      await tester.enterText(find.byType(TextField), 'n');
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Attempts: 3'), findsOneWidget);
      expect(find.text('Champion: 1 (50%)'), findsOneWidget);
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
    'level learning: the lifetime record accumulates the rung answered at and '
    'keeps the level last reached',
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

      // One correct answer at level 3 (Beginner) promotes the unit to level 2.
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'one');
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      final LevelDirectionStats lifetime = harnessState()
          .allTime
          .perLevel
          .singleWhere((LevelUnitStats s) => s.index == 1)
          .dir1;
      // The attempt lands on the rung it was answered at, not the one the
      // promotion moved to.
      expect(
        lifetime.levels[kMaxSupportLevel],
        const DirectionStats(attempts: 1, correct: 1),
      );
      expect(lifetime.levels[2], const DirectionStats());
      // A level is a state, not a counter: the record keeps the one most
      // recently reached, which the all-time view reads as "Last level".
      expect(lifetime.currentLevel, 2);
      // Nothing reached the mode-agnostic section — this was not free recall.
      expect(harnessState().allTime.perUnit, isEmpty);
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

  testWidgets(
    'Enter on the completion view extends the session and records nothing, '
    'no unit is served unseen',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final List<bool> activeReports = <bool>[];
      await tester.pumpWidget(
        _DrillHarness(
          deck: deck,
          statistics: const <UnitStats>[],
          onSessionActiveChanged: activeReports.add,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start session'));
      await tester.pumpAndSettle();
      for (int i = 0; i < 2; i += 1) {
        await tester.sendKeyEvent(LogicalKeyboardKey.f10);
        await tester.pumpAndSettle();
        await tester.tap(find.text("Didn't know"));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Extend session'), findsOneWidget);
      final _DrillHarnessState harness = tester.state(
        find.byType(_DrillHarness),
      );
      // Both units answered once, neither known.
      String counters() => harness._statistics
          .map(
            (UnitStats s) =>
                '${s.index}: ${s.direction1.attempts}/${s.direction1.correct}',
          )
          .join(', ');
      expect(counters(), '1: 1/0, 2: 1/0');
      expect(activeReports.last, isFalse);

      // Enter presses the view's one button, as it does on every other stage.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Extend session'), findsNothing);
      expect(find.text('Start session'), findsOneWidget);
      expect(counters(), '1: 1/0, 2: 1/0');
      expect(activeReports.last, isFalse);

      // Only the setup screen's own Enter starts a session — in plain view.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.textContaining('Unit 1/2'), findsOneWidget);
      expect(activeReports.last, isTrue);
      expect(counters(), '1: 1/0, 2: 1/0');
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
    'a drill ends once every unit has been answered correctly, instead of '
    'asking the last one a second time',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _DrillHarness(
          deck: drillDeck,
          statistics: const <UnitStats>[],
          parameters: const SessionParameters(
            withInput: false,
            mode: SessionMode.superQuery,
            directionSelection: DirectionSelection.direction1,
            shuffle: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start session'));
      await tester.pumpAndSettle();

      // One correct answer masters a unit at the default 40 % threshold, so
      // three units take exactly three answers. The last one used to be drawn
      // again from statistics that did not yet hold its answer.
      final Finder completed = find.textContaining(
        'mastered all learning units',
      );
      var answers = 0;
      while (completed.evaluate().isEmpty && answers < 6) {
        await tester.sendKeyEvent(LogicalKeyboardKey.f10);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Knew it'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        answers += 1;
      }

      expect(completed, findsOneWidget);
      expect(answers, 3);
      final _DrillHarnessState harness = tester.state(
        find.byType(_DrillHarness),
      );
      expect(
        harness._statistics.map((UnitStats stats) => stats.direction1),
        everyElement(const DirectionStats(attempts: 1, correct: 1)),
      );
    },
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
    'every answer reaches BOTH records: the working counters and the deck '
    'lifetime record, each by the same amount',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final _DrillHarnessState Function() harness =
          () => tester.state(find.byType(_DrillHarness));
      await tester.pumpWidget(
        _DrillHarness(
          deck: drillDeck,
          // The working record was cleared for a fresh start; the lifetime
          // record kept everything the learner has ever answered.
          statistics: const <UnitStats>[
            UnitStats(index: 1),
            UnitStats(index: 2),
          ],
          allTime: const AllTimeStatistics(
            perUnit: <UnitStats>[
              UnitStats(
                index: 1,
                direction1: DirectionStats(attempts: 40, correct: 25),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start session'));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Knew it'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // The fresh start reads 1/1 while the lifetime record carries on from 40.
      expect(find.text('Attempts: 1'), findsOneWidget);
      expect(
        harness().allTimeDir1(1),
        const DirectionStats(attempts: 41, correct: 26),
      );

      // "No count" is a no-op in both records.
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();
      await tester.tap(find.text('No count'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Attempts: 1'), findsOneWidget);
      expect(
        harness().allTimeDir1(2),
        const DirectionStats(),
        reason: 'nothing was counted, so no lifetime entry was minted either',
      );
      expect(
        harness().allTimeDir1(1),
        const DirectionStats(attempts: 41, correct: 26),
      );
    },
  );

  testWidgets(
    'an attempt the wrong-answer ceiling suppresses is skipped in the '
    'lifetime record too',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final _DrillHarnessState Function() harness =
          () => tester.state(find.byType(_DrillHarness));
      await tester.pumpWidget(
        _DrillHarness(
          deck: drillDeck,
          options: const DesktopQueryOptions(
            wrongAnswerCeilingEnabled: true,
            wrongAnswerCeiling: 2,
          ),
          // Unit 1 is already at the ceiling: two wrong out of two.
          statistics: const <UnitStats>[
            UnitStats(index: 1, direction1: DirectionStats(attempts: 2)),
          ],
          allTime: const AllTimeStatistics(
            perUnit: <UnitStats>[
              UnitStats(
                index: 1,
                direction1: DirectionStats(attempts: 30, correct: 12),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start session'));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();
      await tester.tap(find.text("Didn't know"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Neither record moved. The lifetime wrongs are well past two, and that
      // is the point: the ceiling is evaluated once, against the working
      // record, or a unit would silently stop recording forever.
      expect(find.text('Attempts: 2'), findsOneWidget);
      expect(
        harness().allTimeDir1(1),
        const DirectionStats(attempts: 30, correct: 12),
      );
    },
  );

  // Six units, so a session can be restricted to a couple of them and still
  // leave plenty of deck outside the range for the readouts to count.
  final LearningDeck scopeDeck = LearningDeck(
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
      LearningUnit(
        categoryId: 0,
        fields: <int, FieldValue>{
          0: FieldValue.plain('vier'),
          1: FieldValue.plain('four'),
        },
      ),
      LearningUnit(
        categoryId: 0,
        fields: <int, FieldValue>{
          0: FieldValue.plain('fünf'),
          1: FieldValue.plain('five'),
        },
      ),
      LearningUnit(
        categoryId: 0,
        fields: <int, FieldValue>{
          0: FieldValue.plain('sechs'),
          1: FieldValue.plain('six'),
        },
      ),
    ],
  );

  testWidgets(
    'a range-restricted, single-direction session reads every pill as a deck '
    'total in that direction',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _DrillHarness(
          deck: scopeDeck,
          // Direction 1 across the deck: 9 attempts, 6 correct, with units 1 and
          // 3 above the mastery threshold. Direction 2 carries a further 12
          // attempts that this session must not count.
          statistics: const <UnitStats>[
            UnitStats(
              index: 1,
              direction1: DirectionStats(attempts: 4, correct: 3),
              direction2: DirectionStats(attempts: 5, correct: 5),
            ),
            UnitStats(
              index: 2,
              direction1: DirectionStats(attempts: 2),
            ),
            UnitStats(
              index: 3,
              direction1: DirectionStats(attempts: 3, correct: 3),
            ),
            UnitStats(
              index: 4,
              direction2: DirectionStats(attempts: 7, correct: 1),
            ),
          ],
          parameters: const SessionParameters(
            withInput: false,
            mode: SessionMode.onceThrough,
            directionSelection: DirectionSelection.direction1,
            startIndex: 1,
            endIndex: 2,
            shuffle: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start session'));
      await tester.pumpAndSettle();

      // The range holds two units; every pill still describes all six, and the
      // direction selection holds them all to direction 1.
      expect(find.text('Attempts: 9'), findsOneWidget);
      expect(find.text('Accuracy: 6/9 (67%)'), findsOneWidget);
      // Units 1 and 3 are mastered in direction 1; 2, 4, 5 and 6 are not.
      expect(find.text('Mastered: 2/6'), findsOneWidget);
      // Remaining adds what the range itself has left: unit 2 of units 1-2.
      expect(find.text('Remaining: 4 (1)'), findsOneWidget);
    },
  );

  testWidgets(
    "direction-2 statistics leave a direction-1 session's Attempts and "
    'Accuracy alone',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _DrillHarness(
          deck: scopeDeck,
          // A deck drilled hard in direction 2 and barely at all in direction 1.
          statistics: const <UnitStats>[
            UnitStats(
              index: 1,
              direction1: DirectionStats(attempts: 2, correct: 1),
              direction2: DirectionStats(attempts: 10, correct: 10),
            ),
            UnitStats(
              index: 2,
              direction2: DirectionStats(attempts: 4, correct: 4),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start session'));
      await tester.pumpAndSettle();

      // Direction 1 only: the 14 direction-2 attempts are not added in, so the
      // figures match the statistics screen's Direction 1 view.
      expect(find.text('Attempts: 2'), findsOneWidget);
      expect(find.text('Accuracy: 1/2 (50%)'), findsOneWidget);
    },
  );

  testWidgets(
    'widening the readouts leaves what the session serves untouched: only the '
    'unit range, only the chosen direction',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _DrillHarness(
          deck: scopeDeck,
          statistics: const <UnitStats>[],
          parameters: const SessionParameters(
            withInput: false,
            mode: SessionMode.onceThrough,
            directionSelection: DirectionSelection.direction1,
            startIndex: 3,
            endIndex: 4,
            shuffle: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start session'));
      await tester.pumpAndSettle();

      /// The header of the card on screen
      /// ("Unit 3/6 - Cat - A - Unit accuracy: …").
      String header() => tester
          .widgetList<Text>(find.textContaining('Unit '))
          .map((Text text) => text.data ?? '')
          .single;

      final List<String> served = <String>[];
      // Two items in scope; a third pass would mean the session had widened.
      for (var card = 0; card < 3; card += 1) {
        if (find.text('Extend session').evaluate().isNotEmpty) {
          break;
        }
        served.add(header());
        await tester.sendKeyEvent(LogicalKeyboardKey.f10);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Knew it'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }

      expect(served, hasLength(2));
      // Units 3 and 4 only — never 1, 2, 5 or 6 — and 'A' is the direction-1
      // label of the fixture mask, so direction 2 was never served either.
      expect(served.where((String h) => h.contains('Unit 3/6')), hasLength(1));
      expect(served.where((String h) => h.contains('Unit 4/6')), hasLength(1));
      for (final String head in served) {
        expect(head, contains(' - A - '));
        expect(head, isNot(contains(' - B - ')));
      }
      // With both in-scope items answered the session is over.
      expect(find.text('Extend session'), findsOneWidget);
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

  testWidgets(
    'Arrow Down/Up move focus between answer fields without wrapping',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates:
              LearnAnywhereLocalizations.localizationsDelegates,
          supportedLocales: LearnAnywhereLocalizations.supportedLocales,
          home: Scaffold(
            body: LearnSessionPage(
              deck: markerDeck,
              statistics: const <UnitStats>[],
              options: const DesktopQueryOptions(),
              parameters: const SessionParameters(
                withInput: true,
                mode: SessionMode.onceThrough,
                directionSelection: DirectionSelection.direction1,
                shuffle: false,
              ),
              onParametersChanged: (SessionParameters _) {},
              onStatisticsChanged: (List<UnitStats> _) {},
              onOpenEditor: () {},
              onExit: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start session'));
      await tester.pumpAndSettle();

      // French, Plural, Gender: three answer fields in direction 1.
      final Finder fields = find.byType(TextField);
      expect(fields, findsNWidgets(3));
      FocusNode nodeAt(int i) =>
          tester.widget<TextField>(fields.at(i)).focusNode!;

      // The first field claims focus as soon as the unit is served.
      expect(FocusManager.instance.primaryFocus, nodeAt(0));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, nodeAt(1));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, nodeAt(2));

      // Consumed at the last field: nothing changes.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, nodeAt(2));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, nodeAt(1));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, nodeAt(0));

      // Consumed at the first field: nothing changes.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, nodeAt(0));
    },
  );

  testWidgets(
    'the evaluation pills sit just after the action pills with a bigger '
    'gap between the groups than within a group, and drop to their own '
    'line — without splitting either group — once the window narrows',
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

      final Finder actionGroup = find.byKey(const Key('learnActionPillsGroup'));
      final Finder evalGroup = find.byKey(
        const Key('learnEvaluationPillsGroup'),
      );
      final Rect actionGroupRect = tester.getRect(actionGroup);
      final Rect evalGroupRect = tester.getRect(evalGroup);

      // Wide window: one line, action pills first, evaluation group after,
      // with a bigger gap between the groups than between pills within one.
      // The line is bottom-aligned: the evaluation group's caption stands
      // above its pills, which line up with the action pills.
      expect(actionGroupRect.bottom, evalGroupRect.bottom);
      expect(actionGroupRect.right, lessThan(evalGroupRect.left));

      // Compare whole-button edges (not text edges) so button padding/icons
      // don't skew the "gap within a group" measurement.
      final Rect continueButtonRect = tester.getRect(
        find.ancestor(
          of: find.text('Continue'),
          matching: find.byType(FilledButton),
        ),
      );
      final Rect cancelButtonRect = tester.getRect(
        find.ancestor(
          of: find.text('Cancel'),
          matching: find.byType(FilledButton),
        ),
      );
      final double withinGroupGap =
          cancelButtonRect.left - continueButtonRect.right;
      final double betweenGroupGap = evalGroupRect.left - actionGroupRect.right;
      expect(betweenGroupGap, greaterThan(withinGroupGap));

      // Narrow the window: the evaluation group must drop to its own line
      // without either group splitting, and no overflow may be raised
      // (pumpAndSettle throws on the classic overflow-stripes assertion).
      tester.view.physicalSize = const Size(750, 1000);
      await tester.pumpAndSettle();

      final Rect narrowActionGroupRect = tester.getRect(actionGroup);
      final Rect narrowEvalGroupRect = tester.getRect(evalGroup);
      // The evaluation group dropped below the action group entirely.
      expect(
        narrowEvalGroupRect.top,
        greaterThan(narrowActionGroupRect.bottom - 1),
      );
      // Each group still renders as a single, unsplit unit: its same-sized
      // pills share one line (a Row, unlike a Wrap, cannot itself break a
      // line mid-group).
      final Rect narrowContinueRect = tester.getRect(find.text('Continue'));
      final Rect narrowCancelRect = tester.getRect(find.text('Cancel'));
      expect(narrowContinueRect.top, narrowCancelRect.top);

      final Rect narrowF5Rect = tester.getRect(find.text('F5'));
      final Rect narrowF6Rect = tester.getRect(find.text('F6'));
      final Rect narrowF7Rect = tester.getRect(find.text('F7'));
      expect(narrowF5Rect.top, narrowF6Rect.top);
      expect(narrowF5Rect.top, narrowF7Rect.top);
      // The rating label lives in the same, single-line group as the pills.
      expect(find.text('Evaluate as:'), findsOneWidget);
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

  /// The lifetime record, accumulated exactly as the shell accumulates it.
  AllTimeStatistics allTime = AllTimeStatistics.empty;

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
          onAttemptRecorded: (RecordedAttempt attempt) {
            setState(() => allTime = allTime.record(attempt));
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
  const _DrillHarness({
    required this.deck,
    required this.statistics,
    this.allTime = AllTimeStatistics.empty,
    this.options = const DesktopQueryOptions(),
    this.parameters = const SessionParameters(
      withInput: false,
      mode: SessionMode.onceThrough,
      directionSelection: DirectionSelection.direction1,
      shuffle: false,
    ),
    this.onSessionActiveChanged,
  });

  final LearningDeck deck;
  final List<UnitStats> statistics;

  /// What the page reports to the shell as sessions start and end.
  final ValueChanged<bool>? onSessionActiveChanged;

  /// The deck's lifetime record as the shell holds it.
  final AllTimeStatistics allTime;

  /// Query options, so a test can switch the wrong-answer ceiling on.
  final DesktopQueryOptions options;

  /// The session's own scope — what it serves. The live readouts widen it to
  /// the whole deck themselves.
  final SessionParameters parameters;

  @override
  State<_DrillHarness> createState() => _DrillHarnessState();
}

class _DrillHarnessState extends State<_DrillHarness> {
  late List<UnitStats> _statistics = widget.statistics;

  /// The lifetime record, accumulated exactly as the shell accumulates it.
  late AllTimeStatistics allTime = widget.allTime;

  /// Mimics the shell opening another deck: statistics are replaced wholesale.
  void openDeck(List<UnitStats> statistics) {
    setState(() => _statistics = statistics);
  }

  /// The lifetime counters recorded for [unitIndex] in direction 1.
  DirectionStats allTimeDir1(int unitIndex) {
    return allTime.perUnit
            .where((UnitStats stats) => stats.index == unitIndex)
            .firstOrNull
            ?.direction1 ??
        const DirectionStats();
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
          options: widget.options,
          parameters: widget.parameters,
          onParametersChanged: (SessionParameters _) {},
          onStatisticsChanged: (List<UnitStats> value) {
            setState(() => _statistics = value);
          },
          onAttemptRecorded: (RecordedAttempt attempt) {
            setState(() => allTime = allTime.record(attempt));
          },
          onSessionActiveChanged: widget.onSessionActiveChanged,
          onOpenEditor: () {},
          onExit: () {},
        ),
      ),
    );
  }
}
