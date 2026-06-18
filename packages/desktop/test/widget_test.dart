import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_desktop/main.dart';

void main() {
  testWidgets('desktop shell launches with navigation chrome', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LearnAnywhereDesktopApp());
    await tester.pumpAndSettle();

    expect(find.text('Learn Anywhere'), findsOneWidget);
    expect(find.text('Workspace'), findsOneWidget);
    expect(find.text('Desktop shell ready'), findsOneWidget);
    expect(find.text('File'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Mask Editor'), findsOneWidget);
    expect(
      find.text(
        'F1 Help   F2 Back   F3 Next   F5 Search   F6 Jump   F7 Delete   F8 Insert   F10 Done   Esc Cancel',
      ),
      findsOneWidget,
    );
  });

  testWidgets('desktop shell routes from top-level menu buttons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LearnAnywhereDesktopApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mask Editor'));
    await tester.pumpAndSettle();

    expect(find.text('Mask Editor'), findsWidgets);
    expect(find.text('Mask name'), findsOneWidget);
    expect(find.text('Direction 1 label'), findsOneWidget);
    expect(find.text('Direction 2 label'), findsOneWidget);
    expect(find.text('Categories: 1/20'), findsOneWidget);
    expect(find.text('Fields: 3/20'), findsOneWidget);
  });

  testWidgets('editor inserts units and edits length-limited fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LearnAnywhereDesktopApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('No learning units'), findsOneWidget);
    await tester.tap(find.text('Insert before'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Category 1'));
    await tester.pumpAndSettle();

    expect(find.text('Unit 1 of 1 - Category 1'), findsOneWidget);
    expect(find.text('Question'), findsOneWidget);
    expect(find.text('Answer'), findsOneWidget);

    await tester.tap(find.byTooltip('Bold').first);
    await tester.enterText(
      find.byKey(const ValueKey<String>('editor-input-Question')),
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
    await tester.pumpWidget(const LearnAnywhereDesktopApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Insert before'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Category 1'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('editor-input-Question')),
      'rabbit',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Category 1'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('editor-input-Question')),
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
    await tester.pumpWidget(const LearnAnywhereDesktopApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Query Options'));
    await tester.pumpAndSettle();

    expect(find.text('Query Options'), findsWidgets);
    expect(find.text('Wrong input correctable'), findsOneWidget);
    expect(find.text('Complete input required'), findsOneWidget);
    expect(find.text('Case sensitive'), findsOneWidget);
    expect(find.text('With answer input'), findsOneWidget);

    await tester.tap(find.text('With answer input'));
    await tester.pumpAndSettle();

    expect(find.text('With answer input'), findsOneWidget);
  });

  testWidgets('learn session checks answers and records live accuracy', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LearnAnywhereDesktopApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Insert before'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Category 1'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('editor-input-Question')),
      'hello',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('editor-input-Answer')),
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
    await tester.drag(find.byType(ListView), const Offset(0, 500));
    await tester.pumpAndSettle();

    expect(find.textContaining('Unit 1 of 1 - Category 1'), findsOneWidget);
    if (tester.any(find.text('hello', findRichText: true))) {
      await tester.enterText(
        find.byKey(const ValueKey<String>('learn-answer-Answer')),
        'bonjour',
      );
    } else {
      expect(find.text('bonjour', findRichText: true), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey<String>('learn-answer-Question')),
        'hello',
      );
    }
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

    expect(find.text('Accuracy: 100%'), findsOneWidget);
  });

  testWidgets('mask editor edits mask metadata and adds schema items', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LearnAnywhereDesktopApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mask Editor'));
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

  testWidgets('file menu clear units asks for confirmation and shows status', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LearnAnywhereDesktopApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('File'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear units in memory...'));
    await tester.pumpAndSettle();

    expect(find.text('Please confirm'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('File operations'), findsOneWidget);
    expect(find.text('Units: 0'), findsOneWidget);
    expect(find.text('Units cleared.'), findsWidgets);
  });

  testWidgets('desktop shell switches language at runtime', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LearnAnywhereDesktopApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<Locale>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('German').last);
    await tester.pumpAndSettle();

    expect(find.text('Datei'), findsOneWidget);
    expect(find.text('Arbeitsbereich'), findsOneWidget);
    expect(find.text('Desktop-Shell bereit'), findsOneWidget);
  });
}
