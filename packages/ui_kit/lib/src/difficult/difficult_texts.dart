import 'package:learn_anywhere_core/core.dart';

import '../i18n/learn_anywhere_localizations.dart';

/// How the setup words a [DifficultUnitCount], on desktop and Android alike.
extension DifficultUnitCountText on DifficultUnitCount {
  /// The option's label: "Difficult units only (y)" or "(x/y)".
  String optionLabel(LearnAnywhereLocalizations messages) {
    return messages
        .message(LearnAnywhereMessage.learnDifficultOnly)
        .replaceAll('{count}', text);
  }

  /// What the count means, in words: the deck's total when the range
  /// [coversDeck], else how many of them the range holds.
  String optionTooltip(LearnAnywhereLocalizations messages) {
    if (coversDeck) {
      return messages
          .message(LearnAnywhereMessage.learnDifficultOnlyDeckTooltip)
          .replaceAll('{total}', '$inDeck');
    }
    return messages
        .message(LearnAnywhereMessage.learnDifficultOnlyRangeTooltip)
        .replaceAll('{count}', '$inRange')
        .replaceAll('{total}', '$inDeck');
  }
}

/// How a session words its [RemainingReadout], on desktop and Android alike.
extension RemainingReadoutText on RemainingReadout {
  /// What the pill counts: the whole deck, and in a [restricted] session
  /// also what the session itself has left.
  String tooltip(LearnAnywhereLocalizations messages) {
    if (!restricted) {
      return messages.message(LearnAnywhereMessage.learnLiveRemainingTooltip);
    }
    return messages
        .message(LearnAnywhereMessage.learnLiveRemainingRestrictedTooltip)
        .replaceAll('{total}', '$inDeck')
        .replaceAll('{count}', '$inSession');
  }
}
