import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

/// Options ▸ Speech: the voice each language is read in on THIS machine, and
/// how fast everything is read.
///
/// One row per language — the ones the open deck declares, plus any already
/// configured — offering that language's installed voices and a button that
/// speaks a sample so one can be heard before it is chosen. A language the
/// machine has no voice for says so instead of offering an empty list.
///
/// Nothing here is written into a deck: which of a machine's French voices
/// speaks French is a property of the machine. The screen decides none of
/// that itself — [speechLanguagesFor] and [voicesForSpeechLanguage] in core
/// do, so the list offered here is exactly the list a session resolves from.
final class SpeechSettingsPage extends StatefulWidget {
  /// Creates the Speech screen.
  const SpeechSettingsPage({
    required this.engine,
    required this.settings,
    required this.onChanged,
    this.deck,
    this.onClose,
    super.key,
  });

  /// The host's speech, injected by the shell exactly as a session gets it.
  ///
  /// This screen is only ever opened on a host whose engine is available: the
  /// menu entry that reaches it is not built otherwise.
  final TtsEngine engine;

  /// The deck open right now, or null when none is.
  final LearningDeck? deck;

  /// The machine's current speech settings.
  final SpeechSettings settings;

  /// Called with the settings after every change, for the shell to persist.
  final ValueChanged<SpeechSettings> onChanged;

  /// Called when the user closes this page.
  final VoidCallback? onClose;

  @override
  State<SpeechSettingsPage> createState() => _SpeechSettingsPageState();
}

final class _SpeechSettingsPageState extends State<SpeechSettingsPage> {
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
    // Leaving the screen mid-sample must not talk over the next one.
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
        // The sample belongs to no field; the row it came from is its language.
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
    final Widget page = Material(
      color: Theme.of(context).colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
        children: <Widget>[
          Text(
            messages.message(LearnAnywhereMessage.speechSettingsTitle),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: LearnAnywhereTokens.gapSmall),
          Text(
            messages.message(LearnAnywhereMessage.speechSettingsIntro),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: LearnAnywhereTokens.gapLarge),
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
              _LanguageRow(
                key: Key('speechRow-$language'),
                language: language,
                voices: voicesForSpeechLanguage(language, _voices),
                chosen: widget.settings.voiceFor(language),
                onChosen: (VoiceChoice? choice) {
                  widget.onChanged(widget.settings.withVoice(language, choice));
                },
                onTest: () => _test(language),
              ),
          if (widget.onClose != null) ...<Widget>[
            const SizedBox(height: LearnAnywhereTokens.gapLarge),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: widget.onClose,
                child: Text(
                  messages.message(LearnAnywhereMessage.actionClose),
                ),
              ),
            ),
          ],
        ],
      ),
    );
    final VoidCallback? close = widget.onClose;
    if (close == null) {
      return page;
    }
    // Enter closes, as it does on the other options screen; Esc is handled
    // globally in main.dart.
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): _CloseIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _CloseIntent: CallbackAction<_CloseIntent>(
            onInvoke: (_) {
              close();
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: page),
      ),
    );
  }
}

final class _CloseIntent extends Intent {
  const _CloseIntent();
}

/// The speech rate, as a share of each voice's own normal speed.
///
/// One control for every utterance the program makes, which for a language
/// barely known is the single most useful thing on this screen.
///
/// Stateful for one reason: the slider reports every pointer move, and each
/// report the parent hears is a settings file written. It follows the drag on
/// screen and reports the result once, when the drag ends.
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

  /// The offered range in steps of five percent of normal speed: fine enough
  /// to find a comfortable speed, coarse enough that the value can be read
  /// back and recognised.
  static int get _divisions =>
      (((kMaxSpeechRate - kMinSpeechRate) * 100) / 5).round();

  /// [value] rounded to the two decimals a division can land on, so what is
  /// stored is what the label said.
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
        const SizedBox(height: LearnAnywhereTokens.gapSmall),
        // Wrapped, not a Row: at 200 % zoom in the window the program opens
        // at, the scaled slider and its reading no longer fit side by side.
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: LearnAnywhereTokens.gapMedium,
          runSpacing: LearnAnywhereTokens.gapSmall,
          children: <Widget>[
            SizedBox(
              width: LearnAnywhereZoom.scaleBox(context, 320),
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
        const SizedBox(height: LearnAnywhereTokens.gapSmall),
        Text(
          messages.message(LearnAnywhereMessage.speechRateHint),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// One language: its installed voices, or a plain statement that it has none.
final class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
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
    // shows as Automatic — which is exactly what the session would do with it.
    final VoiceChoice? selectable = voices.any(
          (SpeechVoice voice) =>
              chosen != null &&
              chosen!.engine == kSystemSpeechEngineId &&
              voice.id == chosen!.voiceId,
        )
        ? chosen
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: LearnAnywhereTokens.gapMedium),
      // Wrapped, not a Row: every part of a row is sized from the zoom level,
      // so at the top of the range they stack instead of running off the edge.
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: LearnAnywhereTokens.gapMedium,
        runSpacing: LearnAnywhereTokens.gapSmall,
        children: <Widget>[
          SizedBox(
            width: LearnAnywhereZoom.scaleBox(context, 200),
            child: Text(
              _languageLabel(language),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          if (voices.isEmpty)
            SizedBox(
              width: LearnAnywhereZoom.scaleBox(context, 420),
              child: Text(
                messages
                    .message(LearnAnywhereMessage.speechNoVoiceInstalled)
                    .replaceAll('{language}', language),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else ...<Widget>[
            SizedBox(
              width: LearnAnywhereZoom.scaleBox(context, 320),
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
              tooltip: messages.message(LearnAnywhereMessage.speechTestVoice),
              onPressed: onTest,
            ),
          ],
        ],
      ),
    );
  }

  /// The language as the mask editor names it, falling back to the bare tag
  /// for one typed by hand.
  String _languageLabel(String tag) {
    for (final SpokenLanguageOption option in spokenLanguageCatalog) {
      if (option.tag == tag) {
        return '${option.label} ($tag)';
      }
    }
    return tag;
  }
}
