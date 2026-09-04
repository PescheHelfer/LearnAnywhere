import 'package:learn_anywhere_core/core.dart';
import 'package:test/test.dart';

/// The machine's own speech choices: the voice map, the rate, the languages
/// the Speech screen lists, and the voices it offers for each of them.
///
/// Pure Dart, host-independent, and silent: nothing here reaches an engine.
void main() {
  const SpeechVoice hortense = SpeechVoice(
    id: 'Microsoft Hortense',
    name: 'Microsoft Hortense',
    language: 'fr-FR',
  );
  const SpeechVoice claude = SpeechVoice(
    id: 'Microsoft Claude',
    name: 'Microsoft Claude',
    language: 'fr-CA',
  );
  const SpeechVoice hedda = SpeechVoice(
    id: 'Microsoft Hedda',
    name: 'Microsoft Hedda',
    language: 'de-DE',
  );

  LearningDeck deckWithLanguages(List<String> languages) {
    return LearningDeck(
      mask: LearningMask(
        maskId: 'm_new_speech-settings-fixture',
        name: 'Fixture',
        direction1Label: 'A',
        direction2Label: 'B',
        categories: <CategoryDefinition>[
          CategoryDefinition(
            id: 0,
            name: 'Cat',
            fields: <FieldDefinition>[
              for (final (int index, String language) in languages.indexed)
                FieldDefinition(
                  id: index,
                  name: 'F$index',
                  length: 20,
                  equalGroup: 0,
                  role1: index == 0 ? FieldRole.question : FieldRole.answer,
                  role2: index == 0 ? FieldRole.answer : FieldRole.question,
                  language: language,
                  speak: language != noSpokenLanguage,
                ),
            ],
          ),
        ],
      ),
      units: const <LearningUnit>[],
    );
  }

  group('the stored voice choice', () {
    test('records the engine beside the voice, never a bare voice name', () {
      const SpeechSettings settings = SpeechSettings(
        voices: <String, VoiceChoice>{
          'fr-FR': VoiceChoice(
            engine: kSystemSpeechEngineId,
            voiceId: 'Microsoft Hortense',
          ),
        },
      );
      final Map<String, Object?> json = encodeSpeechSettings(settings);
      final Object? voices = json['voices'];
      expect(voices, isA<Map<String, Object?>>());
      expect((voices! as Map<String, Object?>)['fr-FR'], <String, Object?>{
        'engine': kSystemSpeechEngineId,
        'voice': 'Microsoft Hortense',
      });
    });

    test('survives a round trip through JSON', () {
      const SpeechSettings settings = SpeechSettings(
        rate: 0.8,
        voices: <String, VoiceChoice>{
          'fr-FR': VoiceChoice(
            engine: kSystemSpeechEngineId,
            voiceId: 'Hortense',
          ),
          'de-DE': VoiceChoice(engine: 'piper', voiceId: 'de_DE-thorsten.onnx'),
        },
      );
      expect(decodeSpeechSettings(encodeSpeechSettings(settings)), settings);
    });

    test('is looked up by the tag however the caller spells it', () {
      const SpeechSettings settings = SpeechSettings(
        voices: <String, VoiceChoice>{
          'fr-FR': VoiceChoice(
            engine: kSystemSpeechEngineId,
            voiceId: 'Hortense',
          ),
        },
      );
      expect(settings.voiceFor('FR-fr')?.voiceId, 'Hortense');
      expect(settings.voiceFor('fr_FR')?.voiceId, 'Hortense');
      expect(settings.voiceFor('de-DE'), isNull);
    });

    test('withVoice adds, replaces and clears one language', () {
      const SpeechSettings empty = SpeechSettings();
      const VoiceChoice first = VoiceChoice(
        engine: kSystemSpeechEngineId,
        voiceId: 'Hortense',
      );
      const VoiceChoice second = VoiceChoice(
        engine: kSystemSpeechEngineId,
        voiceId: 'Julie',
      );
      final SpeechSettings one = empty.withVoice('fr-FR', first);
      expect(one.voiceFor('fr-FR'), first);
      expect(one.withVoice('fr-FR', second).voiceFor('fr-FR'), second);
      expect(one.withVoice('fr-FR', null).voiceFor('fr-FR'), isNull);
      // The original is untouched: settings are values.
      expect(empty.voices, isEmpty);
    });
  });

  group('the automatic-speech switch', () {
    test('starts off, so a program that never spoke stays silent', () {
      expect(const SpeechSettings().automatic, isFalse);
    });

    test('survives a round trip through JSON', () {
      const SpeechSettings settings = SpeechSettings(
        automatic: true,
        rate: 0.8,
      );
      expect(decodeSpeechSettings(encodeSpeechSettings(settings)), settings);
      expect(
        decodeSpeechSettings(encodeSpeechSettings(settings)).automatic,
        isTrue,
      );
    });

    test('is carried through withVoice and copyWith', () {
      const SpeechSettings on = SpeechSettings(automatic: true);
      const VoiceChoice hortenseChoice = VoiceChoice(
        engine: kSystemSpeechEngineId,
        voiceId: 'Hortense',
      );
      // Choosing a voice must not switch speech off behind the learner's back.
      expect(on.withVoice('fr-FR', hortenseChoice).automatic, isTrue);
      expect(on.copyWith(rate: 0.6).automatic, isTrue);
      expect(on.copyWith(automatic: false).automatic, isFalse);
    });

    test('takes part in equality', () {
      expect(
        const SpeechSettings(automatic: true),
        isNot(const SpeechSettings()),
      );
      expect(
        const SpeechSettings(automatic: true),
        const SpeechSettings(automatic: true),
      );
    });

    test('a missing or unreadable value leaves it off', () {
      expect(
        decodeSpeechSettings(<String, Object?>{'rate': 0.9}).automatic,
        isFalse,
      );
      expect(
        decodeSpeechSettings(<String, Object?>{'automatic': 'yes'}).automatic,
        isFalse,
      );
    });
  });

  group('decoding tolerates what it does not understand', () {
    test('anything that is not a map yields the defaults', () {
      expect(decodeSpeechSettings(null), const SpeechSettings());
      expect(decodeSpeechSettings('speech'), const SpeechSettings());
      expect(decodeSpeechSettings(<Object?>[]), const SpeechSettings());
    });

    test('a malformed entry is dropped, the rest survive', () {
      final SpeechSettings settings = decodeSpeechSettings(<String, Object?>{
        'rate': 0.9,
        'voices': <String, Object?>{
          'fr-FR': <String, Object?>{'engine': 'system', 'voice': 'Hortense'},
          // No engine: unusable, because a bare voice name cannot be trusted
          // to mean anything to the engine that reads it back.
          'de-DE': <String, Object?>{'voice': 'Hedda'},
          'it-IT': 'Alice',
          'not a tag': <String, Object?>{'engine': 'system', 'voice': 'X'},
        },
      });
      expect(settings.rate, 0.9);
      expect(settings.voices.keys, <String>['fr-FR']);
    });

    test('a rate outside the offered range is clamped, a broken one reset', () {
      expect(
        decodeSpeechSettings(<String, Object?>{'rate': 9.0}).rate,
        kMaxSpeechRate,
      );
      expect(
        decodeSpeechSettings(<String, Object?>{'rate': 0.0}).rate,
        kMinSpeechRate,
      );
      expect(
        decodeSpeechSettings(<String, Object?>{'rate': 'fast'}).rate,
        kDefaultSpeechRate,
      );
    });
  });

  group('the languages the Speech screen lists', () {
    test('are the ones the open deck declares, in mask order', () {
      expect(
        speechLanguagesFor(deck: deckWithLanguages(<String>['fr-FR', 'de-DE'])),
        <String>['fr-FR', 'de-DE'],
      );
    });

    test('name each language once, and skip fields with none', () {
      expect(
        speechLanguagesFor(
          deck: deckWithLanguages(<String>['fr-FR', '', 'fr-FR', 'de-DE']),
        ),
        <String>['fr-FR', 'de-DE'],
      );
    });

    test('include a configured language the deck does not use', () {
      const SpeechSettings settings = SpeechSettings(
        voices: <String, VoiceChoice>{
          'it-IT': VoiceChoice(engine: kSystemSpeechEngineId, voiceId: 'Elsa'),
        },
      );
      expect(
        speechLanguagesFor(
          deck: deckWithLanguages(<String>['fr-FR']),
          settings: settings,
        ),
        <String>['fr-FR', 'it-IT'],
      );
    });

    test('are only the configured ones when no deck is open', () {
      const SpeechSettings settings = SpeechSettings(
        voices: <String, VoiceChoice>{
          'it-IT': VoiceChoice(engine: kSystemSpeechEngineId, voiceId: 'Elsa'),
          'de-DE': VoiceChoice(engine: kSystemSpeechEngineId, voiceId: 'Hedda'),
        },
      );
      expect(speechLanguagesFor(settings: settings), <String>['de-DE', 'it-IT']);
      expect(speechLanguagesFor(), isEmpty);
    });
  });

  group('the voices a language may be spoken by', () {
    test('put the exact tag first and the same language after it', () {
      expect(
        voicesForSpeechLanguage('fr-FR', const <SpeechVoice>[
          claude,
          hedda,
          hortense,
        ]),
        <SpeechVoice>[hortense, claude],
      );
    });

    test('are empty when the machine has nothing for that language', () {
      expect(
        voicesForSpeechLanguage('it-IT', const <SpeechVoice>[hortense, hedda]),
        isEmpty,
      );
    });
  });

  group('a chosen voice', () {
    const SpeechSettings chooseCanadian = SpeechSettings(
      voices: <String, VoiceChoice>{
        'fr-FR': VoiceChoice(
          engine: kSystemSpeechEngineId,
          voiceId: 'Microsoft Claude',
        ),
      },
    );

    test('wins over the exact-tag match', () {
      expect(
        resolveSpeechVoice(
          'fr-FR',
          const <SpeechVoice>[hortense, claude],
          settings: chooseCanadian,
        ),
        claude,
      );
    });

    test('falls back to the automatic match once it is uninstalled', () {
      expect(
        resolveSpeechVoice(
          'fr-FR',
          const <SpeechVoice>[hortense],
          settings: chooseCanadian,
        ),
        hortense,
      );
    });

    test('is ignored when it was made for another engine', () {
      const SpeechSettings otherEngine = SpeechSettings(
        voices: <String, VoiceChoice>{
          'fr-FR': VoiceChoice(engine: 'piper', voiceId: 'Microsoft Claude'),
        },
      );
      expect(
        resolveSpeechVoice(
          'fr-FR',
          const <SpeechVoice>[hortense, claude],
          settings: otherEngine,
        ),
        hortense,
      );
    });
  });

  group('the sample phrase a voice is auditioned with', () {
    test('is written in the language being auditioned', () {
      expect(speechSampleFor('fr-FR'), speechSampleFor('fr-CA'));
      expect(speechSampleFor('de-AT'), isNot(speechSampleFor('fr-FR')));
      expect(speechSampleFor('it-IT'), isNotEmpty);
    });

    test('falls back to English for a language it has no phrase for', () {
      expect(speechSampleFor('ru-RU'), speechSampleFor('en-GB'));
    });
  });
}
