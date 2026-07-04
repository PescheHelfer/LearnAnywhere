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
    this.onStartUnitChanged,
    this.onEndUnitChanged,
    this.onExit,
    super.key,
  });

  /// Current deck.
  final LearningDeck deck;

  /// Current statistics.
  final List<UnitStats> statistics;

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

  final Random _random = Random(1);
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
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _draftParameters = _optionsApplied(widget.parameters);
    _startIndex = _draftParameters.startIndex ?? 1;
    _endIndex = _draftParameters.endIndex ?? widget.deck.units.length;
    _thresholdPercent = (_draftParameters.superStatusThreshold * 100).round();
    if (widget.options.showClock) {
      _startClock();
    }
  }

  @override
  void didUpdateWidget(LearnSessionPage oldWidget) {
    super.didUpdateWidget(oldWidget);
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
                _reveal();
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
        onDirectionChanged: (DirectionSelection value) {
          _applyDraft(_parametersWith(direction: value));
        },
        onModeChanged: (SessionMode value) {
          _applyDraft(_parametersWith(mode: value));
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
      options: widget.options,
      parameters: _draftParameters,
      item: _currentItem!,
      evaluation: _evaluation,
      selectedRating: _selectedRating,
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
      onReveal: _reveal,
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
  }

  /// Stores the edited draft and pushes it to the shell so it is persisted.
  void _applyDraft(SessionParameters next) {
    setState(() => _draftParameters = next);
    widget.onParametersChanged(next);
  }

  void _selectNextItem() {
    final SessionItem? next = switch (_draftParameters.mode) {
      SessionMode.superQuery => _firstSuperQueryItem(),
      SessionMode.practice || SessionMode.onceThrough => _nextOrderedItem(),
    };
    if (next == null) {
      setState(() {
        _currentItem = null;
        _completed = true;
        _evaluation = null;
      });
      return;
    }
    _resetAnswerControllers(next);
    setState(() {
      _currentItem = next;
      _evaluation = null;
      _selectedRating = AttemptRating.noCount;
      _elapsedSeconds = 0;
    });
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
    if (_answerFocusNodes.isNotEmpty) {
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
        _reveal();
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
  }

  void _continueShortcut() {
    if (_currentItem == null) {
      _startSession();
    } else if (_evaluation == null) {
      _reveal();
    } else {
      _continueAfterRating();
    }
  }

  void _continueAfterRating() {
    final SessionItem? item = _currentItem;
    if (item == null || _evaluation == null) {
      return;
    }
    final List<UnitStats> updated = _recordRating(item, _selectedRating);
    widget.onStatisticsChanged(updated);
    final bool counted = _selectedRating != AttemptRating.noCount;
    final bool correct = _selectedRating == AttemptRating.correct;
    widget.onSessionProgressChanged(
      widget.sessionAttempts + (counted ? 1 : 0),
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
    return SessionParameters(
      directionSelection: direction ?? _draftParameters.directionSelection,
      startIndex: startIndex ?? _draftParameters.startIndex,
      endIndex: endIndex ?? _draftParameters.endIndex,
      withInput: withInput ?? _draftParameters.withInput,
      mode: mode ?? _draftParameters.mode,
      shuffle: shuffle ?? _draftParameters.shuffle,
      superStatusThreshold: threshold ?? _draftParameters.superStatusThreshold,
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
    required this.onDirectionChanged,
    required this.onModeChanged,
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
  final ValueChanged<DirectionSelection> onDirectionChanged;
  final ValueChanged<SessionMode> onModeChanged;
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
          label: messages.message(LearnAnywhereMessage.learnSuperThreshold),
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
    required this.options,
    required this.parameters,
    required this.item,
    required this.evaluation,
    required this.selectedRating,
    required this.ratingEntries,
    required this.answerControllers,
    required this.answerFocusNodes,
    required this.enteredAnswers,
    required this.elapsedSeconds,
    required this.sessionAttempts,
    required this.sessionCorrect,
    required this.showSolution,
    required this.onReveal,
    required this.onRatingChanged,
    required this.onToggleView,
    required this.onRestoreFocus,
    required this.onContinue,
    required this.onCancel,
  });

  final LearningDeck deck;
  final List<UnitStats> statistics;
  final DesktopQueryOptions options;
  final SessionParameters parameters;
  final SessionItem item;
  final AnswerEvaluation? evaluation;
  final AttemptRating selectedRating;
  final List<MapEntry<AttemptRating, String>> ratingEntries;
  final Map<int, TextEditingController> answerControllers;
  final Map<int, FocusNode> answerFocusNodes;
  final Map<int, String> enteredAnswers;
  final int elapsedSeconds;
  final int sessionAttempts;
  final int sessionCorrect;
  final bool showSolution;
  final VoidCallback onReveal;
  final ValueChanged<AttemptRating> onRatingChanged;
  final VoidCallback onToggleView;
  final VoidCallback onRestoreFocus;
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final ColorScheme colors = Theme.of(context).colorScheme;
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

    // Compute stat values for the header row.
    final List<SessionItem> pool = activeSuperQueryPool(
      deck: deck,
      statistics: statistics,
      parameters: parameters,
    );
    final int totalItems = _totalItems(deck, parameters);
    final int mastered = (totalItems - pool.length).clamp(0, totalItems);
    final int accuracy = sessionAttempts == 0
        ? 0
        : ((sessionCorrect / sessionAttempts) * 100).round();
    final bool timeWarning =
        options.showClock &&
        options.timeLimitSeconds > 0 &&
        elapsedSeconds >= options.timeLimitSeconds;

    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ── Header: stats + inline title ───────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _StatPill(
                  label: messages.message(
                    LearnAnywhereMessage.learnLiveMastered,
                  ),
                  value: '$mastered/$totalItems',
                ),
                const SizedBox(width: LearnAnywhereTokens.gapSmall),
                _StatPill(
                  label: messages.message(
                    LearnAnywhereMessage.learnLiveRemaining,
                  ),
                  value: pool.length.toString(),
                ),
                const SizedBox(width: LearnAnywhereTokens.gapSmall),
                _StatPill(
                  label: messages.message(
                    LearnAnywhereMessage.learnLiveAccuracy,
                  ),
                  value: '$accuracy%',
                ),
                if (options.showClock) ...<Widget>[
                  const SizedBox(width: LearnAnywhereTokens.gapSmall),
                  _StatPill(
                    label: 'Time',
                    value: _clockText(elapsedSeconds),
                    warning: timeWarning,
                  ),
                ],
                const SizedBox(width: LearnAnywhereTokens.gapSmall),
                Expanded(
                  child: Text(
                    _learnUnitHeader(
                      messages,
                      item.unitIndex,
                      deck.units.length,
                      category.name,
                      _directionLabel(deck, item.direction),
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: LearnAnywhereTokens.gapSmall),
            // ── Field grid ────────────────────────────────────────────────
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: colors.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < visibleFields.length; i++) ...<Widget>[
                      if (i > 0)
                        Container(height: 1, color: colors.outlineVariant),
                      Builder(
                        builder: (BuildContext ctx) {
                          final FieldDefinition field = visibleFields[i];
                          final FieldRole role = field.roleFor(item.direction);
                          final double bgOpacity =
                              Theme.of(ctx).brightness == Brightness.light
                                  ? 0.15
                                  : 0.10;

                          final bool showUserAnswer =
                              role == FieldRole.answer &&
                              evaluation != null &&
                              parameters.withInput &&
                              !showSolution;

                          final Color accentColor;
                          final Color bgColor;
                          final FieldValue displayValue;

                          if (showUserAnswer) {
                            final ColorScheme rowColors =
                                Theme.of(ctx).colorScheme;
                            accentColor = rowColors.outline;
                            bgColor = rowColors.surfaceContainerHighest;
                            displayValue = FieldValue.plain(
                              enteredAnswers[field.id] ?? '',
                            );
                          } else {
                            accentColor = switch (role) {
                              FieldRole.question =>
                                const Color.fromRGBO(0, 150, 180, 1),
                              FieldRole.answer =>
                                const Color.fromRGBO(0, 160, 80, 1),
                              FieldRole.remark =>
                                const Color.fromRGBO(200, 140, 0, 1),
                            };
                            bgColor = accentColor.withValues(alpha: bgOpacity);
                            displayValue = unit.valueForFieldId(field.id);
                          }

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
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
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
              Wrap(
                spacing: LearnAnywhereTokens.gapSmall,
                children: <Widget>[
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
                  FilledButton.icon(
                    onPressed: onReveal,
                    icon: Icon(
                      parameters.withInput ? Icons.check : Icons.visibility,
                    ),
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          messages.message(
                            parameters.withInput
                                ? LearnAnywhereMessage.learnCheckAnswer
                                : LearnAnywhereMessage.learnReveal,
                          ),
                        ),
                        const Text('F10', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
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

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isEditable =
        role == FieldRole.answer && evaluation == null && withInput;

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
                child: isEditable
                    ? TextField(
                        focusNode: focusNode,
                        controller: controller,
                        maxLines: 1,
                        inputFormatters: <TextInputFormatter>[
                          LengthLimitingTextInputFormatter(field.length),
                        ],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamilyFallback:
                              LearnAnywhereTokens.monospaceFallback,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 0,
                          ),
                          border: InputBorder.none,
                        ),
                      )
                    : LearnAnywhereRichText(
                        value: value,
                        maxLines: 3,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamilyFallback:
                              LearnAnywhereTokens.monospaceFallback,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
  String category,
  String direction,
) {
  return messages
      .message(LearnAnywhereMessage.learnUnitHeader)
      .replaceAll('{index}', index.toString())
      .replaceAll('{total}', total.toString())
      .replaceAll('{category}', category)
      .replaceAll('{direction}', direction);
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
