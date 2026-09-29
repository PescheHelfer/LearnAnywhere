import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

import '../widgets/difficult_badge.dart';
import 'desktop_query_options.dart';

/// Desktop learning session page.
final class LearnSessionPage extends StatefulWidget {
  /// Creates a desktop learning session page.
  const LearnSessionPage({
    required this.deck,
    required this.statistics,
    required this.options,
    required this.parameters,
    required this.onParametersChanged,
    required this.onStatisticsChanged,
    required this.onOpenEditor,
    this.onSessionStarted,
    this.onPersistStatistics,
    this.onAttemptRecorded,
    this.levelStatistics = const <LevelUnitStats>[],
    this.levelNames = kDefaultLevelNamesEn,
    this.entryLevelCap = kMaxSupportLevel,
    this.resetToSetupSignal = 0,
    this.startSessionOnOpen = false,
    this.onSessionActiveChanged,
    this.onLevelStatisticsChanged,
    this.onEntryLevelCapChanged,
    this.onStartUnitChanged,
    this.onEndUnitChanged,
    this.onExit,
    this.onToggleDifficult,
    this.speechEngine = const UnavailableTtsEngine(),
    this.speechSettings = const SpeechSettings(),
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

  /// Increments when Learn ▸ Practice setup is chosen; a change always returns
  /// the page to its practice setup, whatever it was showing.
  final int resetToSetupSignal;

  /// Set for the frame in which Learn ▸ "Learn with last settings" is chosen;
  /// the page then starts a session immediately with the settings on hand,
  /// whether it was already open or is being created by that command.
  final bool startSessionOnOpen;

  /// Called when a session starts or ends, so the shell can offer "Continue"
  /// instead of "Learn with last settings" while one is running.
  final ValueChanged<bool>? onSessionActiveChanged;

  /// Called when Level-Learning statistics change (attempt or manual override).
  final ValueChanged<List<LevelUnitStats>>? onLevelStatisticsChanged;

  /// Called when the user changes the Level-Learning entry-level cap in setup.
  final ValueChanged<int>? onEntryLevelCapChanged;

  /// Current query options.
  final DesktopQueryOptions options;

  /// Session parameters retained by the shell.
  final SessionParameters parameters;

  /// Called when setup parameters change.
  final ValueChanged<SessionParameters> onParametersChanged;

  /// Called when statistics are updated by a rating.
  final ValueChanged<List<UnitStats>> onStatisticsChanged;

  /// Called when a session is about to start, so the shell can create a
  /// timestamped auto-save target when none is loaded yet (§3.7) and warn when
  /// the statistics on hand were recorded in a different mode.
  ///
  /// Returning `false` aborts the start and leaves the setup screen up.
  final Future<bool> Function(SessionMode mode)? onSessionStarted;

  /// Called after each check→continue cycle, so the shell can auto-save the
  /// updated statistics to the active target (§3.7).
  final VoidCallback? onPersistStatistics;

  /// Called with each attempt exactly as the working record took it, so the
  /// shell can add the same amount to the deck's lifetime record.
  ///
  /// Fires for every rating, including one the wrong-answer ceiling suppressed
  /// and a "no count" — both arrive carrying an empty delta, which the lifetime
  /// record ignores. Fires BEFORE [onPersistStatistics], so the shell's
  /// document already holds the attempt when the writes are queued.
  final ValueChanged<RecordedAttempt>? onAttemptRecorded;

  /// Called when the user wants to interrupt and edit the deck.
  final VoidCallback onOpenEditor;

  /// Called when the user changes the start unit on the setup screen.
  final ValueChanged<int>? onStartUnitChanged;

  /// Called when the user manually changes the end unit on the setup screen.
  final ValueChanged<int>? onEndUnitChanged;

  /// Called when the user exits the learn session back to the home screen.
  final VoidCallback? onExit;

  /// Called with the question on screen — its unit and the direction being
  /// asked — when the learner toggles its difficulty (F12 or the Difficult
  /// pill), which acts on that direction only.
  ///
  /// The page only asks: the shell applies the rule, writes the deck and
  /// hands the changed deck back through [deck], which is what the pill and
  /// the badge read. Without it the session offers neither the key nor the
  /// pill.
  final ValueChanged<SessionItem>? onToggleDifficult;

  /// The host's speech, injected by the shell.
  ///
  /// Defaults to the engine that cannot speak, so a caller that says nothing
  /// about speech gets a session with no speaker icons rather than a session
  /// reaching for a plugin its host may not have.
  final TtsEngine speechEngine;

  /// The machine's chosen voices and speech rate.
  ///
  /// Passed to the policy rather than consulted here, so an icon in a session
  /// uses exactly the voice the Speech screen auditioned.
  final SpeechSettings speechSettings;

  @override
  State<LearnSessionPage> createState() => _LearnSessionPageState();
}

/// Which post-check panel the F9/toggle button currently shows.
enum _AnswerViewMode {
  /// Diff-highlighted corrections overlaid on the expected solution.
  correction,

  /// The plain solution, without any correction marks.
  solution,

  /// The user's raw typed answer.
  yourAnswer,
}

/// The mode the toggle button switches to next (and therefore the label it
/// shows). Cycles correction -> solution -> yourAnswer -> correction, except
/// that a fully correct answer has nothing to correct, so [skipCorrection]
/// makes yourAnswer wrap back to solution instead.
_AnswerViewMode _nextAnswerViewMode(
  _AnswerViewMode current, {
  required bool skipCorrection,
}) {
  switch (current) {
    case _AnswerViewMode.correction:
      return _AnswerViewMode.solution;
    case _AnswerViewMode.solution:
      return _AnswerViewMode.yourAnswer;
    case _AnswerViewMode.yourAnswer:
      return skipCorrection
          ? _AnswerViewMode.solution
          : _AnswerViewMode.correction;
  }
}

/// Each live-statistics pill's label paired with the widest reading it can
/// show — a four-figure deck, counted, scored and timed.
///
/// Sampled rather than measured, because the real figures do not exist when
/// the content frame is computed — and because a frame that changed width as
/// the counters ticked would move the mask under the learner mid-sitting.
///
/// Only the widest single entry matters: the pills sit in a [Wrap] and are
/// free to run onto a second line.
const List<(LearnAnywhereMessage, String)> _widestStatPills =
    <(LearnAnywhereMessage, String)>[
      (LearnAnywhereMessage.learnLiveAttempts, '99999'),
      (LearnAnywhereMessage.learnLiveMastered, '9999/9999'),
      (LearnAnywhereMessage.learnLiveRemaining, '9999 (9999)'),
      (LearnAnywhereMessage.learnLiveAccuracy, '9999/9999 (100%)'),
      (LearnAnywhereMessage.learnLiveTime, '999:99'),
    ];

/// The widest thing on the session screen that cannot be broken across lines.
///
/// One of the two halves of the floor [deckContentFrameWidth] may never put
/// the content frame below; the editor's widest button is the other.
///
/// The frame is sized from the deck, and a control row wider than the deck is
/// expected to **wrap** — it is laid out in a [Wrap] for exactly that. What it
/// must never do is get *squeezed*: the two pill groups are each a
/// [FittedBox], so a frame narrower than one of them shrinks its text instead
/// of moving it. This is therefore the widest single unbreakable cluster, not
/// the sum of a row: the question-stage group, the action group, the
/// evaluation group, one statistic pill, or the Difficult pill, whichever is
/// widest.
///
/// Measured, not estimated: every label is measured in the very style it is
/// painted in, so the figure follows the language, the zoom level and the
/// host's font by itself, and only each control's fixed chrome is a constant.
double learnControlGroupWidth(
  BuildContext context,
  LearnAnywhereLocalizations messages,
) {
  final TextTheme text = Theme.of(context).textTheme;
  final TextStyle pillLabelStyle = text.labelLarge ?? const TextStyle();
  final TextStyle keyHintStyle = LearnAnywhereTokens.keyHint(context);
  final TextStyle bodyStyle = text.bodyMedium ?? const TextStyle();
  final TextStyle captionStyle = text.bodySmall ?? const TextStyle();

  String say(LearnAnywhereMessage key) => messages.message(key);

  double labelColumn(String label, String keyName) =>
      measurePillLabelWidth(context, label, keyName);

  double widest(Iterable<LearnAnywhereMessage> keys) => keys
      .map((LearnAnywhereMessage key) =>
          measureTextWidth(say(key), pillLabelStyle))
      .reduce(max);

  // ── The action group: it may wrap away from the evaluation group, but its
  // own pills are one atom — at their widest, Read aloud included.
  final double actionGroup =
      iconPillChrome +
      labelColumn(say(LearnAnywhereMessage.learnContinue), 'F3') +
      LearnAnywhereTokens.gapSmall +
      iconPillChrome +
      labelColumn(say(LearnAnywhereMessage.learnReadAloud), 'F4') +
      LearnAnywhereTokens.gapSmall +
      iconPillChrome +
      labelColumn(say(LearnAnywhereMessage.actionCancel), 'Esc') +
      LearnAnywhereTokens.gapSmall +
      plainPillChrome +
      max(
        widest(const <LearnAnywhereMessage>[
          LearnAnywhereMessage.learnCorrection,
          LearnAnywhereMessage.learnSolution,
          LearnAnywhereMessage.learnYourAnswer,
        ]),
        measureTextWidth(
          '${say(LearnAnywhereMessage.learnSwitchHint)}: F9',
          keyHintStyle,
        ),
      );

  // ── The question-stage group, at its widest: Level Learning's Less/More
  // help, Read aloud, the widest of the three F10 labels, and Cancel.
  final double questionGroup =
      iconPillChrome +
      measureTextWidth(say(LearnAnywhereMessage.learnLessHelp), pillLabelStyle) +
      LearnAnywhereTokens.gapSmall +
      iconPillChrome +
      measureTextWidth(say(LearnAnywhereMessage.learnMoreHelp), pillLabelStyle) +
      LearnAnywhereTokens.gapSmall +
      iconPillChrome +
      labelColumn(say(LearnAnywhereMessage.learnReadAloud), 'F4') +
      LearnAnywhereTokens.gapSmall +
      iconPillChrome +
      max(
        widest(const <LearnAnywhereMessage>[
          LearnAnywhereMessage.learnCheckAnswer,
          LearnAnywhereMessage.learnReveal,
          LearnAnywhereMessage.learnHideAndType,
        ]),
        measureTextWidth('F10', keyHintStyle),
      ) +
      LearnAnywhereTokens.gapSmall +
      iconPillChrome +
      labelColumn(say(LearnAnywhereMessage.actionCancel), 'Esc');

  // Always three rating pills, whichever outcome produced them; the widest
  // label any outcome can offer sizes all three.
  final double ratingPill =
      plainPillChrome +
      max(
        widest(const <LearnAnywhereMessage>[
          LearnAnywhereMessage.learnRatingCorrect,
          LearnAnywhereMessage.learnRatingWrong,
          LearnAnywhereMessage.learnRatingActuallyCorrect,
          LearnAnywhereMessage.learnRatingCloseEnough,
          LearnAnywhereMessage.learnRatingActuallyWrong,
          LearnAnywhereMessage.learnRatingNoCount,
          LearnAnywhereMessage.learnRatingKnewIt,
          LearnAnywhereMessage.learnRatingDidNotKnow,
        ]),
        measureTextWidth('F5', keyHintStyle),
      );
  // The caption sits above the three pills, so the group is as wide as the
  // wider of the two.
  final double evaluationGroup = max(
    measureTextWidth(say(LearnAnywhereMessage.learnEvaluateAs), captionStyle),
    3 * ratingPill + 2 * LearnAnywhereTokens.gapSmall,
  );

  // ── The widest single live-statistics pill ───────────────────────────────
  double statisticPill = 0;
  for (final (LearnAnywhereMessage label, String value) in _widestStatPills) {
    statisticPill = max(
      statisticPill,
      measureTextWidth('${say(label)}: $value', bodyStyle) +
          2 * LearnAnywhereTokens.gapMedium,
    );
  }

  // ── The Difficult pill, a group of its own in both stages ────────────────
  final double difficultPill =
      iconPillChrome +
      labelColumn(say(LearnAnywhereMessage.learnDifficult), 'F12');

  return <double>[
    questionGroup,
    actionGroup,
    evaluationGroup,
    statisticPill,
    difficultPill,
  ].reduce(max);
}

/// The message naming [mode], used for the toggle button label (which names
/// the mode currently displayed).
LearnAnywhereMessage _answerViewModeMessage(_AnswerViewMode mode) {
  return switch (mode) {
    _AnswerViewMode.correction => LearnAnywhereMessage.learnCorrection,
    _AnswerViewMode.solution => LearnAnywhereMessage.learnSolution,
    _AnswerViewMode.yourAnswer => LearnAnywhereMessage.learnYourAnswer,
  };
}

final class _LearnSessionPageState extends State<LearnSessionPage> {
  static const Map<ShortcutActivator, Intent> _kShortcuts =
      <ShortcutActivator, Intent>{
        // F1 is deliberately absent: it belongs to the app-wide user guide
        // (see `_handleHelpKey` in main.dart), which opens over this page
        // without interrupting the running session.
        SingleActivator(LogicalKeyboardKey.f3): _LearnContinueIntent(),
        SingleActivator(LogicalKeyboardKey.enter): _LearnContinueIntent(),
        // F4 replays what automatic speech plays. Free everywhere else in the
        // session and in the menu bar, so the program stays fully operable
        // from the keyboard without taking a key that already does something.
        SingleActivator(LogicalKeyboardKey.f4): _LearnSpeakAnswerIntent(),
        SingleActivator(LogicalKeyboardKey.f5): _LearnRate1Intent(),
        SingleActivator(LogicalKeyboardKey.f6): _LearnRate2Intent(),
        SingleActivator(LogicalKeyboardKey.f7): _LearnRate3Intent(),
        SingleActivator(LogicalKeyboardKey.f9): _LearnToggleViewIntent(),
        SingleActivator(LogicalKeyboardKey.f10): _LearnRevealIntent(),
        // F12 toggles the unit's difficulty in both stages. Free in the
        // session and in the menu bar, and never a rating or a reveal.
        SingleActivator(LogicalKeyboardKey.f12): _LearnToggleDifficultIntent(),
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

  // Which post-check toggle panel is shown. Always reset when a unit is
  // evaluated (see _reveal): starts at correction unless the answer was
  // fully correct, in which case there is nothing to correct and it starts
  // at solution instead.
  _AnswerViewMode _viewMode = _AnswerViewMode.correction;

  late SessionParameters _draftParameters;
  late int _startIndex;
  late int _endIndex;
  late int _thresholdPercent;

  // Pins the unit range to the whole deck and disables both range fields.
  // Opt-in only: a range that happens to span the deck does not switch this on
  // by itself, so opening the setup screen never starts with dead fields.
  bool _useAllUnits = false;

  List<SessionItem> _order = const <SessionItem>[];
  int _orderPosition = 0;
  Map<int, String> _lastEntered = <int, String>{};

  // The voices the host reported, read once in initState. Empty on a host that
  // cannot speak, and equally on one that speaks but has nothing installed —
  // the difference is the engine's own isAvailable, not this list.
  List<SpeechVoice> _voices = const <SpeechVoice>[];

  // Bumped by every new speech request. A sequence reading several answer
  // fields checks it between two of them and abandons itself when it no longer
  // holds the newest number, so a reveal, an icon or a second F4 replaces what
  // is being said instead of being queued behind it.
  int _speechGeneration = 0;

  SessionItem? _currentItem;
  AnswerEvaluation? _evaluation;
  // Display classification of the revealed answer (correct/almost/wrong). Drives
  // the result message and which rating labels are offered; never recorded.
  AnswerOutcome _outcome = AnswerOutcome.correct;
  AttemptRating _selectedRating = AttemptRating.noCount;
  Timer? _clockTimer;
  int _elapsedSeconds = 0;
  // Whether the time-limit warning tone has already sounded for the current
  // unit; reset when a new unit is shown so the tone fires once per unit.
  bool _timeTonePlayed = false;
  bool _completed = false;
  // Whether the completed session ran out of difficult units rather than
  // mastering them; decided as it ends, so the view says the right thing.
  bool _endedWithNoneLeft = false;

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

  // Last session-active state pushed to the shell; see [_notifySessionActive].
  bool _sessionActiveNotified = false;

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
    unawaited(_loadVoices());
    // Created by Learn ▸ "Learn with last settings": skip the setup screen.
    if (widget.startSessionOnOpen) {
      _startSessionOnOpen();
    }
  }

  /// Asks the host once which voices it has, so the speech policy can resolve
  /// a field's language against them without the UI waiting on the engine.
  Future<void> _loadVoices() async {
    if (!widget.speechEngine.isAvailable) {
      return;
    }
    final List<SpeechVoice> voices = await widget.speechEngine.voices();
    if (!mounted) {
      return;
    }
    setState(() => _voices = voices);
  }

  /// Says [utterance], or explains why it cannot be said.
  ///
  /// The unresolved case is a message and not a missing icon: the learner is
  /// told which language their machine has no voice for, which is the one
  /// thing that gets them from silence to sound.
  Future<void> _speak(SpeechUtterance utterance) async {
    if (!utterance.canBeSpoken) {
      _explainMissingVoice(utterance);
      return;
    }
    _speechGeneration += 1;
    await widget.speechEngine.speak(utterance);
  }

  /// Tells the learner which language their machine has no voice for.
  void _explainMissingVoice(SpeechUtterance utterance) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          messages
              .message(LearnAnywhereMessage.learnSpeakNoVoice)
              .replaceAll('{language}', utterance.language),
        ),
      ),
    );
  }

  /// What may be spoken for the unit as it now stands on screen.
  ///
  /// Built from the same call the view renders icons from, so an icon, `F4`
  /// and automatic speech can never disagree about what this unit offers. A
  /// host that cannot speak gets the silent plan.
  SpeechPlan _speechPlan() {
    final SessionItem? item = _currentItem;
    if (item == null || !widget.speechEngine.isAvailable) {
      return SpeechPlan.silent;
    }
    return buildSpeechPlan(
      deck: widget.deck,
      unit: widget.deck.units[item.unitIndex - 1],
      direction: item.direction,
      afterCheck: _evaluation != null,
      answerShown: _answerShownAsSupport,
      voices: _voices,
      settings: widget.speechSettings,
    );
  }

  /// Reads the answer aloud: every Speak-enabled field holding the answer
  /// role in this direction, in mask field order.
  ///
  /// The one set automatic speech plays at the reveal and `F4` plays on
  /// demand. It always stops first, so moving to a new unit cuts the previous
  /// word off instead of queueing behind it, and it abandons itself the
  /// moment a newer request arrives — hammering Enter must not stack eight
  /// words on top of each other.
  ///
  /// [explain] tells a learner who pressed `F4` which language has no voice.
  /// Automatic speech passes false: a feature that speaks by itself must not
  /// also complain by itself, once per unit, for the rest of the session.
  Future<void> _speakAnswer({required bool explain}) async {
    final List<SpeechUtterance> utterances = _speechPlan().answerUtterances
        .toList(growable: false);
    final int generation = ++_speechGeneration;
    // Stopped even when this unit says nothing: silence here means silence,
    // not the previous unit still talking.
    await widget.speechEngine.stop();
    bool explained = false;
    for (final SpeechUtterance utterance in utterances) {
      if (!mounted || generation != _speechGeneration) {
        return;
      }
      if (!utterance.canBeSpoken) {
        if (explain && !explained) {
          explained = true;
          _explainMissingVoice(utterance);
        }
        continue;
      }
      await widget.speechEngine.speak(utterance);
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
    // Learn ▸ Practice setup always lands on the setup screen, from the
    // completion view as well as from a running session.
    if (widget.resetToSetupSignal != oldWidget.resetToSetupSignal) {
      _completed = false;
      _currentItem = null;
      _notifySessionActive(false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _rootFocusNode.requestFocus();
      });
    }
    // Learn ▸ "Learn with last settings" starts right away; a session already
    // running is simply resumed (the shell labels that entry "Continue").
    if (widget.startSessionOnOpen && !oldWidget.startSessionOnOpen) {
      _startSessionOnOpen();
    }
  }

  /// Starts a session from the settings on hand, unless one is already running.
  ///
  /// Deferred a frame: the request arrives from the shell mid-build (page
  /// creation or rebuild), and [_startSession] both awaits the shell's
  /// start-of-session hook and calls `setState`.
  void _startSessionOnOpen() {
    if (_currentItem != null) {
      return;
    }
    _completed = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _currentItem == null) {
        unawaited(_startSession());
      }
    });
  }

  /// Reports session start/end to the shell, once per transition.
  ///
  /// Always deferred to the next frame: the transitions happen inside this
  /// page's `setState`/`didUpdateWidget`, where calling back into the shell
  /// would rebuild an ancestor mid-build.
  void _notifySessionActive(bool active) {
    if (_sessionActiveNotified == active) {
      return;
    }
    _sessionActiveNotified = active;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onSessionActiveChanged?.call(active);
    });
  }

  @override
  void dispose() {
    // Leaving the page by any route ends a running session, so the shell
    // hears of it even when it switched screens without asking this page.
    if (_sessionActiveNotified) {
      final ValueChanged<bool>? onChanged = widget.onSessionActiveChanged;
      WidgetsBinding.instance.addPostFrameCallback((_) => onChanged?.call(false));
    }
    _clockTimer?.cancel();
    // Leaving the session cuts off a word still being spoken: a voice talking
    // over the screen the learner has just moved to is nobody's idea of help.
    unawaited(widget.speechEngine.stop());
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
            _LearnSpeakAnswerIntent: CallbackAction<_LearnSpeakAnswerIntent>(
              onInvoke: (_) {
                // The same set automatic speech plays, whether it is on or
                // off. Asked for by hand, so a language with no voice says so
                // rather than leaving the learner wondering.
                unawaited(_speakAnswer(explain: true));
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
                  setState(
                    () => _viewMode = _nextAnswerViewMode(
                      _viewMode,
                      skipCorrection: _evaluation?.correct ?? false,
                    ),
                  );
                  _rootFocusNode.requestFocus();
                }
                return null;
              },
            ),
            _LearnToggleDifficultIntent:
                CallbackAction<_LearnToggleDifficultIntent>(
                  onInvoke: (_) {
                    _toggleDifficult();
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
      return _CompletionView(
        onExtend: _backToSetup,
        noneLeft: _endedWithNoneLeft,
      );
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
        useAllUnits: _useAllUnits,
        onUseAllUnitsChanged: (bool value) {
          setState(() {
            _useAllUnits = value;
            if (!value) {
              return;
            }
            // Pinning the range spans the whole deck; unpinning leaves the
            // last values in place so the previous range is still there.
            _startIndex = 1;
            _endIndex = widget.deck.units.length;
          });
          if (value) {
            widget.onStartUnitChanged?.call(_startIndex);
            widget.onEndUnitChanged?.call(_endIndex);
          }
        },
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
        nothingDifficultToAsk: _nothingDifficultToAsk,
        difficultCount: countDifficultUnits(widget.deck, _scopedDraft()),
        onDifficultOnlyChanged: (bool value) {
          _applyDraft(_parametersWith(difficultOnly: value));
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
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final bool answerShownAsSupport = _answerShownAsSupport;
    // What may be spoken for the unit as it now stands. A host that cannot
    // speak gets the silent plan, so no icon is rendered at all — a disabled
    // one would only offer what the machine cannot do.
    final SpeechPlan speechPlan = _speechPlan();
    return _SessionView(
      deck: widget.deck,
      statistics: widget.statistics,
      speechPlan: speechPlan,
      onSpeak: _speak,
      // Offered exactly when F4 would play something: an answer with no
      // installed voice still counts, and pressing it explains as F4 does.
      onReadAloud: speechPlan.answerUtterances.isEmpty
          ? null
          : () => unawaited(_speakAnswer(explain: true)),
      answerShownAsSupport: answerShownAsSupport,
      levelStatistics: _levelStats,
      levelNames: widget.levelNames,
      entryLevelCap: widget.entryLevelCap,
      options: widget.options,
      parameters: _draftParameters,
      item: _currentItem!,
      evaluation: _evaluation,
      outcome: _outcome,
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
      viewMode: _viewMode,
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
        setState(
          () => _viewMode = _nextAnswerViewMode(
            _viewMode,
            skipCorrection: _evaluation?.correct ?? false,
          ),
        );
        _rootFocusNode.requestFocus();
      },
      onRestoreFocus: _rootFocusNode.requestFocus,
      onContinue: _continueAfterRating,
      onCancel: _cancelSession,
      onToggleDifficult: widget.onToggleDifficult == null
          ? null
          : _toggleDifficult,
    );
  }

  /// Asks the shell to toggle the difficulty of the unit on screen in the
  /// direction being asked.
  ///
  /// Only while a unit is on screen — the question or the answer stage — and
  /// only when the shell offers it. The stage itself is left exactly as it
  /// was: marking never rates, reveals or moves on.
  void _toggleDifficult() {
    final SessionItem? item = _currentItem;
    final ValueChanged<SessionItem>? onToggle = widget.onToggleDifficult;
    if (item == null || onToggle == null) {
      return;
    }
    onToggle(item);
  }

  /// The draft with the setup's unit range, clamped to the deck, and its
  /// threshold applied: what a session started now would ask.
  SessionParameters _scopedDraft() {
    final int maxUnit = widget.deck.units.length;
    final int start = _startIndex.clamp(1, maxUnit).toInt();
    final int end = _endIndex.clamp(start, maxUnit).toInt();
    return _parametersWith(
      startIndex: start,
      endIndex: end,
      threshold: _thresholdPercent / 100,
    );
  }

  /// Whether **Difficult units only** is on and leaves nothing to ask in the
  /// chosen range, so the setup says so and refuses to start.
  bool get _nothingDifficultToAsk =>
      _draftParameters.difficultOnly &&
      itemsInScope(widget.deck, _scopedDraft()).isEmpty;

  Future<void> _startSession() async {
    // Refused before anything else: the setup already shows why.
    if (_nothingDifficultToAsk) {
      return;
    }
    // Give the shell a chance to create a fresh timestamped auto-save target
    // when a session starts with no statistics loaded (§3.7), and to warn about
    // statistics recorded in a different mode. Either can abort the start.
    final bool proceed =
        await widget.onSessionStarted?.call(_draftParameters.mode) ?? true;
    if (!proceed || !mounted) {
      return;
    }
    _draftParameters = _scopedDraft();
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
    _viewMode = _AnswerViewMode.correction;
    _selectNextItem();
  }

  void _backToSetup() {
    setState(() {
      _currentItem = null;
      _completed = false;
    });
    _notifySessionActive(false);
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

  /// Serves the next item, or shows the completion view when none is left.
  ///
  /// [statistics] are the ones the pools are drawn from. Right after an answer
  /// they must be the list just recorded: `widget.statistics` only catches up
  /// once the shell rebuilds, and until then still counts the last unit of a
  /// drill as unmastered — which served it a second time.
  void _selectNextItem({List<UnitStats>? statistics}) {
    final List<UnitStats> current = statistics ?? widget.statistics;
    final SessionItem? next = switch (_draftParameters.mode) {
      SessionMode.superQuery => _firstSuperQueryItem(current),
      SessionMode.levelLearning => _firstLevelLearningItem(current),
      SessionMode.practice || SessionMode.onceThrough => _nextOrderedItem(),
    };
    if (next == null) {
      setState(() {
        _endedWithNoneLeft = noDifficultUnitsLeft(
          widget.deck,
          _draftParameters,
          lastItem: _currentItem,
        );
        _currentItem = null;
        _completed = true;
        _evaluation = null;
      });
      _notifySessionActive(false);
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
    _notifySessionActive(true);
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
  /// session; in endless mode the order restarts — reshuffled when shuffle is
  /// on, so successive passes differ — and the first item of a new pass is
  /// never the one just shown (unless it is the only item).
  ///
  /// What is asked is read from the deck on every draw, as the drill and
  /// Level-Learning pools are: under **Difficult units only**, a unit unmarked
  /// with F12 is skipped. When nothing is left to ask, the session ends.
  SessionItem? _nextOrderedItem() {
    final Set<SessionItem> asked = itemsInScope(
      widget.deck,
      _draftParameters,
    ).toSet();
    while (_orderPosition < _order.length) {
      final SessionItem item = _order[_orderPosition++];
      if (asked.contains(item)) {
        return item;
      }
    }
    if (_draftParameters.mode == SessionMode.onceThrough) {
      return null;
    }
    // Every item of a fresh order is asked, so its first one is served.
    _order = sessionItemOrder(
      deck: widget.deck,
      parameters: _draftParameters,
      random: _random,
    );
    _orderPosition = 0;
    if (_order.isEmpty) {
      return null;
    }
    _avoidRepeatAtOrderStart();
    return _order[_orderPosition++];
  }

  /// Swaps the upcoming first item away when it repeats the one just shown.
  ///
  /// Only relevant at a pass boundary; a single-item order must still repeat.
  void _avoidRepeatAtOrderStart() {
    final SessionItem? last = _currentItem;
    if (last == null || _order.length < 2 || _order.first != last) {
      return;
    }
    final List<SessionItem> reordered = _order.toList();
    final int swapWith = 1 + _random.nextInt(reordered.length - 1);
    reordered[0] = reordered[swapWith];
    reordered[swapWith] = last;
    _order = List<SessionItem>.unmodifiable(reordered);
  }

  SessionItem? _firstSuperQueryItem(List<UnitStats> statistics) {
    return pickAvoidingRepeat(
      activeSuperQueryPool(
        deck: widget.deck,
        statistics: statistics,
        parameters: _draftParameters,
      ),
      _random,
      lastItem: _currentItem,
    );
  }

  SessionItem? _firstLevelLearningItem(List<UnitStats> statistics) {
    return pickAvoidingRepeat(
      activeLevelLearningPool(
        deck: widget.deck,
        statistics: statistics,
        levelStatistics: _levelStats,
        parameters: _draftParameters,
        entryLevelCap: widget.entryLevelCap,
      ),
      _random,
      lastItem: _currentItem,
    );
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

  /// Whether the answer's value is on screen as Level-Learning support.
  ///
  /// At the top of the ladder the whole solution is shown to be memorized, so
  /// the answer is visible before any Check — which the field grid, the icons
  /// and `F4` must all agree about, and do because they read this.
  bool get _answerShownAsSupport =>
      _isLevelLearning &&
      _activeLevel == kMaxSupportLevel &&
      !_level3Memorized;

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
    byIndex[item.unitIndex] = existing.withDirectionStats(
      item.direction,
      stats,
    );
    final List<LevelUnitStats> next = byIndex.values.toList(growable: false)
      ..sort((LevelUnitStats a, LevelUnitStats b) => a.index - b.index);
    return List<LevelUnitStats>.unmodifiable(next);
  }

  /// Applies [stats] for [item] to the session ladder and pushes it upstream.
  void _pushLevelStats(SessionItem item, LevelDirectionStats stats) {
    _levelStats = _levelStatsWith(item, stats);
    widget.onLevelStatisticsChanged?.call(_levelStats);
  }

  /// Returns the ladder with fresh seeds materialized for every unit the
  /// session asks that has no entry yet.
  ///
  /// Runs once per session start so the seeding (from the unit's prior drill
  /// bucket, capped by the entry level) is a one-time assignment; afterwards
  /// the ladder alone owns each unit's level. Existing entries are untouched,
  /// so re-starting or extending a session never resets progress. A unit left
  /// out by **Difficult units only** is not seeded until a session asks it.
  List<LevelUnitStats> _materializedLevelStats() {
    final Map<int, LevelUnitStats> byIndex = <int, LevelUnitStats>{
      for (final LevelUnitStats s in _levelStats) s.index: s,
    };
    final List<UnitStats> normalized = _normalizedStats();
    final Set<int> asked = <int>{
      for (final SessionItem item in itemsInScope(
        widget.deck,
        _draftParameters,
      ))
        item.unitIndex,
    };
    for (final int index in asked) {
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
    final List<LevelUnitStats> next = byIndex.values.toList(growable: false)
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
      final bool isFirst = i == 0;
      final bool isLast = i == fields.length - 1;
      _answerControllers[field.id] = TextEditingController();
      _answerFocusNodes[field.id] = FocusNode(
        onKeyEvent: (FocusNode node, KeyEvent event) =>
            _handleAnswerFieldKey(node, event, isFirst, isLast),
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
  /// Enter key from racing through multiple units. Arrow Down/Up move to the
  /// next/previous field but do not wrap: at the first or last field the key
  /// is consumed with no effect, so the default single-line caret jump never
  /// fires.
  KeyEventResult _handleAnswerFieldKey(
    FocusNode node,
    KeyEvent event,
    bool isFirst,
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

    if (key == LogicalKeyboardKey.arrowDown) {
      if (!isLast) node.nextFocus();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      if (!isFirst) node.previousFocus();
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
    final AnswerOutcome outcome = evaluation != null
        ? classifyOutcome(
            evaluation,
            similarityEnabled: widget.options.almostEnabled,
            similarityThreshold: widget.options.almostThreshold,
          )
        : AnswerOutcome.correct;
    // An exact match (or think-only) preselects Correct; a near-miss and a plain
    // wrong both default to Wrong (the user opts up to Close enough / Actually
    // correct).
    final AttemptRating defaultRating = _draftParameters.withInput
        ? (evaluation!.correct ? AttemptRating.correct : AttemptRating.wrong)
        : AttemptRating.correct;
    setState(() {
      _lastEntered = entered;
      _evaluation =
          evaluation ??
          const AnswerEvaluation(correct: true, fields: <FieldEvaluation>[]);
      _outcome = outcome;
      _selectedRating = defaultRating;
      // Always restart the toggle cycle for the newly revealed unit; skip the
      // correction state when there's nothing to correct.
      _viewMode = _evaluation!.correct
          ? _AnswerViewMode.solution
          : _AnswerViewMode.correction;
    });
    // Revealing removes the answer text fields (they become read-only rich
    // text), so focus would be left on a defunct node and the F-keys/Esc would
    // stop working. Pull focus back to the session root.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _rootFocusNode.requestFocus();
    });
    // Automatic speech reads the answer out here and nowhere else: this is the
    // one place a unit becomes revealed, and it runs once per unit whatever
    // the outcome — a mistake is the moment hearing it said properly is worth
    // most. Cycling the answer view afterwards touches none of this.
    if (widget.speechSettings.automatic) {
      unawaited(_speakAnswer(explain: false));
    }
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
    // What the WORKING record actually took, measured before and after. The
    // lifetime record is then incremented by exactly this and no more, which
    // is how a ceiling-suppressed attempt and a "no count" rating stay no-ops
    // in both records.
    final DirectionStats drillBefore = _statsFor(item);
    AttemptDelta drillDelta = AttemptDelta.none;
    int? level;
    AttemptDelta levelDelta = AttemptDelta.none;
    int? reachedLevel;
    // The statistics as they stand after this answer, when it recorded into
    // them. The next item must be drawn from these (see [_selectNextItem]).
    List<UnitStats>? recorded;
    if (_isLevelLearning) {
      // Level Learning records into the level ladder. Level 0 is free recall —
      // the same thing the drill modes test — so an attempt answered *at*
      // level 0 additionally counts towards the mode-agnostic statistics.
      // Read the level before recording: recordLevelLearningAttempt records at
      // the current level and only then promotes, so the attempt that promotes
      // a unit from level 1 to level 0 was answered at level 1 and must not
      // count here.
      final LevelDirectionStats before = _levelStatsFor(item);
      final int levelBefore = before.currentLevel;
      final LevelDirectionStats after = recordLevelLearningAttempt(
        before,
        _selectedRating,
        parameters: _draftParameters,
      );
      _pushLevelStats(item, after);
      level = levelBefore;
      levelDelta = AttemptDelta.between(
        before.currentLevelStats,
        after.levels[levelBefore] ?? const DirectionStats(),
      );
      reachedLevel = after.currentLevel;
      if (levelBefore == kFreeRecallLevel) {
        final List<UnitStats> updated = _recordRating(item, _selectedRating);
        drillDelta = AttemptDelta.between(
          drillBefore,
          updated[item.unitIndex - 1].statsFor(item.direction),
        );
        widget.onStatisticsChanged(updated);
        recorded = updated;
      }
    } else {
      final List<UnitStats> updated = _recordRating(item, _selectedRating);
      drillDelta = AttemptDelta.between(
        drillBefore,
        updated[item.unitIndex - 1].statsFor(item.direction),
      );
      widget.onStatisticsChanged(updated);
      recorded = updated;
    }
    widget.onAttemptRecorded?.call(
      RecordedAttempt(
        unitIndex: item.unitIndex,
        direction: item.direction,
        drill: drillDelta,
        level: level,
        levelDelta: levelDelta,
        reachedLevel: reachedLevel,
      ),
    );
    // Persist the just-recorded attempt to the auto-save target. Runs after the
    // stats callbacks above so the shell's document already holds this attempt;
    // the shell queues the write asynchronously so it never stalls the cycle.
    widget.onPersistStatistics?.call();
    _selectNextItem(statistics: recorded);
  }

  /// The mode-agnostic counters [item] currently stands at.
  DirectionStats _statsFor(SessionItem item) {
    return _normalizedStats()[item.unitIndex - 1].statsFor(item.direction);
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
      withInput: parameters.mode == SessionMode.levelLearning
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
    bool? difficultOnly,
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
      difficultOnly: difficultOnly ?? _draftParameters.difficultOnly,
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
    if (_outcome == AnswerOutcome.correct) {
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
    if (_outcome == AnswerOutcome.almost) {
      // Near-miss: Wrong is preselected; "Close enough" is the relabeled
      // Actually-correct (attempts += 1; correct += 1) and always offered here.
      return <MapEntry<AttemptRating, String>>[
        MapEntry<AttemptRating, String>(
          AttemptRating.wrong,
          messages.message(LearnAnywhereMessage.learnRatingWrong),
        ),
        MapEntry<AttemptRating, String>(
          AttemptRating.correct,
          messages.message(LearnAnywhereMessage.learnRatingCloseEnough),
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
    if (_outcome == AnswerOutcome.correct) {
      const List<AttemptRating> r = <AttemptRating>[
        AttemptRating.correct,
        AttemptRating.wrong,
        AttemptRating.noCount,
      ];
      return index < r.length ? r[index] : null;
    }
    if (_outcome == AnswerOutcome.almost) {
      const List<AttemptRating> r = <AttemptRating>[
        AttemptRating.wrong,
        AttemptRating.correct,
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

  /// Leaves the session (Esc, or the Cancel button on setup/completion/a live
  /// session) straight away — no confirmation. Per-unit statistics already
  /// live in the shell's document (and are auto-saved per unit when that
  /// option is on), so there is nothing a prompt could protect here.
  void _cancelSession() {
    widget.onExit?.call();
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
            label: Text(
              messages.message(LearnAnywhereMessage.learnEmptyOpenEditor),
            ),
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
    required this.useAllUnits,
    required this.onDirectionChanged,
    required this.onModeChanged,
    required this.onEntryLevelCapChanged,
    required this.onShuffleChanged,
    required this.nothingDifficultToAsk,
    required this.difficultCount,
    required this.onDifficultOnlyChanged,
    required this.onWithInputChanged,
    required this.onUseAllUnitsChanged,
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

  /// Whether the range is pinned to the whole deck, disabling both fields.
  final bool useAllUnits;

  final ValueChanged<DirectionSelection> onDirectionChanged;
  final ValueChanged<SessionMode> onModeChanged;
  final ValueChanged<int> onEntryLevelCapChanged;
  final ValueChanged<bool> onShuffleChanged;

  /// Whether Difficult units only leaves nothing to ask in the chosen range;
  /// the setup then says so and cannot start.
  final bool nothingDifficultToAsk;

  /// The difficult units in the chosen range and direction, of the deck's;
  /// shown on the Difficult units only option.
  final DifficultUnitCount difficultCount;
  final ValueChanged<bool> onDifficultOnlyChanged;
  final ValueChanged<bool> onWithInputChanged;
  final ValueChanged<bool> onUseAllUnitsChanged;
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
        if (isLevelLearning)
          _DropdownRow<int>(
            label: messages.message(LearnAnywhereMessage.learnEntryLevel),
            tooltip: messages.message(LearnAnywhereMessage.learnEntryLevelHint),
            value: entryLevelCap.clamp(kFreeRecallLevel, kMaxSupportLevel),
            items: <DropdownMenuItem<int>>[
              for (
                int level = kMaxSupportLevel;
                level >= kFreeRecallLevel;
                level -= 1
              )
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
        _NumberRow(
          label: messages.message(LearnAnywhereMessage.learnMasteryThreshold),
          tooltip: messages.message(
            LearnAnywhereMessage.learnMasteryThresholdTooltip,
          ),
          value: thresholdPercent,
          minimum: 1,
          maximum: 100,
          onChanged: onThresholdChanged,
        ),
        // Level Learning is always "with input", so the toggle is hidden there.
        if (!isLevelLearning)
          _ToggleRow(
            label: messages.message(
              LearnAnywhereMessage.queryOptionWithAnswerInput,
            ),
            value: parameters.withInput,
            onChanged: onWithInputChanged,
          ),
        _ToggleRow(
          label: messages.message(LearnAnywhereMessage.learnShuffleUnits),
          value: parameters.shuffle,
          onChanged: onShuffleChanged,
        ),
        _ToggleRow(
          label: messages
              .message(LearnAnywhereMessage.learnDifficultOnly)
              .replaceAll('{count}', difficultCount.text),
          tooltip: difficultCount.coversDeck
              ? messages
                    .message(LearnAnywhereMessage.learnDifficultOnlyDeckTooltip)
                    .replaceAll('{total}', '${difficultCount.inDeck}')
              : messages
                    .message(
                      LearnAnywhereMessage.learnDifficultOnlyRangeTooltip,
                    )
                    .replaceAll('{count}', '${difficultCount.inRange}')
                    .replaceAll('{total}', '${difficultCount.inDeck}'),
          value: parameters.difficultOnly,
          onChanged: onDifficultOnlyChanged,
        ),
        if (nothingDifficultToAsk)
          Padding(
            padding: const EdgeInsets.only(
              bottom: LearnAnywhereTokens.gapSmall,
            ),
            child: Text(
              messages.message(LearnAnywhereMessage.learnNoDifficultUnits),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        _ToggleRow(
          label: messages
              .message(LearnAnywhereMessage.learnUseAllUnits)
              .replaceAll('{count}', deck.units.length.toString()),
          value: useAllUnits,
          onChanged: onUseAllUnitsChanged,
        ),
        const SizedBox(height: LearnAnywhereTokens.gapSmall),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _NumberRow(
                label: messages.message(LearnAnywhereMessage.learnRangeStart),
                tooltip: messages.message(
                  LearnAnywhereMessage.learnRangeStartTooltip,
                ),
                value: startIndex,
                minimum: 1,
                maximum: deck.units.length,
                enabled: !useAllUnits,
                onChanged: onStartChanged,
              ),
            ),
            const SizedBox(width: LearnAnywhereTokens.gapMedium),
            Expanded(
              child: _NumberRow(
                label: messages.message(LearnAnywhereMessage.learnRangeEnd),
                tooltip: messages.message(
                  LearnAnywhereMessage.learnRangeEndTooltip,
                ),
                value: endIndex,
                minimum: 1,
                maximum: deck.units.length,
                // Clearing "End unit" means "up to the last unit", not 1.
                emptyFallback: deck.units.length,
                enabled: !useAllUnits,
                onChanged: onEndChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: LearnAnywhereTokens.gapMedium),
        Wrap(
          spacing: LearnAnywhereTokens.gapSmall,
          children: <Widget>[
            FilledButton.icon(
              onPressed: nothingDifficultToAsk ? null : onStartSession,
              icon: const Icon(Icons.play_arrow),
              label: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    messages.message(LearnAnywhereMessage.learnStartSession),
                  ),
                  Text('F3', style: LearnAnywhereTokens.keyHint(context)),
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
                  Text('Esc', style: LearnAnywhereTokens.keyHint(context)),
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
    required this.speechPlan,
    required this.onSpeak,
    required this.onReadAloud,
    required this.answerShownAsSupport,
    required this.levelStatistics,
    required this.levelNames,
    required this.entryLevelCap,
    required this.options,
    required this.parameters,
    required this.item,
    required this.evaluation,
    required this.outcome,
    required this.selectedRating,
    required this.activeLevel,
    required this.level3Memorized,
    required this.serveNonce,
    required this.ratingEntries,
    required this.answerControllers,
    required this.answerFocusNodes,
    required this.enteredAnswers,
    required this.elapsedSeconds,
    required this.viewMode,
    required this.onReveal,
    required this.onCellAnswerChanged,
    required this.onSetLevel,
    required this.onRatingChanged,
    required this.onToggleView,
    required this.onRestoreFocus,
    required this.onContinue,
    required this.onCancel,
    required this.onToggleDifficult,
  });

  final LearningDeck deck;
  final List<UnitStats> statistics;

  /// What may be spoken for this unit as it currently stands, decided by the
  /// core policy. The view renders it and decides nothing of its own.
  final SpeechPlan speechPlan;

  /// Says one of [speechPlan]'s utterances, or explains why it cannot.
  final ValueChanged<SpeechUtterance> onSpeak;

  /// Reads the answer aloud, as `F4` does; `null` hides the Read aloud pill,
  /// because `F4` would play nothing.
  final VoidCallback? onReadAloud;

  /// Whether the whole answer is on screen as Level-Learning support, before
  /// any Check — the state the top of the ladder shows for memorizing.
  ///
  /// Passed rather than re-derived so the field grid and the speech plan can
  /// never disagree about what the learner can see.
  final bool answerShownAsSupport;

  final List<LevelUnitStats> levelStatistics;
  final List<String> levelNames;
  final int entryLevelCap;
  final DesktopQueryOptions options;
  final SessionParameters parameters;
  final SessionItem item;
  final AnswerEvaluation? evaluation;

  /// Display classification of the revealed answer (correct/almost/wrong).
  final AnswerOutcome outcome;
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
  final _AnswerViewMode viewMode;
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

  /// Toggles the unit's difficulty in the asked direction; `null` hides the
  /// Difficult pill.
  final VoidCallback? onToggleDifficult;

  bool get _isLevelLearning => parameters.mode == SessionMode.levelLearning;

  /// The Difficult pill for [unit] in the asked direction, or nothing when
  /// the shell offers none.
  List<Widget> _difficultPill(LearningUnit unit) {
    final VoidCallback? onToggle = onToggleDifficult;
    if (onToggle == null) {
      return const <Widget>[];
    }
    return <Widget>[
      DifficultPill(
        key: const Key('learnDifficultPill'),
        difficult: unit.isDifficultIn(item.direction),
        onPressed: onToggle,
      ),
    ];
  }

  /// The Read aloud pill, or nothing when `F4` would play nothing.
  List<Widget> _readAloudPill() {
    final VoidCallback? onPressed = onReadAloud;
    if (onPressed == null) {
      return const <Widget>[];
    }
    return <Widget>[
      _ReadAloudPill(key: const Key('learnReadAloudPill'), onPressed: onPressed),
    ];
  }

  /// The current unit's own accuracy for the active direction, as a header
  /// segment (e.g. "Unit accuracy: 3/4 (75%)"). Always numeric, including
  /// `0/0 (0%)` before the unit has been attempted in this scope.
  String _unitAccuracyLabel(LearnAnywhereLocalizations messages) {
    final DirectionStats stats = unitDirectionStats(
      statistics: statistics,
      unitIndex: item.unitIndex,
      direction: item.direction,
    );
    return '${messages.message(LearnAnywhereMessage.learnUnitAccuracy)}: '
        '${stats.correct}/${stats.attempts} (${accuracyPercent(stats)}%)';
  }

  /// The rich-text runs of [value] (a plain value becomes a single run), used as
  /// the base for the reveal-screen diff overlay.
  static List<RichTextRun> _runsOf(FieldValue value) {
    return switch (value) {
      PlainFieldValue(:final String text) => <RichTextRun>[
        RichTextRun(text: text),
      ],
      RichFieldValue(:final List<RichTextRun> runs) => runs,
    };
  }

  /// Builds the live-stats pills: Attempts first, then mode-specific fields.
  ///
  /// Non-Level-Learning: Mastered / Remaining / Accuracy `x/y (z%)`. Level
  /// Learning: one pill per level (highest support first) with the count of
  /// units at that level and its share. The clock pill is appended for both when
  /// enabled.
  ///
  /// Every pill is a **deck total in the session's direction** ([deckWideScope],
  /// [directionViewFor]): restricting the unit range narrows what is asked, not
  /// what is counted, so no two pills describe different populations. They are
  /// also **derived from the statistics**, never counted per sitting, so they
  /// agree with the statistics screen for the same deck — its **View** on
  /// **Combined** for a Both session, on that direction otherwise — and survive
  /// leaving a session or restarting the app. Level Learning reads the ladder
  /// instead ([aggregateLadderAttempts]): only its level-0 attempts reach the
  /// mode-agnostic statistics, so its Attempts figure is deliberately larger
  /// than the statistics screen's total.
  ///
  /// The one exception is Remaining in a restricted session ([remainingReadout]):
  /// "n (m)" adds what this session has left to ask, which reaches 0 exactly
  /// when the drill ends. Every pill carries a tooltip saying what it counts.
  List<Widget> _statPills(
    LearnAnywhereLocalizations messages,
    bool timeWarning,
  ) {
    final SessionParameters readoutScope = deckWideScope(parameters);
    final StatisticsDirectionView view = directionViewFor(
      parameters.directionSelection,
    );
    final int totalItems = sessionItemCount(
      unitCount: deck.units.length,
      parameters: readoutScope,
    );
    // Deck-wide drill totals in the session's direction — the same figures the
    // statistics screen sums into Total Attempts and Correct Attempts under the
    // matching View. Level Learning never reads them, so it never pays for the
    // pass.
    final StatisticsSummary? drillTotals = _isLevelLearning
        ? null
        : aggregateStatistics(
            unitCount: deck.units.length,
            statistics: statistics,
            view: view,
          );
    final int attempts =
        drillTotals?.totalAttempts ??
        aggregateLadderAttempts(
          levelStatistics: levelStatistics,
          unitCount: deck.units.length,
          view: view,
        ).attempts;
    final List<Widget> pills = <Widget>[
      _StatPill(
        label: messages.message(LearnAnywhereMessage.learnLiveAttempts),
        value: '$attempts',
        tooltip: messages.message(
          _isLevelLearning
              ? LearnAnywhereMessage.learnLiveAttemptsLevelTooltip
              : LearnAnywhereMessage.learnLiveAttemptsTooltip,
        ),
      ),
    ];
    if (_isLevelLearning) {
      final Map<int, int> counts = _levelCounts(readoutScope);
      var inPool = 0;
      for (
        int level = kMaxSupportLevel;
        level >= kFreeRecallLevel;
        level -= 1
      ) {
        final int count = counts[level] ?? 0;
        inPool += count;
        final int pct = totalItems == 0
            ? 0
            : ((count / totalItems) * 100).round();
        pills.add(
          _StatPill(
            label: levelNameFor(levelNames, level),
            value: '$count ($pct%)',
            tooltip: messages.message(
              LearnAnywhereMessage.learnLiveLevelTooltip,
            ),
          ),
        );
      }
      // Units that have left the pool (mastered at level 0).
      final int mastered = (totalItems - inPool).clamp(0, totalItems);
      final int masteredPct = totalItems == 0
          ? 0
          : ((mastered / totalItems) * 100).round();
      pills.add(
        _StatPill(
          label: messages.message(LearnAnywhereMessage.learnLiveMastered),
          value: '$mastered ($masteredPct%)',
          tooltip: messages.message(
            LearnAnywhereMessage.learnLiveMasteredLevelTooltip,
          ),
        ),
      );
    } else {
      final RemainingReadout remaining = remainingReadout(
        deck: deck,
        statistics: statistics,
        parameters: parameters,
      );
      final int mastered = (totalItems - remaining.inDeck).clamp(0, totalItems);
      // Non-null in this branch: only Level Learning skips the aggregation.
      final int correct = drillTotals!.totalCorrect;
      final int pct = attempts == 0 ? 0 : ((correct / attempts) * 100).round();
      pills.addAll(<Widget>[
        _StatPill(
          label: messages.message(LearnAnywhereMessage.learnLiveMastered),
          value: '$mastered/$totalItems',
          tooltip: messages.message(
            LearnAnywhereMessage.learnLiveMasteredTooltip,
          ),
        ),
        _StatPill(
          label: messages.message(LearnAnywhereMessage.learnLiveRemaining),
          value: remaining.text,
          tooltip: remaining.restricted
              ? messages
                    .message(
                      LearnAnywhereMessage.learnLiveRemainingRestrictedTooltip,
                    )
                    .replaceAll('{total}', '${remaining.inDeck}')
                    .replaceAll('{count}', '${remaining.inSession}')
              : messages.message(
                  LearnAnywhereMessage.learnLiveRemainingTooltip,
                ),
        ),
        _StatPill(
          label: messages.message(LearnAnywhereMessage.learnLiveAccuracy),
          value: '$correct/$attempts ($pct%)',
          tooltip: messages.message(
            LearnAnywhereMessage.learnLiveAccuracyTooltip,
          ),
        ),
      ]);
    }
    if (options.showClock) {
      pills.add(
        _StatPill(
          label: messages.message(LearnAnywhereMessage.learnLiveTime),
          value: _clockText(elapsedSeconds),
          tooltip: messages.message(LearnAnywhereMessage.learnLiveTimeTooltip),
          warning: timeWarning,
        ),
      );
    }
    return pills;
  }

  /// Counts not-yet-mastered Level-Learning units by current level.
  ///
  /// [readoutScope] is the deck-wide scope the pills describe, not the session's
  /// own range — see [_statPills].
  Map<int, int> _levelCounts(SessionParameters readoutScope) {
    final List<SessionItem> pool = activeLevelLearningPool(
      deck: deck,
      statistics: statistics,
      levelStatistics: levelStatistics,
      parameters: readoutScope,
      entryLevelCap: entryLevelCap,
    );
    final Map<int, LevelUnitStats> byIndex = <int, LevelUnitStats>{
      for (final LevelUnitStats s in levelStatistics) s.index: s,
    };
    final Map<int, UnitStats> statsByIndex = <int, UnitStats>{
      for (final UnitStats s in statistics) s.index: s,
    };
    final Map<int, int> counts = <int, int>{
      for (int level = kMaxSupportLevel; level >= kFreeRecallLevel; level -= 1)
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
    final double labelWidth = computeFieldLabelWidth(context, deck.mask);
    int? firstAnswerId;
    int? lastAnswerId;
    for (final FieldDefinition f in visibleFields) {
      if (f.roleFor(item.direction) == FieldRole.answer) {
        firstAnswerId ??= f.id;
        lastAnswerId = f.id;
      }
    }
    // Fixed monospace column widths (see FieldRow) can exceed the viewport for
    // long fields, so FieldRowGrid scrolls the grid horizontally rather than
    // shrinking the value boxes to fit.
    return FieldRowGrid(
      rows: <Widget>[
        for (int i = 0; i < visibleFields.length; i++)
          Builder(
            builder: (BuildContext ctx) {
              final FieldDefinition field = visibleFields[i];
              final FieldRole role = field.roleFor(item.direction);

              final bool showUserAnswer =
                  role == FieldRole.answer &&
                  evaluation != null &&
                  parameters.withInput &&
                  viewMode == _AnswerViewMode.yourAnswer;

              final Color accentColor;
              final Color bgColor;
              final FieldValue displayValue;

              if (showUserAnswer) {
                final ColorScheme rowColors = Theme.of(ctx).colorScheme;
                accentColor = rowColors.outline;
                bgColor = rowColors.surfaceContainerHighest;
                displayValue = FieldValue.plain(enteredAnswers[field.id] ?? '');
              } else {
                accentColor = LearnAnywhereFieldAccents.accentFor(role);
                bgColor = LearnAnywhereFieldAccents.backgroundFor(
                  role,
                  Theme.of(ctx).brightness,
                );
                final FieldValue expectedValue = unit.valueForFieldId(field.id);
                // On the correction view, an answer field shows the student's
                // mistakes marked on the solution; a field with a mistake
                // hides its own conflicting formatting, a correct one keeps
                // it. The plain solution view always shows the expected value
                // with no diff marks.
                displayValue =
                    (viewMode == _AnswerViewMode.correction &&
                        role == FieldRole.answer &&
                        evaluation != null &&
                        parameters.withInput)
                    ? FieldValue.rich(
                        buildCorrectionRuns(
                          expectedRuns: _runsOf(expectedValue),
                          enteredPlain: enteredAnswers[field.id] ?? '',
                          options: options.evaluationOptions,
                        ),
                      )
                    : expectedValue;
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
                      field.id == lastAnswerId,
                    )
                  : null;

              final TextStyle valueStyle = LearnAnywhereTokens.monospace(
                Theme.of(ctx).textTheme.bodyMedium,
              );
              // Every row — plain text, editable field, or Level-Learning
              // scaffold — sizes its value column to the field length in
              // monospace character widths, so the answer column matches
              // the question column and stays constant while browsing.
              final double valueWidth = computeFieldValueWidth(
                fieldLength: field.length,
                charWidth: measureMonospaceCharWidth(valueStyle),
              );

              final bool isEditable =
                  role == FieldRole.answer &&
                  !isFieldValueVisible(
                    field,
                    item.direction,
                    afterCheck: evaluation != null,
                    answerShown: answerShownAsSupport,
                  );
              final Widget content =
                  override ??
                  (isEditable
                      ? _AnswerTextField(
                          controller: answerControllers[field.id],
                          focusNode: answerFocusNodes[field.id],
                          maxLength: field.length,
                        )
                      : LearnAnywhereRichText(
                          value: displayValue,
                          maxLines: 3,
                          style: valueStyle,
                        ));

              // One rule, no special cases: a field carries a speaker exactly
              // when the policy put an utterance in the plan for it, which is
              // exactly when its value is on screen.
              final SpeechUtterance? utterance = speechPlan.utteranceFor(
                field.id,
              );

              return FieldRow(
                label: field.name,
                labelWidth: labelWidth,
                valueWidth: valueWidth,
                accentColor: accentColor,
                backgroundColor: bgColor,
                value: content,
                trailing: utterance == null
                    ? null
                    : SpeakerButton(
                        key: Key('speakField-${field.id}'),
                        tooltip: LearnAnywhereLocalizations.of(
                          ctx,
                        ).message(LearnAnywhereMessage.learnSpeakField),
                        onPressed: () => onSpeak(utterance),
                      ),
              );
            },
          ),
      ],
    );
  }

  /// The Level-Learning answer widget for [field] at the active level, or null
  /// to fall back to a normal editable text field (levels 0 and memorized 3).
  Widget? _levelAnswerContent(
    BuildContext ctx,
    FieldDefinition field,
    LearningUnit unit,
    bool autofocus,
    bool isLastAnswer,
  ) {
    final String plain = unit.valueForFieldId(field.id).plainText;
    final int level = activeLevel;
    final TextStyle style = LearnAnywhereTokens.monospace(
      Theme.of(ctx).textTheme.bodyMedium,
    );

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
        isLastAnswer: isLastAnswer,
        onChanged: (String value) => onCellAnswerChanged(field.id, value),
        onSubmit: onReveal,
      );
    }
    return null;
  }

  /// Pre-check button row, laid out like the answer stage's: one group with
  /// the Level-Learning help override (Less/More help), Read aloud where the
  /// solution is on screen, the primary action (Check / Reveal, or Hide &
  /// type at level 3) and Cancel last; then the Difficult pill on its own.
  Widget _preCheckButtons(
    BuildContext context,
    LearnAnywhereLocalizations messages,
    LearningUnit unit,
  ) {
    final bool level3Pending =
        _isLevelLearning && activeLevel == kMaxSupportLevel && !level3Memorized;
    final List<Widget> actions = <Widget>[
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
      ..._readAloudPill(),
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
            Text('F10', style: LearnAnywhereTokens.keyHint(context)),
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
            Text('Esc', style: LearnAnywhereTokens.keyHint(context)),
          ],
        ),
      ),
    ];
    return Wrap(
      key: const Key('learnQuestionPills'),
      spacing: LearnAnywhereTokens.gapLarge,
      runSpacing: LearnAnywhereTokens.gapMedium,
      children: <Widget>[
        _PillGroup(
          key: const Key('learnQuestionPillsGroup'),
          children: <Widget>[
            for (int i = 0; i < actions.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: LearnAnywhereTokens.gapSmall),
              actions[i],
            ],
          ],
        ),
        // A group of its own, as after the reveal.
        ..._difficultPill(unit),
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

    // Only render fields that are relevant in the current state.
    final List<FieldDefinition> visibleFields = category.fields
        .where(
          (FieldDefinition f) => isFieldRowVisible(
            f,
            item.direction,
            afterCheck: evaluation != null,
            withInput: parameters.withInput,
          ),
        )
        .toList(growable: false);

    final bool timeWarning =
        options.showClock &&
        options.timeLimitSeconds > 0 &&
        elapsedSeconds >= options.timeLimitSeconds;

    // Header: "Unit x/y", the level name (for Level Learning, right after the
    // unit), then category, direction, and — outside Level Learning, where a
    // per-unit drill accuracy isn't meaningful — this unit's own accuracy.
    final List<String> headerParts = <String>[
      _learnUnitHeader(messages, item.unitIndex, deck.units.length),
      if (_isLevelLearning) levelNameFor(levelNames, activeLevel),
      category.name,
      deck.mask.labelFor(item.direction),
      if (!_isLevelLearning) _unitAccuracyLabel(messages),
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
              key: const Key('learnStatPills'),
              spacing: LearnAnywhereTokens.gapSmall,
              runSpacing: LearnAnywhereTokens.gapSmall,
              children: _statPills(messages, timeWarning),
            ),
            const SizedBox(height: LearnAnywhereTokens.gapSmall),
            // The badge sits on the unit's own line, so it reads as part of
            // the card; the Wrap drops it below the header when both do not
            // fit.
            Wrap(
              spacing: LearnAnywhereTokens.gapMedium,
              runSpacing: LearnAnywhereTokens.gapSmall,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(headerText, style: Theme.of(context).textTheme.titleSmall),
                if (unit.isDifficultIn(item.direction))
                  DifficultBadge(flags: unit.flagsFor(item.direction)),
              ],
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
                    messages.message(switch (outcome) {
                      AnswerOutcome.correct =>
                        LearnAnywhereMessage.learnCorrectMessage,
                      AnswerOutcome.almost =>
                        LearnAnywhereMessage.learnAlmostMessage,
                      AnswerOutcome.wrong =>
                        LearnAnywhereMessage.learnWrongMessage,
                    }),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(width: 8),
                  Text(switch (outcome) {
                    AnswerOutcome.correct => '😊',
                    AnswerOutcome.almost => '🤏',
                    AnswerOutcome.wrong => '😔',
                  }, style: const TextStyle(fontSize: 40)),
                ],
              ),
              const SizedBox(height: LearnAnywhereTokens.gapSmall),
              // Two _PillGroups nested in a Wrap: the whole group drops to
              // its own line (with a bigger gap than the pills within a
              // group) once the window is too narrow for both to sit side
              // by side. Within each group the keyed pills run in F-key
              // order, and Cancel comes last in its group.
              Wrap(
                key: const Key('learnAnswerPills'),
                spacing: LearnAnywhereTokens.gapLarge,
                runSpacing: LearnAnywhereTokens.gapMedium,
                // Bottom-aligned, so the pills beside the evaluation group
                // line up with its buttons rather than with its caption.
                crossAxisAlignment: WrapCrossAlignment.end,
                children: <Widget>[
                  _PillGroup(
                    key: const Key('learnActionPillsGroup'),
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: onContinue,
                        icon: const Icon(Icons.arrow_forward),
                        label: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              messages.message(
                                LearnAnywhereMessage.learnContinue,
                              ),
                            ),
                            Text('F3', style: LearnAnywhereTokens.keyHint(context)),
                          ],
                        ),
                      ),
                      for (final Widget pill in _readAloudPill()) ...<Widget>[
                        const SizedBox(width: LearnAnywhereTokens.gapSmall),
                        pill,
                      ],
                      if (parameters.withInput) ...<Widget>[
                        const SizedBox(width: LearnAnywhereTokens.gapSmall),
                        _ToggleViewButton(
                          label: messages.message(
                            _answerViewModeMessage(viewMode),
                          ),
                          hint:
                              '${messages.message(LearnAnywhereMessage.learnSwitchHint)}: F9',
                          onPressed: onToggleView,
                          onRestoreFocus: onRestoreFocus,
                        ),
                      ],
                      const SizedBox(width: LearnAnywhereTokens.gapSmall),
                      FilledButton.tonalIcon(
                        onPressed: onCancel,
                        icon: const Icon(Icons.close),
                        label: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              messages.message(
                                LearnAnywhereMessage.actionCancel,
                              ),
                            ),
                            Text('Esc', style: LearnAnywhereTokens.keyHint(context)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  _PillGroup(
                    key: const Key('learnEvaluationPillsGroup'),
                    caption: messages.message(
                      LearnAnywhereMessage.learnEvaluateAs,
                    ),
                    children: <Widget>[
                      for (
                        int i = 0;
                        i < ratingEntries.length;
                        i++
                      ) ...<Widget>[
                        if (i > 0)
                          const SizedBox(width: LearnAnywhereTokens.gapSmall),
                        _EvalButton(
                          label: ratingEntries[i].value,
                          hint: 'F${i + 5}',
                          filled: ratingEntries[i].key == selectedRating,
                          onPressed: () =>
                              onRatingChanged(ratingEntries[i].key),
                          onRestoreFocus: onRestoreFocus,
                        ),
                      ],
                    ],
                  ),
                  // A group of its own: marking is neither an action on the
                  // answer nor a rating of it.
                  ..._difficultPill(unit),
                ],
              ),
            ] else ...<Widget>[
              const SizedBox(height: LearnAnywhereTokens.gapLarge),
              // ── Pre-check buttons ──────────────────────────────────────
              _preCheckButtons(context, messages, unit),
            ],
          ],
        ),
      ),
    );
  }
}

/// An atomic pill group for a [Wrap]: its [Row] can never split across
/// lines, and [FittedBox] shrinks it as a last resort instead of
/// overflowing, on a window narrower than the group itself.
final class _PillGroup extends StatelessWidget {
  const _PillGroup({super.key, required this.children, this.caption});

  final List<Widget> children;

  /// A small label above the pills, left-aligned with the first of them.
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final Widget row = Row(mainAxisSize: MainAxisSize.min, children: children);
    final String? caption = this.caption;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: caption == null
          ? row
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(caption, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: LearnAnywhereTokens.gapSmall / 2),
                row,
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
      style: LearnAnywhereTokens.monospace(
        Theme.of(context).textTheme.bodyMedium,
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

// Each scaffold character occupies exactly one monospace character width (the
// same width used to size the value column), so blanks, revealed letters and
// shown context all line up and the answer column matches the question column.
// The line reads like normal text: revealed (given) letters carry a subtle
// background — like the question — while blanks are marked only by a thin
// underline the student writes on. Every state shares one baseline via a matched
// strut, so typed characters sit exactly where the revealed ones do.

/// Shared height of every scaffold cell slot, so all states share one baseline.
const double _kScaffoldSlotHeight = 24;

/// Matched strut so a plain [Text] glyph and a [TextField] glyph share the same
/// line box (and therefore the same baseline). Without this, the editable
/// blanks render lower than the revealed letters beside them.
StrutStyle _scaffoldStrut(TextStyle style) => StrutStyle(
  fontSize: style.fontSize,
  fontFamily: style.fontFamily,
  fontFamilyFallback: style.fontFamilyFallback,
  forceStrutHeight: true,
);

/// Background behind a "given" (revealed) character, marking it as provided
/// context like the question — a touch more pronounced than the row tint, and
/// neutral so it stays legible on every theme.
Color _givenCellColor(ColorScheme colors) =>
    colors.onSurface.withValues(alpha: 0.12);

/// Colour of the thin "type here" underline: the muted text colour, so it reads
/// as an unobtrusive writing line rather than a bold accent.
Color _blankUnderlineColor(ColorScheme colors) => colors.onSurfaceVariant;

/// Splits [cells] into per-word runs (whitespace `shown` cells become a
/// one-character gap) and lays the words out in a [Wrap] so word boundaries stay
/// intact. Each cell is turned into a widget by [cellBuilder], which receives a
/// blank cell's running 0-based blank index (−1 for non-blank cells).
Widget _scaffoldLayout(
  List<MaskCell> cells,
  double gapWidth,
  Widget Function(MaskCell cell, int blankIndex) cellBuilder,
) {
  final List<Widget> words = <Widget>[];
  List<Widget> current = <Widget>[];
  void flush() {
    if (current.isNotEmpty) {
      words.add(Row(mainAxisSize: MainAxisSize.min, children: current));
      current = <Widget>[];
    }
  }

  int blankIndex = 0;
  for (final MaskCell cell in cells) {
    final bool isWhitespace =
        cell.kind == MaskCellKind.shown && cell.char.trim().isEmpty;
    if (isWhitespace) {
      flush();
      words.add(SizedBox(width: gapWidth));
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

/// A read-only Level-Learning scaffold: revealed letters and empty "type here"
/// slots. Used for the level-3 full-solution preview.
final class _ScaffoldPreview extends StatelessWidget {
  const _ScaffoldPreview({required this.cells, required this.textStyle});

  final List<MaskCell> cells;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final double cellWidth = measureMonospaceCharWidth(textStyle);
    return _scaffoldLayout(cells, cellWidth, (MaskCell cell, int _) {
      switch (cell.kind) {
        case MaskCellKind.shown:
          return _ShownCell(
            char: cell.char,
            width: cellWidth,
            textStyle: textStyle,
          );
        case MaskCellKind.revealed:
          return _RevealedCell(
            char: cell.char,
            width: cellWidth,
            textStyle: textStyle,
            colors: colors,
          );
        case MaskCellKind.blank:
          return _BlankSlot(width: cellWidth, colors: colors);
      }
    });
  }
}

/// A shown context character (punctuation the mask never hides): a plain glyph
/// in the normal foreground, one character wide, with no highlight.
final class _ShownCell extends StatelessWidget {
  const _ShownCell({
    required this.char,
    required this.width,
    required this.textStyle,
  });

  final String char;
  final double width;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: _kScaffoldSlotHeight,
      child: Center(
        child: Text(
          char,
          maxLines: 1,
          strutStyle: _scaffoldStrut(textStyle),
          style: textStyle,
        ),
      ),
    );
  }
}

/// A revealed (given) letter: shown in the normal foreground on a subtle
/// background, so it reads as provided context — like the question — rather than
/// as something the student typed.
final class _RevealedCell extends StatelessWidget {
  const _RevealedCell({
    required this.char,
    required this.width,
    required this.textStyle,
    required this.colors,
  });

  final String char;
  final double width;
  final TextStyle textStyle;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: _kScaffoldSlotHeight,
      alignment: Alignment.center,
      color: _givenCellColor(colors),
      child: Text(
        char,
        maxLines: 1,
        strutStyle: _scaffoldStrut(textStyle),
        style: textStyle,
      ),
    );
  }
}

/// A read-only blank slot one character wide: just the thin "type here"
/// underline. Used for the level-3 preview, where blanks are shown but not yet
/// editable.
final class _BlankSlot extends StatelessWidget {
  const _BlankSlot({required this.width, required this.colors});

  final double width;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: _kScaffoldSlotHeight,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 1,
            right: 1,
            bottom: 3,
            child: Container(height: 1, color: _blankUnderlineColor(colors)),
          ),
        ],
      ),
    );
  }
}

