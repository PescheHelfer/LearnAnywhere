import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:learn_anywhere_core/core.dart';

/// Speaks through the voices the operating system already has.
///
/// The one concrete engine both shells use, kept here rather than in a shell
/// so Windows and Android speak through exactly the same code. It is a thin
/// adapter and nothing more: what to say, in which language and in which
/// voice, was already decided by the pure policy in core.
///
/// It is never constructed on a host the plugin has no implementation for —
/// the shell selects [UnavailableTtsEngine] there instead.
final class FlutterTtsEngine implements TtsEngine {
  /// Creates an engine over [tts], or over a fresh `FlutterTts`.
  FlutterTtsEngine({FlutterTts? tts}) : _tts = tts ?? FlutterTts() {
    // The host tells us when a word is over, and [speak] does not return
    // before then. That is what lets a caller reading two answer fields say
    // them in order: without it the second would cut off the first, and only
    // the last field of a multi-field answer would ever be heard.
    _tts.setCompletionHandler(_hostFinished);
    _tts.setCancelHandler(_hostFinished);
    _tts.setErrorHandler((dynamic _) => _hostFinished());
  }

  /// How long an utterance may run before it is given up on.
  ///
  /// Purely insurance: a host that never reports a completion would otherwise
  /// leave the rest of a multi-field answer unsaid until something else stops
  /// speech. Longer than any single field read at the slowest rate.
  static const Duration _utteranceLimit = Duration(seconds: 60);

  /// What the plugin answers when it has taken an utterance on. Anything else
  /// is a refusal, and no completion will ever be reported for it.
  static const Object _accepted = 1;

  final FlutterTts _tts;

  /// The utterance the host is speaking, or null when it is saying nothing.
  ///
  /// One at a time by construction: a new request replaces this one, and the
  /// replaced request gives up rather than speaking over its successor.
  _SpokenRequest? _current;

  /// The host reporting that what it was saying is over, one way or another.
  void _hostFinished() {
    final _SpokenRequest? request = _current;
    // Only ever the utterance actually handed to the host: a cancel report
    // arriving while the NEXT request is still being set up belongs to the one
    // being replaced, and must not end the new one before it has begun.
    if (request != null && request.issued) {
      _current = null;
      request.finish();
    }
  }

  @override
  bool get isAvailable => true;

  @override
  Future<List<SpeechVoice>> voices() async {
    final Object? reported = await _ask(() => _tts.getVoices);
    if (reported is! List) {
      return const <SpeechVoice>[];
    }
    final List<SpeechVoice> voices = <SpeechVoice>[];
    for (final Object? entry in reported) {
      // Every host reports a voice as a map of `name` and `locale`; anything
      // else is skipped rather than failing the whole list.
      if (entry is! Map) continue;
      final Object? name = entry['name'];
      final Object? locale = entry['locale'];
      if (name is! String || locale is! String) continue;
      if (name.isEmpty || locale.isEmpty) continue;
      // The name is what `setVoice` takes back, so it is also the identifier.
      voices.add(SpeechVoice(id: name, name: name, language: locale));
    }
    return voices;
  }

  @override
  Future<void> speak(SpeechUtterance utterance) async {
    final SpeechVoice? voice = utterance.voice;
    if (voice == null || utterance.text.isEmpty) {
      return;
    }
    // Claimed before the first await, so a request arriving while this one is
    // still being set up wins and this one gives up. Whoever was waiting on
    // the utterance being replaced stops waiting here.
    final _SpokenRequest request = _SpokenRequest();
    _current?.finish();
    _current = request;
    final Object? accepted = await _ask(() async {
      // Cut off whatever is still being said: two words on top of each other
      // are worth less than either of them alone.
      await _tts.stop();
      await _tts.setSpeechRate(pluginSpeechRate(utterance.rate));
      // The language is set as well as the voice because a host that ignores
      // one of the two still gets told which language this is.
      await _tts.setLanguage(voice.language);
      await _tts.setVoice(<String, String>{
        'name': voice.id,
        'locale': voice.language,
      });
      // Handed over here, and marked as handed over here: the stop above has
      // already been answered, so every report that follows is about this
      // utterance and not about the one it replaced.
      request.issued = true;
      return await _tts.speak(utterance.text);
    });
    if (!identical(_current, request)) {
      // Replaced while the host was being set up. The utterance that replaced
      // it owns the voice now, and stopped this one on its way in.
      return;
    }
    if (accepted != _accepted) {
      // The host refused it, so no completion will ever arrive. Waiting for
      // one would only stall whatever comes next.
      _current = null;
      return;
    }
    try {
      await request.done.timeout(_utteranceLimit);
    } on TimeoutException {
      // A host that reported no completion. Nothing is broken and nothing is
      // said about it; the next utterance simply goes ahead.
    } finally {
      if (identical(_current, request)) {
        _current = null;
      }
    }
  }

  @override
  Future<void> stop() async {
    final _SpokenRequest? request = _current;
    _current = null;
    await _ask(() => _tts.stop());
    // Not left to the host's own cancel report: a host that sends none would
    // leave a caller waiting on a word that is no longer being said.
    request?.finish();
  }

  /// Translates an app speech rate into the number the plugin takes.
  ///
  /// The plugin's scale is `0.0..1.0` with **0.5 as the voice's normal speed**
  /// on both platforms that can speak here: its Android side multiplies by two
  /// before reaching a `TextToSpeech` whose normal is `1.0`, and its two
  /// Windows backends both offset by `0.5` before reaching an engine whose
  /// normal is the zero point. So halving the app rate lands on it.
  ///
  /// It is a direction rather than an exact factor: the Windows backends apply
  /// the remainder on their own curves, so "half speed" is slower and not
  /// necessarily half. The learner sets this by ear, which is the only way it
  /// could be set anyway.
  static double pluginSpeechRate(double rate) =>
      (clampSpeechRate(rate) / 2).clamp(0.0, 1.0);

  /// Runs [request] against the host, treating a refusal as silence.
  ///
  /// Speech is presentation and nothing else: a host that has no speech
  /// channel at all, or one that fails mid-word, must leave the learner in a
  /// working session rather than taking it down. The worst case is that
  /// nothing is said, which the guide already explains.
  Future<Object?> _ask(Future<Object?> Function() request) async {
    try {
      return await request();
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

/// One utterance handed to the host, and the wait for it to be over.
///
/// [issued] separates a request the host has actually been asked to speak from
/// one still being set up, which is what tells a completion report from the
/// previous utterance apart from one belonging to this one.
final class _SpokenRequest {
  final Completer<void> _done = Completer<void>();

  /// Whether the host has been handed this utterance yet.
  bool issued = false;

  /// Completes when the utterance is over, cancelled or refused.
  Future<void> get done => _done.future;

  /// Ends the wait, once.
  void finish() {
    if (!_done.isCompleted) {
      _done.complete();
    }
  }
}
