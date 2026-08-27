import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_desktop/main.dart';
import 'package:learn_anywhere_desktop/src/editor/unit_editor_page.dart';
import 'package:learn_anywhere_desktop/src/preferences/desktop_prefs.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';
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
    // Pins the NEWEST history entry, not an arbitrary older one: the list is a
    // fixed-height lazy ListView that only builds its first ~3 rows, so an
    // older version silently falls out of the built range on the next bump.
    // Update this together with the version — see packages/desktop/CLAUDE.md.
    expect(find.textContaining('0.8.1'), findsOneWidget);
  });

  testWidgets('help user guide opens with a contents list and search', (
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
    await tester.tap(find.text('User guide'));
    await tester.pumpAndSettle();

    expect(find.byType(HelpViewer), findsOneWidget);
    expect(find.text('Contents'), findsOneWidget);
    expect(find.text('Search the guide...'), findsOneWidget);
    // Chapter titles come from each file's own "# " heading, so finding them
    // proves the assets were bundled, discovered and parsed.
    expect(find.text('Getting started'), findsWidgets);
    expect(find.text('Troubleshooting'), findsWidgets);
  });

  testWidgets('F1 opens the user guide from the home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(LearnAnywhereDesktopApp(prefs: prefs));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.f1);
    await tester.pumpAndSettle();

    expect(find.byType(HelpViewer), findsOneWidget);
  });

  testWidgets('F1 opens the guide over the editor and leaves it intact', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(LearnAnywhereDesktopApp(prefs: prefs));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unit editor').last);
    await tester.pumpAndSettle();
    expect(find.byType(UnitEditorPage), findsOneWidget);

    // The guide opens as a dialog, so the editor stays mounted underneath
    // rather than being routed away and rebuilt.
    await tester.sendKeyEvent(LogicalKeyboardKey.f1);
    await tester.pumpAndSettle();
    expect(find.byType(HelpViewer), findsOneWidget);
    expect(find.byType(UnitEditorPage), findsOneWidget);

    // A second F1 must not stack another copy on top.
    await tester.sendKeyEvent(LogicalKeyboardKey.f1);
    await tester.pumpAndSettle();
    expect(find.byType(HelpViewer), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(HelpViewer), findsNothing);
    expect(find.byType(UnitEditorPage), findsOneWidget);
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

    // The default field length is 80 (Batch 12); type well past it and
    // confirm the entered text is truncated to exactly that length.
    const String repeatUnit =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final String overLong = repeatUnit + repeatUnit;
    await tester.tap(find.byTooltip('Bold').first);
    await tester.enterText(editorInput('Question'), overLong);
    await tester.pumpAndSettle();

    expect(find.text(overLong.substring(0, 80)), findsOneWidget);
    expect(find.text(overLong), findsNothing);
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

  testWidgets('re-entering the unit editor opens on the last unit', (
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

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Category 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Unit 2 of 2 - Category 1'), findsOneWidget);

    // Leave the editor (F10/Done), then land back in the home screen — a
    // fresh Edit ▸ Unit editor must not restart at unit 1.
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unit editor').last);
    await tester.pumpAndSettle();

    expect(find.text('Unit 2 of 2 - Category 1'), findsOneWidget);
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
    await answerOneQuestion(tester);

    expect(find.text('Accuracy: 1/1 (100%)'), findsOneWidget);
    expect(find.text('Attempts: 1'), findsOneWidget);
  });

  testWidgets('clearing the all-time record asks first and spares the rest', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(LearnAnywhereDesktopApp(prefs: prefs));
    await tester.pumpAndSettle();
    await answerOneQuestion(tester);

    // The one answer is in both records: the working one the engine reads,
    // and the lifetime one this test is about to clear.
    await tester.tap(find.text('Statistics'));
    await tester.pumpAndSettle();
    expect(find.text('Total Attempts: 1'), findsOneWidget);
    await tester.tap(find.text('All-time'));
    await tester.pumpAndSettle();
    expect(find.text('Total Attempts: 1'), findsOneWidget);

    // Nothing destructive is on the screen: the clear has to be opened for.
    expect(find.text('Clear all-time stats...'), findsNothing);

    // Enter is the key that confirms every other prompt in the program. Here
    // it must dismiss, because Cancel holds the focus.
    await openAllTimeClear(tester);
    expect(find.textContaining('cannot be undone', findRichText: true),
        findsOneWidget);
    // And it names the record at stake. This deck was built in the editor and
    // never written, so it is named by the same "Unsaved" stand-in the file
    // status uses — the placeholder is filled either way.
    expect(
      find.textContaining("'Unsaved'", findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('{deck}', findRichText: true),
      findsNothing,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.textContaining('cannot be undone', findRichText: true),
        findsNothing);
    expect(find.text('Total Attempts: 1'), findsOneWidget);

    // Confirming deliberately: the lifetime numbers go back to zero.
    await openAllTimeClear(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Clear'));
    await tester.pumpAndSettle();
    expect(find.text('All-time statistics cleared.'), findsWidgets);
    expect(find.text('Total Attempts: 0'), findsOneWidget);

    // And the current statistics — the record that decides what is practised
    // — are exactly as they were.
    await tester.tap(find.text('Current'));
    await tester.pumpAndSettle();
    expect(find.text('Total Attempts: 1'), findsOneWidget);
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

  testWidgets('the zoom submenu offers every level and marks the current one', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(LearnAnywhereDesktopApp(prefs: prefs));
    await tester.pumpAndSettle();

    await openZoomMenu(tester);
    // Exactly the levels the shared model defines, no more and no fewer.
    for (final int level in LearnAnywhereZoom.levels) {
      expect(find.text('$level%'), findsOneWidget, reason: 'level $level');
    }
    expect(
      find.byType(RadioMenuButton<int>),
      findsNWidgets(LearnAnywhereZoom.levels.length),
    );

    // 100 % is where an untouched install starts, and the menu says so.
    expect(selectedZoomLevel(tester), 100);

    await tester.tap(find.text('150%'));
    await tester.pumpAndSettle();
    await openZoomMenu(tester);
    expect(selectedZoomLevel(tester), 150);
  });

  testWidgets('the zoom level survives a relaunch', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(LearnAnywhereDesktopApp(prefs: prefs));
    await tester.pumpAndSettle();
    await openZoomMenu(tester);
    await tester.tap(find.text('175%'));
    await tester.pumpAndSettle();

    // Quit and come back: a brand-new app over the same preference store, the
    // way the next launch sees it.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      LearnAnywhereDesktopApp(
        prefs: DesktopPrefs(await SharedPreferences.getInstance()),
      ),
    );
    await tester.pumpAndSettle();

    await openZoomMenu(tester);
    expect(selectedZoomLevel(tester), 175);
  });

  testWidgets('Ctrl+plus, Ctrl+minus and Ctrl+zero step through the levels', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(LearnAnywhereDesktopApp(prefs: prefs));
    await tester.pumpAndSettle();

    // Straight from launch, with nothing clicked and nothing focused.
    await pressZoomKey(tester, LogicalKeyboardKey.equal);
    expect(await currentZoomLevel(tester), 125);
    await pressZoomKey(tester, LogicalKeyboardKey.equal);
    expect(await currentZoomLevel(tester), 150);

    // The keys land on offered levels only — never a free-form size between.
    await pressZoomKey(tester, LogicalKeyboardKey.minus);
    expect(await currentZoomLevel(tester), 125);

    // Ctrl+0 goes home from anywhere — home being 100 %, which is NOT the
    // smallest level: there is one step below it.
    await pressZoomKey(tester, LogicalKeyboardKey.digit0);
    expect(await currentZoomLevel(tester), 100);
    await pressZoomKey(tester, LogicalKeyboardKey.minus);
    expect(await currentZoomLevel(tester), 75);

    // The bottom of the ladder holds; it does not wrap or go smaller.
    await pressZoomKey(tester, LogicalKeyboardKey.minus);
    expect(await currentZoomLevel(tester), LearnAnywhereZoom.minimum);

    // And the top holds too.
    for (int i = 0; i < 7; i++) {
      await pressZoomKey(tester, LogicalKeyboardKey.numpadAdd);
    }
    expect(await currentZoomLevel(tester), LearnAnywhereZoom.maximum);
  });

  testWidgets('zoom reaches the menu bar, not only the screens', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(LearnAnywhereDesktopApp(prefs: prefs));
    await tester.pumpAndSettle();
    final Size plainMenu = tester.getSize(find.text('File'));
    final Size plainTitle = tester.getSize(find.text('Learn Anywhere'));

    await setZoomFromMenu(tester, 200);
    // The menu bar is chrome, not a screen — it would be the one thing left
    // behind by a per-screen approach, and the interface would read as
    // mismatched.
    expect(tester.getSize(find.text('File')).width,
        greaterThan(plainMenu.width * 1.5));
    expect(tester.getSize(find.text('Learn Anywhere')).width,
        greaterThan(plainTitle.width * 1.5));
  });

  testWidgets('the key name under a button zooms with the label above it', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(2400, 1500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(LearnAnywhereDesktopApp(prefs: prefs));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Statistics'));
    await tester.pumpAndSettle();

    final Size plainLabel = tester.getSize(find.text('Cancel'));
    final Size plainHint = tester.getSize(find.text('Esc'));

    await setZoomFromMenu(tester, 200);
    final double labelGrowth =
        tester.getSize(find.text('Cancel')).width / plainLabel.width;
    final double hintGrowth =
        tester.getSize(find.text('Esc')).width / plainHint.width;

    // The caption is written as a literal font size rather than taken from the
    // theme, so it is the one piece of text that could be left behind. It has
    // to travel with the label it belongs to, not sit at 10 pixels beside text
    // the learner deliberately doubled.
    expect(labelGrowth, greaterThan(1.8));
    expect(hintGrowth, closeTo(labelGrowth, 0.15));
  });

  testWidgets('a mask field box grows together with the text inside it', (
    WidgetTester tester,
  ) async {
    // THE test for the zoom mechanism. The field box is sized by measuring one
    // character in the style the text is painted with, so scaling the theme's
    // own font sizes grows the box and the text together. Overriding the text
    // scaler instead would grow the text at paint time, AFTER that
    // measurement: the row would get taller (the text lays out taller) while
    // its width stayed exactly where it was, and every field would clip. That
    // is why this asserts the WIDTH, and asserts it against the height rather
    // than against a fixed number.
    tester.view.physicalSize = const Size(2200, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(LearnAnywhereDesktopApp(prefs: prefs));
    await tester.pumpAndSettle();
    await openEditorWithOneUnit(tester);

    final Size plain = tester.getSize(find.byType(FieldRow).first);

    await setZoomFromMenu(tester, 200);
    await openEditorWithOneUnit(tester);
    final Size zoomed = tester.getSize(find.byType(FieldRow).first);

    final double widthGrowth = zoomed.width / plain.width;
    final double heightGrowth = zoomed.height / plain.height;
    // The text really did get bigger: the row is taller because the line it
    // holds is taller. (It grows by less than the full factor because the row's
    // padding is fixed — the accepted consequence recorded in the ADR.)
    expect(heightGrowth, greaterThan(1.2));
    // And the box that holds the text grew with it — the assertion the whole
    // mechanism exists for. A text-scaler override would leave this at exactly
    // 1.0 while the height above still grew, so comparing the two is what makes
    // this test fail against the wrong implementation.
    expect(widthGrowth, greaterThan(heightGrowth));
    // At 200 % the value column is sized for characters twice as wide, so the
    // row very nearly doubles; only the fixed accent bar and divider hold it
    // back.
    expect(widthGrowth, greaterThan(1.8));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the far ends of the zoom range raise no overflow anywhere', (
    WidgetTester tester,
  ) async {
    // Both the window the program opens at and a large monitor: the first is
    // where doubled text runs out of room first, and it is what the learner
    // most likely has when she reaches for zoom in the first place. The
    // smallest level is walked too — text that shrinks while paddings and
    // icons stay put is the other end of the same hazard.
    for (final int level in <int>[
      LearnAnywhereZoom.minimum,
      LearnAnywhereZoom.maximum,
    ]) {
      for (final Size size in <Size>[
        const Size(1280, 720),
        const Size(2400, 1500),
      ]) {
        await walkEveryScreen(tester, zoomPercent: level, surface: size);
      }
    }
  });

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

/// Drives every screen of the program at [zoomPercent] on a [surface]-sized
/// window, failing on the first layout overflow any of them raises.
///
/// A layout overflow throws in a widget test, so visiting the screens IS the
/// assertion; each [WidgetTester.takeException] names the screen it belongs to
/// so a failure says where to look. The zoom comes from the preference store
/// rather than the menu, so every screen is built at that level from the start.
Future<void> walkEveryScreen(
  WidgetTester tester, {
  required int zoomPercent,
  required Size surface,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'zoom_percent': zoomPercent,
  });
  final DesktopPrefs zoomed = DesktopPrefs(
    await SharedPreferences.getInstance(),
  );
  final String tag = '$zoomPercent% at ${surface.width.toInt()} wide';
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  Future<void> clean(String where) async {
    expect(tester.takeException(), isNull, reason: '$tag — $where');
  }

  Future<void> pick(String top, String item) async {
    await tester.ensureVisible(find.text(top));
    await tester.pumpAndSettle();
    await tester.tap(find.text(top));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item).last);
    await tester.pumpAndSettle();
  }

  await tester.pumpWidget(LearnAnywhereDesktopApp(prefs: zoomed));
  await tester.pumpAndSettle();
  await clean('the workspace');

  await openEditorWithOneUnit(tester);
  await clean('the unit editor');
  await tester.tap(find.text('Done'));
  await tester.pumpAndSettle();
  // The workspace again, now in its loaded-deck form: status lines and the
  // statistics summary, which the empty one above does not show.
  await clean('the workspace with a deck loaded');

  await pick('Edit', 'Mask Editor');
  await clean('the mask editor');
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await tester.pumpAndSettle();

  await tester.ensureVisible(find.text('Statistics'));
  await tester.tap(find.text('Statistics'));
  await tester.pumpAndSettle();
  await clean('the statistics screen');
  await tester.tap(find.text('All-time'));
  await tester.pumpAndSettle();
  await clean('the statistics screen in all-time scope');
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await tester.pumpAndSettle();

  await tester.ensureVisible(find.text('Lexicon'));
  await tester.tap(find.text('Lexicon'));
  await tester.pumpAndSettle();
  await clean('the lexicon');
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await tester.pumpAndSettle();

  await pick('Options', 'Advanced Learning Options');
  await clean('the advanced learning options');
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await tester.pumpAndSettle();

  await pick('Learn', 'Practice setup');
  await clean('the practice setup');
  await tester.drag(find.byType(ListView), const Offset(0, -500));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Start session'));
  await tester.pumpAndSettle();
  await clean('a running session');
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await tester.pumpAndSettle();
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await tester.pumpAndSettle();

  await tester.sendKeyEvent(LogicalKeyboardKey.f1);
  await tester.pumpAndSettle();
  await clean('the user guide');
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await tester.pumpAndSettle();

  await pick('Help', 'About');
  await clean('the about screen');

  await pick('Options', 'Start folder...');
  await clean('the start-folder prompt');
  await tester.tap(find.text('Cancel').last);
  await tester.pumpAndSettle();
}

