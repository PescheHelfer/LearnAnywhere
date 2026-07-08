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

  Widget buildPage({required VoidCallback onExit}) {
    return MaterialApp(
      localizationsDelegates: LearnAnywhereLocalizations.localizationsDelegates,
      supportedLocales: LearnAnywhereLocalizations.supportedLocales,
      home: Scaffold(
        body: LearnSessionPage(
          deck: deck,
          statistics: const <UnitStats>[],
          options: const DesktopQueryOptions(),
          parameters: const SessionParameters(
            withInput: false,
            mode: SessionMode.onceThrough,
            directionSelection: DirectionSelection.direction1,
            shuffle: false,
          ),
          sessionAttempts: 0,
          sessionCorrect: 0,
          onParametersChanged: (SessionParameters _) {},
          onStatisticsChanged: (List<UnitStats> _) {},
          onSessionProgressChanged: (int _, int __) {},
          onOpenEditor: () {},
          onExit: onExit,
        ),
      ),
    );
  }

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
}
