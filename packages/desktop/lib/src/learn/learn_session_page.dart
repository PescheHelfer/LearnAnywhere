import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

import 'desktop_query_options.dart';

/// Callback used to persist live session counters in the shell.
typedef LearnSessionProgressChanged = void Function(int attempts, int correct);

/// Desktop learning session page.
final class LearnSessionPage extends StatefulWidget {
  /// Creates a desktop learning session page.
  const LearnSessionPage({
    required this.deck,
    required this.statistics,
    required this.options,
    required this.parameters,
    required this.sessionAttempts,
    required this.sessionCorrect,
    required this.onParametersChanged,
    required this.onStatisticsChanged,
    required this.onSessionProgressChanged,
    required this.onOpenEditor,
    this.levelStatistics = const <LevelUnitStats>[],
    this.levelNames = kDefaultLevelNamesEn,
    this.entryLevelCap = kMaxSupportLevel,
    this.onLevelStatisticsChanged,
    this.onEntryLevelCapChanged,
    this.onStartUnitChanged,
    this.onEndUnitChanged,
    this.onExit,
    super.key,
  });

  /// Current deck.
  final LearningDeck deck;

  /// Current statistics.
  final List<UnitStats> statistics;

  /// Current Level-Learning statistics (`.sta` v2 section, may be empty).
  final List<LevelUnitStats> levelStatistics;

  /// Level names for the active locale, ordered engine level 3 → 0.
  final List<String> levelNames;

  /// Highest support level a newly seeded Level-Learning unit may start at.
  final int entryLevelCap;

  /// Called when Level-Learning statistics change (attempt or manual override).
  final ValueChanged<List<LevelUnitStats>>? onLevelStatisticsChanged;

  /// Called when the user changes the Level-Learning entry-level cap in setup.
  final ValueChanged<int>? onEntryLevelCapChanged;

  /// Current query options.
  final DesktopQueryOptions options;

  /// Session parameters retained by the shell.
  final SessionParameters parameters;

  /// Counted attempts in the current in-memory session.
  final int sessionAttempts;

  /// Counted correct attempts in the current in-memory session.
  final int sessionCorrect;

  /// Called when setup parameters change.
  final ValueChanged<SessionParameters> onParametersChanged;

  /// Called when statistics are updated by a rating.
  final ValueChanged<List<UnitStats>> onStatisticsChanged;

  /// Called when live session counters change.
  final LearnSessionProgressChanged onSessionProgressChanged;

  /// Called when the user wants to interrupt and edit the deck.
  final VoidCallback onOpenEditor;

  /// Called when the user changes the start unit on the setup screen.
  final ValueChanged<int>? onStartUnitChanged;

  /// Called when the user manually changes the end unit on the setup screen.
  final ValueChanged<int>? onEndUnitChanged;

  /// Called when the user exits the learn session back to the home screen.
  final VoidCallback? onExit;

  @override
  State<LearnSessionPage> createState() => _LearnSessionPageState();
}