/// Opens Options ▸ Zoom level, leaving its five radio items on screen.
Future<void> openZoomMenu(WidgetTester tester) async {
  // The menu bar scrolls horizontally, and every level above 100 % makes it
  // wider — so scroll the entry into view rather than assuming it is.
  await tester.ensureVisible(find.text('Options'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Options'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Zoom level').last);
  await tester.pumpAndSettle();
}

/// Closes whatever menu is open, so a keystroke reaches the app again.
Future<void> closeMenus(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await tester.pumpAndSettle();
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await tester.pumpAndSettle();
}

/// The level the open zoom submenu shows as selected.
///
/// Also asserts that exactly one level is marked, which is the whole point of
/// a radio group: the learner can always see where she is.
int selectedZoomLevel(WidgetTester tester) {
  final Iterable<RadioMenuButton<int>> marked = tester
      .widgetList<RadioMenuButton<int>>(find.byType(RadioMenuButton<int>))
      .where((RadioMenuButton<int> button) => button.value == button.groupValue);
  expect(marked, hasLength(1));
  return marked.first.value;
}

/// Opens the zoom submenu, reads the selected level, and closes up again.
Future<int> currentZoomLevel(WidgetTester tester) async {
  await openZoomMenu(tester);
  final int level = selectedZoomLevel(tester);
  await closeMenus(tester);
  return level;
}

