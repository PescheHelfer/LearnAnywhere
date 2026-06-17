import 'package:learn_anywhere_core/core.dart';

/// In-memory desktop document state shared by file operations and feature pages.
final class DesktopDocument {
  /// Creates a desktop document state.
  const DesktopDocument({
    required this.deck,
    required this.statistics,
    this.deckPath,
    this.statisticsPath,
    this.autoLoadStatistics = true,
    this.autoSaveStatistics = true,
  });

  /// Current self-contained deck.
  final LearningDeck deck;

  /// Current in-memory statistics.
  final List<UnitStats> statistics;

  /// Current `.vok` path, if any.
  final String? deckPath;

  /// Current `.sta` path, if manually loaded or auto-loaded.
  final String? statisticsPath;

  /// Whether opening a deck auto-loads a sidecar `.sta`.
  final bool autoLoadStatistics;

  /// Whether leaving a deck auto-saves statistics.
  final bool autoSaveStatistics;

  /// Current embedded mask.
  LearningMask get mask => deck.mask;

  /// Creates a new empty document with [mask].
  factory DesktopDocument.empty(LearningMask mask) {
    final LearningDeck deck = LearningDeck(
      mask: mask,
      units: const <LearningUnit>[],
    );
    return DesktopDocument(deck: deck, statistics: clearStatistics(deck));
  }

  /// Returns a copy with selected fields changed.
  DesktopDocument copyWith({
    LearningDeck? deck,
    List<UnitStats>? statistics,
    String? deckPath,
    String? statisticsPath,
    bool clearDeckPath = false,
    bool clearStatisticsPath = false,
    bool? autoLoadStatistics,
    bool? autoSaveStatistics,
  }) {
    return DesktopDocument(
      deck: deck ?? this.deck,
      statistics: statistics ?? this.statistics,
      deckPath: clearDeckPath ? null : deckPath ?? this.deckPath,
      statisticsPath: clearStatisticsPath
          ? null
          : statisticsPath ?? this.statisticsPath,
      autoLoadStatistics: autoLoadStatistics ?? this.autoLoadStatistics,
      autoSaveStatistics: autoSaveStatistics ?? this.autoSaveStatistics,
    );
  }
}