final class _LearnSessionPageState extends State<LearnSessionPage> {
  static const Map<ShortcutActivator, Intent> _kShortcuts =
      <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.f1): _LearnHelpIntent(),
    SingleActivator(LogicalKeyboardKey.f3): _LearnContinueIntent(),
    SingleActivator(LogicalKeyboardKey.enter): _LearnContinueIntent(),
    SingleActivator(LogicalKeyboardKey.f5): _LearnRate1Intent(),
    SingleActivator(LogicalKeyboardKey.f6): _LearnRate2Intent(),
    SingleActivator(LogicalKeyboardKey.f7): _LearnRate3Intent(),
    SingleActivator(LogicalKeyboardKey.f9): _LearnToggleViewIntent(),
    SingleActivator(LogicalKeyboardKey.f10): _LearnRevealIntent(),
    SingleActivator(LogicalKeyboardKey.escape): _LearnSetupIntent(),
  };

  final Random _random = Random();
  final FocusNode _rootFocusNode = FocusNode();
  // Answer widgets are keyed by FieldDefinition.id (the same key unit values
  // use), so renaming or reordering a field never mismatches a controller.
  final Map<int, TextEditingController> _answerControllers =
      <int, TextEditingController>{};
  final Map<int, FocusNode> _answerFocusNodes = <int, FocusNode>{};

  // Prevents rapid-fire unit progression when Enter is held: set to true when
  // Enter triggers Check or Continue, cleared on the next key-up event.
  bool _enterAwaitingRelease = false;

  // Whether the post-check toggle panel shows the solution (true) or the
  // user's typed answer (false). Persists across units within a session;
  // reset to true when a new session starts.
  bool _showSolution = true;

  late SessionParameters _draftParameters;
  late int _startIndex;
  late int _endIndex;
  late int _thresholdPercent;

  List<SessionItem> _order = const <SessionItem>[];
  int _orderPosition = 0;
  Map<int, String> _lastEntered = <int, String>{};

  SessionItem? _currentItem;
  AnswerEvaluation? _evaluation;
  AttemptRating _selectedRating = AttemptRating.noCount;
  Timer? _clockTimer;
  int _elapsedSeconds = 0;
  // Whether the time-limit warning tone has already sounded for the current
  // unit; reset when a new unit is shown so the tone fires once per unit.
  bool _timeTonePlayed = false;
  bool _completed = false;

  // Level Learning: at level 3 the full solution is shown first; the student
  // presses "Hide & type" to memorize it, then types it from an empty field.
  // Reset to false whenever a new unit is shown.
  bool _level3Memorized = false;

  // Session-local Level-Learning ladder: the single source of truth while this
  // page lives, so levels never depend on parent-rebuild timing. Every change
  // is pushed to the shell; the widget value is adopted back only when an
  // external replacement (loading/clearing a .sta) hands us a list instance we
  // did not push ourselves.
  late List<LevelUnitStats> _levelStats;

  // Monotonic serve counter: keys the level-2 scaffold so re-serving the same
  // unit at the same level still starts from empty cells.
  int _serveNonce = 0;

  @override
  void initState() {
    super.initState();
    _levelStats = widget.levelStatistics;
    _draftParameters = _optionsApplied(widget.parameters);
    _startIndex = _draftParameters.startIndex ?? 1;
    _endIndex = _draftParameters.endIndex ?? widget.deck.units.length;
    _thresholdPercent = (_draftParameters.masteryThreshold * 100).round();
    if (widget.options.showClock) {
      _startClock();
    }
  }

  @override
  void didUpdateWidget(LearnSessionPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Adopt an externally replaced ladder (loading/clearing statistics). The
    // lists we push ourselves come back as the identical instance and must not
    // overwrite newer local state.
    if (!identical(widget.levelStatistics, oldWidget.levelStatistics) &&
        !identical(widget.levelStatistics, _levelStats)) {
      _levelStats = widget.levelStatistics;
    }
    _draftParameters = _optionsApplied(_draftParameters);
    if (widget.options.showClock && _clockTimer == null) {
      _startClock();
    } else if (!widget.options.showClock && _clockTimer != null) {
      _clockTimer?.cancel();
      _clockTimer = null;
    }
    if (_currentItem != null &&
        _currentItem!.unitIndex > widget.deck.units.length) {
      _currentItem = null;
      _completed = false;
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _rootFocusNode.dispose();
    for (final TextEditingController controller in _answerControllers.values) {
      controller.dispose();
    }
    for (final FocusNode node in _answerFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      // Outer Focus intercepts Enter key-up to release the anti-rapid-fire
      // guard, without consuming the event (so shortcuts still fire normally).
      onKeyEvent: (FocusNode _, KeyEvent event) {
        if (event is KeyUpEvent) {
          final LogicalKeyboardKey key = event.logicalKey;
          if ((key == LogicalKeyboardKey.enter ||
                  key == LogicalKeyboardKey.numpadEnter) &&
              _enterAwaitingRelease) {
            setState(() => _enterAwaitingRelease = false);
          }
        }
        return KeyEventResult.ignored;
      },
      child: Shortcuts(
        shortcuts: _kShortcuts,
        child: Actions(
          actions: <Type, Action<Intent>>{
            _LearnHelpIntent: CallbackAction<_LearnHelpIntent>(
              onInvoke: (_) {
                _showHelp();
                return null;
              },
            ),
            _LearnContinueIntent: CallbackAction<_LearnContinueIntent>(
              onInvoke: (_) {
                if (_enterAwaitingRelease) return null;
                final bool enterHeld =
                    HardwareKeyboard.instance.isLogicalKeyPressed(
                      LogicalKeyboardKey.enter,
                    ) ||
                    HardwareKeyboard.instance.isLogicalKeyPressed(
                      LogicalKeyboardKey.numpadEnter,
                    );
                _continueShortcut();
                if (enterHeld) setState(() => _enterAwaitingRelease = true);
                return null;
              },
            ),
            _LearnRevealIntent: CallbackAction<_LearnRevealIntent>(
              onInvoke: (_) {
                // Must go through the pre-check dispatcher so F10 respects the
                // level-3 "Hide & type" step instead of evaluating empty input.
                _primaryPreCheck();
                return null;
              },
            ),
            _LearnSetupIntent: CallbackAction<_LearnSetupIntent>(
              onInvoke: (_) {
                _cancelSession();
                return null;
              },
            ),
            _LearnRate1Intent: CallbackAction<_LearnRate1Intent>(
              onInvoke: (_) {
                final AttemptRating? r = _ratingAtIndex(0);
                if (r != null) setState(() => _selectedRating = r);
                return null;
              },
            ),
            _LearnRate2Intent: CallbackAction<_LearnRate2Intent>(
              onInvoke: (_) {
                final AttemptRating? r = _ratingAtIndex(1);
                if (r != null) setState(() => _selectedRating = r);
                return null;
              },
            ),
            _LearnRate3Intent: CallbackAction<_LearnRate3Intent>(
              onInvoke: (_) {
                final AttemptRating? r = _ratingAtIndex(2);
                if (r != null) setState(() => _selectedRating = r);
                return null;
              },
            ),
            _LearnToggleViewIntent: CallbackAction<_LearnToggleViewIntent>(
              onInvoke: (_) {
                if (_evaluation != null && _draftParameters.withInput) {
                  setState(() => _showSolution = !_showSolution);
                  _rootFocusNode.requestFocus();
                }
                return null;
              },
            ),
          },
          child: Focus(
            focusNode: _rootFocusNode,
            autofocus: true,
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              child: _content(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    if (widget.deck.units.isEmpty) {
      return _EmptyLearnState(onOpenEditor: widget.onOpenEditor);
    }
    if (_completed) {
      return _CompletionView(onExtend: _backToSetup);
    }
    if (_currentItem == null) {
      return _SetupView(
        deck: widget.deck,
        parameters: _draftParameters,
        startIndex: _startIndex,
        endIndex: _endIndex,
        thresholdPercent: _thresholdPercent,
        levelNames: widget.levelNames,
        entryLevelCap: widget.entryLevelCap,
        onDirectionChanged: (DirectionSelection value) {
          _applyDraft(_parametersWith(direction: value));
        },
        onModeChanged: (SessionMode value) {
          _applyDraft(_parametersWith(mode: value));
        },
        onEntryLevelCapChanged: (int value) {
          widget.onEntryLevelCapChanged?.call(value);
        },
        onShuffleChanged: (bool value) {
          _applyDraft(_parametersWith(shuffle: value));
        },
        onWithInputChanged: (bool value) {
          _applyDraft(_parametersWith(withInput: value));
        },
        onStartChanged: (int value) {
          setState(() => _startIndex = value);
          widget.onStartUnitChanged?.call(value);
        },
        onEndChanged: (int value) {
          setState(() => _endIndex = value);
          widget.onEndUnitChanged?.call(value);
        },
        onThresholdChanged: (int value) {
          setState(() => _thresholdPercent = value.clamp(1, 100).toInt());
          _applyDraft(_parametersWith(threshold: _thresholdPercent / 100));
        },
        onStartSession: _startSession,
        onCancel: _cancelSession,
      );
    }
    final LearnAnywhereLocalizations messages =
        LearnAnywhereLocalizations.of(context);
    return _SessionView(
      deck: widget.deck,
      statistics: widget.statistics,
      levelStatistics: _levelStats,
      levelNames: widget.levelNames,
      entryLevelCap: widget.entryLevelCap,
      options: widget.options,
      parameters: _draftParameters,
      item: _currentItem!,
      evaluation: _evaluation,
      selectedRating: _selectedRating,
      activeLevel: _isLevelLearning ? _activeLevel : kFreeRecallLevel,
      level3Memorized: _level3Memorized,
      serveNonce: _serveNonce,
      ratingEntries: _evaluation != null
          ? _computeRatingEntries(messages)
          : const <MapEntry<AttemptRating, String>>[],
      answerControllers: _answerControllers,
      answerFocusNodes: _answerFocusNodes,
      enteredAnswers: _lastEntered,
      elapsedSeconds: _elapsedSeconds,
      sessionAttempts: widget.sessionAttempts,
      sessionCorrect: widget.sessionCorrect,
      showSolution: _showSolution,
      onReveal: _primaryPreCheck,
      onCellAnswerChanged: (int fieldId, String value) {
        _answerControllers[fieldId]?.value = TextEditingValue(
          text: value,
          selection: TextSelection.collapsed(offset: value.length),
        );
      },
      onSetLevel: _setLevelManually,
      onRatingChanged: (AttemptRating value) {
        setState(() => _selectedRating = value);
      },
      onToggleView: () {
        setState(() => _showSolution = !_showSolution);
        _rootFocusNode.requestFocus();
      },
      onRestoreFocus: _rootFocusNode.requestFocus,
      onContinue: _continueAfterRating,
      onCancel: _cancelSession,
    );
  }

  void _startSession() {
    final int maxUnit = widget.deck.units.length;
    final int start = _startIndex.clamp(1, maxUnit).toInt();
    final int end = _endIndex.clamp(start, maxUnit).toInt();
    _draftParameters = _parametersWith(
      startIndex: start,
      endIndex: end,
      threshold: _thresholdPercent / 100,
    );
    widget.onParametersChanged(_draftParameters);
    if (_isLevelLearning) {
      // Seed once for every in-scope unit, then persist the ladder: from here
      // on, levels come exclusively from the ladder (promotion moves one level
      // down; only the manual override moves up).
      _levelStats = _materializedLevelStats();
      widget.onLevelStatisticsChanged?.call(_levelStats);
    }
    _order = sessionItemOrder(
      deck: widget.deck,
      parameters: _draftParameters,
      random: _random,
    );
    _orderPosition = 0;
    _showSolution = true;
    _selectNextItem();
  }

  void _backToSetup() {
    setState(() {
      _currentItem = null;
      _completed = false;
    });
    // The "Extend session" button that triggered this is disposed by the
    // view switch, so reclaim root focus for the setup view's shortcuts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _rootFocusNode.requestFocus();
    });
  }

  /// Stores the edited draft and pushes it to the shell so it is persisted.
  void _applyDraft(SessionParameters next) {
    setState(() => _draftParameters = next);
    widget.onParametersChanged(next);
  }

  void _selectNextItem() {
    final SessionItem? next = switch (_draftParameters.mode) {
      SessionMode.superQuery => _firstSuperQueryItem(),
      SessionMode.levelLearning => _firstLevelLearningItem(),
      SessionMode.practice || SessionMode.onceThrough => _nextOrderedItem(),
    };
    if (next == null) {
      setState(() {
        _currentItem = null;
        _completed = true;
        _evaluation = null;
      });
      // The completion view has no focusable answer fields; the button that
      // triggered this transition may be disposed, so reclaim root focus.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _rootFocusNode.requestFocus();
      });
      return;
    }
    _resetAnswerControllers(next);
    setState(() {
      _currentItem = next;
      _evaluation = null;
      _selectedRating = AttemptRating.noCount;
      _elapsedSeconds = 0;
      _timeTonePlayed = false;
      _level3Memorized = false;
      _serveNonce += 1;
    });
    // Reclaim root focus unless an answer field (or the level-2 scaffold, which
    // autofocuses itself) will claim it. This covers think-only mode (no fields)
    // and the level-3 pre-memorize step, keeping the F-keys/Esc/primary action
    // live there.
    final int level = _isLevelLearning
        ? _levelStatsFor(next).currentLevel
        : kFreeRecallLevel;
    final bool editableNow = !_isLevelLearning || level == kFreeRecallLevel;
    final bool scaffold = _usesScaffoldInput(level);
    final bool focusHandled =
        _answerFocusNodes.isNotEmpty && (editableNow || scaffold);
    if (!focusHandled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _rootFocusNode.requestFocus();
      });
    }
  }

  /// Returns the next item from the precomputed presentation order.
  ///
  /// In once-through mode each item is served once, then `null` ends the
  /// session; in endless mode the order repeats indefinitely.
  SessionItem? _nextOrderedItem() {
    if (_order.isEmpty) {
      return null;
    }
    if (_draftParameters.mode == SessionMode.onceThrough) {
      if (_orderPosition >= _order.length) {
        return null;
      }
      return _order[_orderPosition++];
    }
    final SessionItem item = _order[_orderPosition % _order.length];
    _orderPosition += 1;
    return item;
  }

  SessionItem? _firstSuperQueryItem() {
    final List<SessionItem> pool = activeSuperQueryPool(
      deck: widget.deck,
      statistics: widget.statistics,
      parameters: _draftParameters,
    );
    if (pool.isEmpty) {
      return null;
    }
    return pool[_random.nextInt(pool.length)];
  }

  SessionItem? _firstLevelLearningItem() {
    final List<SessionItem> pool = activeLevelLearningPool(
      deck: widget.deck,
      statistics: widget.statistics,
      levelStatistics: _levelStats,
      parameters: _draftParameters,
      entryLevelCap: widget.entryLevelCap,
    );
    if (pool.isEmpty) {
      return null;
    }
    return pool[_random.nextInt(pool.length)];
  }

  /// Returns the Level-Learning stats for [item] from the session ladder.
  ///
  /// Falls back to a fresh seed (from the unit's prior drill bucket, capped by
  /// the entry level) only for units without an entry — after
  /// [_materializedLevelStats] ran at session start this is a rare safety net,
  /// not the normal path, so levels stay stable.
  LevelDirectionStats _levelStatsFor(SessionItem item) {
    for (final LevelUnitStats stats in _levelStats) {
      if (stats.index == item.unitIndex) {
        return stats.statsFor(item.direction);
      }
    }
    final UnitStats unitStats = _normalizedStats()[item.unitIndex - 1];
    return seedLevelLearningStats(
      unitStats.statsFor(item.direction),
      entryLevelCap: widget.entryLevelCap,
    );
  }

  /// The active support level (`0..3`) for the current Level-Learning unit.
  int get _activeLevel {
    final SessionItem? item = _currentItem;
    if (item == null) return kFreeRecallLevel;
    return _levelStatsFor(item).currentLevel;
  }

  bool get _isLevelLearning =>
      _draftParameters.mode == SessionMode.levelLearning;

  /// Whether [level] uses the editable cell scaffold (levels 1 and 2), which
  /// owns its own per-cell focus.
  bool _usesScaffoldInput(int level) =>
      _isLevelLearning && (level == 1 || level == 2);

  /// Enters the level-3 "type it from memory" step: hides the shown solution
  /// and focuses the (now editable) answer field.
  void _memorizeLevel3() {
    setState(() => _level3Memorized = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final FocusNode? node = _answerFocusNodes.values.isEmpty
          ? null
          : _answerFocusNodes.values.first;
      (node ?? _rootFocusNode).requestFocus();
    });
  }

  /// Returns the level statistics with [item]'s direction replaced by [stats],
  /// materializing a per-unit entry (seeding the other direction) when the unit
  /// was still relying on on-the-fly seeding.
  List<LevelUnitStats> _levelStatsWith(
    SessionItem item,
    LevelDirectionStats stats,
  ) {
    final Map<int, LevelUnitStats> byIndex = <int, LevelUnitStats>{
      for (final LevelUnitStats s in _levelStats) s.index: s,
    };
    final LevelUnitStats existing =
        byIndex[item.unitIndex] ??
        LevelUnitStats(
          index: item.unitIndex,
          dir1: _levelStatsFor(
            SessionItem(
              unitIndex: item.unitIndex,
              direction: QueryDirection.direction1,
            ),
          ),
          dir2: _levelStatsFor(
            SessionItem(
              unitIndex: item.unitIndex,
              direction: QueryDirection.direction2,
            ),
          ),
        );
    byIndex[item.unitIndex] = existing.withDirectionStats(item.direction, stats);
    final List<LevelUnitStats> next =
        byIndex.values.toList(growable: false)
          ..sort((LevelUnitStats a, LevelUnitStats b) => a.index - b.index);
    return List<LevelUnitStats>.unmodifiable(next);
  }

  /// Applies [stats] for [item] to the session ladder and pushes it upstream.
  void _pushLevelStats(SessionItem item, LevelDirectionStats stats) {
    _levelStats = _levelStatsWith(item, stats);
    widget.onLevelStatisticsChanged?.call(_levelStats);
  }

  /// Returns the ladder with fresh seeds materialized for every in-scope unit
  /// that has no entry yet.
  ///
  /// Runs once per session start so the seeding (from the unit's prior drill
  /// bucket, capped by the entry level) is a one-time assignment; afterwards
  /// the ladder alone owns each unit's level. Existing entries are untouched,
  /// so re-starting or extending a session never resets progress.
  List<LevelUnitStats> _materializedLevelStats() {
    final Map<int, LevelUnitStats> byIndex = <int, LevelUnitStats>{
      for (final LevelUnitStats s in _levelStats) s.index: s,
    };
    final List<UnitStats> normalized = _normalizedStats();
    final int maxUnit = widget.deck.units.length;
    final int start = (_draftParameters.startIndex ?? 1).clamp(1, maxUnit);
    final int end = (_draftParameters.endIndex ?? maxUnit).clamp(start, maxUnit);
    for (var index = start; index <= end; index += 1) {
      if (byIndex.containsKey(index)) {
        continue;
      }
      final UnitStats unitStats = normalized[index - 1];
      byIndex[index] = LevelUnitStats(
        index: index,
        dir1: seedLevelLearningStats(
          unitStats.statsFor(QueryDirection.direction1),
          entryLevelCap: widget.entryLevelCap,
        ),
        dir2: seedLevelLearningStats(
          unitStats.statsFor(QueryDirection.direction2),
          entryLevelCap: widget.entryLevelCap,
        ),
      );
    }
    final List<LevelUnitStats> next =
        byIndex.values.toList(growable: false)
          ..sort((LevelUnitStats a, LevelUnitStats b) => a.index - b.index);
    return List<LevelUnitStats>.unmodifiable(next);
  }

  /// Manual level override (no penalty): moves the current unit to [newLevel]
  /// and restarts that level's track record. Also restarts the unit locally.
  void _setLevelManually(int newLevel) {
    final SessionItem? item = _currentItem;
    if (item == null || newLevel == _activeLevel || !isValidLevel(newLevel)) {
      return;
    }
    final LevelDirectionStats moved = setLevelLearningLevel(
      _levelStatsFor(item),
      newLevel,
    );
    _pushLevelStats(item, moved);
    // Restart the current prompt so the new level's scaffold is shown fresh.
    _resetAnswerControllers(item);
    setState(() {
      _evaluation = null;
      _selectedRating = AttemptRating.noCount;
      _level3Memorized = false;
      // Force a fresh scaffold (new key) so switching level 1<->2 clears cells.
      _serveNonce += 1;
    });
  }

  void _resetAnswerControllers(SessionItem item) {
    for (final TextEditingController c in _answerControllers.values) {
      c.dispose();
    }
    for (final FocusNode n in _answerFocusNodes.values) {
      n.dispose();
    }
    _answerControllers.clear();
    _answerFocusNodes.clear();
    _enterAwaitingRelease = false;
    if (!_draftParameters.withInput) {
      return;
    }
    final LearningUnit unit = widget.deck.units[item.unitIndex - 1];
    final List<FieldDefinition> fields = answerFields(
      widget.deck,
      unit,
      item.direction,
    ).keys.toList(growable: false);
    for (int i = 0; i < fields.length; i++) {
      final FieldDefinition field = fields[i];
      final bool isLast = i == fields.length - 1;
      _answerControllers[field.id] = TextEditingController();
      _answerFocusNodes[field.id] = FocusNode(
        onKeyEvent: (FocusNode node, KeyEvent event) =>
            _handleAnswerFieldKey(node, event, isLast),
      );
    }
    // A reset always begins a fresh prompt: only the normal text field (any
    // non-LL field, or LL level 0) takes focus immediately. The level-1/2
    // scaffold and the level-3 memorize step claim focus themselves.
    final int level = _isLevelLearning
        ? _levelStatsFor(item).currentLevel
        : kFreeRecallLevel;
    final bool editableNow = !_isLevelLearning || level == kFreeRecallLevel;
    if (_answerFocusNodes.isNotEmpty && editableNow) {
      final FocusNode firstNode = _answerFocusNodes.values.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) firstNode.requestFocus();
      });
    }
  }

  /// Key handler for answer input fields.
  ///
  /// Tab always moves to the next answer field. Enter on a non-last field also
  /// advances; on the last field Enter triggers Check (before reveal) or
  /// Continue (after reveal). A mandatory key-release cycle prevents the held
  /// Enter key from racing through multiple units.
  KeyEventResult _handleAnswerFieldKey(
    FocusNode node,
    KeyEvent event,
    bool isLast,
  ) {
    final LogicalKeyboardKey key = event.logicalKey;
    final bool isEnter =
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;
    final bool isForwardTab =
        key == LogicalKeyboardKey.tab &&
        !HardwareKeyboard.instance.isShiftPressed;

    // Track key-up to release the anti-rapid-fire guard.
    if (isEnter && event is KeyUpEvent) {
      if (_enterAwaitingRelease) {
        setState(() => _enterAwaitingRelease = false);
      }
      return KeyEventResult.ignored;
    }

    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (isEnter) {
      if (_enterAwaitingRelease) return KeyEventResult.handled;
      if (!isLast) {
        node.nextFocus();
        return KeyEventResult.handled;
      }
      // Last answer field: trigger Check or Continue.
      setState(() => _enterAwaitingRelease = true);
      if (_evaluation == null) {
        _primaryPreCheck();
      } else {
        _continueAfterRating();
      }
      return KeyEventResult.handled;
    }

    if (isForwardTab) {
      node.nextFocus();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// The pre-check primary action. In Level Learning at level 3 before the
  /// solution has been memorized this hides it and starts typing; otherwise it
  /// checks/reveals the answer.
  void _primaryPreCheck() {
    if (_isLevelLearning &&
        _activeLevel == kMaxSupportLevel &&
        !_level3Memorized) {
      _memorizeLevel3();
      return;
    }
    _reveal();
  }

  void _reveal() {
    final SessionItem? item = _currentItem;
    if (item == null || _evaluation != null) {
      return;
    }
    final LearningUnit unit = widget.deck.units[item.unitIndex - 1];
    // Capture the raw typed text so the result screen can show it back to the
    // user alongside the correct answer.
    final Map<int, String> entered = <int, String>{
      for (final MapEntry<int, TextEditingController> e
          in _answerControllers.entries)
        e.key: e.value.text,
    };
    final AnswerEvaluation? evaluation = _draftParameters.withInput
        ? evaluateAnswer(
            deck: widget.deck,
            unit: unit,
            direction: item.direction,
            enteredValues: <int, FieldValue>{
              for (final MapEntry<int, String> entry in entered.entries)
                entry.key: FieldValue.plain(entry.value),
            },
            options: widget.options.evaluationOptions,
          )
        : null;
    final AttemptRating defaultRating = _draftParameters.withInput
        ? (evaluation!.correct ? AttemptRating.correct : AttemptRating.wrong)
        : AttemptRating.correct;
    setState(() {
      _lastEntered = entered;
      _evaluation =
          evaluation ??
          const AnswerEvaluation(correct: true, fields: <FieldEvaluation>[]);
      _selectedRating = defaultRating;
    });
    // Revealing removes the answer text fields (they become read-only rich
    // text), so focus would be left on a defunct node and the F-keys/Esc would
    // stop working. Pull focus back to the session root.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _rootFocusNode.requestFocus();
    });
  }

  void _continueShortcut() {
    if (_currentItem == null) {
      _startSession();
    } else if (_evaluation == null) {
      _primaryPreCheck();
    } else {
      _continueAfterRating();
    }
  }

  void _continueAfterRating() {
    final SessionItem? item = _currentItem;
    if (item == null || _evaluation == null) {
      return;
    }
    if (_isLevelLearning) {
      // Level Learning records exclusively into the level ladder. The drill
      // statistics stay untouched — they only influence the one-time initial
      // level assignment at session start.
      final LevelDirectionStats after = recordLevelLearningAttempt(
        _levelStatsFor(item),
        _selectedRating,
        parameters: _draftParameters,
      );
      _pushLevelStats(item, after);
    } else {
      final List<UnitStats> updated = _recordRating(item, _selectedRating);
      widget.onStatisticsChanged(updated);
    }
    // Attempts counts every check→continue cycle; correct counts only
    // correct-rated attempts (accuracy is correct/attempts).
    final bool correct = _selectedRating == AttemptRating.correct;
    widget.onSessionProgressChanged(
      widget.sessionAttempts + 1,
      widget.sessionCorrect + (correct ? 1 : 0),
    );
    _selectNextItem();
  }

  List<UnitStats> _recordRating(SessionItem item, AttemptRating rating) {
    final List<UnitStats> stats = _normalizedStats();
    final UnitStats current = stats[item.unitIndex - 1];
    final DirectionStats directionStats = current.statsFor(item.direction);
    final DirectionStats updatedDirection = recordAttempt(
      directionStats,
      rating,
      wrongAnswerCeiling: widget.options.wrongAnswerCeilingOptions,
    );
    stats[item.unitIndex - 1] = current.withDirectionStats(
      item.direction,
      updatedDirection,
    );
    return List<UnitStats>.unmodifiable(stats);
  }

  List<UnitStats> _normalizedStats() {
    final Map<int, UnitStats> byIndex = <int, UnitStats>{
      for (final UnitStats stats in widget.statistics) stats.index: stats,
    };
    return List<UnitStats>.generate(
      widget.deck.units.length,
      (int index) => byIndex[index + 1] ?? UnitStats(index: index + 1),
    );
  }

  /// Overlays the advanced-options mastery guard onto setup [parameters].
  ///
  /// The "require typed answers" toggle now lives on the practice-setup screen,
  /// so [SessionParameters.withInput] is taken from the parameters, while the
  /// minimum-attempts guard still comes from the advanced options.
  SessionParameters _optionsApplied(SessionParameters parameters) {
    return parameters.copyWith(
      // Level Learning is always "with input" (every level ends in typing).
      withInput:
          parameters.mode == SessionMode.levelLearning
          ? true
          : parameters.withInput,
      minimumAttemptsGuardEnabled: widget.options.minimumAttemptsGuardEnabled,
      minAttempts: widget.options.minAttempts,
    );
  }

  SessionParameters _parametersWith({
    DirectionSelection? direction,
    int? startIndex,
    int? endIndex,
    bool? withInput,
    SessionMode? mode,
    bool? shuffle,
    double? threshold,
  }) {
    final SessionMode nextMode = mode ?? _draftParameters.mode;
    return SessionParameters(
      directionSelection: direction ?? _draftParameters.directionSelection,
      startIndex: startIndex ?? _draftParameters.startIndex,
      endIndex: endIndex ?? _draftParameters.endIndex,
      // Level Learning always types its answers; force the flag on there.
      withInput: nextMode == SessionMode.levelLearning
          ? true
          : (withInput ?? _draftParameters.withInput),
      mode: nextMode,
      shuffle: shuffle ?? _draftParameters.shuffle,
      masteryThreshold: threshold ?? _draftParameters.masteryThreshold,
      minimumAttemptsGuardEnabled: widget.options.minimumAttemptsGuardEnabled,
      minAttempts: widget.options.minAttempts,
    );
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _currentItem == null) {
        return;
      }
      setState(() => _elapsedSeconds += 1);
      // Sound a one-shot warning tone the first second the limit is reached
      // (0 = no limit). The visual red pill is driven separately in the view.
      final int limit = widget.options.timeLimitSeconds;
      if (limit > 0 && _elapsedSeconds >= limit && !_timeTonePlayed) {
        _timeTonePlayed = true;
        SystemSound.play(SystemSoundType.alert);
      }
    });
  }

  void _showHelp() {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(messages.message(LearnAnywhereMessage.desktopHintBar)),
      ),
    );
  }

  /// Returns the ordered rating entries shown as evaluation buttons.
  /// Must match the ordering used by [_ratingAtIndex].
  List<MapEntry<AttemptRating, String>> _computeRatingEntries(
    LearnAnywhereLocalizations messages,
  ) {
    if (!_draftParameters.withInput) {
      return <MapEntry<AttemptRating, String>>[
        MapEntry<AttemptRating, String>(
          AttemptRating.correct,
          messages.message(LearnAnywhereMessage.learnRatingKnewIt),
        ),
        MapEntry<AttemptRating, String>(
          AttemptRating.wrong,
          messages.message(LearnAnywhereMessage.learnRatingDidNotKnow),
        ),
        MapEntry<AttemptRating, String>(
          AttemptRating.noCount,
          messages.message(LearnAnywhereMessage.learnRatingNoCount),
        ),
      ];
    }
    if (_evaluation!.correct) {
      return <MapEntry<AttemptRating, String>>[
        MapEntry<AttemptRating, String>(
          AttemptRating.correct,
          messages.message(LearnAnywhereMessage.learnRatingCorrect),
        ),
        MapEntry<AttemptRating, String>(
          AttemptRating.wrong,
          messages.message(LearnAnywhereMessage.learnRatingActuallyWrong),
        ),
        MapEntry<AttemptRating, String>(
          AttemptRating.noCount,
          messages.message(LearnAnywhereMessage.learnRatingNoCount),
        ),
      ];
    }
    return <MapEntry<AttemptRating, String>>[
      MapEntry<AttemptRating, String>(
        AttemptRating.wrong,
        messages.message(LearnAnywhereMessage.learnRatingWrong),
      ),
      if (widget.options.wrongInputCorrectable)
        MapEntry<AttemptRating, String>(
          AttemptRating.correct,
          messages.message(LearnAnywhereMessage.learnRatingActuallyCorrect),
        ),
      MapEntry<AttemptRating, String>(
        AttemptRating.noCount,
        messages.message(LearnAnywhereMessage.learnRatingNoCount),
      ),
    ];
  }

  /// Returns the [AttemptRating] at the given 0-based index in the rating
  /// list, or null when the index is out of range or no evaluation is active.
  /// Must match the ordering used by [_computeRatingEntries].
  AttemptRating? _ratingAtIndex(int index) {
    if (_evaluation == null) return null;
    if (!_draftParameters.withInput) {
      const List<AttemptRating> r = <AttemptRating>[
        AttemptRating.correct,
        AttemptRating.wrong,
        AttemptRating.noCount,
      ];
      return index < r.length ? r[index] : null;
    }
    if (_evaluation!.correct) {
      const List<AttemptRating> r = <AttemptRating>[
        AttemptRating.correct,
        AttemptRating.wrong,
        AttemptRating.noCount,
      ];
      return index < r.length ? r[index] : null;
    }
    final List<AttemptRating> r = <AttemptRating>[
      AttemptRating.wrong,
      if (widget.options.wrongInputCorrectable) AttemptRating.correct,
      AttemptRating.noCount,
    ];
    return index < r.length ? r[index] : null;
  }

  Future<void> _cancelSession() async {
    // On the setup or completion screens there are no live stats to lose, so
    // exit straight to the home screen without a confirmation prompt.
    if (_currentItem == null) {
      widget.onExit?.call();
      return;
    }
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(messages.message(LearnAnywhereMessage.confirmTitle)),
          content: Text(
            messages.message(LearnAnywhereMessage.learnCancelConfirm),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(messages.message(LearnAnywhereMessage.actionCancel)),
            ),
            FilledButton(
              autofocus: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                messages.message(LearnAnywhereMessage.actionContinue),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed == true && mounted) {
      widget.onExit?.call();
    }
  }
}