/// Picks [level] from Options ▸ Zoom level.
Future<void> setZoomFromMenu(WidgetTester tester, int level) async {
  await openZoomMenu(tester);
  await tester.tap(find.text('$level%'));
  await tester.pumpAndSettle();
}

/// Presses [key] with the left Ctrl held down.
Future<void> pressZoomKey(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

/// Opens the unit editor on a deck that has one unit, creating it on the first
/// call and re-entering the existing one afterwards.
///
/// The shortest route to a mask field box on screen, which is what the zoom
/// geometry assertion needs to measure.
Future<void> openEditorWithOneUnit(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Edit'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Edit'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Unit editor').last);
  await tester.pumpAndSettle();
  if (tester.any(find.text('No learning units'))) {
    await tester.tap(find.text('Insert unit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Category 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }
  expect(find.byType(FieldRow), findsWidgets);
}

/// Opens the all-time overflow menu and picks the clear command, leaving the
/// confirmation dialog on screen.
///
/// The command sits behind that menu on purpose — nothing destructive is
/// visible on the statistics screen — so every route to the dialog goes
/// through two taps. Expects the statistics screen in the all-time scope.
Future<void> openAllTimeClear(WidgetTester tester) async {
  await tester.tap(find.byTooltip('All-time actions'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Clear all-time stats...'));
  await tester.pumpAndSettle();
}

/// Builds a one-unit deck, runs a session over it and answers its single
/// question correctly, leaving the app on the finished session page.
///
/// The shortest route to a deck with something in BOTH statistics records,
/// which is what a test about either of them needs to start from. Expects a
/// freshly pumped app on the home screen and a surface at least 1400 wide —
/// the practice grid overflows the default 800.
Future<void> answerOneQuestion(WidgetTester tester) async {
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
  await tester.enterText(editorInput('Question'), 'hello');
  await tester.enterText(editorInput('Answer'), 'bonjour');
  await tester.pumpAndSettle();

  await tester.tap(find.text('Learn'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Practice setup').last);
  await tester.pumpAndSettle();
  expect(find.text('Practice setup'), findsOneWidget);
  await tester.drag(find.byType(ListView), const Offset(0, -500));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Start session'));
  await tester.pumpAndSettle();

  expect(find.textContaining('Unit 1/1 - Category 1'), findsOneWidget);
  // Before Check, the prompt is read-only rich text and the single answer
  // cell is the only editable field, so target it by type. Which direction
  // was drawn decides which of the two words is the prompt.
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
