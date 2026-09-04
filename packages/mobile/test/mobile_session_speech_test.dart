import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_mobile/src/mobile_file_service.dart';
import 'package:learn_anywhere_mobile/src/session/mobile_session_screen.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

/// Speech in a running mobile session: where the speaker icons are, what
/// they ask to be said, and what a host with no voice — or no speech at all
/// — shows.
///
/// Mirrors `packages/desktop/test/learn_session_speech_test.dart`, adapted to
/// the phone's two-tap prompt/reveal flow (there is no `F10`, no `F4`, and no
/// Level Learning here). Driven against a recording engine, so no test makes
/// a sound.
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
    maskId: 'm_new_mobile-speech-fixture',
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

  Widget buildScreen(
    TtsEngine engine,
    SpeechSettings speechSettings,
    LearningDeck sessionDeck,
    _RecordingFileService fileService,
  ) {
    return MaterialApp(
      localizationsDelegates: LearnAnywhereLocalizations.localizationsDelegates,
      supportedLocales: LearnAnywhereLocalizations.supportedLocales,
      home: MobileSessionScreen(
        document: MobileDeckDocument(
          deck: sessionDeck,
          deckPath: 'fixture.vok',
          statistics: clearStatistics(sessionDeck),
        ),
        parameters: const SessionParameters(
          directionSelection: DirectionSelection.direction1,
          mode: SessionMode.onceThrough,
          shuffle: false,
        ),
        wrongAnswerCeiling: const WrongAnswerCeiling(),
        fileService: fileService,
        speechEngine: engine,
        speechSettings: speechSettings,
      ),
    );
  }

  Future<void> startSession(
    WidgetTester tester,
    TtsEngine engine, {
    SpeechSettings speechSettings = const SpeechSettings(),
    LearningDeck? sessionDeck,
    _RecordingFileService? fileService,
  }) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      buildScreen(
        engine,
        speechSettings,
        sessionDeck ?? deck,
        fileService ?? _RecordingFileService(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the question speaks throughout; the answer only once '
      'revealed', (WidgetTester tester) async {
    final _RecordingTtsEngine engine = _RecordingTtsEngine(
      const <SpeechVoice>[frenchVoice, germanVoice],
    );
    await startSession(tester, engine);

    // Before Show answer: the question offers speech, the answer does not.
    expect(find.byKey(const Key('speakField-0')), findsOneWidget);
    expect(find.byKey(const Key('speakField-1')), findsNothing);

    await tester.tap(find.byKey(const Key('speakField-0')));
    await tester.pumpAndSettle();
    expect(engine.spoken.single.text, 'anniversaire');
    expect(engine.spoken.single.voice, frenchVoice);

    await tester.tap(find.text('Show answer'));
    await tester.pumpAndSettle();
    // The reveal screen opens on the solution: the answer field's icon is
    // there, and the question field's is not — it is a click away behind the
    // Prompt/Solution toggle, which is exactly where its value now is.
    expect(find.byKey(const Key('speakField-0')), findsNothing);
    expect(find.byKey(const Key('speakField-1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('speakField-1')));
    await tester.pumpAndSettle();
    expect(engine.spoken.last.text, 'Geburtstag');
    expect(engine.spoken.last.voice, germanVoice);

    // Switching the toggle back to the question brings the question field's
    // icon back — the same rule, "an icon is wherever its field's value is",
    // holding through the toggle.
    await tester.tap(find.text('Prompt'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('speakField-0')), findsOneWidget);
    expect(find.byKey(const Key('speakField-1')), findsNothing);
  });

  testWidgets('a language with no installed voice says so and stays '
      'silent', (WidgetTester tester) async {
    final _RecordingTtsEngine engine = _RecordingTtsEngine(
      const <SpeechVoice>[germanVoice],
    );
    await startSession(tester, engine);

    await tester.tap(find.byKey(const Key('speakField-0')));
    await tester.pumpAndSettle();
    expect(engine.spoken, isEmpty);
    expect(find.textContaining('fr-FR'), findsOneWidget);
  });

  group('automatic speech', () {
    const SpeechSettings automatic = SpeechSettings(automatic: true);

    testWidgets('reads the answer once at a reveal', (
      WidgetTester tester,
    ) async {
      final _RecordingTtsEngine engine = _RecordingTtsEngine(
        const <SpeechVoice>[frenchVoice, germanVoice],
      );
      await startSession(tester, engine, speechSettings: automatic);

      // Nothing is said while the answer is still hidden.
      expect(engine.spoken, isEmpty);

      await tester.tap(find.text('Show answer'));
      await tester.pumpAndSettle();

      // Exactly the answer field, in its own voice — not the question the
      // learner can already see, and not the remark field (no Speak flag).
      expect(engine.spoken.single.text, 'Geburtstag');
      expect(engine.spoken.single.voice, germanVoice);
      expect(engine.events, <String>['stop', 'speak:Geburtstag']);
    });

    testWidgets('toggling Prompt/Solution does not repeat it', (
      WidgetTester tester,
    ) async {
      final _RecordingTtsEngine engine = _RecordingTtsEngine(
        const <SpeechVoice>[frenchVoice, germanVoice],
      );
      await startSession(tester, engine, speechSettings: automatic);

      await tester.tap(find.text('Show answer'));
      await tester.pumpAndSettle();
      expect(engine.spoken, hasLength(1));

      // The segmented control toggles back to the question and back to the
      // solution; the card was revealed once, so it was read once.
      await tester.tap(find.text('Prompt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Solution').first);
      await tester.pumpAndSettle();

      expect(engine.spoken, hasLength(1));
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

      await tester.tap(find.text('Show answer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Knew it'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show answer'));
      await tester.pumpAndSettle();

      expect(engine.events, <String>[
        'stop',
        'speak:Geburtstag',
        // Rating stops speech too, so leaving a card mid-word never bleeds
        // into the next one's prompt.
        'stop',
        'stop',
        'speak:Haus',
      ]);
    });

    testWidgets('listening moves no statistics', (WidgetTester tester) async {
      final _RecordingTtsEngine engine = _RecordingTtsEngine(
        const <SpeechVoice>[frenchVoice, germanVoice],
      );
      final _RecordingFileService fileService = _RecordingFileService();
      await startSession(
        tester,
        engine,
        speechSettings: automatic,
        fileService: fileService,
      );

      await tester.tap(find.text('Show answer'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('speakField-1')));
      await tester.pumpAndSettle();

      expect(fileService.saveCalls, isZero);
    });
  });

  testWidgets('a host that cannot speak shows no icons at all', (
    WidgetTester tester,
  ) async {
    await startSession(tester, const UnavailableTtsEngine());

    expect(find.byType(SpeakerButton), findsNothing);
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

/// A [MobileFileService] that counts statistics saves instead of touching
/// disk.
final class _RecordingFileService extends MobileFileService {
  int saveCalls = 0;

  @override
  Future<void> saveStatistics(
    MobileDeckDocument document,
    List<UnitStats> statistics,
  ) async {
    saveCalls += 1;
  }
}
