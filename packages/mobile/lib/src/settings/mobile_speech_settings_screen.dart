import 'dart:async';

import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

/// The mobile companion's Speech screen: the voice each language is read in
/// on THIS phone, how fast everything is read, and whether the answer reads
/// itself out.
///
/// Mirrors the desktop Speech screen exactly in what it stores — the same
/// [SpeechSettings] shape, so a phone and a desktop reading the same settings
/// file agree about what they mean — but is laid out as one column of full-
/// width rows rather than desktop's zoom-aware wrapping rows, since a phone
/// has no zoom level to design around.
///
/// [deck] is the deck open right now, when this screen is reached from
/// practice setup; it is null when reached from Settings with no deck open,
/// in which case only already-configured languages are offered — exactly
/// [speechLanguagesFor]'s own rule, shared with the desktop.
final class MobileSpeechSettingsScreen extends StatefulWidget {
  /// Creates the mobile Speech screen.
  const MobileSpeechSettingsScreen({
    required this.engine,
    required this.settings,
    required this.onChanged,
    this.deck,
    super.key,
  });

  /// The host's speech, injected by the shell exactly as a session gets it.
  ///
  /// This screen is only ever opened on a host whose engine is available:
  /// the entries that reach it are not built otherwise.
  final TtsEngine engine;

  /// The deck open right now, or null when none is.
  final LearningDeck? deck;

  /// The machine's current speech settings.
  final SpeechSettings settings;

  /// Called with the settings after every change, for the shell to persist.
  final ValueChanged<SpeechSettings> onChanged;

  @override
  State<MobileSpeechSettingsScreen> createState() =>
      _MobileSpeechSettingsScreenState();
}