final class _EmptyLearnState extends StatelessWidget {
  const _EmptyLearnState({required this.onOpenEditor});

  final VoidCallback onOpenEditor;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return Padding(
      padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            messages.message(LearnAnywhereMessage.learnEmptyTitle),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: LearnAnywhereTokens.gapSmall),
          Text(messages.message(LearnAnywhereMessage.learnEmptyBody)),
          const SizedBox(height: LearnAnywhereTokens.gapMedium),
          FilledButton.icon(
            onPressed: onOpenEditor,
            icon: const Icon(Icons.edit),
            label: Text(messages.message(LearnAnywhereMessage.menuEdit)),
          ),
        ],
      ),
    );
  }
}

final class _SetupView extends StatelessWidget {
  const _SetupView({
    required this.deck,
    required this.parameters,
    required this.startIndex,
    required this.endIndex,
    required this.thresholdPercent,
    required this.levelNames,
    required this.entryLevelCap,
    required this.onDirectionChanged,
    required this.onModeChanged,
    required this.onEntryLevelCapChanged,
    required this.onShuffleChanged,
    required this.onWithInputChanged,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.onThresholdChanged,
    required this.onStartSession,
    required this.onCancel,
  });

  final LearningDeck deck;
  final SessionParameters parameters;
  final int startIndex;
  final int endIndex;
  final int thresholdPercent;
  final List<String> levelNames;
  final int entryLevelCap;
  final ValueChanged<DirectionSelection> onDirectionChanged;
  final ValueChanged<SessionMode> onModeChanged;
  final ValueChanged<int> onEntryLevelCapChanged;
  final ValueChanged<bool> onShuffleChanged;
  final ValueChanged<bool> onWithInputChanged;
  final ValueChanged<int> onStartChanged;
  final ValueChanged<int> onEndChanged;
  final ValueChanged<int> onThresholdChanged;
  final VoidCallback onStartSession;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final bool isLevelLearning = parameters.mode == SessionMode.levelLearning;
    return ListView(
      padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
      children: <Widget>[
        Text(
          messages.message(LearnAnywhereMessage.learnSetupTitle),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: LearnAnywhereTokens.gapMedium),
        _DropdownRow<DirectionSelection>(
          label: messages.message(LearnAnywhereMessage.learnDirection),
          value: parameters.directionSelection,
          items: <DropdownMenuItem<DirectionSelection>>[
            DropdownMenuItem<DirectionSelection>(
              value: DirectionSelection.direction1,
              child: Text(deck.mask.direction1Label),
            ),
            DropdownMenuItem<DirectionSelection>(
              value: DirectionSelection.direction2,
              child: Text(deck.mask.direction2Label),
            ),
            DropdownMenuItem<DirectionSelection>(
              value: DirectionSelection.both,
              child: Text(
                messages.message(LearnAnywhereMessage.learnBothDirections),
              ),
            ),
          ],
          onChanged: onDirectionChanged,
        ),
        _DropdownRow<SessionMode>(
          label: messages.message(LearnAnywhereMessage.learnMode),
          value: parameters.mode,
          items: <DropdownMenuItem<SessionMode>>[
            DropdownMenuItem<SessionMode>(
              value: SessionMode.levelLearning,
              child: Text(
                messages.message(LearnAnywhereMessage.learnModeLevelLearning),
              ),
            ),
            DropdownMenuItem<SessionMode>(
              value: SessionMode.superQuery,
              child: Text(
                messages.message(LearnAnywhereMessage.learnModeSuperQuery),
              ),
            ),
            DropdownMenuItem<SessionMode>(
              value: SessionMode.practice,
              child: Text(
                messages.message(LearnAnywhereMessage.learnModePractice),
              ),
            ),
            DropdownMenuItem<SessionMode>(
              value: SessionMode.onceThrough,
              child: Text(
                messages.message(LearnAnywhereMessage.learnModeOnceThrough),
              ),
            ),
          ],
          onChanged: onModeChanged,
        ),
        // Level Learning caps the highest starting support; the whole ladder
        // always ends in typing, so the think-only toggle does not apply.
        if (isLevelLearning) ...<Widget>[
          _DropdownRow<int>(
            label: messages.message(LearnAnywhereMessage.learnEntryLevel),
            value: entryLevelCap.clamp(kFreeRecallLevel, kMaxSupportLevel),
            items: <DropdownMenuItem<int>>[
              for (int level = kMaxSupportLevel;
                  level >= kFreeRecallLevel;
                  level -= 1)
                DropdownMenuItem<int>(
                  value: level,
                  child: Text(
                    level == kMaxSupportLevel
                        ? levelNameFor(levelNames, level) +
                              messages.message(
                                LearnAnywhereMessage.learnEntryLevelNoCapSuffix,
                              )
                        : levelNameFor(levelNames, level),
                  ),
                ),
            ],
            onChanged: onEntryLevelCapChanged,
          ),
          Padding(
            padding: const EdgeInsets.only(
              bottom: LearnAnywhereTokens.gapMedium,
            ),
            child: Text(
              messages.message(LearnAnywhereMessage.learnEntryLevelHint),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _NumberRow(
              label: messages.message(LearnAnywhereMessage.learnRangeStart),
              value: startIndex,
              minimum: 1,
              onChanged: onStartChanged,
            ),
            const SizedBox(width: LearnAnywhereTokens.gapMedium),
            _NumberRow(
              label: messages.message(LearnAnywhereMessage.learnRangeEnd),
              value: endIndex,
              minimum: 1,
              onChanged: onEndChanged,
            ),
          ],
        ),
        // Level Learning is always "with input", so the toggle is hidden there.
        if (!isLevelLearning)
          SwitchListTile(
            title: Text(
              messages.message(LearnAnywhereMessage.queryOptionWithAnswerInput),
            ),
            value: parameters.withInput,
            onChanged: onWithInputChanged,
          ),
        SwitchListTile(
          title: Text(
            messages.message(LearnAnywhereMessage.learnShuffleUnits),
          ),
          value: parameters.shuffle,
          onChanged: onShuffleChanged,
        ),
        _NumberRow(
          label: messages.message(LearnAnywhereMessage.learnMasteryThreshold),
          value: thresholdPercent,
          minimum: 1,
          maximum: 100,
          onChanged: onThresholdChanged,
        ),
        const SizedBox(height: LearnAnywhereTokens.gapMedium),
        Wrap(
          spacing: LearnAnywhereTokens.gapSmall,
          children: <Widget>[
            FilledButton.icon(
              onPressed: onStartSession,
              icon: const Icon(Icons.play_arrow),
              label: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(messages.message(LearnAnywhereMessage.learnStartSession)),
                  const Text('F3', style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: onCancel,
              icon: const Icon(Icons.close),
              label: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(messages.message(LearnAnywhereMessage.actionCancel)),
                  const Text('Esc', style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

final class _SessionView extends StatelessWidget {
  const _SessionView({
    required this.deck,
    required this.statistics,
    required this.levelStatistics,
    required this.levelNames,
    required this.entryLevelCap,
    required this.options,
    required this.parameters,
    required this.item,
    required this.evaluation,
    required this.selectedRating,
    required this.activeLevel,
    required this.level3Memorized,
    required this.serveNonce,
    required this.ratingEntries,
    required this.answerControllers,
    required this.answerFocusNodes,
    required this.enteredAnswers,
    required this.elapsedSeconds,
    required this.sessionAttempts,
    required this.sessionCorrect,
    required this.showSolution,
    required this.onReveal,
    required this.onCellAnswerChanged,
    required this.onSetLevel,
    required this.onRatingChanged,
    required this.onToggleView,
    required this.onRestoreFocus,
    required this.onContinue,
    required this.onCancel,
  });

  final LearningDeck deck;
  final List<UnitStats> statistics;
  final List<LevelUnitStats> levelStatistics;
  final List<String> levelNames;
  final int entryLevelCap;
  final DesktopQueryOptions options;
  final SessionParameters parameters;
  final SessionItem item;
  final AnswerEvaluation? evaluation;
  final AttemptRating selectedRating;

  /// The active support level (`0..3`) when in Level Learning; ignored otherwise.
  final int activeLevel;

  /// Whether the level-3 solution has been memorized (typing phase reached).
  final bool level3Memorized;

  /// Monotonic serve counter; keys the level-2 scaffold so re-serving the same
  /// unit at the same level starts from empty cells.
  final int serveNonce;
  final List<MapEntry<AttemptRating, String>> ratingEntries;
  final Map<int, TextEditingController> answerControllers;
  final Map<int, FocusNode> answerFocusNodes;
  final Map<int, String> enteredAnswers;
  final int elapsedSeconds;
  final int sessionAttempts;
  final int sessionCorrect;
  final bool showSolution;
  final VoidCallback onReveal;

  /// Called by the editable level-2 scaffold with the reconstructed answer.
  final void Function(int fieldId, String value) onCellAnswerChanged;

  /// Manual level override (More/Less help) for the current unit+direction.
  final ValueChanged<int> onSetLevel;
  final ValueChanged<AttemptRating> onRatingChanged;
  final VoidCallback onToggleView;
  final VoidCallback onRestoreFocus;
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  bool get _isLevelLearning => parameters.mode == SessionMode.levelLearning;

  /// Builds the live-stats pills: Attempts first, then mode-specific fields.
  ///
  /// Non-Level-Learning: Mastered / Remaining / Accuracy `x/y (z%)`. Level
  /// Learning: one pill per level (highest support first) with the count of
  /// in-scope units at that level and its share. The clock pill is appended for
  /// both when enabled.
  List<Widget> _statPills(
    LearnAnywhereLocalizations messages,
    bool timeWarning,
  ) {
    final int totalItems = _totalItems(deck, parameters);
    final List<Widget> pills = <Widget>[
      _StatPill(
        label: messages.message(LearnAnywhereMessage.learnLiveAttempts),
        value: '$sessionAttempts',
      ),
    ];
    if (_isLevelLearning) {
      final Map<int, int> counts = _levelCounts();
      var inPool = 0;
      for (int level = kMaxSupportLevel;
          level >= kFreeRecallLevel;
          level -= 1) {
        final int count = counts[level] ?? 0;
        inPool += count;
        final int pct =
            totalItems == 0 ? 0 : ((count / totalItems) * 100).round();
        pills.add(
          _StatPill(
            label: levelNameFor(levelNames, level),
            value: '$count ($pct%)',
          ),
        );
      }
      // Units that have left the pool (mastered at level 0).
      final int mastered = (totalItems - inPool).clamp(0, totalItems);
      final int masteredPct =
          totalItems == 0 ? 0 : ((mastered / totalItems) * 100).round();
      pills.add(
        _StatPill(
          label: messages.message(LearnAnywhereMessage.learnLiveMastered),
          value: '$mastered ($masteredPct%)',
        ),
      );
    } else {
      final List<SessionItem> pool = activeSuperQueryPool(
        deck: deck,
        statistics: statistics,
        parameters: parameters,
      );
      final int mastered = (totalItems - pool.length).clamp(0, totalItems);
      final int pct = sessionAttempts == 0
          ? 0
          : ((sessionCorrect / sessionAttempts) * 100).round();
      pills.addAll(<Widget>[
        _StatPill(
          label: messages.message(LearnAnywhereMessage.learnLiveMastered),
          value: '$mastered/$totalItems',
        ),
        _StatPill(
          label: messages.message(LearnAnywhereMessage.learnLiveRemaining),
          value: '${pool.length}',
        ),
        _StatPill(
          label: messages.message(LearnAnywhereMessage.learnLiveAccuracy),
          value: '$sessionCorrect/$sessionAttempts ($pct%)',
        ),
      ]);
    }
    if (options.showClock) {
      pills.add(
        _StatPill(
          label: messages.message(LearnAnywhereMessage.learnLiveTime),
          value: _clockText(elapsedSeconds),
          warning: timeWarning,
        ),
      );
    }
    return pills;
  }

  /// Counts in-scope, not-yet-mastered Level-Learning units by current level.
  Map<int, int> _levelCounts() {
    final List<SessionItem> pool = activeLevelLearningPool(
      deck: deck,
      statistics: statistics,
      levelStatistics: levelStatistics,
      parameters: parameters,
      entryLevelCap: entryLevelCap,
    );
    final Map<int, LevelUnitStats> byIndex = <int, LevelUnitStats>{
      for (final LevelUnitStats s in levelStatistics) s.index: s,
    };
    final Map<int, UnitStats> statsByIndex = <int, UnitStats>{
      for (final UnitStats s in statistics) s.index: s,
    };
    final Map<int, int> counts = <int, int>{
      for (int level = kMaxSupportLevel;
          level >= kFreeRecallLevel;
          level -= 1)
        level: 0,
    };
    for (final SessionItem poolItem in pool) {
      final LevelUnitStats? ls = byIndex[poolItem.unitIndex];
      final LevelDirectionStats dir = ls != null
          ? ls.statsFor(poolItem.direction)
          : seedLevelLearningStats(
              (statsByIndex[poolItem.unitIndex] ??
                      UnitStats(index: poolItem.unitIndex))
                  .statsFor(poolItem.direction),
              entryLevelCap: entryLevelCap,
            );
      counts[dir.currentLevel] = (counts[dir.currentLevel] ?? 0) + 1;
    }
    return counts;
  }

  /// Builds the bordered field grid (one row per visible field).
  Widget _fieldGrid(
    BuildContext context,
    List<FieldDefinition> visibleFields,
    LearningUnit unit,
  ) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    int? firstAnswerId;
    for (final FieldDefinition f in visibleFields) {
      if (f.roleFor(item.direction) == FieldRole.answer) {
        firstAnswerId = f.id;
        break;
      }
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Column(
          children: <Widget>[
            for (int i = 0; i < visibleFields.length; i++) ...<Widget>[
              if (i > 0) Container(height: 1, color: colors.outlineVariant),
              Builder(
                builder: (BuildContext ctx) {
                  final FieldDefinition field = visibleFields[i];
                  final FieldRole role = field.roleFor(item.direction);
                  final double bgOpacity =
                      Theme.of(ctx).brightness == Brightness.light ? 0.15 : 0.10;

                  final bool showUserAnswer =
                      role == FieldRole.answer &&
                      evaluation != null &&
                      parameters.withInput &&
                      !showSolution;

                  final Color accentColor;
                  final Color bgColor;
                  final FieldValue displayValue;

                  if (showUserAnswer) {
                    final ColorScheme rowColors = Theme.of(ctx).colorScheme;
                    accentColor = rowColors.outline;
                    bgColor = rowColors.surfaceContainerHighest;
                    displayValue = FieldValue.plain(
                      enteredAnswers[field.id] ?? '',
                    );
                  } else {
                    accentColor = switch (role) {
                      FieldRole.question => const Color.fromRGBO(0, 150, 180, 1),
                      FieldRole.answer => const Color.fromRGBO(0, 160, 80, 1),
                      FieldRole.remark => const Color.fromRGBO(200, 140, 0, 1),
                    };
                    bgColor = accentColor.withValues(alpha: bgOpacity);
                    displayValue = unit.valueForFieldId(field.id);
                  }

                  final Widget? override =
                      (_isLevelLearning &&
                          role == FieldRole.answer &&
                          evaluation == null)
                      ? _levelAnswerContent(
                          ctx,
                          field,
                          unit,
                          field.id == firstAnswerId,
                        )
                      : null;

                  return _PracticeGridRow(
                    field: field,
                    role: role,
                    value: displayValue,
                    bgColor: bgColor,
                    accentColor: accentColor,
                    evaluation: evaluation,
                    withInput: parameters.withInput,
                    enteredText: enteredAnswers[field.id],
                    controller: answerControllers[field.id],
                    focusNode: answerFocusNodes[field.id],
                    contentOverride: override,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// The Level-Learning answer widget for [field] at the active level, or null
  /// to fall back to a normal editable text field (levels 0 and memorized 3).
  Widget? _levelAnswerContent(
    BuildContext ctx,
    FieldDefinition field,
    LearningUnit unit,
    bool autofocus,
  ) {
    final String plain = unit.valueForFieldId(field.id).plainText;
    final int level = activeLevel;
    final TextStyle style =
        Theme.of(ctx).textTheme.bodyMedium?.copyWith(
          fontFamilyFallback: LearnAnywhereTokens.monospaceFallback,
        ) ??
        const TextStyle();

    if (level == kMaxSupportLevel) {
      // Show the full solution to read; typing starts only after Hide & type.
      if (!level3Memorized) {
        return _ScaffoldPreview(
          cells: maskFieldValue(plain, kMaxSupportLevel),
          textStyle: style,
        );
      }
      return null;
    }
    if (level == 1 || level == 2) {
      // Both fill blanks in place: level 2 reveals every other letter, level 1
      // only the first and last. The student types into the empty cells.
      return _LevelScaffoldInput(
        // The nonce guarantees a fresh scaffold (empty cells) on every serve,
        // even when the same unit+level is presented twice in a row.
        key: ValueKey<String>('scaffold-$serveNonce-${field.id}'),
        cells: maskFieldValue(plain, level),
        textStyle: style,
        autofocus: autofocus,
        onChanged: (String value) => onCellAnswerChanged(field.id, value),
        onSubmit: onReveal,
      );
    }
    return null;
  }

  /// Pre-check button row: Cancel, the Level-Learning help override (More/Less
  /// help), and the primary action (Check / Reveal, or Hide & type at level 3).
  Widget _preCheckButtons(
    BuildContext context,
    LearnAnywhereLocalizations messages,
  ) {
    final bool level3Pending =
        _isLevelLearning &&
        activeLevel == kMaxSupportLevel &&
        !level3Memorized;
    return Wrap(
      spacing: LearnAnywhereTokens.gapSmall,
      runSpacing: LearnAnywhereTokens.gapSmall,
      children: <Widget>[
        FilledButton.tonalIcon(
          onPressed: onCancel,
          icon: const Icon(Icons.close),
          label: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(messages.message(LearnAnywhereMessage.actionCancel)),
              const Text('Esc', style: TextStyle(fontSize: 10)),
            ],
          ),
        ),
        if (_isLevelLearning) ...<Widget>[
          OutlinedButton.icon(
            onPressed: activeLevel > kFreeRecallLevel
                ? () => onSetLevel(activeLevel - 1)
                : null,
            icon: const Icon(Icons.remove),
            label: Text(messages.message(LearnAnywhereMessage.learnLessHelp)),
          ),
          OutlinedButton.icon(
            onPressed: activeLevel < kMaxSupportLevel
                ? () => onSetLevel(activeLevel + 1)
                : null,
            icon: const Icon(Icons.add),
            label: Text(messages.message(LearnAnywhereMessage.learnMoreHelp)),
          ),
        ],
        FilledButton.icon(
          onPressed: onReveal,
          icon: Icon(
            level3Pending
                ? Icons.visibility_off
                : (parameters.withInput ? Icons.check : Icons.visibility),
          ),
          label: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                messages.message(
                  level3Pending
                      ? LearnAnywhereMessage.learnHideAndType
                      : (parameters.withInput
                            ? LearnAnywhereMessage.learnCheckAnswer
                            : LearnAnywhereMessage.learnReveal),
                ),
              ),
              const Text('F10', style: TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final LearningUnit unit = deck.units[item.unitIndex - 1];
    final CategoryDefinition category = deck.categoryForUnit(unit);

    // All non-hidden fields for the category, in definition order.
    final List<FieldDefinition> allFields = category.fields
        .where((FieldDefinition f) => !f.isHidden)
        .toList(growable: false);

    // Only render fields that are relevant in the current state.
    final List<FieldDefinition> visibleFields = allFields
        .where((FieldDefinition f) {
          final FieldRole r = f.roleFor(item.direction);
          // Remarks appear only after Check.
          if (r == FieldRole.remark && evaluation == null) return false;
          // Answer fields without typed-input mode are hidden before Check.
          if (r == FieldRole.answer &&
              evaluation == null &&
              !parameters.withInput) {
            return false;
          }
          return true;
        })
        .toList(growable: false);

    final bool timeWarning =
        options.showClock &&
        options.timeLimitSeconds > 0 &&
        elapsedSeconds >= options.timeLimitSeconds;

    // Header: "Unit x/y", the level name (for Level Learning, right after the
    // unit), then category and direction.
    final List<String> headerParts = <String>[
      _learnUnitHeader(messages, item.unitIndex, deck.units.length),
      if (_isLevelLearning) levelNameFor(levelNames, activeLevel),
      category.name,
      _directionLabel(deck, item.direction),
    ];
    final String headerText = headerParts.join(' - ');

    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ── Header: live (global) stats on top, then the unit line ─────
            Wrap(
              spacing: LearnAnywhereTokens.gapSmall,
              runSpacing: LearnAnywhereTokens.gapSmall,
              children: _statPills(messages, timeWarning),
            ),
            const SizedBox(height: LearnAnywhereTokens.gapSmall),
            Text(
              headerText,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: LearnAnywhereTokens.gapSmall),
            // ── Field grid ────────────────────────────────────────────────
            _fieldGrid(context, visibleFields, unit),
            // ── Post-reveal results ────────────────────────────────────────
            if (evaluation != null) ...<Widget>[
              const SizedBox(height: LearnAnywhereTokens.gapMedium),
              // Fix 3: emoji immediately after result text, inline
              Row(
                children: <Widget>[
                  Text(
                    evaluation!.correct
                        ? messages.message(
                            LearnAnywhereMessage.learnCorrectMessage,
                          )
                        : messages.message(
                            LearnAnywhereMessage.learnWrongMessage,
                          ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    evaluation!.correct ? '😊' : '😔',
                    style: const TextStyle(fontSize: 40),
                  ),
                ],
              ),
              const SizedBox(height: LearnAnywhereTokens.gapSmall),
              Row(
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: onContinue,
                    icon: const Icon(Icons.arrow_forward),
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          messages.message(LearnAnywhereMessage.learnContinue),
                        ),
                        const Text('F3', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                  const SizedBox(width: LearnAnywhereTokens.gapSmall),
                  FilledButton.tonalIcon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close),
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          messages.message(LearnAnywhereMessage.actionCancel),
                        ),
                        const Text('Esc', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                  if (parameters.withInput) ...<Widget>[
                    const SizedBox(width: LearnAnywhereTokens.gapSmall),
                    _ToggleViewButton(
                      label: showSolution
                          ? messages.message(
                              LearnAnywhereMessage.learnYourAnswer,
                            )
                          : messages.message(LearnAnywhereMessage.learnSolution),
                      onPressed: onToggleView,
                      onRestoreFocus: onRestoreFocus,
                    ),
                  ],
                  const Spacer(),
                  Text(
                    messages.message(LearnAnywhereMessage.learnEvaluateAs),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: LearnAnywhereTokens.gapSmall),
                  for (int i = 0; i < ratingEntries.length; i++) ...<Widget>[
                    if (i > 0)
                      const SizedBox(width: LearnAnywhereTokens.gapSmall),
                    _EvalButton(
                      label: ratingEntries[i].value,
                      hint: 'F${i + 5}',
                      filled: ratingEntries[i].key == selectedRating,
                      onPressed: () => onRatingChanged(ratingEntries[i].key),
                      onRestoreFocus: onRestoreFocus,
                    ),
                  ],
                ],
              ),
            ] else ...<Widget>[
              const SizedBox(height: LearnAnywhereTokens.gapLarge),
              // ── Pre-check buttons ──────────────────────────────────────
              _preCheckButtons(context, messages),
            ],
          ],
        ),
      ),
    );
  }

}

// ─── Practice grid row ────────────────────────────────────────────────────────

final class _PracticeGridRow extends StatelessWidget {
  const _PracticeGridRow({
    required this.field,
    required this.role,
    required this.value,
    required this.bgColor,
    required this.accentColor,
    required this.evaluation,
    required this.withInput,
    required this.enteredText,
    required this.controller,
    required this.focusNode,
    this.contentOverride,
  });

  final FieldDefinition field;
  final FieldRole role;
  final FieldValue value;
  final Color bgColor;
  final Color accentColor;
  final AnswerEvaluation? evaluation;
  final bool withInput;
  final String? enteredText;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// A Level-Learning answer widget (scaffold or preview) that replaces the
  /// default text field / rich-text value for this row when non-null.
  final Widget? contentOverride;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isEditable =
        role == FieldRole.answer && evaluation == null && withInput;

    final Widget content =
        contentOverride ??
        (isEditable
            ? _AnswerTextField(
                controller: controller,
                focusNode: focusNode,
                maxLength: field.length,
              )
            : LearnAnywhereRichText(
                value: value,
                maxLines: 3,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamilyFallback: LearnAnywhereTokens.monospaceFallback,
                ),
              ));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(width: 4, color: accentColor),
          Container(
            width: 120,
            color: bgColor,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              field.name,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(width: 1, color: colors.outlineVariant),
          Expanded(
            child: ColoredBox(
              color: bgColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                child: content,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The plain single-line answer text field used pre-check.
final class _AnswerTextField extends StatelessWidget {
  const _AnswerTextField({
    required this.controller,
    required this.focusNode,
    required this.maxLength,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: focusNode,
      controller: controller,
      maxLines: 1,
      inputFormatters: <TextInputFormatter>[
        LengthLimitingTextInputFormatter(maxLength),
      ],
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontFamilyFallback: LearnAnywhereTokens.monospaceFallback,
      ),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        border: InputBorder.none,
      ),
    );
  }
}

// ─── Level-Learning scaffold cells ────────────────────────────────────────────

/// Blue used for the "type here" dashed cell outline (matches the mockups).
const Color _kBlankCellColor = Color.fromRGBO(40, 110, 240, 1);
const double _kCellWidth = 22;
const double _kCellHeight = 30;

/// Colour for a locked/revealed letter. Kept muted (it's context, not input),
/// but nudged brighter in dark themes where `onSurfaceVariant` reads too dim.
Color _revealedTextColor(BuildContext context, ColorScheme colors) {
  if (Theme.of(context).brightness == Brightness.dark) {
    return Color.lerp(colors.onSurfaceVariant, colors.onSurface, 0.5)!;
  }
  return colors.onSurfaceVariant;
}

/// Splits [cells] into per-word runs (whitespace `shown` cells become gaps) and
/// lays the words out in a [Wrap] so word boundaries stay intact. Each cell is
/// turned into a widget by [cellBuilder], which receives a blank cell's running
/// 0-based blank index (−1 for non-blank cells).
Widget _scaffoldLayout(
  List<MaskCell> cells,
  Widget Function(MaskCell cell, int blankIndex) cellBuilder,
) {
  final List<Widget> words = <Widget>[];
  List<Widget> current = <Widget>[];
  void flush() {
    if (current.isNotEmpty) {
      words.add(
        Row(mainAxisSize: MainAxisSize.min, children: current),
      );
      current = <Widget>[];
    }
  }

  int blankIndex = 0;
  for (final MaskCell cell in cells) {
    final bool isWhitespace =
        cell.kind == MaskCellKind.shown && cell.char.trim().isEmpty;
    if (isWhitespace) {
      flush();
      words.add(const SizedBox(width: 12));
      continue;
    }
    current.add(
      cellBuilder(cell, cell.kind == MaskCellKind.blank ? blankIndex : -1),
    );
    if (cell.kind == MaskCellKind.blank) blankIndex += 1;
  }
  flush();
  return Wrap(
    spacing: 0,
    runSpacing: 4,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: words,
  );
}

/// A read-only Level-Learning scaffold: locked revealed letters and empty
/// dashed "type here" cells. Used for level-3 (full solution) and as context
/// for level 1; also for any level's revealed context.
final class _ScaffoldPreview extends StatelessWidget {
  const _ScaffoldPreview({required this.cells, required this.textStyle});

  final List<MaskCell> cells;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return _scaffoldLayout(cells, (MaskCell cell, int _) {
      switch (cell.kind) {
        case MaskCellKind.shown:
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Text(cell.char, style: textStyle),
          );
        case MaskCellKind.revealed:
          return _StaticCell(
            char: cell.char,
            revealed: true,
            textStyle: textStyle,
            colors: colors,
          );
        case MaskCellKind.blank:
          return _StaticCell(
            char: '',
            revealed: false,
            textStyle: textStyle,
            colors: colors,
          );
      }
    });
  }
}

/// A single fixed-size scaffold cell: greyed locked letter or dashed blank box.
final class _StaticCell extends StatelessWidget {
  const _StaticCell({
    required this.char,
    required this.revealed,
    required this.textStyle,
    required this.colors,
  });

  final String char;
  final bool revealed;
  final TextStyle textStyle;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final Widget inner = Container(
      width: _kCellWidth,
      height: _kCellHeight,
      alignment: Alignment.center,
      decoration: revealed
          ? BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: colors.outlineVariant),
            )
          : null,
      child: Text(
        char,
        style: textStyle.copyWith(
          color: revealed ? _revealedTextColor(context, colors) : null,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: revealed
          ? inner
          : CustomPaint(
              painter: const _DashedRectPainter(color: _kBlankCellColor),
              child: inner,
            ),
    );
  }
}

/// The editable level-2 scaffold: locked revealed letters interleaved with
/// per-blank single-character inputs the student fills. Reconstructs the full
/// answer string (revealed + typed + shown) and reports it via [onChanged].
final class _LevelScaffoldInput extends StatefulWidget {
  const _LevelScaffoldInput({
    required this.cells,
    required this.textStyle,
    required this.autofocus,
    required this.onChanged,
    required this.onSubmit,
    super.key,
  });

  final List<MaskCell> cells;
  final TextStyle textStyle;
  final bool autofocus;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;

  @override
  State<_LevelScaffoldInput> createState() => _LevelScaffoldInputState();
}

final class _LevelScaffoldInputState extends State<_LevelScaffoldInput> {
  final List<TextEditingController> _controllers = <TextEditingController>[];
  final List<FocusNode> _nodes = <FocusNode>[];

  int get _blankCount =>
      widget.cells.where((MaskCell c) => c.kind == MaskCellKind.blank).length;

  @override
  void initState() {
    super.initState();
    _build();
    if (widget.autofocus && _nodes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _nodes.first.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(_LevelScaffoldInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_blankCount != _controllers.length) {
      _dispose();
      _build();
    }
  }

  void _build() {
    for (int i = 0; i < _blankCount; i++) {
      _controllers.add(TextEditingController());
      final int index = i;
      _nodes.add(FocusNode(onKeyEvent: (_, KeyEvent e) => _onKey(index, e)));
    }
  }

  void _dispose() {
    for (final TextEditingController c in _controllers) {
      c.dispose();
    }
    for (final FocusNode n in _nodes) {
      n.dispose();
    }
    _controllers.clear();
    _nodes.clear();
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  /// Rebuilds the full answer string from revealed/shown characters and the
  /// typed blank cells, then reports it upward.
  void _report() {
    final StringBuffer buffer = StringBuffer();
    int blank = 0;
    for (final MaskCell cell in widget.cells) {
      if (cell.kind == MaskCellKind.blank) {
        buffer.write(_controllers[blank].text);
        blank += 1;
      } else {
        buffer.write(cell.char);
      }
    }
    widget.onChanged(buffer.toString());
  }

  KeyEventResult _onKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final LogicalKeyboardKey key = event.logicalKey;
    final bool isEnter =
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;
    final bool isTab = key == LogicalKeyboardKey.tab;
    if (isEnter || isTab) {
      if (index < _nodes.length - 1) {
        _nodes[index + 1].requestFocus();
      } else if (isEnter) {
        widget.onSubmit();
      } else {
        _nodes[index].nextFocus();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _nodes[index - 1].requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return _scaffoldLayout(widget.cells, (MaskCell cell, int blankIndex) {
      switch (cell.kind) {
        case MaskCellKind.shown:
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Text(cell.char, style: widget.textStyle),
          );
        case MaskCellKind.revealed:
          return _StaticCell(
            char: cell.char,
            revealed: true,
            textStyle: widget.textStyle,
            colors: colors,
          );
        case MaskCellKind.blank:
          return _BlankInputCell(
            controller: _controllers[blankIndex],
            focusNode: _nodes[blankIndex],
            textStyle: widget.textStyle,
            onChanged: (String value) {
              if (value.isNotEmpty && blankIndex < _nodes.length - 1) {
                _nodes[blankIndex + 1].requestFocus();
              }
              _report();
            },
          );
      }
    });
  }
}

/// A single editable blank cell (one character) with a dashed blue outline.
final class _BlankInputCell extends StatelessWidget {
  const _BlankInputCell({
    required this.controller,
    required this.focusNode,
    required this.textStyle,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final TextStyle textStyle;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: CustomPaint(
        painter: const _DashedRectPainter(color: _kBlankCellColor),
        child: SizedBox(
          width: _kCellWidth,
          height: _kCellHeight,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            textAlign: TextAlign.center,
            // Centre the glyph vertically so typed letters sit at the same
            // height as the locked (revealed) cells beside them.
            textAlignVertical: TextAlignVertical.center,
            maxLength: 1,
            style: textStyle,
            cursorWidth: 1,
            decoration: const InputDecoration(
              counterText: '',
              isCollapsed: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

/// Paints a dashed rounded rectangle just inside the given size.
final class _DashedRectPainter extends CustomPainter {
  const _DashedRectPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const double dash = 3;
    const double gap = 3;
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final RRect rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(4),
    );
    final Path path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter oldDelegate) =>
      oldDelegate.color != color;
}

final class _CompletionView extends StatelessWidget {
  const _CompletionView({required this.onExtend});

  final VoidCallback onExtend;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return Padding(
      padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            messages.message(LearnAnywhereMessage.superQueryCompleted),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: LearnAnywhereTokens.gapMedium),
          FilledButton.icon(
            onPressed: onExtend,
            icon: const Icon(Icons.tune),
            label: Text(
              messages.message(LearnAnywhereMessage.learnExtendSession),
            ),
          ),
        ],
      ),
    );
  }
}


final class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    this.warning = false,
  });

  final String label;
  final String value;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: warning ? colors.errorContainer : colors.surfaceContainerHighest,
        borderRadius: LearnAnywhereTokens.smallRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LearnAnywhereTokens.gapMedium,
          vertical: LearnAnywhereTokens.gapSmall,
        ),
        child: Text('$label: $value'),
      ),
    );
  }
}


final class _DropdownRow<T> extends StatelessWidget {
  const _DropdownRow({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LearnAnywhereTokens.gapMedium),
      child: SizedBox(
        width: 360,
        child: DropdownButtonFormField<T>(
          decoration: InputDecoration(labelText: label),
          initialValue: value,
          items: items,
          onChanged: (T? value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ),
    );
  }
}

final class _NumberRow extends StatefulWidget {
  const _NumberRow({
    required this.label,
    required this.value,
    required this.minimum,
    required this.onChanged,
    this.maximum,
  });

  final String label;
  final int value;
  final int minimum;
  final int? maximum;
  final ValueChanged<int> onChanged;

  @override
  State<_NumberRow> createState() => _NumberRowState();
}

final class _NumberRowState extends State<_NumberRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(_NumberRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String text = widget.value.toString();
    if (_controller.text != text) {
      _controller.text = text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LearnAnywhereTokens.gapMedium),
      child: SizedBox(
        width: 240,
        child: TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(labelText: widget.label),
          onChanged: (String value) {
            var parsed = int.tryParse(value) ?? widget.minimum;
            if (parsed < widget.minimum) {
              parsed = widget.minimum;
            }
            final int? maximum = widget.maximum;
            if (maximum != null && parsed > maximum) {
              parsed = maximum;
            }
            widget.onChanged(parsed);
          },
        ),
      ),
    );
  }
}

String _directionLabel(LearningDeck deck, QueryDirection direction) {
  return switch (direction) {
    QueryDirection.direction1 => deck.mask.direction1Label,
    QueryDirection.direction2 => deck.mask.direction2Label,
  };
}

String _learnUnitHeader(
  LearnAnywhereLocalizations messages,
  int index,
  int total,
) {
  return messages
      .message(LearnAnywhereMessage.learnUnitHeader)
      .replaceAll('{index}', index.toString())
      .replaceAll('{total}', total.toString());
}

int _totalItems(LearningDeck deck, SessionParameters parameters) {
  final int start = parameters.startIndex ?? 1;
  final int end = parameters.endIndex ?? deck.units.length;
  final int unitCount = max(
    0,
    min(end, deck.units.length) - max(1, start) + 1,
  ).toInt();
  return switch (parameters.directionSelection) {
    DirectionSelection.both => unitCount * 2,
    DirectionSelection.direction1 || DirectionSelection.direction2 => unitCount,
  };
}

String _clockText(int seconds) {
  final int minutes = seconds ~/ 60;
  final int rest = seconds % 60;
  return '$minutes:${rest.toString().padLeft(2, '0')}';
}

// ─── Evaluation button (Fix 1: skipTraversal focus node) ─────────────────────

final class _EvalButton extends StatefulWidget {
  const _EvalButton({
    required this.label,
    required this.hint,
    required this.filled,
    required this.onPressed,
    required this.onRestoreFocus,
  });

  final String label;
  final String hint;
  final bool filled;
  final VoidCallback onPressed;
  final VoidCallback onRestoreFocus;

  @override
  State<_EvalButton> createState() => _EvalButtonState();
}

final class _EvalButtonState extends State<_EvalButton> {
  final FocusNode _focusNode = FocusNode(
    skipTraversal: true,
    canRequestFocus: false,
  );

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(widget.label),
        Text(widget.hint, style: const TextStyle(fontSize: 10)),
      ],
    );
    if (widget.filled) {
      return FilledButton(
        focusNode: _focusNode,
        onPressed: () {
          widget.onPressed();
          widget.onRestoreFocus();
        },
        child: child,
      );
    }
    return OutlinedButton(
      focusNode: _focusNode,
      onPressed: () {
        widget.onPressed();
        widget.onRestoreFocus();
      },
      child: child,
    );
  }
}

