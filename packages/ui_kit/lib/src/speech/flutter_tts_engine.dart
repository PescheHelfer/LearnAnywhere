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
  FlutterTtsEngine({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;

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
    await _ask(() async {
      // Cut off whatever is still being said: two words on top of each other
      // are worth less than either of them alone.
      await _tts.stop();
      // The language is set as well as the voice because a host that ignores
      // one of the two still gets told which language this is.
      await _tts.setLanguage(voice.language);
      await _tts.setVoice(<String, String>{
        'name': voice.id,
        'locale': voice.language,
      });
      return await _tts.speak(utterance.text);
    });
  }

  @override
  Future<void> stop() async {
    await _ask(() => _tts.stop());
  }

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
