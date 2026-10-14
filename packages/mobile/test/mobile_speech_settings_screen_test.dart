import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_mobile/src/settings/mobile_speech_settings_screen.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

/// The mobile companion's Speech screen: which languages it lists, what a
/// missing voice says, and what it stores — the same [SpeechSettings] shape
/// the desktop's own Speech screen stores.
///
/// Mirrors `packages/desktop/test/speech_settings_page_test.dart`. Driven
/// against a recording engine, so no test makes a sound.
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

  const LearningDeck deck = LearningDeck(
    mask: LearningMask(
      maskId: 'm_new_mobile-speech-screen-fixture',
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
              name: 'Italian',
              length: 20,
              equalGroup: 0,
              role1: FieldRole.answer,
              role2: FieldRole.question,
              language: 'it-IT',
              speak: true,
            ),
          ],
        ),
      ],
    ),
    units: <LearningUnit>[],
  );

  Future<SpeechSettings Function()> pumpScreen(
    WidgetTester tester, {
    required TtsEngine engine,
    LearningDeck? withDeck = deck,
    SpeechSettings initial = const SpeechSettings(),
  }) async {
    SpeechSettings current = initial;
    // Tall enough that every row is on screen without scrolling: this test
    // is about what the screen offers and stores, not about phone-sized
    // layout, which the mobile widget-test suite covers elsewhere.
    tester.view.physicalSize = const Size(360, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: LearnAnywhereLocalizations.localizationsDelegates,
        supportedLocales: LearnAnywhereLocalizations.supportedLocales,
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MobileSpeechSettingsScreen(
              engine: engine,
              deck: withDeck,
              settings: current,
              onChanged: (SpeechSettings value) {
                setState(() => current = value);
              },
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return () => current;
  }

  testWidgets("lists the open deck's languages and any already configured", (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      engine: _RecordingTtsEngine(const <SpeechVoice>[hortense]),
      initial: const SpeechSettings(
        voices: <String, VoiceChoice>{
          'de-DE': VoiceChoice(
            engine: kSystemSpeechEngineId,
            voiceId: 'Microsoft Hedda',
          ),
        },
      ),
    );

    expect(find.byKey(const Key('speechRow-fr-FR')), findsOneWidget);
    expect(find.byKey(const Key('speechRow-it-IT')), findsOneWidget);
    expect(find.byKey(const Key('speechRow-de-DE')), findsOneWidget);
  });

  testWidgets('lists only the configured languages with no deck open', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      engine: _RecordingTtsEngine(const <SpeechVoice>[hortense]),
      withDeck: null,
      initial: const SpeechSettings(
        voices: <String, VoiceChoice>{
          'de-DE': VoiceChoice(
            engine: kSystemSpeechEngineId,
            voiceId: 'Microsoft Hedda',
          ),
        },
      ),
    );

    expect(find.byKey(const Key('speechRow-de-DE')), findsOneWidget);
    expect(find.byKey(const Key('speechRow-fr-FR')), findsNothing);
  });

  testWidgets('says so plainly when a language has no installed voice', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      engine: _RecordingTtsEngine(const <SpeechVoice>[hortense]),
    );

    expect(find.byKey(const Key('speechVoice-fr-FR')), findsOneWidget);
    expect(find.byKey(const Key('speechVoice-it-IT')), findsNothing);
    expect(find.textContaining('no voice for it-IT'), findsOneWidget);
  });

  testWidgets('stores a chosen voice as an engine plus a voice within it', (
    WidgetTester tester,
  ) async {
    final SpeechSettings Function() settings = await pumpScreen(
      tester,
      engine: _RecordingTtsEngine(const <SpeechVoice>[hortense, claude]),
    );

    await tester.tap(find.byKey(const Key('speechVoice-fr-FR')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Microsoft Claude').last);
    await tester.pumpAndSettle();

    expect(
      settings().voiceFor('fr-FR'),
      const VoiceChoice(
        engine: kSystemSpeechEngineId,
        voiceId: 'Microsoft Claude',
      ),
    );
  });

  testWidgets('the test button speaks a sample in the chosen voice', (
    WidgetTester tester,
  ) async {
    final _RecordingTtsEngine engine = _RecordingTtsEngine(
      const <SpeechVoice>[hortense],
    );
    await pumpScreen(tester, engine: engine);

    await tester.tap(find.byKey(const Key('speechTest-fr-FR')));
    await tester.pumpAndSettle();

    expect(engine.spoken.single.voice, hortense);
    expect(engine.spoken.single.text, speechSampleFor('fr-FR'));
  });

  testWidgets('the automatic-speech switch persists through onChanged', (
    WidgetTester tester,
  ) async {
    final SpeechSettings Function() settings = await pumpScreen(
      tester,
      engine: _RecordingTtsEngine(const <SpeechVoice>[hortense]),
    );

    expect(settings().automatic, isTrue);
    await tester.tap(find.byKey(const Key('speechAutomatic')));
    await tester.pumpAndSettle();

    expect(settings().automatic, isFalse);
  });
}

/// A [TtsEngine] that records what it was asked to say instead of saying it.
final class _RecordingTtsEngine implements TtsEngine {
  _RecordingTtsEngine(this._voices);

  final List<SpeechVoice> _voices;

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