/// The editable scaffold (levels 1 and 2): locked revealed letters interleaved
/// with per-blank single-character inputs the student fills. Reconstructs the
/// full answer string (revealed + typed + shown) and reports it via [onChanged].
///
/// It reports whenever it is built or rebuilt, not only when a blank is typed
/// into, so a field the scaffold reveals whole reaches grading as the letters
/// it displayed rather than as an empty answer. Reporting writes into the
/// host's answer buffer, so the build-time report is deferred to after the
/// frame.
final class _LevelScaffoldInput extends StatefulWidget {
  const _LevelScaffoldInput({
    required this.cells,
    required this.textStyle,
    required this.autofocus,
    required this.isLastAnswer,
    required this.onChanged,
    required this.onSubmit,
    super.key,
  });

  final List<MaskCell> cells;
  final TextStyle textStyle;
  final bool autofocus;

  /// Whether this scaffold is the last answer field of the unit. Only then does
  /// Enter on the final blank submit; otherwise it advances to the next field.
  final bool isLastAnswer;
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
    _reportAfterFrame();
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
    if (!listEquals(widget.cells, oldWidget.cells)) {
      _reportAfterFrame();
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

  /// Reports the reconstruction once the current frame is done, so building
  /// this scaffold never writes into the host's answer buffer mid-build.
  void _reportAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _report();
    });
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
        // More blanks in this field: advance to the next one.
        _nodes[index + 1].requestFocus();
      } else if (isEnter && widget.isLastAnswer) {
        // Final blank of the last answer field: Enter checks the answer.
        widget.onSubmit();
      } else {
        // Final blank of an earlier field (or Tab): move to the next field,
        // so Enter never checks while other answer lines are still empty.
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
    final double cellWidth = measureMonospaceCharWidth(widget.textStyle);
    return _scaffoldLayout(widget.cells, cellWidth, (
      MaskCell cell,
      int blankIndex,
    ) {
      switch (cell.kind) {
        case MaskCellKind.shown:
          return _ShownCell(
            char: cell.char,
            width: cellWidth,
            textStyle: widget.textStyle,
          );
        case MaskCellKind.revealed:
          return _RevealedCell(
            char: cell.char,
            width: cellWidth,
            textStyle: widget.textStyle,
            colors: colors,
          );
        case MaskCellKind.blank:
          return _BlankInputCell(
            controller: _controllers[blankIndex],
            focusNode: _nodes[blankIndex],
            width: cellWidth,
            textStyle: widget.textStyle,
            colors: colors,
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

/// A single editable blank cell (one character).
///
/// The visible glyph is a plain [Text], so it lands exactly where the revealed
/// letters do; the real [TextField] sits transparently on top only to capture
/// keystrokes (a one-character-wide field would otherwise scroll its content and
/// clip/shift the glyph). Focus is shown by the underline turning to the accent
/// colour, and gaining focus scrolls the cell into view so typing/arrowing
/// toward the edge of a long answer keeps the active cell visible.
final class _BlankInputCell extends StatefulWidget {
  const _BlankInputCell({
    required this.controller,
    required this.focusNode,
    required this.width,
    required this.textStyle,
    required this.colors,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final double width;
  final TextStyle textStyle;
  final ColorScheme colors;
  final ValueChanged<String> onChanged;

  @override
  State<_BlankInputCell> createState() => _BlankInputCellState();
}

final class _BlankInputCellState extends State<_BlankInputCell> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(_BlankInputCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChanged);
      widget.focusNode.addListener(_onFocusChanged);
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
    if (!widget.focusNode.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool focused = widget.focusNode.hasFocus;
    return SizedBox(
      width: widget.width,
      height: _kScaffoldSlotHeight,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 1,
            right: 1,
            bottom: 3,
            child: Container(
              height: focused ? 1.5 : 1,
              color: focused
                  ? widget.colors.primary
                  : _blankUnderlineColor(widget.colors),
            ),
          ),
          // The visible glyph — a plain Text, aligned like the revealed cells.
          Center(
            child: Text(
              widget.controller.text,
              maxLines: 1,
              strutStyle: _scaffoldStrut(widget.textStyle),
              style: widget.textStyle,
            ),
          ),
          // Transparent capture field on top: its text is hidden so the narrow
          // field's scroll offset can't shift the visible glyph, but the caret
          // (drawn in cursorColor, independent of the text colour) stays visible
          // to mark the typing position.
          Positioned.fill(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              textAlign: TextAlign.center,
              maxLength: 1,
              showCursor: true,
              cursorColor: widget.colors.primary,
              cursorWidth: 1.5,
              enableInteractiveSelection: false,
              style: widget.textStyle.copyWith(color: Colors.transparent),
              decoration: const InputDecoration(
                counterText: '',
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
              onChanged: widget.onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

final class _CompletionView extends StatelessWidget {
  const _CompletionView({required this.onExtend, required this.noneLeft});

  final VoidCallback onExtend;

  /// Whether the session ran out of difficult units rather than mastering
  /// them all ([noDifficultUnitsLeft]), so it must not claim the latter.
  final bool noneLeft;

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
            messages.message(
              noneLeft
                  ? LearnAnywhereMessage.learnNoDifficultUnitsLeft
                  : LearnAnywhereMessage.superQueryCompleted,
            ),
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
    required this.tooltip,
    this.warning = false,
  });

  final String label;
  final String value;

  /// What the pill counts, shown on hover.
  final String tooltip;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: warning
              ? colors.errorContainer
              : colors.surfaceContainerHighest,
          borderRadius: LearnAnywhereTokens.smallRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LearnAnywhereTokens.gapMedium,
            vertical: LearnAnywhereTokens.gapSmall,
          ),
          child: Text('$label: $value'),
        ),
      ),
    );
  }
}

/// A toggle row with a fixed-width label column so consecutive toggles (e.g.
/// "Shuffle units" and "Use all units") line their switches up regardless of
/// label length.
final class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.tooltip,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// Explanation shown on hover, plus a help icon marking it as available.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final String? tooltip = this.tooltip;
    return Padding(
      padding: const EdgeInsets.only(bottom: LearnAnywhereTokens.gapSmall),
      child: InkWell(
        // Matches SwitchListTile's tap-anywhere-in-the-row behavior, which
        // this replaces for alignment.
        onTap: () => onChanged(!value),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: LearnAnywhereZoom.scaleBox(context, 280),
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ),
            Switch(value: value, onChanged: onChanged),
            if (tooltip != null)
              Tooltip(
                message: tooltip,
                child: const Icon(Icons.help_outline, size: 18),
              ),
          ],
        ),
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
    this.tooltip,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;

  /// Explanation shown on hover, plus a help icon marking it as available.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final String? tooltip = this.tooltip;
    return Padding(
      padding: const EdgeInsets.only(bottom: LearnAnywhereTokens.gapMedium),
      child: DropdownButtonFormField<T>(
        decoration: InputDecoration(
          labelText: label,
          // The icon is the visible affordance; its own Tooltip is what
          // actually shows the explanation on hover.
          suffixIcon: tooltip == null
              ? null
              : Tooltip(
                  message: tooltip,
                  child: const Icon(Icons.help_outline, size: 18),
                ),
        ),
        initialValue: value,
        items: items,
        onChanged: (T? value) {
          if (value != null) {
            onChanged(value);
          }
        },
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
    this.emptyFallback,
    this.enabled = true,
    this.tooltip,
  });

  final String label;
  final int value;
  final int minimum;
  final int? maximum;
  final ValueChanged<int> onChanged;

  /// Explanation shown on hover, plus a help icon marking it as available.
  final String? tooltip;

  /// Value reported when the field is cleared; defaults to [minimum].
  ///
  /// Lets the unit-range fields expand to their own end of the range instead
  /// of both collapsing to 1: clearing "Start unit" means the first unit,
  /// clearing "End unit" means the last one.
  final int? emptyFallback;

  /// Whether the field accepts input. A disabled field still shows [value].
  final bool enabled;

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
    final String? tooltip = widget.tooltip;
    return Padding(
      padding: const EdgeInsets.only(bottom: LearnAnywhereTokens.gapMedium),
      child: TextField(
        controller: _controller,
        enabled: widget.enabled,
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          labelText: widget.label,
          // The icon is the visible affordance; its own Tooltip is what
          // actually shows the explanation on hover.
          suffixIcon: tooltip == null
              ? null
              : Tooltip(
                  message: tooltip,
                  child: const Icon(Icons.help_outline, size: 18),
                ),
        ),
        onChanged: (String value) {
          // An empty field means "as far as this end goes", which is not
          // necessarily the minimum — see [_NumberRow.emptyFallback].
          var parsed =
              int.tryParse(value) ?? widget.emptyFallback ?? widget.minimum;
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
    );
  }
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
        Text(widget.hint, style: LearnAnywhereTokens.keyHint(context)),
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
    required this.hint,
    required this.onPressed,
    required this.onRestoreFocus,
  });

  final String label;
  final String hint;
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
          Text(widget.hint, style: LearnAnywhereTokens.keyHint(context)),
        ],
      ),
    );
  }
}

