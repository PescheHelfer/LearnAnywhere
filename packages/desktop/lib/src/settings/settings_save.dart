import 'package:learn_anywhere_core/core.dart';

import '../learn/desktop_query_options.dart';

/// Returns the settings to write to disk for this auto-save.
///
/// Starts from [previous] and overlays only the fields [queryOptions],
/// [learnParameters], [deckPath], and [maskPath] actually represent, so any
/// other field — including one nobody has added UI for yet — is carried
/// forward unchanged instead of reverting to its constructor default.
LearnAnywhereSettings nextSettingsForSave({
  required LearnAnywhereSettings previous,
  required DesktopQueryOptions queryOptions,
  required SessionParameters learnParameters,
  required String? deckPath,
  required String? maskPath,
}) {
  return previous.copyWith(
    wrongInputCorrectable: queryOptions.wrongInputCorrectable,
    completeInputRequired: queryOptions.completeInputRequired,
    caseSensitive: queryOptions.caseSensitive,
    accentSensitive: queryOptions.accentSensitive,
    almostEnabled: queryOptions.almostEnabled,
    almostThreshold: queryOptions.almostThreshold,
    showClock: queryOptions.showClock,
    timeLimitSeconds: queryOptions.timeLimitSeconds,
    minimumAttemptsGuardEnabled: queryOptions.minimumAttemptsGuardEnabled,
    minAttempts: queryOptions.minAttempts,
    wrongAnswerCeilingEnabled: queryOptions.wrongAnswerCeilingEnabled,
    wrongAnswerCeiling: queryOptions.wrongAnswerCeiling,
    mode: learnParameters.mode,
    direction: learnParameters.directionSelection,
    shuffle: learnParameters.shuffle,
    requireTypedAnswers: learnParameters.withInput,
    masteryThreshold: learnParameters.masteryThreshold,
    lastDeckPath: deckPath,
    lastMaskPath: maskPath,
  );
}
