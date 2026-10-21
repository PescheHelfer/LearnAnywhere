import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_desktop/src/learn/desktop_query_options.dart';
import 'package:learn_anywhere_desktop/src/learn/learn_session_page.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

/// Speech in a running session: where the speaker icons are, what they ask to
/// be said, and what a host with no voice — or no speech at all — shows.
///
/// Driven against a recording engine, so no test makes a sound.
void main() {
  const SpeechVoice frenchVoice = SpeechVoice(
    id: 'Microsoft Hortense',
    name: 'Microsoft Hortense',
    language: 'fr-FR',
  );
  const SpeechVoice germanVoice = SpeechVoice(
    id: 'Microsoft Hedda',
    name: 'Microsoft Hedda',
    language: 'de-DE',
  );

  const LearningMask mask = LearningMask(
    maskId: 'm_new_speech-session-fixture',
    name: 'Fixture',
    direction1Label: 'A',
    direction2Label: 'B',
    categories: <CategoryDefinition>[
      CategoryDefinition(
        id: 0,
        name: 'Cat',
        fields: <FieldDefinition>[
          FieldDefinition(
            id: 0,
            name: 'French',
            length: 20,
            equalGroup: 0,
            role1: FieldRole.question,
            role2: FieldRole.answer,
            language: 'fr-FR',
            speak: true,
          ),
          FieldDefinition(
            id: 1,
            name: 'German',
            length: 20,
            equalGroup: 0,
            role1: FieldRole.answer,
            role2: FieldRole.question,
            language: 'de-DE',
            speak: true,
          ),
          // Speech is switched off here, so this field never offers it.
          FieldDefinition(
            id: 2,
            name: 'Gender',
            length: 1,
            equalGroup: 0,
            role1: FieldRole.remark,
            role2: FieldRole.remark,
            language: 'fr-FR',
          ),
        ],
      ),
    ],
  );

  const LearningUnit birthday = LearningUnit(
    categoryId: 0,
    fields: <int, FieldValue>{
      0: FieldValue.plain('anniversaire'),
      1: FieldValue.plain('Geburtstag'),
      2: FieldValue.plain('m'),
    },
  );
  const LearningUnit house = LearningUnit(
    categoryId: 0,
    fields: <int, FieldValue>{
      0: FieldValue.plain('maison'),
      1: FieldValue.plain('Haus'),
      2: FieldValue.plain('f'),
    },
  );

  final LearningDeck deck = LearningDeck(
    mask: mask,
    units: const <LearningUnit>[birthday],
  );

  /// The same deck with a second unit, for what happens when one reveal
  /// follows another.
  final LearningDeck twoUnitDeck = LearningDeck(
    mask: mask,
    units: const <LearningUnit>[birthday, house],
  );

  /// The same deck with speech switched off for the answer field, so no unit
  /// in it has anything to read aloud automatically.
  final LearningDeck mutedAnswerDeck = LearningDeck(
    mask: LearningMask(
      maskId: mask.maskId,
      name: mask.name,
      direction1Label: mask.direction1Label,
      direction2Label: mask.direction2Label,
      categories: <CategoryDefinition>[
        CategoryDefinition(
          id: 0,
          name: 'Cat',
          fields: <FieldDefinition>[
            mask.categories.single.fields[0],
            mask.categories.single.fields[1].copyWith(speak: false),
            mask.categories.single.fields[2],
          ],
        ),
      ],
    ),
    units: const <LearningUnit>[birthday],
  );

  Widget buildPage(
    TtsEngine engine,
    SessionMode mode,
    SpeechSettings speechSettings,
    LearningDeck sessionDeck,
    bool withInput,
    ValueChanged<List<UnitStats>> onStatisticsChanged,
    DifficultFlags Function(SessionItem, DifficultFlags)? onToggleDifficult,
  ) {
    return MaterialApp(
      localizationsDelegates: LearnAnywhereLocalizations.localizationsDelegates,
      supportedLocales: LearnAnywhereLocalizations.supportedLocales,
      home: Scaffold(
        body: LearnSessionPage(
          startSessionOnOpen: true,
          speechEngine: engine,
          speechSettings: speechSettings,
          deck: sessionDeck,
          statistics: const <UnitStats>[],
          options: const DesktopQueryOptions(),
          parameters: SessionParameters(
            withInput: withInput,
            mode: mode,
            directionSelection: DirectionSelection.direction1,
            shuffle: false,
          ),
          onParametersChanged: (SessionParameters _) {},
          onStatisticsChanged: onStatisticsChanged,
          onOpenEditor: () {},
          onToggleDifficult: onToggleDifficult,
        ),
      ),
    );
  }

  Future<void> startSession(
    WidgetTester tester,
    TtsEngine engine, {
    SessionMode mode = SessionMode.onceThrough,
    // Off here, although the program's default is on: most tests look at one
    // route to speech at a time, and the ones about automatic speech say so.
    SpeechSettings speechSettings = const SpeechSettings(automatic: false),
    LearningDeck? sessionDeck,
    bool withInput = false,
    ValueChanged<List<UnitStats>>? onStatisticsChanged,
    DifficultFlags Function(SessionItem, DifficultFlags)? onToggleDifficult,
  }) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      buildPage(
        engine,
        mode,
        speechSettings,
        sessionDeck ?? deck,
        withInput,
        onStatisticsChanged ?? (List<UnitStats> _) {},
        onToggleDifficult,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the question speaks throughout; the answer only once revealed', (
    WidgetTester tester,
  ) async {
    final _RecordingTtsEngine engine = _RecordingTtsEngine(
      const <SpeechVoice>[frenchVoice, germanVoice],
    );
    await startSession(tester, engine);

    // Before Check: the question offers speech, the answer does not, and the
    // Speak-disabled field never does.
    expect(find.byKey(const Key('speakField-0')), findsOneWidget);
    expect(find.byKey(const Key('speakField-1')), findsNothing);
    expect(find.byKey(const Key('speakField-2')), findsNothing);

    await tester.tap(find.byKey(const Key('speakField-0')));
    await tester.pumpAndSettle();
    expect(engine.spoken.single.text, 'anniversaire');
    expect(engine.spoken.single.voice, frenchVoice);

    // F10 reveals the answer, which then offers speech in its own voice.
    await tester.sendKeyEvent(LogicalKeyboardKey.f10);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('speakField-0')), findsOneWidget);
    expect(find.byKey(const Key('speakField-1')), findsOneWidget);
    expect(find.byKey(const Key('speakField-2')), findsNothing);

    await tester.tap(find.byKey(const Key('speakField-1')));
    await tester.pumpAndSettle();
    expect(engine.spoken.last.text, 'Geburtstag');
    expect(engine.spoken.last.voice, germanVoice);
  });

  testWidgets('level learning speaks the solution it puts on screen to be '
      'memorized, and stops offering it once it is hidden', (
    WidgetTester tester,
  ) async {
    final _RecordingTtsEngine engine = _RecordingTtsEngine(
      const <SpeechVoice>[frenchVoice, germanVoice],
    );
    await startSession(tester, engine, mode: SessionMode.levelLearning);

    // A fresh unit seeds the top of the ladder, where the whole solution is
    // shown to be read. Its value is on screen, so it offers speech — this is
    // the moment hearing the word is worth most.
    expect(find.text('Hide & type'), findsOneWidget);
    expect(find.byKey(const Key('speakField-1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('speakField-1')));
    await tester.pumpAndSettle();
    expect(engine.spoken.single.text, 'Geburtstag');

    // Hide & type takes the solution away again; the icon goes with it.
    await tester.sendKeyEvent(LogicalKeyboardKey.f10);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byKey(const Key('speakField-1')), findsNothing);
    expect(find.byKey(const Key('speakField-0')), findsOneWidget);
  });

  testWidgets('a language with no installed voice says so and stays silent', (
    WidgetTester tester,
  ) async {
    final _RecordingTtsEngine engine = _RecordingTtsEngine(
      const <SpeechVoice>[germanVoice],
    );
    await startSession(tester, engine);

    // The icon is there — hiding it would look like a field the author never
    // enabled — and using it explains the silence.
    await tester.tap(find.byKey(const Key('speakField-0')));
    await tester.pumpAndSettle();
    expect(engine.spoken, isEmpty);
    expect(find.textContaining('fr-FR'), findsOneWidget);
    expect(find.textContaining('Speech'), findsOneWidget);
  });

  testWidgets('an icon uses the voice and the rate chosen on the Speech '
      'screen', (WidgetTester tester) async {
    const SpeechVoice canadian = SpeechVoice(
      id: 'Microsoft Claude',
      name: 'Microsoft Claude',
      language: 'fr-CA',
    );
    final _RecordingTtsEngine engine = _RecordingTtsEngine(
      const <SpeechVoice>[frenchVoice, canadian],
    );
    await startSession(
      tester,
      engine,
      speechSettings: const SpeechSettings(
        rate: 0.7,
        voices: <String, VoiceChoice>{
          'fr-FR': VoiceChoice(
            engine: kSystemSpeechEngineId,
            voiceId: 'Microsoft Claude',
          ),
        },
      ),
    );

    await tester.tap(find.byKey(const Key('speakField-0')));
    await tester.pumpAndSettle();
    // The Canadian voice, though a France-French one is installed: the
    // learner's choice comes before the automatic match.
    expect(engine.spoken.single.voice, canadian);
    expect(engine.spoken.single.rate, 0.7);
  });

  group('automatic speech', () {
    const SpeechSettings automatic = SpeechSettings(automatic: true);

    testWidgets('reads the answer once at a reveal with no typing', (
      WidgetTester tester,
    ) async {
      final _RecordingTtsEngine engine = _RecordingTtsEngine(
        const <SpeechVoice>[frenchVoice, germanVoice],
      );
      await startSession(tester, engine, speechSettings: automatic);

      // Nothing is said while the answer is still hidden: the question is on
      // screen and the solution has not been earned yet.
      expect(engine.spoken, isEmpty);

      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();

      // Exactly the answer field, in its own voice — not the question the
      // learner can already see, and not the remark field.
      expect(engine.spoken.single.text, 'Geburtstag');
      expect(engine.spoken.single.voice, germanVoice);
      // It stopped before it started: a word from the unit before must not run
      // on over this one.
      expect(engine.events, <String>['stop', 'speak:Geburtstag']);
    });

    testWidgets('reads a swapped equal group in the order Correction shows it, '
        'and Solution in the stored order', (WidgetTester tester) async {
      FieldDefinition germanRow(int id) => FieldDefinition(
        id: id,
        name: 'German $id',
        length: 20,
        equalGroup: 1,
        role1: FieldRole.answer,
        role2: FieldRole.question,
        language: 'de-DE',
        speak: true,
      );
      final LearningDeck groupDeck = LearningDeck(
        mask: LearningMask(
          maskId: mask.maskId,
          name: mask.name,
          direction1Label: mask.direction1Label,
          direction2Label: mask.direction2Label,
          categories: <CategoryDefinition>[
            CategoryDefinition(
              id: 0,
              name: 'Cat',
              fields: <FieldDefinition>[
                mask.categories.single.fields[0],
                germanRow(1),
                germanRow(3),
              ],
            ),
          ],
        ),
        units: const <LearningUnit>[
          LearningUnit(
            categoryId: 0,
            fields: <int, FieldValue>{
              0: FieldValue.plain('anniversaire'),
              1: FieldValue.plain('Geburtstag'),
              3: FieldValue.plain('Wiegenfest'),
            },
          ),
        ],
      );
      final _RecordingTtsEngine engine = _RecordingTtsEngine(
        const <SpeechVoice>[frenchVoice, germanVoice],
      );
      await startSession(
        tester,
        engine,
        speechSettings: automatic,
        sessionDeck: groupDeck,
        withInput: true,
      );

      await tester.enterText(find.byType(TextField).at(0), 'Wiegenfest');
      await tester.enterText(find.byType(TextField).at(1), 'Geburtstag');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();

      // A swap opens on Correction, in the typed order, and is read so.
      expect(find.text('Correction'), findsOneWidget);
      expect(engine.spoken.map((SpeechUtterance u) => u.text), <String>[
        'Wiegenfest',
        'Geburtstag',
      ]);

      engine.spoken.clear();
      await tester.sendKeyEvent(LogicalKeyboardKey.f9);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f4);
      await tester.pumpAndSettle();
      expect(find.text('Solution'), findsOneWidget);
      expect(engine.spoken.map((SpeechUtterance u) => u.text), <String>[
        'Geburtstag',
        'Wiegenfest',
      ]);
    });

    testWidgets('starts the reveal and every F4 with the lead-in that wakes '
        'the audio output', (WidgetTester tester) async {
      final _RecordingTtsEngine engine = _RecordingTtsEngine(
        const <SpeechVoice>[frenchVoice, germanVoice],
      );
      await startSession(tester, engine, speechSettings: automatic);

      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f4);
      await tester.pumpAndSettle();
      // Each is a new read after a pause the output may have dozed through.
      expect(
        engine.spoken.map((SpeechUtterance u) => u.leadIn),
        <bool>[true, true],
      );
    });

    testWidgets('plays no lead-in when waking the audio output is switched '
        'off', (WidgetTester tester) async {
      final _RecordingTtsEngine quiet = _RecordingTtsEngine(
        const <SpeechVoice>[frenchVoice, germanVoice],
      );
      await startSession(
        tester,
        quiet,
        speechSettings: const SpeechSettings(wakeAudio: false),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();
      expect(quiet.spoken.single.leadIn, isFalse);
    });

    testWidgets('reads the answer out on a wrong answer too, and cycling the '
        'answer view does not repeat it', (WidgetTester tester) async {
      final _RecordingTtsEngine engine = _RecordingTtsEngine(
        const <SpeechVoice>[frenchVoice, germanVoice],
      );
      final List<List<UnitStats>> pushes = <List<UnitStats>>[];
      await startSession(
        tester,
        engine,
        speechSettings: automatic,
        withInput: true,
        onStatisticsChanged: pushes.add,
      );

      await tester.enterText(find.byType(TextField), 'Geburtsatg');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();

      // A mistake is the moment hearing it said properly is worth most.
      expect(find.textContaining('wrong'), findsWidgets);
      expect(engine.spoken.single.text, 'Geburtstag');

      // F9 cycles Correction → Solution → Your answer. The unit was revealed
      // once, so it is read once.
      await tester.sendKeyEvent(LogicalKeyboardKey.f9);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f9);
      await tester.pumpAndSettle();
      expect(engine.spoken.length, 1);
      // Listening moved no statistics: nothing is recorded until Continue.
      expect(pushes, isEmpty);
    });

    testWidgets('a new reveal stops what is still being said', (
      WidgetTester tester,
    ) async {
      final _RecordingTtsEngine engine = _RecordingTtsEngine(
        const <SpeechVoice>[frenchVoice, germanVoice],
      );
      await startSession(
        tester,
        engine,
        speechSettings: automatic,
        sessionDeck: twoUnitDeck,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();
      // Continue to unit 2 and reveal it as well.
      await tester.sendKeyEvent(LogicalKeyboardKey.f3);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();

      expect(engine.events, <String>[
        'stop',
        'speak:Geburtstag',
        'stop',
        'speak:Haus',
      ]);
    });

    testWidgets('fires at the Level-Learning level that shows the solution '
        'first', (WidgetTester tester) async {
      final _RecordingTtsEngine engine = _RecordingTtsEngine(
        const <SpeechVoice>[frenchVoice, germanVoice],
      );
      await startSession(
        tester,
        engine,
        mode: SessionMode.levelLearning,
        speechSettings: automatic,
      );

      // The top of the ladder shows the solution to be memorized. That is not
      // a reveal, so nothing is said by itself yet.
      expect(find.text('Hide & type'), findsOneWidget);
      expect(engine.spoken, isEmpty);

      // Hide & type, then reveal what was typed: the reveal reads it out, at
      // this level exactly as at any other.
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();
      expect(engine.spoken.single.text, 'Geburtstag');
    });

    testWidgets('a unit with no Speak-enabled answer field stays silent', (
      WidgetTester tester,
    ) async {
      final _RecordingTtsEngine engine = _RecordingTtsEngine(
        const <SpeechVoice>[frenchVoice, germanVoice],
      );
      await startSession(
        tester,
        engine,
        speechSettings: automatic,
        sessionDeck: mutedAnswerDeck,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();
      // Silent, and nothing raised: the previous unit is cut off all the same.
      expect(engine.spoken, isEmpty);
      expect(engine.events, <String>['stop']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('says nothing at all when it is switched off', (
      WidgetTester tester,
    ) async {
      final _RecordingTtsEngine engine = _RecordingTtsEngine(
        const <SpeechVoice>[frenchVoice, germanVoice],
      );
      await startSession(
        tester,
        engine,
        speechSettings: const SpeechSettings(automatic: false),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();
      expect(engine.events, isEmpty);
    });
  });

  group('F4', () {
    testWidgets('plays the answer set on demand with automatic speech off', (
      WidgetTester tester,
    ) async {
      final _RecordingTtsEngine engine = _RecordingTtsEngine(
        const <SpeechVoice>[frenchVoice, germanVoice],
      );
      final List<List<UnitStats>> pushes = <List<UnitStats>>[];
      await startSession(tester, engine, onStatisticsChanged: pushes.add);

      // Before the reveal there is no answer on screen, so there is nothing to
      // replay: F4 can never leak the solution.
      await tester.sendKeyEvent(LogicalKeyboardKey.f4);
      await tester.pumpAndSettle();
      expect(engine.spoken, isEmpty);

      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();
      expect(engine.spoken, isEmpty);

      await tester.sendKeyEvent(LogicalKeyboardKey.f4);
      await tester.pumpAndSettle();
      expect(engine.spoken.single.text, 'Geburtstag');
      expect(engine.spoken.single.voice, germanVoice);

      // Again, as often as it helps — and it is never an attempt.
      await tester.sendKeyEvent(LogicalKeyboardKey.f4);
      await tester.pumpAndSettle();
      expect(
        engine.spoken.map((SpeechUtterance u) => u.text),
        <String>['Geburtstag', 'Geburtstag'],
      );
      expect(pushes, isEmpty);
    });

    testWidgets('says which language has no voice, rather than staying '
        'silently unexplained', (WidgetTester tester) async {
      // No German voice: the answer field in this direction cannot be spoken.
      final _RecordingTtsEngine engine = _RecordingTtsEngine(
        const <SpeechVoice>[frenchVoice],
      );
      await startSession(tester, engine);

      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f4);
      await tester.pumpAndSettle();

      expect(engine.spoken, isEmpty);
      expect(find.textContaining('de-DE'), findsOneWidget);
    });

    testWidgets('plays the Level-Learning solution shown before any check', (
      WidgetTester tester,
    ) async {
      final _RecordingTtsEngine engine = _RecordingTtsEngine(
        const <SpeechVoice>[frenchVoice, germanVoice],
      );
      await startSession(tester, engine, mode: SessionMode.levelLearning);

      // The solution is on screen to be memorized, so F4 reads what is there —
      // the same rule the icon beside it follows.
      expect(find.text('Hide & type'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.f4);
      await tester.pumpAndSettle();
      expect(engine.spoken.single.text, 'Geburtstag');
    });
  });

  group('Read aloud pill', () {
    final Finder pill = find.byKey(const Key('learnReadAloudPill'));

    /// Every label and key hint in the row keyed [rowKey], in reading order.
    List<String?> texts(String rowKey) => find
        .descendant(of: find.byKey(Key(rowKey)), matching: find.byType(Text))
        .evaluate()
        .map((Element e) => (e.widget as Text).data)
        .toList();

    testWidgets('appears once the answer is revealed and plays what F4 plays', (
      WidgetTester tester,
    ) async {
      final _RecordingTtsEngine engine = _RecordingTtsEngine(
        const <SpeechVoice>[frenchVoice, germanVoice],
      );
      final List<List<UnitStats>> pushes = <List<UnitStats>>[];
      await startSession(tester, engine, onStatisticsChanged: pushes.add);

      // The question stage has no answer on screen, so F4 would say nothing
      // and no pill offers it.
      expect(pill, findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();
      expect(pill, findsOneWidget);
      expect(
        find.descendant(of: pill, matching: find.text('Read aloud')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: pill, matching: find.text('F4')),
        findsOneWidget,
      );

      await tester.tap(pill);
      await tester.pumpAndSettle();
      expect(engine.events, <String>['stop', 'speak:Geburtstag']);
      expect(engine.spoken.single.voice, germanVoice);
      expect(pushes, isEmpty);
    });

    testWidgets('is absent on a host that cannot speak', (
      WidgetTester tester,
    ) async {
      await startSession(tester, const UnavailableTtsEngine());
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();
      expect(find.text('Continue'), findsOneWidget);
      expect(pill, findsNothing);
    });

    testWidgets('is absent when the unit has no answer to read', (
      WidgetTester tester,
    ) async {
      final _RecordingTtsEngine engine = _RecordingTtsEngine(
        const <SpeechVoice>[frenchVoice, germanVoice],
      );
      await startSession(tester, engine, sessionDeck: mutedAnswerDeck);
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();
      expect(find.text('Continue'), findsOneWidget);
      expect(pill, findsNothing);
    });

    testWidgets('stays for an answer with no installed voice and explains it '
        'as F4 does', (WidgetTester tester) async {
      final _RecordingTtsEngine engine = _RecordingTtsEngine(
        const <SpeechVoice>[frenchVoice],
      );
      await startSession(tester, engine);
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();

      expect(pill, findsOneWidget);
      await tester.tap(pill);
      await tester.pumpAndSettle();
      expect(engine.spoken, isEmpty);
      expect(find.textContaining('de-DE'), findsOneWidget);
    });

    testWidgets('the answer stage orders its groups by key, Cancel last in '
        'its group and Difficult on its own', (WidgetTester tester) async {
      final _RecordingTtsEngine engine = _RecordingTtsEngine(
        const <SpeechVoice>[frenchVoice, germanVoice],
      );
      await startSession(
        tester,
        engine,
        withInput: true,
        onToggleDifficult: (SessionItem _, DifficultFlags f) => f,
      );
      await tester.enterText(find.byType(TextField), 'Geburtstag');
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();

      expect(texts('learnActionPillsGroup'), <String>[
        'Continue', 'F3', //
        'Read aloud', 'F4', //
        'Solution', 'Switch: F9', //
        'Cancel', 'Esc', //
      ]);
      expect(texts('learnAnswerPills'), <String?>[
        ...texts('learnActionPillsGroup'),
        ...texts('learnEvaluationPillsGroup'),
        'Difficult', 'F12', //
      ]);
      expect(texts('learnEvaluationPillsGroup'), <String>[
        'Evaluate as:', //
        'Correct', 'F5', //
        'Actually wrong', 'F6', //
        'No count', 'F7', //
      ]);

      // The caption stands above the rating pills, flush with the first, and
      // whatever shares their line lines up with the pills rather than with
      // the caption. Which groups share it depends on the width.
      final Rect caption = tester.getRect(find.text('Evaluate as:'));
      final Rect correct = tester.getRect(
        find.ancestor(
          of: find.text('Correct'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(caption.bottom, lessThanOrEqualTo(correct.top));
      expect(caption.left, correct.left);
      final List<Rect> sameLine = <Rect>[
        tester.getRect(find.byKey(const Key('learnActionPillsGroup'))),
        tester.getRect(find.byKey(const Key('learnDifficultPill'))),
      ].where(
        (Rect pill) => pill.top < correct.bottom && pill.bottom > correct.top,
      ).toList();
      expect(sameLine, isNotEmpty);
      for (final Rect pill in sameLine) {
        expect(pill.bottom, correct.bottom);
      }
    });

    testWidgets('the question stage shows it where the solution is on screen, '
        'in key order with Cancel before Difficult', (
      WidgetTester tester,
    ) async {
      final _RecordingTtsEngine engine = _RecordingTtsEngine(
        const <SpeechVoice>[frenchVoice, germanVoice],
      );
      await startSession(
        tester,
        engine,
        mode: SessionMode.levelLearning,
        onToggleDifficult: (SessionItem _, DifficultFlags f) => f,
      );

      // The top of the ladder shows the solution to be memorized: F4 reads
      // it, so the pill is there.
      expect(texts('learnQuestionPills'), <String>[
        'Less help', //
        'More help', //
        'Read aloud', 'F4', //
        'Hide & type', 'F10', //
        'Cancel', 'Esc', //
        'Difficult', 'F12', //
      ]);
      await tester.tap(pill);
      await tester.pumpAndSettle();
      expect(engine.spoken.single.text, 'Geburtstag');

      // Hide & type takes the solution away, and the pill with it.
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();
      expect(pill, findsNothing);
      expect(texts('learnQuestionPills'), <String>[
        'Less help', //
        'More help', //
        'Check', 'F10', //
        'Cancel', 'Esc', //
        'Difficult', 'F12', //
      ]);
    });
  });

  testWidgets('a host that cannot speak shows no icons at all', (
    WidgetTester tester,
  ) async {
    await startSession(tester, const UnavailableTtsEngine());

    expect(find.byType(SpeakerButton), findsNothing);
    // The session itself is unaffected.
    expect(find.textContaining('Unit 1/1'), findsOneWidget);
  });
}

/// A [TtsEngine] that records what it was asked to say instead of saying it.
final class _RecordingTtsEngine implements TtsEngine {
  _RecordingTtsEngine(this._voices);

  final List<SpeechVoice> _voices;

  /// Every utterance handed to [speak], in order.
  final List<SpeechUtterance> spoken = <SpeechUtterance>[];

  /// Every call, in the order they arrived: `stop` and `speak:<text>`.
  ///
  /// The timing rules are about ORDER — stop before start, once per reveal —
  /// so the order is what the tests read.
  final List<String> events = <String>[];

  @override
  bool get isAvailable => true;

  @override
  Future<List<SpeechVoice>> voices() async => _voices;

  @override
  Future<void> speak(SpeechUtterance utterance) async {
    spoken.add(utterance);
    events.add('speak:${utterance.text}');
  }

  @override
  Future<void> stop() async {
    events.add('stop');
  }
}
