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

  final LearningDeck deck = LearningDeck(
    mask: mask,
    units: const <LearningUnit>[
      LearningUnit(
        categoryId: 0,
        fields: <int, FieldValue>{
          0: FieldValue.plain('anniversaire'),
          1: FieldValue.plain('Geburtstag'),
          2: FieldValue.plain('m'),
        },
      ),
    ],
  );

  Widget buildPage(
    TtsEngine engine,
    SessionMode mode,
    SpeechSettings speechSettings,
  ) {
    return MaterialApp(
      localizationsDelegates: LearnAnywhereLocalizations.localizationsDelegates,
      supportedLocales: LearnAnywhereLocalizations.supportedLocales,
      home: Scaffold(
        body: LearnSessionPage(
          startSessionOnOpen: true,
          speechEngine: engine,
          speechSettings: speechSettings,
          deck: deck,
          statistics: const <UnitStats>[],
          options: const DesktopQueryOptions(),
          parameters: SessionParameters(
            withInput: false,
            mode: mode,
            directionSelection: DirectionSelection.direction1,
            shuffle: false,
          ),
          onParametersChanged: (SessionParameters _) {},
          onStatisticsChanged: (List<UnitStats> _) {},
          onOpenEditor: () {},
        ),
      ),
    );
  }

  Future<void> startSession(
    WidgetTester tester,
    TtsEngine engine, {
    SessionMode mode = SessionMode.onceThrough,
    SpeechSettings speechSettings = const SpeechSettings(),
  }) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildPage(engine, mode, speechSettings));
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

  @override
  bool get isAvailable => true;

  @override
  Future<List<SpeechVoice>> voices() async => _voices;

  @override
  Future<void> speak(SpeechUtterance utterance) async {
    spoken.add(utterance);
  }

  @override
  Future<void> stop() async {}
}
