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
    'F12 reports the current unit\'s one-based position, and the badge '
    'follows the flag on navigation',
    (WidgetTester tester) async {
      LearningDeck deck = LearningDeck(
        mask: mask,
        units: const <LearningUnit>[
          LearningUnit(
            categoryId: 0,
            fields: <int, FieldValue>{0: FieldValue.plain('one')},
          ),
          LearningUnit(
            categoryId: 0,
            fields: <int, FieldValue>{0: FieldValue.plain('two')},
            direction1Flags: DifficultFlags(manual: true),
          ),
        ],
      );
      final List<(int, QueryDirection)> toggled = <(int, QueryDirection)>[];
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
                  onToggleDifficult:
                      (int unitIndex, QueryDirection direction) {
                        toggled.add((unitIndex, direction));
                        setState(
                          () => deck = toggleDifficultAt(
                            deck,
                            unitIndex,
                            direction,
                          ),
                        );
                      },
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // First unit carries no flag.
      expect(find.byTooltip('Manual flag'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.f3);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Manual flag'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await tester.pumpAndSettle();
      // F12 acts on Direction 1 in the editor.
      expect(toggled, <(int, QueryDirection)>[(2, QueryDirection.direction1)]);
      expect(find.byTooltip('Manual flag'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Manual flag'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await tester.pumpAndSettle();
      expect(toggled, <(int, QueryDirection)>[
        (2, QueryDirection.direction1),
        (1, QueryDirection.direction1),
      ]);
      expect(find.byTooltip('Manual flag'), findsOneWidget);
    },
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
                  onToggleDifficult: (int _, QueryDirection _) {},
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

  testWidgets(
    'Text color stores text1 on the selection and removes it when pressed '
    'again, drawing its icon in the theme\'s colour',
    (WidgetTester tester) async {
      final ThemeData theme = LearnAnywhereTheme.darkBlue();
      LearningDeck deck = const LearningDeck(
        mask: mask,
        units: <LearningUnit>[
          LearningUnit(
            categoryId: 0,
            fields: <int, FieldValue>{0: FieldValue.plain('bonjour')},
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          localizationsDelegates:
              LearnAnywhereLocalizations.localizationsDelegates,
          supportedLocales: LearnAnywhereLocalizations.supportedLocales,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return UnitEditorPage(
                  deck: deck,
                  onChanged:
                      (LearningDeck value, {int? insertedAt, int? deletedAt}) {
                        setState(() => deck = value);
                      },
                  onDone: () {},
                  onCancel: () {},
                  onToggleDifficult: (int _, QueryDirection _) {},
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Color text1 = theme.extension<LearnAnywhereFormatColours>()!.text1;
      expect(
        tester.widget<Icon>(find.byIcon(Icons.format_color_text)).color,
        text1,
      );

      tester
          .widget<EditableText>(find.byType(EditableText))
          .controller
          .selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 3,
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Text color'));
      await tester.pumpAndSettle();
      expect(
        deck.units.single.valueForFieldId(0),
        FieldValue.rich(<RichTextRun>[
          const RichTextRun(text: 'bon', color: TextColourToken.text1),
          const RichTextRun(text: 'jour'),
        ]),
      );
      expect(
        tester
            .widget<IconButton>(
              find.ancestor(
                of: find.byIcon(Icons.format_color_text),
                matching: find.byType(IconButton),
              ),
            )
            .isSelected,
        isTrue,
      );

      await tester.tap(find.byTooltip('Text color'));
      await tester.pumpAndSettle();
      expect(
        deck.units.single.valueForFieldId(0),
        const FieldValue.plain('bonjour'),
      );
    },
  );

  testWidgets(
    'Highlight stores highlight1 on the selection and removes it when pressed '
    'again, drawing its icon in the theme\'s highlight',
    (WidgetTester tester) async {
      final ThemeData theme = LearnAnywhereTheme.light();
      LearningDeck deck = const LearningDeck(
        mask: mask,
        units: <LearningUnit>[
          LearningUnit(
            categoryId: 0,
            fields: <int, FieldValue>{0: FieldValue.plain('bonjour')},
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          localizationsDelegates:
              LearnAnywhereLocalizations.localizationsDelegates,
          supportedLocales: LearnAnywhereLocalizations.supportedLocales,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return UnitEditorPage(
                  deck: deck,
                  onChanged:
                      (LearningDeck value, {int? insertedAt, int? deletedAt}) {
                        setState(() => deck = value);
                      },
                  onDone: () {},
                  onCancel: () {},
                  onToggleDifficult: (int _, QueryDirection _) {},
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Color highlight1 = theme
          .extension<LearnAnywhereFormatColours>()!
          .highlight1;
      expect(
        tester.widget<Icon>(find.byIcon(Icons.format_color_fill)).color,
        highlight1,
      );

      tester
          .widget<EditableText>(find.byType(EditableText))
          .controller
          .selection = const TextSelection(
        baseOffset: 3,
        extentOffset: 7,
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Highlight'));
      await tester.pumpAndSettle();
      expect(
        deck.units.single.valueForFieldId(0),
        FieldValue.rich(<RichTextRun>[
          const RichTextRun(text: 'bon'),
          const RichTextRun(
            text: 'jour',
            highlight: HighlightToken.highlight1,
          ),
        ]),
      );
      expect(
        tester
            .widget<IconButton>(
              find.ancestor(
                of: find.byIcon(Icons.format_color_fill),
                matching: find.byType(IconButton),
              ),
            )
            .isSelected,
        isTrue,
      );

      await tester.tap(find.byTooltip('Highlight'));
      await tester.pumpAndSettle();
      expect(
        deck.units.single.valueForFieldId(0),
        const FieldValue.plain('bonjour'),
      );
    },
  );

  testWidgets(
    'field value containers render with the BUNDLED monospace family',
    (WidgetTester tester) async {
      // The PRD's fixed-width containers size themselves by measuring one
      // character, so they must not fall back to a host font: Consolas and
      // Cascadia Mono do not exist on Linux, and a generic "monospace" request
      // can resolve to a PROPORTIONAL face. Assert the concrete family reaches
      // the rendered field, not just that a fallback list was supplied.
      const LearningDeck deck = LearningDeck(
        mask: mask,
        units: <LearningUnit>[
          LearningUnit(
            categoryId: 0,
            fields: <int, FieldValue>{0: FieldValue.plain('bonjour')},
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates:
              LearnAnywhereLocalizations.localizationsDelegates,
          supportedLocales: LearnAnywhereLocalizations.supportedLocales,
          home: Scaffold(
            body: UnitEditorPage(
              deck: deck,
              onChanged:
                  (LearningDeck value, {int? insertedAt, int? deletedAt}) {},
              onDone: () {},
              onCancel: () {},
              onToggleDifficult: (int _, QueryDirection _) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Finder fieldRow = find.byType(FieldRow);
      expect(fieldRow, findsWidgets);
      final Finder valueField = find.descendant(
        of: fieldRow.first,
        matching: find.byType(EditableText),
      );
      expect(valueField, findsOneWidget);
      final EditableText editable = tester.widget<EditableText>(valueField);
      expect(
        editable.style.fontFamily,
        LearnAnywhereTokens.monospaceFamily,
        reason: 'the value column must use the ui_kit-bundled Lab Mono',
      );
      expect(
        editable.style.fontFamilyFallback,
        LearnAnywhereTokens.monospaceFallback,
      );
    },
  );
}