// ─── Read aloud pill (F4, skipTraversal focus node) ───────────────────────────

/// The pill that reads the answer aloud, like `F4`.
///
/// Its focus node never takes focus, so clicking it at the top of the level
/// ladder or on the answer leaves the session's keys where they were.
final class _ReadAloudPill extends StatefulWidget {
  const _ReadAloudPill({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_ReadAloudPill> createState() => _ReadAloudPillState();
}

final class _ReadAloudPillState extends State<_ReadAloudPill> {
  final FocusNode _focusNode = FocusNode(
    skipTraversal: true,
    canRequestFocus: false,
  );

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // Tonal, like Cancel and the view switch: a secondary action, not a toggle,
  // so it must not look like an unselected rating or an unflagged Difficult.
  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      focusNode: _focusNode,
      onPressed: widget.onPressed,
      icon: const Icon(Icons.volume_up),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            LearnAnywhereLocalizations.of(
              context,
            ).message(LearnAnywhereMessage.learnReadAloud),
          ),
          Text('F4', style: LearnAnywhereTokens.keyHint(context)),
        ],
      ),
    );
  }
}

// ─── Intents ──────────────────────────────────────────────────────────────────

final class _LearnContinueIntent extends Intent {
  const _LearnContinueIntent();
}

final class _LearnRevealIntent extends Intent {
  const _LearnRevealIntent();
}

final class _LearnSpeakAnswerIntent extends Intent {
  const _LearnSpeakAnswerIntent();
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

final class _LearnToggleDifficultIntent extends Intent {
  const _LearnToggleDifficultIntent();
}
