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
    expect(
      find.text(
        'The integrated mask editor will be implemented in Phase 2 Step 2.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('file menu commands route to file operations placeholder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LearnAnywhereDesktopApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('File'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open deck...'));
    await tester.pumpAndSettle();

    expect(find.text('File operations'), findsOneWidget);
    expect(
      find.text(
        'File commands are ready to be wired in the next Phase 2 steps.',
      ),
      findsOneWidget,
    );
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
