import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_desktop/src/file_operations/desktop_file_service.dart';
import 'package:learn_anywhere_desktop/src/home/recent_decks.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory temp;
  late Directory language;
  late List<String> opened;
  late Map<String, DeckDates> dates;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('la_recent_decks');
    // Decks sit one folder deep, as they do in practice: the folder carries
    // the language, and the link shows it.
    language = Directory(p.join(temp.path, 'Franz'))..createSync();
    opened = <String>[];
    dates = <String, DeckDates>{};
  });

  tearDown(() {
    temp.deleteSync(recursive: true);
  });

  /// Creates a real `.vok` file so the link sees it as existing.
  String deckFile(String name) {
    final File file = File(p.join(language.path, name))..writeAsStringSync('{}');
    return file.path;
  }

  /// The text a link shows for [name]: its folder, its own name, nothing else.
  String labelOf(String name) => p.join('...', 'Franz', name);

  Future<void> pumpList(
    WidgetTester tester,
    List<String> paths, {
    Locale locale = const Locale('en'),
  }) {
    return tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: LearnAnywhereLocalizations.localizationsDelegates,
        supportedLocales: LearnAnywhereLocalizations.supportedLocales,
        home: Scaffold(
          body: RecentDecksList(
            paths: paths,
            onOpen: (String path) async => opened.add(path),
            datesOf: (String path) async => dates[path] ?? const DeckDates(),
          ),
        ),
      ),
    );
  }

  testWidgets('lists the decks newest first and opens one in a single tap', (
    WidgetTester tester,
  ) async {
    final String french = deckFile('french.vok');
    final String latin = deckFile('latin.vok');
    await pumpList(tester, <String>[french, latin]);
    await tester.pumpAndSettle();

    expect(find.text('Recent decks:'), findsOneWidget);
    // Each entry names the folder it sits in and the deck, not the whole path.
    expect(find.text(labelOf('french.vok')), findsOneWidget);
    expect(find.text(labelOf('latin.vok')), findsOneWidget);
    expect(find.textContaining(temp.path), findsNothing);
    // Each carries the mark that says it is a link.
    expect(find.text('⧉'), findsNWidgets(2));

    await tester.tap(find.text(labelOf('latin.vok')));
    await tester.pumpAndSettle();
    expect(opened, <String>[latin]);
  });

  testWidgets('the full path is available on hover', (
    WidgetTester tester,
  ) async {
    final String french = deckFile('french.vok');
    await pumpList(tester, <String>[french]);
    await tester.pumpAndSettle();

    final Tooltip tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, french);
  });

  testWidgets('a deck whose file is gone stays listed, muted and unclickable', (
    WidgetTester tester,
  ) async {
    final String missing = p.join(language.path, 'moved.vok');
    final String french = deckFile('french.vok');
    await pumpList(tester, <String>[missing, french]);
    await tester.pumpAndSettle();

    // Still listed rather than silently pruned — a missing entry would hide a
    // moved folder instead of showing it.
    expect(find.text(labelOf('moved.vok')), findsOneWidget);

    final TextStyle missingStyle = tester
        .widget<Text>(find.text(labelOf('moved.vok')))
        .style!;
    final TextStyle liveStyle = tester
        .widget<Text>(find.text(labelOf('french.vok')))
        .style!;
    expect(missingStyle.decoration, TextDecoration.none);
    expect(liveStyle.decoration, TextDecoration.underline);
    expect(missingStyle.color, isNot(liveStyle.color));

    await tester.tap(find.text(labelOf('moved.vok')));
    await tester.pumpAndSettle();

    // Nothing was loaded, and the message names the path that is gone — the
    // whole one, not the shortened label.
    expect(opened, isEmpty);
    expect(find.text('File not found: $missing'), findsOneWidget);
  });

  testWidgets('an empty list renders nothing at all', (
    WidgetTester tester,
  ) async {
    await pumpList(tester, const <String>[]);
    await tester.pumpAndSettle();

    expect(find.text('Recent decks:'), findsNothing);
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('each deck shows when it was last edited and last learned', (
    WidgetTester tester,
  ) async {
    final String french = deckFile('french.vok');
    final String latin = deckFile('latin.vok');
    dates[french] = DeckDates(
      lastEdited: LocalTimestamp.of(DateTime(2026, 9, 25, 16, 32, 11)),
      lastLearned: DateTime(2026, 9, 26, 8, 5, 42),
    );
    await pumpList(tester, <String>[french, latin]);
    await tester.pumpAndSettle();

    expect(
      find.text('Last edited: 2026-09-25 16:32 · '
          'Last learned: 2026-09-26 08:05'),
      findsOneWidget,
    );
    // A deck with neither date says so rather than leaving a gap.
    expect(
      find.text('Last edited: not recorded · '
          'Last learned: not learned yet'),
      findsOneWidget,
    );
  });

  testWidgets('the dates read in German with the German labels', (
    WidgetTester tester,
  ) async {
    final String french = deckFile('french.vok');
    final String latin = deckFile('latin.vok');
    dates[french] = DeckDates(
      lastEdited: LocalTimestamp.of(DateTime(2026, 9, 25, 16, 32, 11)),
    );
    await pumpList(
      tester,
      <String>[french, latin],
      locale: const Locale('de'),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Zuletzt bearbeitet: 2026-09-25 16:32 · '
          'Zuletzt gelernt: noch nicht gelernt'),
      findsOneWidget,
    );
    expect(
      find.text('Zuletzt bearbeitet: nicht erfasst · '
          'Zuletzt gelernt: noch nicht gelernt'),
      findsOneWidget,
    );
  });

  testWidgets('a deck whose file is gone shows no dates', (
    WidgetTester tester,
  ) async {
    final String missing = p.join(language.path, 'moved.vok');
    await pumpList(tester, <String>[missing]);
    await tester.pumpAndSettle();

    expect(find.textContaining('Last edited'), findsNothing);
  });
}
