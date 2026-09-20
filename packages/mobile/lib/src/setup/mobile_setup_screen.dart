import 'dart:async';

import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

import '../mobile_app_scope.dart';
import '../mobile_file_service.dart';
import '../session/mobile_session_screen.dart';
import '../settings/mobile_speech_settings_screen.dart';
import '../statistics/mobile_statistics_screen.dart';
import '../widgets/mobile_form_rows.dart';

/// Practice-setup screen for one deck: direction, mode, shuffle, unit range,
/// and (Drill only) mastery threshold. Reached by opening a deck from the
/// library; starting pushes the session.
///
/// Mode, direction, shuffle and the mastery threshold are read from and
/// written straight back to the persisted [LearnAnywhereSettings] through
/// [MobileAppScope], so each choice survives leaving the screen and restarting
/// the app — the same options desktop remembers, in the same file. They are
/// deliberately NOT mirrored into local state: a second copy could drift from
/// the stored one, and the scope already rebuilds this screen on every change.
///
/// The unit range is the exception and stays local, matching the rule
/// [LearnAnywhereSettings] documents for itself — start and end are per-deck
/// and reset when a deck is opened, because a range that fits one deck is
/// meaningless for the next.
final class MobileSetupScreen extends StatefulWidget {
  /// Creates the mobile setup screen.
  const MobileSetupScreen({
    required this.document,
    required this.fileService,
    required this.speechEngine,
    super.key,
  });

  /// Deck opened from the library, plus its loaded statistics.
  final MobileDeckDocument document;

  /// File service used to persist statistics, settings, and reload the deck.
  final MobileFileService fileService;

  /// The host's speech, threaded to the session and to the Speech screen,
  /// where this deck's own languages populate the language list.
  final TtsEngine speechEngine;

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
  late int _startUnit;
  late int _endUnit;

  int get _maxUnit =>
      _document.deck.units.length < 1 ? 1 : _document.deck.units.length;

  /// The persisted settings, read live so a change made here (or in Settings)
  /// is visible immediately.
  LearnAnywhereSettings get _settings => MobileAppScope.of(context).settings;

  /// Mastery threshold as the whole percent the Drill row edits.
  int get _thresholdPercent => (_settings.masteryThreshold * 100).round();

  /// Writes [next] to the settings file and publishes it to the app scope.
  ///
  /// Saved on every change rather than on "Start session", so a choice made
  /// and then backed out of is still remembered — and so the file survives the
  /// process being killed, which on Android can happen the moment the app
  /// leaves the foreground.
  void _apply(LearnAnywhereSettings next) {
    unawaited(widget.fileService.saveSettings(next));
    MobileAppScope.of(context).onSettingsChanged(next);
  }

  @override
  void initState() {
    super.initState();
    _document = widget.document;
    _startUnit = 1;
    _endUnit = _maxUnit;
  }

  Future<void> _reload() async {
    final MobileDeckDocument reloaded = await widget.fileService.openDeck(
      _document.deckPath,
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

  /// Opens the Speech screen with THIS deck's languages available to
  /// configure a voice for, in addition to the ones already configured —
  /// reached from Settings too, where no deck is open yet.
  Future<void> _openSpeechSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => MobileSpeechSettingsScreen(
          engine: widget.speechEngine,
          deck: _document.deck,
          settings: _settings.speech,
          onChanged: (SpeechSettings next) {
            _apply(_settings.copyWith(speech: next));
          },
        ),
      ),
    );
  }

  Future<void> _startSession() async {
    final int start = _startUnit.clamp(1, _maxUnit).toInt();
    final int end = _endUnit.clamp(start, _maxUnit).toInt();
    final LearnAnywhereSettings settings = _settings;
    final SessionParameters parameters = SessionParameters(
      directionSelection: settings.direction,
      startIndex: start,
      endIndex: end,
      withInput: false,
      mode: settings.mode,
      shuffle: settings.shuffle,
      masteryThreshold: settings.masteryThreshold,
      minimumAttemptsGuardEnabled: settings.minimumAttemptsGuardEnabled,
      minAttempts: settings.minAttempts,
    );
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => MobileSessionScreen(
          document: _document,
          parameters: parameters,
          wrongAnswerCeiling: WrongAnswerCeiling(
            enabled: settings.wrongAnswerCeilingEnabled,
            value: settings.wrongAnswerCeiling,
          ),
          fileService: widget.fileService,
          speechEngine: widget.speechEngine,
          speechSettings: settings.speech,
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
    final LearnAnywhereSettings settings = _settings;
    final bool isDrill = settings.mode == SessionMode.superQuery;
    return Scaffold(
      appBar: AppBar(
        title: Text(_document.deckTitle),
        actions: <Widget>[
          // On a host with no engine, this entry does not appear at all —
          // mirroring the desktop, where the Speech screen is unreachable
          // rather than present and empty.
          if (widget.speechEngine.isAvailable)
            IconButton(
              tooltip: messages.message(LearnAnywhereMessage.speechSettingsTitle),
              onPressed: _openSpeechSettings,
              icon: const Icon(Icons.record_voice_over_outlined),
            ),
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
              value: settings.direction,
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
                _apply(settings.copyWith(direction: value));
              },
            ),
            MobileDropdownRow<SessionMode>(
              label: messages.message(LearnAnywhereMessage.learnMode),
              value: settings.mode,
              items: <DropdownMenuItem<SessionMode>>[
                for (final SessionMode mode in _kMobileModes)
                  DropdownMenuItem<SessionMode>(
                    value: mode,
                    child: Text(messages.message(_modeLabel(mode))),
                  ),
              ],
              onChanged: (SessionMode value) {
                _apply(settings.copyWith(mode: value));
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
                  _apply(settings.copyWith(masteryThreshold: value / 100));
                },
              ),
            MobileToggleRow(
              label: messages.message(LearnAnywhereMessage.learnShuffleUnits),
              value: settings.shuffle,
              onChanged: (bool value) {
                _apply(settings.copyWith(shuffle: value));
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