final class _MobileSpeechSettingsScreenState
    extends State<MobileSpeechSettingsScreen> {
  /// The voices the host reported, read once. Empty until they arrive.
  List<SpeechVoice> _voices = const <SpeechVoice>[];

  @override
  void initState() {
    super.initState();
    unawaited(_loadVoices());
  }

  Future<void> _loadVoices() async {
    final List<SpeechVoice> voices = await widget.engine.voices();
    if (!mounted) {
      return;
    }
    setState(() => _voices = voices);
  }

  @override
  void dispose() {
    // Leaving the screen mid-sample must not talk over the next thing said.
    unawaited(widget.engine.stop());
    super.dispose();
  }

  /// Speaks the sample phrase for [language] in the voice this row resolves
  /// to, at the rate now set.
  Future<void> _test(String language) async {
    final SpeechVoice? voice = resolveSpeechVoice(
      language,
      _voices,
      settings: widget.settings,
    );
    if (voice == null) {
      return;
    }
    await widget.engine.speak(
      SpeechUtterance(
        // The sample belongs to no field; the row it came from is its
        // language.
        fieldId: -1,
        text: speechSampleFor(language),
        language: language,
        voice: voice,
        rate: widget.settings.rate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final List<String> languages = speechLanguagesFor(
      deck: widget.deck,
      settings: widget.settings,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(messages.message(LearnAnywhereMessage.speechSettingsTitle)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
          children: <Widget>[
            Text(
              messages.message(LearnAnywhereMessage.speechSettingsIntro),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: LearnAnywhereTokens.gapLarge),
            SwitchListTile(
              key: const Key('speechAutomatic'),
              contentPadding: EdgeInsets.zero,
              title: Text(
                messages.message(LearnAnywhereMessage.speechAutomaticLabel),
              ),
              subtitle: Text(
                messages.message(
                  LearnAnywhereMessage.speechAutomaticHintMobile,
                ),
              ),
              value: widget.settings.automatic,
              onChanged: (bool value) {
                widget.onChanged(widget.settings.copyWith(automatic: value));
              },
            ),
            const SizedBox(height: LearnAnywhereTokens.gapMedium),
            _RateControl(
              rate: widget.settings.rate,
              onChanged: (double value) {
                widget.onChanged(widget.settings.copyWith(rate: value));
              },
            ),
            const SizedBox(height: LearnAnywhereTokens.gapLarge),
            if (languages.isEmpty)
              Text(
                messages.message(LearnAnywhereMessage.speechNoLanguages),
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              for (final String language in languages)
                _LanguageCard(
                  key: Key('speechRow-$language'),
                  language: language,
                  voices: voicesForSpeechLanguage(language, _voices),
                  chosen: widget.settings.voiceFor(language),
                  onChosen: (VoiceChoice? choice) {
                    widget.onChanged(
                      widget.settings.withVoice(language, choice),
                    );
                  },
                  onTest: () => _test(language),
                ),
          ],
        ),
      ),
    );
  }
}

/// The speech rate, as a share of each voice's own normal speed.
///
/// Stateful for one reason: the slider reports every pointer move, and each
/// report the parent hears is a settings file written. It follows the drag on
/// screen and reports the result once, when the drag ends — same rule as the
/// desktop's own rate control.
final class _RateControl extends StatefulWidget {
  const _RateControl({required this.rate, required this.onChanged});

  final double rate;
  final ValueChanged<double> onChanged;

  @override
  State<_RateControl> createState() => _RateControlState();
}

final class _RateControlState extends State<_RateControl> {
  /// The rate under the finger, or null when nothing is being dragged.
  double? _dragging;

  double get _shown => _dragging ?? clampSpeechRate(widget.rate);

  static int get _divisions =>
      (((kMaxSpeechRate - kMinSpeechRate) * 100) / 5).round();

  static double _stepped(double value) =>
      double.parse(value.toStringAsFixed(2));

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final int percent = (_shown * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          messages.message(LearnAnywhereMessage.speechRateLabel),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: Slider(
                key: const Key('speechRate'),
                value: _shown,
                min: kMinSpeechRate,
                max: kMaxSpeechRate,
                divisions: _divisions,
                label: '$percent%',
                onChanged: (double value) {
                  setState(() => _dragging = _stepped(value));
                },
                onChangeEnd: (double value) {
                  setState(() => _dragging = null);
                  widget.onChanged(_stepped(value));
                },
              ),
            ),
            Text(
              messages
                  .message(LearnAnywhereMessage.speechRateValue)
                  .replaceAll('{percent}', '$percent'),
            ),
          ],
        ),
        Text(
          messages.message(LearnAnywhereMessage.speechRateHint),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// One language: its installed voices, or a plain statement that it has none.
final class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.language,
    required this.voices,
    required this.chosen,
    required this.onChosen,
    required this.onTest,
    super.key,
  });

  final String language;
  final List<SpeechVoice> voices;
  final VoiceChoice? chosen;
  final ValueChanged<VoiceChoice?> onChosen;
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    // A stored choice for another engine, or for a voice since uninstalled,
    // shows as Automatic — which is exactly what a session would do with it.
    final VoiceChoice? selectable = selectableVoiceChoice(chosen, voices);
    return Card(
      margin: const EdgeInsets.only(bottom: LearnAnywhereTokens.gapMedium),
      child: Padding(
        padding: const EdgeInsets.all(LearnAnywhereTokens.gapMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              spokenLanguageLabel(language),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: LearnAnywhereTokens.gapSmall),
            if (voices.isEmpty)
              Text(
                messages
                    .message(LearnAnywhereMessage.speechNoVoiceInstalled)
                    .replaceAll('{language}', language),
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Row(
                children: <Widget>[
                  Expanded(
                    child: DropdownButtonFormField<VoiceChoice?>(
                      key: Key('speechVoice-$language'),
                      initialValue: selectable,
                      isExpanded: true,
                      decoration: InputDecoration(
                        isDense: true,
                        border: const OutlineInputBorder(),
                        labelText: messages.message(
                          LearnAnywhereMessage.speechVoiceColumn,
                        ),
                      ),
                      items: <DropdownMenuItem<VoiceChoice?>>[
                        DropdownMenuItem<VoiceChoice?>(
                          child: Text(
                            messages.message(
                              LearnAnywhereMessage.speechVoiceAutomatic,
                            ),
                          ),
                        ),
                        for (final SpeechVoice voice in voices)
                          DropdownMenuItem<VoiceChoice?>(
                            value: VoiceChoice(
                              engine: kSystemSpeechEngineId,
                              voiceId: voice.id,
                            ),
                            child: Text(
                              voice.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: onChosen,
                    ),
                  ),
                  SpeakerButton(
                    key: Key('speechTest-$language'),
                    tooltip: messages.message(
                      LearnAnywhereMessage.speechTestVoice,
                    ),
                    onPressed: onTest,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

}