// ─── Toggle view button (Fix 4: F9 toggle, skipTraversal focus node) ──────────

final class _ToggleViewButton extends StatefulWidget {
  const _ToggleViewButton({
    required this.label,
    required this.onPressed,
    required this.onRestoreFocus,
  });

  final String label;
  final VoidCallback onPressed;
  final VoidCallback onRestoreFocus;

  @override
  State<_ToggleViewButton> createState() => _ToggleViewButtonState();
}

final class _ToggleViewButtonState extends State<_ToggleViewButton> {
  final FocusNode _focusNode = FocusNode(
    skipTraversal: true,
    canRequestFocus: false,
  );

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      focusNode: _focusNode,
      onPressed: () {
        widget.onPressed();
        widget.onRestoreFocus();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(widget.label),
          const Text('F9', style: TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}

// ─── Intents ──────────────────────────────────────────────────────────────────

final class _LearnHelpIntent extends Intent {
  const _LearnHelpIntent();
}

final class _LearnContinueIntent extends Intent {
  const _LearnContinueIntent();
}

final class _LearnRevealIntent extends Intent {
  const _LearnRevealIntent();
}

final class _LearnSetupIntent extends Intent {
  const _LearnSetupIntent();
}

final class _LearnRate1Intent extends Intent {
  const _LearnRate1Intent();
}

final class _LearnRate2Intent extends Intent {
  const _LearnRate2Intent();
}

final class _LearnRate3Intent extends Intent {
  const _LearnRate3Intent();
}

final class _LearnToggleViewIntent extends Intent {
  const _LearnToggleViewIntent();
}
