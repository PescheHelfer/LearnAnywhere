/// The speech choices that belong to a MACHINE: which of its voices speaks
/// each language, and how fast.
///
/// None of this is ever written into a deck. The deck says a field is French;
/// each machine decides which of its French voices says it, so a deck copied
/// to another computer carries nothing meaningless with it.
///
/// Pure Dart, no I/O: the same model serves both shells.
library;

import 'spoken_language.dart';

/// The engine that speaks through the operating system's own installed
/// voices — the one engine that ships today.
///
/// Stored beside every voice choice, and checked before one is honoured,
/// because the planned successor names its voices by model file rather than
/// by installed voice name. A choice made for one engine means nothing to the
/// other, and this is what lets the second engine arrive without reshaping a
/// single stored key.
const String kSystemSpeechEngineId = 'system';

/// Slowest speech the rate control offers, as a share of normal speed.
const double kMinSpeechRate = 0.5;

/// Fastest speech the rate control offers, as a share of normal speed.
const double kMaxSpeechRate = 1.5;

/// The voice's own normal speed, and the default.
const double kDefaultSpeechRate = 1.0;

/// Returns [rate] brought inside the offered range.
double clampSpeechRate(double rate) {
  if (rate.isNaN) {
    return kDefaultSpeechRate;
  }
  return rate.clamp(kMinSpeechRate, kMaxSpeechRate);
}

/// One stored voice choice: an engine, and a voice within that engine.
///
/// Never a bare operating-system voice name. `Microsoft Hortense` identifies a
/// voice only to the engine that speaks through Windows' own voices; the same
/// string means nothing to an engine carrying its own models. Recording which
/// engine named it is what keeps a stored choice interpretable after the
/// engine changes.
final class VoiceChoice {
  /// Creates a voice choice.
  const VoiceChoice({required this.engine, required this.voiceId});

  /// The engine that named [voiceId] — [kSystemSpeechEngineId] today.
  final String engine;

  /// The voice, as that engine identifies it (`SpeechVoice.id`).
  final String voiceId;

  @override
  bool operator ==(Object other) =>
      other is VoiceChoice && other.engine == engine && other.voiceId == voiceId;

  @override
  int get hashCode => Object.hash(engine, voiceId);

  @override
  String toString() => 'VoiceChoice($engine, $voiceId)';
}

/// The machine's speech settings: the rate, and a voice per language.
final class SpeechSettings {
  /// Creates speech settings.
  ///
  /// [voices] is keyed by canonical spoken-language tag; use [withVoice] to
  /// build one, which canonicalises the key for you.
  const SpeechSettings({
    this.automatic = false,
    this.rate = kDefaultSpeechRate,
    this.voices = const <String, VoiceChoice>{},
  });

  /// Whether the answer is read aloud the moment it is revealed.
  ///
  /// Off by default, and the one switch that makes the program speak without
  /// being asked: with it off nothing is ever said unless the learner clicks
  /// an icon or presses the replay key.
  final bool automatic;

  /// Speech speed as a share of the voice's own normal speed, between
  /// [kMinSpeechRate] and [kMaxSpeechRate].
  final double rate;

  /// The chosen voice per language, keyed by canonical spoken-language tag.
  ///
  /// A language with no entry is spoken by whichever installed voice the
  /// policy resolves on its own, so an empty map is a complete setting and not
  /// an unconfigured one.
  final Map<String, VoiceChoice> voices;

  /// The choice stored for [language], however the caller spells the tag.
  VoiceChoice? voiceFor(String language) =>
      voices[canonicalSpokenLanguageTag(language)];

  /// Returns a copy with [language] set to [choice], or cleared when null.
  SpeechSettings withVoice(String language, VoiceChoice? choice) {
    final String tag = canonicalSpokenLanguageTag(language);
    final Map<String, VoiceChoice> next = Map<String, VoiceChoice>.of(voices);
    if (choice == null) {
      next.remove(tag);
    } else {
      next[tag] = choice;
    }
    return SpeechSettings(
      automatic: automatic,
      rate: rate,
      voices: Map<String, VoiceChoice>.unmodifiable(next),
    );
  }

  /// Returns a copy with selected fields changed.
  SpeechSettings copyWith({
    bool? automatic,
    double? rate,
    Map<String, VoiceChoice>? voices,
  }) {
    return SpeechSettings(
      automatic: automatic ?? this.automatic,
      rate: rate ?? this.rate,
      voices: voices ?? this.voices,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! SpeechSettings ||
        other.automatic != automatic ||
        other.rate != rate) {
      return false;
    }
    if (other.voices.length != voices.length) {
      return false;
    }
    for (final MapEntry<String, VoiceChoice> entry in voices.entries) {
      if (other.voices[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    automatic,
    rate,
    Object.hashAllUnordered(<Object>[
      for (final MapEntry<String, VoiceChoice> entry in voices.entries)
        Object.hash(entry.key, entry.value),
    ]),
  );
}

/// Encodes [settings] as the settings file's `speech` object.
Map<String, Object?> encodeSpeechSettings(SpeechSettings settings) {
  return <String, Object?>{
    'automatic': settings.automatic,
    'rate': settings.rate,
    'voices': <String, Object?>{
      for (final MapEntry<String, VoiceChoice> entry in settings.voices.entries)
        entry.key: <String, Object?>{
          'engine': entry.value.engine,
          'voice': entry.value.voiceId,
        },
    },
  };
}

/// Decodes the settings file's `speech` object, tolerating anything malformed.
///
/// Follows the rest of the settings decoder: an entry it cannot read is
/// dropped and the load continues. A machine whose settings file was hand
/// edited, or written by a build that spells a key differently, still starts —
/// with the automatic voice for the languages it could not read.
SpeechSettings decodeSpeechSettings(Object? value) {
  if (value is! Map) {
    return const SpeechSettings();
  }
  final Object? automatic = value['automatic'];
  final Object? rate = value['rate'];
  final Object? voices = value['voices'];
  final Map<String, VoiceChoice> choices = <String, VoiceChoice>{};
  if (voices is Map) {
    for (final MapEntry<Object?, Object?> entry in voices.entries) {
      final Object? key = entry.key;
      final Object? stored = entry.value;
      if (key is! String || stored is! Map) {
        continue;
      }
      if (!isValidSpokenLanguageTag(key)) {
        continue;
      }
      final Object? engine = stored['engine'];
      final Object? voice = stored['voice'];
      // Both halves are required: a voice with no engine cannot be trusted to
      // mean anything to the engine that reads it back.
      if (engine is! String || voice is! String) {
        continue;
      }
      if (engine.isEmpty || voice.isEmpty) {
        continue;
      }
      choices[canonicalSpokenLanguageTag(key)] = VoiceChoice(
        engine: engine,
        voiceId: voice,
      );
    }
  }
  return SpeechSettings(
    // Anything but a plain true leaves it off: the program speaking of its own
    // accord is the one thing a half-readable settings file must not turn on.
    automatic: automatic is bool && automatic,
    rate: rate is num ? clampSpeechRate(rate.toDouble()) : kDefaultSpeechRate,
    voices: Map<String, VoiceChoice>.unmodifiable(choices),
  );
}
