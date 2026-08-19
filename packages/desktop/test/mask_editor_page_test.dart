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

      expect(fieldName(tester, 2, 2), 'Deutsch 1');
      expect(fieldName(tester, 2, 3), 'Deutsch 2');
      expect(fieldName(tester, 2, 4), 'Franz 1');
      expect(fieldLength(tester, 2, 2), '60');
      expect(fieldEqualGroup(tester, 2, 2), '1');

      // Switch back to category 1 and confirm it is still intact.
      await tester.tap(find.text('Einzeiler'));
      await tester.pumpAndSettle();
      expect(fieldName(tester, 1, 0), 'Deutsch');
      expect(fieldName(tester, 1, 1), 'Franz');
    },
  );

  testWidgets('OK button and Enter both invoke onClose', (
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
      find.byKey(const ValueKey<String>('mask-editor-ok-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('mask-editor-ok-button')),
    );
    await tester.pumpAndSettle();
    expect(closeCount, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(closeCount, 2);
  });

  testWidgets('cancel button appears with onCancel and invokes the callback', (
    WidgetTester tester,
  ) async {
    const LearningMask mask = LearningMask(
      maskId: 'm_new_mask-editor-cancel-fixture',
      name: 'Französisch',
      direction1Label: 'De -> Fr',
      direction2Label: 'Fr -> De',
      categories: <CategoryDefinition>[],
    );
    var cancelCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates:
            LearnAnywhereLocalizations.localizationsDelegates,
        supportedLocales: LearnAnywhereLocalizations.supportedLocales,
        home: Scaffold(
          body: MaskEditorPage(
            mask: mask,
            onChanged: (LearningMask _) {},
            onClose: () {},
            onCancel: () => cancelCount += 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('mask-editor-cancel-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('mask-editor-cancel-button')),
    );
    await tester.pumpAndSettle();
    expect(cancelCount, 1);
  });

  testWidgets('adding a field defaults its length to 80', (
    WidgetTester tester,
  ) async {
    const LearningMask mask = LearningMask(
      maskId: 'm_new_add-field-fixture',
      name: 'AddField',
      direction1Label: 'A',
      direction2Label: 'B',
      categories: <CategoryDefinition>[
        CategoryDefinition(id: 0, name: 'C0', fields: <FieldDefinition>[]),
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

    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('add-field-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('add-field-button')));
    await tester.pumpAndSettle();

    expect(emitted.categories.single.fields.single.length, 80);
  });

  testWidgets(
    'shows the linked .inf path, or an unsaved indicator when null',
    (WidgetTester tester) async {
      const LearningMask mask = LearningMask(
        maskId: 'm_new_linked-path-fixture',
        name: 'Linked',
        direction1Label: 'A',
        direction2Label: 'B',
        categories: <CategoryDefinition>[],
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates:
              LearnAnywhereLocalizations.localizationsDelegates,
          supportedLocales: LearnAnywhereLocalizations.supportedLocales,
          home: Scaffold(
            body: MaskEditorPage(
              mask: mask,
              onChanged: (LearningMask _) {},
              linkedPath: 'C:/decks/french.inf',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('C:/decks/french.inf'), findsOneWidget);

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
      expect(find.text('Not yet saved to a mask file'), findsOneWidget);
    },
  );

  testWidgets('fork button appears with onFork and invokes the callback', (
    WidgetTester tester,
  ) async {
    const LearningMask mask = LearningMask(
      maskId: 'm_new_fork-fixture',
      name: 'Fork',
      direction1Label: 'A',
      direction2Label: 'B',
      categories: <CategoryDefinition>[],
    );
    var forkCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates:
            LearnAnywhereLocalizations.localizationsDelegates,
        supportedLocales: LearnAnywhereLocalizations.supportedLocales,
        home: Scaffold(
          body: MaskEditorPage(
            mask: mask,
            onChanged: (LearningMask _) {},
            onClose: () {},
            onFork: () => forkCount += 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('mask-editor-fork-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('mask-editor-fork-button')),
    );
    await tester.pumpAndSettle();
    expect(forkCount, 1);
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
              equalGroup: 1,
              role1: FieldRole.question,
              role2: FieldRole.answer,
            ),
            FieldDefinition(
              id: 1,
              name: 'Beta',
              length: 55,
              equalGroup: 2,
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

    // The row on screen must describe the field it now belongs to: every
    // column moves with the field, read through the cell's own editing
    // controller — not merely asserted against the emitted mask above. This
    // is the layer the original bug lived in (stale, position-keyed
    // controllers left every column but the roles showing the old field).
    expect(fieldNameAtRow(tester, 0), 'Beta');
    expect(fieldLengthAtRow(tester, 0), '55');
    expect(fieldEqualGroupAtRow(tester, 0), '2');
    expect(fieldNameAtRow(tester, 1), 'Alpha');
    expect(fieldLengthAtRow(tester, 1), '40');
    expect(fieldEqualGroupAtRow(tester, 1), '1');
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

  testWidgets(
    'cloning a category inserts a copy after it, selects it, and mints '
    'fresh field ids as one contiguous run',
    (WidgetTester tester) async {
      // Field ids 0/1 belong to the source category; the OTHER category (id
      // 5, chosen non-contiguous on purpose) has no fields at all. If the
      // clone re-derived "the next id" once per field against the
      // unmodified mask, both cloned fields would collide on id 2 instead
      // of landing on 2 and 3.
      const LearningMask mask = LearningMask(
        maskId: 'm_new_clone-fixture',
        name: 'Clone',
        direction1Label: 'A',
        direction2Label: 'B',
        categories: <CategoryDefinition>[
          CategoryDefinition(
            id: 0,
            name: 'First',
            fields: <FieldDefinition>[
              FieldDefinition(
                id: 0,
                name: 'Alpha',
                length: 40,
                equalGroup: 1,
                role1: FieldRole.question,
                role2: FieldRole.answer,
              ),
              FieldDefinition(
                id: 1,
                name: 'Beta',
                length: 55,
                equalGroup: 2,
                role1: FieldRole.answer,
                role2: FieldRole.question,
              ),
            ],
          ),
          CategoryDefinition(id: 5, name: 'Other', fields: <FieldDefinition>[]),
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

      await tester.tap(find.byKey(const ValueKey<String>('category-clone-0')));
      await tester.pumpAndSettle();

      expect(
        emitted.categories.map((CategoryDefinition c) => c.id),
        <int>[0, 6, 5],
      );
      final CategoryDefinition clone = emitted.categories[1];
      expect(clone.name, 'First (copy)');
      expect(clone.fields.map((FieldDefinition f) => f.id), <int>[2, 3]);
      expect(clone.fields.map((FieldDefinition f) => f.name), <String>[
        'Alpha',
        'Beta',
      ]);
      expect(clone.fields.map((FieldDefinition f) => f.length), <int>[40, 55]);
      // The source category is untouched.
      expect(
        emitted.categories.first.fields.map((FieldDefinition f) => f.id),
        <int>[0, 1],
      );

      // The clone is selected immediately, so it can be renamed straight
      // away — read through the category-name field's own controller.
      final Finder cloneNameField = find.descendant(
        of: find.byKey(const ValueKey<String>('category-name-6')),
        matching: find.byType(EditableText),
      );
      expect(
        tester.widget<EditableText>(cloneNameField).controller.text,
        'First (copy)',
      );
    },
  );

  testWidgets('cloning a long-named category clamps the copy name to 40 characters', (
    WidgetTester tester,
  ) async {
    // 38 chars: legal on its own (the rename field's cap is 40), but "{name}
    // (copy)" would run to 45 without clamping.
    const String longName = 'ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLM';
    const LearningMask mask = LearningMask(
      maskId: 'm_new_clone-long-name-fixture',
      name: 'LongName',
      direction1Label: 'A',
      direction2Label: 'B',
      categories: <CategoryDefinition>[
        CategoryDefinition(id: 0, name: longName, fields: <FieldDefinition>[]),
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

    await tester.tap(find.byKey(const ValueKey<String>('category-clone-0')));
    await tester.pumpAndSettle();

    final CategoryDefinition clone = emitted.categories[1];
    expect(clone.name.length, lessThanOrEqualTo(maxCategoryNameLength));
  });

  testWidgets('clone is unavailable at the category limit, exactly as add is', (
    WidgetTester tester,
  ) async {
    final LearningMask mask = LearningMask(
      maskId: 'm_new_clone-limit-fixture',
      name: 'ClonedLimit',
      direction1Label: 'A',
      direction2Label: 'B',
      categories: List<CategoryDefinition>.generate(
        maxCategoriesPerMask,
        (int i) => CategoryDefinition(
          id: i,
          name: 'C$i',
          fields: const <FieldDefinition>[],
        ),
      ),
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

    final FilledButton addButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey<String>('add-category-button')),
    );
    final IconButton cloneButton = tester.widget<IconButton>(
      find.byKey(const ValueKey<String>('category-clone-0')),
    );
    expect(addButton.onPressed, isNull);
    expect(cloneButton.onPressed, isNull);
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

// Field cells are keyed by the field's own stable id, not its position — see
// the production comment in `_fieldRow`. Callers pass that id, not an index.
String fieldName(WidgetTester tester, int categoryId, int fieldId) {
  return _cellText(tester, 'field-name-$categoryId-$fieldId');
}

String fieldLength(WidgetTester tester, int categoryId, int fieldId) {
  return _cellText(tester, 'field-length-$categoryId-$fieldId');
}

String fieldEqualGroup(WidgetTester tester, int categoryId, int fieldId) {
  return _cellText(tester, 'field-equal-group-$categoryId-$fieldId');
}

// Reads the text actually rendered at a given VISUAL row/column position in
// the fields DataTable, independent of whatever key scheme the rows use. This
// is what catches a regression to position-keyed controllers: a stale
// controller still renders under some key, but it never renders at the right
// row position once the underlying field there has changed.
String _fieldCellAtRow(WidgetTester tester, int rowIndex, int columnOffset) {
  final Iterable<EditableText> editors = tester.widgetList<EditableText>(
    find.descendant(
      of: find.byType(DataTable),
      matching: find.byType(EditableText),
    ),
  );
  // Three text columns per row: name, length, equal-group (role columns are
  // dropdowns, not EditableText).
  return editors.elementAt(rowIndex * 3 + columnOffset).controller.text;
}

String fieldNameAtRow(WidgetTester tester, int rowIndex) =>
    _fieldCellAtRow(tester, rowIndex, 0);

String fieldLengthAtRow(WidgetTester tester, int rowIndex) =>
    _fieldCellAtRow(tester, rowIndex, 1);

String fieldEqualGroupAtRow(WidgetTester tester, int rowIndex) =>
    _fieldCellAtRow(tester, rowIndex, 2);
