/// The speech policy: everything the program decides about reading a unit
/// aloud, as pure functions.
///
/// The policy RETURNS A PLAN and performs nothing. Given a deck, the unit on
/// screen, the direction, whether the answer has been revealed, and the voices
/// the host reports, it says which fields offer speech, what each of them
/// says, and which voice says it. The shell renders that plan and dispatches
/// it to a `TtsEngine`; it decides nothing of its own.
///
/// That is what makes the feature testable without audio, on any host.
library;

import '../engine/engine.dart';
import '../models/models.dart';
import 'spoken_language.dart';
import 'tts_engine.dart';

/// What speech is on offer for one unit as it currently stands on screen.
///
/// One [SpeechUtterance] per field that offers speech, in the order the mask
/// declares its fields, and [iconFieldIds] naming the same fields.
final class SpeechPlan {
  /// Creates a plan from [utterances], one per field offering speech.
  SpeechPlan(List<SpeechUtterance> utterances)
    : _byFieldId = Map<int, SpeechUtterance>.unmodifiable(<int, SpeechUtterance>{
        for (final SpeechUtterance utterance in utterances)
          utterance.fieldId: utterance,
      });

  /// The plan for a host that cannot speak, or a unit with nothing to say.
  static final SpeechPlan silent = SpeechPlan(const <SpeechUtterance>[]);

  // One entry per field offering speech, in mask field order (a Dart map
  // iterates in insertion order), so the two views below cannot disagree
  // about which fields those are.
  final Map<int, SpeechUtterance> _byFieldId;

  /// What can be said, in mask field order.
  Iterable<SpeechUtterance> get utterances => _byFieldId.values;

  /// The fields carrying a speaker icon — exactly those with an utterance.
  Iterable<int> get iconFieldIds => _byFieldId.keys;

  /// The utterance for the field with [fieldId], or null when that field
  /// offers no speech in the current state.
  SpeechUtterance? utteranceFor(int fieldId) => _byFieldId[fieldId];
}

/// Builds the speech plan for [unit] as it stands on screen.
///
/// A field offers speech when the author enabled it (`speak`), gave it a
/// spoken language, and this unit has something in it — and when its VALUE is
/// on screen, which is [isFieldValueVisible] and deliberately not the weaker
/// "its row is rendered". One rule covers all three roles: the question offers
/// speech throughout, the answer and any remark only from the reveal onwards,
/// so the solution can never be heard before it has been attempted.
///
/// [answerShown] carries the one state where an answer is on screen before
/// Check — Level Learning showing the whole solution to be memorized — so the
/// icon follows the value there too, which is exactly the moment hearing the
/// word is worth most.
///
/// A field whose language matches no installed voice still gets an utterance,
/// with a null [SpeechUtterance.voice]: an icon that explains why it is silent
/// beats no icon, which the learner could not tell from a field the author
/// never enabled.
SpeechPlan buildSpeechPlan({
  required LearningDeck deck,
  required LearningUnit unit,
  required QueryDirection direction,
  required bool afterCheck,
  required List<SpeechVoice> voices,
  bool answerShown = false,
}) {
  final CategoryDefinition category = deck.categoryForUnit(unit);
  final List<SpeechUtterance> utterances = <SpeechUtterance>[];
  for (final FieldDefinition field in category.fields) {
    if (!field.speak || field.language == noSpokenLanguage) {
      continue;
    }
    if (!isFieldValueVisible(
      field,
      direction,
      afterCheck: afterCheck,
      answerShown: answerShown,
    )) {
      continue;
    }
    final FieldValue value = unit.valueForFieldId(field.id);
    // An icon over an empty field would be an icon that does nothing.
    if (value.isBlank) {
      continue;
    }
    utterances.add(
      SpeechUtterance(
        fieldId: field.id,
        // Verbatim, struck-through runs included: the author wrote it, and
        // the program does not edit what it was told to say.
        text: value.plainText,
        language: field.language,
        voice: resolveSpeechVoice(field.language, voices),
      ),
    );
  }
  return SpeechPlan(utterances);
}

/// The installed voice that should speak [language], or null when none should.
///
/// Tries the exact tag first, then any voice sharing the base language — a
/// Canadian French voice reads a France-French field rather than leaving it
/// silent — and otherwise gives up. Both sides are compared canonically, so a
/// host that reports `fr_FR` or `FR-fr` still matches `fr-FR`.
SpeechVoice? resolveSpeechVoice(String language, List<SpeechVoice> voices) {
  if (language == noSpokenLanguage) {
    return null;
  }
  final String wanted = _canonicalTag(language);
  for (final SpeechVoice voice in voices) {
    if (_canonicalTag(voice.language) == wanted) {
      return voice;
    }
  }
  final String base = _baseLanguage(wanted);
  if (base.isEmpty) {
    return null;
  }
  for (final SpeechVoice voice in voices) {
    if (_baseLanguage(_canonicalTag(voice.language)) == base) {
      return voice;
    }
  }
  return null;
}

/// [tag] in the casing this app stores, with a host's underscore form
/// (`fr_FR`, which Android's locales produce) folded onto the hyphen form.
String _canonicalTag(String tag) =>
    normalizeSpokenLanguageTag(tag.replaceAll('_', '-'));

/// The primary language subtag of [tag] — `fr` of `fr-CA`.
String _baseLanguage(String tag) => tag.split('-').first.toLowerCase();
