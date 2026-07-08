import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_desktop/src/editor/unit_editor_page.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

void main() {
  const LearningMask mask = LearningMask(
    maskId: 'm_new_unit-editor-fixture',
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
        ],
      ),
    ],
  );

  testWidgets(
    'deleting the last unit leaves the empty editor focusable '
    '(Enter still opens the category chooser)',
    (WidgetTester tester) async {
      LearningDeck deck = const LearningDeck(
        mask: mask,
        units: <LearningUnit>[
          LearningUnit(
            categoryId: 0,
            fields: <int, FieldValue>{0: FieldValue.plain('only')},
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates:
              LearnAnywhereLocalizations.localizationsDelegates,
          supportedLocales: LearnAnywhereLocalizations.supportedLocales,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return UnitEditorPage(
                  deck: deck,
                  onChanged: (LearningDeck value, {int? insertedAt, int? deletedAt}) {
                    setState(() => deck = value);
                  },
                  onDone: () {},
                  onCancel: () {},
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.f7);
      await tester.pumpAndSettle();
      expect(find.text('Please confirm'), findsOneWidget);

      final Finder confirmDialog = find.byType(AlertDialog);
      await tester.tap(
        find.descendant(of: confirmDialog, matching: find.text('Delete')),
      );
      await tester.pumpAndSettle();

      expect(find.text('No learning units'), findsOneWidget);

      // The empty state has no focusable widget of its own; Enter must
      // still reach the page's root Shortcuts and open the category
      // chooser (the _EnterIntent -> _appendUnit() flow).
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Choose category'), findsOneWidget);
    },
  );
}
