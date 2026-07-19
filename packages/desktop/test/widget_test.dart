import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_desktop/main.dart';
import 'package:learn_anywhere_desktop/src/preferences/desktop_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late DesktopPrefs prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = DesktopPrefs(await SharedPreferences.getInstance());
  });

  testWidgets('desktop shell launches with navigation chrome', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(LearnAnywhereDesktopApp(prefs: prefs));
    await tester.pumpAndSettle();

    expect(find.text('Learn Anywhere'), findsOneWidget);
    expect(find.text('Workspace'), findsOneWidget);
    expect(find.text('No file loaded'), findsOneWidget);
    expect(find.text('File'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Options'), findsOneWidget);
  });

  testWidgets('desktop shell routes from top-level menu buttons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(LearnAnywhereDesktopApp(prefs: prefs));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mask Editor').last);
    await tester.pumpAndSettle();

    expect(find.text('Mask Editor'), findsWidgets);
    expect(find.text('Mask name'), findsOneWidget);
    expect(find.text('Direction 1 label'), findsOneWidget);
    expect(find.text('Direction 2 label'), findsOneWidget);
    expect(find.text('Categories: 1/20'), findsOneWidget);
    expect(find.text('Fields: 3/20'), findsOneWidget);
  });

  testWidgets('help about shows legacy and conversion credits', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(LearnAnywhereDesktopApp(prefs: prefs));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Help'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    expect(find.text('About'), findsWidgets);
    expect(find.textContaining('Lern PC plus'), findsWidgets);
    expect(
      find.textContaining('Ulrich Veigel Softwareservice'),
      findsOneWidget,
    );
    expect(find.textContaining('SbitFire Software'), findsOneWidget);
    expect(find.text('Version history'), findsOneWidget);
  });

  testWidgets('editor inserts units and edits length-limited fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(LearnAnywhereDesktopApp(prefs: prefs));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unit editor').last);
    await tester.pumpAndSettle();

    expect(find.text('No learning units'), findsOneWidget);
    await tester.tap(find.text('Insert unit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Category 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Unit 1 of 1 - Category 1'), findsOneWidget);
    expect(find.text('Question'), findsOneWidget);
    expect(find.text('Answer'), findsOneWidget);

    await tester.tap(find.byTooltip('Bold').first);
    await tester.enterText(
      editorInput('Question'),
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
    );
    await tester.pumpAndSettle();

    expect(
      find.text('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMN'),
      findsOneWidget,
    );
    expect(
      find.text('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'),
      findsNothing,
    );
  });

  testWidgets('editor search shows selectable all-match results', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(LearnAnywhereDesktopApp(prefs: prefs));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unit editor').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Insert unit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Category 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(
      editorInput('Question'),
      'rabbit',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Category 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(
      editorInput('Question'),
      'turtle',
    );
    await tester.pumpAndSettle();

    expect(find.text('Unit 2 of 2 - Category 1'), findsOneWidget);
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'rabbit');
    await tester.tap(find.text('Search').last);
    await tester.pumpAndSettle();

    expect(find.text('Search results'), findsOneWidget);
    expect(find.text('Unit 1 of 2 - Category 1'), findsOneWidget);
    expect(find.text('Question'), findsWidgets);
    await tester.tap(find.text('Unit 1 of 2 - Category 1'));
    await tester.pumpAndSettle();

    expect(find.text('Unit 1 of 2 - Category 1'), findsOneWidget);
  });

  testWidgets('query options route exposes learning toggles', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(LearnAnywhereDesktopApp(prefs: prefs));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Advanced Learning Options').last);
    await tester.pumpAndSettle();

    expect(find.text('Advanced Learning Options'), findsWidgets);
    expect(find.text('Wrong input correctable'), findsOneWidget);
    expect(find.text('Complete input required'), findsOneWidget);
    expect(find.text('Case sensitive'), findsOneWidget);
    expect(find.text('Accent sensitive'), findsOneWidget);

    await tester.tap(find.text('Accent sensitive'));
    await tester.pumpAndSettle();

    expect(find.text('Accent sensitive'), findsOneWidget);
  });

  testWidgets('learn session checks answers and records live accuracy', (
    WidgetTester tester,
  ) async {
    // The active practice grid is wider than the default 800px test surface,
    // so give it room to lay out without a RenderFlex overflow.
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(LearnAnywhereDesktopApp(prefs: prefs));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unit editor').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Insert unit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Category 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(
      editorInput('Question'),
      'hello',
    );
    await tester.enterText(
      editorInput('Answer'),
      'bonjour',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(MenuItemButton, 'Learn'));
    await tester.pumpAndSettle();
    expect(find.text('Practice setup'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start session'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Unit 1/1 - Category 1'), findsOneWidget);
    // Before Check, the prompt is read-only rich text and the single answer
    // cell is the only editable field, so target it by type.
    if (tester.any(find.text('hello', findRichText: true))) {
      await tester.enterText(find.byType(TextField).first, 'bonjour');
    } else {
      expect(find.text('bonjour', findRichText: true), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'hello');
    }
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Check'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();

    expect(
      find.text('Your answer is correct. Congratulations!'),
      findsOneWidget,
    );
    expect(find.text('Correct'), findsOneWidget);
    await tester.ensureVisible(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Accuracy: 1/1 (100%)'), findsOneWidget);
    expect(find.text('Attempts: 1'), findsOneWidget);
  });

  testWidgets('mask editor edits mask metadata and adds schema items', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(LearnAnywhereDesktopApp(prefs: prefs));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mask Editor').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('mask-name-field')),
      'Spanish verbs',
    );
    await tester.pumpAndSettle();
    expect(find.text('Spanish verbs'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('add-category-button')));
    await tester.pumpAndSettle();
    expect(find.text('Categories: 2/20'), findsOneWidget);
    expect(find.text('Category 2'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('add-field-button')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('add-field-button')));
    await tester.pumpAndSettle();
    expect(find.text('Fields: 1/20'), findsOneWidget);
  });

  testWidgets(
    'file menu clear units asks for confirmation then a mask choice',
    (WidgetTester tester) async {
      await tester.pumpWidget(LearnAnywhereDesktopApp(prefs: prefs));
      await tester.pumpAndSettle();

      await tester.tap(find.text('File'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear units from memory...'));
      await tester.pumpAndSettle();

      expect(find.text('Please confirm'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // B1: File->New no longer silently carries the current mask over; it
      // asks whether to load an existing mask or mint a brand-new one.
      expect(find.text('New deck: choose a mask'), findsOneWidget);
      await tester.tap(find.text('Create new mask'));
      await tester.pumpAndSettle();

      expect(find.text('Mask Editor'), findsWidgets);
      // A fresh mask has no linked file yet (B6).
      expect(find.text('Not yet saved to a mask file'), findsOneWidget);
    },
  );

  testWidgets('desktop shell switches language at runtime', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(LearnAnywhereDesktopApp(prefs: prefs));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('German'));
    await tester.pumpAndSettle();

    expect(find.text('Datei'), findsOneWidget);
    expect(find.text('Arbeitsbereich'), findsOneWidget);
    expect(find.text('Keine Datei geladen'), findsOneWidget);
  });
}

/// Finds the editable [TextField] for the grid-editor field named [fieldName].
///
/// Each editor row is a `_GridRow` keyed `editor-field-<unit>-<i>-<name>`; the
/// inner [TextField] has no key of its own, so we locate the row by the stable
/// name suffix and drill into it.
Finder editorInput(String fieldName) {
  return find.descendant(
    of: find.byWidgetPredicate(
      (Widget widget) =>
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith('editor-field-') &&
          (widget.key! as ValueKey<String>).value.endsWith('-$fieldName'),
    ),
    matching: find.byType(TextField),
  );
}
