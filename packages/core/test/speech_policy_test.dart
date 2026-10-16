import 'package:learn_anywhere_core/core.dart';
import 'package:test/test.dart';

/// The speech policy: which fields carry a speaker icon, what each one says,
/// and which installed voice says it.
///
/// Pure in, pure out — no audio and no widgets, so these run on any host.
void main() {
  /// A one-category deck whose fields and values are handed in by each test.
  LearningDeck deckOf(
    List<FieldDefinition> fields,
    Map<int, FieldValue> values,
  ) {
    return LearningDeck(
      mask: LearningMask(
        maskId: 'm_new_speech-fixture',
        name: 'Speech',
        direction1Label: 'A',
        direction2Label: 'B',
        categories: <CategoryDefinition>[
          CategoryDefinition(id: 0, name: 'Cat', fields: fields),
        ],
      ),
      units: <LearningUnit>[LearningUnit(categoryId: 0, fields: values)],
    );
  }

  const SpeechVoice french = SpeechVoice(
    id: 'Microsoft Hortense',
    name: 'Microsoft Hortense',
    language: 'fr-FR',
  );
  const SpeechVoice canadianFrench = SpeechVoice(
    id: 'Microsoft Caroline',
    name: 'Microsoft Caroline',
    language: 'fr-CA',
  );
  const SpeechVoice german = SpeechVoice(
    id: 'Microsoft Hedda',
    name: 'Microsoft Hedda',
    language: 'de-DE',
  );

  /// The question in direction 1 (the answer in direction 2), spoken French.
  const FieldDefinition frenchQuestion = FieldDefinition(
    id: 0,
    name: 'French',
    length: 40,
    equalGroup: 0,
    role1: FieldRole.question,
    role2: FieldRole.answer,
    language: 'fr-FR',
    speak: true,
  );

  /// The answer in direction 1, spoken German.
  const FieldDefinition germanAnswer = FieldDefinition(
    id: 1,
    name: 'German',
    length: 40,
    equalGroup: 0,
    role1: FieldRole.answer,
    role2: FieldRole.question,
    language: 'de-DE',
    speak: true,
  );

  group('which fields offer speech', () {
    test('a Speak-enabled question field offers it throughout the item', () {
      final LearningDeck deck = deckOf(
        <FieldDefinition>[frenchQuestion, germanAnswer],
        <int, FieldValue>{
          0: const FieldValue.plain('anniversaire'),
          1: const FieldValue.plain('Geburtstag'),
        },
      );

      final SpeechPlan before = buildSpeechPlan(
        deck: deck,
        unit: deck.units.single,
        direction: QueryDirection.direction1,
        afterCheck: false,
        voices: const <SpeechVoice>[french, german],
      );
      // Before Check only the question is on screen, so only it offers speech.
      expect(before.iconFieldIds, <int>[0]);

      final SpeechPlan after = buildSpeechPlan(
        deck: deck,
        unit: deck.units.single,
        direction: QueryDirection.direction1,
        afterCheck: true,
        voices: const <SpeechVoice>[french, german],
      );
      // The question keeps its icon; the answer gains one at reveal.
      expect(after.iconFieldIds, <int>[0, 1]);
    });

    test('an answer field offers nothing until it is revealed', () {
      final LearningDeck deck = deckOf(
        <FieldDefinition>[frenchQuestion, germanAnswer],
        <int, FieldValue>{
          0: const FieldValue.plain('anniversaire'),
          1: const FieldValue.plain('Geburtstag'),
        },
      );

      // Direction 2 asks the German field, so French is the answer here.
      final SpeechPlan before = buildSpeechPlan(
        deck: deck,
        unit: deck.units.single,
        direction: QueryDirection.direction2,
        afterCheck: false,
        voices: const <SpeechVoice>[french, german],
      );
      expect(before.iconFieldIds, <int>[1]);
      expect(before.utteranceFor(0), isNull);
    });

    test('a remark field offers nothing until it is revealed', () {
      const FieldDefinition remark = FieldDefinition(
        id: 2,
        name: 'Example',
        length: 60,
        equalGroup: 0,
        role1: FieldRole.remark,
        role2: FieldRole.remark,
        language: 'fr-FR',
        speak: true,
      );
      final LearningDeck deck = deckOf(
        <FieldDefinition>[frenchQuestion, germanAnswer, remark],
        <int, FieldValue>{
          0: const FieldValue.plain('anniversaire'),
          1: const FieldValue.plain('Geburtstag'),
          2: const FieldValue.plain('Bon anniversaire!'),
        },
      );

      expect(
        buildSpeechPlan(
          deck: deck,
          unit: deck.units.single,
          direction: QueryDirection.direction1,
          afterCheck: false,
          voices: const <SpeechVoice>[french, german],
        ).iconFieldIds,
        <int>[0],
      );
      expect(
        buildSpeechPlan(
          deck: deck,
          unit: deck.units.single,
          direction: QueryDirection.direction1,
          afterCheck: true,
          voices: const <SpeechVoice>[french, german],
        ).iconFieldIds,
        <int>[0, 1, 2],
      );
    });

    test('a Speak-disabled field never offers it, language or not', () {
      const FieldDefinition silent = FieldDefinition(
        id: 1,
        name: 'Gender',
        length: 1,
        equalGroup: 0,
        role1: FieldRole.answer,
        role2: FieldRole.question,
        language: 'fr-FR',
      );
      final LearningDeck deck = deckOf(
        <FieldDefinition>[frenchQuestion, silent],
        <int, FieldValue>{
          0: const FieldValue.plain('anniversaire'),
          1: const FieldValue.plain('m'),
        },
      );

      expect(
        buildSpeechPlan(
          deck: deck,
          unit: deck.units.single,
          direction: QueryDirection.direction1,
          afterCheck: true,
          voices: const <SpeechVoice>[french],
        ).iconFieldIds,
        <int>[0],
      );
    });

    test('a hidden field never offers it, even with Speak ticked', () {
      const FieldDefinition hidden = FieldDefinition(
        id: 1,
        name: '',
        length: 40,
        equalGroup: 0,
        role1: FieldRole.answer,
        role2: FieldRole.question,
        language: 'de-DE',
        speak: true,
      );
      final LearningDeck deck = deckOf(
        <FieldDefinition>[frenchQuestion, hidden],
        <int, FieldValue>{
          0: const FieldValue.plain('anniversaire'),
          1: const FieldValue.plain('Geburtstag'),
        },
      );

      expect(
        buildSpeechPlan(
          deck: deck,
          unit: deck.units.single,
          direction: QueryDirection.direction1,
          afterCheck: true,
          voices: const <SpeechVoice>[french, german],
        ).iconFieldIds,
        <int>[0],
      );
    });

    test('a Speak-enabled field with no spoken language offers none', () {
      const FieldDefinition languageless = FieldDefinition(
        id: 1,
        name: 'German',
        length: 40,
        equalGroup: 0,
        role1: FieldRole.answer,
        role2: FieldRole.question,
        speak: true,
      );
      final LearningDeck deck = deckOf(
        <FieldDefinition>[frenchQuestion, languageless],
        <int, FieldValue>{
          0: const FieldValue.plain('anniversaire'),
          1: const FieldValue.plain('Geburtstag'),
        },
      );

      // Nothing says which voice should read it, so there is nothing to offer.
      expect(
        buildSpeechPlan(
          deck: deck,
          unit: deck.units.single,
          direction: QueryDirection.direction1,
          afterCheck: true,
          voices: const <SpeechVoice>[french, german],
        ).iconFieldIds,
        <int>[0],
      );
    });

    test('a field this unit leaves empty offers none', () {
      final LearningDeck deck = deckOf(
        <FieldDefinition>[frenchQuestion, germanAnswer],
        <int, FieldValue>{
          0: const FieldValue.plain('anniversaire'),
          1: const FieldValue.plain('   '),
        },
      );

      expect(
        buildSpeechPlan(
          deck: deck,
          unit: deck.units.single,
          direction: QueryDirection.direction1,
          afterCheck: true,
          voices: const <SpeechVoice>[french, german],
        ).iconFieldIds,
        <int>[0],
      );
    });

    test('an answer shown as Level-Learning support offers speech before '
        'Check', () {
      final LearningDeck deck = deckOf(
        <FieldDefinition>[frenchQuestion, germanAnswer],
        <int, FieldValue>{
          0: const FieldValue.plain('anniversaire'),
          1: const FieldValue.plain('Geburtstag'),
        },
      );

      // Level Learning at the top of the ladder puts the whole solution on
      // screen to be read and memorized. Nothing is withheld there, so the
      // icon follows the value — and that is the moment hearing it is worth
      // most.
      expect(
        buildSpeechPlan(
          deck: deck,
          unit: deck.units.single,
          direction: QueryDirection.direction1,
          afterCheck: false,
          answerShown: true,
          voices: const <SpeechVoice>[french, german],
        ).iconFieldIds,
        <int>[0, 1],
      );
      // A remark is still not on screen: only the answer is being shown.
      expect(
        buildSpeechPlan(
          deck: deck,
          unit: deck.units.single,
          direction: QueryDirection.direction1,
          afterCheck: false,
          voices: const <SpeechVoice>[french, german],
        ).iconFieldIds,
        <int>[0],
      );
    });

    test('the utterances follow the order the mask declares its fields in', () {
      final LearningDeck deck = deckOf(
        <FieldDefinition>[germanAnswer, frenchQuestion],
        <int, FieldValue>{
          0: const FieldValue.plain('anniversaire'),
          1: const FieldValue.plain('Geburtstag'),
        },
      );

      expect(
        buildSpeechPlan(
          deck: deck,
          unit: deck.units.single,
          direction: QueryDirection.direction1,
          afterCheck: true,
          voices: const <SpeechVoice>[french, german],
        ).utterances.map((SpeechUtterance u) => u.fieldId),
        <int>[1, 0],
      );
    });
  });

  group('the answer set — what automatic speech and F4 both play', () {
    const FieldDefinition frenchRemark = FieldDefinition(
      id: 2,
      name: 'Example',
      length: 60,
      equalGroup: 0,
      role1: FieldRole.remark,
      role2: FieldRole.remark,
      language: 'fr-FR',
      speak: true,
    );

    LearningDeck threeFieldDeck() => deckOf(
      <FieldDefinition>[frenchQuestion, germanAnswer, frenchRemark],
      <int, FieldValue>{
        0: const FieldValue.plain('anniversaire'),
        1: const FieldValue.plain('Geburtstag'),
        2: const FieldValue.plain('Bon anniversaire!'),
      },
    );

    test('is exactly the Speak-enabled fields holding the answer role', () {
      final LearningDeck deck = threeFieldDeck();

      final SpeechPlan plan = buildSpeechPlan(
        deck: deck,
        unit: deck.units.single,
        direction: QueryDirection.direction1,
        afterCheck: true,
        voices: const <SpeechVoice>[french, german],
      );
      // The question is on screen already and the remark holds the remark
      // role in BOTH directions, so neither is ever played automatically —
      // both keep their icon.
      expect(plan.iconFieldIds, <int>[0, 1, 2]);
      expect(
        plan.answerUtterances.map((SpeechUtterance u) => u.fieldId),
        <int>[1],
      );
    });

    test('follows the direction: the other field answers in direction 2', () {
      final LearningDeck deck = threeFieldDeck();

      expect(
        buildSpeechPlan(
          deck: deck,
          unit: deck.units.single,
          direction: QueryDirection.direction2,
          afterCheck: true,
          voices: const <SpeechVoice>[french, german],
        ).answerUtterances.map((SpeechUtterance u) => u.text),
        <String>['anniversaire'],
      );
    });

    test('is empty before the answer is revealed', () {
      final LearningDeck deck = threeFieldDeck();

      expect(
        buildSpeechPlan(
          deck: deck,
          unit: deck.units.single,
          direction: QueryDirection.direction1,
          afterCheck: false,
          voices: const <SpeechVoice>[french, german],
        ).answerUtterances,
        isEmpty,
      );
    });

    test('holds an answer shown as Level-Learning support', () {
      final LearningDeck deck = threeFieldDeck();

      expect(
        buildSpeechPlan(
          deck: deck,
          unit: deck.units.single,
          direction: QueryDirection.direction1,
          afterCheck: false,
          answerShown: true,
          voices: const <SpeechVoice>[french, german],
        ).answerUtterances.map((SpeechUtterance u) => u.fieldId),
        <int>[1],
      );
    });

    test('runs in mask field order, not answer-role order', () {
      const FieldDefinition secondAnswer = FieldDefinition(
        id: 3,
        name: 'German 2',
        length: 40,
        equalGroup: 0,
        role1: FieldRole.answer,
        role2: FieldRole.question,
        language: 'de-DE',
        speak: true,
      );
      // Declared second-answer-first, so an implementation reading roles in
      // any other order than the mask's would show up here.
      final LearningDeck deck = deckOf(
        <FieldDefinition>[secondAnswer, frenchQuestion, germanAnswer],
        <int, FieldValue>{
          0: const FieldValue.plain('anniversaire'),
          1: const FieldValue.plain('Geburtstag'),
          3: const FieldValue.plain('Wiegenfest'),
        },
      );

      expect(
        buildSpeechPlan(
          deck: deck,
          unit: deck.units.single,
          direction: QueryDirection.direction1,
          afterCheck: true,
          voices: const <SpeechVoice>[french, german],
        ).answerUtterances.map((SpeechUtterance u) => u.text),
        <String>['Wiegenfest', 'Geburtstag'],
      );
    });

    test('is empty when no answer field may be spoken', () {
      const FieldDefinition mutedAnswer = FieldDefinition(
        id: 1,
        name: 'German',
        length: 40,
        equalGroup: 0,
        role1: FieldRole.answer,
        role2: FieldRole.question,
        language: 'de-DE',
      );
      final LearningDeck deck = deckOf(
        <FieldDefinition>[frenchQuestion, mutedAnswer],
        <int, FieldValue>{
          0: const FieldValue.plain('anniversaire'),
          1: const FieldValue.plain('Geburtstag'),
        },
      );

      final SpeechPlan plan = buildSpeechPlan(
        deck: deck,
        unit: deck.units.single,
        direction: QueryDirection.direction1,
        afterCheck: true,
        voices: const <SpeechVoice>[french, german],
      );
      expect(plan.answerUtterances, isEmpty);
      // The question is still on offer through its own icon.
      expect(plan.iconFieldIds, <int>[0]);
    });

    test('the silent plan has neither icons nor an answer set', () {
      expect(SpeechPlan.silent.iconFieldIds, isEmpty);
      expect(SpeechPlan.silent.answerUtterances, isEmpty);
    });
  });

  group('what is said', () {
    test('the spoken text is the plain text of the value, verbatim', () {
      final LearningDeck deck = deckOf(
        <FieldDefinition>[frenchQuestion],
        <int, FieldValue>{
          0: FieldValue.rich(const <RichTextRun>[
            RichTextRun(text: 'anniv'),
            // A struck-through run is read out with the rest: the policy says
            // what the author wrote, and does not second-guess it.
            RichTextRun(text: 'ers', strikethrough: true),
            RichTextRun(text: 'aire'),
          ]),
        },
      );

      final SpeechPlan plan = buildSpeechPlan(
        deck: deck,
        unit: deck.units.single,
        direction: QueryDirection.direction1,
        afterCheck: false,
        voices: const <SpeechVoice>[french],
      );
      expect(plan.utteranceFor(0)!.text, 'anniversaire');
      expect(plan.utteranceFor(0)!.language, 'fr-FR');
      expect(plan.utteranceFor(0)!.voice, french);
    });
  });

  group('voice resolution', () {
    test('an exact language tag wins over a voice sharing its base', () {
      expect(
        resolveSpeechVoice('fr-FR', const <SpeechVoice>[canadianFrench, french]),
        french,
      );
    });

    test('a voice sharing the base language speaks when none matches '
        'exactly', () {
      expect(
        resolveSpeechVoice('fr-FR', const <SpeechVoice>[
          german,
          canadianFrench,
        ]),
        canadianFrench,
      );
    });

    test('nothing resolves when no installed voice shares the base', () {
      expect(
        resolveSpeechVoice('it-IT', const <SpeechVoice>[french, german]),
        isNull,
      );
    });

    test('host spellings of a tag still match: casing and underscores', () {
      const SpeechVoice androidStyle = SpeechVoice(
        id: 'fr_FR-local',
        name: 'French',
        language: 'fr_FR',
      );
      expect(
        resolveSpeechVoice('FR-fr', const <SpeechVoice>[androidStyle]),
        androidStyle,
      );
    });

    test('a field whose language resolves to nothing still offers speech', () {
      final LearningDeck deck = deckOf(
        <FieldDefinition>[frenchQuestion],
        <int, FieldValue>{0: const FieldValue.plain('anniversaire')},
      );

      final SpeechPlan plan = buildSpeechPlan(
        deck: deck,
        unit: deck.units.single,
        direction: QueryDirection.direction1,
        afterCheck: false,
        voices: const <SpeechVoice>[german],
      );
      // The icon is there — a missing one would be indistinguishable from a
      // field the author never enabled — but it has nothing to speak with.
      expect(plan.iconFieldIds, <int>[0]);
      expect(plan.utteranceFor(0)!.voice, isNull);
      expect(plan.utteranceFor(0)!.canBeSpoken, isFalse);
    });
  });

  group('selectableVoiceChoice — what a Speech screen shows as chosen', () {
    const VoiceChoice choice = VoiceChoice(
      engine: kSystemSpeechEngineId,
      voiceId: 'Microsoft Hortense',
    );

    test('a choice naming a still-installed voice for this engine is '
        'selectable', () {
      expect(
        selectableVoiceChoice(choice, const <SpeechVoice>[french]),
        choice,
      );
    });

    test('null when nothing is chosen', () {
      expect(selectableVoiceChoice(null, const <SpeechVoice>[french]), isNull);
    });

    test('null when the chosen voice is no longer installed', () {
      expect(
        selectableVoiceChoice(choice, const <SpeechVoice>[german]),
        isNull,
      );
    });

    test('null when the choice was made for another engine', () {
      const VoiceChoice otherEngine = VoiceChoice(
        engine: 'some-other-engine',
        voiceId: 'Microsoft Hortense',
      );
      expect(
        selectableVoiceChoice(otherEngine, const <SpeechVoice>[french]),
        isNull,
      );
    });
  });

  group('the unavailable engine', () {
    test('reports itself unavailable, has no voices, and does nothing', () {
      const TtsEngine engine = UnavailableTtsEngine();
      expect(engine.isAvailable, isFalse);
      expect(engine.voices(), completion(isEmpty));
      expect(
        engine.speak(
          const SpeechUtterance(
            fieldId: 0,
            text: 'anniversaire',
            language: 'fr-FR',
          ),
        ),
        completes,
      );
      expect(engine.stop(), completes);
    });
  });

  group('the lead-in that wakes the audio output', () {
    /// A second answer field in direction 1, also spoken German.
    const FieldDefinition germanPlural = FieldDefinition(
      id: 2,
      name: 'Plural',
      length: 40,
      equalGroup: 1,
      role1: FieldRole.answer,
      role2: FieldRole.remark,
      language: 'de-DE',
      speak: true,
    );

    /// An answer field in a language the host has no voice for.
    const FieldDefinition italianAnswer = FieldDefinition(
      id: 3,
      name: 'Italian',
      length: 40,
      equalGroup: 2,
      role1: FieldRole.answer,
      role2: FieldRole.remark,
      language: 'it-IT',
      speak: true,
    );

    SpeechPlan revealed(
      List<FieldDefinition> fields, {
      SpeechSettings settings = const SpeechSettings(),
    }) {
      final LearningDeck deck = deckOf(fields, <int, FieldValue>{
        0: const FieldValue.plain('anniversaire'),
        1: const FieldValue.plain('Geburtstag'),
        2: const FieldValue.plain('Geburtstage'),
        3: const FieldValue.plain('compleanno'),
      });
      return buildSpeechPlan(
        deck: deck,
        unit: deck.units.single,
        direction: QueryDirection.direction1,
        afterCheck: true,
        voices: const <SpeechVoice>[french, german],
        settings: settings,
      );
    }

    test('is on by default, and a read plays it before its first field '
        'only', () {
      final SpeechPlan plan = revealed(<FieldDefinition>[
        frenchQuestion,
        germanAnswer,
        germanPlural,
      ]);
      // The first word wakes the output; a lead-in before every later field
      // would only lengthen the pause between them.
      expect(
        plan.answerUtterances.map((SpeechUtterance u) => u.leadIn),
        <bool>[true, false],
      );
    });

    test('goes to the first field that can actually be spoken', () {
      final SpeechPlan plan = revealed(<FieldDefinition>[
        frenchQuestion,
        italianAnswer,
        germanAnswer,
      ]);
      // The Italian field has no voice and is skipped when the answer is
      // read, so the German one is the first word the learner hears.
      expect(
        plan.answerUtterances.map((SpeechUtterance u) => u.fieldId),
        <int>[3, 1],
      );
      expect(
        plan.answerUtterances.map((SpeechUtterance u) => u.leadIn),
        <bool>[false, true],
      );
    });

    test('comes with every single field an icon plays', () {
      final SpeechPlan plan = revealed(<FieldDefinition>[
        frenchQuestion,
        germanAnswer,
        germanPlural,
      ]);
      // A click on an icon is a read of one word, after any pause at all.
      expect(plan.utteranceFor(0)!.leadIn, isTrue);
      expect(plan.utteranceFor(1)!.leadIn, isTrue);
      expect(plan.utteranceFor(2)!.leadIn, isTrue);
    });

    test('is never planned when the switch is off', () {
      final SpeechPlan plan = revealed(<FieldDefinition>[
        frenchQuestion,
        germanAnswer,
        germanPlural,
      ], settings: const SpeechSettings(wakeAudio: false));
      expect(
        plan.utterances.map((SpeechUtterance u) => u.leadIn),
        everyElement(isFalse),
      );
      expect(
        plan.answerUtterances.map((SpeechUtterance u) => u.leadIn),
        everyElement(isFalse),
      );
    });
  });
}
