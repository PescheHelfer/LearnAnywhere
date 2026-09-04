/// The speech engine seam: what a host's speech looks like from here, and the
/// engine that admits a host has none.
///
/// Pure Dart, no Flutter and no plugin: core describes speech, it never
/// performs it. The concrete engine lives in `ui_kit` and is injected by the
/// shell, which is what lets a host with no speech at all be handed
/// [UnavailableTtsEngine] instead of a plugin that would throw.
library;

/// One voice the host reports.
///
/// A voice is a property of the MACHINE, never of a deck: it is resolved fresh
/// from the host's installed voices every time, and nothing about it is ever
/// written into a mask.
final class SpeechVoice {
  /// Creates a voice as the host describes it.
  const SpeechVoice({
    required this.id,
    required this.name,
    required this.language,
  });

  /// What the engine needs to select this voice again.
  ///
  /// Engine-specific and meaningless anywhere else — an installed voice name
  /// for the operating system's own speech, a model file for an engine that
  /// carries its own voices.
  final String id;

  /// The voice's name as the learner would recognise it in a list.
  final String name;

  /// The language this voice speaks, as the host spells it (`fr-FR`, and on
  /// some hosts `fr_FR`). Compared through the policy's voice resolution,
  /// never directly.
  final String language;

  @override
  bool operator ==(Object other) =>
      other is SpeechVoice &&
      other.id == id &&
      other.name == name &&
      other.language == language;

  @override
  int get hashCode => Object.hash(id, name, language);

  @override
  String toString() => 'SpeechVoice($id, $language)';
}

/// One thing to say: a field's text, its language, and the voice resolved to
/// speak it.
///
/// Produced by the speech policy and handed to a [TtsEngine] unchanged. A null
/// [voice] means the host has no voice for [language]; the utterance still
/// exists, so the shell can explain the silence instead of hiding it.
final class SpeechUtterance {
  /// Creates an utterance.
  const SpeechUtterance({
    required this.fieldId,
    required this.text,
    required this.language,
    this.voice,
  });

  /// The field this text came from, as its mask field id numbers it.
  final int fieldId;

  /// The text to say: the field value's plain text, verbatim.
  final String text;

  /// The spoken language the mask declares for the field.
  final String language;

  /// The host voice that will say it, or null when none matched.
  final SpeechVoice? voice;

  /// Whether a voice was found, so this can actually be spoken.
  bool get canBeSpoken => voice != null;
}

/// What the shells need of a host's speech.
///
/// Deliberately tiny and asynchronous: everything richer — which fields speak,
/// what they say, which voice says it — is decided by the pure policy before
/// an engine is ever called.
abstract interface class TtsEngine {
  /// Whether this host can speak at all.
  ///
  /// False makes the whole feature disappear rather than dimming it: a shell
  /// that reads this as false shows no speaker icons, so nothing offers what
  /// the machine cannot do.
  bool get isAvailable;

  /// The voices the host has installed, or empty when it has none.
  Future<List<SpeechVoice>> voices();

  /// Says [utterance] in its resolved voice, cutting off anything still being
  /// said.
  Future<void> speak(SpeechUtterance utterance);

  /// Stops whatever is being said, if anything.
  Future<void> stop();
}

/// The engine for a host that cannot speak.
///
/// Not a test double: it is what the desktop shell selects away from Windows,
/// so Linux is handed something inert instead of reaching a plugin that has no
/// implementation there.
final class UnavailableTtsEngine implements TtsEngine {
  /// Creates the inert engine.
  const UnavailableTtsEngine();

  @override
  bool get isAvailable => false;

  @override
  Future<List<SpeechVoice>> voices() async => const <SpeechVoice>[];

  @override
  Future<void> speak(SpeechUtterance utterance) async {}

  @override
  Future<void> stop() async {}
}
