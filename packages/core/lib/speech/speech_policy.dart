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
import 'speech_settings.dart';
import 'spoken_language.dart';
import 'tts_engine.dart';

/// What speech is on offer for one unit as it currently stands on screen.
///
/// One [SpeechUtterance] per field that offers speech, in the order the mask
/// declares its fields, and [iconFieldIds] naming the same fields.
/// [answerUtterances] is the subset that reads the answer — what automatic
/// speech plays at the reveal and what `F4` plays on demand, which are one
/// set and not two.
final class SpeechPlan {
  /// Creates a plan from [utterances], one per field offering speech.
  ///
  /// [answerFieldIds] names those of them holding the answer role in the
  /// direction the plan was built for.
  SpeechPlan(
    List<SpeechUtterance> utterances, {
    Iterable<int> answerFieldIds = const <int>[],
  }) : _byFieldId = Map<int, SpeechUtterance>.unmodifiable(<int, SpeechUtterance>{
         for (final SpeechUtterance utterance in utterances)
           utterance.fieldId: utterance,
       }),
       _answerFieldIds = Set<int>.unmodifiable(answerFieldIds);

  /// The plan for a host that cannot speak, or a unit with nothing to say.
  static final SpeechPlan silent = SpeechPlan(const <SpeechUtterance>[]);

  // One entry per field offering speech, in mask field order (a Dart map
  // iterates in insertion order), so the two views below cannot disagree
  // about which fields those are.
  final Map<int, SpeechUtterance> _byFieldId;

  // Which of those fields hold the answer role. Kept as ids rather than as a
  // second list so the answer set is a FILTER over the one list above and can
  // never name an utterance the plan does not have.
  final Set<int> _answerFieldIds;

  /// What can be said, in mask field order.
  Iterable<SpeechUtterance> get utterances => _byFieldId.values;

  /// The fields carrying a speaker icon — exactly those with an utterance.
  Iterable<int> get iconFieldIds => _byFieldId.keys;

  /// What reads the answer, in mask field order.
  ///
  /// Automatic speech plays this at the reveal and `F4` plays it on demand:
  /// one rule for both. A field holding the remark role in both directions is
  /// therefore never played automatically however loudly its `speak` flag is
  /// set — it stays available through its own icon, which is intended.
  Iterable<SpeechUtterance> get answerUtterances =>
      _byFieldId.values.where(
        (SpeechUtterance utterance) =>
            _answerFieldIds.contains(utterance.fieldId),
      );

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
  SpeechSettings settings = const SpeechSettings(),
  String engineId = kSystemSpeechEngineId,
}) {
  final CategoryDefinition category = deck.categoryForUnit(unit);
  final List<SpeechUtterance> utterances = <SpeechUtterance>[];
  final Set<int> answerFieldIds = <int>{};
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
    if (field.roleFor(direction) == FieldRole.answer) {
      answerFieldIds.add(field.id);
    }
    utterances.add(
      SpeechUtterance(
        fieldId: field.id,
        // Verbatim, struck-through runs included: the author wrote it, and
        // the program does not edit what it was told to say.
        text: value.plainText,
        language: field.language,
        voice: resolveSpeechVoice(
          field.language,
          voices,
          settings: settings,
          engineId: engineId,
        ),
        rate: settings.rate,
      ),
    );
  }
  return SpeechPlan(utterances, answerFieldIds: answerFieldIds);
}

/// The installed voice that should speak [language], or null when none should.
///
/// Three steps, in order:
///
/// 1. the voice the learner chose for this language on this machine, when it
///    is still installed and was chosen for [engineId];
/// 2. a voice for the exact tag;
/// 3. any voice sharing the base language — a Canadian French voice reads a
///    France-French field rather than leaving it silent.
///
/// A stored choice never silences a field: one made for another engine, or
/// naming a voice since uninstalled, simply falls through to the automatic
/// steps below it.
SpeechVoice? resolveSpeechVoice(
  String language,
  List<SpeechVoice> voices, {
  SpeechSettings settings = const SpeechSettings(),
  String engineId = kSystemSpeechEngineId,
}) {
  if (language == noSpokenLanguage) {
    return null;
  }
  final List<SpeechVoice> candidates = voicesForSpeechLanguage(
    language,
    voices,
  );
  final VoiceChoice? chosen = settings.voiceFor(language);
  if (chosen != null && chosen.engine == engineId) {
    for (final SpeechVoice voice in candidates) {
      if (voice.id == chosen.voiceId) {
        return voice;
      }
    }
  }
  return candidates.isEmpty ? null : candidates.first;
}

/// Every installed voice that could speak [language], best match first.
///
/// The exact-tag voices in the order the host reports them, then the voices
/// sharing only the base language. This is both what [resolveSpeechVoice]
/// picks from and what the Speech screen offers, so the list the learner
/// chooses from cannot differ from the list the program would choose from.
/// An empty result means the machine has no voice for that language at all.
List<SpeechVoice> voicesForSpeechLanguage(
  String language,
  List<SpeechVoice> voices,
) {
  if (language == noSpokenLanguage) {
    return const <SpeechVoice>[];
  }
  final String wanted = canonicalSpokenLanguageTag(language);
  final String base = baseSpokenLanguage(wanted);
  final List<SpeechVoice> exact = <SpeechVoice>[];
  final List<SpeechVoice> related = <SpeechVoice>[];
  for (final SpeechVoice voice in voices) {
    final String reported = canonicalSpokenLanguageTag(voice.language);
    if (reported == wanted) {
      exact.add(voice);
    } else if (base.isNotEmpty && baseSpokenLanguage(reported) == base) {
      related.add(voice);
    }
  }
  return List<SpeechVoice>.unmodifiable(<SpeechVoice>[...exact, ...related]);
}

/// The languages the Speech screen lists, in the order it lists them.
///
/// The open deck's own languages first, in mask order, so the languages that
/// matter right now are at the top; then any language already configured that
/// the deck does not use, sorted, so a choice made for another deck is neither
/// lost nor invisible. With no deck open only the configured ones remain.
///
/// A field's language is listed whether or not its `speak` flag is on: the row
/// is about the language, and a field can be switched on later without the
/// voice choice having to be made again.
List<String> speechLanguagesFor({
  LearningDeck? deck,
  SpeechSettings settings = const SpeechSettings(),
}) {
  final List<String> ordered = <String>[];
  final Set<String> seen = <String>{};
  if (deck != null) {
    for (final CategoryDefinition category in deck.mask.categories) {
      for (final FieldDefinition field in category.fields) {
        if (field.language == noSpokenLanguage) {
          continue;
        }
        final String tag = canonicalSpokenLanguageTag(field.language);
        if (seen.add(tag)) {
          ordered.add(tag);
        }
      }
    }
  }
  final List<String> configured = settings.voices.keys
      .where((String tag) => !seen.contains(tag))
      .toList()
    ..sort();
  return List<String>.unmodifiable(<String>[...ordered, ...configured]);
}
