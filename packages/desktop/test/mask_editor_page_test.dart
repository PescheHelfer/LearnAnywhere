import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_desktop/src/mask_editor/mask_editor_page.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

void main() {
  testWidgets(
    'switching categories shows the target category fields, not stale ones',
    (WidgetTester tester) async {
      // Category 1 has fewer fields than category 2. The classic bug is that
      // the smaller category's index-keyed text controllers get reused for the
      // larger category's first rows, scrambling its displayed fields.
      const LearningMask mask = LearningMask(
        maskId: 'm_new_mask-editor-fixture',
        name: 'Französisch',
        direction1Label: 'De -> Fr',
        direction2Label: 'Fr -> De',
        categories: <CategoryDefinition>[
          CategoryDefinition(
            id: 1,
            name: 'Einzeiler',
            fields: <FieldDefinition>[
              FieldDefinition(
                id: 0,
                name: 'Deutsch',
                length: 60,
                equalGroup: 0,
                role1: FieldRole.question,
                role2: FieldRole.answer,
              ),
              FieldDefinition(
                id: 1,
                name: 'Franz',
                length: 60,
                equalGroup: 0,
                role1: FieldRole.answer,
                role2: FieldRole.question,
              ),
            ],
          ),
          CategoryDefinition(
            id: 2,
            name: 'Zweizeiler',
            fields: <FieldDefinition>[
              FieldDefinition(
                id: 2,
                name: 'Deutsch 1',
                length: 60,
                equalGroup: 1,
                role1: FieldRole.question,
                role2: FieldRole.answer,
              ),
              FieldDefinition(
                id: 3,
                name: 'Deutsch 2',
                length: 60,
                equalGroup: 1,
                role1: FieldRole.question,
                role2: FieldRole.answer,
              ),
              FieldDefinition(
                id: 4,
                name: 'Franz 1',
                length: 60,
                equalGroup: 2,
                role1: FieldRole.answer,
                role2: FieldRole.question,
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates:
              LearnAnywhereLocalizations.localizationsDelegates,
          supportedLocales: LearnAnywhereLocalizations.supportedLocales,
          home: Scaffold(
            body: MaskEditorPage(mask: mask, onChanged: (LearningMask _) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Category 1 is selected first, seeding its field controllers.
      expect(fieldName(tester, 1, 0), 'Deutsch');
      expect(fieldName(tester, 1, 1), 'Franz');

      // Switch to category 2 and confirm every visible field is its own.
      await tester.tap(find.text('Zweizeiler'));
      await tester.pumpAndSettle();

      expect(fieldName(tester, 2, 0), 'Deutsch 1');
      expect(fieldName(tester, 2, 1), 'Deutsch 2');
      expect(fieldName(tester, 2, 2), 'Franz 1');
      expect(fieldLength(tester, 2, 0), '60');
      expect(fieldEqualGroup(tester, 2, 0), '1');

      // Switch back to category 1 and confirm it is still intact.
      await tester.tap(find.text('Einzeiler'));
      await tester.pumpAndSettle();
      expect(fieldName(tester, 1, 0), 'Deutsch');
      expect(fieldName(tester, 1, 1), 'Franz');
    },
  );

  testWidgets('close button and Enter both invoke onClose', (
    WidgetTester tester,
  ) async {
    const LearningMask mask = LearningMask(
      maskId: 'm_new_mask-editor-empty-fixture',
      name: 'Französisch',
      direction1Label: 'De -> Fr',
      direction2Label: 'Fr -> De',
      categories: <CategoryDefinition>[
        CategoryDefinition(id: 1, name: 'Einzeiler', fields: <FieldDefinition>[]),
      ],
    );
    var closeCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates:
            LearnAnywhereLocalizations.localizationsDelegates,
        supportedLocales: LearnAnywhereLocalizations.supportedLocales,
        home: Scaffold(
          body: MaskEditorPage(
            mask: mask,
            onChanged: (LearningMask _) {},
            onClose: () => closeCount += 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('mask-editor-close-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('mask-editor-close-button')),
    );
    await tester.pumpAndSettle();
    expect(closeCount, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(closeCount, 2);
  });

  testWidgets('reordering categories and fields swaps order, keeps ids', (
    WidgetTester tester,
  ) async {
    const LearningMask mask = LearningMask(
      maskId: 'm_new_reorder-fixture',
      name: 'Reorder',
      direction1Label: 'A',
      direction2Label: 'B',
      categories: <CategoryDefinition>[
        CategoryDefinition(
          id: 1,
          name: 'First',
          fields: <FieldDefinition>[
            FieldDefinition(
              id: 0,
              name: 'Alpha',
              length: 40,
              equalGroup: 0,
              role1: FieldRole.question,
              role2: FieldRole.answer,
            ),
            FieldDefinition(
              id: 1,
              name: 'Beta',
              length: 40,
              equalGroup: 0,
              role1: FieldRole.answer,
              role2: FieldRole.question,
            ),
          ],
        ),
        CategoryDefinition(id: 2, name: 'Second', fields: <FieldDefinition>[]),
      ],
    );
    LearningMask emitted = mask;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates:
            LearnAnywhereLocalizations.localizationsDelegates,
        supportedLocales: LearnAnywhereLocalizations.supportedLocales,
        home: Scaffold(
          // Feed edits back into the page like the app does, so the editor
          // rebuilds against the reordered mask.
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return MaskEditorPage(
                mask: emitted,
                onChanged: (LearningMask value) =>
                    setState(() => emitted = value),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Move the first category (id 1) down: order becomes [id 2, id 1].
    await tester.tap(
      find.byKey(const ValueKey<String>('category-move-down-1')),
    );
    await tester.pumpAndSettle();
    expect(
      emitted.categories.map((CategoryDefinition c) => c.id),
      <int>[2, 1],
    );

    // Move field "Alpha" (id 0) down within its category: order [id 1, id 0].
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('field-move-down-1-0')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('field-move-down-1-0')),
    );
    await tester.pumpAndSettle();
    final CategoryDefinition edited = emitted.categories.firstWhere(
      (CategoryDefinition c) => c.id == 1,
    );
    expect(edited.fields.map((FieldDefinition f) => f.id), <int>[1, 0]);
    // Names/ids preserved — only order changed.
    expect(edited.fields.map((FieldDefinition f) => f.name), <String>[
      'Beta',
      'Alpha',
    ]);
  });

  testWidgets('deleting a category does not recycle its id on the next add', (
    WidgetTester tester,
  ) async {
    const LearningMask mask = LearningMask(
      maskId: 'm_new_id-reuse-fixture',
      name: 'Ids',
      direction1Label: 'A',
      direction2Label: 'B',
      categories: <CategoryDefinition>[
        CategoryDefinition(id: 0, name: 'C0', fields: <FieldDefinition>[]),
        CategoryDefinition(id: 1, name: 'C1', fields: <FieldDefinition>[]),
        CategoryDefinition(id: 2, name: 'C2', fields: <FieldDefinition>[]),
      ],
    );
    LearningMask emitted = mask;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates:
            LearnAnywhereLocalizations.localizationsDelegates,
        supportedLocales: LearnAnywhereLocalizations.supportedLocales,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return MaskEditorPage(
                mask: emitted,
                onChanged: (LearningMask value) =>
                    setState(() => emitted = value),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Delete the middle category (id 1).
    await tester.tap(
      find.byKey(const ValueKey<String>('category-delete-1')),
    );
    await tester.pumpAndSettle();
    expect(emitted.categories.map((CategoryDefinition c) => c.id), <int>[0, 2]);

    // Adding a new category takes the next unused id (max + 1 = 3), never the
    // freed id 1.
    await tester.tap(
      find.byKey(const ValueKey<String>('add-category-button')),
    );
    await tester.pumpAndSettle();
    expect(
      emitted.categories.map((CategoryDefinition c) => c.id),
      <int>[0, 2, 3],
    );
  });
}

// Reads the text actually rendered in a field cell (its internal controller),
// not the widget's `initialValue`. The scramble bug lives in the controller,
// which keeps a stale value while `initialValue` still reads correct.
String _cellText(WidgetTester tester, String key) {
  final Finder editable = find.descendant(
    of: find.byKey(ValueKey<String>(key)),
    matching: find.byType(EditableText),
  );
  return tester.widget<EditableText>(editable).controller.text;
}

String fieldName(WidgetTester tester, int categoryId, int index) {
  return _cellText(tester, 'field-name-$categoryId-$index');
}

String fieldLength(WidgetTester tester, int categoryId, int index) {
  return _cellText(tester, 'field-length-$categoryId-$index');
}

String fieldEqualGroup(WidgetTester tester, int categoryId, int index) {
  return _cellText(tester, 'field-equal-group-$categoryId-$index');
}
