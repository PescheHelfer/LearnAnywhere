import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_desktop/src/learn/desktop_query_options.dart';
import 'package:learn_anywhere_desktop/src/settings/settings_save.dart';

void main() {
  // Regression coverage for a bug where the save path reconstructed
  // LearnAnywhereSettings from a hand-written literal that omitted
  // keepStatisticsVersions, silently reverting it to its constructor
  // default on every save.
  test('a save cycle preserves a field the save did not touch', () {
    const LearnAnywhereSettings previous = LearnAnywhereSettings(
      keepStatisticsVersions: 7,
    );

    final LearnAnywhereSettings next = nextSettingsForSave(
      previous: previous,
      queryOptions: const DesktopQueryOptions(),
      learnParameters: const SessionParameters(),
      deckPath: previous.lastDeckPath,
      maskPath: previous.lastMaskPath,
    );

    expect(next.keepStatisticsVersions, 7);
  });

  test('entry-level cap and level names survive a save', () {
    const LearnAnywhereSettings previous = LearnAnywhereSettings(
      entryLevelCap: 1,
      levelNamesEn: <String>['A', 'B', 'C', 'D'],
      levelNamesDe: <String>['E', 'F', 'G', 'H'],
    );

    final LearnAnywhereSettings next = nextSettingsForSave(
      previous: previous,
      queryOptions: const DesktopQueryOptions(),
      learnParameters: const SessionParameters(),
      deckPath: previous.lastDeckPath,
      maskPath: previous.lastMaskPath,
    );

    expect(next.entryLevelCap, 1);
    expect(next.levelNamesEn, <String>['A', 'B', 'C', 'D']);
    expect(next.levelNamesDe, <String>['E', 'F', 'G', 'H']);
  });

  test('opening a deck puts it at the head of the recent list', () {
    const LearnAnywhereSettings previous = LearnAnywhereSettings(
      recentDeckPaths: <String>['/decks/latin.vok'],
    );

    final LearnAnywhereSettings next = _save(
      previous,
      deckPath: '/decks/french.vok',
    );

    expect(next.recentDeckPaths, <String>[
      '/decks/french.vok',
      '/decks/latin.vok',
    ]);
    expect(next.lastDeckPath, '/decks/french.vok');
  });

  test('reopening a listed deck moves it up instead of duplicating it', () {
    const LearnAnywhereSettings previous = LearnAnywhereSettings(
      recentDeckPaths: <String>['/decks/latin.vok', '/decks/french.vok'],
    );

    final LearnAnywhereSettings next = _save(
      previous,
      deckPath: '/decks/french.vok',
    );

    expect(next.recentDeckPaths, <String>[
      '/decks/french.vok',
      '/decks/latin.vok',
    ]);
  });

  test('a save with no deck loaded leaves the recent list alone', () {
    const LearnAnywhereSettings previous = LearnAnywhereSettings(
      recentDeckPaths: <String>['/decks/latin.vok'],
    );

    final LearnAnywhereSettings next = _save(previous, deckPath: null);

    expect(next.recentDeckPaths, <String>['/decks/latin.vok']);
  });
}

/// Runs one auto-save cycle over [previous] with nothing but the deck changed.
LearnAnywhereSettings _save(
  LearnAnywhereSettings previous, {
  required String? deckPath,
}) {
  return nextSettingsForSave(
    previous: previous,
    queryOptions: const DesktopQueryOptions(),
    learnParameters: const SessionParameters(),
    deckPath: deckPath,
    maskPath: previous.lastMaskPath,
  );
}
