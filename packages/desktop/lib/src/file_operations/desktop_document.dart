import 'package:learn_anywhere_core/core.dart';

/// In-memory desktop document state shared by file operations and feature pages.
final class DesktopDocument {
  /// Creates a desktop document state.
  const DesktopDocument({
    required this.deck,
    required this.statistics,
    this.levelStatistics = const <LevelUnitStats>[],
    this.deckPath,
    this.statisticsPath,
    this.autoSaveTargetPath,
    this.autoLoadStatistics = false,
    this.autoSaveStatistics = false,
    this.lastSessionMode,
  });

  /// Current self-contained deck.
  final LearningDeck deck;

  /// Current in-memory statistics.
  final List<UnitStats> statistics;

  /// Current in-memory Level-Learning statistics (`.sta` v2 section).
  ///
  /// Empty when the deck has no Level-Learning history yet; entries are seeded
  /// on demand by the engine (`activeLevelLearningPool`) and materialized here
  /// as the student answers Level-Learning units.
  final List<LevelUnitStats> levelStatistics;

  /// Current `.vok` path, if any.
  final String? deckPath;

  /// Current `.sta` path, if manually loaded or auto-loaded.
  final String? statisticsPath;

  /// Active auto-save target `.sta` path, or `null` when auto-saving is
  /// suspended.
  ///
  /// This is the file every check→continue cycle writes to during a session
  /// (§3.7). It is set when a timestamped session file is created, when a
  /// `.sta` is auto-loaded, when the user picks "Save stats as", or when a
  /// manually-loaded `.sta` is adopted; it is cleared (suspended) when a
  /// manual load is declined for auto-saving.
  final String? autoSaveTargetPath;

  /// Whether opening a deck auto-loads a `.sta`.
  final bool autoLoadStatistics;

  /// Whether leaving a deck auto-saves statistics.
  final bool autoSaveStatistics;

  /// Mode of the session these statistics were last recorded in, when known.
  ///
  /// `null` means "unknown" — nothing recorded yet this run, or a `.sta`
  /// written before the field existed. Starting a session in a mode that
  /// differs from this one prompts the student before proceeding.
  final SessionMode? lastSessionMode;

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
    List<LevelUnitStats>? levelStatistics,
    String? deckPath,
    String? statisticsPath,
    String? autoSaveTargetPath,
    bool clearDeckPath = false,
    bool clearStatisticsPath = false,
    bool clearAutoSaveTarget = false,
    bool clearLastSessionMode = false,
    bool? autoLoadStatistics,
    bool? autoSaveStatistics,
    SessionMode? lastSessionMode,
  }) {
    return DesktopDocument(
      deck: deck ?? this.deck,
      statistics: statistics ?? this.statistics,
      levelStatistics: levelStatistics ?? this.levelStatistics,
      deckPath: clearDeckPath ? null : deckPath ?? this.deckPath,
      statisticsPath: clearStatisticsPath
          ? null
          : statisticsPath ?? this.statisticsPath,
      autoSaveTargetPath: clearAutoSaveTarget
          ? null
          : autoSaveTargetPath ?? this.autoSaveTargetPath,
      autoLoadStatistics: autoLoadStatistics ?? this.autoLoadStatistics,
      autoSaveStatistics: autoSaveStatistics ?? this.autoSaveStatistics,
      lastSessionMode: clearLastSessionMode
          ? null
          : lastSessionMode ?? this.lastSessionMode,
    );
  }
}
