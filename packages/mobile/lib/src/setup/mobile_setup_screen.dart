import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

import '../mobile_file_service.dart';
import '../session/mobile_session_screen.dart';
import '../statistics/mobile_statistics_screen.dart';
import '../widgets/mobile_form_rows.dart';

/// Practice-setup screen for one deck: direction, mode, shuffle, unit range,
/// and (Drill only) mastery threshold. Reached by opening a deck from the
/// library; starting pushes the session.
final class MobileSetupScreen extends StatefulWidget {
  /// Creates the mobile setup screen.
  const MobileSetupScreen({
    required this.document,
    required this.fileService,
    required this.guardSettings,
    super.key,
  });

  /// Deck opened from the library, plus its loaded statistics.
  final MobileDeckDocument document;

  /// File service used to persist statistics and reload the deck.
  final MobileFileService fileService;

  /// Guardrail settings (minimum-attempts guard, wrong-answer ceiling) from
  /// the Settings screen.
  final LearnAnywhereSettings guardSettings;

  @override
  State<MobileSetupScreen> createState() => _MobileSetupScreenState();
}

/// Session modes offered on mobile setup. Level Learning is desktop-only.
const List<SessionMode> _kMobileModes = <SessionMode>[
  SessionMode.superQuery,
  SessionMode.practice,
  SessionMode.onceThrough,
];

final class _MobileSetupScreenState extends State<MobileSetupScreen> {
  late MobileDeckDocument _document;
  DirectionSelection _direction = DirectionSelection.both;
  SessionMode _mode = SessionMode.practice;
  bool _shuffle = false;
  late int _startUnit;
  late int _endUnit;
  // Matches SessionParameters.masteryThreshold's own default (0.4).
  int _thresholdPercent = 40;

  int get _maxUnit =>
      _document.deck.units.length < 1 ? 1 : _document.deck.units.length;

  @override
  void initState() {
    super.initState();
    _document = widget.document;
    _startUnit = 1;
    _endUnit = _maxUnit;
  }

  Future<void> _reload() async {
    final String? path = _document.deckPath;
    if (path == null) {
      return;
    }
    final MobileDeckDocument reloaded = await widget.fileService.openDeck(
      path,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _document = reloaded;
      _startUnit = _startUnit.clamp(1, _maxUnit).toInt();
      _endUnit = _endUnit.clamp(_startUnit, _maxUnit).toInt();
    });
  }

  Future<void> _openStatistics() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => MobileStatisticsScreen(
          document: _document,
          fileService: widget.fileService,
        ),
      ),
    );
    await _reload();
  }

  Future<void> _startSession() async {
    final int start = _startUnit.clamp(1, _maxUnit).toInt();
    final int end = _endUnit.clamp(start, _maxUnit).toInt();
    final SessionParameters parameters = SessionParameters(
      directionSelection: _direction,
      startIndex: start,
      endIndex: end,
      withInput: false,
      mode: _mode,
      shuffle: _shuffle,
      masteryThreshold: _thresholdPercent / 100,
      minimumAttemptsGuardEnabled:
          widget.guardSettings.minimumAttemptsGuardEnabled,
      minAttempts: widget.guardSettings.minAttempts,
    );
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => MobileSessionScreen(
          document: _document,
          parameters: parameters,
          wrongAnswerCeiling: WrongAnswerCeiling(
            enabled: widget.guardSettings.wrongAnswerCeilingEnabled,
            value: widget.guardSettings.wrongAnswerCeiling,
          ),
          fileService: widget.fileService,
        ),
      ),
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final bool isDrill = _mode == SessionMode.superQuery;
    return Scaffold(
      appBar: AppBar(
        title: Text(_document.deck.mask.name),
        actions: <Widget>[
          IconButton(
            tooltip: messages.message(LearnAnywhereMessage.statisticsTitle),
            onPressed: _openStatistics,
            icon: const Icon(Icons.bar_chart_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
          children: <Widget>[
            Text(
              messages.message(LearnAnywhereMessage.learnSetupTitle),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: LearnAnywhereTokens.gapMedium),
            MobileDropdownRow<DirectionSelection>(
              label: messages.message(LearnAnywhereMessage.learnDirection),
              value: _direction,
              items: <DropdownMenuItem<DirectionSelection>>[
                DropdownMenuItem<DirectionSelection>(
                  value: DirectionSelection.direction1,
                  child: Text(_document.deck.mask.direction1Label),
                ),
                DropdownMenuItem<DirectionSelection>(
                  value: DirectionSelection.direction2,
                  child: Text(_document.deck.mask.direction2Label),
                ),
                DropdownMenuItem<DirectionSelection>(
                  value: DirectionSelection.both,
                  child: Text(
                    messages.message(LearnAnywhereMessage.learnBothDirections),
                  ),
                ),
              ],
              onChanged: (DirectionSelection value) {
                setState(() => _direction = value);
              },
            ),
            MobileDropdownRow<SessionMode>(
              label: messages.message(LearnAnywhereMessage.learnMode),
              value: _mode,
              items: <DropdownMenuItem<SessionMode>>[
                for (final SessionMode mode in _kMobileModes)
                  DropdownMenuItem<SessionMode>(
                    value: mode,
                    child: Text(messages.message(_modeLabel(mode))),
                  ),
              ],
              onChanged: (SessionMode value) {
                setState(() => _mode = value);
              },
            ),
            if (isDrill)
              MobileNumberRow(
                label: messages.message(
                  LearnAnywhereMessage.learnMasteryThreshold,
                ),
                value: _thresholdPercent,
                minimum: 1,
                maximum: 100,
                onChanged: (int value) {
                  setState(() => _thresholdPercent = value);
                },
              ),
            MobileToggleRow(
              label: messages.message(LearnAnywhereMessage.learnShuffleUnits),
              value: _shuffle,
              onChanged: (bool value) {
                setState(() => _shuffle = value);
              },
            ),
            const SizedBox(height: LearnAnywhereTokens.gapSmall),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: MobileNumberRow(
                    label: messages.message(
                      LearnAnywhereMessage.learnRangeStart,
                    ),
                    value: _startUnit,
                    minimum: 1,
                    maximum: _maxUnit,
                    onChanged: (int value) {
                      setState(() {
                        _startUnit = value;
                        if (_endUnit < _startUnit) {
                          _endUnit = _startUnit;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: LearnAnywhereTokens.gapMedium),
                Expanded(
                  child: MobileNumberRow(
                    label: messages.message(
                      LearnAnywhereMessage.learnRangeEnd,
                    ),
                    value: _endUnit,
                    minimum: _startUnit,
                    maximum: _maxUnit,
                    onChanged: (int value) {
                      setState(() => _endUnit = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: LearnAnywhereTokens.gapLarge),
            FilledButton.icon(
              onPressed: _document.deck.units.isEmpty ? null : _startSession,
              icon: const Icon(Icons.play_arrow),
              label: Text(
                messages.message(LearnAnywhereMessage.learnStartSession),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

LearnAnywhereMessage _modeLabel(SessionMode mode) {
  return switch (mode) {
    SessionMode.superQuery => LearnAnywhereMessage.learnModeSuperQuery,
    SessionMode.practice => LearnAnywhereMessage.learnModePractice,
    SessionMode.onceThrough => LearnAnywhereMessage.learnModeOnceThrough,
    SessionMode.levelLearning => LearnAnywhereMessage.learnModeSuperQuery,
  };
}
