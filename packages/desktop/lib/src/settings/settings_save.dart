import 'package:learn_anywhere_core/core.dart';

import '../learn/desktop_query_options.dart';

/// Returns the settings to write to disk for this auto-save.
///
/// Starts from [previous] and overlays only the fields [queryOptions],
/// [learnParameters], [deckPath], and [maskPath] actually represent, so any
/// other field — including one nobody has added UI for yet — is carried
/// forward unchanged instead of reverting to its constructor default.
///
/// A non-null [deckPath] is promoted to the head of the recent-deck list and
/// [unitRange] remembered as its range; a null one (nothing loaded, or an
/// unsaved deck) leaves the list alone, so starting a new deck does not forget
/// where the learner has been. The remembered ranges are then cut back to the
/// decks still on the list.
LearnAnywhereSettings nextSettingsForSave({
  required LearnAnywhereSettings previous,
  required DesktopQueryOptions queryOptions,
  required SessionParameters learnParameters,
  required String? deckPath,
  required UnitRangeSelection unitRange,
  required String? maskPath,
}) {
  final List<String> recentDeckPaths = deckPath == null
      ? previous.recentDeckPaths
      : withRecentDeckPath(previous.recentDeckPaths, deckPath);
  return previous.copyWith(
    wrongInputCorrectable: queryOptions.wrongInputCorrectable,
    completeInputRequired: queryOptions.completeInputRequired,
    caseSensitive: queryOptions.caseSensitive,
    accentSensitive: queryOptions.accentSensitive,
    almostEnabled: queryOptions.almostEnabled,
    almostThreshold: queryOptions.almostThreshold,
    showUnitTime: queryOptions.showUnitTime,
    showSittingTime: queryOptions.showSittingTime,
    showStatisticsTime: queryOptions.showStatisticsTime,
    showTotalTime: queryOptions.showTotalTime,
    timeLimitSeconds: queryOptions.timeLimitSeconds,
    minimumAttemptsGuardEnabled: queryOptions.minimumAttemptsGuardEnabled,
    minAttempts: queryOptions.minAttempts,
    wrongAnswerCeilingEnabled: queryOptions.wrongAnswerCeilingEnabled,
    wrongAnswerCeiling: queryOptions.wrongAnswerCeiling,
    mode: learnParameters.mode,
    direction: learnParameters.directionSelection,
    shuffle: learnParameters.shuffle,
    difficultOnly: learnParameters.difficultOnly,
    requireTypedAnswers: learnParameters.withInput,
    masteryThreshold: learnParameters.masteryThreshold,
    recentDeckPaths: recentDeckPaths,
    unitRanges: unitRangesForRecentDecks(
      deckPath == null
          ? previous.unitRanges
          : withUnitRange(previous.unitRanges, deckPath, unitRange),
      recentDeckPaths,
    ),
    lastMaskPath: maskPath,
  );
}
