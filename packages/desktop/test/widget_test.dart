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
